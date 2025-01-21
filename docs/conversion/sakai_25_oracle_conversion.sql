-- SAK-48106
UPDATE user_audits_log audits SET audits.user_id = (SELECT idmap.user_id FROM SAKAI_USER_ID_MAP idmap WHERE idmap.eid = audits.user_id) WHERE EXISTS (SELECT 1 FROM SAKAI_USER_ID_MAP idmap WHERE idmap.eid = audits.user_id);
UPDATE user_audits_log audits SET audits.action_user_id = (SELECT idmap.user_id FROM SAKAI_USER_ID_MAP idmap WHERE idmap.eid = audits.action_user_id) WHERE EXISTS (SELECT 1 FROM SAKAI_USER_ID_MAP idmap WHERE idmap.eid = audits.action_user_id); 
-- END SAK-48106

-- S2U-12 --
ALTER TABLE sam_itemfeedback_t ADD TEXT_CLOB CLOB;
UPDATE sam_itemfeedback_t set TEXT_CLOB = TEXT;  -- convert varchar2 to CLOB
ALTER TABLE sam_itemfeedback_t drop column TEXT;
ALTER TABLE sam_itemfeedback_t RENAME COLUMN TEXT_CLOB TO TEXT;

ALTER TABLE sam_publisheditemfeedback_t ADD TEXT_CLOB CLOB;
UPDATE sam_publisheditemfeedback_t set TEXT_CLOB = TEXT;  -- convert varchar2 to CLOB
ALTER TABLE sam_publisheditemfeedback_t drop column TEXT;
ALTER TABLE sam_publisheditemfeedback_t RENAME COLUMN TEXT_CLOB TO TEXT;
-- End S2U-12 --

-- S2U-42 --
CREATE TABLE CARDGAME_STAT_ITEM (
  ID VARCHAR2(99 CHAR) NOT NULL,
  PLAYER_ID VARCHAR2(99 CHAR) NOT NULL,
  USER_ID VARCHAR2(99 CHAR) NOT NULL,
  HITS NUMBER(5,0) NOT NULL,
  MISSES NUMBER(5,0) NOT NULL,
  MARKED_AS_LEARNED NUMBER(1,0) NOT NULL,
  PRIMARY KEY(ID)
);

CREATE INDEX IDX_CARDGAME_STAT_ITEM_PLAYER_ID ON CARDGAME_STAT_ITEM (ID, PLAYER_ID);
-- END S2U-42 --

-- S2U-27 --
ALTER TABLE MFR_OPEN_FORUM_T ADD IS_FAQ_FORUM NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE MFR_TOPIC_T ADD IS_FAQ_TOPIC NUMBER(1,0) DEFAULT 0 NOT NULL;
-- END S2U-27 --

-- S2U-34 --
-- IMPORTANT: This index must be deleted and may have a different name, maybe UK_dn0jue890jn9p7vs6tvnsf2gf or similar
DROP INDEX UKdn0jue890jn9p7vs6tvnsf2gf;
CREATE UNIQUE INDEX UKqsk75a24pi108jpybtt16hshv ON RBC_EVALUATION (EVALUATED_ITEM_OWNER_ID, EVALUATED_ITEM_ID, ASSOCIATION_ID);
UPDATE rbc_evaluation SET evaluated_item_owner_id = SUBSTR(evaluated_item_owner_id, -36) where evaluated_item_owner_id like '/site/%';
-- END S2U-34 --

-- S2U-11 --
ALTER TABLE SAM_ITEMTEXT_T ADD ADDEDBUTNOTEXTRACTED NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE SAM_PUBLISHEDITEMTEXT_T ADD ADDEDBUTNOTEXTRACTED NUMBER(1,0) DEFAULT 0 NOT NULL;
-- End S2U-11 --

-- S2U-39 --
CREATE TABLE rwikipagegroups (
    rwikiobjectid VARCHAR2(36) NOT NULL,
    groupid VARCHAR2(99) NOT NULL
)
-- END S2U-39 --

-- S2U-23 --
ALTER TABLE SAM_PUBLISHEDFEEDBACK_T ADD SHOWCORRECTION NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE SAM_ASSESSFEEDBACK_T ADD SHOWCORRECTION NUMBER(1,0) DEFAULT 0 NOT NULL;
-- to preserve the complete functionality on assessments previous to the patch with 'showcorrectresponse' enabled
UPDATE SAM_PUBLISHEDFEEDBACK_T SET showcorrection = 1 WHERE showcorrection = 0 AND showcorrectresponse = 1;
UPDATE SAM_ASSESSFEEDBACK_T SET showcorrection = 1 WHERE showcorrection = 0 AND showcorrectresponse = 1;
-- END S2U-23 --

-- S2U-29 --
alter table MFR_PVT_MSG_USR_T add READ_RECEIPT NUMBER(1,0) DEFAULT null;
-- END S2U-29 --

