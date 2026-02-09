CREATE OR REPLACE PACKAGE BODY lms_report_pkg AS
    PROCEDURE get_pending_requests (
        p_for_level IN VARCHAR2,
        p_result    OUT SYS_REFCURSOR
    ) IS
        l_level VARCHAR2(20) := UPPER(TRIM(p_for_level));
    BEGIN
        IF l_level = 'MANAGER' THEN
            OPEN p_result FOR
                SELECT lr.request_id,
                       lr.employee_id,
                       e.full_name employee_name,
                       lt.leave_name,
                       lr.start_date,
                       lr.end_date,
                       lr.requested_days,
                       lr.status,
                       lr.submitted_at
                  FROM leave_requests lr
                  JOIN employees e ON e.employee_id = lr.employee_id
                  JOIN leave_types lt ON lt.leave_type_id = lr.leave_type_id
                 WHERE lr.status = 'PENDING_MANAGER'
                 ORDER BY lr.submitted_at;
        ELSIF l_level = 'HR' THEN
            OPEN p_result FOR
                SELECT lr.request_id,
                       lr.employee_id,
                       e.full_name employee_name,
                       lt.leave_name,
                       lr.start_date,
                       lr.end_date,
                       lr.requested_days,
                       lr.status,
                       lr.submitted_at
                  FROM leave_requests lr
                  JOIN employees e ON e.employee_id = lr.employee_id
                  JOIN leave_types lt ON lt.leave_type_id = lr.leave_type_id
                 WHERE lr.status = 'PENDING_HR'
                 ORDER BY lr.submitted_at;
        ELSE
            RAISE_APPLICATION_ERROR(-20201, 'p_for_level must be MANAGER or HR.');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_report_pkg.get_pending_requests',
                SQLERRM,
                'p_for_level=' || NVL(p_for_level, 'NULL')
            );
            RAISE;
    END get_pending_requests;

    PROCEDURE get_employee_balance_summary (
        p_employee_id IN NUMBER,
        p_balance_year IN NUMBER,
        p_result      OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_result FOR
            SELECT lb.employee_id,
                   e.full_name,
                   lb.balance_year,
                   lt.leave_code,
                   lt.leave_name,
                   lb.opening_balance_days,
                   lb.accrued_days,
                   lb.used_days,
                   lb.adjusted_days,
                   (lb.opening_balance_days + lb.accrued_days + lb.adjusted_days - lb.used_days) AS available_days,
                   lb.updated_at
              FROM leave_balances lb
              JOIN employees e ON e.employee_id = lb.employee_id
              JOIN leave_types lt ON lt.leave_type_id = lb.leave_type_id
             WHERE lb.employee_id = p_employee_id
               AND lb.balance_year = p_balance_year
             ORDER BY lt.leave_name;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_report_pkg.get_employee_balance_summary',
                SQLERRM,
                'employee_id=' || p_employee_id || ', year=' || p_balance_year
            );
            RAISE;
    END get_employee_balance_summary;

    PROCEDURE get_monthly_leave_trend (
        p_year   IN NUMBER,
        p_result OUT SYS_REFCURSOR
    ) IS
    BEGIN
        IF p_year < 2000 OR p_year > 2099 THEN
            RAISE_APPLICATION_ERROR(-20202, 'Invalid year for report.');
        END IF;

        OPEN p_result FOR
            SELECT EXTRACT(MONTH FROM lr.start_date) AS month_no,
                   COUNT(*) AS total_requests,
                   SUM(CASE WHEN lr.status = 'APPROVED' THEN 1 ELSE 0 END) AS approved_requests,
                   SUM(CASE WHEN lr.status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected_requests,
                   SUM(CASE WHEN lr.status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_requests,
                   SUM(lr.requested_days) AS total_requested_days
              FROM leave_requests lr
             WHERE EXTRACT(YEAR FROM lr.start_date) = p_year
             GROUP BY EXTRACT(MONTH FROM lr.start_date)
             ORDER BY month_no;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_report_pkg.get_monthly_leave_trend',
                SQLERRM,
                'year=' || p_year
            );
            RAISE;
    END get_monthly_leave_trend;
END lms_report_pkg;
/
