-- Seed reference data

INSERT INTO employees (emp_code, full_name, email, manager_id, hire_date)
VALUES ('E1000', 'HR Admin', 'hr.admin@acme.com', NULL, DATE '2020-01-10');

INSERT INTO employees (emp_code, full_name, email, manager_id, hire_date)
VALUES ('E1001', 'Alice Johnson', 'alice.johnson@acme.com', 1, DATE '2021-03-15');

INSERT INTO employees (emp_code, full_name, email, manager_id, hire_date)
VALUES ('E1002', 'Bob Smith', 'bob.smith@acme.com', 1, DATE '2022-07-01');

INSERT INTO leave_types (leave_code, leave_name, yearly_quota_days, carry_forward_allowed)
VALUES ('ANNUAL', 'Annual Leave', 24, 'Y');

INSERT INTO leave_types (leave_code, leave_name, yearly_quota_days, carry_forward_allowed)
VALUES ('SICK', 'Sick Leave', 12, 'N');

INSERT INTO leave_types (leave_code, leave_name, yearly_quota_days, carry_forward_allowed)
VALUES ('CASUAL', 'Casual Leave', 8, 'N');

INSERT INTO holiday_calendar (holiday_date, holiday_name, is_optional)
VALUES (DATE '2026-01-01', 'New Year''s Day', 'N');

INSERT INTO holiday_calendar (holiday_date, holiday_name, is_optional)
VALUES (DATE '2026-07-04', 'Independence Day', 'N');

INSERT INTO holiday_calendar (holiday_date, holiday_name, is_optional)
VALUES (DATE '2026-12-25', 'Christmas Day', 'N');

INSERT INTO leave_balances (employee_id, leave_type_id, balance_year, opening_balance_days, accrued_days, used_days, adjusted_days)
SELECT e.employee_id, l.leave_type_id, 2026,
       CASE WHEN l.leave_code = 'ANNUAL' THEN 2 ELSE 0 END,
       l.yearly_quota_days,
       0,
       0
FROM employees e
CROSS JOIN leave_types l
WHERE e.emp_code IN ('E1001', 'E1002');

COMMIT;
