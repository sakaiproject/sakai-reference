-- Gradbook Classic tool removed in 19, move tool reference to Gradebook NG
UPDATE SAKAI_SITE_TOOL set REGISTRATION='sakai.gradebookng' where REGISTRATION='sakai.gradebook.tool';

-- SAK-38427

ALTER TABLE MFR_TOPIC_T ADD ALLOW_EMAIL_NOTIFICATIONS NUMBER(1,0) DEFAULT 1 NOT NULL;
ALTER TABLE MFR_TOPIC_T ADD INCLUDE_CONTENTS_IN_EMAILS NUMBER(1,0) DEFAULT 1 NOT NULL;

-- END SAK-38427

-- SAK-33969
ALTER TABLE MFR_OPEN_FORUM_T ADD RESTRICT_PERMS_FOR_GROUPS NUMBER(1) DEFAULT 0;
ALTER TABLE MFR_TOPIC_T ADD RESTRICT_PERMS_FOR_GROUPS NUMBER(1) DEFAULT 0;
-- SAK-33969

-- SAK-39967

CREATE INDEX contentreview_provider_id_idx on CONTENTREVIEW_ITEM (providerId, externalId);

-- End SAK-39967

-- SAK-40182
DECLARE
    seq_start INTEGER;
BEGIN
   SELECT NVL(MAX(PUBLISHEDSECTIONMETADATAID),0) + 1
   INTO   seq_start   FROM SAM_PUBLISHEDSECTIONMETADATA_T;
   EXECUTE IMMEDIATE 'CREATE SEQUENCE SAM_PUBSECTIONMETADATA_ID_S START WITH '||seq_start||' INCREMENT BY 1 NOMAXVALUE';
END;
-- End SAK-40182

-- SAK-41021
ALTER TABLE SIGNUP_TS_ATTENDEES ADD INSCRIPTION_TIME TIMESTAMP;

ALTER TABLE SIGNUP_TS_WAITINGLIST ADD INSCRIPTION_TIME TIMESTAMP;

-- END SAK-41021

-- SAK-40967
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'rubrics.evaluee');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'rubrics.evaluator');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'rubrics.associator');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'rubrics.editor');

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.user'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'access'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluee'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.user'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.associator'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.user'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.editor'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.user'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluator'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.user'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluee'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'access'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluee'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluator'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.associator'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.editor'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluee'));

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluee'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.associator'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.editor'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluator'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluee'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluator'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Teaching Assistant'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'rubrics.evaluee'));

-- End SAK-40967

-- SAK-40721
ALTER TABLE BULLHORN_ALERTS ADD DEFERRED NUMBER(1) DEFAULT 0 NOT NULL;
-- END SAK-40721

-- SAK-41017

UPDATE SAKAI_SITE_PAGE SET layout = '0' WHERE page_id = '!error-100';
UPDATE SAKAI_SITE_PAGE SET layout = '0' WHERE page_id = '!urlError-100';

-- End of SAK-41017

-- SAK-33855 add settings for display of stats
ALTER TABLE gb_gradebook_t ADD assignment_stats_displayed NUMBER(1,0) DEFAULT 1 NOT NULL;
ALTER TABLE gb_gradebook_t ADD course_grade_stats_displayed NUMBER(1,0) DEFAULT 1 NOT NULL;
-- end SAK-33855

-- SAK-41225
DELETE FROM EMAIL_TEMPLATE_ITEM WHERE template_key = 'polls.notifyDeletedOption' AND template_locale='default';
-- End of SAK-41225

ALTER TABLE lti_tools
  ADD (allowfa_icon NUMBER(1) DEFAULT 0)
  ADD (allowlineitems NUMBER(1) DEFAULT 0)
  ADD (rolemap CLOB)
  ADD (lti13_client_id varchar2(1024) DEFAULT NULL)
  ADD (lti13_tool_public CLOB)
  ADD (lti13_tool_keyset CLOB)
  ADD (lti13_tool_kid varchar2(1024) DEFAULT NULL)
  ADD (lti13_tool_private CLOB)
  ADD (lti13_platform_public CLOB)
  ADD (lti13_platform_private CLOB)
  ADD (lti13_oidc_endpoint varchar2(1024) DEFAULT NULL)
  ADD (lti13_oidc_redirect varchar2(1024) DEFAULT NULL)
  ADD (lti11_launch_type NUMBER(1) DEFAULT 0);

