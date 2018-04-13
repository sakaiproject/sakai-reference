-- SAK-33432 - Restore all the past events of LB items that are LB pages
-- This is a copy of the MySQL script and may not work, this must be adapted and tested with oracle
CREATE TABLE EVENTS_TEMP (EVENT_ID INTEGER);

INSERT INTO EVENTS_TEMP (EVENT_ID)
SELECT SE.EVENT_ID FROM SAKAI_EVENT SE, LESSON_BUILDER_ITEMS LBI WHERE SE.REF = CONCAT('/lessonbuilder/item/', LBI.ID) AND LBI.SAKAIID <> '' AND LBI.PAGEID = 0;

UPDATE SAKAI_EVENT SE SET EVENT = REPLACE(EVENT, 'lessonbuilder.create', 'lessonbuilder.page.create') WHERE EXISTS (SELECT * FROM EVENTS_TEMP ET WHERE SE.EVENT_ID = ET.EVENT_ID);
UPDATE SAKAI_EVENT SE SET EVENT = REPLACE(EVENT, 'lessonbuilder.update', 'lessonbuilder.page.update') WHERE EXISTS (SELECT * FROM EVENTS_TEMP ET WHERE SE.EVENT_ID = ET.EVENT_ID);
UPDATE SAKAI_EVENT SE SET EVENT = REPLACE(EVENT, 'lessonbuilder.delete', 'lessonbuilder.page.delete') WHERE EXISTS (SELECT * FROM EVENTS_TEMP ET WHERE SE.EVENT_ID = ET.EVENT_ID);
UPDATE SAKAI_EVENT SE SET EVENT = REPLACE(EVENT, 'lessonbuilder.remove', 'lessonbuilder.page.remove') WHERE EXISTS (SELECT * FROM EVENTS_TEMP ET WHERE SE.EVENT_ID = ET.EVENT_ID);
UPDATE SAKAI_EVENT SE SET EVENT = REPLACE(EVENT, 'lessonbuilder.read', 'lessonbuilder.page.read') WHERE EXISTS (SELECT * FROM EVENTS_TEMP ET WHERE SE.EVENT_ID = ET.EVENT_ID);
UPDATE SAKAI_EVENT SE SET EVENT = REPLACE(EVENT, 'item', 'page'), REF = REPLACE(REF, 'item', 'page') WHERE EXISTS (SELECT * FROM EVENTS_TEMP ET WHERE SE.EVENT_ID = ET.EVENT_ID);

DROP TABLE EVENTS_TEMP;
-- END SAK-33432

