SET SERVEROUTPUT ON;

BEGIN
    lms_scheduler_pkg.create_monthly_accrual_job;
    DBMS_OUTPUT.PUT_LINE('Scheduler job created: LMS_MONTHLY_ACCRUAL_JOB');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Could not create scheduler job: ' || SQLERRM);
END;
/

BEGIN
    lms_scheduler_pkg.drop_monthly_accrual_job;
    DBMS_OUTPUT.PUT_LINE('Scheduler job dropped: LMS_MONTHLY_ACCRUAL_JOB');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Could not drop scheduler job: ' || SQLERRM);
END;
/
