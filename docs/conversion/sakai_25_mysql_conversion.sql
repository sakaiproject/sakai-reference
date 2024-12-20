-- clear unchanged bundle properties
DELETE SAKAI_MESSAGE_BUNDLE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

-- SAK-48106
UPDATE user_audits_log AS audits INNER JOIN SAKAI_USER_ID_MAP AS idmap ON audits.user_id = idmap.eid SET audits.user_id = idmap.user_id;
UPDATE user_audits_log AS audits INNER JOIN SAKAI_USER_ID_MAP AS idmap ON audits.action_user_id = idmap.eid SET audits.action_user_id = idmap.user_id;
-- END SAK-48106

-- SAK-48238
ALTER TABLE CONTENT_RESOURCE ADD COLUMN RESOURCE_SHA256 VARCHAR (64);
CREATE INDEX CONTENT_RESOURCE_SHA256 ON CONTENT_RESOURCE (RESOURCE_SHA256);
CREATE INDEX CONTENT_RESOURCE_FILE_PATH ON CONTENT_RESOURCE (FILE_PATH);

ALTER TABLE CONTENT_RESOURCE_BODY_BINARY ADD COLUMN RESOURCE_SHA256 VARCHAR (64);
CREATE INDEX CONTENT_RESOURCE_BB_SHA256 ON CONTENT_RESOURCE_BODY_BINARY (RESOURCE_SHA256 );

ALTER TABLE CONTENT_RESOURCE_DELETE ADD COLUMN RESOURCE_SHA256 VARCHAR (64);
CREATE INDEX CONTENT_RESOURCE_SHA256_DELETE_I ON CONTENT_RESOURCE_DELETE (RESOURCE_SHA256);
CREATE INDEX CONTENT_RESOURCE_FILE_PATH_DELETE_I ON CONTENT_RESOURCE_DELETE (FILE_PATH);
-- End SAK-48328

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
  ID VARCHAR(99) PRIMARY KEY,
  PLAYER_ID VARCHAR(99) NOT NULL,
  USER_ID VARCHAR(99) NOT NULL,
  HITS INT NOT NULL,
  MISSES INT NOT NULL,
  MARKED_AS_LEARNED BIT(1) NOT NULL
);

CREATE INDEX IDX_CARDGAME_STAT_ITEM_PLAYER_ID ON CARDGAME_STAT_ITEM (ID, PLAYER_ID);
-- END S2U-42 --

-- S2U-27 --
ALTER TABLE MFR_OPEN_FORUM_T ADD IS_FAQ_FORUM bit(1) DEFAULT b'0' NOT NULL;
ALTER TABLE MFR_TOPIC_T ADD IS_FAQ_TOPIC bit(1) DEFAULT b'0' NOT NULL;
-- END S2U-27 --

-- S2U-34 --
-- IMPORTANT: This index must be deleted and may have a different name, maybe UK_dn0jue890jn9p7vs6tvnsf2gf or similar
ALTER TABLE rbc_evaluation DROP INDEX `UKdn0jue890jn9p7vs6tvnsf2gf`;
CREATE UNIQUE INDEX `UKqsk75a24pi108jpybtt16hshv` ON `rbc_evaluation` (evaluated_item_owner_id, evaluated_item_id, association_id) COMMENT '' ALGORITHM DEFAULT LOCK DEFAULT;
UPDATE rbc_evaluation SET evaluated_item_owner_id = RIGHT(evaluated_item_owner_id, 36) where evaluated_item_owner_id like '/site/%';
ALTER TABLE rbc_tool_item_rbc_assoc_conf MODIFY COLUMN parameters int;
-- END S2U-34 --

-- S2U-11 --
ALTER TABLE SAM_ITEMTEXT_T ADD COLUMN ADDEDBUTNOTEXTRACTED BIT(1) DEFAULT FALSE NOT NULL;
ALTER TABLE SAM_PUBLISHEDITEMTEXT_T ADD COLUMN ADDEDBUTNOTEXTRACTED BIT(1) DEFAULT FALSE NOT NULL;
-- End S2U-11 --

