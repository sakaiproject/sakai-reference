-- SAK-44420
UPDATE POLL_OPTION SET DELETED = 0 WHERE DELETED IS NULL;
ALTER TABLE POLL_OPTION MODIFY DELETED NUMBER(1,0) DEFAULT 0 NOT NULL;
-- End SAK-44420

-- SAK-44636 - Add LTI Lessons Placement checkbox - By default it is off for future tool installations
ALTER TABLE lti_tools ADD pl_lessonsselection NUMBER(1) DEFAULT 0;
-- Existing records needed to be switched on
UPDATE lti_tools SET pl_lessonsselection = 1;
-- END SAK-44636
