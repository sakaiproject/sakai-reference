-- Start SAK-41604
ALTER TABLE RBC_EVALUATION ADD EVALUATED_ITEM_OWNER_TYPE NUMBER(1,0);
-- End SAK-41604

-- SAK-45987
CREATE TABLE RBC_RETURNED_CRITERION_OUT (
  ID NUMBER(19) NOT NULL,
  COMMENTS CLOB DEFAULT NULL,
  CRITERION_ID NUMBER(19) DEFAULT NULL,
  POINTS FLOAT DEFAULT NULL,
  POINTSADJUSTED NUMBER(1,0) NOT NULL,
  SELECTED_RATING_ID NUMBER(19) DEFAULT NULL,
  PRIMARY KEY (ID),
  CONSTRAINT FK_RBC_RETURNED_CRITERION_ID FOREIGN KEY (CRITERION_ID) REFERENCES RBC_CRITERION (ID)
);

CREATE SEQUENCE RBC_RET_CRIT_OUT_SEQ;

CREATE TABLE RBC_RETURNED_EVALUATION (
  ID NUMBER(19) NOT NULL,
  ORIGINAL_EVALUATION_ID NUMBER(19) NOT NULL,
  OVERALLCOMMENT VARCHAR2(255) DEFAULT NULL,
  PRIMARY KEY (ID)
);

CREATE SEQUENCE RBC_RET_EVAL_SEQ;

CREATE INDEX RBC_RET_ORIG_ID ON  RBC_RETURNED_EVALUATION(ORIGINAL_EVALUATION_ID);

CREATE TABLE RBC_RETURNED_CRITERION_OUTS (
  RBC_RETURNED_EVALUATION_ID NUMBER(19) NOT NULL,
  RBC_RETURNED_CRITERION_OUT_ID NUMBER(19) NOT NULL UNIQUE,
  CONSTRAINT RETURNED_CRITERION_OUT_ID_FK FOREIGN KEY (RBC_RETURNED_CRITERION_OUT_ID) REFERENCES RBC_RETURNED_CRITERION_OUT (ID),
  CONSTRAINT RETURNED_EVALUTION_ID_FK FOREIGN KEY (RBC_RETURNED_EVALUATION_ID) REFERENCES RBC_RETURNED_EVALUATION (ID)
);

CREATE INDEX RETURNED_EVALUATION_ID_KEY ON RBC_RETURNED_CRITERION_OUTS(RBC_RETURNED_EVALUATION_ID);
-- End SAK-45987

-- SAK-46977
-- Add the Functions
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_KEY, FUNCTION_NAME) VALUES(SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'sitestats.all');
INSERT INTO SAKAI_REALM_FUNCTION (FUNCTION_KEY, FUNCTION_NAME) VALUES(SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'sitestats.own');

-- --------------------------------------------------------------------------------------------------------------------------------------
-- backfill new permission into existing realms
-- --------------------------------------------------------------------------------------------------------------------------------------

-- for each realm that has a role matching something in this table, we will add to that role the function from this table
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

-- END SAK-46977
