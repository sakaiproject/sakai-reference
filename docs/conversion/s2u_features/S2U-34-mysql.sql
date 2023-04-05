-- S2U-34 --
-- IMPORTANT: This index must be deleted and may have a different name, maybe UK_dn0jue890jn9p7vs6tvnsf2gf or similar
ALTER TABLE rbc_evaluation DROP INDEX `UKdn0jue890jn9p7vs6tvnsf2gf`;
CREATE UNIQUE INDEX `UKqsk75a24pi108jpybtt16hshv` ON `rbc_evaluation` (evaluated_item_owner_id, evaluated_item_id, association_id) COMMENT '' ALGORITHM DEFAULT LOCK DEFAULT;
UPDATE rbc_evaluation SET evaluated_item_owner_id = RIGHT(evaluated_item_owner_id, 36) where evaluated_item_owner_id like '/site/%';
ALTER TABLE rbc_tool_item_rbc_assoc_conf MODIFY COLUMN parameters int;
-- END S2U-34 --
