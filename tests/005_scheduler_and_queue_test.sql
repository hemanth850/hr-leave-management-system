SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_before NUMBER;
    l_after  NUMBER;
BEGIN
    SELECT accrued_days
      INTO l_before
      FROM leave_balances
     WHERE employee_id = 2
       AND leave_type_id = 1
       AND balance_year = 2026;

    lms_scheduler_pkg.run_monthly_accrual(DATE '2026-02-01');

    SELECT accrued_days
      INTO l_after
      FROM leave_balances
     WHERE employee_id = 2
       AND leave_type_id = 1
       AND balance_year = 2026;

    DBMS_OUTPUT.PUT_LINE('Accrued days before=' || l_before || ' after=' || l_after);
END;
/

BEGIN
    lms_notification_pkg.process_pending_notifications(200);
    DBMS_OUTPUT.PUT_LINE('Processed pending notifications.');
END;
/

SELECT status, COUNT(*) AS cnt
  FROM notification_queue
 GROUP BY status
 ORDER BY status;
