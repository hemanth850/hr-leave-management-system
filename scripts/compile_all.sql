WHENEVER SQLERROR EXIT SQL.SQLCODE;

PROMPT Compiling package specs...
@packages/spec/lms_common_pkg.pks
@packages/spec/lms_notification_pkg.pks
@packages/spec/lms_employee_pkg.pks
@packages/spec/lms_approval_pkg.pks
@packages/spec/lms_leave_pkg.pks
@packages/spec/lms_report_pkg.pks
@packages/spec/lms_scheduler_pkg.pks

PROMPT Compiling package bodies...
@packages/body/lms_common_pkg.pkb
@packages/body/lms_notification_pkg.pkb
@packages/body/lms_employee_pkg.pkb
@packages/body/lms_approval_pkg.pkb
@packages/body/lms_leave_pkg.pkb
@packages/body/lms_report_pkg.pkb
@packages/body/lms_scheduler_pkg.pkb

PROMPT Compilation completed.
