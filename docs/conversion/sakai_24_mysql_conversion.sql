-- SAK-48106
UPDATE user_audits_log AS audits INNER JOIN SAKAI_USER_ID_MAP AS idmap ON audits.user_id = idmap.eid SET audits.user_id = idmap.user_id;
UPDATE user_audits_log AS audits INNER JOIN SAKAI_USER_ID_MAP AS idmap ON audits.action_user_id = idmap.eid SET audits.action_user_id = idmap.user_id;
-- END SAK-48106

-- SAK-49006
DELETE FROM email_template_item WHERE TEMPLATE_KEY IN ('sitemanage.siteImport.Confirmation', 'sitemange.notifyAddedParticipant', 'sitemanage.notifyNewUserEmail');
-- END SAK-49006
