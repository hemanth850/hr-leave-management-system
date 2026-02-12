WHENEVER SQLERROR EXIT SQL.SQLCODE;

SELECT request_id, employee_name, leave_code, status
  FROM v_leave_request_dashboard
 ORDER BY request_id;

SELECT employee_name, leave_code, balance_year, available_days
  FROM v_leave_balance_dashboard
 ORDER BY employee_name, leave_code;

SELECT request_id, status, current_queue_owner, pending_days
  FROM v_pending_approval_aging
 ORDER BY pending_days DESC;

SELECT status, channel, total_count
  FROM v_notification_summary
 ORDER BY status, channel;