-- SAK-49591 --
CREATE TABLE SAM_ITEMHISTORICAL_T (
  ITEMHISTORICALID NUMBER(19,0) NOT NULL,
  ITEMID NUMBER(19,0) NOT NULL,
  MODIFIEDBY VARCHAR2(255) NOT NULL,
  MODIFIEDDATE TIMESTAMP (6) WITH TIME ZONE NOT NULL,
  PRIMARY KEY(ITEMHISTORICALID)
);

CREATE SEQUENCE SAM_ITEMHISTORICAL_ID_S MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER NOCYCLE NOKEEP NOSCALE GLOBAL;
CREATE INDEX SAM_ITEMHISTORICAL_ITEMID_I ON SAM_ITEMHISTORICAL_T (ITEMID) 
ALTER TABLE SAM_ITEMHISTORICAL_T ADD CONSTRAINT FK_ITEMHISTORICAL_ITEM FOREIGN KEY (ITEMID) REFERENCES SAM_ITEM_T (ITEMID) ENABLE;
-- END SAK-49591 --

-- S2U-32 and S2U-28 --
CREATE TABLE tagservice_tagassociation (
  id varchar2(99) NOT NULL,
  tag_id varchar2(255) NOT NULL,
  item_id varchar2(255) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT UK7tc7vcvcb0bw8moqdu3giik6o UNIQUE (tag_id,item_id)
);
ALTER TABLE tagservice_tag MODIFY taglabel VARCHAR2(255 CHAR);

-- Permission added in 12 might not be present 
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_KEY, FUNCTION_NAME) VALUES(SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'tagservice.manage');
-- Add this for every role able to create and manage tags on a site, you'll need to add the tool too
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'tagservice.manage'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'tagservice.manage'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'tagservice.manage'));
-- Add this to populate existing sites with the permission
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('maintain','tagservice.manage');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Instructor','tagservice.manage');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Teaching Assistant','tagservice.manage');

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
    WHERE SR.REALM_ID != '!site.helper' AND SR.REALM_ID NOT LIKE '!user.template%'
    AND NOT EXISTS (
        SELECT 1
            FROM SAKAI_REALM_RL_FN SRRFI
            WHERE SRRFI.REALM_KEY=SRRFD.REALM_KEY AND SRRFI.ROLE_KEY=SRRFD.ROLE_KEY AND SRRFI.FUNCTION_KEY=TMP.FUNCTION_KEY
    );

DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_SRC_TEMP;
-- END S2U-32 and S2U-28 --

-- S2U-21 --
CREATE TABLE SAM_SEBVALIDATION_T (
  ID NUMBER(19,0) NOT NULL,
  PUBLISHEDASSESSMENTID NUMBER(19,0) NOT NULL,
  AGENTID VARCHAR2(99) NOT NULL,
  URL VARCHAR2(1000) NOT NULL,
  CONFIGKEYHASH VARCHAR2(64) DEFAULT NULL,
  EXAMKEYHASH VARCHAR2(64) DEFAULT NULL,
  EXPIRED NUMBER(1, 0) NOT NULL,
  CONSTRAINT PK_SAM_SEBVALIDATION_T PRIMARY KEY (ID)
);

CREATE INDEX SAM_SEB_INDEX ON SAM_SEBVALIDATION_T (PUBLISHEDASSESSMENTID, AGENTID);

CREATE SEQUENCE SAM_SEBVALIDATION_ID_S MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;
-- END S2U-21 --

-- S2U-14 --
ALTER TABLE SAM_PUBLISHEDITEM_T ADD CANCELLATION NUMBER(2,0) DEFAULT 0 NOT NULL;
-- END S2U-14 --

-- S2U-5 --
ALTER TABLE rbc_rubric ADD adhoc NUMBER(1) DEFAULT 0;
-- End S2U-5 --

-- S2U-35 --
CREATE TABLE COND_CONDITION (
  ID varchar2(36) NOT NULL,
  COND_TYPE varchar2(99) NOT NULL,
  OPERATOR varchar2(99) DEFAULT NULL,
  ARGUMENT varchar2(999) DEFAULT NULL,
  SITE_ID varchar2(36) NOT NULL,
  TOOL_ID varchar2(99) NOT NULL,
  ITEM_ID varchar2(99) DEFAULT NULL,
  PRIMARY KEY (ID)
);
CREATE INDEX IDX_CONDITION_SITE_ID ON COND_CONDITION (SITE_ID);

CREATE TABLE COND_PARENT_CHILD (
  PARENT_ID varchar2(36) NOT NULL,
  CHILD_ID varchar2(36) NOT NULL,
  PRIMARY KEY (PARENT_ID, CHILD_ID),
  CONSTRAINT FK_CHILD_ID_CONDITION_ID FOREIGN KEY (CHILD_ID) REFERENCES COND_CONDITION (ID),
  CONSTRAINT FK_PARENT_ID_CONDITION_ID FOREIGN KEY (PARENT_ID) REFERENCES COND_CONDITION (ID)
);
CREATE INDEX FK_CHILD_ID_CONDITION_ID ON COND_PARENT_CHILD (CHILD_ID);

