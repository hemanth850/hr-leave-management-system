SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_request_id NUMBER;
BEGIN
    lms_leave_pkg.apply_leave(
        p_employee_id   => 2,
        p_leave_type_id => 1,
        p_start_date    => DATE '2026-05-11',
        p_end_date      => DATE '2026-05-12',
        p_reason        => 'Authorization and overlap test',
        p_request_id    => l_request_id
    );

    DBMS_OUTPUT.PUT_LINE('Created request_id=' || l_request_id);

    BEGIN
        lms_approval_pkg.approve_leave(
            p_request_id  => l_request_id,
            p_approver_id => 3,
            p_comments    => 'Should fail manager-level authorization'
        );
        DBMS_OUTPUT.PUT_LINE('Unexpected: non-manager approved at manager level');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected manager-level authorization failure: ' || SQLERRM);
    END;

    lms_approval_pkg.approve_leave(
        p_request_id  => l_request_id,
        p_approver_id => 1,
        p_comments    => 'Manager approval success'
    );
    DBMS_OUTPUT.PUT_LINE('Manager-level approval done');

    BEGIN
        lms_approval_pkg.approve_leave(
            p_request_id  => l_request_id,
            p_approver_id => 3,
            p_comments    => 'Should fail HR-level authorization'
        );
        DBMS_OUTPUT.PUT_LINE('Unexpected: non-HR approved at HR level');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected HR-level authorization failure: ' || SQLERRM);
    END;

    lms_approval_pkg.approve_leave(
        p_request_id  => l_request_id,
        p_approver_id => 1,
        p_comments    => 'HR approval success'
    );
    DBMS_OUTPUT.PUT_LINE('HR-level approval done');

    BEGIN
        lms_leave_pkg.apply_leave(
            p_employee_id   => 2,
            p_leave_type_id => 1,
            p_start_date    => DATE '2026-05-12',
            p_end_date      => DATE '2026-05-13',
            p_reason        => 'Overlapping request should fail',
            p_request_id    => l_request_id
        );
        DBMS_OUTPUT.PUT_LINE('Unexpected: overlapping leave was accepted');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected overlap failure: ' || SQLERRM);
    END;
END;
/

SELECT request_id, status
  FROM leave_requests
 WHERE employee_id = 2
   AND start_date = DATE '2026-05-11';

SELECT request_id, approval_level, action_taken, approver_id
  FROM leave_approvals
 WHERE request_id = (
       SELECT MAX(request_id)
         FROM leave_requests
        WHERE employee_id = 2
          AND start_date = DATE '2026-05-11'
  )
 ORDER BY approval_level;
