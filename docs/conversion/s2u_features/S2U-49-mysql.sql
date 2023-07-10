-- S2U-49 --
CREATE TABLE `mc_access_token` (
  `sakaiUserId` varchar(255) NOT NULL,
  `accessToken` text,
  `microsoftUserId` varchar(255) DEFAULT NULL,
  `account` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sakaiUserId`)
);
-- S2U-49 --