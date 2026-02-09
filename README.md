# HR Leave Management System (PL/SQL)

Oracle PL/SQL project for end-to-end leave management with configurable leave types, balance tracking, approvals, employee lifecycle, and reporting.

## Features
- Employee and leave type master data
- Leave balance ledger by year
- Leave request lifecycle (`PENDING_MANAGER -> PENDING_HR -> APPROVED`)
- Rejection and cancellation support
- Weekend/holiday-aware working day calculation
- Employee onboarding, deactivation, and yearly balance initialization
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
- `lms_employee_pkg`
  - `create_employee`
  - `deactivate_employee`
  - `initialize_yearly_balances`
- `lms_leave_pkg`
  - `apply_leave`
  - `approve_leave`
  - `reject_leave`
  - `cancel_leave`
- `lms_report_pkg`
  - `get_pending_requests`
  - `get_employee_balance_summary`
  - `get_monthly_leave_trend`

## Tests
- `tests/001_smoke_test.sql`: Leave request apply + 2-level approval flow
- `tests/002_employee_pkg_test.sql`: Employee lifecycle APIs
- `tests/003_report_pkg_test.sql`: Reporting API cursor fetch checks

## Notes
- Default seed data uses year `2026` balances.
- Update seed and test dates as required for your target demo year.
