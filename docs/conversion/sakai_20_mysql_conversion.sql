-- SAK_41228
UPDATE cm_membership_t SET USER_ID = LOWER(USER_ID);
UPDATE cm_enrollment_t SET USER_ID = LOWER(USER_ID);
UPDATE cm_official_instructors_t SET INSTRUCTOR_ID = LOWER(INSTRUCTOR_ID);
-- End of SAK_41228
