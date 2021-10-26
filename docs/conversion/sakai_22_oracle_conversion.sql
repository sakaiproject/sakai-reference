-- SAK-40427
UPDATE SAKAI_SITE_TOOL SET TITLE = 'Discussions' WHERE REGISTRATION = 'sakai.forums' AND TITLE = 'Forums';
UPDATE SAKAI_SITE_PAGE SET TITLE = 'Discussions' WHERE TITLE = 'Forums';
-- End SAK-40427

-- SAK-44305
create table MFR_DRAFT_RECIPIENT_T
(ID NUMBER(19,0) NOT NULL,
 TYPE NUMBER(10,0) NOT NULL,
 RECIPIENT_ID VARCHAR2(255) NOT NULL,
 DRAFT_ID NUMBER(19,0) NOT NULL,
 BCC NUMBER(1,0) NOT NULL,
 PRIMARY KEY (ID));

create index MFR_DRAFT_REC_MSG_ID_I on MFR_DRAFT_RECIPIENT_T(DRAFT_ID);

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
ALTER TABLE ASN_ASSIGNMENT ADD ESTIMATE_REQUIRED CHAR(1) DEFAULT '0' NOT NULL;
ALTER TABLE ASN_ASSIGNMENT ADD ESTIMATE VARCHAR2(255) NULL;
ALTER TABLE ASN_SUBMISSION_SUBMITTER ADD TIME_SPENT VARCHAR2(255) NULL;
ALTER TABLE ASN_ASSIGNMENT ADD CONSTRAINT CHECK_IS_REQUIRED_ESTIMATE CHECK (ESTIMATE_REQUIRED IN ('0', '1'));

CREATE TABLE ASN_SUBMITTER_TIMESHEET (
ID number(22) NOT NULL,
SUBMISSION_SUBMITTER_ID number NOT NULL,
START_TIME TIMESTAMP(6) NOT NULL,
DURATION VARCHAR2(255) NOT NULL,
`COMMENT` VARCHAR2(4096) NULL,
PRIMARY KEY (ID) USING INDEX TABLESPACE SAKAI_PR ENABLE VALIDATE,
CONSTRAINT FK_ASN_SUBMISSION_SUB_TEST FOREIGN KEY (SUBMISSION_SUBMITTER_ID) REFERENCES ASN_SUBMISSION_SUBMITTER (ID)
);

CREATE SEQUENCE ASN_SUBMITTER_TIMESHEET_S
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

-- SAK-46137
ALTER TABLE SAKAI_PERSON_T ADD PRINCIPAL_NAME_PRIOR varchar2(255) DEFAULT NULL;
ALTER TABLE SAKAI_PERSON_T ADD SCOPED_AFFILIATION varchar2(255) DEFAULT NULL;
ALTER TABLE SAKAI_PERSON_T ADD TARGETED_ID varchar2(255) DEFAULT NULL;
ALTER TABLE SAKAI_PERSON_T ADD ASSURANCE varchar2(255) DEFAULT NULL;
ALTER TABLE SAKAI_PERSON_T ADD UNIQUE_ID varchar2(255) DEFAULT NULL;
-- End SAK-46137 

-- SAK-46085
ALTER TABLE PROFILE_SOCIAL_INFO_T ADD COLUMN INSTAGRAM_URL VARCHAR2(255) NOT NULL;
--End SAK-46085
