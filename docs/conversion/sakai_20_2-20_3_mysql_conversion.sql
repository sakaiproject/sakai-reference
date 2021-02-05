-- START SAK-42371
ALTER TABLE rbc_evaluation ADD COLUMN status int(11) NOT NULL;
UPDATE rbc_evaluation SET status = 2;
-- END SAK-42371
