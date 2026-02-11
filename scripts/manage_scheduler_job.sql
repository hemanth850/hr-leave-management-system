SET SERVEROUTPUT ON;

BEGIN
    lms_scheduler_pkg.create_monthly_accrual_job;
    DBMS_OUTPUT.PUT_LINE('Scheduler job created: LMS_MONTHLY_ACCRUAL_JOB');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Could not create monthly accrual job: ' || SQLERRM);
END;
/

BEGIN
    lms_scheduler_pkg.create_retention_purge_job;
    DBMS_OUTPUT.PUT_LINE('Scheduler job created: LMS_RETENTION_PURGE_JOB');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Could not create retention purge job: ' || SQLERRM);
END;
/

BEGIN
    lms_scheduler_pkg.drop_monthly_accrual_job;
    DBMS_OUTPUT.PUT_LINE('Scheduler job dropped: LMS_MONTHLY_ACCRUAL_JOB');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Could not drop monthly accrual job: ' || SQLERRM);
END;
/

BEGIN
    lms_scheduler_pkg.drop_retention_purge_job;
    DBMS_OUTPUT.PUT_LINE('Scheduler job dropped: LMS_RETENTION_PURGE_JOB');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Could not drop retention purge job: ' || SQLERRM);
END;
/
