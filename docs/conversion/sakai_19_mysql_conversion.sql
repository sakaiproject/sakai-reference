-- SAK-38427

ALTER TABLE MFR_TOPIC_T ADD COLUMN ALLOW_EMAIL_NOTIFICATIONS BIT(1) NOT NULL DEFAULT 1;
ALTER TABLE MFR_TOPIC_T ADD COLUMN INCLUDE_CONTENTS_IN_EMAILS BIT(1) NOT NULL DEFAULT 1;

-- END SAK-38427

-- SAK-39967

CREATE INDEX contentreview_provider_id_idx on CONTENTREVIEW_ITEM (providerId, externalId);

-- End SAK-39967