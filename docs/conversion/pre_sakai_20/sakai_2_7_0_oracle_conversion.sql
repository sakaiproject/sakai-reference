-- This is the Oracle Sakai 2.6.x -> 2.7.0 conversion script
-- --------------------------------------------------------------------------------------------------------------------------------------
-- 
-- use this to convert a Sakai database from 2.6.x to 2.7.0.  Run this before you run your first app server.
-- auto.ddl does not need to be enabled in your app server - this script takes care of all new TABLEs, changed TABLEs, and changed data.
--
-- Script insertion format
-- -- [TICKET] [short comment]
-- -- [comment continued] (repeat as necessary)
-- SQL statement
-- --------------------------------------------------------------------------------------------------------------------------------------

-- SAK-16610 introduced a new osp presentation review permission
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.presentation.review');

-- SAK-16686/KNL-241 Support exceptions to dynamic page localization
INSERT INTO SAKAI_SITE_PAGE_PROPERTY VALUES ('~admin','~admin-400','sitePage.customTitle','true');

-- SAK-16832
ALTER TABLE SAM_PUBLISHEDASSESSMENT_T ADD LASTNEEDRESUBMITDATE timestamp NULL;

-- SAK-16880 collaborative portfolio editing
ALTER TABLE osp_presentation ADD isCollab number(1,0) DEFAULT 0 NOT NULL;

-- SAK-17447
alter table EMAIL_TEMPLATE_ITEM add HTMLMESSAGE clob; 

-- SAK-16984 new column in sakai-Person
alter TABLE SAKAI_PERSON_T add NORMALIZEDMOBILE varchar2(255) NULL;

-- SAK-15165 new fields for SakaiPerson
alter table SAKAI_PERSON_T add FAVOURITE_BOOKS varchar2(4000); 
alter table SAKAI_PERSON_T add FAVOURITE_TV_SHOWS varchar2(4000); 
alter table SAKAI_PERSON_T add FAVOURITE_MOVIES varchar2(4000); 
alter table SAKAI_PERSON_T add FAVOURITE_QUOTES varchar2(4000); 
alter table SAKAI_PERSON_T add EDUCATION_COURSE varchar2(4000); 
alter table SAKAI_PERSON_T add EDUCATION_SUBJECTS varchar2(4000);

-- SAK-17485/SAK-10559
alter table MFR_MESSAGE_T add NUM_READERS int;
update MFR_MESSAGE_T set NUM_READERS = 0; 

-- SAK-15710
ALTER TABLE osp_wizard_page_def 
  ADD (defaultCustomForm number(1,0), defaultReflectionForm number(1,0), defaultFeedbackForm number(1,0), 
  defaultReviewers number(1,0), defaultEvaluationForm number(1,0), defaultEvaluators number(1,0));
UPDATE osp_wizard_page_def 
  SET defaultCustomForm = 0, defaultReflectionForm = 0, defaultFeedbackForm = 0, 
  defaultReviewers = 0, defaultEvaluationForm = 0, defaultEvaluators = 0;

ALTER TABLE osp_scaffolding ADD (allowRequestFeedback number(1,0));
UPDATE osp_scaffolding SET allowRequestFeedback = 0;

ALTER TABLE osp_scaffolding ADD (hideEvaluations number(1,0));
UPDATE osp_scaffolding SET hideEvaluations = 0;

ALTER TABLE osp_wizard_page_def ADD (allowRequestFeedback number(1,0));
UPDATE osp_wizard_page_def SET allowRequestFeedback = 0;

ALTER TABLE osp_wizard_page_def ADD (hideEvaluations number(1,0));
UPDATE osp_wizard_page_def SET hideEvaluations = 0;

ALTER TABLE osp_scaffolding Drop column reviewerGroupAccess;

ALTER TABLE osp_scaffolding ADD (defaultFormsMatrixVersion number(1,0));
UPDATE osp_scaffolding SET defaultFormsMatrixVersion = 1;

alter table osp_scaffolding add (returnedColor varchar2(7), modifiedDate timestamp);
update osp_scaffolding set returnedColor = '';

create table osp_scaffolding_attachments (
        id varchar2(36) not null,
        artifact_id varchar2(255),
        seq_num number(10,0) not null,
        primary key (id, seq_num)
    );
    
alter table osp_scaffolding_attachments
    add ( constraint FK529713EAE023FB45
	foreign key(id)
	references osp_scaffolding(id));
	
create index FK529713EAE023FB45 on osp_scaffolding_attachments(id);	

create table osp_scaffolding_form_defs (
        id varchar2(36) not null,
        form_def_id varchar2(255),
        seq_num number(10,0) not null,
        primary key (id, seq_num)
    );
    
alter table osp_scaffolding_form_defs
    add ( constraint FK95431263E023FB45
	foreign key(id)
	references osp_scaffolding(id));
	
create index FK95431263E023FB45 on osp_scaffolding_form_defs(id);
    
create table SITEASSOC_CONTEXT_ASSOCIATION (
		FROM_CONTEXT varchar2(99 char) not null, 
		TO_CONTEXT varchar2(99 char) not null, 
		VERSION number(10,0) not null, 
		primary key (FROM_CONTEXT, TO_CONTEXT)
	);

alter table osp_wizard_page_def add (type varchar2(1) default '0');

update osp_wizard_page_def set type = '0' where id in (
select distinct s.wiz_page_def_id From osp_scaffolding_cell s );

update osp_wizard_page_def set type = '1' where id in (
select distinct wps.wiz_page_def_id
From osp_wizard w
join osp_wizard_category wc on wc.wizard_id = w.id
join osp_wizard_page_sequence wps on wps.category_id = wc.id
where w.wizard_type = 'org.theospi.portfolio.wizard.model.Wizard.hierarchical'
);

update osp_wizard_page_def set type = '2' where id in (
select distinct wps.wiz_page_def_id 
From osp_wizard w
join osp_wizard_category wc on wc.wizard_id = w.id
join osp_wizard_page_sequence wps on wps.category_id = wc.id
where w.wizard_type = 'org.theospi.portfolio.wizard.model.Wizard.sequential'
);

-- since scaffolding are now extending osp_workflow_parent
insert into OSP_WORKFLOW_PARENT select s.id, null, null, null, null, null, null from osp_scaffolding s where s.id not in (select wp.id from osp_workflow_parent wp);

