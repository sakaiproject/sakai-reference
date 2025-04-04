-- Begin SAK-50526
ALTER TABLE CONV_TOPICS ADD COLUMN UPVOTES int NULL DEFAULT 0;
ALTER TABLE CONV_TOPIC_STATUS ADD COLUMN UPVOTED bit(1) NULL DEFAULT b'0';
ALTER TABLE CONV_POSTS
  ADD COLUMN NUMBER_OF_THREAD_UPVOTES int NULL DEFAULT 0,
  ADD COLUMN REACTION_COUNT int NULL DEFAULT 0;

-- Step 1: Drop the unique index
ALTER TABLE CONV_POST_REACTIONS DROP INDEX UniquePostReactions;

-- Step 2: Run the original CASE update
UPDATE CONV_POST_REACTIONS
SET REACTION = CASE REACTION
    WHEN 0 THEN 2  -- GOOD_QUESTION → GOOD_IDEA
    WHEN 1 THEN 2  -- GOOD_ANSWER → GOOD_IDEA
    WHEN 2 THEN 1  -- LOVE_IT → 1
    WHEN 3 THEN 2  -- GOOD_IDEA → 2
    WHEN 4 THEN 3  -- KEY → 3
    ELSE REACTION
END;

-- Step 3: Remove duplicates, keeping the row with the lowest ID
DELETE t1 FROM CONV_POST_REACTIONS t1
  INNER JOIN CONV_POST_REACTIONS t2
  WHERE t1.POST_ID = t2.POST_ID
  AND t1.USER_ID = t2.USER_ID
  AND t1.REACTION = t2.REACTION
  AND t1.ID > t2.ID;

-- Step 4: Re-add the unique index
ALTER TABLE CONV_POST_REACTIONS ADD UNIQUE KEY UniquePostReactions (POST_ID, USER_ID, REACTION);

-- Now do topics
ALTER TABLE CONV_TOPIC_REACTIONS DROP INDEX UniqueTopicReactions;

UPDATE CONV_TOPIC_REACTIONS
SET REACTION = CASE REACTION
    WHEN 0 THEN 2  -- GOOD_QUESTION → GOOD_IDEA
    WHEN 1 THEN 2  -- GOOD_ANSWER → GOOD_IDEA
    WHEN 2 THEN 1  -- LOVE_IT → 1
    WHEN 3 THEN 2  -- GOOD_IDEA → 2
    WHEN 4 THEN 3  -- KEY → 3
    ELSE REACTION
END;

DELETE t1 FROM CONV_TOPIC_REACTIONS t1
  INNER JOIN CONV_TOPIC_REACTIONS t2
  WHERE t1.TOPIC_ID = t2.TOPIC_ID
  AND t1.USER_ID = t2.USER_ID
  AND t1.REACTION = t2.REACTION
  AND t1.ID > t2.ID;

ALTER TABLE CONV_TOPIC_REACTIONS ADD UNIQUE KEY UniqueTopicReactions (TOPIC_ID, USER_ID, REACTION);

-- Now post totals
ALTER TABLE CONV_POST_REACTION_TOTALS DROP INDEX UniquePostReactionTotals;

UPDATE CONV_POST_REACTION_TOTALS
SET REACTION = CASE REACTION
    WHEN 0 THEN 2  -- GOOD_QUESTION → GOOD_IDEA
    WHEN 1 THEN 2  -- GOOD_ANSWER → GOOD_IDEA
    WHEN 2 THEN 1  -- LOVE_IT → 1
    WHEN 3 THEN 2  -- GOOD_IDEA → 2
    WHEN 4 THEN 3  -- KEY → 3
    ELSE REACTION
END;

DELETE t1 FROM CONV_POST_REACTION_TOTALS t1
  INNER JOIN CONV_POST_REACTION_TOTALS t2
  WHERE t1.POST_ID = t2.POST_ID
  AND t1.REACTION = t2.REACTION
  AND t1.ID > t2.ID;

ALTER TABLE CONV_POST_REACTION_TOTALS ADD UNIQUE KEY UniquePostReactionTotals (POST_ID, REACTION);

-- Now topic totals
ALTER TABLE CONV_TOPIC_REACTION_TOTALS DROP INDEX UniqueTopicReactionTotals;

UPDATE CONV_TOPIC_REACTION_TOTALS
SET REACTION = CASE REACTION
    WHEN 0 THEN 2  -- GOOD_QUESTION → GOOD_IDEA
    WHEN 1 THEN 2  -- GOOD_ANSWER → GOOD_IDEA
    WHEN 2 THEN 1  -- LOVE_IT → 1
    WHEN 3 THEN 2  -- GOOD_IDEA → 2
    WHEN 4 THEN 3  -- KEY → 3
    ELSE REACTION
END;

DELETE t1 FROM CONV_TOPIC_REACTION_TOTALS t1
  INNER JOIN CONV_TOPIC_REACTION_TOTALS t2
  WHERE t1.TOPIC_ID = t2.TOPIC_ID
  AND t1.REACTION = t2.REACTION
  AND t1.ID > t2.ID;

ALTER TABLE CONV_TOPIC_REACTION_TOTALS ADD UNIQUE KEY UniqueTopicReactionTotals (TOPIC_ID, REACTION);

-- End SAK-50526
