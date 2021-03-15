-- clear unchanged bundle properties
DELETE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

-- this constraint may have been missed, it is ok if this line fails just comment it out
ALTER TABLE CONTENTREVIEW_ITEM ADD CONSTRAINT UK_8dngr1v68kkv4u11c1nvrjj1l UNIQUE (PROVIDERID, CONTENTID);

-- SAK-30079
ALTER TABLE MFR_PRIVATE_FORUM_T MODIFY AUTO_FORWARD INTEGER NOT NULL DEFAULT 2;

-- SAK-43826 : Rubrics: Support weighted criterions

ALTER TABLE RBC_RUBRIC ADD WEIGHTED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE RBC_CRITERION ADD WEIGHT DOUBLE PRECISION DEFAULT 0 NOT NULL;

-- SAK-44637 - Make the Lessons Placement checkbox work
-- Note that SAK-44636 already added the column in sakai_20_1-20_2_mysql_conversion.sql
-- It is included here and commented out in case you need it.
-- ALTER TABLE lti_tools ADD pl_lessonsselection TINYINT DEFAULT 0;
-- Existing records needed to be switched on right before the feature is used
UPDATE lti_tools SET pl_lessonsselection = 1;
-- END SAK-44637

-- SAK-45174 Rubrics metadata datetime conversion
ALTER TABLE rbc_criterion DROP COLUMN created;
ALTER TABLE rbc_criterion DROP COLUMN modified;
ALTER TABLE rbc_evaluation DROP COLUMN created;
ALTER TABLE rbc_evaluation DROP COLUMN modified;
ALTER TABLE rbc_rating DROP COLUMN created;
ALTER TABLE rbc_rating DROP COLUMN modified;
ALTER TABLE rbc_rubric DROP COLUMN created;
ALTER TABLE rbc_rubric DROP COLUMN modified;
ALTER TABLE rbc_tool_item_rbc_assoc DROP COLUMN created;
ALTER TABLE rbc_tool_item_rbc_assoc DROP COLUMN modified;

ALTER TABLE rbc_criterion ADD created TIMESTAMP NULL;
ALTER TABLE rbc_criterion ADD modified TIMESTAMP NULL;
ALTER TABLE rbc_evaluation ADD created TIMESTAMP NULL;
ALTER TABLE rbc_evaluation ADD modified TIMESTAMP NULL;
ALTER TABLE rbc_rating ADD created TIMESTAMP NULL;
ALTER TABLE rbc_rating ADD modified TIMESTAMP NULL;
ALTER TABLE rbc_rubric ADD created TIMESTAMP NULL;
ALTER TABLE rbc_rubric ADD modified TIMESTAMP NULL;
ALTER TABLE rbc_tool_item_rbc_assoc ADD created TIMESTAMP NULL;
ALTER TABLE rbc_tool_item_rbc_assoc ADD modified TIMESTAMP NULL;

UPDATE rbc_criterion SET created = current_timestamp WHERE created IS NULL;
UPDATE rbc_criterion SET modified = current_timestamp WHERE created IS NULL;
UPDATE rbc_evaluation SET created = current_timestamp WHERE created IS NULL;
UPDATE rbc_evaluation SET modified = current_timestamp WHERE created IS NULL;
UPDATE rbc_rating SET created = current_timestamp WHERE created IS NULL;
UPDATE rbc_rating SET modified = current_timestamp WHERE created IS NULL;
UPDATE rbc_rubric SET created = current_timestamp WHERE created IS NULL;
UPDATE rbc_rubric SET modified = current_timestamp WHERE created IS NULL;
UPDATE rbc_tool_item_rbc_assoc SET created = current_timestamp WHERE created IS NULL;
UPDATE rbc_tool_item_rbc_assoc SET modified = current_timestamp WHERE created IS NULL;
-- END SAK-45174
