-- clear unchanged bundle properties
DELETE FROM SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

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

-- START SAK-52355
ALTER TABLE MC_SITE_SYNCHRONIZATION ADD DISABLED BIT DEFAULT b'0' NOT NULL;
-- END SAK-52355

-- START SAK-52541
DROP TABLE IF EXISTS OAUTH_RIGHTS;
DROP TABLE IF EXISTS OAUTH_ACCESSORS;
DROP TABLE IF EXISTS OAUTH_CONSUMERS;
-- END SAK-52541

-- START SAK-52642
CREATE TABLE mc_team_archive (
  id VARCHAR(99) NOT NULL,
  site_id VARCHAR(99) NOT NULL,
  team_id VARCHAR(255) NOT NULL,
  archive_date DATETIME(6) DEFAULT NULL,
  status INT NOT NULL DEFAULT 0,
  CONSTRAINT PK_MC_TEAM_ARCHIVE PRIMARY KEY (id)
);

ALTER TABLE mc_team_archive ADD CONSTRAINT UKmc9f2k3lrxwp7v8qntjd5hs0ya UNIQUE (site_id, team_id);
-- END SAK-52642

-- SAK-52039 Polls: migrate persistence to Spring Data JPA (MySQL)

-- The Poll primary key changes from a numeric, AUTO_INCREMENT POLL_ID to the
-- 36-char UUID that was previously stored in POLL_UUID. The Option/Vote
-- foreign keys are re-pointed to the new string key, POLL_VOTE.VOTE_POLL_ID
-- is dropped (votes now reach a poll through their option), VOTE_OPTION
-- becomes NOT NULL, and the obsolete OPTION_UUID/POLL_UUID columns are
-- removed. Several user/site/ip columns are narrowed to VARCHAR(99) to match
-- the JPA entities.

-- Run once when upgrading an existing instance. The whole migration is
-- guarded on the presence of POLL_POLL.POLL_UUID, so it is a no-op on schemas
-- that Hibernate already created in the new shape and is safe to re-run.

