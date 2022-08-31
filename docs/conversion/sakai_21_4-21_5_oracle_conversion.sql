-- SAK-47291
UPDATE gb_gradable_object_t SET EXTERNAL_APP_NAME = 'sakai.assignment.grades' WHERE EXTERNAL_ID LIKE '/assignment/a/%';
UPDATE gb_gradable_object_t SET EXTERNAL_APP_NAME = 'sakai.lessonbuildertool' WHERE EXTERNAL_ID LIKE 'lesson-builder:%';
UPDATE gb_gradable_object_t SET EXTERNAL_APP_NAME = 'sakai.attendance' WHERE EXTERNAL_ID LIKE 'sakai.attendance.%';
UPDATE gb_gradable_object_t SET EXTERNAL_APP_NAME = 'sakai.samigo' WHERE REGEXP_LIKE(EXTERNAL_ID, '^[0-9]+$');
-- END SAK-47291
