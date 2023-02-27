-- SAK-43881 START
alter table MFR_TOPIC_T add SEND_TO_CALENDAR bit null;
alter table MFR_TOPIC_T add CALENDAR_BEGIN_ID varchar(255) null;
alter table MFR_TOPIC_T add CALENDAR_END_ID varchar(255) null;
alter table MFR_OPEN_FORUM_T add SEND_TO_CALENDAR bit null;
alter table MFR_OPEN_FORUM_T add CALENDAR_BEGIN_ID varchar(255) null;
alter table MFR_OPEN_FORUM_T add CALENDAR_END_ID varchar(255) null;
-- SAK-43881 END

