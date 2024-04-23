-- clear unchanged bundle properties
DELETE SAKAI_MESSAGE_BUNDLE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

-- SAK-46974
ALTER TABLE MFR_MESSAGE_T ADD SCHEDULER NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE MFR_MESSAGE_T ADD SCHEDULED_DATE TIMESTAMP DEFAULT NULL;
-- End SAK-46974

-- SAK-46436
ALTER TABLE TASKS ADD TASK_OWNER VARCHAR2(99 CHAR);

CREATE TABLE TASKS_ASSIGNED
(
   ID              NUMBER(19,0) NOT NULL,
   TASK_ID         NUMBER(19,0) NOT NULL,
   ASSIGNATION_TYPE   VARCHAR2(5) NOT NULL,
   OBJECT_ID       VARCHAR2(99 CHAR),
   PRIMARY KEY(ID),
   CONSTRAINT FK_TASKS_ASSIGNED_TASKS FOREIGN KEY(TASK_ID) REFERENCES TASKS (ID)
);

CREATE SEQUENCE TASKS_ASSIGNED_S MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;
CREATE INDEX IDX_TASKS_ASSIGNED ON TASKS_ASSIGNED (TASK_ID);

-- SAK-46178
RENAME COLUMN rbc_tool_item_rbc_assoc.ownerId TO siteId;
DROP INDEX rbc_tool_item_owner;
CREATE INDEX rbc_tool_item_active ON rbc_tool_item_rbc_assoc(toolId, itemId, active);
ALTER TABLE rbc_criterion ADD order_index NUMBER(1,0) NULL;
ALTER TABLE rbc_rating ADD order_index NUMBER(1,0) NULL;
UPDATE rbc_rating r, rbc_criterion_ratings cr SET r.criterion_id = cr.rbc_criterion_id, r.order_index = cr.order_index WHERE cr.ratings_id = r.id;
UPDATE rbc_criterion c, rbc_rubric_criterions rc SET c.rubric_id = rc.rbc_rubric_id, c.order_index = rc.order_index WHERE rc.criterions_id = c.id;
-- END SAK-46178

-- SAK-47246
ALTER TABLE SAKAI_MESSAGE_BUNDLE DROP KEY SMB_SEARCH;
ALTER TABLE SAKAI_MESSAGE_BUNDLE ADD CONSTRAINT SMB_SEARCH UNIQUE (BASENAME, MODULE_NAME, LOCALE, PROP_NAME);
-- END SAK-47246

-- SAK-47784 Rubrics: Save Rubrics as Draft
ALTER TABLE rbc_rubric ADD draft NUMBER(1) DEFAULT 0 NOT NULL;
-- END SAK-47784

-- SAK-43542 Assignments: Provide more information in Removed Assignments/Trash list
ALTER TABLE ASN_ASSIGNMENT ADD SOFT_REMOVED_DATE TIMESTAMP DEFAULT NULL;
-- END SAK-43542

-- SAK-47992 START
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_KEY, FUNCTION_NAME) VALUES(SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'roster.viewcandidatedetails');

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'maintain'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'roster.viewcandidatedetails')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template.course'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'Instructor'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'roster.viewcandidatedetails')
);

-- SAK-47992 START
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP VALUES('maintain','roster.viewcandidatedetails');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES('Instructor','roster.viewcandidatedetails');

CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
FROM PERMISSIONS_SRC_TEMP TMPSRC
JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

-- insert the new function into the roles of any existing realm that has the role (don't convert the "!site.helper")
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

-- SAK-48034 User Properties: Cannot add user properties to external users (LDAP)
-- IMPORTANT: Replace SYS_C0013939 by your foreign key name associated to the sakai_user_property table.
ALTER TABLE SAKAI_USER_PROPERTY DROP FOREIGN KEY SYS_C0013939;
-- END SAK-48034 User Properties: Cannot add user properties to external users (LDAP)

-- SAK-48021

-- Create the !plussite site.

INSERT INTO SAKAI_SITE VALUES('!plussite', 'plussite', null, 'SakaiPlus Template', 'Default template used when SakaiPlus creates a new site', null, null, null, 0, 0, 0, 'access', 'admin', 'admin', SYSDATE, SYSDATE, 1, 0, 0, 0, null);
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-100', '!plussite', 'Dashboard', '0', 1, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-110', '!plussite-100', '!plussite', 'sakai.dashboard', 1, 'Dashboard', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-200', '!plussite', 'Announcements', '0', 2, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-210', '!plussite-200', '!plussite', 'sakai.announcements', 1, 'Announcements', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-300', '!plussite', 'Assignments', '0', 3, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-310', '!plussite-300', '!plussite', 'sakai.assignment.grades', 1, 'Assignments', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-400', '!plussite', 'Grades', '0', 4, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-410', '!plussite-400', '!plussite', 'sakai.gradebookng', 1, 'Grades', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-500', '!plussite', 'Lessons', '0', 5, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-510', '!plussite-500', '!plussite', 'sakai.lessonbuildertool', 1, 'Lessons', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-600', '!plussite', 'Resources', '0', 6, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-610', '!plussite-600', '!plussite', 'sakai.resources', 1, 'Resources', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-700', '!plussite', 'Conversations', '0', 7, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-710', '!plussite-700', '!plussite', 'sakai.conversations', 1, 'Conversations', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-800', '!plussite', 'Chat', '0', 8, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-810', '!plussite-800', '!plussite', 'sakai.chat', 1, 'Chat', NULL );
INSERT INTO SAKAI_SITE_TOOL_PROPERTY VALUES('!plussite', '!plussite-810', 'display-date', 'true' );
INSERT INTO SAKAI_SITE_TOOL_PROPERTY VALUES('!plussite', '!plussite-810', 'filter-param', '3' );
INSERT INTO SAKAI_SITE_TOOL_PROPERTY VALUES('!plussite', '!plussite-810', 'display-time', 'true' );
INSERT INTO SAKAI_SITE_TOOL_PROPERTY VALUES('!plussite', '!plussite-810', 'sound-alert', 'true' );
INSERT INTO SAKAI_SITE_TOOL_PROPERTY VALUES('!plussite', '!plussite-810', 'filter-type', 'SelectMessagesByTime' );
INSERT INTO SAKAI_SITE_TOOL_PROPERTY VALUES('!plussite', '!plussite-810', 'display-user', 'true' );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-900', '!plussite', 'Calendar', '0', 9, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-910', '!plussite-900', '!plussite', 'sakai.schedule', 1, 'Calendar', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-1000', '!plussite', 'Roster', '0', 10, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-1010', '!plussite-1000', '!plussite', 'sakai.site.roster2', 1, 'Roster', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-1100', '!plussite', 'Site Info', '0', 11, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-1110', '!plussite-1100', '!plussite', 'sakai.siteinfo', 1, 'Site Info', NULL );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-1200', '!plussite', 'Sakai Plus', '0', 12, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-1210', '!plussite-1200', '!plussite', 'sakai.plus', 1, 'Sakai Plus', NULL );
INSERT INTO SAKAI_SITE_TOOL_PROPERTY VALUES('!plussite', '!plussite-1210', 'sakai-portal:visible', 'false' );
INSERT INTO SAKAI_SITE_PAGE VALUES('!plussite-1300', '!plussite', 'Statistics', '0', 13, '0' );
INSERT INTO SAKAI_SITE_TOOL VALUES('!plussite-1310', '!plussite-1300', '!plussite', 'sakai.sitestats', 1, 'Statistics', NULL );
INSERT INTO SAKAI_SITE_TOOL_PROPERTY VALUES('!plussite', '!plussite-1310', 'sakai-portal:visible', 'false' );
-- End SAK-48021

