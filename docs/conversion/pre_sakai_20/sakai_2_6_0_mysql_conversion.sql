-- This is the MYSQL Sakai 2.5.4 -> 2.6.0 conversion script
-- --------------------------------------------------------------------------------------------------------------------------------------
-- 
-- use this to convert a Sakai database from 2.5.3 to 2.6.0.  Run this before you run your first app server.
-- auto.ddl does not need to be enabled in your app server - this script takes care of all new TABLEs, changed TABLEs, and changed data.
--
-- The 2.5.0 - 2.5.2 script can be located at https://source.sakaiproject.org/svn/reference/tags/sakai_2-5-2/docs/conversion/sakai_2_5_0-2_5_2_mysql_conversion.sql
-- * Note that there was not a 2.5.1 release due to critical issue identified just prior to release 
-- The 2.5.2 - 2.5.3 script can be located at https://source.sakaiproject.org/svn/reference/tags/sakai_2-5-3/docs/conversion/sakai_2_5_2-2_5_3_mysql_conversion.sql
-- The 2.5.3 - 2.5.4 script can be located at https://source.sakaiproject.org/svn/reference/tags/sakai-2.5.4/docs/conversion/sakai_2_5_3-2_5_4_mysql_conversion.sql
-- --------------------------------------------------------------------------------------------------------------------------------------

-- SAK-13345 introduced a performance optimization to search. To see if you need this index run this command:
-- show indexes from searchbuilderitem where key_name = "isearchbuilderitem_sta";
-- If there is 1 row returned then you should run the following 2 queries
-- create index ISEARCHBUILDERITEM_STA_ACT on searchbuilderitem (SEARCHSTATE,SEARCHACTION);
-- drop index ISEARCHBUILDERITEM_STA; 

-- SAK-12527 Changes to Chat Room options do not work consistently

-- add column timeParam and numberParam 
alter table CHAT2_CHANNEL add column timeParam int;
alter table CHAT2_CHANNEL add column numberParam int;

UPDATE CHAT2_CHANNEL
SET numberParam = Case When filterParam = 0 or filterType <> 'SelectByNumber' Then 10 Else filterParam End,
timeParam = Case When filterparam = 0 or filterType <> 'SelectMessagesByTime' Then 3 Else filterParam End;

alter table CHAT2_CHANNEL modify column timeParam int not null;
alter table CHAT2_CHANNEL modify column numberParam int not null;

-- SAK-12176 Messages-Send cc to recipients' email address(es)

-- add column sendEmailOut to table MFR_AREA_T
alter table MFR_AREA_T add column (SENDEMAILOUT bit);
update MFR_AREA_T set SENDEMAILOUT=1 where SENDEMAILOUT is NULL;
alter table MFR_AREA_T modify column SENDEMAILOUT bit not null;

-- new msg.emailout permission 

INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'msg.emailout');

-- maintain role
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.emailout'));

-- Instructor role
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.emailout'));

-- CIG Coordinator role
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.emailout'));

-- Program Coordinator role
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolioAdmin'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Program Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.emailout'));

-- Program Admin role
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolioAdmin'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Program Admin'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'msg.emailout'));

-- --------------------------------------------------------------------------------------------------------------------------------------
-- backfill new msg.emailout permissions into existing realms
-- --------------------------------------------------------------------------------------------------------------------------------------

-- for each realm that has a role matching something in this table, we will add to that role the function from this table
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP values ('maintain','msg.emailout');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Instructor','msg.emailout');
INSERT INTO PERMISSIONS_SRC_TEMP values ('CIG Coordinator','msg.emailout');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Program Coordinator','msg.emailout');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Program Admin','msg.emailout');

-- lookup the role and function numbers
CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
from PERMISSIONS_SRC_TEMP TMPSRC
JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