-- Permission added might not be present
MERGE INTO SAKAI_REALM_FUNCTION srf
USING (
SELECT -123 as function_key,
'conditions.update.condition' as function_name
FROM dual
) t on (srf.function_name = t.function_name)
WHEN NOT MATCHED THEN
INSERT (function_key, function_name)
VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, t.function_name);
-- Add this for every role able to create and manage conditions on a site, you'll need to add the tool too
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'conditions.update.condition'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'conditions.update.condition'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'conditions.update.condition'));
-- Add this to populate existing sites with the permission
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('maintain','conditions.update.condition');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Instructor','conditions.update.condition');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Teaching Assistant','conditions.update.condition');

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
    WHERE SR.REALM_ID != '!site.helper' AND SR.REALM_ID NOT LIKE '!user.template%'
    AND NOT EXISTS (
        SELECT 1
            FROM SAKAI_REALM_RL_FN SRRFI
            WHERE SRRFI.REALM_KEY=SRRFD.REALM_KEY AND SRRFI.ROLE_KEY=SRRFD.ROLE_KEY AND SRRFI.FUNCTION_KEY=TMP.FUNCTION_KEY
    );

DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_SRC_TEMP;
-- END S2U-35 --

-- S2U-46 --
CREATE TABLE mc_site_synchronization (
  id varchar2(99) NOT NULL,
  site_id varchar2(255) NOT NULL,
  team_id varchar2(255) NOT NULL,
  forced number(1,0) DEFAULT NULL,
  date_from timestamp(6) DEFAULT NULL,
  date_to timestamp(6) DEFAULT NULL,
  status number(1,0) DEFAULT NULL,
  status_updated_at timestamp(6) DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT UKmc_ss UNIQUE (site_id,team_id)
);

CREATE TABLE mc_group_synchronization (
  id varchar2(99) NOT NULL,
  parentId varchar2(99) DEFAULT NULL,
  group_id varchar2(255) NOT NULL,
  channel_id varchar2(255) NOT NULL,
  status number(1,0) DEFAULT NULL,
  status_updated_at timestamp(6) DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT UKmc_gs UNIQUE (parentId,group_id,channel_id),
  CONSTRAINT FKmc_gs_ss FOREIGN KEY (parentId) REFERENCES mc_site_synchronization (id) ON DELETE CASCADE
);

CREATE TABLE mc_config_item (
  item_key varchar2(255) NOT NULL,
  value varchar2(255) DEFAULT NULL,
  PRIMARY KEY (item_key)
);

