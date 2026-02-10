CREATE OR REPLACE PACKAGE BODY lms_notification_pkg AS
    PROCEDURE enqueue_notification (
        p_recipient_emp_id IN NUMBER,
        p_subject          IN VARCHAR2,
        p_message_body     IN VARCHAR2,
        p_channel          IN VARCHAR2 DEFAULT 'EMAIL'
    ) IS
    BEGIN
        INSERT INTO notification_queue (
            recipient_emp_id,
            subject,
            message_body,
            channel,
            status
        ) VALUES (
            p_recipient_emp_id,
            SUBSTR(p_subject, 1, 200),
            SUBSTR(p_message_body, 1, 1000),
            NVL(UPPER(TRIM(p_channel)), 'EMAIL'),
            'PENDING'
        );
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_notification_pkg.enqueue_notification',
                SQLERRM,
                'recipient_emp_id=' || p_recipient_emp_id
            );
            RAISE;
    END enqueue_notification;

    PROCEDURE process_pending_notifications (
        p_limit IN NUMBER DEFAULT 100
    ) IS
        CURSOR c_notif IS
            SELECT notification_id
              FROM notification_queue
             WHERE status = 'PENDING'
             ORDER BY created_at
             FOR UPDATE SKIP LOCKED;

        l_processed NUMBER := 0;
    BEGIN
        FOR rec IN c_notif LOOP
            EXIT WHEN l_processed >= NVL(p_limit, 100);

            UPDATE notification_queue
               SET status = 'SENT',
                   sent_at = SYSTIMESTAMP
             WHERE notification_id = rec.notification_id;

            l_processed := l_processed + 1;
        END LOOP;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_notification_pkg.process_pending_notifications',
                SQLERRM,
                'limit=' || NVL(TO_CHAR(p_limit), 'NULL')
            );
            ROLLBACK;
            RAISE;
    END process_pending_notifications;
END lms_notification_pkg;
/
