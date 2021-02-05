-- SAK-44420
UPDATE poll_option SET deleted = 0 WHERE DELETED IS NULL;
ALTER TABLE poll_option MODIFY COLUMN DELETED BIT NOT NULL DEFAULT 0;
-- End SAK-44420

-- SAK-43497
alter table ASN_ASSIGNMENT_PROPERTIES modify VALUE varchar(4000) null;
-- END SAK-43407

-- SAK-44636 - Add LTI Lessons Placement checkbox - By default it is off for future tool installations
ALTER TABLE lti_tools ADD pl_lessonsselection TINYINT DEFAULT 0;
-- Existing records needed to be switched on
UPDATE lti_tools SET pl_lessonsselection = 1;
-- END SAK-44636

-- SAK-44753
alter table rbc_tool_item_rbc_assoc add constraint UKq4btc0dfymi80bb5mp3vp3r7u unique (rubric_id, toolId, itemId);
-- END SAK-44753

