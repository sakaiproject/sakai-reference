-- START SAK-51950
CREATE INDEX CALENDAR_EVENT_CID_RSTART_REND_ESTART
  ON CALENDAR_EVENT (CALENDAR_ID, RANGE_START, RANGE_END, EVENT_START);
-- END SAK-51950

-- START SAK-49313
ALTER TABLE SAM_PUBLISHEDASSESSMENT_T MODIFY COMMENTS VARCHAR(4000) NULL;
-- END SAK-49313

-- START SAK-49440
-- Rename (not drop/add) so existing values are preserved; bit(1) NOT NULL.
ALTER TABLE mfr_permission_level_t CHANGE COLUMN MARK_AS_READ MARK_AS_NOT_READ bit(1) NOT NULL;
-- END SAK-49440

-- START SAK-51938
ALTER TABLE lesson_builder_pages ADD hiddenFromNavigation BIT DEFAULT 0;
-- END SAK-51938

-- START SAK-52495
ALTER TABLE GB_GRADABLE_OBJECT_T ADD LINEITEM_METADATA LONGTEXT NULL;
-- END SAK-52495

-- START SAK-52559
-- deployment_id changes from INTEGER to VARCHAR(255); lti13_lms_deployment_id is
-- replaced by the per-site lti_tool_site.deployment_group column.
ALTER TABLE lti_tools MODIFY deployment_id VARCHAR(255) DEFAULT NULL;
ALTER TABLE lti_tools DROP COLUMN lti13_lms_deployment_id;
ALTER TABLE lti_tool_site ADD deployment_group VARCHAR(128) DEFAULT NULL;
-- END SAK-52559

-- START SAK-52583
ALTER TABLE lti_tools ADD allowgradebookreadonly TINYINT DEFAULT 0;
-- END SAK-52583

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

-- SAK-51713 --
-- Permission added might not be present
INSERT IGNORE INTO SAKAI_REALM_FUNCTION (FUNCTION_NAME) VALUES ('assessment.all.groups');
-- Add this for every role able to create and manage conditions on a site, you'll need to add the tool too
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'assessment.all.groups'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'assessment.all.groups'));
-- Add this to populate existing sites with the permission
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));
INSERT INTO PERMISSIONS_SRC_TEMP values ('maintain','assessment.all.groups');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Instructor','assessment.all.groups');

CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
  SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
    from PERMISSIONS_SRC_TEMP TMPSRC
    JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
    JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
  SELECT SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
  FROM
    (SELECT DISTINCT SRRF.REALM_KEY, SRRF.ROLE_KEY FROM SAKAI_REALM_RL_FN SRRF) SRRFD
    JOIN PERMISSIONS_TEMP TMP ON (SRRFD.ROLE_KEY = TMP.ROLE_KEY)
    JOIN SAKAI_REALM SR ON (SRRFD.REALM_KEY = SR.REALM_KEY)
    WHERE SR.REALM_ID != '!site.helper' AND SR.REALM_ID NOT LIKE '!user.template%'
    AND NOT EXISTS (
        SELECT 1
            FROM SAKAI_REALM_RL_FN SRRFI
            WHERE SRRFI.REALM_KEY=SRRFD.REALM_KEY AND SRRFI.ROLE_KEY=SRRFD.ROLE_KEY AND SRRFI.FUNCTION_KEY=TMP.FUNCTION_KEY
    );

DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_SRC_TEMP;
-- END SAK-51713 --

