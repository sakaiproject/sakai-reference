-- SAM-3016
ALTER TABLE SAM_EVENTLOG_T ADD IPADDRESS varchar2(99);

-- SAK-30207
CREATE TABLE CONTENTREVIEW_ITEM (
    ID                  NUMBER(19) NOT NULL,
    VERSION             INTEGER NOT NULL,
    PROVIDERID          INTEGER NOT NULL,
    CONTENTID           VARCHAR2(255) NOT NULL,
    USERID              VARCHAR2(255),
    SITEID              VARCHAR2(255),
    TASKID              VARCHAR2(255),
    EXTERNALID          VARCHAR2(255),
    DATEQUEUED          TIMESTAMP NOT NULL,
    DATESUBMITTED       TIMESTAMP,
    DATEREPORTRECEIVED  TIMESTAMP,
    STATUS              NUMBER(19),
    REVIEWSCORE         INTEGER,
    LASTERROR           CLOB,
    RETRYCOUNT          NUMBER(19),
    NEXTRETRYTIME       TIMESTAMP NOT NULL,
    ERRORCODE           INTEGER,
    CONSTRAINT ID PRIMARY KEY (ID),
    CONSTRAINT PROVIDERID UNIQUE (PROVIDERID, CONTENTID)
);
-- END SAK-30207

-- SAK-33723 Content review item properties
CREATE TABLE CONTENTREVIEW_ITEM_PROPERTIES (
  CONTENTREVIEW_ITEM_ID number(19) NOT NULL,
  VALUE varchar2(255) DEFAULT NULL,
  PROPERTY varchar2(255) NOT NULL,
  PRIMARY KEY (CONTENTREVIEW_ITEM_ID,PROPERTY),
  FOREIGN KEY (CONTENTREVIEW_ITEM_ID) REFERENCES CONTENTREVIEW_ITEM (id)
);

-- END SAK-33723

--
-- SAK-31641 Switch from INTs to VARCHARs in Oauth
--
ALTER TABLE oauth_accessors
MODIFY (
  status VARCHAR2(255)
, type VARCHAR2(255)
);

UPDATE oauth_accessors SET status = CASE
  WHEN status = 0 THEN 'VALID'
  WHEN status = 1 THEN 'REVOKED'
  WHEN status = 2 THEN 'EXPIRED'
END;

UPDATE oauth_accessors SET type = CASE
  WHEN type = 0 THEN 'REQUEST'
  WHEN type = 1 THEN 'REQUEST_AUTHORISING'
  WHEN type = 2 THEN 'REQUEST_AUTHORISED'
  WHEN type = 3 THEN 'ACCESS'
END;

--
-- SAK-31636 Rename existing 'Home' tools
--

update sakai_site_page set title = 'Overview' where title = 'Home';

--
-- SAK-31563
--

-- Add new user_id columns and their corresponding indexes
ALTER TABLE pasystem_popup_assign ADD user_id varchar2(99);
ALTER TABLE pasystem_popup_dismissed ADD user_id varchar2(99);
ALTER TABLE pasystem_banner_dismissed ADD user_id varchar2(99);

CREATE INDEX popup_assign_lower_user_id on pasystem_popup_assign (user_id);
CREATE INDEX popup_dismissed_lower_user_id on pasystem_popup_dismissed (user_id);
CREATE INDEX banner_dismissed_user_id on pasystem_banner_dismissed (user_id);

-- Map existing EIDs to their corresponding user IDs
update pasystem_popup_assign popup set user_id = (select user_id from sakai_user_id_map map where popup.user_eid = map.eid);
update pasystem_popup_dismissed popup set user_id = (select user_id from sakai_user_id_map map where popup.user_eid = map.eid);
update pasystem_banner_dismissed banner set user_id = (select user_id from sakai_user_id_map map where banner.user_eid = map.eid);

-- Any rows that couldn't be mapped are dropped (there shouldn't
-- really be any, but if there are those users were already being
-- ignored when identified by EID)
DELETE FROM pasystem_popup_assign WHERE user_id is null;
DELETE FROM pasystem_popup_dismissed WHERE user_id is null;
DELETE FROM pasystem_banner_dismissed WHERE user_id is null;

