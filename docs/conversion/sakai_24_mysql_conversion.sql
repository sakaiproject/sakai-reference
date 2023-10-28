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

INSERT INTO sakai_realm_function (FUNCTION_NAME) VALUES
('conversations.question.create'),
('conversations.discussion.create');

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
