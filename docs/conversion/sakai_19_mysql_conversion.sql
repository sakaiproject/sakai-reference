-- SAK-38427

ALTER TABLE MFR_TOPIC_T ADD COLUMN ALLOW_EMAIL_NOTIFICATIONS BIT(1) NOT NULL DEFAULT 1;
ALTER TABLE MFR_TOPIC_T ADD COLUMN INCLUDE_CONTENTS_IN_EMAILS BIT(1) NOT NULL DEFAULT 1;

-- END SAK-38427

-- SAK-33969
ALTER TABLE MFR_OPEN_FORUM_T ADD RESTRICT_PERMISSIONS_FOR_GROUPS BIT(1) DEFAULT FALSE;
ALTER TABLE MFR_TOPIC_T ADD RESTRICT_PERMISSIONS_FOR_GROUPS BIT(1) DEFAULT FALSE;
-- SAK-33969
