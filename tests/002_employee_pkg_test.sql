SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_new_emp_id NUMBER;
BEGIN
    lms_employee_pkg.create_employee(
        p_emp_code    => 'E1003',
        p_full_name   => 'Charlie Rivera',
        p_email       => 'charlie.rivera@acme.com',
        p_manager_id  => 1,
        p_hire_date   => DATE '2026-01-15',
        p_employee_id => l_new_emp_id
    );

    DBMS_OUTPUT.PUT_LINE('Created employee_id=' || l_new_emp_id);

    lms_employee_pkg.initialize_yearly_balances(2027);
    DBMS_OUTPUT.PUT_LINE('Initialized yearly balances for 2027');

    lms_employee_pkg.deactivate_employee(l_new_emp_id);
    DBMS_OUTPUT.PUT_LINE('Deactivated employee_id=' || l_new_emp_id);
END;
/

SELECT employee_id, emp_code, full_name, is_active
  FROM employees
 WHERE emp_code = 'E1003';

SELECT employee_id, leave_type_id, balance_year, accrued_days
  FROM leave_balances
 WHERE employee_id = (
       SELECT employee_id FROM employees WHERE emp_code = 'E1003'
  )
   AND balance_year = 2027
 ORDER BY leave_type_id;
