-- SAM-3016
ALTER TABLE SAM_EVENTLOG_T ADD IPADDRESS varchar(99);

-- SAK-30207
CREATE TABLE IF NOT EXISTS CONTENTREVIEW_ITEM (
    ID                  BIGINT NOT NULL AUTO_INCREMENT,
    VERSION             INT NOT NULL,
    PROVIDERID          INT NOT NULL,
    CONTENTID           VARCHAR(255) NOT NULL,
    USERID              VARCHAR(255),
    SITEID              VARCHAR(255),
    TASKID              VARCHAR(255),
    EXTERNALID          VARCHAR(255),
    DATEQUEUED          DATETIME NOT NULL,
    DATESUBMITTED       DATETIME,
    DATEREPORTRECEIVED  DATETIME,
    STATUS              BIGINT,
    REVIEWSCORE         INT,
    LASTERROR           LONGTEXT,
    RETRYCOUNT          BIGINT,
    NEXTRETRYTIME       DATETIME NOT NULL,
    ERRORCODE           INT,
    PRIMARY KEY (ID),
    CONSTRAINT PROVIDERID UNIQUE (PROVIDERID, CONTENTID)
);
-- END SAK-30207

-- 
-- SAK-31641 Switch from INTs to VARCHARs in Oauth
-- 
ALTER TABLE OAUTH_ACCESSORS
CHANGE
  status status VARCHAR(255),
  CHANGE type type VARCHAR(255)
;

UPDATE OAUTH_ACCESSORS SET status = CASE
  WHEN status = 0 THEN "VALID"
  WHEN status = 1 THEN "REVOKED"
  WHEN status = 2 THEN "EXPIRED"
END;

UPDATE OAUTH_ACCESSORS SET type = CASE
  WHEN type = 0 THEN "REQUEST"
  WHEN type = 1 THEN "REQUEST_AUTHORISING"
  WHEN type = 2 THEN "REQUEST_AUTHORISED"
  WHEN type = 3 THEN "ACCESS"
END;

--
-- SAK-31636 Rename existing 'Home' tools
--

update SAKAI_SITE_PAGE set title = 'Overview' where title = 'Home';

--
-- SAK-31563
--

-- Add new user_id columns and their corresponding indexes
ALTER TABLE pasystem_popup_assign ADD user_id varchar(99);
ALTER TABLE pasystem_popup_dismissed ADD user_id varchar(99);
ALTER TABLE pasystem_banner_dismissed ADD user_id varchar(99);

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
ALTER TABLE pasystem_popup_assign MODIFY user_id varchar(99) NOT NULL;
ALTER TABLE pasystem_popup_dismissed MODIFY user_id varchar(99) NOT NULL;
ALTER TABLE pasystem_banner_dismissed MODIFY user_id varchar(99) NOT NULL;

-- Reintroduce unique constraints for the new column
ALTER TABLE pasystem_popup_dismissed drop INDEX unique_popup_dismissed;
ALTER TABLE pasystem_popup_dismissed add UNIQUE INDEX unique_popup_dismissed (user_id, state, uuid);

ALTER TABLE pasystem_banner_dismissed drop INDEX unique_banner_dismissed;
ALTER TABLE pasystem_banner_dismissed add UNIQUE INDEX unique_banner_dismissed (user_id, state, uuid);

-- Drop the old columns
ALTER TABLE pasystem_popup_assign DROP COLUMN user_eid;
ALTER TABLE pasystem_popup_dismissed DROP COLUMN user_eid;
ALTER TABLE pasystem_banner_dismissed DROP COLUMN user_eid;

-- LSNBLDR-633 Restrict editing of Lessons pages and subpages to one person
ALTER TABLE lesson_builder_pages ADD owned bit default false not null;
-- END LSNBLDR-633
--
-- SAK-31840 update defaults as its now managed in the POJO
--
alter table GB_GRADABLE_OBJECT_T alter column IS_EXTRA_CREDIT bit(1) DEFAULT NULL;
alter table GB_GRADABLE_OBJECT_T alter column HIDE_IN_ALL_GRADES_TABLE bit(1) DEFAULT NULL;

-- BEGIN SAK-31819 Remove the old ScheduledInvocationManager job as it's not present in Sakai 12.
DELETE FROM QRTZ_SIMPLE_TRIGGERS WHERE TRIGGER_NAME='org.sakaiproject.component.app.scheduler.ScheduledInvocationManagerImpl.runner';
DELETE FROM QRTZ_TRIGGERS WHERE TRIGGER_NAME='org.sakaiproject.component.app.scheduler.ScheduledInvocationManagerImpl.runner';
-- This one is the actual job that the triggers were trying to run
DELETE FROM QRTZ_JOB_DETAILS WHERE JOB_NAME='org.sakaiproject.component.app.scheduler.ScheduledInvocationManagerImpl.runner';
-- END SAK-31819

-- BEGIN SAK-15708 avoid duplicate rows
CREATE TABLE SAKAI_POSTEM_STUDENT_DUPES (
  id bigint(20) NOT NULL,
  username varchar(99),
  surrogate_key bigint(20)
);
INSERT INTO SAKAI_POSTEM_STUDENT_DUPES SELECT MAX(id), username, surrogate_key FROM SAKAI_POSTEM_STUDENT GROUP BY username, surrogate_key HAVING count(id) > 1;
DELETE FROM SAKAI_POSTEM_STUDENT_GRADES WHERE student_id IN (SELECT id FROM SAKAI_POSTEM_STUDENT_DUPES);
DELETE FROM SAKAI_POSTEM_STUDENT WHERE id IN (SELECT id FROM SAKAI_POSTEM_STUDENT_DUPES);
DROP TABLE SAKAI_POSTEM_STUDENT_DUPES;