CREATE TABLE mc_log (
  id number(19,0) NOT NULL,
  context clob,
  event varchar2(255) DEFAULT NULL,
  event_date timestamp(6) DEFAULT NULL,
  status number(1,0) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- Generate ID using sequence and trigger
CREATE SEQUENCE mc_log_seq START WITH 1 INCREMENT BY 1;
-- END S2U-46 --

-- S2U-47 --
CREATE TABLE meeting_providers (
  provider_id varchar2(99) NOT NULL,
  provider_name varchar2(255) NOT NULL,
  PRIMARY KEY (provider_id)
);

CREATE TABLE meetings (
  meeting_id varchar2(99) NOT NULL,
  meeting_description clob,
  meeting_end_date timestamp(6) DEFAULT NULL,
  meeting_owner_id varchar2(99) DEFAULT NULL,
  meeting_site_id varchar2(99) DEFAULT NULL,
  meeting_start_date timestamp(6) DEFAULT NULL,
  meeting_title varchar2(255) NOT NULL,
  meeting_url varchar2(255) DEFAULT NULL,
  meeting_provider_id varchar2(99) DEFAULT NULL,
  PRIMARY KEY (meeting_id),
  CONSTRAINT FK_m_mp FOREIGN KEY (meeting_provider_id) REFERENCES meeting_providers (provider_id)
);

CREATE INDEX FK_m_mp ON meetings (meeting_provider_id);

CREATE TABLE meeting_properties (
  prop_id number(19,0) NOT NULL,
  prop_name varchar2(255) NOT NULL,
  prop_value varchar2(255) DEFAULT NULL,
  prop_meeting_id varchar2(99) DEFAULT NULL,
  PRIMARY KEY (prop_id),
  CONSTRAINT FK_mp_m FOREIGN KEY (prop_meeting_id) REFERENCES meetings (meeting_id)
);

-- Generate ID using sequence and trigger
CREATE SEQUENCE MEETING_PROPERTY_S START WITH 1 INCREMENT BY 1;

CREATE INDEX FK_mp_m ON meeting_properties (prop_meeting_id);

CREATE TABLE meeting_attendees (
  attendee_id number(19,0) NOT NULL,
  attendee_object_id varchar2(255) DEFAULT NULL,
  attendee_type number(1,0) DEFAULT NULL,
  attendee_meeting_id varchar2(99) DEFAULT NULL,
  PRIMARY KEY (attendee_id),
  CONSTRAINT FK_ma_m FOREIGN KEY (attendee_meeting_id) REFERENCES meetings (meeting_id)
);

-- Generate ID using sequence and trigger
CREATE SEQUENCE MEETING_ATTENDEE_S START WITH 1 INCREMENT BY 1;

CREATE INDEX FK_ma_m ON meeting_attendees (attendee_meeting_id);
-- END S2U-47 --

-- S2U-49 --
CREATE TABLE mc_access_token (
  sakaiUserId varchar2(255) NOT NULL,
  accessToken clob,
  microsoftUserId varchar2(255) DEFAULT NULL,
  account varchar2(255) DEFAULT NULL,
  PRIMARY KEY (sakaiUserId)
);
-- END S2U-49 --

-- S2U-16 --
ALTER TABLE SAM_ITEMGRADING_T ADD ATTEMPTDATE TIMESTAMP (6);

CREATE TABLE SAM_SECTIONGRADING_T (
  SECTIONGRADINGID NUMBER(19) NOT NULL,
  ASSESSMENTGRADINGID NUMBER(19) NOT NULL,
  PUBLISHEDSECTIONID NUMBER(19) NOT NULL,
  AGENTID VARCHAR2(255) NOT NULL,
  ATTEMPTDATE TIMESTAMP(6) DEFAULT NULL,
  PRIMARY KEY (SECTIONGRADINGID),
  CONSTRAINT uniqueStudentSectionResponse UNIQUE  (ASSESSMENTGRADINGID,PUBLISHEDSECTIONID,AGENTID)
);
CREATE SEQUENCE SAM_SECTIONGRADING_ID_S START WITH 1 INCREMENT BY 1;
-- S2U-16 --

-- S2U-19 --
ALTER TABLE SAM_ITEM_T ADD ISFIXED NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE SAM_PUBLISHEDITEM_T ADD ISFIXED NUMBER(1,0) DEFAULT 0 NOT NULL;
-- END S2U-19 --

-- SAK-46714 --
-- These are columns dropped by SAK-46714 but will not be dropped by 
-- the Sakai 25 conversion scripts until Sakai 25.2 or later
-- New Sakai 25 instances won't have these columns but the columns will
-- not be removed as systems go from Sakai 23 to Sakai 25.0 or 25.1 to allow
-- for forward and backward version movement for early versions of Sakai 25
-- They are included here to note than when the schema comparison
-- is done prior to the 25 release - these will show up but not be included
-- in the final 25.0 conversion script

-- ALTER TABLE lti_tools DROP lti13_platform_public_next;
-- ALTER TABLE lti_tools DROP lti13_platform_public_next_at;
-- ALTER TABLE lti_tools DROP lti13_platform_private_next;
-- ALTER TABLE lti_tools DROP lti13_platform_public;
-- ALTER TABLE lti_tools DROP lti13_platform_private;
-- ALTER TABLE lti_tools DROP lti13_platform_public_old;
-- ALTER TABLE lti_tools DROP lti13_platform_public_old_at; 
-- END SAK-46714 --

-- SAK-50378 --
-- These are columns dropped by SAK-50378 but will not be dropped by 
-- the Sakai 25 conversion scripts until Sakai 25.2 or later
-- New Sakai 25 instances won't have these columns but the columns will
-- not be removed as systems go from Sakai 23 to Sakai 25.0 or 25.1 to allow
-- for forward and backward version movement for early versions of Sakai 25
-- They are included here to note than when the schema comparison
-- is done prior to the 25 release - these will show up but not be included
-- in the final 25.0 conversion script

-- ALTER TABLE lti_content DROP COLUMN pagetitle;
-- ALTER TABLE lti_content DROP COLUMN toolorder;
-- ALTER TABLE lti_content DROP COLUMN consumerkey;
-- ALTER TABLE lti_content DROP COLUMN secret;
-- ALTER TABLE lti_content DROP COLUMN settings_ext;
-- ALTER TABLE lti_content DROP COLUMN fa_icon;

-- ALTER TABLE lti_tools DROP COLUMN allowtitle;
-- ALTER TABLE lti_tools DROP COLUMN pagetitle;
-- ALTER TABLE lti_tools DROP COLUMN allowpagetitle;
-- ALTER TABLE lti_tools DROP COLUMN allowlaunch;
-- ALTER TABLE lti_tools DROP COLUMN allowframeheight;
-- ALTER TABLE lti_tools DROP COLUMN allowfa_icon;
-- ALTER TABLE lti_tools DROP COLUMN toolorder;
-- ALTER TABLE lti_tools DROP COLUMN allowsettings_ext;
-- ALTER TABLE lti_tools DROP COLUMN allowconsumerkey;
-- ALTER TABLE lti_tools DROP COLUMN allowsecret;
-- ALTER TABLE lti_tools DROP COLUMN lti11_launch_type;
-- END SAK-50378 --

-- SAK-50536
drop table PROFILE_COMPANY_PROFILES_T;
drop table PROFILE_GALLERY_IMAGES_T;
drop table PROFILE_MESSAGE_PARTICIPANTS_T;
drop table PROFILE_MESSAGE_THREADS_T;
drop table PROFILE_MESSAGES_T;
drop table PROFILE_FRIENDS_T;
drop table PROFILE_KUDOS_T;
drop table PROFILE_PRIVACY_T;
drop table PROFILE_STATUS_T;
drop table PROFILE_WALL_ITEM_COMMENTS_T;
drop table PROFILE_WALL_ITEMS_T;
alter table PROFILE_SOCIAL_INFO_T drop column SKYPE_USERNAME;
-- END SAK-50536

-- SAK-47843
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_KEY, FUNCTION_NAME) VALUES(SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'conversations.question.create');
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_KEY, FUNCTION_NAME) VALUES(SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'conversations.discussion.create');

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template.course'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'Instructor'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'conversations.question.create')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template.course'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'Instructor'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'conversations.discussion.create')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template.course'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'Student'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'conversations.question.create')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template.course'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'Student'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'conversations.discussion.create')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'maintain'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'conversations.question.create')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'maintain'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'conversations.discussion.create')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'access'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'conversations.question.create')
);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY) VALUES (
    (SELECT REALM_KEY FROM SAKAI_REALM WHERE REALM_ID = '!site.template'),
    (SELECT ROLE_KEY FROM SAKAI_REALM_ROLE WHERE ROLE_NAME = 'access'),
    (SELECT FUNCTION_KEY FROM SAKAI_REALM_FUNCTION WHERE FUNCTION_NAME = 'conversations.discussion.create')
);
-- END SAK-47843

