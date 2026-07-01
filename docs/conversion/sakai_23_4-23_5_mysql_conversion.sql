
-- START SAK-51950
CREATE INDEX CALENDAR_EVENT_CID_RSTART_REND_ESTART ON CALENDAR_EVENT(CALENDAR_ID, RANGE_START, RANGE_END, EVENT_START);
-- END SAK-51950

-- START SAK-49313
ALTER TABLE SAM_PUBLISHEDASSESSMENT_T MODIFY COMMENTS VARCHAR(4000) NULL;
-- END SAK-49313

-- START SAK-48981 Permission Level Data Cleanup (MySQL)

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
-- END SAK-48981
