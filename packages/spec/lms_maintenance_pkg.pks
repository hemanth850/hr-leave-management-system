CREATE OR REPLACE PACKAGE lms_maintenance_pkg AS
    PROCEDURE purge_notification_queue (
        p_retain_days IN NUMBER DEFAULT 30,
        p_only_status IN VARCHAR2 DEFAULT 'SENT'
    );

    PROCEDURE purge_error_logs (
        p_retain_days IN NUMBER DEFAULT 90
    );

    PROCEDURE purge_old_data (
        p_notif_retain_days IN NUMBER DEFAULT 30,
        p_error_retain_days IN NUMBER DEFAULT 90
    );
END lms_maintenance_pkg;
/