-- SAK-48085 - Add a few more roles from the LTI Spec
INSERT INTO SAKAI_REALM_ROLE VALUES (SAKAI_REALM_ROLE_SEQ.NEXTVAL, 'ContentDeveloper');
INSERT INTO SAKAI_REALM_ROLE VALUES (SAKAI_REALM_ROLE_SEQ.NEXTVAL, 'Manager');
INSERT INTO SAKAI_REALM_ROLE VALUES (SAKAI_REALM_ROLE_SEQ.NEXTVAL, 'None');
INSERT INTO SAKAI_REALM_ROLE VALUES (SAKAI_REALM_ROLE_SEQ.NEXTVAL, 'Officer');

-- SAK-48085 switches the approach from explicitly inserting all the roles into !site.template.lti (in SAK-39496 / KNL-879) To deriving
-- the roles in !site.template.lti from !site.template.course

DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti');

-- Instructor like roles pull roles from !site.template.course / Instructor
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'ContentDeveloper') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor');

-- Teaching Assistant like roles pull roles from !site.template.course / Teaching Assistant
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant');

-- Student like roles pull roles from !site.template.course / Student
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Learner') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student');

-- Build Mentor by initially copying !site.template.course / Student
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student');

-- Convert Mentor to a read-only variant or Student by removing functions
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY = (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'section.role.student');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'assessment%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY = (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'chat.new');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'conversations%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'gradebook%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'dropbox%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY = (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'mailtool.send');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY = (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'mail.new');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'msg%');
DELETE FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY IN (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor') AND FUNCTION_KEY IN (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION where FUNCTION_NAME LIKE 'roster%');

-- Clone reduced Mentor role into Mentor-like roles
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Manager') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Officer') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor');
INSERT INTO SAKAI_REALM_RL_FN SELECT (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AS REALM_KEY, (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Member') AS ROLE_KEY, FUNCTION_KEY FROM SAKAI_REALM_RL_FN WHERE REALM_KEY = (select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.lti') AND ROLE_KEY = (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Mentor');

-- End of SAK-48085 - Improve Default Role Mapping

-- SAK-48238
ALTER TABLE CONTENT_RESOURCE ADD RESOURCE_SHA256 VARCHAR2 (64);
CREATE INDEX CONTENT_RESOURCE_SHA256 ON CONTENT_RESOURCE (RESOURCE_SHA256);
CREATE INDEX CONTENT_RESOURCE_FILE_PATH ON CONTENT_RESOURCE (FILE_PATH);

ALTER TABLE CONTENT_RESOURCE_BODY_BINARY ADD RESOURCE_SHA256 VARCHAR2 (64);
CREATE INDEX CONTENT_RESOURCE_BB_SHA256 ON CONTENT_RESOURCE_BODY_BINARY (RESOURCE_SHA256 );

ALTER TABLE CONTENT_RESOURCE_DELETE ADD RESOURCE_SHA256 VARCHAR2 (64);
CREATE INDEX CONTENT_RESOURCE_SHA256_DELETE_I ON CONTENT_RESOURCE_DELETE (RESOURCE_SHA256);
CREATE INDEX CONTENT_RESOURCE_FILE_PATH_DELETE_I ON CONTENT_RESOURCE_DELETE (FILE_PATH);
-- End SAK-48328

-- START SAK-41579
update rbc_tool_item_rbc_assoc set toolId='sakai.assignment.grades' where toolId='sakai.assignment';
-- END SAK-41579

