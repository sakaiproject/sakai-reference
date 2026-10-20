
-- START SAK-51950
CREATE INDEX CAL_EVENT_CID_RST_REND_EST ON CALENDAR_EVENT(CALENDAR_ID, RANGE_START, RANGE_END, EVENT_START);
-- END SAK-51950

-- START SAK-49313
ALTER TABLE SAM_PUBLISHEDASSESSMENT_T MODIFY (COMMENTS VARCHAR2(4000));
-- END SAK-49313

-- START SAK-48981 Permission Level Data Cleanup (Oracle)

-- Clear stored levels only when all 15 flags match the corresponding global default.
UPDATE MFR_MEMBERSHIP_ITEM_T item
SET PERMISSION_LEVEL = NULL
WHERE item.PERMISSION_LEVEL_NAME IN (
          'Owner', 'Author', 'Nonediting Author',
          'Contributor', 'Reviewer', 'None'
      )
  AND EXISTS (
      SELECT 1
      FROM MFR_PERMISSION_LEVEL_T stored_level
      JOIN CMN_TYPE_T default_type
        ON default_type.AUTHORITY = 'org.sakaiproject.component.app.messageforums'
       AND default_type.DOMAIN = 'sakai_messageforums'
       AND default_type.KEYWORD = CONCAT(item.PERMISSION_LEVEL_NAME, ' Permission Level')
      JOIN MFR_PERMISSION_LEVEL_T default_level ON default_level.TYPE_UUID = default_type.UUID
      WHERE stored_level.ID = item.PERMISSION_LEVEL
        AND stored_level.CHANGE_SETTINGS = default_level.CHANGE_SETTINGS
        AND stored_level.DELETE_ANY = default_level.DELETE_ANY
        AND stored_level.DELETE_OWN = default_level.DELETE_OWN
        AND stored_level.MARK_AS_READ = default_level.MARK_AS_READ
        AND stored_level.MOVE_POSTING = default_level.MOVE_POSTING
        AND stored_level.NEW_FORUM = default_level.NEW_FORUM
        AND stored_level.NEW_RESPONSE = default_level.NEW_RESPONSE
        AND stored_level.NEW_RESPONSE_TO_RESPONSE = default_level.NEW_RESPONSE_TO_RESPONSE
        AND stored_level.NEW_TOPIC = default_level.NEW_TOPIC
        AND stored_level.POST_TO_GRADEBOOK = default_level.POST_TO_GRADEBOOK
        AND stored_level.X_READ = default_level.X_READ
        AND stored_level.REVISE_ANY = default_level.REVISE_ANY
        AND stored_level.REVISE_OWN = default_level.REVISE_OWN
        AND stored_level.MODERATE_POSTINGS = default_level.MODERATE_POSTINGS
        AND stored_level.IDENTIFY_ANON_AUTHORS = default_level.IDENTIFY_ANON_AUTHORS
  );

-- Delete unreferenced non-standard-named levels; keep all standard-named rows.

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
