# Release Checklist

## 1. Pre-Release Validation
- [ ] Connect to target Oracle schema (non-production first).
- [ ] Run `@scripts/bootstrap_and_test.sql` and confirm all scripts complete.
- [ ] Run `@scripts/demo_interview_flow.sql` and confirm expected outputs.
- [ ] Verify scheduler privileges for `DBMS_SCHEDULER` (create/drop jobs).
- [ ] Validate dashboard views return data:
  - `v_leave_request_dashboard`
  - `v_leave_balance_dashboard`
  - `v_pending_approval_aging`
  - `v_notification_summary`

## 2. Security & Role Verification
- [ ] Confirm `employee_roles` has expected role records (`EMPLOYEE`, `MANAGER`, `HR`, `ADMIN`).
- [ ] Verify manager-level approval enforcement.
- [ ] Verify HR-level approval enforcement.
- [ ] Verify self-approval restriction (except ADMIN).

## 3. Data Quality Checks
- [ ] Ensure seeded demo users exist (`E1000`, `E1001`, `E1002`).
- [ ] Confirm yearly balance records exist for current demo year.
- [ ] Confirm notification queue and app error log retention jobs are configured if needed.

## 4. Release Packaging
- [ ] Finalize README and docs.
- [ ] Tag release version (`v1.0.0` suggested for first stable release).
- [ ] Export SQL run order in release notes:
  1. `@scripts/run_all.sql`
  2. `@scripts/compile_all.sql`
  3. `@scripts/bootstrap_and_test.sql` (optional full verification)

## 5. Post-Release Verification
- [ ] Re-run smoke flow (`tests/001_smoke_test.sql`) on release schema.
- [ ] Validate scheduler jobs (if enabled):
  - `LMS_MONTHLY_ACCRUAL_JOB`
  - `LMS_RETENTION_PURGE_JOB`
- [ ] Check app logs for errors after first execution cycle.
