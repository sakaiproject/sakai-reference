
-- SAK-51949
ALTER TABLE CONTENT_RESOURCE DROP COLUMN XML;
ALTER TABLE CONTENT_RESOURCE_DELETE DROP COLUMN XML;
-- END SAK-51949

-- SAK-52193

-- Not used anymore
DROP TABLE PROFILE_EXTERNAL_INTEGRATION_T;
DROP TABLE PROFILE_IMAGES_EXTERNAL_T;

-- Not allowing multiple uploaded avatars at once
DELETE FROM PROFILE_IMAGES_T WHERE IS_CURRENT = 0;
ALTER TABLE PROFILE_IMAGES_T DROP INDEX PROFILE_IMAGES_IS_CURRENT_I;
ALTER TABLE PROFILE_IMAGES_T DROP COLUMN IS_CURRENT;

-- Using USER_UUID as the primary key
ALTER TABLE PROFILE_IMAGES_T DROP COLUMN ID;
ALTER TABLE PROFILE_IMAGES_T ADD PRIMARY KEY (USER_UUID);
ALTER TABLE PROFILE_IMAGES_T DROP INDEX PROFILE_IMAGES_USER_UUID_I;

-- END SAK-52193

-- RUBRICS: clean duplicate/nullable evaluations before enforcing uniqueness
-- Normalize key values
UPDATE rbc_evaluation SET evaluated_item_id = TRIM(evaluated_item_id) WHERE evaluated_item_id IS NOT NULL;
UPDATE rbc_evaluation SET evaluated_item_owner_id = TRIM(evaluated_item_owner_id) WHERE evaluated_item_owner_id IS NOT NULL;

-- Remove unrecoverable rows with NULL keys (and their outcomes)
DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_nulls;
CREATE TEMPORARY TABLE tmp_rbc_eval_nulls (id BIGINT PRIMARY KEY);
INSERT INTO tmp_rbc_eval_nulls (id)
SELECT id FROM rbc_evaluation WHERE evaluated_item_id IS NULL OR evaluated_item_owner_id IS NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_null_outcomes;
CREATE TEMPORARY TABLE tmp_rbc_eval_null_outcomes (criterionOutcomes_id BIGINT PRIMARY KEY);
INSERT INTO tmp_rbc_eval_null_outcomes (criterionOutcomes_id)
SELECT DISTINCT eco.criterionOutcomes_id
FROM rbc_eval_criterion_outcomes eco
JOIN tmp_rbc_eval_nulls n ON eco.rbc_evaluation_id = n.id;

DELETE eco FROM rbc_eval_criterion_outcomes eco
JOIN tmp_rbc_eval_nulls n ON eco.rbc_evaluation_id = n.id;

DELETE co FROM rbc_criterion_outcome co
JOIN tmp_rbc_eval_null_outcomes o ON co.id = o.criterionOutcomes_id;

DELETE e FROM rbc_evaluation e
JOIN tmp_rbc_eval_nulls n ON e.id = n.id;

DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_null_outcomes;
DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_nulls;

-- Deduplicate by association/evaluated item/owner (prefer RETURNED, then latest modified/created)
DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_dupes;
CREATE TEMPORARY TABLE tmp_rbc_eval_dupes AS
SELECT association_id, evaluated_item_id, evaluated_item_owner_id
FROM rbc_evaluation
GROUP BY association_id, evaluated_item_id, evaluated_item_owner_id
HAVING COUNT(*) > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_keep;
CREATE TEMPORARY TABLE tmp_rbc_eval_keep (id BIGINT PRIMARY KEY);
INSERT INTO tmp_rbc_eval_keep (id)
SELECT e.id
FROM tmp_rbc_eval_dupes d
JOIN rbc_evaluation e ON e.association_id = d.association_id
    AND e.evaluated_item_id = d.evaluated_item_id
    AND e.evaluated_item_owner_id = d.evaluated_item_owner_id
WHERE e.id = (
    SELECT e2.id
    FROM rbc_evaluation e2
    WHERE e2.association_id = e.association_id
      AND e2.evaluated_item_id = e.evaluated_item_id
      AND e2.evaluated_item_owner_id = e.evaluated_item_owner_id
    ORDER BY CASE WHEN e2.status = 2 THEN 2 WHEN e2.status = 1 THEN 1 ELSE 0 END DESC,
             COALESCE(e2.modified, e2.created, '1970-01-01') DESC,
             e2.id DESC
    LIMIT 1
);

DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_remove;
CREATE TEMPORARY TABLE tmp_rbc_eval_remove AS
SELECT e.id
FROM tmp_rbc_eval_dupes d
JOIN rbc_evaluation e ON e.association_id = d.association_id
    AND e.evaluated_item_id = d.evaluated_item_id
    AND e.evaluated_item_owner_id = d.evaluated_item_owner_id
LEFT JOIN tmp_rbc_eval_keep k ON k.id = e.id
WHERE k.id IS NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_remove_outcomes;
CREATE TEMPORARY TABLE tmp_rbc_eval_remove_outcomes (criterionOutcomes_id BIGINT PRIMARY KEY);
INSERT INTO tmp_rbc_eval_remove_outcomes (criterionOutcomes_id)
SELECT DISTINCT eco.criterionOutcomes_id
FROM rbc_eval_criterion_outcomes eco
JOIN tmp_rbc_eval_remove r ON eco.rbc_evaluation_id = r.id;

DELETE eco FROM rbc_eval_criterion_outcomes eco
JOIN tmp_rbc_eval_remove r ON eco.rbc_evaluation_id = r.id;

DELETE co FROM rbc_criterion_outcome co
JOIN tmp_rbc_eval_remove_outcomes o ON co.id = o.criterionOutcomes_id;

DELETE e FROM rbc_evaluation e
JOIN tmp_rbc_eval_remove r ON e.id = r.id;

DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_remove_outcomes;
DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_remove;
DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_keep;
DROP TEMPORARY TABLE IF EXISTS tmp_rbc_eval_dupes;

-- Drop legacy constraints/indexes if present
SET @sql = (
    SELECT CASE
        WHEN COUNT(*) > 0 THEN 'ALTER TABLE rbc_evaluation DROP INDEX UKdn0jue890jn9p7vs6tvnsf2gf'
        ELSE 'SELECT 1'
    END
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'rbc_evaluation'
      AND index_name = 'UKdn0jue890jn9p7vs6tvnsf2gf'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT CASE
        WHEN COUNT(*) > 0 THEN 'ALTER TABLE rbc_evaluation DROP INDEX UKqsk75a24pi108jpybtt16hshv'
        ELSE 'SELECT 1'
    END
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'rbc_evaluation'
      AND index_name = 'UKqsk75a24pi108jpybtt16hshv'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE rbc_evaluation
    MODIFY evaluated_item_id VARCHAR(255) NOT NULL,
    MODIFY evaluated_item_owner_id VARCHAR(99) NOT NULL;

ALTER TABLE rbc_evaluation
    ADD CONSTRAINT UKqsk75a24pi108jpybtt16hshv UNIQUE (association_id, evaluated_item_id, evaluated_item_owner_id);
-- END RUBRICS

