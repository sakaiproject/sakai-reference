-- SAK-38427
ALTER TABLE MFR_TOPIC_T ADD COLUMN ALLOW_EMAIL_NOTIFICATIONS BIT(1) NOT NULL DEFAULT 1;
ALTER TABLE MFR_TOPIC_T ADD COLUMN INCLUDE_CONTENTS_IN_EMAILS BIT(1) NOT NULL DEFAULT 1;
-- END SAK-38427

-- SAK-33969
ALTER TABLE MFR_OPEN_FORUM_T ADD RESTRICT_PERMS_FOR_GROUPS BIT(1) DEFAULT FALSE;
ALTER TABLE MFR_TOPIC_T ADD RESTRICT_PERMS_FOR_GROUPS BIT(1) DEFAULT FALSE;
-- END SAK-33969

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
-- END SAK-40967

-- SAK-40721
ALTER TABLE BULLHORN_ALERTS ADD COLUMN DEFERRED BIT(1) NOT NULL DEFAULT b'0';
-- END SAK-40721

-- SAK-41017
UPDATE SAKAI_SITE_PAGE SET layout = '0' WHERE page_id = '!error-100';
UPDATE SAKAI_SITE_PAGE SET layout = '0' WHERE page_id = '!urlError-100';
-- END SAK-41017

-- SAK-33855 add settings for display of stats
ALTER TABLE GB_GRADEBOOK_T ADD COLUMN ASSIGNMENT_STATS_DISPLAYED bit(1) NOT NULL DEFAULT b'1';
ALTER TABLE GB_GRADEBOOK_T ADD COLUMN COURSE_GRADE_STATS_DISPLAYED bit(1) NOT NULL DEFAULT b'1';
-- end SAK-33855

-- SAK-41225
DELETE FROM EMAIL_TEMPLATE_ITEM WHERE template_key = 'polls.notifyDeletedOption' AND template_locale='default'
-- End of SAK-41225

ALTER TABLE lti_tools ADD allowlineitems TINYINT(3) DEFAULT 0 NULL;
ALTER TABLE lti_tools ADD allowfa_icon TINYINT(3) DEFAULT 0 NULL;
ALTER TABLE lti_tools ADD rolemap MEDIUMTEXT NULL;
ALTER TABLE lti_tools ADD lti13_client_id VARCHAR(1024) NULL;
ALTER TABLE lti_tools ADD lti13_tool_public MEDIUMTEXT NULL;
ALTER TABLE lti_tools ADD lti13_tool_keyset MEDIUMTEXT NULL;
ALTER TABLE lti_tools ADD lti13_tool_kid VARCHAR(1024) NULL;
ALTER TABLE lti_tools ADD lti13_tool_private MEDIUMTEXT NULL;
ALTER TABLE lti_tools ADD lti13_platform_public MEDIUMTEXT NULL;
ALTER TABLE lti_tools ADD lti13_platform_private MEDIUMTEXT NULL;
ALTER TABLE lti_tools ADD lti13_oidc_endpoint VARCHAR(1024) NULL;
ALTER TABLE lti_tools ADD lti13_oidc_redirect VARCHAR(1024) NULL;
ALTER TABLE lti_tools ADD lti11_launch_type TINYINT(3) DEFAULT 0 NULL;

ALTER TABLE lti_deploy ADD COLUMN allowlineitems TINYINT DEFAULT 0;

DELETE SAKAI_MESSAGE_BUNDLE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;

-- Rubrics
CREATE TABLE rbc_criterion (
  id BIGINT AUTO_INCREMENT NOT NULL,
  `description` LONGTEXT NULL,
  created TINYBLOB DEFAULT NULL NULL,
  creatorId VARCHAR(255) NULL,
  modified TINYBLOB DEFAULT NULL NULL,
  ownerId VARCHAR(255) NULL,
  ownerType VARCHAR(255) NULL,
  shared BIT(1) NOT NULL,
  title VARCHAR(255) NULL,
  rubric_id BIGINT DEFAULT NULL NULL,
  CONSTRAINT PK_RBC_CRITERION PRIMARY KEY (id)
);

