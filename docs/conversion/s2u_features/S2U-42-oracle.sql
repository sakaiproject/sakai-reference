-- S2U-42 --
CREATE TABLE CARDGAME_STAT_ITEM (
  ID BIGINT(19,0) AUTO_INCREMENT PRIMARY KEY,
  PLAYER_ID VARCHAR2(255 CHAR) NOT NULL,
  USER_ID VARCHAR2(255 CHAR) NOT NULL,
  HITS NUMBER(5,0) DEFAULT 0 NULL,
  MISSES NUMBER(5,0) DEFAULT 0 NULL
);

CREATE INDEX IDX_CARDGAME_STAT_ITEM_PLAYER_ID ON CARDGAME_STAT_ITEM (ID, PLAYER_ID);
-- END S2U-42 --