-- SAK-50200
create table SCORM_ACTIVITY_TREE_HOLDER_T (
        HOLDER_ID number(19,0) not null,
        CONTENT_PACKAGE_ID number(19,0),
        LEARNER_ID varchar2(255),
        ACT_TREE blob,
        primary key (HOLDER_ID)
);

create table SCORM_ADL_VALID_REQUESTS_T (
	VALID_REQUESTS_ID number(19,0) not null,
	IS_START_ENABLED number(1,0),
	IS_RESUME_ALL_ENABLED number(1,0),
	IS_CONTINUE_ENABLED number(1,0),
	IS_CONTINUE_EXIT_ENABLED number(1,0),
	IS_PREVIOUS_ENABLED number(1,0),
	IS_SUSPEND_VALID number(1,0),
	primary key (VALID_REQUESTS_ID)
);

create table SCORM_ATTEMPT_T (
	ATTEMPT_ID number(19,0) not null,
	CONTENT_PACKAGE_ID number(19,0),
	COURSE_ID varchar2(255),
	LEARNER_ID varchar2(255),
	LEARNER_NAME varchar2(255),
	ATTEMPT_NUMBER number(19,0),
	CREATED_ON date,
	MODIFIED_ON date,
	IS_SUSPENDED number(1,0),
	IS_NOT_EXITED number(1,0),
	primary key (ATTEMPT_ID)
);

create table SCORM_CONTENT_PACKAGE_T (
	PACKAGE_ID number(19,0) not null,
	TITLE varchar2(255),
	RESOURCE_ID varchar2(255),
	MANIFEST_ID raw(255),
	MANIFEST_RESOURCE_ID varchar2(255),
	CONTEXT varchar2(255),
	URL varchar2(255),
	RELEASE_ON date,
	DUE_ON date,
	ACCEPT_UNTIL date,
	CREATED_ON date,
	CREATED_BY varchar2(255),
	MODIFIED_ON date,
	MODIFIED_BY varchar2(255),
	NUMBER_OF_TRIES number(10,0),
	IS_DELETED number(1,0),
	primary key (PACKAGE_ID)
);

create table SCORM_CP_MANIFEST_T (
	MANIFEST_ID number(19,0) not null,
	ACT_TREE_PROTOTYPE blob,
	primary key (MANIFEST_ID)
);

create table SCORM_DATAMANAGER_T (
	DATAMANAGER_ID number(19,0) not null,
	CONTENT_PACKAGE_ID number(19,0),
	COURSE_ID varchar2(255),
	SCO_ID varchar2(255),
	ACTIVITY_ID varchar2(255),
	USER_ID varchar2(255),
	TITLE varchar2(255),
	ATTEMPT_NUMBER number(19,0),
	BEGIN_DATE date,
	LAST_MODIFIED_DATE date,
	primary key (DATAMANAGER_ID)
);

