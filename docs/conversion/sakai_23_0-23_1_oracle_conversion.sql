
-- SAK-48948
ALTER TABLE PINNED_SITES ADD HAS_BEEN_UNPINNED BIT NOT NULL;
-- SAK-48948 END

-- SAK-49537
-- Fix the template
UPDATE SAKAI_SITE_PAGE SET LAYOUT='0' WHERE PAGE_ID='!plussite-100';

-- Fix any sites created with the template
UPDATE SAKAI_SITE_PAGE SET LAYOUT='0' WHERE TITLE='Dashboard';
-- SAK-49537 END

--- SAK-49633
--- Fix Site Type in !plussite template
UPDATE SAKAI_SITE SET TYPE='course' WHERE SITE_ID = '!plussite';
--- SAK-49633 END
