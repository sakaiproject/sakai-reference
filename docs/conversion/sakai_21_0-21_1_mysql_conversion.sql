-- SAK-45435
ALTER TABLE lti_tools ADD     lti13_platform_public_old MEDIUMTEXT NULL;
ALTER TABLE lti_tools ADD     lti13_platform_public_old_at DATETIME NULL;
-- End SAK-45435

-- START SAK-45137
UPDATE rbc_rating SET title = '' WHERE title IS NULL;
ALTER TABLE rbc_rating MODIFY title varchar(255) NOT NULL;
UPDATE rbc_rating SET points = 0 WHERE points IS NULL;
ALTER TABLE rbc_rating MODIFY points double NOT NULL;
-- END SAK-45137
