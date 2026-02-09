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

    PROCEDURE validate_request_exists (
        p_request_id      IN NUMBER,
        p_employee_id     OUT NUMBER,
        p_status          OUT VARCHAR2,
        p_requested_days  OUT NUMBER
    ) IS
    BEGIN
        SELECT employee_id, status, requested_days
          INTO p_employee_id, p_status, p_requested_days
          FROM leave_requests
         WHERE request_id = p_request_id
           FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Leave request not found.');
    END validate_request_exists;

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
        l_emp_id           NUMBER;
        l_status           VARCHAR2(30);
        l_requested_days   NUMBER;
        l_req_emp_id       NUMBER;
        l_req_leave_type   NUMBER;
        l_req_start_date   DATE;
        l_level            NUMBER;
    BEGIN
        validate_employee_active(p_approver_id);
        validate_request_exists(p_request_id, l_emp_id, l_status, l_requested_days);

        IF l_status = 'PENDING_MANAGER' THEN
            l_level := 1;
            UPDATE leave_requests
               SET status = 'PENDING_HR'
             WHERE request_id = p_request_id;
        ELSIF l_status = 'PENDING_HR' THEN
            l_level := 2;

            SELECT employee_id, leave_type_id, start_date
              INTO l_req_emp_id, l_req_leave_type, l_req_start_date
              FROM leave_requests
             WHERE request_id = p_request_id
               FOR UPDATE;

            UPDATE leave_balances
               SET used_days = used_days + l_requested_days,
                   updated_at = SYSTIMESTAMP
             WHERE employee_id = l_req_emp_id
               AND leave_type_id = l_req_leave_type
               AND balance_year = EXTRACT(YEAR FROM l_req_start_date);

            UPDATE leave_requests
               SET status = 'APPROVED',
                   decided_at = SYSTIMESTAMP
             WHERE request_id = p_request_id;
        ELSE
            RAISE_APPLICATION_ERROR(-20009, 'Only pending requests can be approved.');
        END IF;

        INSERT INTO leave_approvals (request_id, approver_id, approval_level, action_taken, comments)
        VALUES (p_request_id, p_approver_id, l_level, 'APPROVED', p_comments);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error('lms_leave_pkg.approve_leave', SQLERRM,
                'request_id=' || p_request_id || ', approver_id=' || p_approver_id);
            ROLLBACK;
            RAISE;
    END approve_leave;

    PROCEDURE reject_leave (
        p_request_id  IN NUMBER,
        p_approver_id IN NUMBER,
        p_comments    IN VARCHAR2 DEFAULT NULL
    ) IS
        l_emp_id         NUMBER;
        l_status         VARCHAR2(30);
        l_requested_days NUMBER;
        l_level          NUMBER;
    BEGIN
        validate_employee_active(p_approver_id);
        validate_request_exists(p_request_id, l_emp_id, l_status, l_requested_days);

        IF l_status = 'PENDING_MANAGER' THEN
            l_level := 1;
        ELSIF l_status = 'PENDING_HR' THEN
            l_level := 2;
        ELSE
            RAISE_APPLICATION_ERROR(-20010, 'Only pending requests can be rejected.');
        END IF;

        UPDATE leave_requests
           SET status = 'REJECTED',
               decided_at = SYSTIMESTAMP
         WHERE request_id = p_request_id;

        INSERT INTO leave_approvals (request_id, approver_id, approval_level, action_taken, comments)
        VALUES (p_request_id, p_approver_id, l_level, 'REJECTED', p_comments);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error('lms_leave_pkg.reject_leave', SQLERRM,
                'request_id=' || p_request_id || ', approver_id=' || p_approver_id);
            ROLLBACK;
            RAISE;
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
        validate_request_exists(p_request_id, l_owner_id, l_status, l_requested_days);

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

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error('lms_leave_pkg.cancel_leave', SQLERRM,
                'request_id=' || p_request_id || ', employee_id=' || p_employee_id);
            ROLLBACK;
            RAISE;
    END cancel_leave;
END lms_leave_pkg;
/
