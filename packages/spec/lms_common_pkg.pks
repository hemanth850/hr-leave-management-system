CREATE OR REPLACE PACKAGE lms_common_pkg AS
    FUNCTION working_days_between (
        p_start_date IN DATE,
        p_end_date   IN DATE
    ) RETURN NUMBER;

    PROCEDURE log_error (
        p_module_name   IN VARCHAR2,
        p_error_message IN VARCHAR2,
        p_context_info  IN VARCHAR2 DEFAULT NULL
    );
END lms_common_pkg;
/
