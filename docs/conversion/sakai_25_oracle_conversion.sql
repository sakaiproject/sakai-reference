-- SAK-48106
UPDATE user_audits_log audits INNER JOIN SAKAI_USER_ID_MAP idmap ON audits.user_id = idmap.eid SET audits.user_id = idmap.user_id;
UPDATE user_audits_log audits INNER JOIN SAKAI_USER_ID_MAP idmap ON audits.action_user_id = idmap.eid SET audits.action_user_id = idmap.user_id;
-- END SAK-48106

-- S2U-12 --
ALTER TABLE sam_itemfeedback_t MODIFY TEXT LONGTEXT;
ALTER TABLE sam_publisheditemfeedback_t MODIFY TEXT LONGTEXT;
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
INSERT IGNORE INTO SAKAI_REALM_FUNCTION (FUNCTION_NAME) VALUES ('tagservice.manage');
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
  id number(19, 0) NOT NULL,
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
  PRIMARY KEY (meeting_id)
,
  CONSTRAINT FK_m_mp FOREIGN KEY (meeting_provider_id) REFERENCES meeting_providers (provider_id)
);

CREATE INDEX FK_m_mp ON meetings (meeting_provider_id);

CREATE TABLE meeting_properties (
  prop_id number(19, 0) NOT NULL,
  prop_name varchar2(255) NOT NULL,
  prop_value varchar2(255) DEFAULT NULL,
  prop_meeting_id varchar2(99) DEFAULT NULL,
  PRIMARY KEY (prop_id)
,
  CONSTRAINT FK_mp_m FOREIGN KEY (prop_meeting_id) REFERENCES meetings (meeting_id)
);

-- Generate ID using sequence and trigger
CREATE SEQUENCE MEETING_PROPERTY_S START WITH 1 INCREMENT BY 1;

CREATE INDEX FK_mp_m ON meeting_properties (prop_meeting_id);

CREATE TABLE meeting_attendees (
  attendee_id number(19, 0) NOT NULL,
  attendee_object_id varchar2(255) DEFAULT NULL,
  attendee_type number(1, 0) DEFAULT NULL,
  attendee_meeting_id varchar2(99) DEFAULT NULL,
  PRIMARY KEY (attendee_id)
,
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
ALTER TABLE lti_tools DROP lti13_platform_public_next;
ALTER TABLE lti_tools DROP lti13_platform_public_next_at;
ALTER TABLE lti_tools DROP lti13_platform_private_next;
ALTER TABLE lti_tools DROP lti13_platform_public;
ALTER TABLE lti_tools DROP lti13_platform_private;
ALTER TABLE lti_tools DROP lti13_platform_public_old;
ALTER TABLE lti_tools DROP lti13_platform_public_old_at; 
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