-- Enforce NULL checks on the new columns
ALTER TABLE pasystem_popup_assign MODIFY user_id varchar2(99) NOT NULL;
ALTER TABLE pasystem_popup_dismissed MODIFY user_id varchar2(99) NOT NULL;
ALTER TABLE pasystem_banner_dismissed MODIFY user_id varchar2(99) NOT NULL;

-- Reintroduce unique constraints for the new column
ALTER TABLE pasystem_popup_dismissed drop CONSTRAINT popup_dismissed_unique;
ALTER TABLE pasystem_popup_dismissed add CONSTRAINT popup_dismissed_unique UNIQUE (user_id, state, uuid);

ALTER TABLE pasystem_banner_dismissed drop CONSTRAINT banner_dismissed_unique;
ALTER TABLE pasystem_banner_dismissed add CONSTRAINT banner_dismissed_unique UNIQUE (user_id, state, uuid);

-- Drop the old columns
ALTER TABLE pasystem_popup_assign DROP COLUMN user_eid;
ALTER TABLE pasystem_popup_dismissed DROP COLUMN user_eid;
ALTER TABLE pasystem_banner_dismissed DROP COLUMN user_eid;

--
-- SAK-31840 drop defaults as its now managed in the POJO
--
ALTER TABLE GB_GRADABLE_OBJECT_T MODIFY IS_EXTRA_CREDIT number(1) DEFAULT NULL;
ALTER TABLE GB_GRADABLE_OBJECT_T MODIFY HIDE_IN_ALL_GRADES_TABLE number(1) DEFAULT NULL;

--LSNBLDR-633 Restrict editing of Lessons pages and subpages to one person
ALTER TABLE lesson_builder_pages ADD owned number(1) default 0 not null;
-- END LSNBLDR-633

-- BEGIN SAK-31819 Remove the old ScheduledInvocationManager job as it's not present in Sakai 12.
DELETE FROM QRTZ_SIMPLE_TRIGGERS WHERE TRIGGER_NAME='org.sakaiproject.component.app.scheduler.ScheduledInvocationManagerImpl.runner';
DELETE FROM QRTZ_TRIGGERS WHERE TRIGGER_NAME='org.sakaiproject.component.app.scheduler.ScheduledInvocationManagerImpl.runner';
-- This one is the actual job that the triggers were trying to run
DELETE FROM QRTZ_JOB_DETAILS WHERE JOB_NAME='org.sakaiproject.component.app.scheduler.ScheduledInvocationManagerImpl.runner';
-- END SAK-31819

-- BEGIN SAK-15708 avoid duplicate rows
CREATE TABLE SAKAI_POSTEM_STUDENT_DUPES (
  id number not null,
  username varchar2(99),
  surrogate_key number
);
INSERT INTO SAKAI_POSTEM_STUDENT_DUPES SELECT MAX(id), username, surrogate_key FROM SAKAI_POSTEM_STUDENT GROUP BY username, surrogate_key HAVING count(id) > 1;
DELETE FROM SAKAI_POSTEM_STUDENT_GRADES WHERE student_id IN (SELECT id FROM SAKAI_POSTEM_STUDENT_DUPES);
DELETE FROM SAKAI_POSTEM_STUDENT WHERE id IN (SELECT id FROM SAKAI_POSTEM_STUDENT_DUPES);
DROP TABLE SAKAI_POSTEM_STUDENT_DUPES;

DROP INDEX POSTEM_STUDENT_USERNAME_I;
ALTER TABLE SAKAI_POSTEM_STUDENT MODIFY ( "USERNAME" VARCHAR2(99 CHAR) ) ;
CREATE UNIQUE INDEX POSTEM_USERNAME_SURROGATE ON SAKAI_POSTEM_STUDENT ("USERNAME" ASC, "SURROGATE_KEY" ASC);
-- END SAK-15708

-- BEGIN SAK-32083 TAGS