-- S2U-39 --
CREATE TABLE rwikipagegroups (
    rwikiobjectid VARCHAR(36) NOT NULL,
    groupid VARCHAR(99) NOT NULL
)
-- END S2U-39 --

-- S2U-23 --
ALTER TABLE SAM_PUBLISHEDFEEDBACK_T ADD SHOWCORRECTION bit(1) DEFAULT b'0' NOT NULL;
ALTER TABLE SAM_ASSESSFEEDBACK_T ADD SHOWCORRECTION bit(1) DEFAULT b'0' NOT NULL;
-- to preserve the complete functionality on assessments previous to the patch with 'showcorrectresponse' enabled
UPDATE SAM_PUBLISHEDFEEDBACK_T SET showcorrection = 1 WHERE showcorrection = 0 AND showcorrectresponse = 1;
UPDATE SAM_ASSESSFEEDBACK_T SET showcorrection = 1 WHERE showcorrection = 0 AND showcorrectresponse = 1;
-- END S2U-23 --

-- S2U-29 --
alter table MFR_PVT_MSG_USR_T add READ_RECEIPT bit(1) DEFAULT null;
-- END S2U-29 --

-- SAK-49591 --
CREATE TABLE `SAM_ITEMHISTORICAL_T` (
  `ITEMHISTORICALID` bigint(20) NOT NULL AUTO_INCREMENT,
  `ITEMID` bigint(20) NOT NULL,
  `MODIFIEDBY` varchar(255) NOT NULL,
  `MODIFIEDDATE` datetime NOT NULL,
  PRIMARY KEY (`ITEMHISTORICALID`),
  KEY `SAM_ITEMHISTORICAL_ITEMID_I` (`ITEMID`),
  CONSTRAINT `FK_ITEMHISTORICAL_ITEM` FOREIGN KEY (`ITEMID`) REFERENCES `SAM_ITEM_T` (`ITEMID`)
);
-- END SAK-49591 --

