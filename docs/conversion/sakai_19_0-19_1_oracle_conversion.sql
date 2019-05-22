-- SAK-41207 Add indexes
CREATE INDEX UK_hyk73ocki8gwvm3ajf8ls08ac ON ASN_ASSIGNMENT_ATTACHMENTS (ASSIGNMENT_ID);
CREATE INDEX UK_8ewbxsplke3c487h0tjujvtm ON ASN_ASSIGNMENT_GROUPS (ASSIGNMENT_ID);
CREATE INDEX UK_jg017qxc4pv3mdf07c1xpytb8 ON ASN_SUBMISSION_ATTACHMENTS (SUBMISSION_ID);
CREATE INDEX UK_3dou5gsqcya4rwwy99l91fofb ON ASN_SUBMISSION_FEEDBACK_ATTACH (SUBMISSION_ID);
-- END SAK-41207

-- SAK-41828 remove grade override from submitter when not a group submission
UPDATE asn_submission_submitter ss
    SET ss.GRADE = NULL
    WHERE EXISTS
        ( SELECT 1 FROM asn_submission_submitter ss1
            JOIN asn_submission s ON (s.SUBMISSION_ID = ss.SUBMISSION_ID)
            JOIN asn_assignment a ON (s.ASSIGNMENT_ID = a.ASSIGNMENT_ID)
            WHERE a.IS_GROUP IS FALSE
                AND s.grade IS NOT NULL
                AND ss1.grade IS NOT NULL
        );
-- END SAK-41828