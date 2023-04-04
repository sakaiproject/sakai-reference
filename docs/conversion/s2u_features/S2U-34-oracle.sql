-- S2U-34 --
ALTER TABLE rbc_evaluation DROP INDEX `UKdn0jue890jn9p7vs6tvnsf2gf`;
CREATE UNIQUE INDEX `UKqsk75a24pi108jpybtt16hshv` ON `rbc_evaluation` (evaluated_item_owner_id, evaluated_item_id, association_id) COMMENT '' ALGORITHM DEFAULT LOCK DEFAULT;
UPDATE rbc_evaluation SET evaluated_item_owner_id = SUBSTR(evaluated_item_owner_id, -36) where evaluated_item_owner_id like '/site/%';
-- END S2U-34 --