ALTER TABLE lti_deploy ADD allowlineitems NUMBER(1) DEFAULT 0;

DELETE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

-- Rubrics
CREATE TABLE rbc_criterion (
  id NUMBER(19) NOT NULL,
  description CLOB NULL,
  created BLOB NULL,
  creatorId VARCHAR2(255) NULL,
  modified BLOB NULL,
  ownerId VARCHAR2(255) NULL,
  ownerType VARCHAR2(255) NULL,
  shared NUMBER(1) NOT NULL,
  title VARCHAR2(255) NULL,
  rubric_id NUMBER(19) DEFAULT NULL NULL,
  CONSTRAINT PK_RBC_CRITERION PRIMARY KEY (id)
);

-- Generate ID using sequence 
CREATE SEQUENCE rbc_crit_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE rbc_criterion_outcome (
  id NUMBER(19) NOT NULL,
  comments VARCHAR2(255) NULL,
  criterion_id NUMBER(19) DEFAULT NULL NULL,
  points NUMBER(10) DEFAULT NULL NULL,
  pointsAdjusted NUMBER(1) NOT NULL,
  selected_rating_id NUMBER(19) DEFAULT NULL NULL,
  CONSTRAINT PK_RBC_CRITERION_OUTCOME PRIMARY KEY (id)
);

-- Generate ID using sequence 
CREATE SEQUENCE rbc_crit_out_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE rbc_criterion_ratings (
  rbc_criterion_id NUMBER(19) NOT NULL,
  ratings_id NUMBER(19) NOT NULL,
  order_index NUMBER(10) NOT NULL,
  CONSTRAINT PK_RBC_CRITERION_RATINGS PRIMARY KEY (rbc_criterion_id, order_index),
  UNIQUE (ratings_id)
);

CREATE TABLE rbc_eval_criterion_outcomes (
  rbc_evaluation_id NUMBER(19) NOT NULL,
  criterionOutcomes_id NUMBER(19) NOT NULL,
  UNIQUE (criterionOutcomes_id)
);

CREATE TABLE rbc_evaluation (
  id NUMBER(19) NOT NULL,
  evaluated_item_id VARCHAR2(255) NULL,
  evaluated_item_owner_id VARCHAR2(255) NULL,
  evaluator_id VARCHAR2(255) NULL,
  created BLOB NULL,
  creatorId VARCHAR2(255) NULL,
  modified BLOB NULL,
  ownerId VARCHAR2(255) NULL,
  ownerType VARCHAR2(255) NULL,
  shared NUMBER(1) NOT NULL,
  overallComment VARCHAR2(255) NULL,
  association_id NUMBER(19) NOT NULL,
  CONSTRAINT PK_RBC_EVALUATION PRIMARY KEY (id)
);

-- Generate ID using sequence 
CREATE SEQUENCE rbc_eval_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE rbc_rating (
  id NUMBER(19) NOT NULL,
  description CLOB NULL,
  created BLOB NULL,
  creatorId VARCHAR2(255) NULL,
  modified BLOB NULL,
  ownerId VARCHAR2(255) NULL,
  ownerType VARCHAR2(255) NULL,
  shared NUMBER(1) NOT NULL,
  points NUMBER(10) DEFAULT NULL NULL,
  title VARCHAR2(255) NULL,
  criterion_id NUMBER(19) DEFAULT NULL NULL,
  CONSTRAINT PK_RBC_RATING PRIMARY KEY (id)
);

