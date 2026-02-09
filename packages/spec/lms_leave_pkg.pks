CREATE OR REPLACE PACKAGE lms_leave_pkg AS
    PROCEDURE apply_leave (
        p_employee_id   IN NUMBER,
        p_leave_type_id IN NUMBER,
        p_start_date    IN DATE,
        p_end_date      IN DATE,
        p_reason        IN VARCHAR2,
        p_request_id    OUT NUMBER
    );

    PROCEDURE approve_leave (
        p_request_id  IN NUMBER,
        p_approver_id IN NUMBER,
        p_comments    IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE reject_leave (
        p_request_id  IN NUMBER,
        p_approver_id IN NUMBER,
        p_comments    IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE cancel_leave (
        p_request_id     IN NUMBER,
        p_employee_id    IN NUMBER,
        p_cancel_reason  IN VARCHAR2 DEFAULT NULL
    );
END lms_leave_pkg;
/
