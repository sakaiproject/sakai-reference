-- S2U-12 --
ALTER TABLE sam_itemfeedback_t ADD TEXT_CLOB CLOB;
UPDATE sam_itemfeedback_t set TEXT_CLOB = TEXT;  -- convert varchar2 to CLOB
ALTER TABLE sam_itemfeedback_t drop column TEXT;
ALTER TABLE sam_itemfeedback_t RENAME COLUMN TEXT_CLOB TO TEXT;

ALTER TABLE sam_publisheditemfeedback_t ADD TEXT_CLOB CLOB;
UPDATE sam_publisheditemfeedback_t set TEXT_CLOB = TEXT;  -- convert varchar2 to CLOB
ALTER TABLE sam_publisheditemfeedback_t drop column TEXT;
ALTER TABLE sam_publisheditemfeedback_t RENAME COLUMN TEXT_CLOB TO TEXT;
-- End S2U-12 --