DROP PROCEDURE IF EXISTS polls_migrate_jpa;
DELIMITER //
CREATE PROCEDURE polls_migrate_jpa()
BEGIN
    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'POLL_POLL'
          AND COLUMN_NAME  = 'POLL_UUID'
    ) THEN

        -- Self-heal malformed/duplicate POLL_UUID values before this
        -- procedure promotes the column to the primary key. Real-world
        -- instances have been found with POLL_UUID = NULL, the literal
        -- string 'null' (residue of a historic bulk import), or values
        -- shared by more than one poll. Left unrepaired, the destructive
        -- ALTER/DELETE statements below are not transactional, so a bad
        -- value causes the final "CHANGE COLUMN ... NOT NULL" to fail and
        -- leaves the schema half-migrated (POLL_ID already dropped, new PK
        -- never added, options silently deleted as orphaned).
        UPDATE POLL_POLL SET POLL_UUID = UUID()
        WHERE POLL_UUID IS NULL
           OR LENGTH(POLL_UUID) <> 36
           OR POLL_UUID IN (
                SELECT dup.POLL_UUID FROM (
                    SELECT POLL_UUID FROM POLL_POLL
                    GROUP BY POLL_UUID HAVING COUNT(*) > 1
                ) dup
           );

        -- --- POLL_OPTION: re-point OPTION_POLL_ID from numeric poll id to poll UUID ---
        ALTER TABLE POLL_OPTION ADD COLUMN OPTION_POLL_ID_TMP VARCHAR(36);
        UPDATE POLL_OPTION o
            JOIN POLL_POLL p ON o.OPTION_POLL_ID = p.POLL_ID
            SET o.OPTION_POLL_ID_TMP = p.POLL_UUID;
        -- Drop options orphaned from any poll; they can no longer be mapped.
        DELETE FROM POLL_OPTION WHERE OPTION_POLL_ID_TMP IS NULL;
        ALTER TABLE POLL_OPTION DROP COLUMN OPTION_POLL_ID;
        ALTER TABLE POLL_OPTION CHANGE COLUMN OPTION_POLL_ID_TMP OPTION_POLL_ID VARCHAR(36) NOT NULL;
        ALTER TABLE POLL_OPTION DROP COLUMN OPTION_UUID;
        CREATE INDEX POLLTOOL_OPTION_POLLID_IDX ON POLL_OPTION (OPTION_POLL_ID);

        -- The JPA entity manages OPTION_ORDER via @OrderColumn on a bidirectional
        -- (mappedBy) Poll.options collection. Hibernate inserts a new Option row
        -- before it knows the collection's final order, then issues a follow-up
        -- UPDATE to set OPTION_ORDER once the index is known. Without a default,
        -- that first INSERT fails outright ("Field 'OPTION_ORDER' doesn't have a
        -- default value") as soon as a poll option is added through the new tool.
        ALTER TABLE POLL_OPTION MODIFY COLUMN OPTION_ORDER INT NOT NULL DEFAULT 0;

        -- --- POLL_VOTE: votes reach a poll through their option now ---
        -- VOTE_OPTION becomes NOT NULL, so drop votes that never recorded one,
        -- plus votes that still point at an OPTION_ID just deleted above as
        -- orphaned (poll with an unresolvable POLL_UUID). Without the second
        -- half of this condition those votes survive the migration as
        -- orphans referencing a non-existent option.
        DELETE FROM POLL_VOTE
        WHERE VOTE_OPTION IS NULL
           OR VOTE_OPTION NOT IN (SELECT OPTION_ID FROM POLL_OPTION);
        ALTER TABLE POLL_VOTE DROP COLUMN VOTE_POLL_ID;
        ALTER TABLE POLL_VOTE MODIFY COLUMN VOTE_OPTION BIGINT NOT NULL;
        ALTER TABLE POLL_VOTE MODIFY COLUMN USER_ID VARCHAR(99) NOT NULL;
        ALTER TABLE POLL_VOTE MODIFY COLUMN VOTE_IP VARCHAR(99) NOT NULL;
        ALTER TABLE POLL_VOTE MODIFY COLUMN VOTE_SUBMISSION_ID VARCHAR(99) NOT NULL;
        CREATE INDEX POLLTOOL_VOTE_OPTION_IDX ON POLL_VOTE (VOTE_OPTION);

        -- --- POLL_POLL: promote POLL_UUID to the primary key ---
        ALTER TABLE POLL_POLL MODIFY COLUMN POLL_ID BIGINT NOT NULL;  -- drop AUTO_INCREMENT
        ALTER TABLE POLL_POLL DROP PRIMARY KEY;
        ALTER TABLE POLL_POLL DROP COLUMN POLL_ID;
        ALTER TABLE POLL_POLL CHANGE COLUMN POLL_UUID POLL_ID VARCHAR(36) NOT NULL;
        ALTER TABLE POLL_POLL ADD PRIMARY KEY (POLL_ID);
        ALTER TABLE POLL_POLL MODIFY COLUMN POLL_OWNER VARCHAR(99) NOT NULL;
        ALTER TABLE POLL_POLL MODIFY COLUMN POLL_SITE_ID VARCHAR(99) NOT NULL;
        ALTER TABLE POLL_POLL MODIFY COLUMN POLL_DISPLAY_RESULT VARCHAR(99) NOT NULL;

    END IF;
END //
DELIMITER ;
CALL polls_migrate_jpa();
DROP PROCEDURE IF EXISTS polls_migrate_jpa;
-- END SAK-52039

-- START SAK-10208
CREATE TABLE POLL_GROUPS (
  POLL_ID varchar(36) NOT NULL,
  GROUP_ID varchar(99) NOT NULL,
  PRIMARY KEY (POLL_ID, GROUP_ID)
);

ALTER TABLE POLL_GROUPS
ADD CONSTRAINT FK_POLL_GROUPS_POLL_ID
FOREIGN KEY (POLL_ID)
REFERENCES POLL_POLL (POLL_ID);

ALTER TABLE POLL_POLL
ADD COLUMN ACCESS_TYPE varchar(10) NOT NULL DEFAULT 'SITE';

UPDATE POLL_POLL SET ACCESS_TYPE = 'SITE';
-- END SAK-10208

-- SAK-52889: migrate Conversations tags and retire Taggable.
ALTER TABLE tagservice_tag DROP FOREIGN KEY tagservice_tag_ibfk_1;
ALTER TABLE tagservice_collection MODIFY tagcollectionid VARCHAR(99) NOT NULL;
ALTER TABLE tagservice_tag MODIFY tagcollectionid VARCHAR(99) NOT NULL;
ALTER TABLE tagservice_tag ADD CONSTRAINT tagservice_tag_ibfk_1
    FOREIGN KEY (tagcollectionid) REFERENCES tagservice_collection(tagcollectionid)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

INSERT INTO tagservice_collection
    (tagcollectionid, name, description, creationdate, lastmodificationdate,
     lastsynchronizationdate, externalupdate, externalcreation, lastupdatedateinexternalsystem)
    SELECT DISTINCT t.SITE_ID, t.SITE_ID, 'Site tags', 0, 0, 0, 0, 0, 0
    FROM CONV_TAGS t WHERE NOT EXISTS
        (SELECT 1 FROM tagservice_collection c WHERE c.tagcollectionid = t.SITE_ID);

INSERT INTO tagservice_tag
    (tagid, tagcollectionid, taglabel, description, creationdate, lastmodificationdate,
     externalcreation, externalcreationDate, externalupdate, lastupdatedateinexternalsystem)
    SELECT CONCAT('conv-', TAG_ID), SITE_ID,
        LABEL, DESCRIPTION, 0, 0, 0, 0, 0, 0 FROM CONV_TAGS;

INSERT INTO tagservice_tagassociation (id, item_id, tag_id)
    SELECT UUID(), TOPIC_ID, CONCAT('conv-', TAG)
    FROM CONV_TOPIC_TAGS;

DROP TABLE CONV_TOPIC_TAGS;
DROP TABLE CONV_TAGS;
DROP TABLE TAGGABLE_LINK;

-- START SAK-52757 Jakarta migration: Hibernate 6 schema changes

-- Enumerations stored by name (@Enumerated(EnumType.STRING)) are mapped by
-- Hibernate 6 to the native MySQL/MariaDB ENUM type instead of VARCHAR. The
-- value lists, nullability and defaults below match what Hibernate 6 creates on
-- a new installation. This must stay after SAK-10208, which adds
-- POLL_POLL.ACCESS_TYPE; the MODIFY below also drops the temporary 'SITE' default.
--
-- Every stored value must be in the new list or the ALTER fails (strict sql_mode)
-- or stores '' (non strict). Values are matched case insensitively, so 'Group'
-- becomes 'GROUP'. To check beforehand, each of these must return 0, for example:
--   SELECT COUNT(*) FROM ASN_ASSIGNMENT WHERE ACCESS_TYPE NOT IN ('GROUP','SITE');
--   SELECT COUNT(*) FROM POLL_POLL WHERE ACCESS_TYPE NOT IN ('GROUP','SITE');
--   SELECT COUNT(*) FROM TASKS_ASSIGNED WHERE ASSIGNATION_TYPE NOT IN ('group','site','user');
--   SELECT COUNT(*) FROM COND_CONDITION WHERE COND_TYPE NOT IN ('COMPLETED','PARENT','ROOT','SCORE');
--   SELECT COUNT(*) FROM COND_CONDITION WHERE OPERATOR NOT IN ('AND','EQUAL_TO','GREATER_THAN','GREATER_THAN_OR_EQUAL_TO','OR','SMALLER_THAN','SMALLER_THAN_OR_EQUAL_TO');
--   SELECT COUNT(*) FROM CONV_SETTINGS WHERE DEFAULT_TOPIC_TYPE NOT IN ('DISCUSSION','QUESTION');
--   SELECT COUNT(*) FROM CONV_TOPICS WHERE TOPIC_TYPE NOT IN ('DISCUSSION','QUESTION');
--   SELECT COUNT(*) FROM CONV_TOPICS WHERE VISIBILITY NOT IN ('GROUP','INSTRUCTORS','SITE');
--   SELECT COUNT(*) FROM FILE_CONVERSION_QUEUE WHERE STATUS NOT IN ('FAILED','IN_PROGRESS','NOT_STARTED');
--   SELECT COUNT(*) FROM scheduler_trigger_events WHERE eventType NOT IN ('COMPLETE','DEBUG','ERROR','FIRED','INFO');

ALTER TABLE ASN_ASSIGNMENT MODIFY COLUMN ACCESS_TYPE ENUM('GROUP','SITE') NOT NULL;
ALTER TABLE POLL_POLL MODIFY COLUMN ACCESS_TYPE ENUM('GROUP','SITE') NOT NULL;
ALTER TABLE TASKS_ASSIGNED MODIFY COLUMN ASSIGNATION_TYPE ENUM('group','site','user') NOT NULL;
ALTER TABLE COND_CONDITION
    MODIFY COLUMN COND_TYPE ENUM('COMPLETED','PARENT','ROOT','SCORE') NOT NULL,
    MODIFY COLUMN OPERATOR ENUM('AND','EQUAL_TO','GREATER_THAN','GREATER_THAN_OR_EQUAL_TO','OR','SMALLER_THAN','SMALLER_THAN_OR_EQUAL_TO') DEFAULT NULL;
ALTER TABLE CONV_SETTINGS MODIFY COLUMN DEFAULT_TOPIC_TYPE ENUM('DISCUSSION','QUESTION') DEFAULT NULL;
ALTER TABLE CONV_TOPICS
    MODIFY COLUMN TOPIC_TYPE ENUM('DISCUSSION','QUESTION') DEFAULT NULL,
    MODIFY COLUMN VISIBILITY ENUM('GROUP','INSTRUCTORS','SITE') DEFAULT NULL;
ALTER TABLE FILE_CONVERSION_QUEUE MODIFY COLUMN STATUS ENUM('FAILED','IN_PROGRESS','NOT_STARTED') NOT NULL;
ALTER TABLE scheduler_trigger_events MODIFY COLUMN eventType ENUM('COMPLETE','DEBUG','ERROR','FIRED','INFO') NOT NULL;

-- Enumerations stored by ordinal (@Enumerated without a type, or ORDINAL) are
-- mapped by Hibernate 6 to TINYINT instead of INT. The stored values are small
-- ordinals, so they fit; an ALTER that meets a value outside -128..127 fails
-- (strict sql_mode) or clips it (non strict). To check beforehand, each of these
-- must return 0, for example:
--   SELECT COUNT(*) FROM ASN_ASSIGNMENT WHERE GRADE_TYPE NOT BETWEEN -128 AND 127 OR SUBMISSION_TYPE NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM CONV_POST_REACTIONS WHERE REACTION NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM CONV_POST_REACTION_TOTALS WHERE REACTION NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM CONV_TOPIC_REACTIONS WHERE REACTION NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM CONV_TOPIC_REACTION_TOTALS WHERE REACTION NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM GB_GRADING_EVENT_T WHERE IS_EXCLUDED NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM mc_log WHERE status NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM meeting_attendees WHERE attendee_type NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM PLUS_CONTEXT_LOG WHERE LOG_TYPE NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM PLUS_SCORE WHERE ACTIVITY_PROGRESS NOT BETWEEN -128 AND 127 OR GRADING_PROGRESS NOT BETWEEN -128 AND 127;
--   SELECT COUNT(*) FROM rbc_evaluation WHERE evaluated_item_owner_type NOT BETWEEN -128 AND 127 OR status NOT BETWEEN -128 AND 127;

-- Only columns that are still INT are converted: redefining a column also removes the CHECK
-- constraint Hibernate 6 puts on it, so a column that is already TINYINT must be left alone.
DROP PROCEDURE IF EXISTS sakai_ordinal_to_tinyint;
DELIMITER //
CREATE PROCEDURE sakai_ordinal_to_tinyint(IN tbl VARCHAR(64), IN col VARCHAR(64), IN not_null BOOLEAN)
BEGIN
    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND LOWER(TABLE_NAME) = LOWER(tbl)
          AND LOWER(COLUMN_NAME) = LOWER(col) AND DATA_TYPE = 'int'
    ) THEN
        SET @sakai_ordinal_sql = CONCAT('ALTER TABLE `', tbl, '` MODIFY COLUMN `', col, '` TINYINT ',
                                        IF(not_null, 'NOT NULL', 'DEFAULT NULL'));
        PREPARE sakai_ordinal_stmt FROM @sakai_ordinal_sql;
        EXECUTE sakai_ordinal_stmt;
        DEALLOCATE PREPARE sakai_ordinal_stmt;
    END IF;