create table SCORM_DATAMODEL_T (
	DATAMODEL_ID number(19,0) not null,
	CLASS_TYPE varchar2(255) not null,
	BINDING varchar2(255),
	NAV_REQUESTS number(19,0),
	CURRENT_REQUEST varchar2(255),
	LEARNER_ID varchar2(255),
	SCO_ID varchar2(255),
	PROTOCOL varchar2(255),
	HOST varchar2(255),
	PORT number(10,0),
	FILE_NAME varchar2(255),
	AUTHORITY varchar2(255),
	REF varchar2(255),
	COURSE_ID varchar2(255),
	ATTEMPT_NUMBER varchar2(255),
	primary key (DATAMODEL_ID)
);

create table SCORM_DELIMITER_T (
	DELIM_ID number(19,0) not null,
	DESC_NAME varchar2(255),
	DEFAULT_VALUE varchar2(255),
	VALUE_SPM number(10,0),
	VALIDATOR number(19,0),
	VALUE varchar2(255),
	primary key (DELIM_ID)
);

create table SCORM_DELIMIT_DESC_T (
	DELIM_DESC_ID number(19,0) not null,
	DESC_NAME varchar2(255),
	DEFAULT_VALUE varchar2(255),
	VALUE_SPM number(10,0),
	VALIDATOR number(19,0),
	primary key (DELIM_DESC_ID)
);

create table SCORM_ELEMENT_DESC_T (
	ELEM_DESC_ID number(19,0) not null,
	ED_BINDING varchar2(255),
	IS_READABLE number(1,0),
	IS_WRITABLE number(1,0),
	INITIAL_VALUE varchar2(255),
	IS_UNIQUE number(1,0),
	IS_WRITE_ONCE number(1,0),
	VALUE_SPM number(10,0),
	SPM number(10,0),
	OLD_SPM number(10,0),
	IS_MAXIMUM number(1,0),
	IS_SHOW_CHILDREN number(1,0),
	primary key (ELEM_DESC_ID)
);

create table SCORM_ELEMENT_T (
	ELEMENT_ID number(19,0) not null,
	CLASS_TYPE varchar2(255) not null,
	DESCRIPTION number(19,0),
	PARENT number(19,0),
	VALUE clob,
	IS_INITIALIZED number(1,0),
	TRUNC_SPM number(1,0),
	ELEMENT_DM number(19,0),
	NAVIGATION_DM number(19,0),
	BINDING varchar2(255),
	IS_RANDOMIZED number(1,0),
	DM_COUNT number(10,0),
	primary key (ELEMENT_ID)
);

create table SCORM_LAUNCH_DATA_T (
	LAUNCH_DATA_ID number(19,0) not null,
	ORG_IDENTIFIER varchar2(255),
	ITEM_IDENTIFIER varchar2(255),
	RESOURCE_IDENTIFIER varchar2(255),
	MANIFEST_XML_BASE varchar2(255),
	RESOURCES_XML_BASE varchar2(255),
	RESOURCE_XML_BASE varchar2(255),
	PARAMETERS varchar2(255),
	PERSIST_STATE varchar2(255),
	LOCATION varchar2(255),
	SCORM_TYPE varchar2(255),
	ITEM_TITLE varchar2(255),
	DATA_FROM_LMS varchar2(4000),
	TIME_LIMIT_ACTION varchar2(255),
	MIN_NORMALIZED_MEASURE varchar2(255),
	ATTEMPT_ABS_DUR_LIMIT varchar2(255),
	COMPLETION_THRESHOLD varchar2(255),
	OBJECTIVES_LIST varchar2(255),
	IS_PREVIOUS number(1,0),
	IS_CONTINUE number(1,0),
	IS_EXIT number(1,0),
	IS_EXIT_ALL number(1,0),
	IS_ABANDON number(1,0),
	IS_SUSPEND_ALL number(1,0),
	primary key (LAUNCH_DATA_ID)
);

create table SCORM_LIST_BINDINGS_T (
	ELEMENT_ID number(19,0) not null,
	BINDING varchar2(255),
	SORT_ORDER number(10,0) not null,
	primary key (ELEMENT_ID, SORT_ORDER)
);

create table SCORM_LIST_DELIMITERS_T (
	ELEMENT_ID number(19,0) not null,
	DELIM_ID number(19,0) not null,
	SORT_ORDER number(10,0) not null,
	primary key (ELEMENT_ID, SORT_ORDER)
);

create table SCORM_LIST_DELIM_DESC_T (
	ELEM_DESC_ID number(19,0) not null,
	DELIM_DESC_ID number(19,0) not null,
	SORT_ORDER number(10,0) not null,
	primary key (ELEM_DESC_ID, SORT_ORDER)
);

create table SCORM_LIST_ELEMENTS_T (
	DATAMODEL_ID number(19,0) not null,
	ELEMENT_ID number(19,0) not null,
	SORT_ORDER number(10,0) not null,
	primary key (DATAMODEL_ID, SORT_ORDER)
);

