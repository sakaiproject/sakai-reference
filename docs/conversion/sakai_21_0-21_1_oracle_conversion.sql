-- SAK-45435
ALTER TABLE lti_tools ADD lti13_platform_public_old CLOB;
ALTER TABLE lti_tools ADD lti13_platform_public_old_at DATE DEFAULT NULL;
-- End SAK-45435

-- START SAK-45137
UPDATE rbc_rating SET title = 'Title' WHERE title IS NULL;
ALTER TABLE rbc_rating MODIFY title VARCHAR2(255) NOT NULL;
UPDATE rbc_rating SET points = 0 WHERE points IS NULL;
ALTER TABLE rbc_rating MODIFY points FLOAT NOT NULL;
-- END SAK-45137
+
