-- Begin SAK-47582
create index TOOL_IDX on lti_content (TOOL_ID);
-- End SAK-47582

-- SAK-47837 start

ALTER TABLE rbc_returned_criterion_out DROP CONSTRAINT FK3sroha5yjh3cbvq0on02wf3fk;
ALTER TABLE rbc_criterion_outcome DROP CONSTRAINT FKalvarr6g412wt7wto6tutsddu;

-- order_index will be added back in 22.3 script
-- ALTER TABLE rbc_rating DROP COLUMN order_index;
ALTER TABLE rbc_criterion DROP COLUMN ownerId;
ALTER TABLE rbc_tool_item_rbc_assoc DROP COLUMN siteId;
ALTER TABLE rbc_rating MODIFY criterion_id NUMBER(19,0) NOT NULL;
ALTER TABLE rbc_rating ALTER criterion_id DEFAULT NULL;
ALTER TABLE rbc_tool_item_rbc_assoc MODIFY rubric_id NUMBER(19,0) NOT NULL;
ALTER TABLE rbc_tool_item_rbc_assoc ALTER rubric_id DEFAULT NULL;

CREATE INDEX rbc_tool_item ON rbc_tool_item_rbc_assoc(toolId, itemId);
-- SAK-47837 end