CREATE TABLE tagservice_collection (
  tagcollectionid VARCHAR2(36) PRIMARY KEY,
  description CLOB,
  externalsourcename VARCHAR2(255),
  externalsourcedescription CLOB,
  name VARCHAR2(255),
  createdby VARCHAR2(255),
  creationdate NUMBER,
  lastmodifiedby VARCHAR2(255),
  lastmodificationdate NUMBER,
  lastsynchronizationdate NUMBER,
  externalupdate NUMBER(1,0),
  externalcreation NUMBER(1,0),
  lastupdatedateinexternalsystem NUMBER,
  CONSTRAINT externalsourcename_UNIQUE UNIQUE (externalsourcename),
  CONSTRAINT name_UNIQUE UNIQUE (name)
);

CREATE TABLE tagservice_tag (
  tagid VARCHAR2(36) PRIMARY KEY,
  tagcollectionid VARCHAR2(36) NOT NULL,
  externalid VARCHAR2(255),
  taglabel VARCHAR2(255),
  description CLOB,
  alternativelabels CLOB,
  createdby VARCHAR2(255),
  creationdate NUMBER,
  externalcreation NUMBER(1,0),
  externalcreationDate NUMBER,
  externalupdate NUMBER(1,0),
  lastmodifiedby VARCHAR2(255),
  lastmodificationdate NUMBER,
  lastupdatedateinexternalsystem NUMBER,
  parentid VARCHAR2(255),
  externalhierarchycode CLOB,
  externaltype VARCHAR2(255),
  data CLOB,
  CONSTRAINT tagservice_tag_fk FOREIGN KEY (tagcollectionid) REFERENCES tagservice_collection(tagcollectionid)
);


CREATE INDEX tagservice_tag_tagcollectionid on tagservice_tag (tagcollectionid);
CREATE INDEX tagservice_tag_taglabel on tagservice_tag (taglabel);
CREATE INDEX tagservice_tag_externalid on tagservice_tag (externalid);



MERGE INTO SAKAI_REALM_FUNCTION srf
USING (
SELECT -123 as function_key,
'tagservice.manage' as function_name
FROM dual
) t on (srf.function_name = t.function_name)
WHEN NOT MATCHED THEN
INSERT (function_key, function_name)
VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, t.function_name);

-- END SAK-32083 TAGS

-- BEGIN 3432 Grade Points Grading Scale
-- add the new grading scale
INSERT INTO gb_grading_scale_t (id, object_type_id, version, scale_uid, name, unavailable)
VALUES (gb_grading_scale_s.nextval, 0, 0, 'GradePointsMapping', 'Grade Points', 0);

-- add the grade ordering
INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'A (4.0)', 0);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'A- (3.67)', 1);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'B+ (3.33)', 2);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'B (3.0)', 3);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'B- (2.67)', 4);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'C+ (2.33)', 5);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'C (2.0)', 6);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'C- (1.67)', 7);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'D (1.0)', 8);

INSERT INTO gb_grading_scale_grades_t (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 'F (0)', 9);

-- add the percent mapping
INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 100, 'A (4.0)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 90, 'A- (3.67)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 87, 'B+ (3.33)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 83, 'B (3.0)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 80, 'B- (2.67)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 77, 'C+ (2.33)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 73, 'C (2.0)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 70, 'C- (1.67)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 67, 'D (1.0)');

INSERT INTO gb_grading_scale_percents_t (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM gb_grading_scale_t WHERE scale_uid = 'GradePointsMapping')
, 0, 'F (0)');

-- add the new scale to all existing gradebook sites
INSERT INTO gb_grade_map_t (id, object_type_id, version, gradebook_id, gb_grading_scale_t)
SELECT 
  gb_grade_mapping_s.nextval
, 0
, 0
, gb.id
, gs.id
FROM gb_gradebook_t gb
JOIN gb_grading_scale_t gs
  ON gs.scale_uid = 'GradePointsMapping';
-- END 3432

-- SAM-1129 Change the column DESCRIPTION of SAM_QUESTIONPOOL_T from VARCHAR2(255) to CLOB

ALTER TABLE SAM_QUESTIONPOOL_T ADD DESCRIPTION_COPY VARCHAR2(255);
UPDATE SAM_QUESTIONPOOL_T SET DESCRIPTION_COPY = DESCRIPTION;

