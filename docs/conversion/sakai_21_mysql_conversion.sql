-- clear unchanged bundle properties
DELETE SAKAI_MESSAGE_BUNDLE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

-- this constraint may have been missed, it is ok if this line fails just comment it out
ALTER TABLE CONTENTREVIEW_ITEM ADD CONSTRAINT UK_8dngr1v68kkv4u11c1nvrjj1l UNIQUE (PROVIDERID, CONTENTID);

-- SAK-30079
ALTER TABLE MFR_PRIVATE_FORUM_T MODIFY COLUMN AUTO_FORWARD INT NOT NULL DEFAULT 2;

-- SAK-43826 : Rubrics: Support weighted criterions

ALTER TABLE rbc_rubric ADD COLUMN WEIGHTED bit(1) NOT NULL DEFAULT 0;
ALTER TABLE rbc_criterion ADD COLUMN WEIGHT DOUBLE NULL DEFAULT 0;

-- SAK-44637 - Make the Lessons Placement checkbox work
-- Note that SAK-44636 already added the column in sakai_20_1-20_2_mysql_conversion.sql
-- It is included here and commented out in case you need it.
-- ALTER TABLE lti_tools ADD pl_lessonsselection TINYINT DEFAULT 0;
-- Existing records needed to be switched on right before the feature is used
UPDATE lti_tools SET pl_lessonsselection = 1;
-- END SAK-44637

-- SAK-44055 - IMS LTI Advantage Autoprovision
ALTER TABLE lti_tools ADD lti13_auto_token VARCHAR(1024);
ALTER TABLE lti_tools ADD lti13_auto_state INT;
ALTER TABLE lti_tools ADD lti13_auto_registration MEDIUMTEXT;
