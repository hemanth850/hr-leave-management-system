# HR Leave Management System (PL/SQL)

Oracle PL/SQL project for end-to-end leave management with configurable leave types, balance tracking, approvals, employee lifecycle, reporting, notifications, and monthly accrual scheduling.

## Features
- Employee and leave type master data
- Leave balance ledger by year
- Leave request lifecycle (`PENDING_MANAGER -> PENDING_HR -> APPROVED`)
- Dedicated approval package (`lms_approval_pkg`)
- Rejection and cancellation support
- Weekend/holiday-aware working day calculation
- Employee onboarding, deactivation, and yearly balance initialization
- Notification queue enqueue + processing
- Monthly accrual run + scheduler job management
- Ref cursor based reporting APIs
- Error logging (`app_error_log`)

## Repository Structure
- `ddl/`: schema DDL
- `data/seed/`: sample seed data
- `packages/spec/`: package specs
- `packages/body/`: package bodies
- `scripts/`: setup and compile runners
- `tests/`: smoke and package tests

## Setup
Run from SQL*Plus/SQLcl while connected to your target schema:

```sql
@scripts/run_all.sql
@scripts/compile_all.sql
```

Or run setup + compile + all tests in one shot:

```sql
@scripts/bootstrap_and_test.sql
```

## Packages
- `lms_common_pkg`
  - `working_days_between`
  - `log_error`
- `lms_notification_pkg`
  - `enqueue_notification`
  - `process_pending_notifications`
- `lms_employee_pkg`
  - `create_employee`
  - `deactivate_employee`
  - `initialize_yearly_balances`
- `lms_approval_pkg`
  - `approve_leave`
  - `reject_leave`
- `lms_leave_pkg`
  - `apply_leave`
  - `approve_leave` (compatibility wrapper)
  - `reject_leave` (compatibility wrapper)
  - `cancel_leave`
- `lms_report_pkg`
  - `get_pending_requests`
  - `get_employee_balance_summary`
  - `get_monthly_leave_trend`
- `lms_scheduler_pkg`
  - `run_monthly_accrual`
  - `create_monthly_accrual_job`
  - `drop_monthly_accrual_job`

## Tests
- `tests/001_smoke_test.sql`: Leave request apply + 2-level approval flow
- `tests/002_employee_pkg_test.sql`: Employee lifecycle APIs
- `tests/003_report_pkg_test.sql`: Reporting API cursor fetch checks
- `tests/004_approval_notification_test.sql`: Dedicated approval package + queue writes
- `tests/005_scheduler_and_queue_test.sql`: Monthly accrual + queue processing

## Scheduler Script
- `scripts/manage_scheduler_job.sql`: Create and drop scheduler job (`LMS_MONTHLY_ACCRUAL_JOB`)

## Notes
- Default seed data uses year `2026` balances.
- Update seed and test dates as required for your target demo year.
