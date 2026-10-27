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
        -- VOTE_OPTION becomes NOT NULL, so drop votes that never recorded one,
        -- plus votes that still point at an OPTION_ID just deleted above as
        -- orphaned (poll with an unresolvable POLL_UUID). Without the second
        -- half of this condition those votes survive the migration as
        -- orphans referencing a non-existent option.
        EXECUTE IMMEDIATE 'DELETE FROM POLL_VOTE
            WHERE VOTE_OPTION IS NULL
               OR VOTE_OPTION NOT IN (SELECT OPTION_ID FROM POLL_OPTION)';
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

-- SAK-52971 Polls: renumber OPTION_ORDER contiguously per poll

-- Legacy Polls did not keep OPTION_ORDER contiguous: a new option took the
-- current option count as its order and deletions did not renumber. The JPA
-- entity uses OPTION_ORDER as the @OrderColumn list index, so gaps become null
-- elements and repeated values hide options. Renumber each poll's options from
-- 0, keeping the current order and, for ties, creation order (OPTION_ID).
-- It runs outside the schema guard of the SAK-52039 conversion above, so it
-- also fixes instances converted before this step existed. Only rows whose
-- order changes are updated, so it is safe to re-run.
MERGE INTO POLL_OPTION o
USING (
    SELECT OPTION_ID,
           ROW_NUMBER() OVER (PARTITION BY OPTION_POLL_ID ORDER BY OPTION_ORDER, OPTION_ID) - 1 AS NEW_ORDER
    FROM POLL_OPTION
) r ON (o.OPTION_ID = r.OPTION_ID)
WHEN MATCHED THEN UPDATE SET o.OPTION_ORDER = r.NEW_ORDER
WHERE o.OPTION_ORDER <> r.NEW_ORDER;
-- END SAK-52971

-- START SAK-10208
CREATE TABLE POLL_GROUPS (
  POLL_ID VARCHAR2(36 CHAR) NOT NULL,
  GROUP_ID VARCHAR2(99 CHAR) NOT NULL,
  PRIMARY KEY (POLL_ID, GROUP_ID)
);

ALTER TABLE POLL_GROUPS
ADD CONSTRAINT FK_POLL_GROUPS_POLL_ID
FOREIGN KEY (POLL_ID)
REFERENCES POLL_POLL (POLL_ID);

ALTER TABLE POLL_POLL
ADD ACCESS_TYPE VARCHAR2(10 CHAR) DEFAULT 'SITE' NOT NULL;

UPDATE POLL_POLL SET ACCESS_TYPE = 'SITE';
-- END SAK-10208

-- SAK-52889: migrate Conversations tags and retire Taggable.
ALTER TABLE tagservice_tag DROP CONSTRAINT tagservice_tag_fk;
ALTER TABLE tagservice_collection MODIFY tagcollectionid VARCHAR2(99 CHAR);
ALTER TABLE tagservice_tag MODIFY tagcollectionid VARCHAR2(99 CHAR);
ALTER TABLE tagservice_tag ADD CONSTRAINT tagservice_tag_fk
    FOREIGN KEY (tagcollectionid) REFERENCES tagservice_collection(tagcollectionid);

INSERT INTO tagservice_collection
    (tagcollectionid, name, description, creationdate, lastmodificationdate,
     lastsynchronizationdate, externalupdate, externalcreation, lastupdatedateinexternalsystem)
    SELECT DISTINCT t.SITE_ID, t.SITE_ID, 'Site tags', 0, 0, 0, 0, 0, 0
    FROM CONV_TAGS t WHERE NOT EXISTS
        (SELECT 1 FROM tagservice_collection c WHERE c.tagcollectionid = t.SITE_ID);

INSERT INTO tagservice_tag
    (tagid, tagcollectionid, taglabel, description, creationdate, lastmodificationdate,
     externalcreation, externalcreationDate, externalupdate, lastupdatedateinexternalsystem)
    SELECT 'conv-' || TO_CHAR(TAG_ID), SITE_ID,
        LABEL, DESCRIPTION, 0, 0, 0, 0, 0, 0 FROM CONV_TAGS;