-- Generate ID using sequence 
CREATE SEQUENCE rbc_rat_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE rbc_rubric (
  id NUMBER(19) NOT NULL,
  description VARCHAR2(255) NULL,
  created BLOB NULL,
  creatorId VARCHAR2(255) NULL,
  modified BLOB NULL,
  ownerId VARCHAR2(255) NULL,
  ownerType VARCHAR2(255) NULL,
  shared NUMBER(1) NOT NULL,
  title VARCHAR2(255) NULL,
  CONSTRAINT PK_RBC_RUBRIC PRIMARY KEY (id)
);

-- Generate ID using sequence 
CREATE SEQUENCE rbc_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE rbc_rubric_criterions (
  rbc_rubric_id NUMBER(19) NOT NULL,
  criterions_id NUMBER(19) NOT NULL,
  order_index NUMBER(10) NOT NULL,
  CONSTRAINT PK_RBC_RUBRIC_CRITERIONS PRIMARY KEY (rbc_rubric_id, order_index)
);

CREATE TABLE rbc_tool_item_rbc_assoc (
  id NUMBER(19) NOT NULL,
  itemId VARCHAR2(255) NULL,
  created BLOB NULL,
  creatorId VARCHAR2(255) NULL,
  modified BLOB NULL,
  ownerId VARCHAR2(255) NULL,
  ownerType VARCHAR2(255) NULL,
  shared NUMBER(1) NOT NULL,
  rubric_id NUMBER(19) DEFAULT NULL NULL,
  toolId VARCHAR2(255) NULL,
  CONSTRAINT PK_RBC_TOOL_ITEM_RBC_ASSOC PRIMARY KEY (id)
);

-- Generate ID using sequence 
CREATE SEQUENCE rbc_tool_item_rbc_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE rbc_tool_item_rbc_assoc_conf (
  association_id NUMBER(19) NOT NULL,
  parameters NUMBER(1) DEFAULT 0 NULL,
  parameter_label VARCHAR2(255) NOT NULL,
  CONSTRAINT PK_RBC_TOOL_ITEM_RBC_ASSO_CONF PRIMARY KEY (association_id, parameter_label)
);

CREATE INDEX FK_52ca0oi01i6aykocyb9840o37 ON rbc_criterion(rubric_id);
CREATE INDEX FK_6dwej9j9vx5viukv8w86chbbc ON rbc_tool_item_rbc_assoc(rubric_id);
CREATE INDEX FK_cc847hghhh56xmwcaxmevyhrn ON rbc_eval_criterion_outcomes(rbc_evaluation_id);
CREATE INDEX FK_h43853lsee9xsay4qlic80pkv ON rbc_criterion_outcome(criterion_id);
CREATE INDEX FK_n44rjf77gscr2kqkamfbpkc7t ON rbc_rating(criterion_id);
CREATE INDEX FK_soau1ppw2wakbx8hemaaanubi ON rbc_rubric_criterions(criterions_id);