create table SCORM_LIST_ELEM_DESC_T (
	ELEM_DESC_ID number(19,0) not null,
	CHILD_ID number(19,0) not null,
	SORT_ORDER number(10,0) not null,
	primary key (ELEM_DESC_ID, SORT_ORDER)
);

create table SCORM_LIST_LAUNCH_DATA_T (
	MANIFEST_ID number(19,0) not null,
	LAUNCH_DATA_ID number(19,0) not null,
	SORT_ORDER number(10,0) not null,
	primary key (MANIFEST_ID, SORT_ORDER)
);

create table SCORM_LIST_RECORDS_T (
	ELEMENT_ID number(19,0) not null,
	RECORD_ID number(19,0) not null,
	SORT_ORDER number(10,0) not null,
	primary key (ELEMENT_ID, SORT_ORDER)
);

create table SCORM_MAP_CHILDREN_T (
	ELEMENT_ID number(19,0) not null,
	CHILD_ID number(19,0) not null,
	CHILD_BINDING varchar2(255) not null,
	primary key (ELEMENT_ID, CHILD_BINDING)
);

create table SCORM_MAP_DATAMODELS_T (
	DATAMANAGER_ID number(19,0) not null,
	DATAMODEL_ID number(19,0) not null,
	DM_BINDING varchar2(255) not null,
	primary key (DATAMANAGER_ID, DM_BINDING)
);

create table SCORM_MAP_ELEMENTS_T (
	DATAMODEL_ID number(19,0) not null,
	ELEMENT_ID number(19,0) not null,
	ELEMENT_BINDING varchar2(255) not null,
	primary key (DATAMODEL_ID, ELEMENT_BINDING)
);

create table SCORM_MAP_SCO_DATAMANAGER_T (
	ATTEMPT_ID number(19,0) not null,
	DATAMANAGER_ID number(19,0),
	SCO_ID varchar2(255) not null,
	primary key (ATTEMPT_ID, SCO_ID)
);

create table SCORM_TYPE_VALIDATOR_T (
	ID number(19,0) not null,
	VALIDATOR_TYPE varchar2(255) not null,
	TYPE varchar2(255),
	INCLUDE_SUB_SECS number(1,0),
	INTER_ALLOW_EMPTY number(1,0),
	ELEMENT varchar2(255),
	INTERACTION_TYPE number(10,0),
	INT_MAX number(10,0),
	INT_MIN number(10,0),
	LANG_ALLOW_EMPTY number(1,0),
	REAL_MAX double precision,
	REAL_MIN double precision,
	RESULT_VOCAB_LIST raw(255),
	SPM number(10,0),
	URI_SPM number(10,0),
	VOCAB_LIST raw(255),
	primary key (ID)
);

create table SCORM_URL (
	URL_ID number(19,0) not null,
	PROTOCOL varchar2(255),
	HOST varchar2(255),
	PORT number(10,0),
	FILE_NAME varchar2(255),
	AUTHORITY varchar2(255),
	REF varchar2(255),
	primary key (URL_ID)
);

create index SCORM_DM_NAV_REQS_IDX on SCORM_DATAMODEL_T (NAV_REQUESTS);

alter table SCORM_DATAMODEL_T
	add constraint FKEA49336F15518963
	foreign key (NAV_REQUESTS)
	references SCORM_ADL_VALID_REQUESTS_T;

create index SCORM_DELIM_DESC_VAL_IDX on SCORM_DELIMITER_T (VALIDATOR);

alter table SCORM_DELIMITER_T
	add constraint FK4EF961B7B90DB7D6
	foreign key (VALIDATOR)
	references SCORM_TYPE_VALIDATOR_T;

alter table SCORM_DELIMIT_DESC_T
	add constraint FK94E28AB0B90DB7D6
	foreign key (VALIDATOR)
	references SCORM_TYPE_VALIDATOR_T;

alter table SCORM_ELEMENT_T
	add constraint FK573F602CCC73593B
	foreign key (NAVIGATION_DM)
	references SCORM_DATAMODEL_T;

alter table SCORM_ELEMENT_T
	add constraint FK573F602C5FFAD0D3
	foreign key (DESCRIPTION)
	references SCORM_ELEMENT_DESC_T;

alter table SCORM_ELEMENT_T
	add constraint FK573F602C6C5A23E6
	foreign key (ELEMENT_DM)
	references SCORM_DATAMODEL_T;

alter table SCORM_ELEMENT_T
	add constraint FK573F602CB9181FF2
	foreign key (PARENT)
	references SCORM_ELEMENT_T;

alter table SCORM_LIST_BINDINGS_T
	add constraint FKC3B4D95FB51407A8
	foreign key (ELEMENT_ID)
	references SCORM_ELEMENT_T;

alter table SCORM_LIST_DELIMITERS_T
	add constraint FKEE1279D16C13886
	foreign key (ELEMENT_ID)
	references SCORM_ELEMENT_T;

alter table SCORM_LIST_DELIMITERS_T
	add constraint FKEE1279DBF0F683E
	foreign key (DELIM_ID)
	references SCORM_DELIMITER_T;

