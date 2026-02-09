SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_rc SYS_REFCURSOR;
    l_request_id NUMBER;
    l_employee_id NUMBER;
    l_employee_name VARCHAR2(120);
    l_leave_name VARCHAR2(80);
    l_start_date DATE;
    l_end_date DATE;
    l_requested_days NUMBER;
    l_status VARCHAR2(30);
    l_submitted_at TIMESTAMP;

    l_balance_year NUMBER;
    l_leave_code VARCHAR2(30);
    l_opening NUMBER;
    l_accrued NUMBER;
    l_used NUMBER;
    l_adjusted NUMBER;
    l_available NUMBER;
    l_updated_at TIMESTAMP;

    l_month_no NUMBER;
    l_total_requests NUMBER;
    l_approved NUMBER;
    l_rejected NUMBER;
    l_cancelled NUMBER;
    l_total_days NUMBER;
BEGIN
    lms_report_pkg.get_pending_requests('MANAGER', l_rc);
    LOOP
        FETCH l_rc INTO l_request_id, l_employee_id, l_employee_name, l_leave_name,
                        l_start_date, l_end_date, l_requested_days, l_status, l_submitted_at;
        EXIT WHEN l_rc%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('PENDING_MANAGER request=' || l_request_id || ' emp=' || l_employee_name);
    END LOOP;
    CLOSE l_rc;

    lms_report_pkg.get_employee_balance_summary(2, 2026, l_rc);
    LOOP
        FETCH l_rc INTO l_employee_id, l_employee_name, l_balance_year, l_leave_code, l_leave_name,
                        l_opening, l_accrued, l_used, l_adjusted, l_available, l_updated_at;
        EXIT WHEN l_rc%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('BALANCE leave=' || l_leave_code || ' available=' || l_available);
    END LOOP;
    CLOSE l_rc;

    lms_report_pkg.get_monthly_leave_trend(2026, l_rc);
    LOOP
        FETCH l_rc INTO l_month_no, l_total_requests, l_approved, l_rejected, l_cancelled, l_total_days;
        EXIT WHEN l_rc%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('TREND month=' || l_month_no || ' total=' || l_total_requests);
    END LOOP;
    CLOSE l_rc;
END;
/
