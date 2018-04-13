-- SAM-3012 - Update samigo events
-- Update camel case events
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.submit' WHERE EVENT = 'sam.assessmentSubmitted';
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.graded.auto' WHERE EVENT = 'sam.assessmentAutoGraded';
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.submit.auto"' WHERE EVENT = 'sam.assessmentAutoSubmitted';
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.submit.timer.thrd' WHERE EVENT = 'sam.assessmentTimedSubmitted';
UPDATE SAKAI_EVENT SET EVENT = 'sam.pubassessment.remove' WHERE EVENT = 'sam.pubAssessment.remove';

-- Update name of submission events
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.submit.from_last' WHERE EVENT = 'sam.submit.from_last_page';
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.submit.from_toc' WHERE EVENT = 'sam.submit.from_toc';
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.submit.thread' WHERE EVENT = 'sam.assessment.thread_submit';
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.submit.timer' WHERE EVENT = 'sam.assessment.timer_submit';
UPDATE SAKAI_EVENT SET EVENT = 'sam.assessment.submit.timer.url' WHERE EVENT = 'sam.assessment.timer_submit.url';

-- END SAM-3012

-- SAK-33432 - Restore all the past events of LB items that are LB pages
-- This is a copy of the MySQL script and may not work, this must be adapted and tested with oracle
CREATE TABLE EVENTS_TEMP (EVENT_ID INTEGER);

INSERT INTO EVENTS_TEMP (EVENT_ID)
SELECT SE.EVENT_ID FROM SAKAI_EVENT SE, LESSON_BUILDER_ITEMS LBI WHERE SE.REF = CONCAT('/lessonbuilder/item/', LBI.ID) AND LBI.SAKAIID <> '' AND LBI.PAGEID = 0;

UPDATE SAKAI_EVENT SE SET EVENT = REPLACE(EVENT, 'item', 'page'), REF = REPLACE(REF, 'item', 'page') WHERE EXISTS (SELECT * FROM EVENTS_TEMP ET WHERE SE.EVENT_ID = ET.EVENT_ID);

DROP TABLE EVENTS_TEMP;
-- END SAK-33432
