-- SAK-48106
UPDATE user_audits_log AS audits INNER JOIN sakai_user_id_map AS idmap ON audits.user_id = idmap.eid SET audits.user_id = idmap.user_id;
UPDATE user_audits_log AS audits INNER JOIN sakai_user_id_map AS idmap ON audits.action_user_id = idmap.eid SET audits.action_user_id = idmap.user_id;
