-- S2U-19 --
ALTER TABLE SAM_ITEM_T ADD COLUMN ISFIXED BIT(1) DEFAULT FALSE NOT NULL;
ALTER TABLE SAM_PUBLISHEDITEM_T ADD COLUMN ISFIXED BIT(1) DEFAULT FALSE NOT NULL;
-- END S2U-19 --
