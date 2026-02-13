# Commit Plan

Use this sequence to keep history clear and interview-friendly.

## Commit 1: Base System Setup
- DDL tables and seed data
- Initial package scaffolding
- Core setup scripts

## Commit 2: Core Leave Workflow
- `lms_common_pkg`
- `lms_leave_pkg` apply/cancel and compatibility wrappers
- Initial smoke tests

## Commit 3: Employee & Reporting Modules
- `lms_employee_pkg`
- `lms_report_pkg`
- tests for employee/reporting flows

## Commit 4: Approval Split, Notifications, Scheduler
- `lms_approval_pkg`
- `lms_notification_pkg`
- `lms_scheduler_pkg`
- queue and accrual tests

## Commit 5: Authorization and Retention
- `employee_roles` schema support
- role-based approval guards
- `lms_maintenance_pkg`
- retention purge tests

## Commit 6: Phase 5 Hardening and Dashboards
- hardened API validations in leave/approval packages
- dashboard views (`ddl/002_create_views.sql`)
- interview demo script
- hardening + view tests
- README polish

## Suggested Commit Message Format
- `feat(schema): add employee roles and retention tables`
- `feat(approval): enforce manager/hr authorization`
- `feat(reporting): add dashboard views for leave analytics`
- `test(leave): add hardening and overlap validation scenarios`
- `docs(project): add release checklist and interview pitch`
