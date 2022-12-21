-- SAK-46974
ALTER TABLE MFR_MESSAGE_T ADD COLUMN SCHEDULER bit(1) DEFAULT 0 NOT NULL;
ALTER TABLE MFR_MESSAGE_T ADD COLUMN SCHEDULED_DATE DATETIME DEFAULT NULL;
-- End SAK-46974
-- SAK-46436
ALTER TABLE TASKS ADD COLUMN TASK_OWNER VARCHAR(99);

CREATE TABLE TASKS_ASSIGNED (
    ID           BIGINT      AUTO_INCREMENT PRIMARY KEY,
    TASK_ID      BIGINT      NOT NULL,
    ASSIGNATION_TYPE VARCHAR(5)  NOT NULL,
    OBJECT_ID    VARCHAR(99),
    CONSTRAINT FK_TASKS_ASSIGNED_TASKS FOREIGN KEY (TASK_ID) REFERENCES TASKS (ID)
);
CREATE INDEX IDX_TASKS_ASSIGNED ON TASKS_ASSIGNED (TASK_ID);

-- SAK-46178
ALTER TABLE rbc_tool_item_rbc_assoc CHANGE ownerId siteId varchar(99);
DROP INDEX rbc_tool_item_owner ON rbc_tool_item_rbc_assoc;
CREATE INDEX rbc_tool_item_active ON rbc_tool_item_rbc_assoc(toolId, itemId, active);
ALTER TABLE rbc_criterion ADD order_index INT DEFAULT NULL;
ALTER TABLE rbc_rating ADD order_index INT DEFAULT NULL;
UPDATE rbc_rating r, rbc_criterion_ratings cr SET r.criterion_id = cr.rbc_criterion_id, r.order_index = cr.order_index WHERE cr.ratings_id = r.id;
UPDATE rbc_criterion c, rbc_rubric_criterions rc SET c.rubric_id = rc.rbc_rubric_id, c.order_index = rc.order_index WHERE rc.criterions_id = c.id;
-- END SAK-46178

-- SAK-47784 Rubrics: Save Rubrics as Draft
ALTER TABLE rbc_rubric ADD draft bit(1) NOT NULL DEFAULT 0;
-- END SAK-47784

-- SAK-43542 Assignments: Provide more information in Removed Assignments/Trash list
ALTER TABLE ASN_ASSIGNMENT ADD SOFT_REMOVED_DATE DATETIME DEFAULT NULL;
-- END SAK-43542

-- SAK-47992 START
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_NAME) VALUES('roster.viewcandidatedetails');

INSERT INTO SAKAI_REALM_RL_FN VALUES (
    (SELECT REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'),
    (SELECT ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'),
    (SELECT FUNCTION_KEY  from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewcandidatedetails')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template.course'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'Instructor'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'roster.viewcandidatedetails')
);

CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP VALUES('maintain','roster.viewcandidatedetails');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES('Instructor','roster.viewcandidatedetails');

CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
FROM PERMISSIONS_SRC_TEMP TMPSRC
JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
SELECT
    SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
FROM
    (SELECT DISTINCT SRRF.REALM_KEY, SRRF.ROLE_KEY FROM SAKAI_REALM_RL_FN SRRF) SRRFD
    JOIN PERMISSIONS_TEMP TMP ON (SRRFD.ROLE_KEY = TMP.ROLE_KEY)
    JOIN SAKAI_REALM SR ON (SRRFD.REALM_KEY = SR.REALM_KEY)
    WHERE SR.REALM_ID != '!site.helper'
    AND NOT EXISTS (
        SELECT 1
            FROM SAKAI_REALM_RL_FN SRRFI
            WHERE SRRFI.REALM_KEY=SRRFD.REALM_KEY AND SRRFI.ROLE_KEY=SRRFD.ROLE_KEY AND SRRFI.FUNCTION_KEY=TMP.FUNCTION_KEY
    );

-- clean up the temp tables
DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_SRC_TEMP;
-- SAK-47992 END

-- SAK-48034 User Properties can be also assigned to external users.
-- IMPORTANT: Replace sakai_user_property_ibfk_1 by your foreign key name associated to the sakai_user_property table.
ALTER TABLE SAKAI_USER_PROPERTY DROP FOREIGN KEY sakai_user_property_ibfk_1;
-- END SAK-48034 User Properties can be also assigned to external users.

-- SAK-48085 - Add a few more roles from the LTI Spec
INSERT INTO SAKAI_REALM_ROLE VALUES (DEFAULT, 'ContentDeveloper');
INSERT INTO SAKAI_REALM_ROLE VALUES (DEFAULT, 'Manager');
INSERT INTO SAKAI_REALM_ROLE VALUES (DEFAULT, 'None');
INSERT INTO SAKAI_REALM_ROLE VALUES (DEFAULT, 'Officer');

-- SAK-48085 switches the approach from explicitly inserting all the roles into !site.template.lti (in SAK-39496 / KNL-879) To deriving
-- the roles in !site.template.lti from !site.template.course

DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti');

-- Instructor like roles pull roles from !site.template.course / Instructor
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Faculty') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'ContentDeveloper') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Staff') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Administrator') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor');

-- Teaching Assistant like roles pull roles from !site.template.course / Teaching Assistant
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant');

-- Student like roles pull roles from !site.template.course / Student
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Learner') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student');

-- Build Guest by initially copying !site.template.course / Student
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student');

-- Convert Guest to a read-only variant or Student by removing functions
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY = (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'section.role.student');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'assessment%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY = (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'chat.new');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'conversations%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'gradebook%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'dropbox%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY = (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'mailtool.send');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY = (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'mail.new');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'msg%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'roster%');

-- Clone reduced Guest role into Guest-like roles
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Observer') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Member') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Alumni') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'ProspectiveStudent') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Manager') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Other') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Officer') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'None') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Guest');

-- End of SAK-48085 - Improve Default Role Mapping