CREATE TABLE rbc_criterion_outcome (
  id BIGINT AUTO_INCREMENT NOT NULL,
  comments VARCHAR(255) NULL,
  criterion_id BIGINT DEFAULT NULL NULL,
  points INT DEFAULT NULL NULL,
  pointsAdjusted BIT(1) NOT NULL,
  selected_rating_id BIGINT DEFAULT NULL NULL,
  CONSTRAINT PK_RBC_CRITERION_OUTCOME PRIMARY KEY (id)
);

CREATE TABLE rbc_criterion_ratings (
  rbc_criterion_id BIGINT NOT NULL,
  ratings_id BIGINT NOT NULL,
  order_index INT NOT NULL,
  CONSTRAINT PK_RBC_CRITERION_RATINGS PRIMARY KEY (rbc_criterion_id, order_index),
  UNIQUE (ratings_id)
);

CREATE TABLE rbc_eval_criterion_outcomes (
  rbc_evaluation_id BIGINT NOT NULL,
  criterionOutcomes_id BIGINT NOT NULL,
  UNIQUE (criterionOutcomes_id)
);

CREATE TABLE rbc_evaluation (
  id BIGINT AUTO_INCREMENT NOT NULL,
  evaluated_item_id VARCHAR(255) NULL,
  evaluated_item_owner_id VARCHAR(255) NULL,
  evaluator_id VARCHAR(255) NULL,
  created TINYBLOB DEFAULT NULL NULL,
  creatorId VARCHAR(255) NULL,
  modified TINYBLOB DEFAULT NULL NULL,
  ownerId VARCHAR(255) NULL,
  ownerType VARCHAR(255) NULL,
  shared BIT(1) NOT NULL,
  overallComment VARCHAR(255) NULL,
  association_id BIGINT NOT NULL,
  CONSTRAINT PK_RBC_EVALUATION PRIMARY KEY (id)
);

CREATE TABLE rbc_rating (
  id BIGINT AUTO_INCREMENT NOT NULL,
  `description` LONGTEXT NULL,
  created TINYBLOB DEFAULT NULL NULL,
  creatorId VARCHAR(255) NULL,
  modified TINYBLOB DEFAULT NULL NULL,
  ownerId VARCHAR(255) NULL,
  ownerType VARCHAR(255) NULL,
  shared BIT(1) NOT NULL,
  points INT DEFAULT NULL NULL,
  title VARCHAR(255) NULL,
  criterion_id BIGINT DEFAULT NULL NULL,
  CONSTRAINT PK_RBC_RATING PRIMARY KEY (id)
);

CREATE TABLE rbc_rubric (
  id BIGINT AUTO_INCREMENT NOT NULL,
  `description` VARCHAR(255) NULL,
  created TINYBLOB DEFAULT NULL NULL,
  creatorId VARCHAR(255) NULL,
  modified TINYBLOB DEFAULT NULL NULL,
  ownerId VARCHAR(255) NULL,
  ownerType VARCHAR(255) NULL,
  shared BIT(1) NOT NULL,
  title VARCHAR(255) NULL,
  CONSTRAINT PK_RBC_RUBRIC PRIMARY KEY (id)
);

CREATE TABLE rbc_rubric_criterions (
  rbc_rubric_id BIGINT NOT NULL,
  criterions_id BIGINT NOT NULL,
  order_index INT NOT NULL,
  CONSTRAINT PK_RBC_RUBRIC_CRITERIONS PRIMARY KEY (rbc_rubric_id, order_index)
);

CREATE TABLE rbc_tool_item_rbc_assoc (
  id BIGINT AUTO_INCREMENT NOT NULL,
  itemId VARCHAR(255) NULL,
  created TINYBLOB DEFAULT NULL NULL,
  creatorId VARCHAR(255) NULL,
  modified TINYBLOB DEFAULT NULL NULL,
  ownerId VARCHAR(255) NULL,
  ownerType VARCHAR(255) NULL,
  shared BIT(1) NOT NULL,
  rubric_id BIGINT DEFAULT NULL NULL,
  toolId VARCHAR(255) NULL,
  CONSTRAINT PK_RBC_TOOL_ITEM_RBC_ASSOC PRIMARY KEY (id)
);

