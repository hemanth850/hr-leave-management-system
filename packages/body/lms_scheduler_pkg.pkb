CREATE OR REPLACE PACKAGE BODY lms_scheduler_pkg AS
    gc_monthly_job_name   CONSTANT VARCHAR2(30) := 'LMS_MONTHLY_ACCRUAL_JOB';
    gc_retention_job_name CONSTANT VARCHAR2(30) := 'LMS_RETENTION_PURGE_JOB';

    PROCEDURE run_monthly_accrual (
        p_run_date IN DATE DEFAULT TRUNC(SYSDATE)
    ) IS
        l_year NUMBER := EXTRACT(YEAR FROM TRUNC(p_run_date));
    BEGIN
        UPDATE leave_balances lb
           SET lb.accrued_days = lb.accrued_days + (
                   SELECT lt.yearly_quota_days / 12
                     FROM leave_types lt
                    WHERE lt.leave_type_id = lb.leave_type_id
               ),
               lb.updated_at = SYSTIMESTAMP
         WHERE lb.balance_year = l_year
           AND EXISTS (
               SELECT 1
                 FROM employees e
                WHERE e.employee_id = lb.employee_id
                  AND e.is_active = 'Y'
           )
           AND EXISTS (
               SELECT 1
                 FROM leave_types lt
                WHERE lt.leave_type_id = lb.leave_type_id
                  AND lt.is_active = 'Y'
           );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_scheduler_pkg.run_monthly_accrual',
                SQLERRM,
                'run_date=' || TO_CHAR(TRUNC(p_run_date), 'YYYY-MM-DD')
            );
            ROLLBACK;
            RAISE;
    END run_monthly_accrual;

    PROCEDURE run_retention_purge IS
    BEGIN
        lms_maintenance_pkg.purge_old_data(
            p_notif_retain_days => 30,
            p_error_retain_days => 90
        );
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_scheduler_pkg.run_retention_purge',
                SQLERRM,
                NULL
            );
            RAISE;
    END run_retention_purge;

    PROCEDURE create_monthly_accrual_job IS
    BEGIN
        BEGIN
            DBMS_SCHEDULER.DROP_JOB(job_name => gc_monthly_job_name, force => TRUE);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => gc_monthly_job_name,
            job_type        => 'PLSQL_BLOCK',
            job_action      => 'BEGIN lms_scheduler_pkg.run_monthly_accrual(TRUNC(SYSDATE)); END;',
            start_date      => SYSTIMESTAMP,
            repeat_interval => 'FREQ=MONTHLY;BYMONTHDAY=1;BYHOUR=1;BYMINUTE=0;BYSECOND=0',
            enabled         => TRUE,
            comments        => 'Accrues monthly leave balance for active employees.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_scheduler_pkg.create_monthly_accrual_job',
                SQLERRM,
                NULL
            );
            RAISE;
    END create_monthly_accrual_job;

    PROCEDURE drop_monthly_accrual_job IS
    BEGIN
        DBMS_SCHEDULER.DROP_JOB(job_name => gc_monthly_job_name, force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -27475 THEN
                lms_common_pkg.log_error(
                    'lms_scheduler_pkg.drop_monthly_accrual_job',
                    SQLERRM,
                    NULL
                );
                RAISE;
            END IF;
    END drop_monthly_accrual_job;

    PROCEDURE create_retention_purge_job IS
    BEGIN
        BEGIN
            DBMS_SCHEDULER.DROP_JOB(job_name => gc_retention_job_name, force => TRUE);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => gc_retention_job_name,
            job_type        => 'PLSQL_BLOCK',
            job_action      => 'BEGIN lms_scheduler_pkg.run_retention_purge; END;',
            start_date      => SYSTIMESTAMP,
            repeat_interval => 'FREQ=DAILY;BYHOUR=2;BYMINUTE=0;BYSECOND=0',
            enabled         => TRUE,
            comments        => 'Purges old notifications and error logs.'
        );
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_scheduler_pkg.create_retention_purge_job',
                SQLERRM,
                NULL
            );
            RAISE;
    END create_retention_purge_job;

    PROCEDURE drop_retention_purge_job IS
    BEGIN
        DBMS_SCHEDULER.DROP_JOB(job_name => gc_retention_job_name, force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -27475 THEN
                lms_common_pkg.log_error(
                    'lms_scheduler_pkg.drop_retention_purge_job',
                    SQLERRM,
                    NULL
                );
                RAISE;
            END IF;
    END drop_retention_purge_job;
END lms_scheduler_pkg;
/