UPDATE SAM_QUESTIONPOOL_T SET DESCRIPTION = NULL;
ALTER TABLE SAM_QUESTIONPOOL_T MODIFY DESCRIPTION LONG;
ALTER TABLE SAM_QUESTIONPOOL_T MODIFY DESCRIPTION CLOB;
UPDATE SAM_QUESTIONPOOL_T SET DESCRIPTION = DESCRIPTION_COPY;

ALTER TABLE SAM_QUESTIONPOOL_T DROP COLUMN DESCRIPTION_COPY;

-- SAK-30461 Portal bullhorns
CREATE TABLE BULLHORN_ALERTS
(
    ID NUMBER(19) NOT NULL,
    ALERT_TYPE VARCHAR(8) NOT NULL,
    FROM_USER VARCHAR2(99) NOT NULL,
    TO_USER VARCHAR2(99) NOT NULL,
    EVENT VARCHAR2(32) NOT NULL,
    REF VARCHAR2(255) NOT NULL,
    TITLE VARCHAR2(255),
    SITE_ID VARCHAR2(99),
    URL CLOB NOT NULL,
    EVENT_DATE TIMESTAMP NOT NULL,
    PRIMARY KEY(ID)
);

CREATE SEQUENCE bullhorn_alerts_seq;

CREATE OR REPLACE TRIGGER bullhorn_alerts_bir
    BEFORE INSERT ON BULLHORN_ALERTS
    FOR EACH ROW
    BEGIN
        SELECT bullhorn_alerts_seq.NEXTVAL
        INTO   :new.id
        FROM   dual;
    END;

-- SAK-32417 Forums permission composite index
CREATE INDEX MFR_COMPOSITE_PERM ON MFR_PERMISSION_LEVEL_T (TYPE_UUID, NAME);

-- SAK-32442 - LTI Column cleanup
-- These conversions may fail if you started Sakai at newer versions that didn't contain these columns/tables
alter table lti_tools drop column enabled_capability;
alter table lti_deploy drop column allowlori;
alter table lti_tools drop column allowlori;
drop table lti_mapping;
-- END SAK-32442

-- SAK-32572 Additional permission settings for Messages
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'msg.permissions.allowToField.myGroupRoles');

--The permission above is false for all users by default
--if you want to turn this feature on for all "student/acces" type roles, then run 
--the following conversion:

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'access'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Participant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Reviewer'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Evaluator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolioAdmin'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Program Admin'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));


INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolioAdmin'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Program Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.permissions.allowToField.myGroupRoles'));

-- --------------------------------------------------------------------------------------------------------------------------------------
-- backfill new permission into existing realms
-- --------------------------------------------------------------------------------------------------------------------------------------

-- for each realm that has a role matching something in this table, we will add to that role the function from this table
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('maintain','msg.permissions.allowToField.myGroupRoles');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('access','msg.permissions.allowToField.myGroupRoles');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Instructor','msg.permissions.allowToField.myGroupRoles');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Teaching Assistant','msg.permissions.allowToField.myGroupRoles');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Student','msg.permissions.allowToField.myGroupRoles');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('CIG Coordinator','msg.permissions.allowToField.myGroupRoles');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Evaluator','msg.permissions.allowToField.myGroupRoles');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Reviewer','msg.permissions.allowToField.myGroupRoles');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('CIG Participant','msg.permissions.allowToField.myGroupRoles');

-- lookup the role and function number
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

-- END SAK-32572 Additional permission settings for Messages

-- SAK-33430 user_audits_log is queried against site_id
ALTER TABLE user_audits_log MODIFY (site_id varchar2(99));
ALTER TABLE user_audits_log MODIFY (role_name varchar2(99));
DROP INDEX user_audits_log_index;
CREATE INDEX user_audits_log_index on user_audits_log (site_id);
-- END SAK-33430

-- SAK-33406 - Allow reorder of LTI plugin tools
alter table lti_tools add toolorder NUMBER(2) DEFAULT '0';
alter table lti_content add toolorder NUMBER(2) DEFAULT '0';
-- END SAK-33406

-- SAK-32440 
alter table lti_tools add siteinfoconfig NUMBER(2) DEFAULT '0';
-- END SAK-32440

