CREATE OR REPLACE PACKAGE lms_scheduler_pkg AS
    PROCEDURE run_monthly_accrual (
        p_run_date IN DATE DEFAULT TRUNC(SYSDATE)
    );

    PROCEDURE create_monthly_accrual_job;

    PROCEDURE drop_monthly_accrual_job;
END lms_scheduler_pkg;
/
