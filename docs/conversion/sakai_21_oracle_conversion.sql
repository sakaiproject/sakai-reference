-- clear unchanged bundle properties
DELETE from SAKAI_MESSAGE_BUNDLE where PROP_VALUE is NULL;
