-- clear unchanged bundle properties
DELETE SAKAI_MESSAGE_BUNDLE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

-- this constraint may have been missed, it is ok if this line fails just comment it out
ALTER TABLE CONTENTREVIEW_ITEM ADD CONSTRAINT UK_8dngr1v68kkv4u11c1nvrjj1l UNIQUE (PROVIDERID, CONTENTID);

-- SAK-30079
ALTER TABLE MFR_PRIVATE_FORUM_T MODIFY COLUMN AUTO_FORWARD INT NOT NULL DEFAULT 2;

-- SAK-43826 : Rubrics: Support weighted criterions

ALTER TABLE rbc_rubric ADD COLUMN WEIGHTED bit(1) NOT NULL DEFAULT 0;
ALTER TABLE rbc_criterion ADD COLUMN WEIGHT DOUBLE NULL DEFAULT 0;