END //
DELIMITER ;
CALL sakai_ordinal_to_tinyint('ASN_ASSIGNMENT', 'GRADE_TYPE', FALSE);
CALL sakai_ordinal_to_tinyint('ASN_ASSIGNMENT', 'SUBMISSION_TYPE', FALSE);
CALL sakai_ordinal_to_tinyint('CONV_POST_REACTIONS', 'REACTION', TRUE);
CALL sakai_ordinal_to_tinyint('CONV_POST_REACTION_TOTALS', 'REACTION', TRUE);
CALL sakai_ordinal_to_tinyint('CONV_TOPIC_REACTIONS', 'REACTION', TRUE);
CALL sakai_ordinal_to_tinyint('CONV_TOPIC_REACTION_TOTALS', 'REACTION', TRUE);
CALL sakai_ordinal_to_tinyint('GB_GRADING_EVENT_T', 'IS_EXCLUDED', FALSE);
CALL sakai_ordinal_to_tinyint('mc_log', 'status', FALSE);
CALL sakai_ordinal_to_tinyint('meeting_attendees', 'attendee_type', FALSE);
CALL sakai_ordinal_to_tinyint('PLUS_CONTEXT_LOG', 'LOG_TYPE', FALSE);
CALL sakai_ordinal_to_tinyint('PLUS_SCORE', 'ACTIVITY_PROGRESS', FALSE);
CALL sakai_ordinal_to_tinyint('PLUS_SCORE', 'GRADING_PROGRESS', FALSE);
CALL sakai_ordinal_to_tinyint('rbc_evaluation', 'evaluated_item_owner_type', FALSE);
CALL sakai_ordinal_to_tinyint('rbc_evaluation', 'status', FALSE);
DROP PROCEDURE IF EXISTS sakai_ordinal_to_tinyint;

