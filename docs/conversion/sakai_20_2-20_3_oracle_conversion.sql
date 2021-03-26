-- START SAK-42371
ALTER TABLE rbc_evaluation ADD COLUMN status NUMBER(1,0) NOT NULL;
UPDATE rbc_evaluation SET status = 2;
-- END SAK-42371

-- START SAK-45137
UPDATE rbc_rating SET title = 'Title' WHERE title IS NULL;
ALTER TABLE rbc_rating MODIFY title VARCHAR2(255) NOT NULL;
UPDATE rbc_rating SET points = 0 WHERE points IS NULL;
ALTER TABLE rbc_rating MODIFY points FLOAT NOT NULL;
-- END SAK-45137

-- SAK-44810 - Add $Resource.id.history
-- This needs to rename a column in the DB because of a bug that keeps "settings"
-- from working as needed for this feature.
ALTER TABLE lti_tools RENAME COLUMN allowsettings TO allowsettings_ext;
-- If autoDDL somehow already ran and created allowsettings_ext - then you need
-- to copy data from the old column and delete it
-- UPDATE lti_tools SET allowsettings_ext=allowsettings;
-- ALTER TABLE lti_tools DROP COLUMN allowsettings;
-- END SAK-44810

-- SAK-41502
ALTER TABLE GB_GRADING_EVENT_T ADD IS_EXCLUDED NUMBER(10, 0);
-- END SAK-41502