-- insert the new functions into the roles of any existing realm that has the role (don't convert the "!site.helper" or "!user.template")
INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
SELECT
    SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
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

-- clean up the temp tables
DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_SRC_TEMP;

-- OSP SAK-12016 SAK-16122
REPLACE INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!group.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'content.all.groups'));
REPLACE INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!group.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'content.hidden'));
REPLACE INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'content.all.groups'));
REPLACE INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'content.hidden'));

-- SAK-12777 Create unique constraint on CALENDAR_EVENT EVENT_ID
CREATE UNIQUE INDEX EVENT_INDEX ON CALENDAR_EVENT
(
       EVENT_ID
);

-- SAK-10139 permissions to allow Evaluation tool in My Workspace 

INSERT INTO SAKAI_REALM_RL_FN SELECT DISTINCT SR.REALM_KEY, SRR.ROLE_KEY, SRF.FUNCTION_KEY  from SAKAI_REALM SR, SAKAI_REALM_ROLE SRR, SAKAI_REALM_FUNCTION SRF where SR.REALM_ID like '/site/~%' AND SRR.ROLE_NAME = 'maintain' AND SRF.FUNCTION_NAME ='osp.matrix.evaluate';

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.user'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.evaluate'));

-- SAK-13406 matrix feedback options

alter table osp_scaffolding add column generalFeedbackOption tinyint not null DEFAULT '0';
alter table osp_scaffolding add column itemFeedbackOption tinyint not null DEFAULT '0';
update osp_scaffolding set generalFeedbackOption=0;
update osp_scaffolding set itemFeedbackOption=0;

alter table osp_wizard add column generalFeedbackOption tinyint not null DEFAULT '0';
alter table osp_wizard add column itemFeedbackOption tinyint not null DEFAULT '0';
update osp_wizard set generalFeedbackOption=0;
update osp_wizard set itemFeedbackOption=0;

-- OSP SAK-11545
alter table osp_wizard add reviewerGroupAccess integer not null default '0';

-- SAK-6216 Optional ability to store client hostname (resolved IP) in SAKAI_SESSION
alter table SAKAI_SESSION add column SESSION_HOSTNAME varchar(255);

-- SAK-10801 Add CONTEXT field to SAKAI_EVENT
alter table SAKAI_EVENT add column CONTEXT varchar(255);

-- SAK-13310 Poll description field too small
alter table POLL_POLL change POLL_DETAILS POLL_DETAILS text; 

-- SAK-14106
alter table SAM_ITEM_T add column DISCOUNT float NULL;
alter table SAM_ANSWER_T add column DISCOUNT float NULL;
alter table SAM_PUBLISHEDITEM_T add column DISCOUNT float NULL;
alter table SAM_PUBLISHEDANSWER_T add column DISCOUNT float NULL;

-- SAK-14291
create index SYLLABUS_ATTACH_ID_I on SAKAI_SYLLABUS_ATTACH (syllabusId);
create index SYLLABUS_DATA_SURRO_I on SAKAI_SYLLABUS_DATA (surrogateKey);

-- Samigo
-- SAK-8432
create index SAM_AG_AGENTID_I on SAM_ASSESSMENTGRADING_T (AGENTID);
-- SAK-14430
ALTER TABLE SAM_ASSESSACCESSCONTROL_T ADD MARKFORREVIEW INTEGER NULL;
ALTER TABLE SAM_PUBLISHEDACCESSCONTROL_T ADD MARKFORREVIEW INTEGER NULL;
-- SAK-14472
INSERT INTO SAM_TYPE_T (TYPEID , AUTHORITY, DOMAIN, KEYWORD, DESCRIPTION, STATUS, CREATEDBY, CREATEDDATE, LASTMODIFIEDBY, LASTMODIFIEDDATE)
    VALUES (12 , 'stanford.edu', 'assessment.item', 'Multiple Correct Single Selection', NULL, 1, 1, SYSDATE(), 1, SYSDATE());
