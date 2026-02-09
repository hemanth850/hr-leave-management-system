CREATE OR REPLACE PACKAGE lms_report_pkg AS
    PROCEDURE get_pending_requests (
        p_for_level IN VARCHAR2,
        p_result    OUT SYS_REFCURSOR
    );

    PROCEDURE get_employee_balance_summary (
        p_employee_id IN NUMBER,
        p_balance_year IN NUMBER,
        p_result      OUT SYS_REFCURSOR
    );

    PROCEDURE get_monthly_leave_trend (
        p_year   IN NUMBER,
        p_result OUT SYS_REFCURSOR
    );
END lms_report_pkg;
/
