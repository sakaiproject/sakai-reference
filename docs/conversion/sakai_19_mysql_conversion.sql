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

-- SAK-41021
ALTER TABLE SIGNUP_TS_ATTENDEES ADD INSCRIPTION_TIME datetime;

ALTER TABLE SIGNUP_TS_WAITINGLIST ADD INSCRIPTION_TIME datetime;

-- END SAK-41021

-- SAK-40967
INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'rubrics.evaluee');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'rubrics.evaluator');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'rubrics.associator');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (DEFAULT, 'rubrics.editor');

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
ALTER TABLE BULLHORN_ALERTS ADD COLUMN DEFERRED BIT(1) NOT NULL DEFAULT b'0';
-- END SAK-40721

-- SAK-41017

UPDATE SAKAI_SITE_PAGE SET layout = '0' WHERE page_id = '!error-100';
UPDATE SAKAI_SITE_PAGE SET layout = '0' WHERE page_id = '!urlError-100';

-- End of SAK-41017

-- SAK-33855 add settings for display of stats
ALTER TABLE GB_GRADEBOOK_T ADD COLUMN ASSIGNMENT_STATS_DISPLAYED bit(1) NOT NULL DEFAULT b'1';
ALTER TABLE GB_GRADEBOOK_T ADD COLUMN COURSE_GRADE_STATS_DISPLAYED bit(1) NOT NULL DEFAULT b'1';
-- end SAK-33855

-- SAK-41225
DELETE FROM EMAIL_TEMPLATE_ITEM WHERE template_key = 'polls.notifyDeletedOption' AND template_locale='default'
-- End of SAK-41225

ALTER TABLE lti_tools
  ADD COLUMN allowfa_icon TINYINT DEFAULT 0,
  ADD COLUMN allowlineitems TINYINT DEFAULT 0,
  ADD COLUMN rolemap mediumtext,
  ADD COLUMN lti13_client_id varchar(1024) DEFAULT NULL,
  ADD COLUMN lti13_tool_public mediumtext,
  ADD COLUMN lti13_tool_keyset mediumtext,
  ADD COLUMN lti13_tool_kid varchar(1024) DEFAULT NULL,
  ADD COLUMN lti13_tool_private mediumtext,
  ADD COLUMN lti13_platform_public mediumtext,
  ADD COLUMN lti13_platform_private mediumtext,
  ADD COLUMN lti13_oidc_endpoint varchar(1024) DEFAULT NULL,
  ADD COLUMN lti13_oidc_redirect varchar(1024) DEFAULT NULL,
  ADD COLUMN lti11_launch_type TINYINT DEFAULT 0;

ALTER TABLE lti_deploy ADD COLUMN allowlineitems TINYINT DEFAULT 0;