-- Move the use permission from site to each newly created scaffolding realms and delete the old osp.matrix.scaffolding.use permissions --
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffolding.revise.any');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffolding.revise.own');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffolding.delete.any');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffolding.delete.own');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffolding.publish.any');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffolding.publish.own');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffolding.export.any');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffolding.export.own');

INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffoldingSpecific.accessAll');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffoldingSpecific.viewEvalOther');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffoldingSpecific.viewFeedbackOther');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffoldingSpecific.manageStatus');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffoldingSpecific.accessUserList');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffoldingSpecific.viewAllGroups');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.matrix.scaffoldingSpecific.use');

INSERT INTO SAKAI_REALM VALUES (SAKAI_REALM_SEQ.NEXTVAL, '!matrix.template.portfolio', '', NULL, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessAll'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewEvalOther'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewFeedbackOther'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.manageStatus'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessUserList'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewAllGroups'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Evaluator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessUserList'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Reviewer'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessUserList'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Participant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.use'));

INSERT INTO SAKAI_REALM VALUES (SAKAI_REALM_SEQ.NEXTVAL, '!matrix.template.course', '', NULL, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessAll'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewEvalOther'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewFeedbackOther'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.manageStatus'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessUserList'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewAllGroups'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessAll'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewEvalOther'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewFeedbackOther'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.manageStatus'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessUserList'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewAllGroups'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.use'));

INSERT INTO SAKAI_REALM VALUES (SAKAI_REALM_SEQ.NEXTVAL, '!matrix.template.project', '', NULL, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.project'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessAll'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.project'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewEvalOther'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.project'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewFeedbackOther'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.project'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.manageStatus'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.project'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.accessUserList'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.project'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.viewAllGroups'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!matrix.template.project'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'access'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.use'));

INSERT INTO SAKAI_REALM (REALM_KEY, REALM_ID, PROVIDER_ID, MAINTAIN_ROLE, CREATEDBY, MODIFIEDBY, CREATEDON, MODIFIEDON) 
(select SAKAI_REALM_SEQ.NEXTVAL, concat('/scaffolding/', concat(worksiteId, concat('/', id))) as new_realm_id, '', NULL, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP from osp_scaffolding);

insert into SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
select distinct sr.REALM_KEY, srrf.ROLE_KEY, (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffoldingSpecific.use')
from sakai_realm sr, osp_scaffolding os, SAKAI_REALM_RL_FN srrf 
where sr.REALM_ID = concat('/scaffolding/', concat(os.WORKSITEID, concat('/', os.id)))  
and srrf.FUNCTION_KEY = (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.scaffolding.use')
and srrf.REALM_KEY = (select REALM_KEY from SAKAI_REALM Where REALM_ID = concat('/site/', os.worksiteid));

-- delete from SAKAI_REALM_RL_FN where function_key = (select function_key From SAKAI_REALM_FUNCTION where function_name = 'osp.matrix.scaffolding.use');
-- delete From SAKAI_REALM_FUNCTION where function_name = 'osp.matrix.scaffolding.use';

create table permissions_backfill_src_temp (function_name varchar2(99), TYPE INTEGER);
CREATE TABLE permissions_backfill_temp (FUNCTION_KEY INTEGER, TYPE INTEGER);

INSERT INTO permissions_backfill_src_temp values ('osp.matrix.scaffoldingSpecific.accessAll', 1);
INSERT INTO permissions_backfill_src_temp values ('osp.matrix.scaffoldingSpecific.viewEvalOther', 1);
INSERT INTO permissions_backfill_src_temp values ('osp.matrix.scaffoldingSpecific.viewFeedbackOther', 1);
INSERT INTO permissions_backfill_src_temp values ('osp.matrix.scaffoldingSpecific.accessUserList', 1);
INSERT INTO permissions_backfill_src_temp values ('osp.matrix.scaffoldingSpecific.accessAll', 2);
INSERT INTO permissions_backfill_src_temp values ('osp.matrix.scaffoldingSpecific.viewFeedbackOther', 2);
INSERT INTO permissions_backfill_src_temp values ('osp.matrix.scaffoldingSpecific.accessUserList', 2);

insert into permissions_backfill_temp
select rf.function_key, pbst.type 
from SAKAI_REALM_FUNCTION rf
join permissions_backfill_src_temp pbst on (pbst.function_name = rf.FUNCTION_NAME);

insert into SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
select distinct sr.REALM_KEY, srrf.ROLE_KEY, pbt.FUNCTION_KEY
from sakai_realm sr, osp_scaffolding os, SAKAI_REALM_RL_FN srrf, permissions_backfill_temp pbt
where sr.REALM_ID = concat('/scaffolding/', concat(os.WORKSITEID, concat('/', os.id))) 
and srrf.FUNCTION_KEY = (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.evaluate')
and srrf.REALM_KEY = (select REALM_KEY from SAKAI_REALM Where REALM_ID = concat('/site/', os.worksiteid))
and pbt.TYPE = 1
and not exists (select 1 from SAKAI_REALM_RL_FN rrf_tmp where rrf_tmp.REALM_KEY = sr.REALM_KEY and rrf_tmp.ROLE_KEY = srrf.ROLE_KEY and rrf_tmp.FUNCTION_KEY = pbt.FUNCTION_KEY);

insert into SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
select distinct sr.REALM_KEY, srrf.ROLE_KEY, pbt.FUNCTION_KEY
from sakai_realm sr, osp_scaffolding os, SAKAI_REALM_RL_FN srrf, permissions_backfill_temp pbt
where sr.REALM_ID = concat('/scaffolding/', concat(os.WORKSITEID, concat('/', os.id))) 
and srrf.FUNCTION_KEY = (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'osp.matrix.review')
and srrf.REALM_KEY = (select REALM_KEY from SAKAI_REALM Where REALM_ID = concat('/site/', os.worksiteid))
and pbt.TYPE = 2
and not exists (select 1 from SAKAI_REALM_RL_FN rrf_tmp where rrf_tmp.REALM_KEY = sr.REALM_KEY and rrf_tmp.ROLE_KEY = srrf.ROLE_KEY and rrf_tmp.FUNCTION_KEY = pbt.FUNCTION_KEY);

drop table permissions_backfill_src_temp;
drop table permissions_backfill_temp;
-- END

-- Backfill sites
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));
CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);

