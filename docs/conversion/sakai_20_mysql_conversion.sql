-- SAK_41228
UPDATE CM_MEMBERSHIP_T SET USER_ID = LOWER(USER_ID);
UPDATE CM_ENROLLMENT_T SET USER_ID = LOWER(USER_ID);
UPDATE CM_OFFICIAL_INSTRUCTORS_T SET INSTRUCTOR_ID = LOWER(INSTRUCTOR_ID);
-- End of SAK_41228

-- SAK-41391

ALTER TABLE POLL_OPTION ADD OPTION_ORDER INTEGER;

-- END SAK-41391

-- SAK-34741
ALTER TABLE SAM_ITEM_T ADD ISEXTRACREDIT TINYINT(1);
ALTER TABLE SAM_PUBLISHEDITEM_T ADD ISEXTRACREDIT TINYINT(1);
-- END SAK-34741