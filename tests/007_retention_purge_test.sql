SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_before_sent_notif NUMBER;
    l_before_pending_notif NUMBER;
    l_before_error_logs NUMBER;
    l_after_sent_notif NUMBER;
    l_after_pending_notif NUMBER;
    l_after_error_logs NUMBER;
BEGIN
    INSERT INTO notification_queue (recipient_emp_id, subject, message_body, channel, status)
    VALUES (2, 'Old sent notification', 'Should be purged', 'INAPP', 'SENT');

    UPDATE notification_queue
       SET created_at = SYSTIMESTAMP - NUMTODSINTERVAL(60, 'DAY')
     WHERE notification_id = (SELECT MAX(notification_id) FROM notification_queue);

    INSERT INTO notification_queue (recipient_emp_id, subject, message_body, channel, status)
    VALUES (2, 'Old pending notification', 'Should stay', 'INAPP', 'PENDING');

    UPDATE notification_queue
       SET created_at = SYSTIMESTAMP - NUMTODSINTERVAL(60, 'DAY')
     WHERE notification_id = (SELECT MAX(notification_id) FROM notification_queue);

    INSERT INTO app_error_log (module_name, error_message, context_info)
    VALUES ('phase4_test', 'old error for purge test', 'phase4');

    UPDATE app_error_log
       SET created_at = SYSTIMESTAMP - NUMTODSINTERVAL(120, 'DAY')
     WHERE error_id = (SELECT MAX(error_id) FROM app_error_log);

    COMMIT;

    SELECT COUNT(*) INTO l_before_sent_notif
      FROM notification_queue
     WHERE status = 'SENT'
       AND created_at < SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY');

    SELECT COUNT(*) INTO l_before_pending_notif
      FROM notification_queue
     WHERE status = 'PENDING'
       AND created_at < SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY');

    SELECT COUNT(*) INTO l_before_error_logs
      FROM app_error_log
     WHERE created_at < SYSTIMESTAMP - NUMTODSINTERVAL(90, 'DAY');

    DBMS_OUTPUT.PUT_LINE('Before purge old SENT notifications=' || l_before_sent_notif);
    DBMS_OUTPUT.PUT_LINE('Before purge old PENDING notifications=' || l_before_pending_notif);
    DBMS_OUTPUT.PUT_LINE('Before purge old error logs=' || l_before_error_logs);

    lms_scheduler_pkg.run_retention_purge;

    SELECT COUNT(*) INTO l_after_sent_notif
      FROM notification_queue
     WHERE status = 'SENT'
       AND created_at < SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY');

    SELECT COUNT(*) INTO l_after_pending_notif
      FROM notification_queue
     WHERE status = 'PENDING'
       AND created_at < SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY');

    SELECT COUNT(*) INTO l_after_error_logs
      FROM app_error_log
     WHERE created_at < SYSTIMESTAMP - NUMTODSINTERVAL(90, 'DAY');

    DBMS_OUTPUT.PUT_LINE('After purge old SENT notifications=' || l_after_sent_notif);
    DBMS_OUTPUT.PUT_LINE('After purge old PENDING notifications=' || l_after_pending_notif);
    DBMS_OUTPUT.PUT_LINE('After purge old error logs=' || l_after_error_logs);
END;
/

SELECT status, COUNT(*) AS cnt
  FROM notification_queue
 GROUP BY status
 ORDER BY status;
