CREATE OR REPLACE PACKAGE BODY lms_approval_pkg AS
    PROCEDURE validate_employee_active (p_employee_id IN NUMBER) IS
        l_active CHAR(1);
    BEGIN
        SELECT is_active
          INTO l_active
          FROM employees
         WHERE employee_id = p_employee_id;

        IF l_active <> 'Y' THEN
            RAISE_APPLICATION_ERROR(-20301, 'Approver is not active.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20302, 'Approver not found.');
    END validate_employee_active;

    PROCEDURE notify_hr_on_manager_approval (
        p_request_id IN NUMBER
    ) IS
    BEGIN
        FOR rec IN (
            SELECT employee_id
              FROM employees
             WHERE manager_id IS NULL
               AND is_active = 'Y'
        ) LOOP
            lms_notification_pkg.enqueue_notification(
                p_recipient_emp_id => rec.employee_id,
                p_subject          => 'Leave Request Pending HR Approval',
                p_message_body     => 'Request #' || p_request_id || ' is pending HR approval.',
                p_channel          => 'INAPP'
            );
        END LOOP;
    END notify_hr_on_manager_approval;

    PROCEDURE notify_requester (
        p_request_id IN NUMBER,
        p_subject    IN VARCHAR2,
        p_body       IN VARCHAR2
    ) IS
        l_employee_id NUMBER;
    BEGIN
        SELECT employee_id
          INTO l_employee_id
          FROM leave_requests
         WHERE request_id = p_request_id;

        lms_notification_pkg.enqueue_notification(
            p_recipient_emp_id => l_employee_id,
            p_subject          => p_subject,
            p_message_body     => p_body,
            p_channel          => 'INAPP'
        );
    END notify_requester;

    PROCEDURE approve_leave (
        p_request_id  IN NUMBER,
        p_approver_id IN NUMBER,
        p_comments    IN VARCHAR2 DEFAULT NULL
    ) IS
        l_status           VARCHAR2(30);
        l_requested_days   NUMBER;
        l_req_emp_id       NUMBER;
        l_req_leave_type   NUMBER;
        l_req_start_date   DATE;
        l_level            NUMBER;
    BEGIN
        validate_employee_active(p_approver_id);

        SELECT status, requested_days, employee_id, leave_type_id, start_date
          INTO l_status, l_requested_days, l_req_emp_id, l_req_leave_type, l_req_start_date
          FROM leave_requests
         WHERE request_id = p_request_id
           FOR UPDATE;

        IF l_status = 'PENDING_MANAGER' THEN
            l_level := 1;

            UPDATE leave_requests
               SET status = 'PENDING_HR'
             WHERE request_id = p_request_id;

            notify_hr_on_manager_approval(p_request_id);
        ELSIF l_status = 'PENDING_HR' THEN
            l_level := 2;

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

            notify_requester(
                p_request_id => p_request_id,
                p_subject    => 'Leave Request Approved',
                p_body       => 'Request #' || p_request_id || ' has been approved.'
            );
        ELSE
            RAISE_APPLICATION_ERROR(-20303, 'Only pending requests can be approved.');
        END IF;

        INSERT INTO leave_approvals (request_id, approver_id, approval_level, action_taken, comments)
        VALUES (p_request_id, p_approver_id, l_level, 'APPROVED', p_comments);

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20304, 'Leave request not found.');
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_approval_pkg.approve_leave',
                SQLERRM,
                'request_id=' || p_request_id || ', approver_id=' || p_approver_id
            );
            ROLLBACK;
            RAISE;
    END approve_leave;

    PROCEDURE reject_leave (
        p_request_id  IN NUMBER,
        p_approver_id IN NUMBER,
        p_comments    IN VARCHAR2 DEFAULT NULL
    ) IS
        l_status VARCHAR2(30);
        l_level  NUMBER;
    BEGIN
        validate_employee_active(p_approver_id);

        SELECT status
          INTO l_status
          FROM leave_requests
         WHERE request_id = p_request_id
           FOR UPDATE;

        IF l_status = 'PENDING_MANAGER' THEN
            l_level := 1;
        ELSIF l_status = 'PENDING_HR' THEN
            l_level := 2;
        ELSE
            RAISE_APPLICATION_ERROR(-20305, 'Only pending requests can be rejected.');
        END IF;

        UPDATE leave_requests
           SET status = 'REJECTED',
               decided_at = SYSTIMESTAMP
         WHERE request_id = p_request_id;

        INSERT INTO leave_approvals (request_id, approver_id, approval_level, action_taken, comments)
        VALUES (p_request_id, p_approver_id, l_level, 'REJECTED', p_comments);

        notify_requester(
            p_request_id => p_request_id,
            p_subject    => 'Leave Request Rejected',
            p_body       => 'Request #' || p_request_id || ' has been rejected.'
        );

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20306, 'Leave request not found.');
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_approval_pkg.reject_leave',
                SQLERRM,
                'request_id=' || p_request_id || ', approver_id=' || p_approver_id
            );
            ROLLBACK;
            RAISE;
    END reject_leave;
END lms_approval_pkg;
/