ALTER TABLE rbc_evaluation ADD CONSTRAINT UK_dn0jue890jn9p7vs6tvnsf2gf UNIQUE (association_id, evaluated_item_id, evaluator_id);
ALTER TABLE rbc_criterion ADD CONSTRAINT FK_52ca0oi01i6aykocyb9840o37 FOREIGN KEY (rubric_id) REFERENCES rbc_rubric (id) ;
ALTER TABLE rbc_tool_item_rbc_assoc ADD CONSTRAINT FK_6dwej9j9vx5viukv8w86chbbc FOREIGN KEY (rubric_id) REFERENCES rbc_rubric (id) ;
ALTER TABLE rbc_rubric_criterions ADD CONSTRAINT FK_6jo83t1ddebdbt9296y1xftkn FOREIGN KEY (rbc_rubric_id) REFERENCES rbc_rubric (id) ;
ALTER TABLE rbc_eval_criterion_outcomes ADD CONSTRAINT FK_cc847hghhh56xmwcaxmevyhrn FOREIGN KEY (rbc_evaluation_id) REFERENCES rbc_evaluation (id) ;
ALTER TABLE rbc_eval_criterion_outcomes ADD CONSTRAINT FK_f8xy8709bllewhbve9ias2vk4 FOREIGN KEY (criterionOutcomes_id) REFERENCES rbc_criterion_outcome (id) ;
ALTER TABLE rbc_evaluation ADD CONSTRAINT FK_faohmo8ewmybgp67w10g53dtm FOREIGN KEY (association_id) REFERENCES rbc_tool_item_rbc_assoc (id) ;
ALTER TABLE rbc_criterion_ratings ADD CONSTRAINT FK_funjjd0xkrmm5x300r7i4la83 FOREIGN KEY (ratings_id) REFERENCES rbc_rating (id) ;
ALTER TABLE rbc_criterion_outcome ADD CONSTRAINT FK_h43853lsee9xsay4qlic80pkv FOREIGN KEY (criterion_id) REFERENCES rbc_criterion (id) ;
ALTER TABLE rbc_criterion_ratings ADD CONSTRAINT FK_h4u89cj06chitnt3vcdsu5t7m FOREIGN KEY (rbc_criterion_id) REFERENCES rbc_criterion (id) ;
ALTER TABLE rbc_rating ADD CONSTRAINT FK_n44rjf77gscr2kqkamfbpkc7t FOREIGN KEY (criterion_id) REFERENCES rbc_criterion (id) ;
ALTER TABLE rbc_tool_item_rbc_assoc_conf ADD CONSTRAINT FK_rdpid6jl4csvfv6la80ppu6p9 FOREIGN KEY (association_id) REFERENCES rbc_tool_item_rbc_assoc (id) ;
ALTER TABLE rbc_rubric_criterions ADD CONSTRAINT FK_soau1ppw2wakbx8hemaaanubi FOREIGN KEY (criterions_id) REFERENCES rbc_criterion (id) ;
-- END Rubrics

-- SAK-40687
ALTER TABLE GB_GRADABLE_OBJECT_T ADD EXTERNAL_DATA CLOB;
-- END SAK-40687

-- --------------------------------------------------------------------------------------------------------------------------------------
-- backfill new permission into existing realms
-- --------------------------------------------------------------------------------------------------------------------------------------

-- for each realm that has a role matching something in this table, we will add to that role the function from this table
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('maintain','rubrics.associator');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('maintain','rubrics.editor');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('maintain','rubrics.evaluator');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('maintain','rubrics.evaluee');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('access','rubrics.evaluee');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Instructor','rubrics.associator');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Instructor','rubrics.editor');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Instructor','rubrics.evaluator');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Instructor','rubrics.evaluee');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Teaching Assistant','rubrics.evaluator');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Teaching Assistant','rubrics.evaluee');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Student','rubrics.evaluee');

-- lookup the role and function number
CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
FROM PERMISSIONS_SRC_TEMP TMPSRC
JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

-- insert the new function into the roles of any existing realm that has the role (don't convert the "!site.helper")
INSERT INTO SAKAI_REALM_RL_FN (REALM_KEY, ROLE_KEY, FUNCTION_KEY)
SELECT
    SRRFD.REALM_KEY, SRRFD.ROLE_KEY, TMP.FUNCTION_KEY
FROM
    (SELECT DISTINCT SRRF.REALM_KEY, SRRF.ROLE_KEY FROM SAKAI_REALM_RL_FN SRRF) SRRFD
    JOIN PERMISSIONS_TEMP TMP ON (SRRFD.ROLE_KEY = TMP.ROLE_KEY)
    JOIN SAKAI_REALM SR ON (SRRFD.REALM_KEY = SR.REALM_KEY)
    WHERE SR.REALM_ID != '!site.helper'
    AND NOT EXISTS (
        SELECT 1
            FROM SAKAI_REALM_RL_FN SRRFI
            WHERE SRRFI.REALM_KEY=SRRFD.REALM_KEY AND SRRFI.ROLE_KEY=SRRFD.ROLE_KEY AND SRRFI.FUNCTION_KEY=TMP.FUNCTION_KEY
    );

-- clean up the temp tables
DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_SRC_TEMP;

