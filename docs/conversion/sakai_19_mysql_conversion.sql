-- SAK-38427

ALTER TABLE MFR_TOPIC_T ADD COLUMN ALLOW_EMAIL_NOTIFICATIONS BIT(1) NOT NULL DEFAULT 1;
ALTER TABLE MFR_TOPIC_T ADD COLUMN INCLUDE_CONTENTS_IN_EMAILS BIT(1) NOT NULL DEFAULT 1;

-- END SAK-38427

-- SAK-33969
ALTER TABLE MFR_OPEN_FORUM_T ADD RESTRICT_PERMS_FOR_GROUPS BIT(1) DEFAULT FALSE;
ALTER TABLE MFR_TOPIC_T ADD RESTRICT_PERMS_FOR_GROUPS BIT(1) DEFAULT FALSE;
-- SAK-33969

-- SAK-39967

CREATE INDEX contentreview_provider_id_idx on CONTENTREVIEW_ITEM (providerId, externalId);

-- End SAK-39967

-- SAK-40721
ALTER TABLE BULLHORN_ALERTS ADD COLUMN DEFERRED BIT(1) NOT NULL;
-- END SAK-40721

-- SAK-41017

UPDATE SAKAI_SITE_PAGE SET layout = '0' WHERE page_id = '!error-100';
UPDATE SAKAI_SITE_PAGE SET layout = '0' WHERE page_id = '!urlError-100';

-- End of SAK-41017

-- BEGIN SAK-41172
DROP TABLE IF EXISTS SAKAI_GROUP_LOCK;
CREATE TABLE `SAKAI_GROUP_LOCK` (`GROUP_ID` VARCHAR(99) NOT NULL,`ITEM_ID` VARCHAR(200) NOT NULL, `LOCK_MODE` VARCHAR(32) NOT NULL, PRIMARY KEY (`GROUP_ID`, `ITEM_ID`, `LOCK_MODE`));
-- END SAK-41172

-- BEGIN SAK-41219
DELETE FROM SAKAI_GROUP_LOCK;
DELIMITER $$
CREATE FUNCTION SPLITASSIGNMENTREFERENCES(ASSIGNMENTREFERENCES VARCHAR(400), POS INTEGER) RETURNS VARCHAR(400)
BEGIN
    DECLARE OUTPUT VARCHAR(400);
    DECLARE DELIM VARCHAR(3);
    SET DELIM = '#:#';
    SET OUTPUT = REPLACE(SUBSTRING(SUBSTRING_INDEX(ASSIGNMENTREFERENCES, DELIM, POS),
                                   LENGTH(SUBSTRING_INDEX(ASSIGNMENTREFERENCES, DELIM, POS - 1)) + 1)
                                   , DELIM
                                   , '');
    IF OUTPUT = '' THEN SET OUTPUT = NULL; END IF;
    RETURN OUTPUT;
END $$

CREATE PROCEDURE BUILDGROUPLOCKTABLE()
BEGIN
    DECLARE I INTEGER;
    SET I = 1;
    REPEAT
        INSERT INTO SAKAI_GROUP_LOCK (GROUP_ID, ITEM_ID, LOCK_MODE)
            SELECT GROUP_ID, SPLITASSIGNMENTREFERENCES(VALUE, I), 'MODIFY'
                FROM SAKAI_SITE_GROUP_PROPERTY
                WHERE SPLITASSIGNMENTREFERENCES(VALUE, I) IS NOT NULL AND NAME='group_prop_locked_by';
        SET I = I + 1;
        UNTIL ROW_COUNT() = 0
    END REPEAT;
END $$

DELIMITER ;

CALL BUILDGROUPLOCKTABLE();
DROP FUNCTION IF EXISTS SPLITASSIGNMENTREFERENCES;
DROP PROCEDURE IF EXISTS BUILDGROUPLOCKTABLE;

/*Execute at your own risk, cleans up the rows of sakai_site_group_property after moving them to the new table.*/
/*DELETE FROM SAKAI_SITE_GROUP_PROPERTY WHERE NAME='group_prop_locked_by';*/
-- END SAK-41219