INSERT INTO tagservice_tagassociation (id, item_id, tag_id)
    SELECT RAWTOHEX(SYS_GUID()), TOPIC_ID, 'conv-' || TO_CHAR(TAG)
    FROM CONV_TOPIC_TAGS;
COMMIT;

DROP TABLE CONV_TOPIC_TAGS;
DROP TABLE CONV_TAGS;
DROP SEQUENCE CONV_TAGS_S;
DROP TABLE TAGGABLE_LINK;

-- SAK-53029 / SAK-49798: Initialize Rubrics revisions and retain unknown historical editors.
ALTER TABLE rbc_rubric ADD (VERSION NUMBER(19,0) DEFAULT 0 NOT NULL, LAST_MODIFIED_BY VARCHAR2(99 CHAR));
ALTER TABLE rbc_criterion ADD (VERSION NUMBER(19,0) DEFAULT 0 NOT NULL);
ALTER TABLE rbc_rating ADD (VERSION NUMBER(19,0) DEFAULT 0 NOT NULL);
ALTER TABLE rbc_evaluation ADD (VERSION NUMBER(19,0) DEFAULT 0 NOT NULL);
ALTER TABLE rbc_criterion_outcome ADD (VERSION NUMBER(19,0) DEFAULT 0 NOT NULL);
ALTER TABLE rbc_returned_evaluation ADD (VERSION NUMBER(19,0) DEFAULT 0 NOT NULL);
ALTER TABLE rbc_returned_criterion_out ADD (VERSION NUMBER(19,0) DEFAULT 0 NOT NULL);
ALTER TABLE rbc_tool_item_rbc_assoc ADD (VERSION NUMBER(19,0) DEFAULT 0 NOT NULL);
-- END SAK-53029

-- SAK-52803: Drop the legacy criterion foreign keys reported on upgraded databases.
-- rbc_criterion_outcome.criterion_id references rbc_criterion.id.
ALTER TABLE rbc_criterion_outcome DROP CONSTRAINT FK_h43853lsee9xsay4qlic80pkv;
-- rbc_returned_criterion_out.criterion_id references rbc_criterion.id.
ALTER TABLE rbc_returned_criterion_out DROP CONSTRAINT fk_rbc_returned_criterion_id;
-- END SAK-52803

-- START SAK-53019
-- Password-reset tokens and per-account email limits are independent of account validation.
CREATE TABLE PASSWORD_RESET (
  USER_ID VARCHAR2(99 CHAR) NOT NULL,
  VERSION NUMBER(19,0) NOT NULL,
  RESET_TOKEN VARCHAR2(36 CHAR),
  CREATED_AT TIMESTAMP(6),
  CONSUMED_AT TIMESTAMP(6),
  REQUEST_TIMES CLOB NOT NULL,
  CONSTRAINT PK_PASSWORD_RESET PRIMARY KEY (USER_ID),
  CONSTRAINT UK_PASSWORD_RESET_TOKEN UNIQUE (RESET_TOKEN)
);
-- END SAK-53019

-- START SAK-52046
-- SAK-52046: run once, with Sakai stopped, after the Tags/Taggable merger conversion.
-- Back up the database first. Unscoped imported/admin collections remain global.
ALTER TABLE tagservice_collection ADD siteid VARCHAR2(100);
BEGIN
    FOR c IN (
        SELECT uc.CONSTRAINT_NAME FROM USER_CONSTRAINTS uc
        JOIN USER_CONS_COLUMNS cols ON cols.CONSTRAINT_NAME = uc.CONSTRAINT_NAME
        WHERE uc.TABLE_NAME = 'TAGSERVICE_COLLECTION' AND uc.CONSTRAINT_TYPE = 'U'
        GROUP BY uc.CONSTRAINT_NAME HAVING COUNT(*) = 1 AND MAX(cols.COLUMN_NAME) = 'NAME'
    ) LOOP
        EXECUTE IMMEDIATE 'ALTER TABLE tagservice_collection DROP CONSTRAINT "' || c.CONSTRAINT_NAME || '"';
    END LOOP;
