SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_request_id NUMBER;
BEGIN
    BEGIN
        lms_leave_pkg.apply_leave(
            p_employee_id   => 2,
            p_leave_type_id => 1,
            p_start_date    => DATE '2026-01-05',
            p_end_date      => DATE '2026-01-06',
            p_reason        => 'Backdated should fail',
            p_request_id    => l_request_id
        );
        DBMS_OUTPUT.PUT_LINE('Unexpected: backdated request succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected backdated rejection: ' || SQLERRM);
    END;

    BEGIN
        lms_leave_pkg.apply_leave(
            p_employee_id   => 2,
            p_leave_type_id => 1,
            p_start_date    => DATE '2026-12-31',
            p_end_date      => DATE '2027-01-02',
            p_reason        => 'Cross-year should fail',
            p_request_id    => l_request_id
        );
        DBMS_OUTPUT.PUT_LINE('Unexpected: cross-year request succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected cross-year rejection: ' || SQLERRM);
    END;
END;
/
