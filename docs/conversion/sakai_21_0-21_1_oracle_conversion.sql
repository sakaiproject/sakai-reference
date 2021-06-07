-- SAK-45435
ALTER TABLE lti_tools ADD lti13_platform_public_old CLOB;
ALTER TABLE lti_tools ADD lti13_platform_public_old_at DATE DEFAULT NULL;
-- End SAK-45435

-- START SAK-45137
UPDATE rbc_rating SET title = 'Title' WHERE title IS NULL;
ALTER TABLE rbc_rating MODIFY title VARCHAR2(255) NOT NULL;
UPDATE rbc_rating SET points = 0 WHERE points IS NULL;
ALTER TABLE rbc_rating MODIFY points FLOAT NOT NULL;
-- END SAK-45137

-- START SAK-45601
CREATE TABLE TINCANAPI_EVENT (
EVENT VARCHAR(255) NOT NULL,
VERB VARCHAR(255) NOT NULL,
ORIGIN VARCHAR(255) NOT NULL,
OBJECT VARCHAR(255) NOT NULL,
EVENT_SUPPLIER VARCHAR(255),
PRIMARY KEY (EVENT));
--Initial data that were in the ifs:
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('user.login', 'initialized', 'sakai.system', 'session-started', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('user.login.container', 'initialized', 'sakai.system', 'session-started', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('user.logout', 'exited', 'sakai.system', 'session-ended', 'logout');
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('annc.read', 'experienced', 'announcement', 'view-announcement', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('calendar.read', 'experienced', 'calendar', 'view-calendar', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('chat.new', 'responded', 'chat', 'view-chats', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('chat.read', 'experienced', 'chat', 'view-chats', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('content.read', 'interacted', 'sakai.resources', 'view-resource', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('content.new', 'shared', 'sakai.resources', 'add-resource', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('content.revise', 'shared', 'sakai.resources', 'edit-resource', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('gradebook.read', 'experienced', 'gradebook', 'view-grades', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('lessonbuilder.page.read', 'experienced', 'lessonbuilder', 'view-lesson', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('lessonbuilder.item.read', 'experienced', 'lessonbuilder', 'view-lesson', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('news.read', 'experienced', 'news', 'view-news', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('podcast.read', 'experienced', 'podcast', 'view-podcast', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('podcast.read.public', 'experienced', 'podcast', 'view-podcast', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('podcast.read.site', 'experienced', 'podcast', 'view-podcast', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('syllabus.read', 'experienced', 'syllabus', 'view-syllabus', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('webcontent.read', 'experienced', 'webcontent', 'view-web-content', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('wiki.new', 'initialized', 'rwiki', 'add-wiki-page', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('wiki.revise', 'shared', 'rwiki', 'edit-wiki-page', null);
INSERT INTO TINCANAPI_EVENT (EVENT, VERB, ORIGIN, OBJECT, EVENT_SUPPLIER) VALUES('wiki.read', 'experienced', 'rwiki', 'view-wiki-page', null);
-- END SAK-45601