alter table SCORM_LIST_DELIM_DESC_T
	add constraint FK7F5CED925C1B7EDB
	foreign key (DELIM_DESC_ID)
	references SCORM_DELIMIT_DESC_T;

alter table SCORM_LIST_DELIM_DESC_T
	add constraint FK7F5CED92BCF1DB0
	foreign key (ELEM_DESC_ID)
	references SCORM_ELEMENT_DESC_T;

alter table SCORM_LIST_ELEMENTS_T
	add constraint FK8BBE81883718242
	foreign key (DATAMODEL_ID)
	references SCORM_DATAMODEL_T;

alter table SCORM_LIST_ELEMENTS_T
	add constraint FK8BBE818816C13886
	foreign key (ELEMENT_ID)
	references SCORM_ELEMENT_T;

alter table SCORM_LIST_ELEM_DESC_T
	add constraint FK398F75DA29AF63F5
	foreign key (CHILD_ID)
	references SCORM_ELEMENT_DESC_T;

alter table SCORM_LIST_ELEM_DESC_T
	add constraint FK398F75DABCF1DB0
	foreign key (ELEM_DESC_ID)
	references SCORM_ELEMENT_DESC_T;

alter table SCORM_LIST_LAUNCH_DATA_T
	add constraint FK34C18F0FDCBCFBA4
	foreign key (MANIFEST_ID)
	references SCORM_CP_MANIFEST_T;

alter table SCORM_LIST_LAUNCH_DATA_T
	add constraint FK34C18F0F288F42D7
	foreign key (LAUNCH_DATA_ID)
	references SCORM_LAUNCH_DATA_T;

alter table SCORM_LIST_RECORDS_T
	add constraint FK9133CF7B16C13886
	foreign key (ELEMENT_ID)
	references SCORM_ELEMENT_T;

alter table SCORM_LIST_RECORDS_T
	add constraint FK9133CF7B2FA56F11
	foreign key (RECORD_ID)
	references SCORM_ELEMENT_T;

alter table SCORM_MAP_CHILDREN_T
	add constraint FK33DB495C57572E66
	foreign key (CHILD_ID)
	references SCORM_ELEMENT_T;

alter table SCORM_MAP_CHILDREN_T
	add constraint FK33DB495C16C13886
	foreign key (ELEMENT_ID)
	references SCORM_ELEMENT_T;

alter table SCORM_MAP_DATAMODELS_T
	add constraint FKC5D1D6B1DA8EBA2F
	foreign key (DATAMODEL_ID)
	references SCORM_DATAMODEL_T;

alter table SCORM_MAP_DATAMODELS_T
	add constraint FKC5D1D6B13D997146
	foreign key (DATAMANAGER_ID)
	references SCORM_DATAMANAGER_T;

alter table SCORM_MAP_ELEMENTS_T
	add constraint FK464CE542FEFA42
	foreign key (DATAMODEL_ID)
	references SCORM_DATAMODEL_T;

alter table SCORM_MAP_ELEMENTS_T
	add constraint FK464CE54FADFC393
	foreign key (ELEMENT_ID)
	references SCORM_ELEMENT_T;

alter table SCORM_MAP_SCO_DATAMANAGER_T
	add constraint FK194F83307DC2A49D
	foreign key (ATTEMPT_ID)
	references SCORM_ATTEMPT_T;

create sequence SCORM_UID_S MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;

ALTER TABLE SCORM_CONTENT_PACKAGE_T ADD SHOW_TOC NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE SCORM_CONTENT_PACKAGE_T ADD SHOW_NAV_BAR NUMBER(1,0) DEFAULT 0 NOT NULL;

ALTER TABLE SCORM_ELEMENT_T ADD (VALUE2 CLOB);
ALTER TABLE SCORM_ELEMENT_T DROP COLUMN VALUE;
ALTER TABLE SCORM_ELEMENT_T RENAME COLUMN VALUE2 TO VALUE;

INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'scorm.configure');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'scorm.delete');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'scorm.grade');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'scorm.launch');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'scorm.upload');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'scorm.validate');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'scorm.view.results');

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'access'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.launch'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.configure'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.delete'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.grade'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.launch'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.upload'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.validate'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.view.results'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.configure'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.delete'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.grade'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.launch'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.upload'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.validate'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.view.results'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.launch'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.configure'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.delete'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.grade'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.launch'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.upload'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.validate'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'scorm.view.results'));
-- END SAK-50200

-- SAK-44945
CREATE TABLE lti_tool_site (
    id NUMBER(11),
    tool_id NUMBER(11),
    SITE_ID VARCHAR2(99 CHAR),
    notes VARCHAR2(1024 CHAR),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    PRIMARY KEY (id)
);

CREATE SEQUENCE lti_tool_site_id_sequence INCREMENT BY 1 START WITH 1;
-- END SAK-44945
