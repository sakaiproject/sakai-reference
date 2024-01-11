-- S2U-47 --
CREATE TABLE meeting_providers (
  provider_id varchar2(99) NOT NULL,
  provider_name varchar2(255) NOT NULL,
  PRIMARY KEY (provider_id)
);

CREATE TABLE meetings (
  meeting_id varchar2(99) NOT NULL,
  meeting_description clob,
  meeting_end_date timestamp(6) DEFAULT NULL,
  meeting_owner_id varchar2(99) DEFAULT NULL,
  meeting_site_id varchar2(99) DEFAULT NULL,
  meeting_start_date timestamp(6) DEFAULT NULL,
  meeting_title varchar2(255) NOT NULL,
  meeting_url varchar2(255) DEFAULT NULL,
  meeting_provider_id varchar2(99) DEFAULT NULL,
  PRIMARY KEY (meeting_id)
,
  CONSTRAINT FK_m_mp FOREIGN KEY (meeting_provider_id) REFERENCES meeting_providers (provider_id)
);

CREATE INDEX FK_m_mp ON meetings (meeting_provider_id);

CREATE TABLE meeting_properties (
  prop_id number(19, 0) NOT NULL,
  prop_name varchar2(255) NOT NULL,
  prop_value varchar2(255) DEFAULT NULL,
  prop_meeting_id varchar2(99) DEFAULT NULL,
  PRIMARY KEY (prop_id)
,
  CONSTRAINT FK_mp_m FOREIGN KEY (prop_meeting_id) REFERENCES meetings (meeting_id)
);

-- Generate ID using sequence and trigger
CREATE SEQUENCE MEETING_PROPERTY_S START WITH 1 INCREMENT BY 1;

CREATE INDEX FK_mp_m ON meeting_properties (prop_meeting_id);

CREATE TABLE meeting_attendees (
  attendee_id number(19, 0) NOT NULL,
  attendee_object_id varchar2(255) DEFAULT NULL,
  attendee_type number(1, 0) DEFAULT NULL,
  attendee_meeting_id varchar2(99) DEFAULT NULL,
  PRIMARY KEY (attendee_id)
,
  CONSTRAINT FK_ma_m FOREIGN KEY (attendee_meeting_id) REFERENCES meetings (meeting_id)
);

-- Generate ID using sequence and trigger
CREATE SEQUENCE MEETING_ATTENDEE_S START WITH 1 INCREMENT BY 1;

CREATE INDEX FK_ma_m ON meeting_attendees (attendee_meeting_id);
-- S2U-47 --