INSERT INTO PERMISSIONS_SRC_TEMP values ('Instructor','osp.matrix.scaffoldingSpecific.manageStatus');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Instructor','osp.matrix.scaffoldingSpecific.viewAllGroups');

INSERT INTO PERMISSIONS_SRC_TEMP values ('CIG Coordinator','osp.matrix.scaffoldingSpecific.manageStatus');
INSERT INTO PERMISSIONS_SRC_TEMP values ('CIG Coordinator','osp.matrix.scaffoldingSpecific.viewAllGroups');

INSERT INTO PERMISSIONS_SRC_TEMP values ('Project Owner','osp.matrix.scaffoldingSpecific.manageStatus');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Project Owner','osp.matrix.scaffoldingSpecific.viewAllGroups');

INSERT INTO PERMISSIONS_SRC_TEMP values ('Teaching Assistant','osp.matrix.scaffoldingSpecific.manageStatus');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Teaching Assistant','osp.matrix.scaffoldingSpecific.viewAllGroups');

INSERT INTO PERMISSIONS_SRC_TEMP values ('maintain','osp.matrix.scaffoldingSpecific.manageStatus');
INSERT INTO PERMISSIONS_SRC_TEMP values ('maintain','osp.matrix.scaffoldingSpecific.viewAllGroups');

INSERT INTO PERMISSIONS_SRC_TEMP values ('Teaching Assistant','osp.matrix.scaffoldingSpecific.manageStatus');
INSERT INTO PERMISSIONS_SRC_TEMP values ('Teaching Assistant','osp.matrix.scaffoldingSpecific.viewAllGroups');

