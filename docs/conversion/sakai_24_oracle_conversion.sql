-- SAK-48106
UPDATE user_audits_log audits INNER JOIN SAKAI_USER_ID_MAP idmap ON audits.user_id = idmap.eid SET audits.user_id = idmap.user_id;
UPDATE user_audits_log audits INNER JOIN SAKAI_USER_ID_MAP idmap ON audits.action_user_id = idmap.eid SET audits.action_user_id = idmap.user_id;
-- END SAK-48106

-- S2U-12 --
ALTER TABLE sam_itemfeedback_t MODIFY TEXT LONGTEXT;
ALTER TABLE sam_publisheditemfeedback_t MODIFY TEXT LONGTEXT;
-- End S2U-12 --
