CREATE OR REPLACE PACKAGE lms_notification_pkg AS
    PROCEDURE enqueue_notification (
        p_recipient_emp_id IN NUMBER,
        p_subject          IN VARCHAR2,
        p_message_body     IN VARCHAR2,
        p_channel          IN VARCHAR2 DEFAULT 'EMAIL'
    );

    PROCEDURE process_pending_notifications (
        p_limit IN NUMBER DEFAULT 100
    );
END lms_notification_pkg;
/