END;
/
ALTER TABLE tagservice_collection ADD CONSTRAINT tagservice_site_name UNIQUE (siteid, name);
CREATE INDEX tagservice_collection_siteid ON tagservice_collection(siteid);

UPDATE tagservice_collection SET siteid = tagcollectionid
WHERE EXISTS (SELECT 1 FROM SAKAI_SITE s WHERE s.SITE_ID = tagcollectionid);
UPDATE tagservice_collection SET siteid = '~' || tagcollectionid
WHERE siteid IS NULL AND EXISTS (SELECT 1 FROM SAKAI_USER_ID_MAP u WHERE u.USER_ID = tagcollectionid);

-- Empty external-source identifiers are absent, allowing ordinary collections to coexist.
UPDATE tagservice_collection SET externalsourcename = NULL WHERE TRIM(externalsourcename) IS NULL;

-- Clone personal Messages tags into each site that actually uses them.
-- Retain originals: question pools and questions may still refer to those IDs.
CREATE TABLE SAK52046_MESSAGE_TAGS (
    old_tag_id VARCHAR2(36) NOT NULL,
    site_id VARCHAR2(99) NOT NULL,
    new_tag_id VARCHAR2(36) NOT NULL,
    PRIMARY KEY (old_tag_id, site_id)
);
INSERT INTO SAK52046_MESSAGE_TAGS (old_tag_id, site_id, new_tag_id)
SELECT old_tag_id, site_id, LOWER(RAWTOHEX(SYS_GUID())) FROM (
    SELECT DISTINCT t.tagid AS old_tag_id, r.CONTEXT_ID AS site_id
    FROM tagservice_tag t
    JOIN tagservice_collection c ON c.tagcollectionid = t.tagcollectionid
    JOIN tagservice_tagassociation a ON a.tag_id = t.tagid
    JOIN MFR_PVT_MSG_USR_T r ON a.item_id = TO_CHAR(r.messageSurrogateKey)
    JOIN SAKAI_SITE s ON s.SITE_ID = r.CONTEXT_ID
    WHERE c.siteid LIKE '~%'
) message_tags;

INSERT INTO tagservice_collection (tagcollectionid, siteid, name, description)
SELECT DISTINCT m.site_id, m.site_id, m.site_id, 'Site tags'
FROM SAK52046_MESSAGE_TAGS m
WHERE NOT EXISTS (SELECT 1 FROM tagservice_collection c WHERE c.tagcollectionid = m.site_id);

INSERT INTO tagservice_tag (tagid, tagcollectionid, externalid, taglabel, description, alternativelabels, createdby, creationdate, externalcreation, externalcreationdate, externalupdate, lastmodifiedby, lastmodificationdate, lastupdatedateinexternalsystem, parentid, externalhierarchycode, externaltype, data)
SELECT m.new_tag_id, m.site_id, t.externalid, t.taglabel, t.description, t.alternativelabels, t.createdby, t.creationdate, t.externalcreation, t.externalcreationdate, t.externalupdate, t.lastmodifiedby, t.lastmodificationdate, t.lastupdatedateinexternalsystem, t.parentid, t.externalhierarchycode, t.externaltype, t.data
FROM SAK52046_MESSAGE_TAGS m JOIN tagservice_tag t ON t.tagid = m.old_tag_id;

