-- clear unchanged bundle properties
DELETE SAKAI_MESSAGE_BUNDLE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;
