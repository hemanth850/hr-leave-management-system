SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_request_id NUMBER;
BEGIN
    lms_leave_pkg.apply_leave(
        p_employee_id   => 2,
        p_leave_type_id => 1,
        p_start_date    => DATE '2026-03-02',
        p_end_date      => DATE '2026-03-04',
        p_reason        => 'Family event',
        p_request_id    => l_request_id
    );
    DBMS_OUTPUT.PUT_LINE('Applied request_id=' || l_request_id);

    lms_leave_pkg.approve_leave(
        p_request_id  => l_request_id,
        p_approver_id => 1,
        p_comments    => 'Manager approved'
    );
    DBMS_OUTPUT.PUT_LINE('Manager approval done for request_id=' || l_request_id);

    lms_leave_pkg.approve_leave(
        p_request_id  => l_request_id,
        p_approver_id => 1,
        p_comments    => 'HR approved'
    );
    DBMS_OUTPUT.PUT_LINE('HR approval done for request_id=' || l_request_id);
END;
/

COLUMN status FORMAT A20
SELECT request_id, employee_id, status, requested_days
  FROM leave_requests
 ORDER BY request_id;

SELECT employee_id, leave_type_id, balance_year, used_days
  FROM leave_balances
 WHERE employee_id = 2
   AND leave_type_id = 1
   AND balance_year = 2026;
