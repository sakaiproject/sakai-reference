-- Begin SAK-47582
create index TOOL_IDX on lti_content (TOOL_ID);
-- End SAK-47582

-- SAK-47837 start
ALTER TABLE rbc_returned_criterion_out DROP FOREIGN KEY FK3sroha5yjh3cbvq0on02wf3fk;
ALTER TABLE rbc_criterion_outcome DROP FOREIGN KEY FKalvarr6g412wt7wto6tutsddu;

ALTER TABLE rbc_rating DROP COLUMN order_index;
ALTER TABLE rbc_criterion DROP COLUMN ownerId;
ALTER TABLE rbc_tool_item_rbc_assoc DROP COLUMN siteId;
ALTER TABLE rbc_rating MODIFY criterion_id BIGINT NOT NULL;
ALTER TABLE rbc_rating ALTER criterion_id DROP DEFAULT;
ALTER TABLE rbc_tool_item_rbc_assoc MODIFY rubric_id BIGINT NOT NULL;
ALTER TABLE rbc_tool_item_rbc_assoc ALTER rubric_id DROP DEFAULT;

CREATE INDEX rbc_tool_item ON rbc_tool_item_rbc_assoc(toolId, itemId);
DROP INDEX rbc_tool_item_owner ON rbc_tool_item_rbc_assoc;
-- SAK-47837 end
