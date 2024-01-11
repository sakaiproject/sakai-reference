-- SAK-42700 add indexes via JPA for common queries 

ALTER TABLE rbc_evaluation 
  MODIFY COLUMN ownerType varchar(99),
  MODIFY COLUMN evaluated_item_owner_id varchar(99),
  MODIFY COLUMN evaluator_id varchar(99),
  MODIFY COLUMN creatorId varchar(99),
  MODIFY COLUMN ownerId varchar(99),
  ADD INDEX rbc_eval_owner(ownerId);

ALTER TABLE rbc_tool_item_rbc_assoc
  MODIFY COLUMN ownerType varchar(99),
  MODIFY COLUMN toolId varchar(99),
  MODIFY COLUMN creatorId varchar(99),
  MODIFY COLUMN ownerId varchar(99),
  ADD INDEX rbc_tool_item_owner(toolId, itemId, ownerId);

ALTER TABLE rbc_criterion
  MODIFY COLUMN ownerType varchar(99),
  MODIFY COLUMN creatorId varchar(99),
  MODIFY COLUMN ownerId varchar(99);

ALTER TABLE rbc_rating
  MODIFY COLUMN ownerType varchar(99),
  MODIFY COLUMN creatorId varchar(99),
  MODIFY COLUMN ownerId varchar(99);

ALTER TABLE rbc_rubric
  MODIFY COLUMN ownerType varchar(99),
  MODIFY COLUMN creatorId varchar(99),
  MODIFY COLUMN ownerId varchar(99);

-- END SAK-42700

-- BEGIN SAK-42748
ALTER TABLE BULLHORN_ALERTS ADD INDEX IDX_BULLHORN_ALERTS_EVENT_REF(EVENT, REF);
-- END SAK-42748

-- SAK-41175
ALTER TABLE rbc_criterion_outcome MODIFY COLUMN points DOUBLE NULL DEFAULT NULL;
ALTER TABLE rbc_rating MODIFY COLUMN points DOUBLE NULL DEFAULT NULL;
-- END SAK-41175
