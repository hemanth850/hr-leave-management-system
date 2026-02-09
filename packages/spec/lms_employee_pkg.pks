CREATE OR REPLACE PACKAGE lms_employee_pkg AS
    PROCEDURE create_employee (
        p_emp_code      IN VARCHAR2,
        p_full_name     IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_manager_id    IN NUMBER,
        p_hire_date     IN DATE,
        p_employee_id   OUT NUMBER
    );

    PROCEDURE deactivate_employee (
        p_employee_id IN NUMBER
    );

    PROCEDURE initialize_yearly_balances (
        p_balance_year IN NUMBER
    );
END lms_employee_pkg;
/