-- OPTIONAL, left commented out: range checks on the ordinal enumeration columns.
-- Hibernate 6 also creates a CHECK constraint for each of these columns on a new
-- installation, restricting the value to a valid ordinal of the Java enum (the
-- number of constants minus one). Hibernate 5 did not. The application never
-- stores an invalid ordinal, so skipping these changes nothing functionally; it
-- only means the database does not reject a bad value inserted by hand.
-- Think twice before adding them: the check lists the enum size at the time it
-- is created, so whenever a constant is added to one of these Java enums the
-- constraint has to be widened (DROP CONSTRAINT then ADD CONSTRAINT) or inserts
-- with the new ordinal are rejected. Adding a constraint also validates every
-- existing row, so the statement fails if a column holds an out of range value.
-- Constraint names and ranges match what Hibernate 6 generates.
--
-- ALTER TABLE ASN_ASSIGNMENT
--     ADD CONSTRAINT GRADE_TYPE CHECK (GRADE_TYPE BETWEEN 0 AND 5),
--     ADD CONSTRAINT SUBMISSION_TYPE CHECK (SUBMISSION_TYPE BETWEEN 0 AND 7);
-- ALTER TABLE CONV_POST_REACTIONS ADD CONSTRAINT REACTION CHECK (REACTION BETWEEN 0 AND 3);
-- ALTER TABLE CONV_POST_REACTION_TOTALS ADD CONSTRAINT REACTION CHECK (REACTION BETWEEN 0 AND 3);
-- ALTER TABLE CONV_TOPIC_REACTIONS ADD CONSTRAINT REACTION CHECK (REACTION BETWEEN 0 AND 3);
-- ALTER TABLE CONV_TOPIC_REACTION_TOTALS ADD CONSTRAINT REACTION CHECK (REACTION BETWEEN 0 AND 3);
-- ALTER TABLE GB_GRADING_EVENT_T ADD CONSTRAINT IS_EXCLUDED CHECK (IS_EXCLUDED BETWEEN 0 AND 2);
-- ALTER TABLE mc_log ADD CONSTRAINT status CHECK (status BETWEEN 0 AND 1);
-- ALTER TABLE meeting_attendees ADD CONSTRAINT attendee_type CHECK (attendee_type BETWEEN 0 AND 2);
-- ALTER TABLE PLUS_CONTEXT_LOG ADD CONSTRAINT LOG_TYPE CHECK (LOG_TYPE BETWEEN 0 AND 10);
-- ALTER TABLE PLUS_SCORE
--     ADD CONSTRAINT ACTIVITY_PROGRESS CHECK (ACTIVITY_PROGRESS BETWEEN 0 AND 4),
--     ADD CONSTRAINT GRADING_PROGRESS CHECK (GRADING_PROGRESS BETWEEN 0 AND 3);
-- ALTER TABLE rbc_evaluation
--     ADD CONSTRAINT evaluated_item_owner_type CHECK (evaluated_item_owner_type BETWEEN 0 AND 1),
--     ADD CONSTRAINT status CHECK (status BETWEEN 0 AND 2);

