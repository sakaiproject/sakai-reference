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
ALTER TABLE pasystem_popup_assign MODIFY (user_id NOT NULL);
ALTER TABLE pasystem_popup_dismissed MODIFY (user_id NOT NULL);
ALTER TABLE pasystem_banner_dismissed MODIFY (user_id NOT NULL);

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
ALTER TABLE GB_GRADABLE_OBJECT_T MODIFY IS_EXTRA_CREDIT DEFAULT NULL;
ALTER TABLE GB_GRADABLE_OBJECT_T MODIFY HIDE_IN_ALL_GRADES_TABLE DEFAULT NULL;

--LSNBLDR-633 Restrict editing of Lessons pages and subpages to one person
ALTER TABLE lesson_builder_pages ADD owned bit default false not null;
-- END LSNBLDR-633

-- BEGIN SAM-3066 remove unecessary indexes because Hibernate always create an index on an FK
DROP INDEX SAM_PUBITEM_SECTION_I;
DROP INDEX SAM_PUBITEMFB_ITEM_I;
DROP INDEX SAM_PUBITEMMETA_ITEM_I;
DROP INDEX SAM_PUBITEMTEXT_ITEM_I;
DROP INDEX SAM_PUBSECTION_ASSESSMENT_I;
DROP INDEX SAM_PUBITEM_SECTION_I;
DROP INDEX SAM_PUBIP_ASSESSMENT_I;
DROP INDEX SAM_PUBSECTIONMETA_SECTION_I;
DROP INDEX SAM_ANSWER_ITEMTEXTID_I;
-- END SAM-3066

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
drop table lti_mapping
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

-- SAK-SAK-33772 - Add LTI 1.3 Data model items

ALTER TABLE lti_content ADD lti13 NUMBER(2) DEFAULT '0';
ALTER TABLE lti_content ADD lti13_settings CLOB DEFAULT NULL;
ALTER TABLE lti_tools ADD lti13 NUMBER(2) DEFAULT '0';
ALTER TABLE lti_tools ADD lti13_settings CLOB DEFAULT NULL;

-- END SAK-33772
