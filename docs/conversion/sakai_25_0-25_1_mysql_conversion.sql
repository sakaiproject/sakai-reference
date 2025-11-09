-- SAK-50378 --
-- These are columns dropped by SAK-50378 in 25.0 but were left out of
-- the Sakai 25 conversion scrpts to allow two way reverting between 25 and 23
-- in case problems were encountered.   They can be dropped in 25.1.

ALTER TABLE lti_content DROP COLUMN pagetitle;
ALTER TABLE lti_content DROP COLUMN toolorder;
ALTER TABLE lti_content DROP COLUMN consumerkey;
ALTER TABLE lti_content DROP COLUMN secret;
ALTER TABLE lti_content DROP COLUMN settings_ext;
ALTER TABLE lti_content DROP COLUMN fa_icon;

ALTER TABLE lti_tools DROP COLUMN allowtitle;
ALTER TABLE lti_tools DROP COLUMN pagetitle;
ALTER TABLE lti_tools DROP COLUMN allowpagetitle;
ALTER TABLE lti_tools DROP COLUMN allowlaunch;
ALTER TABLE lti_tools DROP COLUMN allowframeheight;
ALTER TABLE lti_tools DROP COLUMN allowfa_icon;
ALTER TABLE lti_tools DROP COLUMN toolorder;
ALTER TABLE lti_tools DROP COLUMN allowsettings_ext;
ALTER TABLE lti_tools DROP COLUMN allowconsumerkey;
ALTER TABLE lti_tools DROP COLUMN allowsecret;
ALTER TABLE lti_tools DROP COLUMN lti11_launch_type;
-- END SAK-50378 --

-- SAK-51998
ALTER TABLE lti_content DROP COLUMN lti13_settings;
ALTER TABLE lti_tools DROP COLUMN lti13_settings;
ALTER TABLE lti_content DROP COLUMN lti13;
-- END SAK-51998

-- SAK-51573
DROP TABLE PROFILE_PREFERENCES_T;
-- END SAK-51573
