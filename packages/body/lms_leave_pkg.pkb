CREATE OR REPLACE PACKAGE BODY lms_leave_pkg AS
    PROCEDURE validate_employee_active (p_employee_id IN NUMBER) IS
        l_active CHAR(1);
    BEGIN
        SELECT is_active
          INTO l_active
          FROM employees
         WHERE employee_id = p_employee_id;

        IF l_active <> 'Y' THEN
            RAISE_APPLICATION_ERROR(-20002, 'Employee is not active.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Employee not found.');
    END validate_employee_active;

    PROCEDURE check_overlap (
        p_employee_id IN NUMBER,
        p_start_date  IN DATE,
        p_end_date    IN DATE
    ) IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM leave_requests
         WHERE employee_id = p_employee_id
           AND status IN ('PENDING_MANAGER', 'PENDING_HR', 'APPROVED')
           AND p_start_date <= end_date
           AND p_end_date >= start_date;

        IF l_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Overlapping leave request exists.');
        END IF;
    END check_overlap;

    PROCEDURE notify_manager_for_request (
        p_request_id   IN NUMBER,
        p_employee_id  IN NUMBER
    ) IS
        l_manager_id NUMBER;
    BEGIN
        SELECT manager_id
          INTO l_manager_id
          FROM employees
         WHERE employee_id = p_employee_id;

        IF l_manager_id IS NOT NULL THEN
            lms_notification_pkg.enqueue_notification(
                p_recipient_emp_id => l_manager_id,
                p_subject          => 'Leave Request Pending Approval',
                p_message_body     => 'Request #' || p_request_id || ' needs your approval.',
                p_channel          => 'INAPP'
            );
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END notify_manager_for_request;

    PROCEDURE notify_request_cancelled (
        p_request_id  IN NUMBER,
        p_employee_id IN NUMBER
    ) IS
    BEGIN
        lms_notification_pkg.enqueue_notification(
            p_recipient_emp_id => p_employee_id,
            p_subject          => 'Leave Request Cancelled',
            p_message_body     => 'Request #' || p_request_id || ' has been cancelled.',
            p_channel          => 'INAPP'
        );
    END notify_request_cancelled;

    PROCEDURE apply_leave (
        p_employee_id   IN NUMBER,
        p_leave_type_id IN NUMBER,
        p_start_date    IN DATE,
        p_end_date      IN DATE,
        p_reason        IN VARCHAR2,
        p_request_id    OUT NUMBER
    ) IS
        l_days            NUMBER;
        l_year            NUMBER := EXTRACT(YEAR FROM p_start_date);
        l_available_days  NUMBER;
    BEGIN
        validate_employee_active(p_employee_id);

        IF TRUNC(p_end_date) < TRUNC(p_start_date) THEN
            RAISE_APPLICATION_ERROR(-20006, 'Invalid leave date range.');
        END IF;

        l_days := lms_common_pkg.working_days_between(TRUNC(p_start_date), TRUNC(p_end_date));
        IF l_days <= 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Leave duration should have at least one working day.');
        END IF;

        check_overlap(p_employee_id, TRUNC(p_start_date), TRUNC(p_end_date));

        SELECT opening_balance_days + accrued_days + adjusted_days - used_days
          INTO l_available_days
          FROM leave_balances
         WHERE employee_id = p_employee_id
           AND leave_type_id = p_leave_type_id
           AND balance_year = l_year
           FOR UPDATE;

        IF l_available_days < l_days THEN
            RAISE_APPLICATION_ERROR(-20008, 'Insufficient leave balance.');
        END IF;

        INSERT INTO leave_requests (
            employee_id,
            leave_type_id,
            start_date,
            end_date,
            requested_days,
            reason,
            status
        ) VALUES (
            p_employee_id,
            p_leave_type_id,
            TRUNC(p_start_date),
            TRUNC(p_end_date),
            l_days,
            p_reason,
            'PENDING_MANAGER'
        ) RETURNING request_id INTO p_request_id;

        notify_manager_for_request(p_request_id, p_employee_id);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error('lms_leave_pkg.apply_leave', SQLERRM,
                'employee_id=' || p_employee_id || ', leave_type_id=' || p_leave_type_id);
            ROLLBACK;
            RAISE;
    END apply_leave;

    PROCEDURE approve_leave (
        p_request_id  IN NUMBER,
        p_approver_id IN NUMBER,
        p_comments    IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        lms_approval_pkg.approve_leave(
            p_request_id  => p_request_id,
            p_approver_id => p_approver_id,
            p_comments    => p_comments
        );
    END approve_leave;

    PROCEDURE reject_leave (
        p_request_id  IN NUMBER,
        p_approver_id IN NUMBER,
        p_comments    IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        lms_approval_pkg.reject_leave(
            p_request_id  => p_request_id,
            p_approver_id => p_approver_id,
            p_comments    => p_comments
        );
    END reject_leave;

    PROCEDURE cancel_leave (
        p_request_id     IN NUMBER,
        p_employee_id    IN NUMBER,
        p_cancel_reason  IN VARCHAR2 DEFAULT NULL
    ) IS
        l_owner_id        NUMBER;
        l_status          VARCHAR2(30);
        l_requested_days  NUMBER;
        l_leave_type_id   NUMBER;
        l_start_date      DATE;
    BEGIN
        validate_employee_active(p_employee_id);

        SELECT employee_id, status, requested_days
          INTO l_owner_id, l_status, l_requested_days
          FROM leave_requests
         WHERE request_id = p_request_id
           FOR UPDATE;

        IF l_owner_id <> p_employee_id THEN
            RAISE_APPLICATION_ERROR(-20011, 'Only request owner can cancel leave.');
        END IF;

        IF l_status = 'CANCELLED' OR l_status = 'REJECTED' THEN
            RAISE_APPLICATION_ERROR(-20012, 'Request cannot be cancelled in current status.');
        END IF;

        IF l_status = 'APPROVED' THEN
            SELECT leave_type_id, start_date
              INTO l_leave_type_id, l_start_date
              FROM leave_requests
             WHERE request_id = p_request_id
               FOR UPDATE;

            UPDATE leave_balances
               SET used_days = used_days - l_requested_days,
                   updated_at = SYSTIMESTAMP
             WHERE employee_id = p_employee_id
               AND leave_type_id = l_leave_type_id
               AND balance_year = EXTRACT(YEAR FROM l_start_date);
        END IF;

        UPDATE leave_requests
           SET status = 'CANCELLED',
               cancel_reason = p_cancel_reason,
               decided_at = SYSTIMESTAMP
         WHERE request_id = p_request_id;

        notify_request_cancelled(p_request_id, p_employee_id);

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Leave request not found.');
        WHEN OTHERS THEN
            lms_common_pkg.log_error('lms_leave_pkg.cancel_leave', SQLERRM,
                'request_id=' || p_request_id || ', employee_id=' || p_employee_id);
            ROLLBACK;
            RAISE;
    END cancel_leave;
END lms_leave_pkg;
/
