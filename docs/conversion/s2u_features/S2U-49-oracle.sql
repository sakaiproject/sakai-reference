-- S2U-49 --
CREATE TABLE mc_access_token (
  sakaiUserId varchar2(255) NOT NULL,
  accessToken clob,
  microsoftUserId varchar2(255) DEFAULT NULL,
  account varchar2(255) DEFAULT NULL,
  PRIMARY KEY (sakaiUserId)
);
-- S2U-49 --