-- Lookup the role and function keys
insert into PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
select SRR.ROLE_KEY, SRF.FUNCTION_KEY
from PERMISSIONS_SRC_TEMP TMPSRC
join SAKAI_REALM_ROLE SRR on (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
join SAKAI_REALM_FUNCTION SRF on (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

-- Insert the new functions into the roles of any existing realm that has the role (don't convert the "!site.helper" or any group realms)
insert into SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
select
    SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
from
    (select distinct SRRF.REALM_KEY, SRRF.ROLE_KEY from SAKAI_REALM_RL_FN SRRF) SRRFD
    join PERMISSIONS_TEMP TMP on (SRRFD.ROLE_KEY = TMP.ROLE_KEY)
    join SAKAI_REALM SR on (SRRFD.REALM_KEY = SR.REALM_KEY)
    where SR.REALM_ID like '/scaffolding/%'
   and not exists (
        select 1
            from SAKAI_REALM_RL_FN SRRFI
            where SRRFI.REALM_KEY=SRRFD.REALM_KEY and SRRFI.ROLE_KEY=SRRFD.ROLE_KEY and  SRRFI.FUNCTION_KEY=TMP.FUNCTION_KEY
    );

-- clean up the temp tables to use again for group permissions
drop table PERMISSIONS_TEMP;
drop table PERMISSIONS_SRC_TEMP;

CREATE TABLE permissions_convertl_temp (OLD_FUNCTION_KEY INTEGER, OLD_FUNCTION_NAME VARCHAR2(99), FUNCTION_KEY INTEGER, FUNCTION_NAME VARCHAR2(99));

INSERT INTO permissions_convertl_temp
select rf.FUNCTION_KEY, rf.FUNCTION_NAME, rf2.FUNCTION_KEY, rf2.FUNCTION_NAME 
from SAKAI_REALM_FUNCTION rf, SAKAI_REALM_FUNCTION rf2 
where rf.FUNCTION_NAME = 'osp.matrix.scaffolding.edit' and (rf2.function_name = 'osp.matrix.scaffolding.revise.any' or rf2.function_name = 'osp.matrix.scaffolding.revise.own');

INSERT INTO permissions_convertl_temp
select rf.FUNCTION_KEY, rf.FUNCTION_NAME, rf2.FUNCTION_KEY, rf2.FUNCTION_NAME 
from SAKAI_REALM_FUNCTION rf, SAKAI_REALM_FUNCTION rf2 
where rf.FUNCTION_NAME = 'osp.matrix.scaffolding.delete' and (rf2.function_name = 'osp.matrix.scaffolding.delete.any' or rf2.function_name = 'osp.matrix.scaffolding.delete.own');

INSERT INTO permissions_convertl_temp
select rf.FUNCTION_KEY, rf.FUNCTION_NAME, rf2.FUNCTION_KEY, rf2.FUNCTION_NAME 
from SAKAI_REALM_FUNCTION rf, SAKAI_REALM_FUNCTION rf2 
where rf.FUNCTION_NAME = 'osp.matrix.scaffolding.export' and (rf2.function_name = 'osp.matrix.scaffolding.export.any' or rf2.function_name = 'osp.matrix.scaffolding.export.own');

INSERT INTO permissions_convertl_temp
select rf.FUNCTION_KEY, rf.FUNCTION_NAME, rf2.FUNCTION_KEY, rf2.FUNCTION_NAME 
from SAKAI_REALM_FUNCTION rf, SAKAI_REALM_FUNCTION rf2 
where rf.FUNCTION_NAME = 'osp.matrix.scaffolding.publish' and (rf2.function_name = 'osp.matrix.scaffolding.publish.any' or rf2.function_name = 'osp.matrix.scaffolding.publish.own');

insert into SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
select distinct srrf.REALM_KEY, srrf.ROLE_KEY, pct.function_key
from SAKAI_REALM_RL_FN srrf
join permissions_convertl_temp pct on (srrf.FUNCTION_KEY = pct.old_function_key);

drop table permissions_convertl_temp;

INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'osp.portfolio.evaluation.use');

update SAKAI_REALM_RL_FN set FUNCTION_KEY = (select function_key from SAKAI_REALM_FUNCTION where function_name = 'osp.portfolio.evaluation.use')
where function_key = (select function_key From SAKAI_REALM_FUNCTION where function_name = 'osp.matrix.evaluate');

-- backfill for new returned status
create table tmp_workflow_guid_map (old_id varchar2(99), new_id varchar2(99), 
  parent_id varchar2(99), old_status varchar2(99), new_status varchar2(99));

insert into tmp_workflow_guid_map select id, sys_guid(), parent_id, 'READY', 'RETURNED' from OSP_WORKFLOW where title = 'Return Workflow';

delete From tmp_workflow_guid_map where PARENT_ID in (
select distinct parent_id from osp_workflow where title = 'Returned Workflow');

insert into osp_workflow
select NEW_ID, 'Returned Workflow', parent_id from tmp_workflow_guid_map;

insert into osp_workflow_item
select sys_guid(), owi.actiontype, owi.action_object_id, t.new_status, t.new_id 
from osp_workflow_item owi
join tmp_workflow_guid_map t on (t.old_id = owi.WORKFLOW_ID and t.old_status = owi.ACTION_VALUE);

insert into osp_workflow_item
select sys_guid(), owi.actiontype, owi.action_object_id, owi.action_value, t.new_id 
from osp_workflow_item owi
join tmp_workflow_guid_map t on (t.old_id = owi.WORKFLOW_ID)
where t.old_status <> owi.ACTION_VALUE;

drop table tmp_workflow_guid_map;
-- end backfill for returned status
-- END SAK-15710

-- SAK-16835 columns for new quartz version
alter table QRTZ_TRIGGERS add PRIORITY number(13) NULL;
alter table QRTZ_FIRED_TRIGGERS add PRIORITY number(13) NOT NULL;

-- SAK-16835 migrate existing triggers to have default value
-- see http://www.opensymphony.com/quartz/wikidocs/Quartz%201.6.0.html
update QRTZ_TRIGGERS set PRIORITY = 5 where PRIORITY IS NULL;
update QRTZ_FIRED_TRIGGERS set PRIORITY = 5 where PRIORITY IS NULL; 

-- START SiteStats 2.1 (SAK-17773)
-- IMPORTANT: Installations with previous (contrib) versions of SiteStats deployed should
--            comment out lines below and consult this url for possible conversion upgrades:
--            https://source.sakaiproject.org/svn/sitestats/trunk/updating/
-- NOTE:      There is no DB conversion required from SiteStats 2.0 -> 2.1
create table SST_EVENTS (ID number(19,0) not null, USER_ID varchar2(99 char) not null, SITE_ID varchar2(99 char) not null, EVENT_ID varchar2(32 char) not null, EVENT_DATE date not null, EVENT_COUNT number(19,0) not null, primary key (ID));
create table SST_JOB_RUN (ID number(19,0) not null, JOB_START_DATE timestamp, JOB_END_DATE timestamp, START_EVENT_ID number(19,0), END_EVENT_ID number(19,0), LAST_EVENT_DATE timestamp, primary key (ID));
create table SST_PREFERENCES (ID number(19,0) not null, SITE_ID varchar2(99 char) not null, PREFS clob not null, primary key (ID));
create table SST_REPORTS (ID number(19,0) not null, SITE_ID varchar2(99 char), TITLE varchar2(255 char) not null, DESCRIPTION clob, HIDDEN number(1,0), REPORT_DEF clob not null, CREATED_BY varchar2(99 char) not null, CREATED_ON timestamp not null, MODIFIED_BY varchar2(99 char), MODIFIED_ON timestamp, primary key (ID));
create table SST_RESOURCES (ID number(19,0) not null, USER_ID varchar2(99 char) not null, SITE_ID varchar2(99 char) not null, RESOURCE_REF varchar2(255 char) not null, RESOURCE_ACTION varchar2(12 char) not null, RESOURCE_DATE date not null, RESOURCE_COUNT number(19,0) not null, primary key (ID));
create table SST_SITEACTIVITY (ID number(19,0) not null, SITE_ID varchar2(99 char) not null, ACTIVITY_DATE date not null, EVENT_ID varchar2(32 char) not null, ACTIVITY_COUNT number(19,0) not null, primary key (ID));
create table SST_SITEVISITS (ID number(19,0) not null, SITE_ID varchar2(99 char) not null, VISITS_DATE date not null, TOTAL_VISITS number(19,0) not null, TOTAL_UNIQUE number(19,0) not null, primary key (ID));
create index SST_EVENTS_SITE_ID_IX on SST_EVENTS (SITE_ID);
create index SST_EVENTS_EVENT_ID_IX on SST_EVENTS (EVENT_ID);
create index SST_EVENTS_DATE_IX on SST_EVENTS (EVENT_DATE);
create index SST_PREFERENCES_SITE_ID_IX on SST_PREFERENCES (SITE_ID);
create index SST_REPORTS_SITE_ID_IX on SST_REPORTS (SITE_ID);
create index SST_RESOURCES_DATE_IX on SST_RESOURCES (RESOURCE_DATE);
create index SST_RESOURCES_RES_ACT_IDX on SST_RESOURCES (RESOURCE_ACTION);
create index SST_RESOURCES_USER_ID_IX on SST_RESOURCES (USER_ID);
create index SST_RESOURCES_SITE_ID_IX on SST_RESOURCES (SITE_ID);
create index SST_SITEACTIVITY_DATE_IX on SST_SITEACTIVITY (ACTIVITY_DATE);
create index SST_SITEACTIVITY_EVENT_ID_IX on SST_SITEACTIVITY (EVENT_ID);
create index SST_SITEACTIVITY_SITE_ID_IX on SST_SITEACTIVITY (SITE_ID);
create index SST_SITEVISITS_SITE_ID_IX on SST_SITEVISITS (SITE_ID);
create index SST_SITEVISITS_DATE_IX on SST_SITEVISITS (VISITS_DATE);
create index SST_EVENTS_SITEEVENTUSER_ID_IX on SST_EVENTS (SITE_ID,EVENT_ID,USER_ID);
create sequence SST_EVENTS_ID;
create sequence SST_JOB_RUN_ID;
create sequence SST_PREFERENCES_ID;
create sequence SST_REPORTS_ID;
create sequence SST_RESOURCES_ID;
create sequence SST_SITEACTIVITY_ID;
create sequence SST_SITEVISITS_ID;

-- OPTIONAL: Preload with default reports (STAT-35)
--   0) Activity total (Show activity in site, with totals per event.)
insert into SST_REPORTS (ID,SITE_ID,TITLE,DESCRIPTION,HIDDEN,REPORT_DEF,CREATED_BY,CREATED_ON,MODIFIED_BY,MODIFIED_ON) values (SST_REPORTS_ID.NEXTVAL,NULL,'${predefined_report0_title}','${predefined_report0_description}',0,'<?xml version=''1.0'' ?><ReportParams><howChartCategorySource>none</howChartCategorySource><howChartSeriesSource>total</howChartSeriesSource><howChartSource>event</howChartSource><howChartType>pie</howChartType><howLimitedMaxResults>false</howLimitedMaxResults><howMaxResults>0</howMaxResults><howPresentationMode>how-presentation-both</howPresentationMode><howSort>true</howSort><howSortAscending>true</howSortAscending><howSortBy>event</howSortBy><howTotalsBy><howTotalsBy>event</howTotalsBy></howTotalsBy><siteId/><what>what-events</what><whatEventIds/><whatEventSelType>what-events-bytool</whatEventSelType><whatLimitedAction>false</whatLimitedAction><whatLimitedResourceIds>false</whatLimitedResourceIds><whatResourceAction>new</whatResourceAction><whatResourceIds/><whatToolIds><whatToolIds>all</whatToolIds></whatToolIds><when>when-all</when><whenFrom/><whenTo/><who>who-all</who><whoGroupId/><whoRoleId>access</whoRoleId><whoUserIds/></ReportParams>','preload',(SELECT current_date FROM dual),'preload',(SELECT current_date FROM dual));
--   1) Most accessed files (Show top 10 most accessed files.)
insert into SST_REPORTS (ID,SITE_ID,TITLE,DESCRIPTION,HIDDEN,REPORT_DEF,CREATED_BY,CREATED_ON,MODIFIED_BY,MODIFIED_ON) values (SST_REPORTS_ID.NEXTVAL,NULL,'${predefined_report1_title}','${predefined_report1_description}',0,'<?xml version=''1.0'' ?><ReportParams><howChartCategorySource>none</howChartCategorySource><howChartSeriesSource>total</howChartSeriesSource><howChartSource>resource</howChartSource><howChartType>pie</howChartType><howLimitedMaxResults>true</howLimitedMaxResults><howMaxResults>10</howMaxResults><howPresentationMode>how-presentation-both</howPresentationMode><howSort>true</howSort><howSortAscending>false</howSortAscending><howSortBy>total</howSortBy><howTotalsBy><howTotalsBy>resource</howTotalsBy></howTotalsBy><siteId/><what>what-resources</what><whatEventIds/><whatEventSelType>what-events-bytool</whatEventSelType><whatLimitedAction>true</whatLimitedAction><whatLimitedResourceIds>false</whatLimitedResourceIds><whatResourceAction>read</whatResourceAction><whatResourceIds/><whatToolIds><whatToolIds>all</whatToolIds></whatToolIds><when>when-all</when><whenFrom/><whenTo/><who>who-all</who><whoGroupId/><whoRoleId>access</whoRoleId><whoUserIds/></ReportParams>','preload',(SELECT current_date FROM dual),'preload',(SELECT current_date FROM dual));
--   2) Most active users (Show top 10 users with most activity in site.)
insert into SST_REPORTS (ID,SITE_ID,TITLE,DESCRIPTION,HIDDEN,REPORT_DEF,CREATED_BY,CREATED_ON,MODIFIED_BY,MODIFIED_ON) values (SST_REPORTS_ID.NEXTVAL,NULL,'${predefined_report2_title}','${predefined_report2_description}',0,'<?xml version=''1.0'' ?><ReportParams><howChartCategorySource>none</howChartCategorySource><howChartSeriesSource>total</howChartSeriesSource><howChartSource>user</howChartSource><howChartType>pie</howChartType><howLimitedMaxResults>true</howLimitedMaxResults><howMaxResults>10</howMaxResults><howPresentationMode>how-presentation-both</howPresentationMode><howSort>true</howSort><howSortAscending>false</howSortAscending><howSortBy>total</howSortBy><howTotalsBy><howTotalsBy>user</howTotalsBy></howTotalsBy><siteId/><what>what-events</what><whatEventIds/><whatEventSelType>what-events-bytool</whatEventSelType><whatLimitedAction>false</whatLimitedAction><whatLimitedResourceIds>false</whatLimitedResourceIds><whatResourceAction>new</whatResourceAction><whatResourceIds/><whatToolIds><whatToolIds>all</whatToolIds></whatToolIds><when>when-all</when><whenFrom/><whenTo/><who>who-all</who><whoGroupId/><whoRoleId>access</whoRoleId><whoUserIds/></ReportParams>','preload',(SELECT current_date FROM dual),'preload',(SELECT current_date FROM dual));
--   3) Less active users (Show top 10 users with less activity in site.)
insert into SST_REPORTS (ID,SITE_ID,TITLE,DESCRIPTION,HIDDEN,REPORT_DEF,CREATED_BY,CREATED_ON,MODIFIED_BY,MODIFIED_ON) values (SST_REPORTS_ID.NEXTVAL,NULL,'${predefined_report3_title}','${predefined_report3_description}',0,'<?xml version=''1.0'' ?><ReportParams><howChartCategorySource>none</howChartCategorySource><howChartSeriesSource>total</howChartSeriesSource><howChartSource>user</howChartSource><howChartType>bar</howChartType><howLimitedMaxResults>false</howLimitedMaxResults><howMaxResults>0</howMaxResults><howPresentationMode>how-presentation-both</howPresentationMode><howSort>true</howSort><howSortAscending>true</howSortAscending><howSortBy>total</howSortBy><howTotalsBy><howTotalsBy>user</howTotalsBy></howTotalsBy><siteId/><what>what-events</what><whatEventIds/><whatEventSelType>what-events-bytool</whatEventSelType><whatLimitedAction>false</whatLimitedAction><whatLimitedResourceIds>false</whatLimitedResourceIds><whatResourceAction>new</whatResourceAction><whatResourceIds/><whatToolIds><whatToolIds>all</whatToolIds></whatToolIds><when>when-all</when><whenFrom/><whenTo/><who>who-all</who><whoGroupId/><whoRoleId>access</whoRoleId><whoUserIds/></ReportParams>','preload',(SELECT current_date FROM dual),'preload',(SELECT current_date FROM dual));
--   4) Users with more visits (Show top 10 users who have most visited the site.)
insert into SST_REPORTS (ID,SITE_ID,TITLE,DESCRIPTION,HIDDEN,REPORT_DEF,CREATED_BY,CREATED_ON,MODIFIED_BY,MODIFIED_ON) values (SST_REPORTS_ID.NEXTVAL,NULL,'${predefined_report4_title}','${predefined_report4_description}',0,'<?xml version=''1.0'' ?><ReportParams><howChartCategorySource>none</howChartCategorySource><howChartSeriesSource>total</howChartSeriesSource><howChartSource>user</howChartSource><howChartType>bar</howChartType><howLimitedMaxResults>false</howLimitedMaxResults><howMaxResults>0</howMaxResults><howPresentationMode>how-presentation-both</howPresentationMode><howSort>true</howSort><howSortAscending>false</howSortAscending><howSortBy>total</howSortBy><howTotalsBy><howTotalsBy>user</howTotalsBy></howTotalsBy><siteId/><what>what-visits</what><whatEventIds/><whatEventSelType>what-events-bytool</whatEventSelType><whatLimitedAction>false</whatLimitedAction><whatLimitedResourceIds>false</whatLimitedResourceIds><whatResourceAction>new</whatResourceAction><whatResourceIds/><whatToolIds><whatToolIds>all</whatToolIds></whatToolIds><when>when-all</when><whenFrom/><whenTo/><who>who-all</who><whoGroupId/><whoRoleId>access</whoRoleId><whoUserIds/></ReportParams>','preload',(SELECT current_date FROM dual),'preload',(SELECT current_date FROM dual));
--   5) Users with no visits (Show users who have never visited the site.)
insert into SST_REPORTS (ID,SITE_ID,TITLE,DESCRIPTION,HIDDEN,REPORT_DEF,CREATED_BY,CREATED_ON,MODIFIED_BY,MODIFIED_ON) values (SST_REPORTS_ID.NEXTVAL,NULL,'${predefined_report5_title}','${predefined_report5_description}',0,'<?xml version=''1.0'' ?><ReportParams><howChartCategorySource>none</howChartCategorySource><howChartSeriesSource>total</howChartSeriesSource><howChartSource>event</howChartSource><howChartType>bar</howChartType><howLimitedMaxResults>false</howLimitedMaxResults><howMaxResults>0</howMaxResults><howPresentationMode>how-presentation-table</howPresentationMode><howSort>false</howSort><howSortAscending>false</howSortAscending><howSortBy>default</howSortBy><howTotalsBy><howTotalsBy>user</howTotalsBy></howTotalsBy><siteId/><what>what-visits</what><whatEventIds/><whatEventSelType>what-events-bytool</whatEventSelType><whatLimitedAction>false</whatLimitedAction><whatLimitedResourceIds>false</whatLimitedResourceIds><whatResourceAction>new</whatResourceAction><whatResourceIds/><whatToolIds><whatToolIds>all</whatToolIds></whatToolIds><when>when-all</when><whenFrom/><whenTo/><who>who-none</who><whoGroupId/><whoRoleId>access</whoRoleId><whoUserIds/></ReportParams>','preload',(SELECT current_date FROM dual),'preload',(SELECT current_date FROM dual));
--   6) Users with no activity (Show users with no activity in site.)
insert into SST_REPORTS (ID,SITE_ID,TITLE,DESCRIPTION,HIDDEN,REPORT_DEF,CREATED_BY,CREATED_ON,MODIFIED_BY,MODIFIED_ON) values (SST_REPORTS_ID.NEXTVAL,NULL,'${predefined_report6_title}','${predefined_report6_description}',0,'<?xml version=''1.0'' ?><ReportParams><howChartCategorySource>none</howChartCategorySource><howChartSeriesPeriod>byday</howChartSeriesPeriod><howChartSeriesSource>total</howChartSeriesSource><howChartSource>event</howChartSource><howChartType>bar</howChartType><howLimitedMaxResults>false</howLimitedMaxResults><howMaxResults>0</howMaxResults><howPresentationMode>how-presentation-table</howPresentationMode><howSort>false</howSort><howSortAscending>true</howSortAscending><howSortBy>default</howSortBy><howTotalsBy><howTotalsBy>user</howTotalsBy></howTotalsBy><siteId/><what>what-events</what><whatEventIds/><whatEventSelType>what-events-bytool</whatEventSelType><whatLimitedAction>false</whatLimitedAction><whatLimitedResourceIds>false</whatLimitedResourceIds><whatResourceAction>new</whatResourceAction><whatResourceIds/><whatToolIds><whatToolIds>all</whatToolIds></whatToolIds><when>when-all</when><whenFrom/><whenTo/><who>who-none</who><whoGroupId/><whoRoleId>access</whoRoleId><whoUserIds/></ReportParams>','preload',(SELECT current_date FROM dual),'preload',(SELECT current_date FROM dual));
-- END SiteStats 2.1 (SAK-17773)