-- Binary properties without an explicit length (byte[] certificates, and the
-- String[] vocabulary lists, which are stored as Java serialized bytes) are
-- mapped by Hibernate 6 to VARBINARY(255) instead of TINYBLOB. Both hold at most
-- 255 bytes and the stored bytes are unchanged, so no data is affected.
ALTER TABLE SAKAI_PERSON_T
    MODIFY COLUMN USER_CERTIFICATE VARBINARY(255) DEFAULT NULL,
    MODIFY COLUMN USER_PKCS12 VARBINARY(255) DEFAULT NULL,
    MODIFY COLUMN USER_SMIME_CERTIFICATE VARBINARY(255) DEFAULT NULL;
ALTER TABLE SCORM_TYPE_VALIDATOR_T
    MODIFY COLUMN VOCAB_LIST VARBINARY(255) DEFAULT NULL,
    MODIFY COLUMN RESULT_VOCAB_LIST VARBINARY(255) DEFAULT NULL;

-- Date and time columns without an explicit precision get fractional seconds
-- (precision 6) in Hibernate 6. The Meetings dates used to force datetime(0) with
-- a columnDefinition, which was removed so they match the other Instant columns.
-- Existing values are kept and just gain a zero fraction.
ALTER TABLE meetings
    MODIFY COLUMN meeting_start_date DATETIME(6) DEFAULT NULL,
    MODIFY COLUMN meeting_end_date DATETIME(6) DEFAULT NULL;
