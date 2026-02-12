CREATE OR REPLACE VIEW v_leave_request_dashboard AS
SELECT lr.request_id,
       lr.employee_id,
       e.emp_code,
       e.full_name AS employee_name,
       e.manager_id,
       m.full_name AS manager_name,
       lr.leave_type_id,
       lt.leave_code,
       lt.leave_name,
       lr.start_date,
       lr.end_date,
       lr.requested_days,
       lr.status,
       lr.submitted_at,
       lr.decided_at
  FROM leave_requests lr
  JOIN employees e
    ON e.employee_id = lr.employee_id
  LEFT JOIN employees m
    ON m.employee_id = e.manager_id
  JOIN leave_types lt
    ON lt.leave_type_id = lr.leave_type_id;

CREATE OR REPLACE VIEW v_leave_balance_dashboard AS
SELECT lb.employee_id,
       e.emp_code,
       e.full_name AS employee_name,
       lb.leave_type_id,
       lt.leave_code,
       lt.leave_name,
       lb.balance_year,
       lb.opening_balance_days,
       lb.accrued_days,
       lb.used_days,
       lb.adjusted_days,
       (lb.opening_balance_days + lb.accrued_days + lb.adjusted_days - lb.used_days) AS available_days,
       lb.updated_at
  FROM leave_balances lb
  JOIN employees e
    ON e.employee_id = lb.employee_id
  JOIN leave_types lt
    ON lt.leave_type_id = lb.leave_type_id;

CREATE OR REPLACE VIEW v_pending_approval_aging AS
SELECT lr.request_id,
       lr.status,
       lr.employee_id,
       e.full_name AS employee_name,
       CASE
           WHEN lr.status = 'PENDING_MANAGER' THEN m.full_name
           WHEN lr.status = 'PENDING_HR' THEN 'HR_QUEUE'
           ELSE NULL
       END AS current_queue_owner,
       lr.submitted_at,
       ROUND((CAST(SYSTIMESTAMP AS DATE) - CAST(lr.submitted_at AS DATE)), 2) AS pending_days
  FROM leave_requests lr
  JOIN employees e
    ON e.employee_id = lr.employee_id
  LEFT JOIN employees m
    ON m.employee_id = e.manager_id
 WHERE lr.status IN ('PENDING_MANAGER', 'PENDING_HR');

CREATE OR REPLACE VIEW v_notification_summary AS
SELECT status,
       channel,
       COUNT(*) AS total_count,
       MIN(created_at) AS oldest_created_at,
       MAX(created_at) AS latest_created_at
  FROM notification_queue
 GROUP BY status, channel;
