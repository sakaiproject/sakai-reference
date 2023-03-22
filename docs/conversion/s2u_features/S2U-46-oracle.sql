-- S2U-46 --
CREATE TABLE mc_site_synchronization (
  id varchar2(99) NOT NULL,
  site_id varchar2(255) NOT NULL,
  team_id varchar2(255) NOT NULL,
  forced raw(1) DEFAULT NULL,
  status number(1,0) DEFAULT NULL,
  status_updated_at timestamp(6) DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT UKmc_ss UNIQUE (site_id,team_id)
);

CREATE TABLE mc_group_synchronization (
  id varchar2(99) NOT NULL,
  parentId varchar2(99) DEFAULT NULL,
  group_id varchar2(255) NOT NULL,
  channel_id varchar2(255) NOT NULL,
  status number(1,0) DEFAULT NULL,
  status_updated_at timestamp(6) DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT UKmc_gs UNIQUE (parentId,group_id,channel_id),
  CONSTRAINT FKmc_gs_ss FOREIGN KEY (parentId) REFERENCES mc_site_synchronization (id) ON DELETE CASCADE
);

CREATE TABLE mc_config_item (
  item_key varchar2(255) NOT NULL,
  value varchar2(255) NOT NULL,
  PRIMARY KEY (item_key)
);

CREATE TABLE mc_log (
  id number(19, 0) NOT NULL,
  context clob,
  event varchar2(255) DEFAULT NULL,
  event_date timestamp(6) DEFAULT NULL,
  status number(1,0) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- Generate ID using sequence and trigger
CREATE SEQUENCE mc_log_seq START WITH 1 INCREMENT BY 1;
-- S2U-46 --
