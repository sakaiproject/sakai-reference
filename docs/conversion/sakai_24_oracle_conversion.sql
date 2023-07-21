-- SAK-48106
UPDATE user_audits_log audits INNER JOIN SAKAI_USER_ID_MAP idmap ON audits.user_id = idmap.eid SET audits.user_id = idmap.user_id;
UPDATE user_audits_log audits INNER JOIN SAKAI_USER_ID_MAP idmap ON audits.action_user_id = idmap.eid SET audits.action_user_id = idmap.user_id;
-- END SAK-48106


-- S2U-27 --
ALTER TABLE MFR_OPEN_FORUM_T ADD IS_FAQ_FORUM NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE MFR_TOPIC_T ADD IS_FAQ_TOPIC NUMBER(1,0) DEFAULT 0 NOT NULL;
-- END S2U-27 --
