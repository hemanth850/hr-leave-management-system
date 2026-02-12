SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

PROMPT ===== DEMO: Employee submits leave =====
DECLARE
    l_request_id NUMBER;
BEGIN
    lms_leave_pkg.apply_leave(
        p_employee_id   => 2,
        p_leave_type_id => 1,
        p_start_date    => DATE '2026-06-15',
        p_end_date      => DATE '2026-06-17',
        p_reason        => 'Conference travel',
        p_request_id    => l_request_id
    );
    DBMS_OUTPUT.PUT_LINE('Created request_id=' || l_request_id);
END;
/

PROMPT ===== DEMO: Manager queue snapshot =====
SELECT request_id, employee_name, leave_code, start_date, end_date, status
  FROM v_leave_request_dashboard
 WHERE status = 'PENDING_MANAGER'
 ORDER BY submitted_at;

PROMPT ===== DEMO: Manager approves =====
DECLARE
    l_request_id NUMBER;
BEGIN
    SELECT MAX(request_id)
      INTO l_request_id
      FROM leave_requests
     WHERE employee_id = 2
       AND start_date = DATE '2026-06-15';

    lms_approval_pkg.approve_leave(
        p_request_id  => l_request_id,
        p_approver_id => 1,
        p_comments    => 'Manager approved demo request'
    );
    DBMS_OUTPUT.PUT_LINE('Manager approved request_id=' || l_request_id);
END;
/

PROMPT ===== DEMO: HR queue snapshot =====
SELECT request_id, employee_name, leave_code, start_date, end_date, status
  FROM v_leave_request_dashboard
 WHERE status = 'PENDING_HR'
 ORDER BY submitted_at;

PROMPT ===== DEMO: HR approves =====
DECLARE
    l_request_id NUMBER;
BEGIN
    SELECT MAX(request_id)
      INTO l_request_id
      FROM leave_requests
     WHERE employee_id = 2
       AND start_date = DATE '2026-06-15';

    lms_approval_pkg.approve_leave(
        p_request_id  => l_request_id,
        p_approver_id => 1,
        p_comments    => 'HR approved demo request'
    );
    DBMS_OUTPUT.PUT_LINE('HR approved request_id=' || l_request_id);
END;
/

PROMPT ===== DEMO: Dashboard views =====
SELECT employee_name, leave_code, balance_year, available_days
  FROM v_leave_balance_dashboard
 WHERE employee_id = 2
   AND balance_year = 2026
 ORDER BY leave_code;

SELECT status, channel, total_count
  FROM v_notification_summary
 ORDER BY status, channel;