CREATE TABLE rbc_rubric (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  description varchar(255) DEFAULT NULL,
  created tinyblob,
  creatorId varchar(255) DEFAULT NULL,
  modified tinyblob,
  ownerId varchar(255) DEFAULT NULL,
  ownerType varchar(255) DEFAULT NULL,
  shared bit(1) NOT NULL,
  title varchar(255) DEFAULT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE rbc_criterion (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  description longtext,
  created tinyblob,
  creatorId varchar(255) DEFAULT NULL,
  modified tinyblob,
  ownerId varchar(255) DEFAULT NULL,
  ownerType varchar(255) DEFAULT NULL,
  shared bit(1) NOT NULL,
  title varchar(255) DEFAULT NULL,
  rubric_id bigint(20) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY FK_52ca0oi01i6aykocyb9840o37 (rubric_id),
  CONSTRAINT FK_52ca0oi01i6aykocyb9840o37 FOREIGN KEY (rubric_id) REFERENCES rbc_rubric (id)
);

CREATE TABLE rbc_criterion_outcome (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  comments varchar(255) DEFAULT NULL,
  criterion_id bigint(20) DEFAULT NULL,
  points int(11) DEFAULT NULL,
  pointsAdjusted bit(1) NOT NULL,
  selected_rating_id bigint(20) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY FK_h43853lsee9xsay4qlic80pkv (criterion_id),
  CONSTRAINT FK_h43853lsee9xsay4qlic80pkv FOREIGN KEY (criterion_id) REFERENCES rbc_criterion (id)
);

CREATE TABLE rbc_rating (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  description longtext,
  created tinyblob,
  creatorId varchar(255) DEFAULT NULL,
  modified tinyblob,
  ownerId varchar(255) DEFAULT NULL,
  ownerType varchar(255) DEFAULT NULL,
  shared bit(1) NOT NULL,
  points int(11) DEFAULT NULL,
  title varchar(255) DEFAULT NULL,
  criterion_id bigint(20) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY FK_n44rjf77gscr2kqkamfbpkc7t (criterion_id),
  CONSTRAINT FK_n44rjf77gscr2kqkamfbpkc7t FOREIGN KEY (criterion_id) REFERENCES rbc_criterion (id)
);

CREATE TABLE rbc_criterion_ratings (
  rbc_criterion_id bigint(20) NOT NULL,
  ratings_id bigint(20) NOT NULL,
  order_index int(11) NOT NULL,
  PRIMARY KEY (rbc_criterion_id,order_index),
  UNIQUE KEY UK_funjjd0xkrmm5x300r7i4la83 (ratings_id),
  CONSTRAINT FK_funjjd0xkrmm5x300r7i4la83 FOREIGN KEY (ratings_id) REFERENCES rbc_rating (id),
  CONSTRAINT FK_h4u89cj06chitnt3vcdsu5t7m FOREIGN KEY (rbc_criterion_id) REFERENCES rbc_criterion (id)
);

CREATE TABLE rbc_tool_item_rbc_assoc (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  itemId varchar(255) DEFAULT NULL,
  created tinyblob,
  creatorId varchar(255) DEFAULT NULL,
  modified tinyblob,
  ownerId varchar(255) DEFAULT NULL,
  ownerType varchar(255) DEFAULT NULL,
  shared bit(1) NOT NULL,
  rubric_id bigint(20) DEFAULT NULL,
  toolId varchar(255) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY FK_6dwej9j9vx5viukv8w86chbbc (rubric_id),
  CONSTRAINT FK_6dwej9j9vx5viukv8w86chbbc FOREIGN KEY (rubric_id) REFERENCES rbc_rubric (id)
);

CREATE TABLE rbc_tool_item_rbc_assoc_conf (
  association_id bigint(20) NOT NULL,
  parameters bit(1) DEFAULT NULL,
  parameter_label varchar(255) NOT NULL,
  PRIMARY KEY (association_id,parameter_label),
  CONSTRAINT FK_rdpid6jl4csvfv6la80ppu6p9 FOREIGN KEY (association_id) REFERENCES rbc_tool_item_rbc_assoc (id)
);

CREATE TABLE rbc_evaluation (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  evaluated_item_id varchar(255) DEFAULT NULL,
  evaluated_item_owner_id varchar(255) DEFAULT NULL,
  evaluator_id varchar(255) DEFAULT NULL,
  created tinyblob,
  creatorId varchar(255) DEFAULT NULL,
  modified tinyblob,
  ownerId varchar(255) DEFAULT NULL,
  ownerType varchar(255) DEFAULT NULL,
  shared bit(1) NOT NULL,
  overallComment varchar(255) DEFAULT NULL,
  association_id bigint(20) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY UK_dn0jue890jn9p7vs6tvnsf2gf (association_id,evaluated_item_id,evaluator_id),
  CONSTRAINT FK_faohmo8ewmybgp67w10g53dtm FOREIGN KEY (association_id) REFERENCES rbc_tool_item_rbc_assoc (id)
);

CREATE TABLE rbc_eval_criterion_outcomes (
  rbc_evaluation_id bigint(20) NOT NULL,
  criterionOutcomes_id bigint(20) NOT NULL,
  UNIQUE KEY UK_f8xy8709bllewhbve9ias2vk4 (criterionOutcomes_id),
  KEY FK_cc847hghhh56xmwcaxmevyhrn (rbc_evaluation_id),
  CONSTRAINT FK_cc847hghhh56xmwcaxmevyhrn FOREIGN KEY (rbc_evaluation_id) REFERENCES rbc_evaluation (id),
  CONSTRAINT FK_f8xy8709bllewhbve9ias2vk4 FOREIGN KEY (criterionOutcomes_id) REFERENCES rbc_criterion_outcome (id)
);