ALTER TABLE CM_MEETING_T
    MODIFY COLUMN START_TIME TIME(6) DEFAULT NULL,
    MODIFY COLUMN FINISH_TIME TIME(6) DEFAULT NULL;

-- Hibernate 6 sorts the properties of an hbm.xml composite-id alphabetically, so the
-- primary keys of the question pool tables now start with ITEMID / ACCESSTYPEID
-- instead of QUESTIONPOOLID. Because QUESTIONPOOLID no longer leads the key, the
-- foreign key to SAM_QUESTIONPOOL_T needs its own index; Hibernate 6 creates it
-- under the name of the foreign key constraint. The columns are also moved into the
-- order the mapping now lists them (alphabetical), which new installations get, so the
-- columns of upgraded and new databases line up. The rebuild is skipped when the
-- primary key already starts with ITEMID / ACCESSTYPEID, so it is safe to re-run.
SET @samigo_pk_item = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'SAM_QUESTIONPOOLITEM_T'
        AND INDEX_NAME = 'PRIMARY' AND SEQ_IN_INDEX = 1 AND COLUMN_NAME = 'QUESTIONPOOLID') > 0,
    'ALTER TABLE SAM_QUESTIONPOOLITEM_T MODIFY COLUMN ITEMID BIGINT NOT NULL FIRST, DROP PRIMARY KEY, ADD PRIMARY KEY (ITEMID, QUESTIONPOOLID), ADD INDEX FK64b9lf0ufx0bc2xaa12d95mox (QUESTIONPOOLID)',
    'DO 0');
PREPARE samigo_pk_item_stmt FROM @samigo_pk_item;
EXECUTE samigo_pk_item_stmt;
DEALLOCATE PREPARE samigo_pk_item_stmt;

SET @samigo_pk_access = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'SAM_QUESTIONPOOLACCESS_T'
        AND INDEX_NAME = 'PRIMARY' AND SEQ_IN_INDEX = 1 AND COLUMN_NAME = 'QUESTIONPOOLID') > 0,
    'ALTER TABLE SAM_QUESTIONPOOLACCESS_T MODIFY COLUMN ACCESSTYPEID BIGINT NOT NULL FIRST, MODIFY COLUMN AGENTID VARCHAR(255) NOT NULL AFTER ACCESSTYPEID, DROP PRIMARY KEY, ADD PRIMARY KEY (ACCESSTYPEID, AGENTID, QUESTIONPOOLID), ADD INDEX FK6s27ftmf0vn279b7bydsnvwjd (QUESTIONPOOLID)',
    'DO 0');
PREPARE samigo_pk_access_stmt FROM @samigo_pk_access;
EXECUTE samigo_pk_access_stmt;
DEALLOCATE PREPARE samigo_pk_access_stmt;

-- LineItem.link is a @OneToOne, so Hibernate 6 enforces it with a unique constraint on
-- PLUS_LINEITEM.LINK_GUID (Hibernate 5 only created a plain index). The unique index also
-- serves the foreign key, which makes the old non unique index redundant. LINK_GUID is not
-- populated by Plus today (NULL values never conflict), but if an instance did store the same
-- link on several line items the constraint cannot be added: find them first with
--   SELECT LINK_GUID, COUNT(*) FROM PLUS_LINEITEM WHERE LINK_GUID IS NOT NULL GROUP BY LINK_GUID HAVING COUNT(*) > 1;
-- The constraint is added first so the foreign key always keeps an index. Safe to re-run.
SET @plus_lineitem_uk = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'PLUS_LINEITEM'
        AND INDEX_NAME = 'UKnbat6iqn2gcnhvu9p49718x8u') = 0,
    'ALTER TABLE PLUS_LINEITEM ADD CONSTRAINT UKnbat6iqn2gcnhvu9p49718x8u UNIQUE (LINK_GUID)',
    'DO 0');
PREPARE plus_lineitem_uk_stmt FROM @plus_lineitem_uk;
EXECUTE plus_lineitem_uk_stmt;
DEALLOCATE PREPARE plus_lineitem_uk_stmt;