-- SAK-14474
update SAM_ASSESSACCESSCONTROL_T set AUTOSUBMIT = 0;
update SAM_PUBLISHEDACCESSCONTROL_T set AUTOSUBMIT = 0;
alter table SAM_ASSESSMENTGRADING_T add ISAUTOSUBMITTED INTEGER null DEFAULT '0';
-- SAK-14430
INSERT INTO SAM_ASSESSMETADATA_T (ASSESSMENTMETADATAID, ASSESSMENTID, LABEL, ENTRY) VALUES
	(NULL, 1, 'markForReview_isInstructorEditable', 'true');
INSERT INTO SAM_ASSESSMETADATA_T (ASSESSMENTMETADATAID, ASSESSMENTID, LABEL, ENTRY) VALUES
	(NULL, (SELECT ID FROM SAM_ASSESSMENTBASE_T WHERE TITLE='Formative Assessment' AND TYPEID='142' AND ISTEMPLATE=1), 'markForReview_isInstructorEditable', 'true');
INSERT INTO SAM_ASSESSMETADATA_T (ASSESSMENTMETADATAID, ASSESSMENTID, LABEL, ENTRY) VALUES
	(NULL, (SELECT ID FROM SAM_ASSESSMENTBASE_T WHERE TITLE='Quiz' AND TYPEID='142' AND ISTEMPLATE=1), 'markForReview_isInstructorEditable', 'true');
INSERT INTO SAM_ASSESSMETADATA_T (ASSESSMENTMETADATAID, ASSESSMENTID, LABEL, ENTRY) VALUES
	(NULL, (SELECT ID FROM SAM_ASSESSMENTBASE_T WHERE TITLE='Problem Set' AND TYPEID='142' AND ISTEMPLATE=1), 'markForReview_isInstructorEditable', 'true');
INSERT INTO SAM_ASSESSMETADATA_T (ASSESSMENTMETADATAID, ASSESSMENTID, LABEL, ENTRY) VALUES
	(NULL, (SELECT ID FROM SAM_ASSESSMENTBASE_T WHERE TITLE='Test' AND TYPEID='142' AND ISTEMPLATE=1), 'markForReview_isInstructorEditable', 'true');
INSERT INTO SAM_ASSESSMETADATA_T (ASSESSMENTMETADATAID, ASSESSMENTID, LABEL, ENTRY) VALUES
	(NULL, (SELECT ID FROM SAM_ASSESSMENTBASE_T WHERE TITLE='Timed Test' AND TYPEID='142' AND ISTEMPLATE=1), 'markForReview_isInstructorEditable', 'true');
update SAM_ASSESSACCESSCONTROL_T set MARKFORREVIEW = 1 where ASSESSMENTID = (SELECT ID FROM SAM_ASSESSMENTBASE_T WHERE TITLE='Formative Assessment' AND TYPEID='142' AND ISTEMPLATE=1);


-- SAK-13646
alter table GB_GRADABLE_OBJECT_T
add IS_EXTRA_CREDIT bit(1),
add ASSIGNMENT_WEIGHTING double;

alter table GB_CATEGORY_T
add IS_EXTRA_CREDIT bit(1);

alter table GB_GRADE_RECORD_T
add IS_EXCLUDED_FROM_GRADE bit(1);

-- SAK-12883, SAK-12582 - Allow control over which academic sessions are
-- considered current; support more than one current academic session
alter table CM_ACADEMIC_SESSION_T add column IS_CURRENT bit default 0 not null;

-- WARNING: This simply emulates the old runtime behavior. It is strongly
-- recommended that you decide which terms should be treated as current
-- and edit this script accordingly!
update CM_ACADEMIC_SESSION_T set IS_CURRENT=1 where CURDATE() >= START_DATE and CURDATE() <= END_DATE;

