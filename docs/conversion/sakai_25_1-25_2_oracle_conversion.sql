
-- START SAK-51950
CREATE INDEX CAL_EVENT_CID_RST_REND_EST
  ON CALENDAR_EVENT (CALENDAR_ID, RANGE_START, RANGE_END, EVENT_START);
-- END SAK-51950

-- START SAK-49313
ALTER TABLE SAM_PUBLISHEDASSESSMENT_T MODIFY (COMMENTS VARCHAR2(4000));
-- END SAK-49313

-- START SAK-49440
-- Oracle RENAME COLUMN preserves the existing values, type and NOT NULL constraint.
ALTER TABLE mfr_permission_level_t RENAME COLUMN MARK_AS_READ TO MARK_AS_NOT_READ;
-- END SAK-49440

-- START SAK-51938
ALTER TABLE lesson_builder_pages ADD hiddenFromNavigation NUMBER(1) DEFAULT 0;
-- END SAK-51938

-- START SAK-52495
ALTER TABLE GB_GRADABLE_OBJECT_T ADD LINEITEM_METADATA CLOB;
-- END SAK-52495

-- START SAK-52559
-- deployment_id changes from INTEGER to VARCHAR2(255 CHAR). Oracle cannot change the
-- datatype of a populated column in place, so copy the data through a temporary column.
-- lti13_lms_deployment_id is replaced by the per-site lti_tool_site.deployment_group column.
ALTER TABLE LTI_TOOLS ADD DEPLOYMENT_ID_TMP VARCHAR2(255 CHAR);
UPDATE LTI_TOOLS SET DEPLOYMENT_ID_TMP = TO_CHAR(DEPLOYMENT_ID) WHERE DEPLOYMENT_ID IS NOT NULL;
ALTER TABLE LTI_TOOLS DROP COLUMN DEPLOYMENT_ID;
ALTER TABLE LTI_TOOLS RENAME COLUMN DEPLOYMENT_ID_TMP TO DEPLOYMENT_ID;
ALTER TABLE LTI_TOOLS DROP COLUMN LTI13_LMS_DEPLOYMENT_ID;
ALTER TABLE LTI_TOOL_SITE ADD DEPLOYMENT_GROUP VARCHAR2(128 CHAR);
COMMIT;
-- END SAK-52559

-- START SAK-52583
ALTER TABLE LTI_TOOLS ADD ALLOWGRADEBOOKREADONLY NUMBER(1) DEFAULT 0;
-- END SAK-52583

-- START SAK-48981 Permission Level Data Cleanup (Oracle)

-- NULL out PERMISSION_LEVEL for standard-named items
-- this is aggrssive and is best run after a semester ends and before the next starts
-- which is why it is commented out, organizations should decide when best to run it

-- UPDATE MFR_MEMBERSHIP_ITEM_T
-- SET    PERMISSION_LEVEL = NULL
-- WHERE  PERMISSION_LEVEL IS NOT NULL
--   AND  PERMISSION_LEVEL_NAME NOT IN ('Custom');

-- Delete orphaned non-standard permission level rows
-- Must be run after cleaning standard-named items and stale FKs have already been nulled.
-- Standard-named rows (the six global defaults) are intentionally
-- left in place even if unreferenced.

DELETE FROM MFR_PERMISSION_LEVEL_T
WHERE  ID NOT IN (
           SELECT PERMISSION_LEVEL
           FROM   MFR_MEMBERSHIP_ITEM_T
           WHERE  PERMISSION_LEVEL IS NOT NULL
       )
  AND  NAME NOT IN (
           'Owner', 'Author', 'Nonediting Author',
           'Contributor', 'Reviewer', 'None'
       );

COMMIT;
-- END SAK-48981