-- START Profile2 1.3 (SAK-17773)
-- IMPORTANT: Installations with previous (contrib) versions of Profile2 deployed should
--            comment out lines below and consult this url for possible conversion upgrades:
--            https://source.sakaiproject.org/svn//profile2/branches/profile2-1.3.x/docs/database/oracle/
create table PROFILE_FRIENDS_T (
    ID number(19,0) not null,
    USER_UUID varchar2(99) not null,
    FRIEND_UUID varchar2(99) not null,
    RELATIONSHIP number(10,0) not null,
    REQUESTED_DATE date not null,
    CONFIRMED number(1,0) not null,
    CONFIRMED_DATE date,
    primary key (ID)
);

create table PROFILE_IMAGES_EXTERNAL_T (
    USER_UUID varchar2(99) not null,
    URL_MAIN varchar2(4000) not null,
    URL_THUMB varchar2(4000),
    primary key (USER_UUID)
);

create table PROFILE_IMAGES_T (
    ID number(19,0) not null,
    USER_UUID varchar2(99) not null,
    RESOURCE_MAIN varchar2(255) not null,
    RESOURCE_THUMB varchar2(255) not null,
    IS_CURRENT number(1,0) not null,
    primary key (ID)
);

create table PROFILE_PREFERENCES_T (
    USER_UUID varchar2(99) not null,
    EMAIL_REQUEST number(1,0) not null,
    EMAIL_CONFIRM number(1,0) not null,
    TWITTER_ENABLED number(1,0) not null,
    TWITTER_USERNAME varchar2(255),
    TWITTER_PASSWORD varchar2(255),
    primary key (USER_UUID)
);