-- Build distinct pairs before assigning IDs: a message can have several recipients.
INSERT INTO tagservice_tagassociation (id, tag_id, item_id)
SELECT LOWER(RAWTOHEX(SYS_GUID())), new_tag_id, item_id FROM (
    SELECT DISTINCT m.new_tag_id, a.item_id
    FROM SAK52046_MESSAGE_TAGS m
    JOIN tagservice_tagassociation a ON a.tag_id = m.old_tag_id
    JOIN MFR_PVT_MSG_USR_T r ON a.item_id = TO_CHAR(r.messageSurrogateKey) AND r.CONTEXT_ID = m.site_id
) message_associations;

DELETE FROM tagservice_tagassociation a WHERE EXISTS (
    SELECT 1 FROM SAK52046_MESSAGE_TAGS m JOIN MFR_PVT_MSG_USR_T r ON r.CONTEXT_ID = m.site_id
    WHERE m.old_tag_id = a.tag_id AND a.item_id = TO_CHAR(r.messageSurrogateKey)
);
DROP TABLE SAK52046_MESSAGE_TAGS;

-- Add Tags to existing Admin Workspaces that do not already contain it.
INSERT INTO SAKAI_SITE_PAGE (PAGE_ID, SITE_ID, TITLE, LAYOUT, SITE_ORDER, POPUP)
SELECT '!admin-52046', '!admin', 'Tags', '0', COALESCE(MAX(SITE_ORDER), 0) + 1, '0'
FROM SAKAI_SITE_PAGE
WHERE SITE_ID = '!admin'
HAVING NOT EXISTS (SELECT 1 FROM SAKAI_SITE_TOOL WHERE SITE_ID = '!admin' AND REGISTRATION = 'sakai.tagservice');
INSERT INTO SAKAI_SITE_TOOL (TOOL_ID, PAGE_ID, SITE_ID, REGISTRATION, PAGE_ORDER, TITLE, LAYOUT_HINTS)
SELECT '!admin-52046', '!admin-52046', '!admin', 'sakai.tagservice', 1, 'Tags', NULL FROM DUAL
WHERE EXISTS (SELECT 1 FROM SAKAI_SITE_PAGE WHERE PAGE_ID = '!admin-52046')
AND NOT EXISTS (SELECT 1 FROM SAKAI_SITE_TOOL WHERE SITE_ID = '!admin' AND REGISTRATION = 'sakai.tagservice');

-- END SAK-52046

-- SAK-52991 Preferences optimistic locking
ALTER TABLE SAKAI_PREFERENCES ADD (VERSION NUMBER(19) DEFAULT 0 NOT NULL);

-- SAK-52581 start
CREATE TABLE lti_tool_permissions (
  tool_id NUMBER(19,0) NOT NULL,
  permission VARCHAR2(255 CHAR) NULL,
  CONSTRAINT uk_lti_tool_permissions UNIQUE (tool_id, permission),
  CONSTRAINT fk_lti_tool_permissions_tool
    FOREIGN KEY (tool_id) REFERENCES lti_tools (id)
);
-- SAK-52581 end

