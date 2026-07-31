-- clear unchanged bundle properties
DELETE FROM SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

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

-- SAK-49440, SAK-52495 and SAK-52583 are backported to 25.2; see
-- sakai_25_1-25_2_oracle_conversion.sql (removed here so they are not run
-- twice on a 25.2 -> 26 upgrade).

-- START SAK-52355
ALTER TABLE MC_SITE_SYNCHRONIZATION ADD DISABLED NUMBER(1,0) DEFAULT 0 NOT NULL;
-- END SAK-52355

-- START SAK-52541
DROP TABLE OAUTH_RIGHTS CASCADE CONSTRAINTS;
DROP TABLE OAUTH_ACCESSORS CASCADE CONSTRAINTS;
DROP TABLE OAUTH_CONSUMERS CASCADE CONSTRAINTS;
-- END SAK-52541

-- START SAK-52642
CREATE TABLE mc_team_archive (
  id VARCHAR2(99) NOT NULL,
  site_id VARCHAR2(99) NOT NULL,
  team_id VARCHAR2(255) NOT NULL,
  archive_date TIMESTAMP(6) DEFAULT NULL,
  status NUMBER(1,0) DEFAULT 0 NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT UKmc_ta UNIQUE (site_id, team_id)
);
-- END SAK-52642

-- SAK-52039 Polls: migrate persistence to Spring Data JPA (Oracle)

-- The Poll primary key changes from a numeric POLL_ID (fed by the
-- POLL_POLL_ID_SEQ sequence) to the 36-char UUID that was previously stored
-- in POLL_UUID. The Option/Vote foreign keys are re-pointed to the new string
-- key, POLL_VOTE.VOTE_POLL_ID is dropped (votes now reach a poll through their
-- option), VOTE_OPTION becomes NOT NULL, and the obsolete OPTION_UUID/POLL_UUID
-- columns are removed. Several user/site/ip columns are narrowed to
-- VARCHAR2(99) to match the JPA entities.

-- Run once when upgrading an existing instance. The whole migration is guarded
-- on the presence of POLL_POLL.POLL_UUID, so it is a no-op on schemas that
-- Hibernate already created in the new shape and is safe to re-run.
-- =====================================================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM   USER_TAB_COLUMNS
    WHERE  TABLE_NAME  = 'POLL_POLL'
      AND  COLUMN_NAME = 'POLL_UUID';

    IF v_count > 0 THEN

        -- Self-heal malformed/duplicate POLL_UUID values before this
        -- block promotes the column to the primary key. Real-world
        -- instances have been found with POLL_UUID = NULL, the literal
        -- string 'null' (residue of a historic bulk import), or values
        -- shared by more than one poll. Left unrepaired, the destructive
        -- ALTER/DELETE statements below are not transactional, so a bad
        -- value causes a later MODIFY/ADD PRIMARY KEY to fail and leaves
        -- the schema half-migrated (POLL_ID already dropped, new PK never
        -- added, options silently deleted as orphaned).
        -- SYS_GUID() is formatted to a 36-char hyphenated UUID to match
        -- the Java/MySQL UUID() shape expected by the rest of this migration.
        EXECUTE IMMEDIATE q'[
            UPDATE POLL_POLL
            SET POLL_UUID = LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()),
                    '([A-F0-9]{8})([A-F0-9]{4})([A-F0-9]{4})([A-F0-9]{4})([A-F0-9]{12})',
                    '\1-\2-\3-\4-\5'))
            WHERE POLL_UUID IS NULL
               OR LENGTH(POLL_UUID) <> 36
               OR POLL_UUID IN (
                    SELECT dup.POLL_UUID FROM (
                        SELECT POLL_UUID FROM POLL_POLL
                        GROUP BY POLL_UUID HAVING COUNT(*) > 1
                    ) dup
               )
        ]';

        -- --- POLL_OPTION: re-point OPTION_POLL_ID from numeric poll id to poll UUID ---
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_OPTION ADD OPTION_POLL_ID_TMP VARCHAR2(36)';
        EXECUTE IMMEDIATE 'UPDATE POLL_OPTION o SET o.OPTION_POLL_ID_TMP = ' ||
                          '(SELECT p.POLL_UUID FROM POLL_POLL p WHERE p.POLL_ID = o.OPTION_POLL_ID)';
        -- Drop options orphaned from any poll; they can no longer be mapped.
        EXECUTE IMMEDIATE 'DELETE FROM POLL_OPTION WHERE OPTION_POLL_ID_TMP IS NULL';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_OPTION DROP COLUMN OPTION_POLL_ID';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_OPTION RENAME COLUMN OPTION_POLL_ID_TMP TO OPTION_POLL_ID';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_OPTION MODIFY (OPTION_POLL_ID VARCHAR2(36) NOT NULL)';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_OPTION DROP COLUMN OPTION_UUID';
        EXECUTE IMMEDIATE 'CREATE INDEX POLLTOOL_OPTION_POLLID_IDX ON POLL_OPTION (OPTION_POLL_ID)';

        -- The JPA entity manages OPTION_ORDER via @OrderColumn on a bidirectional
        -- (mappedBy) Poll.options collection. Hibernate inserts a new Option row
        -- before it knows the collection's final order, then issues a follow-up
        -- UPDATE to set OPTION_ORDER once the index is known. Without a default,
        -- that first INSERT fails as soon as a poll option is added through the
        -- new tool (same failure mode as MySQL's missing-default error).
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_OPTION MODIFY (OPTION_ORDER NUMBER(10,0) DEFAULT 0 NOT NULL)';

        -- --- POLL_VOTE: votes reach a poll through their option now ---
        -- VOTE_OPTION becomes NOT NULL, so drop votes that never recorded one.
        EXECUTE IMMEDIATE 'DELETE FROM POLL_VOTE WHERE VOTE_OPTION IS NULL';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_VOTE DROP COLUMN VOTE_POLL_ID';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_VOTE MODIFY (VOTE_OPTION NUMBER(19,0) NOT NULL)';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_VOTE MODIFY (USER_ID VARCHAR2(99) NOT NULL)';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_VOTE MODIFY (VOTE_IP VARCHAR2(99) NOT NULL)';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_VOTE MODIFY (VOTE_SUBMISSION_ID VARCHAR2(99) NOT NULL)';
        EXECUTE IMMEDIATE 'CREATE INDEX POLLTOOL_VOTE_OPTION_IDX ON POLL_VOTE (VOTE_OPTION)';

        -- --- POLL_POLL: promote POLL_UUID to the primary key ---
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_POLL DROP PRIMARY KEY';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_POLL DROP COLUMN POLL_ID';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_POLL RENAME COLUMN POLL_UUID TO POLL_ID';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_POLL MODIFY (POLL_ID VARCHAR2(36) NOT NULL)';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_POLL ADD CONSTRAINT POLL_POLL_PK PRIMARY KEY (POLL_ID)';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_POLL MODIFY (POLL_OWNER VARCHAR2(99) NOT NULL)';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_POLL MODIFY (POLL_SITE_ID VARCHAR2(99) NOT NULL)';
        EXECUTE IMMEDIATE 'ALTER TABLE POLL_POLL MODIFY (POLL_DISPLAY_RESULT VARCHAR2(99) NOT NULL)';

    END IF;
END;
/

-- The poll primary key is no longer sequence-generated; drop the obsolete sequence.
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE POLL_POLL_ID_SEQ';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
-- END SAK-52039