create table PROFILE_PRIVACY_T (
    USER_UUID varchar2(99) not null,
    PROFILE_IMAGE number(10,0) not null,
    BASIC_INFO number(10,0) not null,
    CONTACT_INFO number(10,0) not null,
    ACADEMIC_INFO number(10,0) not null,
    PERSONAL_INFO number(10,0) not null,
    BIRTH_YEAR number(1,0) not null,
    SEARCH number(10,0) not null,
    MY_FRIENDS number(10,0) not null,
    MY_STATUS number(10,0) not null,
    primary key (USER_UUID)
);

create table PROFILE_STATUS_T (
    USER_UUID varchar2(99) not null,
    MESSAGE varchar2(255) not null,
    DATE_ADDED date not null,
    primary key (USER_UUID)
);

create table SAKAI_PERSON_META_T (
    ID number(19,0) not null,
    USER_UUID varchar2(99) not null,
    PROPERTY varchar2(255) not null,
    VALUE varchar2(255) not null,
    primary key (ID)
);

create index PROFILE_FRIENDS_FRIEND_UUID_I on PROFILE_FRIENDS_T (FRIEND_UUID);
create index PROFILE_FRIENDS_USER_UUID_I on PROFILE_FRIENDS_T (USER_UUID);
create index PROFILE_IMAGES_USER_UUID_I on PROFILE_IMAGES_T (USER_UUID);
create index PROFILE_IMAGES_IS_CURRENT_I on PROFILE_IMAGES_T (IS_CURRENT);
create sequence PROFILE_FRIENDS_S;
create sequence PROFILE_IMAGES_S;
create sequence SAKAI_PERSON_META_S;
create index SAKAI_PERSON_META_USER_UUID_I on SAKAI_PERSON_META_T (USER_UUID);
create index SAKAI_PERSON_META_PROPERTY_I on SAKAI_PERSON_META_T (PROPERTY);