-- Tables for email template service (new tool - SAK-14573)
    create table EMAIL_TEMPLATE_ITEM (
        ID bigint not null auto_increment,
        LAST_MODIFIED datetime not null,
        OWNER varchar(255) not null,
        SUBJECT text not null,
        MESSAGE text not null,
        TEMPLATE_KEY varchar(255) not null,
        TEMPLATE_LOCALE varchar(255),
        defaultType varchar(255),
        primary key (ID)
    );

    create index email_templ_owner on EMAIL_TEMPLATE_ITEM (OWNER);

    create index email_templ_key on EMAIL_TEMPLATE_ITEM (TEMPLATE_KEY);

-- --------------------------------------------------------------------------------------------------------------------------------------
-- SAK-7924 - add and backfill new site.roleswap permissions into existing realms and templates
-- --------------------------------------------------------------------------------------------------------------------------------------

-- ---- View Site in a Different Role Backfill --------
-- SAK-7924 -- Adding the new site.roleswap permission as well as backfilling where appropriate
-- roles that can be switched to are defined in sakai.properties with the studentview.roles property

INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'site.roleswap');

-- Add the permission to the templates - this is which roles have permission to access the functionality to switch roles
-- course sites
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'),
(select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'),
(select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.roleswap'));

-- maintain/access sites
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'),
(select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'),
(select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.roleswap'));

-- --------------------------------------------------------------------------------------------------------------------------------------
-- backfill script
-- --------------------------------------------------------------------------------------------------------------------------------------

-- course sites

CREATE TABLE PERMISSIONS_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));
CREATE TABLE PERMISSIONS_TEMP2 (REALM_KEY INTEGER, ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);

INSERT INTO PERMISSIONS_TEMP values ('Instructor','site.roleswap');

INSERT INTO PERMISSIONS_TEMP2 (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
select distinct SAKAI_REALM.REALM_KEY,
SAKAI_REALM_ROLE.ROLE_KEY, SAKAI_REALM_FUNCTION.FUNCTION_KEY
from SAKAI_REALM, SAKAI_REALM_ROLE, PERMISSIONS_TEMP,
SAKAI_REALM_FUNCTION, SAKAI_SITE
where SAKAI_REALM_ROLE.ROLE_NAME = PERMISSIONS_TEMP.ROLE_NAME
AND SAKAI_REALM_FUNCTION.FUNCTION_NAME =
PERMISSIONS_TEMP.FUNCTION_NAME
AND (substr(SAKAI_REALM.REALM_ID, 7,
length(SAKAI_REALM.REALM_ID)) = SAKAI_SITE.SITE_ID)
AND SAKAI_SITE.TYPE='course';

insert into SAKAI_REALM_RL_FN SELECT * FROM PERMISSIONS_TEMP2
tmp WHERE
not exists (
select 1
from SAKAI_REALM_RL_FN SRRFI
where SRRFI.REALM_KEY=tmp.REALM_KEY and SRRFI.ROLE_KEY=tmp.ROLE_KEY and
SRRFI.FUNCTION_KEY=tmp.FUNCTION_KEY
);

DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_TEMP2;

-- project sites

CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP values ('maintain','site.roleswap');

-- lookup the role and function numbers
create table PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
insert into PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
select SRR.ROLE_KEY, SRF.FUNCTION_KEY
from PERMISSIONS_SRC_TEMP TMPSRC
join SAKAI_REALM_ROLE SRR on (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
join SAKAI_REALM_FUNCTION SRF on (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

-- insert the new functions into the roles of any existing realm that has the role (don't convert the "!site.helper" or "!user.template")
insert into SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
select
    SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
from
    (select distinct SRRF.REALM_KEY, SRRF.ROLE_KEY from SAKAI_REALM_RL_FN SRRF) SRRFD
    join PERMISSIONS_TEMP TMP on (SRRFD.ROLE_KEY = TMP.ROLE_KEY)
    join SAKAI_REALM SR on (SRRFD.REALM_KEY = SR.REALM_KEY)
    where SR.REALM_ID != '!site.helper' AND SR.REALM_ID NOT LIKE '!user.template%'
    and not exists (
        select 1
            from SAKAI_REALM_RL_FN SRRFI
            where SRRFI.REALM_KEY=SRRFD.REALM_KEY and SRRFI.ROLE_KEY=SRRFD.ROLE_KEY and  SRRFI.FUNCTION_KEY=TMP.FUNCTION_KEY
    );

-- clean up the temp tables
drop table PERMISSIONS_TEMP;
drop table PERMISSIONS_SRC_TEMP;

-- - Tables added for SAK-12912:Add optional ability to prompt for questions during site creation

    create table SSQ_ANSWER (
        ID varchar(99) not null,
        ANSWER varchar(255),
        ANSWER_STRING varchar(255),
        FILL_IN_BLANK bit,
        ORDER_NUM integer,
        QUESTION_ID varchar(99),
        primary key (ID)
    );

    create table SSQ_QUESTION (
        ID varchar(99) not null,
        QUESTION varchar(255),
        REQUIRED bit,
        MULTIPLE_ANSWERS bit,
        ORDER_NUM integer,
        IS_CURRENT varchar(255),
        SITETYPE_ID varchar(99),
        primary key (ID)
    ) comment='This table stores site setup questions';

    create table SSQ_SITETYPE_QUESTIONS (
        ID varchar(99) not null,
        SITE_TYPE varchar(255),
        INSTRUCTION varchar(255),
        URL varchar(255),
        URL_LABEL varchar(255),
        URL_Target varchar(255),
        primary key (ID)
    );

    create table SSQ_USER_ANSWER (
        ID varchar(99) not null,
        SITE_ID varchar(255),
        USER_ID varchar(255),
        ANSWER_STRING varchar(255),
        ANSWER_ID varchar(255),
        QUESTION_ID varchar(255),
        primary key (ID)
    );

    create index SSQ_ANSWER_QUESTION_I on SSQ_ANSWER (QUESTION_ID);

    alter table SSQ_ANSWER 
        add index FK390C0DCC6B21AFB4 (QUESTION_ID), 
        add constraint FK390C0DCC6B21AFB4 
        foreign key (QUESTION_ID) 
        references SSQ_QUESTION (ID);

    create index SSQ_QUESTION_SITETYPE_I on SSQ_QUESTION (SITETYPE_ID);

    alter table SSQ_QUESTION 
        add index FKFE88BA7443AD4C69 (SITETYPE_ID), 
        add constraint FKFE88BA7443AD4C69 
        foreign key (SITETYPE_ID) 
        references SSQ_SITETYPE_QUESTIONS (ID);

-- --- SAK-15040 site.viewRoster is a newly added permission

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.user'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolioAdmin'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Program Admin'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolioAdmin'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Program Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!group.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!group.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!group.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '/site/mercury'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.viewRoster'));

-- --------------------------------------------------------------------------------------------------------------------------------------
-- backfill new site.viewRoster permissions into existing realms
-- --------------------------------------------------------------------------------------------------------------------------------------

-- for each realm that has a role matching something in this table, we will add to that role the function from this table
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP values ('maintain','site.viewRoster');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Instructor','site.viewRoster');
INSERT INTO PERMISSIONS_SRC_TEMP values ('CIG Coordinator','site.viewRoster');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Program Coordinator','site.viewRoster');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Program Admin','site.viewRoster');

-- lookup the role and function numbers
CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
from PERMISSIONS_SRC_TEMP TMPSRC
JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

-- insert the new functions into the roles of any existing realm that has the role (don't convert the "!site.helper" or "!user.template")
INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
SELECT
    SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
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

-- clean up the temp tables
DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_SRC_TEMP;

-- --- SAK-16024 site.add.course is a newly added permission

INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'site.add.course');
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!user.template.maintain'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = '.auth'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.add.course'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!user.template.registered'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = '.auth'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.add.course'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!user.template.sample'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = '.auth'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'site.add.course'));

-- --------------------------------------------------------------------------------------------------------------------------------------
-- backfill new site.add.course permissions into existing realms
-- --------------------------------------------------------------------------------------------------------------------------------------

-- SAK-16751 Backfilling for site.add.course has been commented out as it updates all realms with .auth role unnecessarily (site realms only require backfilling)
-- It is a rather promiscuous conversion that may not square with an institution's permission strategy.  If you
-- uncomment it and run it you will add site.add.course to realms like /announcement/channel/!site/motd,
-- /site/!urlError and !user.template.guest. None of these realms have include site.add so they cannot create sites.
-- So consider your options carefully before uncommenting and running this backfill operation.

-- for each realm that has a role matching something in this table, we will add to that role the function from this table
-- CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

-- INSERT INTO PERMISSIONS_SRC_TEMP values ('.auth','site.add.course');

-- lookup the role and function numbers
-- CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
-- INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
-- SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
-- from PERMISSIONS_SRC_TEMP TMPSRC
-- JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
-- JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

-- insert the new functions into the roles of any existing realm that has the role (don't convert the "!site.helper" or "!user.template")
-- INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
-- SELECT
--    SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
-- FROM
--    (SELECT DISTINCT SRRF.REALM_KEY, SRRF.ROLE_KEY FROM SAKAI_REALM_RL_FN SRRF) SRRFD
--    JOIN PERMISSIONS_TEMP TMP ON (SRRFD.ROLE_KEY = TMP.ROLE_KEY)
--    JOIN SAKAI_REALM SR ON (SRRFD.REALM_KEY = SR.REALM_KEY)
--    WHERE SR.REALM_ID != '!site.helper' AND SR.REALM_ID NOT LIKE '!user.template%'
--    AND NOT EXISTS (
--        SELECT 1
--            FROM SAKAI_REALM_RL_FN SRRFI
--            WHERE SRRFI.REALM_KEY=SRRFD.REALM_KEY AND SRRFI.ROLE_KEY=SRRFD.ROLE_KEY AND SRRFI.FUNCTION_KEY=TMP.FUNCTION_KEY
--    );

-- clean up the temp tables
-- DROP TABLE PERMISSIONS_TEMP;
-- DROP TABLE PERMISSIONS_SRC_TEMP;

--
-- Citations SAK-14517 Support more RIS types for import/export
--
-- Updates
--
-- INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('article','title','sakai:ris_identifier','T1,TI,CT');
UPDATE CITATION_SCHEMA_FIELD SET PROPERTY_VALUE = 'T1,TI,CT' WHERE SCHEMA_ID = 'article' AND FIELD_ID = 'title' AND PROPERTY_NAME = 'sakai:ris_identifier';
--
-- INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('article','sourceTitle','sakai:ris_identifier','JF,BT');
UPDATE CITATION_SCHEMA_FIELD SET PROPERTY_VALUE = 'JF,BT' WHERE SCHEMA_ID = 'article' AND FIELD_ID = 'sourceTitle' AND PROPERTY_NAME = 'sakai:ris_identifier';
--
-- New fields
--
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','creator','sakai:hasOrder','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','creator','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','creator','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','creator','sakai:maxCardinality','2147483647');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','creator','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','creator','sakai:ris_identifier','AU');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sakai:hasField','creator');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','title','sakai:hasOrder','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','title','sakai:required','true');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','title','sakai:minCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','title','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','title','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','title','sakai:ris_identifier','CT');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sakai:hasField','title');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','year','sakai:hasOrder','2');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','year','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','year','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','year','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','year','sakai:valueType','number');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','year','sakai:ris_identifier','PY');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sakai:hasField','year');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','volume','sakai:hasOrder','3');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','volume','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','volume','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','volume','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','volume','sakai:valueType','number');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','volume','sakai:ris_identifier','VL');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sakai:hasField','volume');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','pages','sakai:hasOrder','4');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','pages','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','pages','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','pages','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','pages','sakai:valueType','number');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','pages','sakai:ris_identifier','SP');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sakai:hasField','pages');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sourceTitle','sakai:hasOrder','5');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sourceTitle','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sourceTitle','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sourceTitle','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sourceTitle','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sourceTitle','sakai:ris_identifier','BT');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sakai:hasField','sourceTitle');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','note','sakai:hasOrder','6');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','note','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','note','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','note','sakai:maxCardinality','2147483647');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','note','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','note','sakai:ris_identifier','N1');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('proceed','sakai:hasField','note');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','title','sakai:hasOrder','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','title','sakai:required','true');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','title','sakai:minCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','title','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','title','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','title','sakai:ris_identifier','CT');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sakai:hasField','title');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','year','sakai:hasOrder','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','year','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','year','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','year','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','year','sakai:valueType','number');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','year','sakai:ris_identifier','PY');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sakai:hasField','year');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sourceTitle','sakai:hasOrder','2');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sourceTitle','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sourceTitle','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sourceTitle','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sourceTitle','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sourceTitle','sakai:ris_identifier','T3');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sakai:hasField','sourceTitle');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','abstract','sakai:hasOrder','3');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','abstract','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','abstract','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','abstract','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','abstract','sakai:valueType','longtext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','abstract','sakai:ris_identifier','N2');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sakai:hasField','abstract');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','subject','sakai:hasOrder','4');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','subject','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','subject','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','subject','sakai:maxCardinality','2147483647');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','subject','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','subject','sakai:ris_identifier','KW');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('electronic','sakai:hasField','subject');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','creator','sakai:hasOrder','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','creator','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','creator','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','creator','sakai:maxCardinality','2147483647');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','creator','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','creator','sakai:ris_identifier','AU');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','sakai:hasField','creator');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','title','sakai:hasOrder','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','title','sakai:required','true');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','title','sakai:minCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','title','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','title','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','title','sakai:ris_identifier','CT');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','sakai:hasField','title');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','year','sakai:hasOrder','2');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','year','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','year','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','year','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','year','sakai:valueType','number');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','year','sakai:ris_identifier','PY');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','sakai:hasField','year');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','publisher','sakai:hasOrder','3');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','publisher','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','publisher','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','publisher','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','publisher','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','publisher','sakai:ris_identifier','PB');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','sakai:hasField','publisher');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','pages','sakai:hasOrder','4');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','pages','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','pages','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','pages','sakai:maxCardinality','1');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','pages','sakai:valueType','number');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','pages','sakai:ris_identifier','SP');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','sakai:hasField','pages');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','note','sakai:hasOrder','5');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','note','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','note','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','note','sakai:maxCardinality','2147483647');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','note','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','note','sakai:ris_identifier','N1');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','sakai:hasField','note');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','subject','sakai:hasOrder','6');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','subject','sakai:required','false');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','subject','sakai:minCardinality','0');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','subject','sakai:maxCardinality','2147483647');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','subject','sakai:valueType','shorttext');
INSERT INTO CITATION_SCHEMA_FIELD (SCHEMA_ID, FIELD_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','subject','sakai:ris_identifier','KW');
INSERT INTO CITATION_SCHEMA (SCHEMA_ID, PROPERTY_NAME, PROPERTY_VALUE) VALUES('thesis','sakai:hasField','subject');

-- tables for SAK-13843: assignment - information display on triggers 


    create table ASN_AP_ITEM_ACCESS_T (
        ID bigint not null auto_increment,
        ITEM_ACCESS varchar(255),
        ASN_AP_ITEM_ID bigint not null,
        primary key (ID),
        unique (ITEM_ACCESS, ASN_AP_ITEM_ID)
    );

    create table ASN_AP_ITEM_T (
        ID bigint not null,
        ASSIGNMENT_ID varchar(255),
        TITLE varchar(255),
        TEXT text,
        RELEASE_DATE datetime,
        RETRACT_DATE datetime,
        HIDE bit,
        primary key (ID)
    );

    create table ASN_MA_ITEM_T (
        ID bigint not null,
        ASSIGNMENT_ID varchar(255),
        TEXT text,
        SHOW_TO integer,
        primary key (ID)
    );

    create table ASN_NOTE_ITEM_T (
        ID bigint not null auto_increment,
        ASSIGNMENT_ID varchar(255),
        NOTE text,
        CREATOR_ID varchar(255),
        SHARE_WITH integer,
        primary key (ID)
    );

    create table ASN_SUP_ATTACH_T (
        ID bigint not null auto_increment,
        ATTACHMENT_ID varchar(255),
        ASN_SUP_ITEM_ID bigint not null,
        primary key (ID),
        unique (ATTACHMENT_ID, ASN_SUP_ITEM_ID)
    ) comment='This table is for assignment supplement item attachment.';

    create table ASN_SUP_ITEM_T (
        ID bigint not null auto_increment,
        primary key (ID)
    );

    create index ASN_AP_ITEM_I on ASN_AP_ITEM_ACCESS_T (ASN_AP_ITEM_ID);

    alter table ASN_AP_ITEM_ACCESS_T 
        add index FK573733586E844C61 (ASN_AP_ITEM_ID), 
        add constraint FK573733586E844C61 
        foreign key (ASN_AP_ITEM_ID) 
        references ASN_AP_ITEM_T (ID);

    alter table ASN_AP_ITEM_T 
        add index FK514CEE15935EEE07 (ID), 
        add constraint FK514CEE15935EEE07 
        foreign key (ID) 
        references ASN_SUP_ITEM_T (ID);

    alter table ASN_MA_ITEM_T 
        add index FK2E508110935EEE07 (ID), 
        add constraint FK2E508110935EEE07 
        foreign key (ID) 
        references ASN_SUP_ITEM_T (ID);

    create index ASN_SUP_ITEM_I on ASN_SUP_ATTACH_T (ASN_SUP_ITEM_ID);

    alter table ASN_SUP_ATTACH_T 
        add index FK560294CEDE4CD07F (ASN_SUP_ITEM_ID), 
        add constraint FK560294CEDE4CD07F 
        foreign key (ASN_SUP_ITEM_ID) 
        references ASN_SUP_ITEM_T (ID);

-- SAK-7670 Add new table for delayed events

CREATE TABLE SAKAI_EVENT_DELAY
(
        EVENT_DELAY_ID BIGINT AUTO_INCREMENT,
        EVENT VARCHAR (32),
        REF VARCHAR (255),
        USER_ID VARCHAR (99),
        EVENT_CODE VARCHAR (1),
        PRIORITY SMALLINT,
        PRIMARY KEY (EVENT_DELAY_ID)
);

CREATE INDEX IE_SAKAI_EVENT_DELAY_RESOURCE ON SAKAI_EVENT_DELAY
(
        REF ASC
);

-- SAK-13584 Further Improve the Performance of the Email Archive and Message API. Note you have to run a bash conversion script on your old mail archive data for it to
-- appear in the new mail archive. The script is in the source as mailarchive-runconversion.sh. Please see the SAK for more information on this script or SAK-16554 for
-- updates to this script. 

ALTER TABLE MAILARCHIVE_MESSAGE ADD COLUMN (
       SUBJECT           VARCHAR (255) NULL,
       BODY              LONGTEXT NULL
);

-- SAK-16809 Index order wrong
CREATE INDEX IE_MAILARC_SUBJECT ON MAILARCHIVE_MESSAGE
(
       SUBJECT                   ASC
);

-- SAK-11096 asn.share.drafts is a newly added permission

INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'asn.share.drafts');