-- BEGIN SAK-32045 -- Update My Workspace to My Home
UPDATE SAKAI_SITE
SET TITLE = 'Home', DESCRIPTION = 'Home'
WHERE SITE_ID LIKE '!user%';

UPDATE SAKAI_SITE
SET TITLE = 'Home', DESCRIPTION = 'Home'
WHERE TITLE = 'My Workspace'
AND SITE_ID LIKE '~%';

UPDATE SAKAI_SITE_TOOL
SET TITLE = 'Home' 
WHERE REGISTRATION = 'sakai.iframe.myworkspace';
-- END SAK-32045

--
-- BEGIN NEW ASSIGNMENTS TABLES
--

CREATE TABLE ASN_ASSIGNMENT (
  ASSIGNMENT_ID varchar2(36) NOT NULL,
  ALLOW_ATTACHMENTS number(1) DEFAULT NULL,
  ALLOW_PEER_ASSESSMENT number(1) DEFAULT NULL,
  AUTHOR varchar2(99) DEFAULT NULL,
  CLOSE_DATE timestamp DEFAULT NULL,
  CONTENT_REVIEW number(1) DEFAULT NULL,
  CONTEXT varchar2(99) NOT NULL,
  CREATED_DATE timestamp NOT NULL,
  MODIFIED_DATE timestamp DEFAULT NULL,
  DELETED number(1) DEFAULT NULL,
  DRAFT number(1) NOT NULL,
  DROP_DEAD_DATE timestamp DEFAULT NULL,
  DUE_DATE timestamp DEFAULT NULL,
  HIDE_DUE_DATE number(1) DEFAULT NULL,
  HONOR_PLEDGE number(1) DEFAULT NULL,
  INDIVIDUALLY_GRADED number(1) DEFAULT NULL,
  INSTRUCTIONS clob,
  IS_GROUP number(1) DEFAULT NULL,
  MAX_GRADE_POINT integer DEFAULT NULL,
  MODIFIER varchar2(99) DEFAULT NULL,
  OPEN_DATE timestamp DEFAULT NULL,
  PEER_ASSESSMENT_ANON_EVAL number(1) DEFAULT NULL,
  PEER_ASSESSMENT_INSTRUCTIONS clob,
  PEER_ASSESSMENT_NUMBER_REVIEW integer DEFAULT NULL,
  PEER_ASSESSMENT_PERIOD_DATE timestamp DEFAULT NULL,
  PEER_ASSESSMENT_STUDENT_REVIEW number(1) DEFAULT NULL,
  POSITION integer DEFAULT NULL,
  RELEASE_GRADES number(1) DEFAULT NULL,
  SCALE_FACTOR integer DEFAULT NULL,
  SECTION varchar2(255) DEFAULT NULL,
  TITLE varchar2(255) DEFAULT NULL,
  ACCESS_TYPE varchar2(255) NOT NULL,
  GRADE_TYPE integer DEFAULT NULL,
  SUBMISSION_TYPE integer DEFAULT NULL,
  VISIBLE_DATE timestamp DEFAULT NULL,
  PRIMARY KEY (ASSIGNMENT_ID)
);

CREATE TABLE ASN_ASSIGNMENT_ATTACHMENTS (
  ASSIGNMENT_ID varchar2(36) NOT NULL,
  ATTACHMENT varchar2(1024) DEFAULT NULL,
  CONSTRAINT FK_ASN_ASSIGNMENT_ATT FOREIGN KEY (ASSIGNMENT_ID) REFERENCES ASN_ASSIGNMENT (ASSIGNMENT_ID)
);

CREATE TABLE ASN_ASSIGNMENT_GROUPS (
  ASSIGNMENT_ID varchar2(36) NOT NULL,
  GROUP_ID varchar2(255) DEFAULT NULL,
  CONSTRAINT FK_ASN_ASSIGNMENTS_GRP FOREIGN KEY (ASSIGNMENT_ID) REFERENCES ASN_ASSIGNMENT (ASSIGNMENT_ID)
);

CREATE TABLE ASN_ASSIGNMENT_PROPERTIES (
  ASSIGNMENT_ID varchar2(36) NOT NULL,
  VALUE clob DEFAULT NULL,
  NAME varchar2(255) NOT NULL,
  PRIMARY KEY (ASSIGNMENT_ID,NAME),
  CONSTRAINT FK_ASN_ASSIGMENTS_PROP FOREIGN KEY (ASSIGNMENT_ID) REFERENCES ASN_ASSIGNMENT (ASSIGNMENT_ID)
);