-- Replace Profile by Profile2 for new and existing sites:
-- update SAKAI_SITE_TOOL set REGISTRATION='sakai.profile2' where REGISTRATION='sakai.profile';
-- Replace Profile by Profile2 only for new sites:
update SAKAI_SITE_TOOL set REGISTRATION='sakai.profile2' where REGISTRATION='sakai.profile' and SITE_ID='!user';
-- END Profile2 1.3 (SAK-17773)

-- SAK-11740 email notification of new posts to forum
-- You may need to run these drop commands if this table still exists in your db
-- DROP TABLE MFR_EMAIL_NOTIFICATION_TIF EXISTS;
-- drop sequence MFR_EMAIL_NOTIFICATION_S;

CREATE TABLE  "MFR_EMAIL_NOTIFICATION_T"
   (    "ID" NUMBER(19,0) NOT NULL ENABLE,
        "VERSION" NUMBER(10,0) NOT NULL ENABLE,
        "USER_ID" VARCHAR2(255 BYTE) NOT NULL ENABLE,
        "CONTEXT_ID" VARCHAR2(255 BYTE) NOT NULL ENABLE,
        "NOTIFICATION_LEVEL" VARCHAR2(1) NOT NULL ENABLE,
         PRIMARY KEY ("ID")
   );
   
CREATE INDEX "MFR_EMAIL_USER_ID_I" ON  "MFR_EMAIL_NOTIFICATION_T" ("USER_ID")  ;
CREATE INDEX  "MFR_EMAIL_CONTEXT_ID_I" ON  "MFR_EMAIL_NOTIFICATION_T" ("CONTEXT_ID") ;

create sequence MFR_EMAIL_NOTIFICATION_S;

-- SAK-15052 update cafe versions to 2.7.0-SNAPSHOT
alter table MFR_MESSAGE_T add THREADID NUMBER(20);
alter table MFR_MESSAGE_T add LASTTHREADATE TIMESTAMP;
alter table MFR_MESSAGE_T add LASTTHREAPOST NUMBER(20);

update MFR_MESSAGE_T set THREADID=IN_REPLY_TO,LASTTHREADATE=CREATED;

-- SAK-10869 displaying all messages should mark them as read

-- SAK-10869 add AutoMarkThreadsRead functionality to Message Center
-- add column to allow AutoMarkThreadsRead as template setting
alter table MFR_AREA_T add (AUTO_MARK_THREADS_READ NUMBER(1,0));
update MFR_AREA_T set AUTO_MARK_THREADS_READ=0 where AUTO_MARK_THREADS_READ is NULL;
alter table MFR_AREA_T modify (AUTO_MARK_THREADS_READ NUMBER(1,0) not null);

-- add column to allow AutoMarkThreadsRead to be set at the forum level
alter table MFR_OPEN_FORUM_T add (AUTO_MARK_THREADS_READ NUMBER(1,0));
update MFR_OPEN_FORUM_T set AUTO_MARK_THREADS_READ=0 where AUTO_MARK_THREADS_READ is NULL;
alter table MFR_OPEN_FORUM_T modify (AUTO_MARK_THREADS_READ NUMBER(1,0) not null);

-- add column to allow AutoMarkThreadsRead to be set at the topic level
alter table MFR_TOPIC_T add (AUTO_MARK_THREADS_READ NUMBER(1,0));
update MFR_TOPIC_T set AUTO_MARK_THREADS_READ=0 where AUTO_MARK_THREADS_READ is NULL;
alter table MFR_TOPIC_T modify (AUTO_MARK_THREADS_READ NUMBER(1,0) not null);

-- SAK-10559 view who has read a message
-- if MFR_MESSAGE_T is missing NUM_READERS, run alter and update commands
-- alter table MFR_MESSAGE_T add NUM_READERS int;
-- update MFR_MESSAGE_T set NUM_READERS = 0;

-- SAK-15655 rework MyWorkspace Synoptic view of Messages & Forums
create table MFR_SYNOPTIC_ITEM
(SYNOPTIC_ITEM_ID number(19,0) not null,
VERSION number(10,0) not null,
USER_ID varchar2(36 char) not null,
SITE_ID varchar2(99 char) not null,
SITE_TITLE varchar2(255 char),
NEW_MESSAGES_COUNT number(10,0),
MESSAGES_LAST_VISIT_DT timestamp,
NEW_FORUM_COUNT number(10,0),
FORUM_LAST_VISIT_DT timestamp,
HIDE_ITEM NUMBER(1,0),
primary key (SYNOPTIC_ITEM_ID),
unique (USER_ID, SITE_ID));

create sequence MFR_SYNOPTIC_ITEM_S;

create index MRF_SYN_USER on MFR_SYNOPTIC_ITEM (USER_ID);

-- MSGCNTR-177 MyWorkspace/Home does now show the Messages & Forums Notifications by default
update SAKAI_SITE_TOOL
Set TITLE = 'Unread Messages and Forums'
Where REGISTRATION = 'sakai.synoptic.messagecenter'; 