-- Attendance: initial schema (sakaiproject/sakai#15237).
CREATE SEQUENCE ATTENDANCE_EVENT_S START WITH 1 INCREMENT BY 50;

CREATE SEQUENCE ATTENDANCE_GRADE_S START WITH 1 INCREMENT BY 50;

CREATE SEQUENCE ATTENDANCE_RECORD_S START WITH 1 INCREMENT BY 50;

CREATE SEQUENCE ATTENDANCE_RULE_T_SEQ START WITH 1 INCREMENT BY 50;

CREATE SEQUENCE ATTENDANCE_SITE_S START WITH 1 INCREMENT BY 50;

CREATE SEQUENCE ATTENDANCE_STATUS_S START WITH 1 INCREMENT BY 50;

CREATE SEQUENCE ATTENDANCE_USER_STATS_S START WITH 1 INCREMENT BY 50;

CREATE TABLE ATTENDANCE_EVENT_T (
  IS_REOCCURRING NUMBER(1,0) CHECK (IS_REOCCURRING IN (0,1)),
  IS_REQUIRED NUMBER(1,0) CHECK (IS_REQUIRED IN (0,1)),
  A_EVENT_ID NUMBER(19,0) NOT NULL,
  A_SITE_ID NUMBER(19,0) NOT NULL,
  END_DATE_TIME TIMESTAMP(6),
  LAST_MODIFIED_DATE TIMESTAMP(6) NOT NULL,
  REOCCURRING_ID NUMBER(19,0),
  START_DATE_TIME TIMESTAMP(6),
  LAST_MODIFIED_BY VARCHAR2(99 CHAR) NOT NULL,
  LOCATION VARCHAR2(255 CHAR),
  NAME VARCHAR2(255 CHAR),
  RELEASED_TO VARCHAR2(255 CHAR),
  PRIMARY KEY (A_EVENT_ID)
);

CREATE TABLE ATTENDANCE_GRADE_T (
  GRADE FLOAT(53),
  OVERRIDE NUMBER(1,0) CHECK (OVERRIDE IN (0,1)),
  A_GRADE_ID NUMBER(19,0) NOT NULL,
  A_SITE_ID NUMBER(19,0) NOT NULL,
  LAST_MODIFIED_DATE TIMESTAMP(6) NOT NULL,
  LAST_MODIFIED_BY VARCHAR2(99 CHAR) NOT NULL,
  USER_ID VARCHAR2(99 CHAR),
  PRIMARY KEY (A_GRADE_ID)
);

CREATE TABLE ATTENDANCE_ITEM_STATS_T (
  EXCUSED NUMBER(10,0),
  LATE NUMBER(10,0),
  LEFT_EARLY NUMBER(10,0),
  PRESENT NUMBER(10,0),
  UNEXCUSED NUMBER(10,0),
  A_ITEM_STATS_ID NUMBER(19,0) NOT NULL,
  PRIMARY KEY (A_ITEM_STATS_ID)
);

CREATE TABLE ATTENDANCE_RECORD_T (
  A_EVENT_ID NUMBER(19,0) NOT NULL,
  A_RECORD_ID NUMBER(19,0) NOT NULL,
  LAST_MODIFIED_DATE TIMESTAMP(6) NOT NULL,
  LAST_MODIFIED_BY VARCHAR2(99 CHAR) NOT NULL,
  USER_ID VARCHAR2(99 CHAR),
  RECORD_COMMENT VARCHAR2(4000 CHAR),
  STATUS VARCHAR2(255 CHAR) CHECK (STATUS IN ('UNKNOWN','PRESENT','UNEXCUSED_ABSENCE','EXCUSED_ABSENCE','LATE','LEFT_EARLY')),
  PRIMARY KEY (A_RECORD_ID),
  constraint UK_ATTENDANCE_RECORD_USER UNIQUE (USER_ID, A_EVENT_ID)
);

CREATE TABLE ATTENDANCE_RULE_T (
  END_RANGE NUMBER(10,0),
  POINTS FLOAT(53) NOT NULL,
  START_RANGE NUMBER(10,0) NOT NULL,
  A_SITE_ID NUMBER(19,0) NOT NULL,
  GRADING_RULE_ID NUMBER(19,0) NOT NULL,
  LAST_MODIFIED_DATE TIMESTAMP(6) NOT NULL,
  LAST_MODIFIED_BY VARCHAR2(99 CHAR) NOT NULL,
  STATUS VARCHAR2(255 CHAR) NOT NULL CHECK (STATUS IN ('UNKNOWN','PRESENT','UNEXCUSED_ABSENCE','EXCUSED_ABSENCE','LATE','LEFT_EARLY')),
  PRIMARY KEY (GRADING_RULE_ID),
  constraint UK_ATTENDANCE_RULE UNIQUE (A_SITE_ID, STATUS, START_RANGE, END_RANGE)
);

CREATE TABLE ATTENDANCE_SITE_T (
  GRADING_METHOD NUMBER(10,0),
  IS_GRADE_SHOWN NUMBER(1,0) CHECK (IS_GRADE_SHOWN IN (0,1)),
  MAXIMUM_GRADE FLOAT(53),
  SEND_TO_GRADEBOOK NUMBER(1,0) CHECK (SEND_TO_GRADEBOOK IN (0,1)),
  SHOW_COMMENTS NUMBER(1,0) CHECK (SHOW_COMMENTS IN (0,1)),
  SYNC NUMBER(1,0) CHECK (SYNC IN (0,1)),
  A_SITE_ID NUMBER(19,0) NOT NULL,
  SYNC_TIME TIMESTAMP(6),
  DEFAULT_STATUS VARCHAR2(20 CHAR) CHECK (DEFAULT_STATUS IN ('UNKNOWN','PRESENT','UNEXCUSED_ABSENCE','EXCUSED_ABSENCE','LATE','LEFT_EARLY')),
  SITE_ID VARCHAR2(99 CHAR),
  GRADEBOOK_ITEM_NAME VARCHAR2(255 CHAR),
  PRIMARY KEY (A_SITE_ID),
  constraint UK_ATT_SITE_SITE_ID UNIQUE (SITE_ID)
);

CREATE TABLE ATTENDANCE_STATUS_T (
  IS_ACTIVE NUMBER(1,0) CHECK (IS_ACTIVE IN (0,1)),
  SORT_ORDER NUMBER(10,0),
  A_SITE_ID NUMBER(19,0) NOT NULL,
  A_STATUS_ID NUMBER(19,0) NOT NULL,
  STATUS VARCHAR2(255 CHAR) CHECK (STATUS IN ('UNKNOWN','PRESENT','UNEXCUSED_ABSENCE','EXCUSED_ABSENCE','LATE','LEFT_EARLY')),
  PRIMARY KEY (A_STATUS_ID)
);

CREATE TABLE ATTENDANCE_USER_STATS_T (
  EXCUSED NUMBER(10,0),
  LATE NUMBER(10,0),
  LEFT_EARLY NUMBER(10,0),
  PRESENT NUMBER(10,0),
  UNEXCUSED NUMBER(10,0),
  A_SITE_ID NUMBER(19,0) NOT NULL,
  A_USER_STATS_ID NUMBER(19,0) NOT NULL,
  USER_ID VARCHAR2(99 CHAR),
  PRIMARY KEY (A_USER_STATS_ID)
);

ALTER TABLE ATTENDANCE_EVENT_T
   ADD CONSTRAINT FKbsghx771fljtodaa9wwhsfujk
   FOREIGN KEY (A_SITE_ID)
   REFERENCES ATTENDANCE_SITE_T;

ALTER TABLE ATTENDANCE_GRADE_T
   ADD CONSTRAINT FK6swbjl8hgshooyaymkg1joy0u
   FOREIGN KEY (A_SITE_ID)
   REFERENCES ATTENDANCE_SITE_T;

ALTER TABLE ATTENDANCE_ITEM_STATS_T
   ADD CONSTRAINT FKtd8u5029kgcwd3ft3u2uk5u9s
   FOREIGN KEY (A_ITEM_STATS_ID)
   REFERENCES ATTENDANCE_EVENT_T;

ALTER TABLE ATTENDANCE_RECORD_T
   ADD CONSTRAINT FK2unk0v76305qniatoq724nrf3
   FOREIGN KEY (A_EVENT_ID)
   REFERENCES ATTENDANCE_EVENT_T;

ALTER TABLE ATTENDANCE_RULE_T
   ADD CONSTRAINT FKhnih6gwr6wdlesg6x1cp7jrxv
   FOREIGN KEY (A_SITE_ID)
   REFERENCES ATTENDANCE_SITE_T;

ALTER TABLE ATTENDANCE_STATUS_T
   ADD CONSTRAINT FK9w495f9jogjo6sxwqlpycrkt3
   FOREIGN KEY (A_SITE_ID)
   REFERENCES ATTENDANCE_SITE_T;

ALTER TABLE ATTENDANCE_USER_STATS_T
   ADD CONSTRAINT FKqp7lk0j4vtynm7h3yrne687ea
   FOREIGN KEY (A_SITE_ID)
   REFERENCES ATTENDANCE_SITE_T;
-- END Attendance

-- SAK-52621 start

DECLARE
    v_count NUMBER;

    PROCEDURE create_table(p_table VARCHAR2, p_ddl VARCHAR2) IS
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists FROM USER_TABLES WHERE TABLE_NAME = UPPER(p_table);
        IF v_exists = 0 THEN
            EXECUTE IMMEDIATE p_ddl;
        END IF;
    END;
BEGIN
    SELECT COUNT(*) INTO v_count FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'VTM_ANALYTICS_EVENT_S';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE SEQUENCE VTM_ANALYTICS_EVENT_S START WITH 1 INCREMENT BY 50';
    END IF;

    create_table('VTM_ANALYTICS_EVENT', q'[
        CREATE TABLE vtm_analytics_event (
            id NUMBER(19,0) NOT NULL,
            eventTime NUMBER(19,0) NOT NULL,
            eventType VARCHAR2(32 CHAR) NOT NULL,
            siteId VARCHAR2(99 CHAR) NOT NULL,
            userId VARCHAR2(99 CHAR) NOT NULL,
            videoId VARCHAR2(36 CHAR) NOT NULL,
            PRIMARY KEY (id)
        )
    ]');

    create_table('VTM_CATEGORY', q'[
        CREATE TABLE vtm_category (
            id VARCHAR2(36 CHAR) NOT NULL,
            createdBy VARCHAR2(99 CHAR),
            createdOn NUMBER(19,0) NOT NULL,
            modifiedBy VARCHAR2(99 CHAR),
            modifiedOn NUMBER(19,0) NOT NULL,
            name VARCHAR2(255 CHAR) NOT NULL,
            parentCategoryId VARCHAR2(36 CHAR),
            siteId VARCHAR2(99 CHAR) NOT NULL,
            sortOrder NUMBER(10,0) NOT NULL,
            PRIMARY KEY (id)
        )
    ]');

    create_table('VTM_LESSON_LINK', q'[
        CREATE TABLE vtm_lesson_link (
            id VARCHAR2(36 CHAR) NOT NULL,
            createdOn NUMBER(19,0) NOT NULL,
            lessonItemId VARCHAR2(99 CHAR),
            lessonPageId VARCHAR2(99 CHAR) NOT NULL,
            siteId VARCHAR2(99 CHAR) NOT NULL,
            videoId VARCHAR2(36 CHAR) NOT NULL,
            PRIMARY KEY (id)
        )
    ]');

    create_table('VTM_OAUTH_CREDENTIALS', q'[
        CREATE TABLE vtm_oauth_credentials (
            id VARCHAR2(36 CHAR) NOT NULL,
            apiKey VARCHAR2(255 CHAR),
            clientId VARCHAR2(255 CHAR),
            secret VARCHAR2(4000 CHAR),
            createdOn NUMBER(19,0) NOT NULL,
            modifiedOn NUMBER(19,0) NOT NULL,
            providerType VARCHAR2(32 CHAR) NOT NULL UNIQUE CHECK (providerType IN ('RESOURCES','EXTERNAL','NATIVE','HLS_UPLOAD','YOUTUBE_UPLOAD')),
            refresh_token VARCHAR2(4000 CHAR),
            PRIMARY KEY (id)
        )
    ]');

    create_table('VTM_USER_VIDEO_PREF', q'[
        CREATE TABLE vtm_user_video_pref (
            id VARCHAR2(36 CHAR) NOT NULL,
            createdOn NUMBER(19,0) NOT NULL,
            favorite NUMBER(1,0) NOT NULL CHECK (favorite IN (0,1)),
            modifiedOn NUMBER(19,0) NOT NULL,
            siteId VARCHAR2(99 CHAR) NOT NULL,
            userId VARCHAR2(99 CHAR) NOT NULL,
            videoId VARCHAR2(36 CHAR) NOT NULL,
            watchLater NUMBER(1,0) NOT NULL CHECK (watchLater IN (0,1)),
            PRIMARY KEY (id)
        )
    ]');

    create_table('VTM_VIDEO', q'[
        CREATE TABLE vtm_video (
            id VARCHAR2(36 CHAR) NOT NULL,
            createdOn NUMBER(19,0) NOT NULL,
            description VARCHAR2(4000 CHAR),
            fileSizeBytes NUMBER(19,0),
            inheritDescriptionMetadata NUMBER(1,0) NOT NULL CHECK (inheritDescriptionMetadata IN (0,1)),
            inheritTitleMetadata NUMBER(1,0) NOT NULL CHECK (inheritTitleMetadata IN (0,1)),
            modifiedOn NUMBER(19,0) NOT NULL,
            ownerId VARCHAR2(99 CHAR) NOT NULL,
            providerType VARCHAR2(16 CHAR) NOT NULL CHECK (providerType IN ('RESOURCES','EXTERNAL','NATIVE','HLS_UPLOAD','YOUTUBE_UPLOAD')),
            publicationStatus VARCHAR2(16 CHAR) NOT NULL CHECK (publicationStatus IN ('DRAFT','PENDING_APPROVAL','PUBLISHED','WITHDRAWN','ARCHIVED')),
            releaseDate NUMBER(19,0),
            requiredViewPermission VARCHAR2(99 CHAR) NOT NULL,
            retractDate NUMBER(19,0),
            siteId VARCHAR2(99 CHAR) NOT NULL,
            sourceDeleted NUMBER(1,0) NOT NULL CHECK (sourceDeleted IN (0,1)),
            sourceReference VARCHAR2(1024 CHAR) NOT NULL,
            title VARCHAR2(255 CHAR) NOT NULL,
            visibilityScope VARCHAR2(16 CHAR) NOT NULL CHECK (visibilityScope IN ('GLOBAL','COURSE','LESSON')),
            PRIMARY KEY (id)
        )
    ]');

    -- Join table behind VideoTrainingVideo.categories (@ManyToMany).
    create_table('VTM_VIDEO_CATEGORY', q'[
        CREATE TABLE vtm_video_category (
            video_id VARCHAR2(36 CHAR) NOT NULL,
            category_id VARCHAR2(36 CHAR) NOT NULL,
            PRIMARY KEY (video_id, category_id),
            CONSTRAINT FKprr31fu8bl59ntapjh5qleflp FOREIGN KEY (category_id) REFERENCES vtm_category (id),
            CONSTRAINT FKjxhwu3bhkblxt1a7nv8erne6s FOREIGN KEY (video_id) REFERENCES vtm_video (id)
        )
    ]');

    create_table('VTM_VIDEO_PROCESS_JOB', q'[
        CREATE TABLE vtm_video_process_job (
            id VARCHAR2(36 CHAR) NOT NULL,
            createdOn NUMBER(19,0) NOT NULL,
            errorMessage VARCHAR2(4000 CHAR),
            modifiedOn NUMBER(19,0) NOT NULL,
            status VARCHAR2(16 CHAR) NOT NULL CHECK (status IN ('PENDING','PROCESSING','COMPLETED','FAILED','RETRY')),
            submitterUserId VARCHAR2(99 CHAR) NOT NULL,
            tempFilePath VARCHAR2(1024 CHAR) NOT NULL,
            videoId VARCHAR2(36 CHAR) NOT NULL,
            PRIMARY KEY (id)
        )
    ]');
END;
/

COMMIT;

-- SAK-52621 end