CREATE TABLE ASN_SUBMISSION (
  SUBMISSION_ID varchar2(36) NOT NULL,
  CREATED_DATE timestamp DEFAULT NULL,
  MODIFIED_DATE timestamp DEFAULT NULL,
  RETURNED_DATE timestamp DEFAULT NULL,
  SUBMITTED_DATE timestamp DEFAULT NULL,
  FACTOR integer DEFAULT NULL,
  FEEDBACK_COMMENT clob,
  FEEDBACK_TEXT clob,
  GRADE varchar2(32) DEFAULT NULL,
  GRADE_RELEASED number(1) DEFAULT NULL,
  GRADED number(1) DEFAULT NULL,
  GRADED_BY varchar2(99) DEFAULT NULL,
  GROUP_ID varchar2(36) DEFAULT NULL,
  HIDDEN_DUE_DATE number(1) DEFAULT NULL,
  HONOR_PLEDGE number(1) DEFAULT NULL,
  RETURNED number(1) DEFAULT NULL,
  SUBMITTED number(1) DEFAULT NULL,
  TEXT clob,
  USER_SUBMISSION number(1) DEFAULT NULL,
  ASSIGNMENT_ID varchar2(36) DEFAULT NULL,
  PRIMARY KEY (SUBMISSION_ID),
  CONSTRAINT FK_ASN_ASSIGMENTS_SUB FOREIGN KEY (ASSIGNMENT_ID) REFERENCES ASN_ASSIGNMENT (ASSIGNMENT_ID)
);

CREATE TABLE ASN_SUBMISSION_ATTACHMENTS (
  SUBMISSION_ID varchar2(36) NOT NULL,
  ATTACHMENT varchar2(1024) DEFAULT NULL,
  CONSTRAINT FK_ASN_SUBMISSION_ATT FOREIGN KEY (SUBMISSION_ID) REFERENCES ASN_SUBMISSION (SUBMISSION_ID)
);

CREATE TABLE ASN_SUBMISSION_FEEDBACK_ATTACH (
  SUBMISSION_ID varchar2(36) NOT NULL,
  FEEDBACK_ATTACHMENT varchar2(1024) DEFAULT NULL,
  CONSTRAINT FK_ASN_SUBMISSION_FEE FOREIGN KEY (SUBMISSION_ID) REFERENCES ASN_SUBMISSION (SUBMISSION_ID)
);

CREATE TABLE ASN_SUBMISSION_PROPERTIES (
  SUBMISSION_ID varchar2(36) NOT NULL,
  VALUE clob DEFAULT NULL,
  NAME varchar2(255) NOT NULL,
  PRIMARY KEY (SUBMISSION_ID,NAME),
  CONSTRAINT FK_ASN_SUBMISSION_PROP FOREIGN KEY (SUBMISSION_ID) REFERENCES ASN_SUBMISSION (SUBMISSION_ID)
);

CREATE TABLE ASN_SUBMISSION_SUBMITTER (
  ID number NOT NULL,
  FEEDBACK clob,
  GRADE varchar2(32) DEFAULT NULL,
  SUBMITTEE number(1) NOT NULL,
  SUBMITTER varchar2(99) NOT NULL,
  SUBMISSION_ID varchar2(36) NOT NULL,
  PRIMARY KEY (ID),
  CONSTRAINT UK_ASN_SUBMISSION UNIQUE (SUBMISSION_ID,SUBMITTER),
  CONSTRAINT FK_ASN_SUBMISSION_SUB FOREIGN KEY (SUBMISSION_ID) REFERENCES ASN_SUBMISSION (SUBMISSION_ID)
);

CREATE SEQUENCE ASN_SUBMISSION_SUBMITTERS_S;

--
-- END NEW ASSIGNMENTS TABLES
--

-- SAK-32642 Commons Tools