INSERT INTO SAKAI_SITE_TOOL VALUES('!user-145', '!user-100', '!user', 'sakai.synoptic.messagecenter', 2, 'Unread Messages and Forums', '1,1' );

create table MSGCNTR_TMP(
    PAGE_ID VARCHAR2(99),
    SITE_ID VARCHAR2(99)
);

insert into MSGCNTR_TMP
(   
    Select PAGE_ID, SITE_ID 
    from SAKAI_SITE_PAGE 
    where SITE_ID like '~%' 
    and TITLE = 'Home'
    and PAGE_ID not in (Select PAGE_ID from SAKAI_SITE_TOOL where REGISTRATION = 'sakai.synoptic.messagecenter')
);

insert into SAKAI_SITE_TOOL
(select SYS_GUID(), PAGE_ID, SITE_ID, 'sakai.synoptic.messagecenter', 2, 'Unread Messages and Forums', '1,1' from MSGCNTR_TMP);

drop table MSGCNTR_TMP;

-- MSGCNTR-25 .UIPermissionsManagerImpl - query did not return a unique result: 4 Error in catalina.out
alter table MFR_AREA_T add constraint MFR_AREA_CONTEXT_UUID_UNIQUE unique (CONTEXT_ID, TYPE_UUID);

-- MSGCNTR-148 unique constraint not created on MFR_PRIVATE_FORUM_T
-- If this alter query fails, use this select query to find duplicates and remove the duplicate:
-- select OWNER, surrogateKey, COUNT(OWNER) FROM MFR_PRIVATE_FORUM_T GROUP BY OWNER, surrogateKey HAVING COUNT(OWNER)>1;
-- CREATE UNIQUE INDEX MFR_PVT_FRM_OWNER ON  MFR_PRIVATE_FORUM_T (OWNER, surrogateKey); 

-- MSGCNTR-132 drop unused MC table columns
ALTER TABLE MFR_MESSAGE_T
DROP COLUMN GRADEBOOK;

ALTER TABLE MFR_MESSAGE_T
DROP COLUMN GRADEBOOK_ASSIGNMENT;

ALTER TABLE MFR_MESSAGE_T
DROP COLUMN GRADECOMMENT;

ALTER TABLE MFR_TOPIC_T
DROP COLUMN GRADEBOOK;

ALTER TABLE MFR_TOPIC_T
DROP COLUMN GRADEBOOK_ASSIGNMENT;

-- SAK-17428
alter table GB_CATEGORY_T
add (
	IS_EQUAL_WEIGHT_ASSNS number(1,0),
	IS_UNWEIGHTED number(1,0),
	CATEGORY_ORDER number(10,0),
	ENFORCE_POINT_WEIGHTING number(1,0)
);

alter table GB_GRADEBOOK_T
add (
	IS_EQUAL_WEIGHT_CATS number(1,0),
	IS_SCALED_EXTRA_CREDIT number(1,0),
	DO_SHOW_MEAN number(1,0),
	DO_SHOW_MEDIAN number(1,0),
	DO_SHOW_MODE number(1,0),
	DO_SHOW_RANK number(1,0),
	DO_SHOW_ITEM_STATS number(1,0)
);

alter table GB_GRADABLE_OBJECT_T
add (
	IS_NULL_ZERO number(1,0)
);
-- END SAK-17428

-- SAK-15311
ALTER TABLE GB_GRADABLE_OBJECT_T 
ADD ( 
SORT_ORDER number(10,0) 
); 

-- SAK-17679/SAK-18116
alter table EMAIL_TEMPLATE_ITEM add VERSION number(10,0) DEFAULT NULL;

-- SAM-818
alter table SAM_ITEM_T add PARTIAL_CREDIT_FLAG number(1,0) NULL; 
alter table SAM_PUBLISHEDITEM_T add PARTIAL_CREDIT_FLAG number(1,0) NULL; 
alter table SAM_ANSWER_T add PARTIAL_CREDIT float NULL; 
alter table SAM_PUBLISHEDANSWER_T add PARTIAL_CREDIT float NULL; 

-- SAM-676
create table SAM_GRADINGATTACHMENT_T (ATTACHMENTID number(19,0) not null, ATTACHMENTTYPE varchar2(255 char) not null, RESOURCEID varchar2(255 char), FILENAME varchar2(255 char), MIMETYPE varchar2(80 char), FILESIZE number(19,0), DESCRIPTION varchar2(4000 char), LOCATION varchar2(4000 char), ISLINK number(1,0), STATUS number(10,0) not null, CREATEDBY varchar2(255 char) not null, CREATEDDATE timestamp not null, LASTMODIFIEDBY varchar2(255 char) not null, LASTMODIFIEDDATE timestamp not null, ITEMGRADINGID number(19,0), primary key (ATTACHMENTID));
create index SAM_GA_ITEMGRADINGID_I on SAM_GRADINGATTACHMENT_T (ITEMGRADINGID);
alter table SAM_GRADINGATTACHMENT_T add constraint FK28156C6C4D7EA7B3 foreign key (ITEMGRADINGID) references SAM_ITEMGRADING_T;
create sequence SAM_GRADINGATTACHMENT_ID_S;

-- SAM-834
UPDATE SAM_ASSESSFEEDBACK_T 
SET FEEDBACKDELIVERY = 3, SHOWSTUDENTRESPONSE = 0, SHOWCORRECTRESPONSE = 0, SHOWSTUDENTSCORE = 0, SHOWSTUDENTQUESTIONSCORE = 0, 
SHOWQUESTIONLEVELFEEDBACK = 0, SHOWSELECTIONLEVELFEEDBACK = 0, SHOWGRADERCOMMENTS = 0, SHOWSTATISTICS = 0
WHERE ASSESSMENTID in (SELECT ID FROM SAM_ASSESSMENTBASE_T WHERE TYPEID='142' AND ISTEMPLATE=1);

-- SAK-18370
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.export'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewallmembers'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewenrollmentstatus'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewhidden'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewgroup'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewofficialphoto'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Coordinator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewprofile'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'CIG Participant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewprofile'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Evaluator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.export'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Evaluator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewofficialphoto'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Evaluator'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewprofile'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Reviewer'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.export'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Reviewer'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewofficialphoto'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.portfolio'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Reviewer'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'roster.viewprofile'));
-- end SAK-18370

-- SAK-17206
alter table POLL_OPTION add DELETED number(1,0) DEFAULT NULL;
