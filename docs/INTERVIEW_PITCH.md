# Interview Pitch Script (2-3 Minutes)

## 1. Problem Statement
I built an Oracle PL/SQL Leave Management System that handles the full lifecycle of leave requests, approvals, balances, notifications, and operational maintenance.

## 2. Architecture Summary
The project is modular and package-driven:
- `lms_leave_pkg` handles leave application and cancellation.
- `lms_approval_pkg` enforces two-level approvals and role-based authorization.
- `lms_employee_pkg` manages employee lifecycle and annual balance initialization.
- `lms_notification_pkg` queues and processes notifications.
- `lms_scheduler_pkg` runs monthly accrual and retention jobs.
- `lms_report_pkg` exposes reporting APIs via ref cursors.

## 3. What Makes It Strong
- Role-based approval security using `employee_roles`.
- API hardening with strict input/state validations.
- Final approval balance re-check to prevent race-condition over-approval.
- Dashboard views for quick operational insights.
- Automated retention cleanup for notifications and error logs.

## 4. Demo Flow
I can run `scripts/demo_interview_flow.sql` to show:
1. Employee submits leave.
2. Manager approves.
3. HR approves.
4. Balance and notification dashboards update.

## 5. Engineering Quality
- End-to-end SQL test scripts (`tests/001` to `tests/009`).
- Structured setup/compile/bootstrap scripts.
- Clear separation of concerns between packages.
- Operational readiness with scheduler and retention jobs.

## 6. Future Improvements
- Add fine-grained approver delegation rules.
- Add REST exposure through Oracle ORDS.
- Add richer analytics views for SLA and utilization trends.
