CREATE OR REPLACE PACKAGE BODY lms_approval_pkg AS
    FUNCTION has_role (
        p_employee_id IN NUMBER,
        p_role_code   IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM employee_roles
         WHERE employee_id = p_employee_id
           AND role_code = UPPER(TRIM(p_role_code))
           AND is_active = 'Y';

        RETURN l_count > 0;
    END has_role;

    PROCEDURE validate_employee_active (p_employee_id IN NUMBER) IS
        l_active CHAR(1);
    BEGIN
        IF p_employee_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20300, 'approver_id is required.');
        END IF;

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

    PROCEDURE validate_approval_authorization (
        p_request_id      IN NUMBER,
        p_requester_id    IN NUMBER,
        p_request_status  IN VARCHAR2,
        p_approver_id     IN NUMBER
    ) IS
        l_manager_id NUMBER;
    BEGIN
        IF has_role(p_approver_id, 'ADMIN') THEN
            RETURN;
        END IF;

        IF p_request_status = 'PENDING_MANAGER' THEN
            SELECT manager_id
              INTO l_manager_id
              FROM employees
             WHERE employee_id = p_requester_id;

            IF l_manager_id IS NULL OR l_manager_id <> p_approver_id THEN
                RAISE_APPLICATION_ERROR(-20307, 'Only assigned manager (or ADMIN) can approve/reject at manager level.');
            END IF;
        ELSIF p_request_status = 'PENDING_HR' THEN
            IF NOT has_role(p_approver_id, 'HR') THEN
                RAISE_APPLICATION_ERROR(-20308, 'Only HR (or ADMIN) can approve/reject at HR level.');
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20309, 'Requester not found for authorization check.');
    END validate_approval_authorization;

    PROCEDURE notify_hr_on_manager_approval (
        p_request_id IN NUMBER
    ) IS
    BEGIN
        FOR rec IN (
            SELECT DISTINCT er.employee_id
              FROM employee_roles er
              JOIN employees e
                ON e.employee_id = er.employee_id
             WHERE er.role_code = 'HR'
               AND er.is_active = 'Y'
               AND e.is_active = 'Y'
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
            p_subject          => SUBSTR(p_subject, 1, 200),
            p_message_body     => SUBSTR(p_body, 1, 1000),
            p_channel          => 'INAPP'
        );
    END notify_requester;

    PROCEDURE validate_comments (p_comments IN VARCHAR2) IS
    BEGIN
        IF p_comments IS NOT NULL AND LENGTH(p_comments) > 500 THEN
            RAISE_APPLICATION_ERROR(-20310, 'Approval comments cannot exceed 500 characters.');
        END IF;
    END validate_comments;

    PROCEDURE approve_leave (
        p_request_id  IN NUMBER,
        p_approver_id IN NUMBER,
        p_comments    IN VARCHAR2 DEFAULT NULL
    ) IS
        l_status            VARCHAR2(30);
        l_requested_days    NUMBER;
        l_req_emp_id        NUMBER;
        l_req_leave_type    NUMBER;
        l_req_start_date    DATE;
        l_level             NUMBER;
        l_available_days    NUMBER;
    BEGIN
        IF p_request_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20311, 'request_id is required.');
        END IF;

        validate_employee_active(p_approver_id);
        validate_comments(p_comments);

        SELECT status, requested_days, employee_id, leave_type_id, start_date
          INTO l_status, l_requested_days, l_req_emp_id, l_req_leave_type, l_req_start_date
          FROM leave_requests
         WHERE request_id = p_request_id
           FOR UPDATE;

        IF l_req_emp_id = p_approver_id AND NOT has_role(p_approver_id, 'ADMIN') THEN
            RAISE_APPLICATION_ERROR(-20312, 'Self-approval is not allowed unless approver has ADMIN role.');
        END IF;

        validate_approval_authorization(
            p_request_id     => p_request_id,
            p_requester_id   => l_req_emp_id,
            p_request_status => l_status,
            p_approver_id    => p_approver_id
        );

        IF l_status = 'PENDING_MANAGER' THEN
            l_level := 1;

            UPDATE leave_requests
               SET status = 'PENDING_HR'
             WHERE request_id = p_request_id;

            notify_hr_on_manager_approval(p_request_id);
        ELSIF l_status = 'PENDING_HR' THEN
            l_level := 2;

            SELECT opening_balance_days + accrued_days + adjusted_days - used_days
              INTO l_available_days
              FROM leave_balances
             WHERE employee_id = l_req_emp_id
               AND leave_type_id = l_req_leave_type
               AND balance_year = EXTRACT(YEAR FROM l_req_start_date)
               FOR UPDATE;

            IF l_available_days < l_requested_days THEN
                RAISE_APPLICATION_ERROR(-20313, 'Insufficient balance at final approval stage.');
            END IF;

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
        VALUES (p_request_id, p_approver_id, l_level, 'APPROVED', SUBSTR(p_comments, 1, 500));

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
        l_status      VARCHAR2(30);
        l_level       NUMBER;
        l_req_emp_id  NUMBER;
    BEGIN
        IF p_request_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20311, 'request_id is required.');
        END IF;

        validate_employee_active(p_approver_id);
        validate_comments(p_comments);

        SELECT status, employee_id
          INTO l_status, l_req_emp_id
          FROM leave_requests
         WHERE request_id = p_request_id
           FOR UPDATE;

        IF l_req_emp_id = p_approver_id AND NOT has_role(p_approver_id, 'ADMIN') THEN
            RAISE_APPLICATION_ERROR(-20312, 'Self-approval is not allowed unless approver has ADMIN role.');
        END IF;

        validate_approval_authorization(
            p_request_id     => p_request_id,
            p_requester_id   => l_req_emp_id,
            p_request_status => l_status,
            p_approver_id    => p_approver_id
        );

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
        VALUES (p_request_id, p_approver_id, l_level, 'REJECTED', SUBSTR(p_comments, 1, 500));

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
