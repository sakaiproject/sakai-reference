-- SAK-45435
ALTER TABLE lti_tools ADD lti13_platform_public_old CLOB;
ALTER TABLE lti_tools ADD lti13_platform_public_old_at DATE DEFAULT NULL;
-- End SAK-45435

-- SAK-43510
ALTER TABLE SAKAI_PERSON_T ADD PRONOUNS VARCHAR2(255);
-- End SAK-43510

-- SAK-45491
ALTER TABLE lti_tools ADD lti13_platform_public_next CLOB;
ALTER TABLE lti_tools ADD lti13_platform_public_next_at DATE NULL;
ALTER TABLE lti_tools ADD lti13_platform_private_next CLOB
-- End SAK-45491

