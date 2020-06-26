-- clear unchanged bundle properties
DELETE SAKAI_MESSAGE_BUNDLE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

-- SAK-43826 : Rubrics: Support weighted criterions

ALTER TABLE rbc_rubric ADD COLUMN WEIGHTED bit(1) NOT NULL DEFAULT 0;
ALTER TABLE rbc_criterion ADD COLUMN WEIGHT DOUBLE NULL DEFAULT 0;
