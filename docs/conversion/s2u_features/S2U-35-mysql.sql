-- S2U-35 --
CREATE TABLE COND_CONDITION (
  ID varchar(36) NOT NULL,
  TYPE varchar(99) NOT NULL,
  OPERATOR varchar(99) DEFAULT NULL,
  ARGUMENT varchar(999) DEFAULT NULL,
  SITE_ID varchar(36) NOT NULL,
  TOOL_ID varchar(99) NOT NULL,
  ITEM_ID varchar(99) DEFAULT NULL,
  PRIMARY KEY (ID),
  KEY IDX_CONDITION_SITE_ID (SITE_ID)
);

CREATE TABLE COND_PARENT_CHILD (
  PARENT_ID varchar(36) NOT NULL,
  CHILD_ID varchar(36) NOT NULL,
  PRIMARY KEY (PARENT_ID, CHILD_ID),
  KEY FK_CHILD_ID_CONDITION_ID (CHILD_ID),
  CONSTRAINT FK_CHILD_ID_CONDITION_ID FOREIGN KEY (CHILD_ID) REFERENCES COND_CONDITION (ID),
  CONSTRAINT FK_PARENT_ID_CONDITION_ID FOREIGN KEY (PARENT_ID) REFERENCES COND_CONDITION (ID)
);
-- END S2U-35 --
