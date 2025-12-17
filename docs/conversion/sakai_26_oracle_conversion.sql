
-- SAK-51949
ALTER TABLE CONTENT_RESOURCE DROP COLUMN XML;
ALTER TABLE CONTENT_RESOURCE_DELETE DROP COLUMN XML;
-- END SAK-51949

-- SAK-52193

DROP TABLE PROFILE_EXTERNAL_INTEGRATION_T;
DROP TABLE PROFILE_IMAGES_EXTERNAL_T;

-- Not allowing multiple uploaded avatars at once
DELETE FROM PROFILE_IMAGES_T WHERE IS_CURRENT = 0;

-- Drop index
DROP INDEX PROFILE_IMAGES_IS_CURRENT_I;

-- Drop column
ALTER TABLE PROFILE_IMAGES_T DROP COLUMN IS_CURRENT;

-- Using USER_UUID as the primary key
ALTER TABLE PROFILE_IMAGES_T DROP COLUMN ID;

-- Add primary key constraint
ALTER TABLE PROFILE_IMAGES_T ADD CONSTRAINT PROFILE_IMAGES_PK PRIMARY KEY (USER_UUID);

-- Drop index
DROP INDEX PROFILE_IMAGES_USER_UUID_I;

-- END SAK-52193

-- RUBRICS: clean duplicate/nullable evaluations before enforcing uniqueness
-- Normalize key values
UPDATE rbc_evaluation SET evaluated_item_id = TRIM(evaluated_item_id) WHERE evaluated_item_id IS NOT NULL;
UPDATE rbc_evaluation SET evaluated_item_owner_id = TRIM(evaluated_item_owner_id) WHERE evaluated_item_owner_id IS NOT NULL;

-- Remove unrecoverable rows with NULL keys (and their outcomes)
DELETE FROM rbc_criterion_outcome co
WHERE co.id IN (
    SELECT eco.criterionOutcomes_id
    FROM rbc_eval_criterion_outcomes eco
    JOIN rbc_evaluation e ON e.id = eco.rbc_evaluation_id
    WHERE e.evaluated_item_id IS NULL OR e.evaluated_item_owner_id IS NULL
);

DELETE FROM rbc_eval_criterion_outcomes eco
WHERE eco.rbc_evaluation_id IN (
    SELECT e.id FROM rbc_evaluation e WHERE e.evaluated_item_id IS NULL OR e.evaluated_item_owner_id IS NULL
);

DELETE FROM rbc_evaluation e
WHERE e.evaluated_item_id IS NULL OR e.evaluated_item_owner_id IS NULL;

-- Deduplicate by association/evaluated item/owner (prefer RETURNED, then latest modified/created)
DELETE FROM rbc_criterion_outcome co
WHERE co.id IN (
    SELECT eco.criterionOutcomes_id
    FROM rbc_eval_criterion_outcomes eco
    WHERE eco.rbc_evaluation_id IN (
        SELECT id FROM (
            SELECT id,
                   ROW_NUMBER() OVER (
                       PARTITION BY association_id, evaluated_item_id, evaluated_item_owner_id
                       ORDER BY CASE WHEN status = 2 THEN 2 WHEN status = 1 THEN 1 ELSE 0 END DESC,
                                NVL(modified, created),
                                id DESC
                   ) rn
            FROM rbc_evaluation
        ) dup
        WHERE dup.rn > 1
    )
);

DELETE FROM rbc_eval_criterion_outcomes eco
WHERE eco.rbc_evaluation_id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY association_id, evaluated_item_id, evaluated_item_owner_id
                   ORDER BY CASE WHEN status = 2 THEN 2 WHEN status = 1 THEN 1 ELSE 0 END DESC,
                            NVL(modified, created),
                            id DESC
               ) rn
        FROM rbc_evaluation
    ) dup
    WHERE dup.rn > 1
);

DELETE FROM rbc_evaluation e
WHERE e.id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY association_id, evaluated_item_id, evaluated_item_owner_id
                   ORDER BY CASE WHEN status = 2 THEN 2 WHEN status = 1 THEN 1 ELSE 0 END DESC,
                            NVL(modified, created),
                            id DESC
               ) rn
        FROM rbc_evaluation
    ) dup
    WHERE dup.rn > 1
);

-- Drop legacy indexes if present
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX UKdn0jue890jn9p7vs6tvnsf2gf';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -1418 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX UKqsk75a24pi108jpybtt16hshv';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -1418 THEN RAISE; END IF;
END;
/

-- Enforce NOT NULL and unique constraint
ALTER TABLE rbc_evaluation MODIFY (
    evaluated_item_id VARCHAR2(255) NOT NULL,
    evaluated_item_owner_id VARCHAR2(99) NOT NULL
);

ALTER TABLE rbc_evaluation
    ADD CONSTRAINT UKqsk75a24pi108jpybtt16hshv UNIQUE (association_id, evaluated_item_id, evaluated_item_owner_id);
-- END RUBRICS