SET @plus_lineitem_fk_index = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'PLUS_LINEITEM'
        AND INDEX_NAME = 'FKq58ue8aq8212glh24mmb4u34w') > 0,
    'ALTER TABLE PLUS_LINEITEM DROP INDEX FKq58ue8aq8212glh24mmb4u34w',
    'DO 0');
PREPARE plus_lineitem_fk_index_stmt FROM @plus_lineitem_fk_index;
EXECUTE plus_lineitem_fk_index_stmt;
DEALLOCATE PREPARE plus_lineitem_fk_index_stmt;

-- SCORM_CONTENT_PACKAGE_T.MANIFEST_ID holds the numeric id of the package manifest, but the
-- property had no type and a Serializable Java type, so Hibernate stored the id as a Java
-- serialized java.lang.Long in a binary column. The mapping now declares it as a long, which
-- gives a BIGINT column, so existing values are converted here without any Java code.
-- A serialized Long is always 82 bytes: a fixed 74 byte header followed by the 8 byte value
-- (big endian). The conversion aborts without changing anything when a row is anything else.
-- The new mapping must not run against an unconverted column. Safe to re-run: it does nothing
-- once the column is a BIGINT. Take a backup first, the old column is dropped.
DROP PROCEDURE IF EXISTS scorm_manifest_id_to_bigint;
DELIMITER //
CREATE PROCEDURE scorm_manifest_id_to_bigint()
BEGIN
    DECLARE bad INT DEFAULT 0;
    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'SCORM_CONTENT_PACKAGE_T'
          AND COLUMN_NAME = 'MANIFEST_ID' AND DATA_TYPE IN ('tinyblob', 'blob', 'varbinary')
    ) THEN
        SELECT COUNT(*) INTO bad FROM SCORM_CONTENT_PACKAGE_T
        WHERE MANIFEST_ID IS NOT NULL
          AND NOT (LENGTH(MANIFEST_ID) = 82
               AND HEX(LEFT(MANIFEST_ID, 74)) = 'ACED00057372000E6A6176612E6C616E672E4C6F6E673B8BE490CC8F23DF0200014A000576616C7565787200106A6176612E6C616E672E4E756D62657286AC951D0B94E08B0200007870');
        IF bad > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SCORM_CONTENT_PACKAGE_T.MANIFEST_ID holds values that are not a serialized java.lang.Long';
        END IF;
        ALTER TABLE SCORM_CONTENT_PACKAGE_T ADD COLUMN MANIFEST_ID_TMP BIGINT NULL AFTER MANIFEST_ID;
        UPDATE SCORM_CONTENT_PACKAGE_T
            SET MANIFEST_ID_TMP = CAST(CONV(HEX(SUBSTRING(MANIFEST_ID, 75, 8)), 16, 10) AS UNSIGNED)
            WHERE MANIFEST_ID IS NOT NULL;
        ALTER TABLE SCORM_CONTENT_PACKAGE_T DROP COLUMN MANIFEST_ID, CHANGE COLUMN MANIFEST_ID_TMP MANIFEST_ID BIGINT NULL;
    END IF;
END //
DELIMITER ;
CALL scorm_manifest_id_to_bigint();
DROP PROCEDURE IF EXISTS scorm_manifest_id_to_bigint;

-- Hibernate 6 names generated unique keys UK<hash> where Hibernate 5 named them UK_<hash>, for the
-- same table and columns. Hibernate 6 adds the unique keys it does not find by name, so without
-- this an upgraded database ends up with a second, identical unique index on each of these tables.
-- Rename the old keys (or drop the old key when the new one already exists, for example when
-- Sakai was started before this script was run). Tables or keys that do not exist are skipped.
DROP PROCEDURE IF EXISTS sakai_rename_unique_index;
DELIMITER //
CREATE PROCEDURE sakai_rename_unique_index(IN tbl VARCHAR(64), IN old_name VARCHAR(64), IN new_name VARCHAR(64))
BEGIN
    DECLARE has_old INT DEFAULT 0;
    DECLARE has_new INT DEFAULT 0;
    SELECT COUNT(*) INTO has_old FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND LOWER(TABLE_NAME) = LOWER(tbl) AND LOWER(INDEX_NAME) = LOWER(old_name);
    SELECT COUNT(*) INTO has_new FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND LOWER(TABLE_NAME) = LOWER(tbl) AND LOWER(INDEX_NAME) = LOWER(new_name);
    IF has_old > 0 AND has_new = 0 THEN
        SET @sakai_unique_index_sql = CONCAT('ALTER TABLE `', tbl, '` RENAME INDEX `', old_name, '` TO `', new_name, '`');
    ELSEIF has_old > 0 AND has_new > 0 THEN
        SET @sakai_unique_index_sql = CONCAT('ALTER TABLE `', tbl, '` DROP INDEX `', old_name, '`');
    ELSE
        SET @sakai_unique_index_sql = NULL;
    END IF;
    IF @sakai_unique_index_sql IS NOT NULL THEN
        PREPARE sakai_unique_index_stmt FROM @sakai_unique_index_sql;
        EXECUTE sakai_unique_index_stmt;
        DEALLOCATE PREPARE sakai_unique_index_stmt;
    END IF;
