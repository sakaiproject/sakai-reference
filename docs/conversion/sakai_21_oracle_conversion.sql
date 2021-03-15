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
ALTER TABLE rbc_criterion DROP created;
ALTER TABLE rbc_criterion DROP modified;
ALTER TABLE rbc_evaluation DROP created;
ALTER TABLE rbc_evaluation DROP modified;
ALTER TABLE rbc_rating DROP created;
ALTER TABLE rbc_rating DROP modified;
ALTER TABLE rbc_rubric DROP created;
ALTER TABLE rbc_rubric DROP modified;
ALTER TABLE rbc_tool_item_rbc_assoc DROP created;
ALTER TABLE rbc_tool_item_rbc_assoc DROP modified;

ALTER TABLE rbc_criterion ADD created DATETIME NULL;
ALTER TABLE rbc_criterion ADD modified DATETIME NULL;
ALTER TABLE rbc_evaluation ADD created DATETIME NULL;
ALTER TABLE rbc_evaluation ADD modified DATETIME NULL;
ALTER TABLE rbc_rating ADD created DATETIME NULL;
ALTER TABLE rbc_rating ADD modified DATETIME NULL;
ALTER TABLE rbc_rubric ADD created DATETIME NULL;
ALTER TABLE rbc_rubric ADD modified DATETIME NULL;
ALTER TABLE rbc_tool_item_rbc_assoc ADD created DATETIME NULL;
ALTER TABLE rbc_tool_item_rbc_assoc ADD modified DATETIME NULL;

UPDATE rbc_criterion SET created = NOW() WHERE created IS NULL;
UPDATE rbc_criterion SET modified = NOW() WHERE created IS NULL;
UPDATE rbc_evaluation SET created = NOW() WHERE created IS NULL;
UPDATE rbc_evaluation SET modified = NOW() WHERE created IS NULL;
UPDATE rbc_rating SET created = NOW() WHERE created IS NULL;
UPDATE rbc_rating SET modified = NOW() WHERE created IS NULL;
UPDATE rbc_rubric SET created = NOW() WHERE created IS NULL;
UPDATE rbc_rubric SET modified = NOW() WHERE created IS NULL;
UPDATE rbc_tool_item_rbc_assoc SET created = NOW() WHERE created IS NULL;
UPDATE rbc_tool_item_rbc_assoc SET modified = NOW() WHERE created IS NULL;
-- END SAK-45174