CREATE TABLE COMMONS_COMMENT (
  ID varchar2(36) NOT NULL,
  POST_ID varchar2(36) DEFAULT NULL,
  CONTENT clob NOT NULL,
  CREATOR_ID varchar2(99) NOT NULL,
  CREATED_DATE timestamp NOT NULL,
  MODIFIED_DATE timestamp NOT NULL,
  PRIMARY KEY (ID)
);

CREATE INDEX IDX_COMMONS_CREATOR ON COMMONS_COMMENT(CREATOR_ID);
CREATE INDEX IDX_COMMONS_POST ON COMMONS_COMMENT(POST_ID);

CREATE TABLE COMMONS_COMMONS (
  ID varchar2(36) NOT NULL,
  SITE_ID varchar2(99) NOT NULL,
  EMBEDDER varchar2(24) NOT NULL,
  PRIMARY KEY (ID)
);

CREATE TABLE COMMONS_COMMONS_POST (
  COMMONS_ID varchar2(36) DEFAULT NULL,
  POST_ID varchar2(36) DEFAULT NULL,
  CONSTRAINT UK_COMMONS_ID_POST_ID UNIQUE (COMMONS_ID,POST_ID)
);

CREATE TABLE COMMONS_POST (
  ID varchar2(36) NOT NULL,
  CONTENT clob NOT NULL,
  CREATOR_ID varchar2(99) NOT NULL,
  CREATED_DATE timestamp NOT NULL,
  MODIFIED_DATE timestamp NOT NULL,
  RELEASE_DATE timestamp NOT NULL,
  PRIMARY KEY (ID)
);

CREATE INDEX IDX_COMMONS_POST_CREATOR ON COMMONS_POST(CREATOR_ID);

-- END SAK-32642

-- SAM-2970 Extended Time

CREATE TABLE SAM_EXTENDEDTIME_T (
  ID number NOT NULL,
  ASSESSMENT_ID number DEFAULT NULL,
  PUB_ASSESSMENT_ID number DEFAULT NULL,
  USER_ID varchar2(255) DEFAULT NULL,
  GROUP_ID varchar2(255) DEFAULT NULL,
  START_DATE timestamp DEFAULT NULL,
  DUE_DATE timestamp DEFAULT NULL,
  RETRACT_DATE timestamp DEFAULT NULL,
  TIME_HOURS integer DEFAULT NULL,
  TIME_MINUTES integer DEFAULT NULL,
  PRIMARY KEY (ID),
  CONSTRAINT FK_EXTENDEDTIME_PUBASSESSMENT FOREIGN KEY (PUB_ASSESSMENT_ID) REFERENCES SAM_PUBLISHEDASSESSMENT_T (ID),
  CONSTRAINT FK_EXTENDEDTIME_ASSESMENTBASE FOREIGN KEY (ASSESSMENT_ID) REFERENCES SAM_ASSESSMENTBASE_T (ID)
);

CREATE INDEX IDX_EXTENDEDTIME_ASSESMENT_ID ON SAM_EXTENDEDTIME_T(ASSESSMENT_ID);
CREATE INDEX IDX_EXTENDEDTIME_ASSESMENT_PID ON SAM_EXTENDEDTIME_T(PUB_ASSESSMENT_ID);

CREATE SEQUENCE SAM_EXTENDEDTIME_S;

-- END SAM-2970


-- SAM-3115 Tags and Search in Samigo

ALTER TABLE SAM_ITEM_T ADD HASH varchar(255) DEFAULT NULL;
ALTER TABLE SAM_PUBLISHEDITEM_T ADD HASH varchar(255) DEFAULT NULL;
ALTER TABLE SAM_PUBLISHEDITEM_T ADD ITEMHASH varchar(255) DEFAULT NULL;

CREATE TABLE SAM_ITEMTAG_T (
  ITEMTAGID number NOT NULL,
  ITEMID number NOT NULL,
  TAGID varchar2(36) NOT NULL,
  TAGLABEL varchar2(255) NOT NULL,
  TAGCOLLECTIONID varchar2(36) NOT NULL,
  TAGCOLLECTIONNAME varchar2(255) NOT NULL,
  PRIMARY KEY (ITEMTAGID),
  CONSTRAINT FK_ITEMTAG_ITEM FOREIGN KEY (ITEMID) REFERENCES SAM_ITEM_T (ITEMID)
);