END //
DELIMITER ;
CALL sakai_rename_unique_index('CMN_TYPE_T', 'UK_2p0cjpjwgndvs41lhrpof8qqu', 'UK2p0cjpjwgndvs41lhrpof8qqu');
CALL sakai_rename_unique_index('CM_ACADEMIC_SESSION_T', 'UK_8tedjqij6wdhbusfq1s8u73qv', 'UK8tedjqij6wdhbusfq1s8u73qv');
CALL sakai_rename_unique_index('CM_ENROLLMENT_SET_T', 'UK_b5uvnlltlu7do85daxg1y8eaj', 'UKb5uvnlltlu7do85daxg1y8eaj');
CALL sakai_rename_unique_index('CONTENTREVIEW_ITEM', 'UK_8dngr1v68kkv4u11c1nvrjj1l', 'UK8dngr1v68kkv4u11c1nvrjj1l');
CALL sakai_rename_unique_index('FILE_CONVERSION_QUEUE', 'UK_j0t1gd58buw5b0cwxayincy09', 'UKj0t1gd58buw5b0cwxayincy09');
CALL sakai_rename_unique_index('GB_GRADEBOOK_T', 'UK_ru3o66mhmaf4no3xt2tv4n8e5', 'UKru3o66mhmaf4no3xt2tv4n8e5');
CALL sakai_rename_unique_index('GB_GRADING_SCALE_T', 'UK_rtwe2scsusdlt5ky2h0rnx08v', 'UKrtwe2scsusdlt5ky2h0rnx08v');
CALL sakai_rename_unique_index('GB_PROPERTY_T', 'UK_kvs819b0osay1jus54sly941w', 'UKkvs819b0osay1jus54sly941w');
CALL sakai_rename_unique_index('GOOGLEDRIVE_USER', 'UK_els5d6yyteuqadxjmnge1qpg4', 'UKels5d6yyteuqadxjmnge1qpg4');
CALL sakai_rename_unique_index('lesson_builder_properties', 'UK_ou4hrxide8o0v88o2efdakrqx', 'UKou4hrxide8o0v88o2efdakrqx');
CALL sakai_rename_unique_index('MFR_MEMBERSHIP_ITEM_T', 'UK_hlhcuxr02f24pibu9vhwoi7as', 'UKhlhcuxr02f24pibu9vhwoi7as');
CALL sakai_rename_unique_index('PUSH_SUBSCRIPTIONS', 'UK_bmh2ettxdtysgemuaw0t8do1r', 'UKbmh2ettxdtysgemuaw0t8do1r');
CALL sakai_rename_unique_index('rbc_eval_criterion_outcomes', 'UK_f8xy8709bllewhbve9ias2vk4', 'UKf8xy8709bllewhbve9ias2vk4');
CALL sakai_rename_unique_index('rwikiobject', 'UK_6urtfjh5iprbjqrkv91yf66m9', 'UK6urtfjh5iprbjqrkv91yf66m9');
CALL sakai_rename_unique_index('rwikiproperties', 'UK_b07q7wfpx20hapev9ol9e35jv', 'UKb07q7wfpx20hapev9ol9e35jv');
CALL sakai_rename_unique_index('SAKAI_PERSON_T', 'UK_ludffuvbtj85siwglqklnxyo0', 'UKludffuvbtj85siwglqklnxyo0');
CALL sakai_rename_unique_index('tagservice_collection', 'UK_nlytxq8ru4t20bmwn3q6pdno8', 'UKnlytxq8ru4t20bmwn3q6pdno8');
CALL sakai_rename_unique_index('tagservice_collection', 'UK_pje21f9w8lpgap08wcphe7swk', 'UKpje21f9w8lpgap08wcphe7swk');
DROP PROCEDURE IF EXISTS sakai_rename_unique_index;

-- END SAK-52757
