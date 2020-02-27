-- SAK-42700 add indexes via JPA for common queries 

ALTER TABLE rbc_evaluation MODIFY (
   ownerType varchar2(99),
   evaluated_item_owner_id varchar2(99),
   evaluator_id varchar2(99),
   creatorId varchar2(99),
   ownerId varchar2(99)
);

CREATE INDEX rbc_eval_owner ON rbc_evaluation(ownerId);

ALTER TABLE rbc_tool_item_rbc_assoc MODIFY (
   ownerType varchar2(99),
   toolId varchar2(99),
   creatorId varchar2(99),
   ownerId varchar2(99)
);

CREATE INDEX rbc_tool_item_owner ON rbc_tool_item_rbc_assoc(toolId, itemId, ownerId);

ALTER TABLE rbc_criterion MODIFY (
   ownerType varchar2(99),
   creatorId varchar2(99),
   ownerId varchar2(99)
);

ALTER TABLE rbc_rating MODIFY (
   ownerType varchar2(99),
   creatorId varchar2(99),
   ownerId varchar2(99)
);

ALTER TABLE rbc_rubric MODIFY (
   ownerType varchar2(99),
   creatorId varchar2(99),
   ownerId varchar2(99)
);

-- END SAK-42700

-- SAK-41175
ALTER TABLE rbc_criterion_outcome MODIFY points DOUBLE PRECISION DEFAULT NULL;
ALTER TABLE rbc_rating MODIFY points DOUBLE PRECISION DEFAULT NULL;
-- END SAK-41175
