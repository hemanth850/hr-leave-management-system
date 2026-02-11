CREATE OR REPLACE PACKAGE BODY lms_employee_pkg AS
    PROCEDURE validate_manager (p_manager_id IN NUMBER) IS
        l_active CHAR(1);
    BEGIN
        IF p_manager_id IS NULL THEN
            RETURN;
        END IF;

        SELECT is_active
          INTO l_active
          FROM employees
         WHERE employee_id = p_manager_id;

        IF l_active <> 'Y' THEN
            RAISE_APPLICATION_ERROR(-20101, 'Manager is not active.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Manager not found.');
    END validate_manager;

    PROCEDURE create_employee (
        p_emp_code      IN VARCHAR2,
        p_full_name     IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_manager_id    IN NUMBER,
        p_hire_date     IN DATE,
        p_employee_id   OUT NUMBER
    ) IS
    BEGIN
        validate_manager(p_manager_id);

        INSERT INTO employees (
            emp_code,
            full_name,
            email,
            manager_id,
            hire_date,
            is_active
        ) VALUES (
            TRIM(p_emp_code),
            TRIM(p_full_name),
            LOWER(TRIM(p_email)),
            p_manager_id,
            TRUNC(p_hire_date),
            'Y'
        ) RETURNING employee_id INTO p_employee_id;

        INSERT INTO employee_roles (employee_id, role_code, is_active)
        VALUES (p_employee_id, 'EMPLOYEE', 'Y');

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_employee_pkg.create_employee',
                SQLERRM,
                'emp_code=' || NVL(p_emp_code, 'NULL')
            );
            ROLLBACK;
            RAISE;
    END create_employee;

    PROCEDURE deactivate_employee (
        p_employee_id IN NUMBER
    ) IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM leave_requests
         WHERE employee_id = p_employee_id
           AND status IN ('PENDING_MANAGER', 'PENDING_HR');

        IF l_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20103, 'Cannot deactivate employee with pending leave requests.');
        END IF;

        UPDATE employees
           SET is_active = 'N'
         WHERE employee_id = p_employee_id
           AND is_active = 'Y';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20104, 'Employee not found or already inactive.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_employee_pkg.deactivate_employee',
                SQLERRM,
                'employee_id=' || p_employee_id
            );
            ROLLBACK;
            RAISE;
    END deactivate_employee;

    PROCEDURE initialize_yearly_balances (
        p_balance_year IN NUMBER
    ) IS
    BEGIN
        IF p_balance_year < 2000 OR p_balance_year > 2099 THEN
            RAISE_APPLICATION_ERROR(-20105, 'Invalid balance year.');
        END IF;

        INSERT INTO leave_balances (
            employee_id,
            leave_type_id,
            balance_year,
            opening_balance_days,
            accrued_days,
            used_days,
            adjusted_days
        )
        SELECT e.employee_id,
               lt.leave_type_id,
               p_balance_year,
               CASE
                   WHEN lt.carry_forward_allowed = 'Y' THEN
                       NVL((
                           SELECT opening_balance_days + accrued_days + adjusted_days - used_days
                             FROM leave_balances lb_prev
                            WHERE lb_prev.employee_id = e.employee_id
                              AND lb_prev.leave_type_id = lt.leave_type_id
                              AND lb_prev.balance_year = p_balance_year - 1
                       ), 0)
                   ELSE 0
               END AS opening_balance_days,
               lt.yearly_quota_days,
               0,
               0
          FROM employees e
          CROSS JOIN leave_types lt
         WHERE e.is_active = 'Y'
           AND lt.is_active = 'Y'
           AND NOT EXISTS (
               SELECT 1
                 FROM leave_balances lb
                WHERE lb.employee_id = e.employee_id
                  AND lb.leave_type_id = lt.leave_type_id
                  AND lb.balance_year = p_balance_year
           );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            lms_common_pkg.log_error(
                'lms_employee_pkg.initialize_yearly_balances',
                SQLERRM,
                'balance_year=' || p_balance_year
            );
            ROLLBACK;
            RAISE;
    END initialize_yearly_balances;
END lms_employee_pkg;
/
