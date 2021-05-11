-- SAK-45435
ALTER TABLE lti_tools ADD lti13_platform_public_old BLOB;
ALTER TABLE lti_tools ADD lti13_platform_public_old_at DATE DEFAULT NULL;
-- End SAK-45435
