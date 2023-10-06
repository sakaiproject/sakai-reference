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
