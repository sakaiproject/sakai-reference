-- S2U-34 --
-- IMPORTANT: This index must be deleted and may have a different name, maybe UK_dn0jue890jn9p7vs6tvnsf2gf or similar
DROP INDEX UKdn0jue890jn9p7vs6tvnsf2gf;
CREATE UNIQUE INDEX UKqsk75a24pi108jpybtt16hshv ON RBC_EVALUATION (EVALUATED_ITEM_OWNER_ID, EVALUATED_ITEM_ID, ASSOCIATION_ID);
UPDATE rbc_evaluation SET evaluated_item_owner_id = SUBSTR(evaluated_item_owner_id, -36) where evaluated_item_owner_id like '/site/%';
-- END S2U-34 --
