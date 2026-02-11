# HR Leave Management System (PL/SQL)

Oracle PL/SQL project for end-to-end leave management with configurable leave types, balance tracking, role-based approvals, notifications, reporting, and scheduled maintenance.

## Features
- Employee and leave type master data
- Role mapping for authorization (`employee_roles`)
- Leave balance ledger by year
- Leave request lifecycle (`PENDING_MANAGER -> PENDING_HR -> APPROVED`)
- Role-based approval authorization
  - Manager-level actions require assigned manager (or `ADMIN`)
  - HR-level actions require `HR` role (or `ADMIN`)
- Rejection and cancellation support
- Weekend/holiday-aware working day calculation
- Employee onboarding, deactivation, and yearly balance initialization
- Notification queue enqueue + processing
- Monthly accrual run + scheduler job management
- Retention purge for notifications and error logs
- Ref cursor based reporting APIs
- Error logging (`app_error_log`)

## Repository Structure
- `ddl/`: schema DDL
- `data/seed/`: sample seed data
- `packages/spec/`: package specs
- `packages/body/`: package bodies
- `scripts/`: setup, compile, and job runners
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
- `lms_maintenance_pkg`
  - `purge_notification_queue`
  - `purge_error_logs`
  - `purge_old_data`
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
  - `run_retention_purge`
  - `create_monthly_accrual_job`
  - `drop_monthly_accrual_job`
  - `create_retention_purge_job`
  - `drop_retention_purge_job`

## Tests
- `tests/001_smoke_test.sql`: Leave request apply + 2-level approval flow
- `tests/002_employee_pkg_test.sql`: Employee lifecycle APIs
- `tests/003_report_pkg_test.sql`: Reporting API cursor fetch checks
- `tests/004_approval_notification_test.sql`: Dedicated approval package + queue writes
- `tests/005_scheduler_and_queue_test.sql`: Monthly accrual + queue processing
- `tests/006_authorization_and_overlap_test.sql`: Manager/HR authorization checks + overlap rejection
- `tests/007_retention_purge_test.sql`: Retention purge behavior for queue and error log

## Scheduler Script
- `scripts/manage_scheduler_job.sql`: Create and drop both jobs
  - `LMS_MONTHLY_ACCRUAL_JOB`
  - `LMS_RETENTION_PURGE_JOB`

## Notes
- Default seed data uses year `2026` balances.
- Seed roles include `ADMIN`, `HR`, and `MANAGER` for employee `E1000`.
- Update seed and test dates as required for your target demo year.
