-- SAK_41228
UPDATE CM_MEMBERSHIP_T SET USER_ID = LOWER(USER_ID);
UPDATE CM_ENROLLMENT_T SET USER_ID = LOWER(USER_ID);
UPDATE CM_OFFICIAL_INSTRUCTORS_T SET INSTRUCTOR_ID = LOWER(INSTRUCTOR_ID);
-- End of SAK_41228

-- SAK-41391

ALTER TABLE POLL_OPTION ADD OPTION_ORDER NUMBER(10,0);

-- END SAK-41391

-- SAK-41825
ALTER TABLE SAM_ASSESSMENTBASE_T ADD COLUMN CATEGORYID NUMBER(19);
ALTER TABLE SAM_PUBLISHEDASSESSMENT_T ADD COLUMN CATEGORYID NUMBER(19);
-- END SAK-41825

-- User Activity

CREATE TABLE SST_DETAILED_EVENTS
   (ID NUMBER(19,0) NOT NULL,
	USER_ID VARCHAR2(99 CHAR) NOT NULL,
	SITE_ID VARCHAR2(99 CHAR) NOT NULL,
	EVENT_ID VARCHAR2(32 CHAR) NOT NULL,
	EVENT_DATE TIMESTAMP (6) NOT NULL,
	EVENT_REF VARCHAR2(512 CHAR) NOT NULL,
	 PRIMARY KEY (ID));

create index IDX_DE_SITE_ID_DATE on SST_DETAILED_EVENTS(SITE_ID,EVENT_DATE);
create index IDX_DE_SITE_ID_USER_ID_DATE on SST_DETAILED_EVENTS(SITE_ID,USER_ID,EVENT_DATE);

create sequence SST_DETAILED_EVENTS_ID;

INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'sitestats.usertracking.track');
INSERT INTO SAKAI_REALM_FUNCTION VALUES (SAKAI_REALM_FUNCTION_SEQ.NEXTVAL, 'sitestats.usertracking.be.tracked');

INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'maintain'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'sitestats.usertracking.track'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'access'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'sitestats.usertracking.be.tracked'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Instructor'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'sitestats.usertracking.track'));
INSERT INTO SAKAI_REALM_RL_FN VALUES((select REALM_KEY from SAKAI_REALM where REALM_ID = '!site.template.course'), (select ROLE_KEY from SAKAI_REALM_ROLE where ROLE_NAME = 'Student'), (select FUNCTION_KEY from SAKAI_REALM_FUNCTION where FUNCTION_NAME = 'sitestats.usertracking.be.tracked'));

CREATE TABLE PERMISSIONS_SRC_TEMP (ROLE_NAME VARCHAR(99), FUNCTION_NAME VARCHAR(99));

INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('maintain','sitestats.usertracking.track');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('access','sitestats.usertracking.be.tracked');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Instructor','sitestats.usertracking.track');
INSERT INTO PERMISSIONS_SRC_TEMP VALUES ('Student','sitestats.usertracking.be.tracked');

CREATE TABLE PERMISSIONS_TEMP (ROLE_KEY INTEGER, FUNCTION_KEY INTEGER);
INSERT INTO PERMISSIONS_TEMP (ROLE_KEY, FUNCTION_KEY)
SELECT SRR.ROLE_KEY, SRF.FUNCTION_KEY
FROM PERMISSIONS_SRC_TEMP TMPSRC
JOIN SAKAI_REALM_ROLE SRR ON (TMPSRC.ROLE_NAME = SRR.ROLE_NAME)
JOIN SAKAI_REALM_FUNCTION SRF ON (TMPSRC.FUNCTION_NAME = SRF.FUNCTION_NAME);

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

DROP TABLE PERMISSIONS_TEMP;
DROP TABLE PERMISSIONS_SRC_TEMP;

-- End User Activity

-- SAK-34741
ALTER TABLE SAM_ITEM_T ADD COLUMN ISEXTRACREDIT NUMBER(1);
ALTER TABLE SAM_PUBLISHEDITEM_T ADD COLUMN ISEXTRACREDIT NUMBER(1);
-- END SAK-34741

-- START SAK-42400
ALTER TABLE SAM_ASSESSACCESSCONTROL_T ADD FEEDBACKENDDATE TIMESTAMP (6);
ALTER TABLE SAM_PUBLISHEDACCESSCONTROL_T ADD FEEDBACKENDDATE TIMESTAMP (6);
ALTER TABLE SAM_ASSESSACCESSCONTROL_T ADD FEEDBACKSCORETHRESHOLD FLOAT(126);
ALTER TABLE SAM_PUBLISHEDACCESSCONTROL_T ADD FEEDBACKSCORETHRESHOLD FLOAT(126);
-- END SAK-42400

-- SAK-42498
ALTER TABLE BULLHORN_ALERTS DROP COLUMN ALERT_TYPE;
