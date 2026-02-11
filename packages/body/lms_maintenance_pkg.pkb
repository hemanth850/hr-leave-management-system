CREATE OR REPLACE PACKAGE BODY lms_maintenance_pkg AS
    PROCEDURE purge_notification_queue (
        p_retain_days IN NUMBER DEFAULT 30,
        p_only_status IN VARCHAR2 DEFAULT 'SENT'
    ) IS
    BEGIN
        IF p_retain_days < 0 THEN
            RAISE_APPLICATION_ERROR(-20401, 'p_retain_days cannot be negative.');
        END IF;

        IF p_only_status IS NULL THEN
            DELETE FROM notification_queue
             WHERE created_at < SYSTIMESTAMP - NUMTODSINTERVAL(p_retain_days, 'DAY');
        ELSE
            DELETE FROM notification_queue
             WHERE status = UPPER(TRIM(p_only_status))
               AND created_at < SYSTIMESTAMP - NUMTODSINTERVAL(p_retain_days, 'DAY');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_maintenance_pkg.purge_notification_queue',
                SQLERRM,
                'retain_days=' || p_retain_days || ', status=' || NVL(p_only_status, 'NULL')
            );
            RAISE;
    END purge_notification_queue;

    PROCEDURE purge_error_logs (
        p_retain_days IN NUMBER DEFAULT 90
    ) IS
    BEGIN
        IF p_retain_days < 0 THEN
            RAISE_APPLICATION_ERROR(-20402, 'p_retain_days cannot be negative.');
        END IF;

        DELETE FROM app_error_log
         WHERE created_at < SYSTIMESTAMP - NUMTODSINTERVAL(p_retain_days, 'DAY');
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_maintenance_pkg.purge_error_logs',
                SQLERRM,
                'retain_days=' || p_retain_days
            );
            RAISE;
    END purge_error_logs;

    PROCEDURE purge_old_data (
        p_notif_retain_days IN NUMBER DEFAULT 30,
        p_error_retain_days IN NUMBER DEFAULT 90
    ) IS
    BEGIN
        purge_notification_queue(p_notif_retain_days, 'SENT');
        purge_error_logs(p_error_retain_days);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_maintenance_pkg.purge_old_data',
                SQLERRM,
                'notif_days=' || p_notif_retain_days || ', error_days=' || p_error_retain_days
            );
            ROLLBACK;
            RAISE;
    END purge_old_data;
END lms_maintenance_pkg;
/