CREATE TABLE rbc_tool_item_rbc_assoc_conf (
  association_id BIGINT NOT NULL,
  parameters BIT(1) DEFAULT 0 NULL,
  parameter_label VARCHAR(255) NOT NULL,
  CONSTRAINT PK_RBC_TOOL_ITEM_RBC_ASSOC_CONF PRIMARY KEY (association_id, parameter_label)
);

CREATE INDEX FK_52ca0oi01i6aykocyb9840o37 ON rbc_criterion(rubric_id);
CREATE INDEX FK_6dwej9j9vx5viukv8w86chbbc ON rbc_tool_item_rbc_assoc(rubric_id);
CREATE INDEX FK_cc847hghhh56xmwcaxmevyhrn ON rbc_eval_criterion_outcomes(rbc_evaluation_id);
CREATE INDEX FK_h43853lsee9xsay4qlic80pkv ON rbc_criterion_outcome(criterion_id);
CREATE INDEX FK_n44rjf77gscr2kqkamfbpkc7t ON rbc_rating(criterion_id);
CREATE INDEX FK_soau1ppw2wakbx8hemaaanubi ON rbc_rubric_criterions(criterions_id);

ALTER TABLE rbc_evaluation ADD CONSTRAINT UK_dn0jue890jn9p7vs6tvnsf2gf UNIQUE (association_id, evaluated_item_id, evaluator_id);
ALTER TABLE rbc_criterion ADD CONSTRAINT FK_52ca0oi01i6aykocyb9840o37 FOREIGN KEY (rubric_id) REFERENCES rbc_rubric (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_tool_item_rbc_assoc ADD CONSTRAINT FK_6dwej9j9vx5viukv8w86chbbc FOREIGN KEY (rubric_id) REFERENCES rbc_rubric (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_rubric_criterions ADD CONSTRAINT FK_6jo83t1ddebdbt9296y1xftkn FOREIGN KEY (rbc_rubric_id) REFERENCES rbc_rubric (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_eval_criterion_outcomes ADD CONSTRAINT FK_cc847hghhh56xmwcaxmevyhrn FOREIGN KEY (rbc_evaluation_id) REFERENCES rbc_evaluation (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_eval_criterion_outcomes ADD CONSTRAINT FK_f8xy8709bllewhbve9ias2vk4 FOREIGN KEY (criterionOutcomes_id) REFERENCES rbc_criterion_outcome (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_evaluation ADD CONSTRAINT FK_faohmo8ewmybgp67w10g53dtm FOREIGN KEY (association_id) REFERENCES rbc_tool_item_rbc_assoc (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_criterion_ratings ADD CONSTRAINT FK_funjjd0xkrmm5x300r7i4la83 FOREIGN KEY (ratings_id) REFERENCES rbc_rating (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_criterion_outcome ADD CONSTRAINT FK_h43853lsee9xsay4qlic80pkv FOREIGN KEY (criterion_id) REFERENCES rbc_criterion (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_criterion_ratings ADD CONSTRAINT FK_h4u89cj06chitnt3vcdsu5t7m FOREIGN KEY (rbc_criterion_id) REFERENCES rbc_criterion (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_rating ADD CONSTRAINT FK_n44rjf77gscr2kqkamfbpkc7t FOREIGN KEY (criterion_id) REFERENCES rbc_criterion (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_tool_item_rbc_assoc_conf ADD CONSTRAINT FK_rdpid6jl4csvfv6la80ppu6p9 FOREIGN KEY (association_id) REFERENCES rbc_tool_item_rbc_assoc (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_rubric_criterions ADD CONSTRAINT FK_soau1ppw2wakbx8hemaaanubi FOREIGN KEY (criterions_id) REFERENCES rbc_criterion (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
-- END Rubrics
