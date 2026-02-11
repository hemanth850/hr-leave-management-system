WHENEVER SQLERROR EXIT SQL.SQLCODE;

@scripts/run_all.sql
@scripts/compile_all.sql
@tests/001_smoke_test.sql
@tests/002_employee_pkg_test.sql
@tests/003_report_pkg_test.sql
@tests/004_approval_notification_test.sql
@tests/005_scheduler_and_queue_test.sql
@tests/006_authorization_and_overlap_test.sql
@tests/007_retention_purge_test.sql

EXIT;