-- S2U-32 and S2U-28 --
CREATE TABLE `tagservice_tagassociation` (
  `id` varchar(99) NOT NULL,
  `tag_id` varchar(255) NOT NULL,
  `item_id` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK7tc7vcvcb0bw8moqdu3giik6o` (`tag_id`,`item_id`)
);
-- Permission added in 12 might not be present 
MERGE INTO SAKAI_REALM_FUNCTION srf
USING (
SELECT -123 as function_key,
'tagservice.manage' as function_name
FROM dual
) t on (srf.function_name = t.function_name)
WHEN NOT MATCHED THEN
INSERT (function_key, function_name)
VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, t.function_name);
-- Add this for every role able to create and manage tags on a site, you'll need to add the tool too
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'tagservice.manage'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'tagservice.manage'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'tagservice.manage'));
-- Add this to populate existing sites with the permission
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));
INSERT INTO PERMISSIONS_SRC_TEMP values ('maintain','tagservice.manage');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Instructor','tagservice.manage');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Teaching Assistant','tagservice.manage');

CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
  SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
    from PERMISSIONS_SRC_TEMP TMPSRC
    JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
    JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
  SELECT SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
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
  ID BIGINT(20) NOT NULL AUTO_INCREMENT,
  PUBLISHEDASSESSMENTID BIGINT(20) NOT NULL,
  AGENTID VARCHAR(99) NOT NULL,
  URL VARCHAR(255) NOT NULL,
  CONFIGKEYHASH VARCHAR(64) DEFAULT NULL,
  EXAMKEYHASH VARCHAR(64) DEFAULT NULL,
  EXPIRED BIT(1) NOT NULL,
  CONSTRAINT PK_SAM_SEBVALIDATION_T PRIMARY KEY (ID)
);

CREATE INDEX SAM_SEB_INDEX ON SAM_SEBVALIDATION_T (PUBLISHEDASSESSMENTID, AGENTID);
-- END S2U-21 --

-- S2U-14 --
ALTER TABLE SAM_PUBLISHEDITEM_T ADD CANCELLATION TINYINT DEFAULT 0 NOT NULL;
-- END S2U-14 --

-- S2U-5 --
ALTER TABLE rbc_rubric ADD adhoc bit(1) DEFAULT 0;
-- End S2U-5 --

-- S2U-35 --
CREATE TABLE COND_CONDITION (
  ID varchar(36) NOT NULL,
  COND_TYPE varchar(99) NOT NULL,
  OPERATOR varchar(99) DEFAULT NULL,
  ARGUMENT varchar(999) DEFAULT NULL,
  SITE_ID varchar(36) NOT NULL,
  TOOL_ID varchar(99) NOT NULL,
  ITEM_ID varchar(99) DEFAULT NULL,
  PRIMARY KEY (ID),
  KEY IDX_CONDITION_SITE_ID (SITE_ID)
);

CREATE TABLE COND_PARENT_CHILD (
  PARENT_ID varchar(36) NOT NULL,
  CHILD_ID varchar(36) NOT NULL,
  PRIMARY KEY (PARENT_ID, CHILD_ID),
  KEY FK_CHILD_ID_CONDITION_ID (CHILD_ID),
  CONSTRAINT FK_CHILD_ID_CONDITION_ID FOREIGN KEY (CHILD_ID) REFERENCES COND_CONDITION (ID),
  CONSTRAINT FK_PARENT_ID_CONDITION_ID FOREIGN KEY (PARENT_ID) REFERENCES COND_CONDITION (ID)
);

-- Permission added might not be present 
INSERT IGNORE INTO SAKAI_REALM_FUNCTION (FUNCTION_NAME) VALUES ('conditions.update.condition');
-- Add this for every role able to create and manage conditions on a site, you'll need to add the tool too
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'conditions.update.condition'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'conditions.update.condition'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'conditions.update.condition'));
-- Add this to populate existing sites with the permission
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));
INSERT INTO PERMISSIONS_SRC_TEMP values ('maintain','conditions.update.condition');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Instructor','conditions.update.condition');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Teaching Assistant','conditions.update.condition');

CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
  SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
    from PERMISSIONS_SRC_TEMP TMPSRC
    JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
    JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
  SELECT SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
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
CREATE TABLE `mc_site_synchronization` (
  `id` varchar(99) NOT NULL,
  `site_id` varchar(255) NOT NULL,
  `team_id` varchar(255) NOT NULL,
  `forced` bit(1) DEFAULT NULL,
  `date_from` datetime DEFAULT NULL,
  `date_to` datetime DEFAULT NULL,
  `status` int DEFAULT NULL,
  `status_updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKmc_ss` (`site_id`,`team_id`)
);

CREATE TABLE `mc_group_synchronization` (
  `id` varchar(99) NOT NULL,
  `parentId` varchar(99) DEFAULT NULL,
  `group_id` varchar(255) NOT NULL,
  `channel_id` varchar(255) NOT NULL,
  `status` int DEFAULT NULL,
  `status_updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKmc_gs` (`parentId`,`group_id`,`channel_id`),
  CONSTRAINT `FKmc_gs_ss` FOREIGN KEY (`parentId`) REFERENCES `mc_site_synchronization` (`id`) ON DELETE CASCADE
);

CREATE TABLE `mc_config_item` (
  `item_key` varchar(255) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`item_key`)
);

CREATE TABLE `mc_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `context` longtext,
  `event` varchar(255) DEFAULT NULL,
  `event_date` datetime DEFAULT NULL,
  `status` int DEFAULT NULL,
  PRIMARY KEY (`id`)
);
-- END S2U-46 --

-- S2U-47 --
CREATE TABLE `meeting_providers` (
  `provider_id` varchar(99) NOT NULL,
  `provider_name` varchar(255) NOT NULL,
  PRIMARY KEY (`provider_id`)
);

