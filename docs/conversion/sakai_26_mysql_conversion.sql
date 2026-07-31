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

        -- --- POLL_VOTE: votes reach a poll through their option now ---
        -- VOTE_OPTION becomes NOT NULL, so drop votes that never recorded one.
        DELETE FROM POLL_VOTE WHERE VOTE_OPTION IS NULL;
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
