SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_request_id NUMBER;
BEGIN
    lms_leave_pkg.apply_leave(
        p_employee_id   => 2,
        p_leave_type_id => 2,
        p_start_date    => DATE '2026-04-06',
        p_end_date      => DATE '2026-04-07',
        p_reason        => 'Doctor visit',
        p_request_id    => l_request_id
    );

    DBMS_OUTPUT.PUT_LINE('Applied request_id=' || l_request_id);

    lms_approval_pkg.approve_leave(
        p_request_id  => l_request_id,
        p_approver_id => 1,
        p_comments    => 'Manager approved via approval pkg'
    );

    lms_approval_pkg.approve_leave(
        p_request_id  => l_request_id,
        p_approver_id => 1,
        p_comments    => 'HR approved via approval pkg'
    );

    DBMS_OUTPUT.PUT_LINE('Approved request_id=' || l_request_id || ' through lms_approval_pkg');
END;
/

COLUMN status FORMAT A20
SELECT request_id, status, decided_at
  FROM leave_requests
 ORDER BY request_id DESC
 FETCH FIRST 3 ROWS ONLY;

SELECT status, COUNT(*) AS cnt
  FROM notification_queue
 GROUP BY status
 ORDER BY status;