CREATE TABLE `meetings` (
  `meeting_id` varchar(99) NOT NULL,
  `meeting_description` text,
  `meeting_end_date` datetime DEFAULT NULL,
  `meeting_owner_id` varchar(99) DEFAULT NULL,
  `meeting_site_id` varchar(99) DEFAULT NULL,
  `meeting_start_date` datetime DEFAULT NULL,
  `meeting_title` varchar(255) NOT NULL,
  `meeting_url` varchar(255) DEFAULT NULL,
  `meeting_provider_id` varchar(99) DEFAULT NULL,
  PRIMARY KEY (`meeting_id`),
  KEY `FK_m_mp` (`meeting_provider_id`),
  CONSTRAINT `FK_m_mp` FOREIGN KEY (`meeting_provider_id`) REFERENCES `meeting_providers` (`provider_id`)
);

CREATE TABLE `meeting_properties` (
  `prop_id` bigint NOT NULL AUTO_INCREMENT,
  `prop_name` varchar(255) NOT NULL,
  `prop_value` varchar(255) DEFAULT NULL,
  `prop_meeting_id` varchar(99) DEFAULT NULL,
  PRIMARY KEY (`prop_id`),
  KEY `FK_mp_m` (`prop_meeting_id`),
  CONSTRAINT `FK_mp_m` FOREIGN KEY (`prop_meeting_id`) REFERENCES `meetings` (`meeting_id`)
);

CREATE TABLE `meeting_attendees` (
  `attendee_id` bigint NOT NULL AUTO_INCREMENT,
  `attendee_object_id` varchar(255) DEFAULT NULL,
  `attendee_type` int DEFAULT NULL,
  `attendee_meeting_id` varchar(99) DEFAULT NULL,
  PRIMARY KEY (`attendee_id`),
  KEY `FK_ma_m` (`attendee_meeting_id`),
  CONSTRAINT `FK_ma_m` FOREIGN KEY (`attendee_meeting_id`) REFERENCES `meetings` (`meeting_id`)
);
-- END S2U-47 --

-- S2U-49 --
CREATE TABLE `mc_access_token` (
  `sakaiUserId` varchar(255) NOT NULL,
  `accessToken` text,
  `microsoftUserId` varchar(255) DEFAULT NULL,
  `account` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sakaiUserId`)
);
-- END S2U-49 --

-- S2U-16 --
ALTER TABLE `SAM_ITEMGRADING_T` ADD COLUMN `ATTEMPTDATE` DATETIME NULL;

CREATE TABLE `SAM_SECTIONGRADING_T` (
  `SECTIONGRADINGID` bigint NOT NULL AUTO_INCREMENT,
  `ASSESSMENTGRADINGID` bigint NOT NULL,
  `PUBLISHEDSECTIONID` bigint NOT NULL,
  `AGENTID` varchar(255) NOT NULL,
  `ATTEMPTDATE` datetime DEFAULT NULL,
  PRIMARY KEY (`SECTIONGRADINGID`),
  UNIQUE KEY `uniqueStudentSectionResponse` (`ASSESSMENTGRADINGID`,`PUBLISHEDSECTIONID`,`AGENTID`)
);
-- S2U-16 --

-- S2U-19 --
ALTER TABLE SAM_ITEM_T ADD COLUMN ISFIXED BIT(1) DEFAULT FALSE NOT NULL;
ALTER TABLE SAM_PUBLISHEDITEM_T ADD COLUMN ISFIXED BIT(1) DEFAULT FALSE NOT NULL;
-- END S2U-19 --

-- SAK-46714 --
ALTER TABLE `lti_tools` DROP `lti13_platform_public_next`;
ALTER TABLE `lti_tools` DROP `lti13_platform_public_next_at`;
ALTER TABLE `lti_tools` DROP `lti13_platform_private_next`;
ALTER TABLE `lti_tools` DROP `lti13_platform_public`;
ALTER TABLE `lti_tools` DROP `lti13_platform_private`;
ALTER TABLE `lti_tools` DROP `lti13_platform_public_old`;
ALTER TABLE `lti_tools` DROP `lti13_platform_public_old_at`; 
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

