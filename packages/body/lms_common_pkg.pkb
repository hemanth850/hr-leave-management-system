CREATE OR REPLACE PACKAGE BODY lms_common_pkg AS
    FUNCTION is_weekend (p_day IN DATE) RETURN BOOLEAN IS
        l_day_name VARCHAR2(10);
    BEGIN
        l_day_name := TO_CHAR(p_day, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH');
        RETURN l_day_name IN ('SAT', 'SUN');
    END is_weekend;

    FUNCTION is_holiday (p_day IN DATE) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM holiday_calendar
         WHERE holiday_date = TRUNC(p_day);

        RETURN l_count > 0;
    END is_holiday;

    FUNCTION working_days_between (
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN NUMBER IS
        l_days NUMBER := 0;
        l_curr DATE;
    BEGIN
        IF p_end_date < p_start_date THEN
            RAISE_APPLICATION_ERROR(-20001, 'End date cannot be before start date.');
        END IF;

        l_curr := TRUNC(p_start_date);

        WHILE l_curr <= TRUNC(p_end_date) LOOP
            IF NOT is_weekend(l_curr) AND NOT is_holiday(l_curr) THEN
                l_days := l_days + 1;
            END IF;
            l_curr := l_curr + 1;
        END LOOP;

        RETURN l_days;
    END working_days_between;

    PROCEDURE log_error (
        p_module_name   IN VARCHAR2,
        p_error_message IN VARCHAR2,
        p_context_info  IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO app_error_log (module_name, error_message, context_info)
        VALUES (SUBSTR(p_module_name, 1, 100), SUBSTR(p_error_message, 1, 1000), SUBSTR(p_context_info, 1, 1000));
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END log_error;
END lms_common_pkg;
/
