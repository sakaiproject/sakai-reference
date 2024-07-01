-- S2U-23 --
ALTER TABLE SAM_PUBLISHEDFEEDBACK_T ADD SHOWCORRECTION bit(1) DEFAULT b'0' NOT NULL;
ALTER TABLE SAM_ASSESSFEEDBACK_T ADD SHOWCORRECTION bit(1) DEFAULT b'0' NOT NULL;
-- to preserve the complete functionality on assessments previous to the patch with 'showcorrectresponse' enabled
UPDATE SAM_PUBLISHEDFEEDBACK_T SET showcorrection = 1 WHERE showcorrection = 0 AND showcorrectresponse = 1;
UPDATE SAM_ASSESSFEEDBACK_T SET showcorrection = 1 WHERE showcorrection = 0 AND showcorrectresponse = 1;
-- END S2U-23 --