CREATE INDEX SAM_ITEMTAG_ITEMID_I ON SAM_ITEMTAG_T(ITEMID);

CREATE SEQUENCE SAM_ITEMTAG_ID_S;

CREATE TABLE SAM_PUBLISHEDITEMTAG_T (
  ITEMTAGID number NOT NULL,
  ITEMID number NOT NULL,
  TAGID varchar2(36) NOT NULL,
  TAGLABEL varchar2(255) NOT NULL,
  TAGCOLLECTIONID varchar2(36) NOT NULL,
  TAGCOLLECTIONNAME varchar2(255) NOT NULL,
  PRIMARY KEY (ITEMTAGID),
  CONSTRAINT FK_ITEMTAG_ITEM_ITEM FOREIGN KEY (ITEMID) REFERENCES SAM_PUBLISHEDITEM_T (ITEMID)
);

CREATE INDEX SAM_PUBLISHEDITEMTAG_ITEMID_I ON SAM_PUBLISHEDITEMTAG_T(ITEMID);

CREATE SEQUENCE SAM_PITEMTAG_ID_S;


--END SAM-3115

-- SAK-31819 Quartz scheduler

CREATE TABLE context_mapping (
  uuid varchar2(255) NOT NULL,
  componentId varchar2(255) DEFAULT NULL,
  contextId varchar2(255) DEFAULT NULL,
  PRIMARY KEY (uuid),
  CONSTRAINT UK_CONTEXT_MAPPING UNIQUE (componentId,contextId)
);

-- END SAK-31819

-- SAK-SAK-33772 - Add LTI 1.3 Data model items

ALTER TABLE lti_content ADD lti13 NUMBER(2) DEFAULT '0';
ALTER TABLE lti_content ADD lti13_settings CLOB DEFAULT NULL;
ALTER TABLE lti_tools ADD lti13 NUMBER(2) DEFAULT '0';
ALTER TABLE lti_tools ADD lti13_settings CLOB DEFAULT NULL;

-- END SAK-33772

-- SAK-32173 Syllabus remove open in new window option

ALTER TABLE SAKAI_SYLLABUS_ITEM DROP COLUMN openInNewWindow;

-- END SAK-33173 

-- SAK-33896  Remove site manage site association code
DROP TABLE SITEASSOC_CONTEXT_ASSOCIATION;

--END SAK-33896 

--
-- SAM-3346 and LSNBLDR-924
--
declare
    type ObjNames is table of varchar2(100);
    sequences ObjNames := ObjNames('LESSON_BUILDER_PAGE_S',
        'LESSON_BUILDER_COMMENTS_S',
        'LESSON_BUILDER_GROUPS_S',
        'LESSON_BUILDER_ITEMS_S',
        'LESSON_BUILDER_PROP_S',
        'LESSON_BUILDER_QR_S',
        'LESSON_BUILDER_STPAGE_S',
        'LESSON_BUILDER_LOG_S',
        'LESSON_BUILDER_QRES_S',
        'SAM_FAVORITECOLCHOICES_S','SAM_FAVORITECOLCHOICESITEM_S');
    tablenames ObjNames := ObjNames('lesson_builder_pages',
        'lesson_builder_comments',
        'lesson_builder_groups',
        'lesson_builder_items',
        'lesson_builder_properties',
        'lesson_builder_qr_totals',
        'lesson_builder_student_pages',
        'lesson_builder_log',
        'lesson_builder_q_responses',
        'SAM_FAVORITECOLCHOICES_T','SAM_FAVORITECOLCHOICESITEM_T');
    tablecolumns ObjNames := ObjNames('pageId',
        'id','id','id','id','id','id','id','id',
        'favoriteId','favoriteItemId');
    lnum number(10);
    stc varchar2(1000);
begin
    for i in sequences.first .. sequences.last
    loop
        stc := 'select nvl(max('||tablecolumns(i)||'),0)+1 from '||tablenames(i);
        execute immediate stc into lnum;
        stc := 'create sequence '||sequences(i)||' start with '||lnum;
        --dbms_output.put_line(stc);
        execute immediate stc;
    end loop;
end;