ALTER TABLE SAKAI_POSTEM_STUDENT MODIFY COLUMN username varchar(99), DROP INDEX POSTEM_STUDENT_USERNAME_I,
  ADD UNIQUE INDEX POSTEM_USERNAME_SURROGATE (username, surrogate_key);
-- END SAK-15708

-- BEGIN SAK-32083 TAGS

CREATE TABLE IF NOT EXISTS `tagservice_collection` (
  `tagcollectionid` CHAR(36) PRIMARY KEY,
  `description` TEXT,
  `externalsourcename` VARCHAR(255) UNIQUE,
  `externalsourcedescription` TEXT,
  `name` VARCHAR(255) UNIQUE,
  `createdby` VARCHAR(255),
  `creationdate` BIGINT,
  `lastmodifiedby` VARCHAR(255),
  `lastmodificationdate` BIGINT,
  `lastsynchronizationdate` BIGINT,
  `externalupdate` BOOLEAN,
  `externalcreation` BOOLEAN,
  `lastupdatedateinexternalsystem` BIGINT
);

CREATE TABLE IF NOT EXISTS `tagservice_tag` (
  `tagid` CHAR(36) PRIMARY KEY,
  `tagcollectionid` CHAR(36) NOT NULL,
  `externalid` VARCHAR(255),
  `taglabel` VARCHAR(255),
  `description` TEXT,
  `alternativelabels` TEXT,
  `createdby` VARCHAR(255),
  `creationdate` BIGINT,
  `externalcreation` BOOLEAN,
  `externalcreationDate` BIGINT,
  `externalupdate` BOOLEAN,
  `lastmodifiedby` VARCHAR(255),
  `lastmodificationdate` BIGINT,
  `lastupdatedateinexternalsystem` BIGINT,
  `parentid` VARCHAR(255),
  `externalhierarchycode` TEXT,
  `externaltype` VARCHAR(255),
  `data` TEXT,
  INDEX tagservice_tag_taglabel (taglabel),
  INDEX tagservice_tag_tagcollectionid (tagcollectionid),
  INDEX tagservice_tag_externalid (externalid),
  FOREIGN KEY (tagcollectionid)
  REFERENCES tagservice_collection(tagcollectionid)
    ON DELETE RESTRICT
);


INSERT IGNORE INTO SAKAI_REALM_FUNCTION (FUNCTION_NAME) VALUES ('tagservice.manage');
-- END SAK-32083 TAGS

-- BEGIN 3432 Grade Points Grading Scale
-- add the new grading scale
INSERT INTO GB_GRADING_SCALE_T (object_type_id, version, scale_uid, name, unavailable)
VALUES (0, 0, 'GradePointsMapping', 'Grade Points', 0);

-- add the grade ordering
INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'A (4.0)', 0);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'A- (3.67)', 1);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'B+ (3.33)', 2);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'B (3.0)', 3);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'B- (2.67)', 4);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'C+ (2.33)', 5);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'C (2.0)', 6);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'C- (1.67)', 7);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'D (1.0)', 8);

INSERT INTO GB_GRADING_SCALE_GRADES_T (grading_scale_id, letter_grade, grade_idx)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 'F (0)', 9);

-- add the percent mapping
INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 100, 'A (4.0)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 90, 'A- (3.67)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 87, 'B+ (3.33)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 83, 'B (3.0)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 80, 'B- (2.67)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 77, 'C+ (2.33)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 73, 'C (2.0)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 70, 'C- (1.67)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 67, 'D (1.0)');

INSERT INTO GB_GRADING_SCALE_PERCENTS_T (grading_scale_id, percent, letter_grade)
VALUES(
(SELECT id FROM GB_GRADING_SCALE_T WHERE scale_uid = 'GradePointsMapping')
, 0, 'F (0)');

-- add the new scale to all existing gradebook sites
INSERT INTO GB_GRADE_MAP_T (object_type_id, version, gradebook_id, GB_GRADING_SCALE_T)
SELECT 
  0
, 0
, gb.id
, gs.id
FROM GB_GRADEBOOK_T gb
JOIN GB_GRADING_SCALE_T gs
  ON gs.scale_uid = 'GradePointsMapping';
-- END 3432

-- SAM-1129 Change the column DESCRIPTION of SAM_QUESTIONPOOL_T from VARCHAR(255) to longtext
ALTER TABLE SAM_QUESTIONPOOL_T MODIFY DESCRIPTION longtext;

-- SAK-30461 Portal bullhorns
CREATE TABLE BULLHORN_ALERTS
(
    ID bigint NOT NULL AUTO_INCREMENT,
    ALERT_TYPE varchar(8) NOT NULL,
    FROM_USER varchar(99) NOT NULL,
    TO_USER varchar(99) NOT NULL,
    EVENT varchar(32) NOT NULL,
    REF varchar(255) NOT NULL,
    TITLE varchar(255),
    SITE_ID varchar(99),
    URL TEXT NOT NULL,
    EVENT_DATE datetime NOT NULL,
    PRIMARY KEY(ID)
);

-- SAK-32417 Forums permission composite index
ALTER TABLE MFR_PERMISSION_LEVEL_T ADD INDEX MFR_COMPOSITE_PERM (TYPE_UUID, NAME);

-- SAK-32442 - LTI Column cleanup
-- These conversions may fail if you started Sakai at newer versions that didn't contain these columns/tables
alter table lti_tools drop column enabled_capability;
alter table lti_deploy drop column allowlori;
alter table lti_tools drop column allowlori;
drop table lti_mapping;
-- END SAK-32442

-- SAK-32572 Additional permission settings for Messages

INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'msg.permissions.allowToField.myGroupRoles');

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
