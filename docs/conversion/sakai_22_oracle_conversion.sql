-- SAK-40427
UPDATE SAKAI_SITE_TOOL SET TITLE = 'Discussions' WHERE REGISTRATION = 'sakai.forums' AND TITLE = 'Forums';
UPDATE SAKAI_SITE_PAGE SET TITLE = 'Discussions' WHERE TITLE = 'Forums';
-- End SAK-40427

-- SAK-44305
create table MFR_DRAFT_RECIPIENT_T
(ID NUMBER(19,0) NOT NULL,
 TYPE NUMBER(10,0) NOT NULL,
 RECIPIENT_ID VARCHAR2(255) NOT NULL,
 DRAFT_MSG_ID NUMBER(19,0) NOT NULL,
 BCC NUMBER(1,0) NOT NULL,
 PRIMARY KEY (ID));

create index MFR_DRAFT_REC_MSG_ID_I on MFR_DRAFT_RECIPIENT_T(DRAFT_MSG_ID);

create sequence MFR_DRAFT_RECIPIENT_S;
-- End SAK-44305

-- SAK-45565
ALTER TABLE lesson_builder_groups RENAME COLUMN groups TO item_groups;
ALTER TABLE lesson_builder_items RENAME COLUMN groups TO item_groups;
ALTER TABLE tasks RENAME COLUMN SYSTEM TO SYSTEM_TASK;
-- SAK-45565

-- SAK-44967
ALTER TABLE gb_gradebook_t ADD allow_compare_grades NUMBER(1,0) DEFAULT 0 NOT NULL ;
ALTER TABLE gb_gradebook_t ADD comparing_display_firstnames NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE gb_gradebook_t ADD comparing_display_surnames NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE gb_gradebook_t ADD comparing_display_comments NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE gb_gradebook_t ADD comparing_display_allitems NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE gb_gradebook_t ADD comparing_randomizedata NUMBER(1,0) DEFAULT 0 NOT NULL;
-- End SAK-44967

-- SAK-43155
ALTER TABLE ASN_ASSIGNMENT ADD IS_REQUIRED_ESTIMATE CHAR(1) DEFAULT '0' NOT NULL;
ALTER TABLE ASN_ASSIGNMENT ADD ESTIMATE VARCHAR(255) NULL;
ALTER TABLE ASN_SUBMISSION_SUBMITTER ADD TIME_SPENT VARCHAR(255) NULL;
ALTER TABLE ASN_ASSIGNMENT ADD CONSTRAINT CHECK_IS_REQUIRED_ESTIMATE CHECK (IS_REQUIRED_ESTIMATE IN ('0', '1'));

CREATE TABLE ASN_TIMESHEET (
ID number(22) NOT NULL,
SUBMITTER_ID number NOT NULL,
REG_DATE TIMESTAMP(6) NOT NULL,
REG_TIME VARCHAR(255) NOT NULL,
ASN_COMMENT VARCHAR(500) NULL,
PRIMARY KEY (ID) USING INDEX TABLESPACE SAKAI_PR ENABLE VALIDATE,
CONSTRAINT FK_ASN_SUBMISSION_SUB_TEST FOREIGN KEY (SUBMITTER_ID) REFERENCES ASN_SUBMISSION_SUBMITTER (ID)
);

CREATE SEQUENCE SEQ_ID_ASN_TIMESHEET_S;
-- End SAK-43155

-- SAK-46021
CREATE TABLE COMMONS_LIKE (
USER_ID VARCHAR2(99) NOT NULL,
POST_ID VARCHAR2(36) NOT NULL,
VOTE NUMBER(1) DEFAULT 0 NOT NULL,
MODIFIED_DATE TIMESTAMP(6),
CONSTRAINT commons_like_pk PRIMARY KEY (USER_ID, POST_ID)
);
--End SAK-46021
