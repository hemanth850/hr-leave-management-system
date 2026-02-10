CREATE OR REPLACE PACKAGE lms_approval_pkg AS
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
END lms_approval_pkg;
/
