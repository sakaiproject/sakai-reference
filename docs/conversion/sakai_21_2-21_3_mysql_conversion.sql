-- Start SAK-41604
ALTER TABLE rbc_evaluation ADD evaluated_item_owner_type INT DEFAULT null NULL;
-- End SAK-41604

-- SAK-45987
CREATE TABLE rbc_returned_criterion_out (
  id BIGINT AUTO_INCREMENT NOT NULL,
  comments LONGTEXT NULL,
  criterion_id BIGINT DEFAULT NULL NULL,
  points DOUBLE DEFAULT NULL NULL,
  pointsAdjusted BIT NOT NULL,
  selected_rating_id BIGINT DEFAULT NULL NULL,
  CONSTRAINT PK_RBC_RETURNED_CRITERION_OUT PRIMARY KEY (id)
);

CREATE TABLE rbc_returned_criterion_outs (
  rbc_returned_evaluation_id BIGINT NOT NULL,
  rbc_returned_criterion_out_id BIGINT NOT NULL,
  UNIQUE (rbc_returned_criterion_out_id)
);

CREATE TABLE rbc_returned_evaluation (
  id BIGINT AUTO_INCREMENT NOT NULL,
  original_evaluation_id BIGINT NOT NULL,
  overallComment VARCHAR(255) NULL,
  CONSTRAINT PK_RBC_RETURNED_EVALUATION PRIMARY KEY (id)
);

CREATE INDEX FK3sroha5yjh3cbvq0on02wf3fk ON rbc_returned_criterion_out(criterion_id);
CREATE INDEX rbc_ret_orig_id ON rbc_returned_evaluation(original_evaluation_id);
CREATE INDEX returned_evaluation_id_key ON rbc_returned_criterion_outs(rbc_returned_evaluation_id);

ALTER TABLE rbc_returned_criterion_out ADD CONSTRAINT FK3sroha5yjh3cbvq0on02wf3fk FOREIGN KEY (criterion_id) REFERENCES rbc_criterion (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_returned_criterion_outs ADD CONSTRAINT returned_criterion_out_id_fk FOREIGN KEY (rbc_returned_criterion_out_id) REFERENCES rbc_returned_criterion_out (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_returned_criterion_outs ADD CONSTRAINT returned_evalution_id_fk FOREIGN KEY (rbc_returned_evaluation_id) REFERENCES rbc_returned_evaluation (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
-- END SAK-45987

-- SAK-46977

-- Add the new function
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_NAME) VALUES('sitestats.all');
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_NAME) VALUES('sitestats.own');

-- Backfil permission
CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP VALUES('maintain','sitestats.all');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES('Instructor','sitestats.all');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES('access','sitestats.own');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES('Student','sitestats.own');

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

-- END SAK-46977
