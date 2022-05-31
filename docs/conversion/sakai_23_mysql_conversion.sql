-- SAK-46974
ALTER TABLE MFR_MESSAGE_T ADD COLUMN SCHEDULER bit(1) DEFAULT 0 NOT NULL;
ALTER TABLE MFR_MESSAGE_T ADD COLUMN SCHEDULED_DATE DATETIME DEFAULT NULL;
-- End SAK-46974
-- SAK-46436
ALTER TABLE TASKS ADD COLUMN TASK_OWNER VARCHAR(99);

CREATE TABLE TASKS_ASSIGNED (
    ID           BIGINT      AUTO_INCREMENT PRIMARY KEY,
    TASK_ID      BIGINT      NOT NULL,
    ASSIGNATION_TYPE VARCHAR(5)  NOT NULL,
    OBJECT_ID    VARCHAR(99),
    CONSTRAINT FK_TASKS_ASSIGNED_TASKS FOREIGN KEY (TASK_ID) REFERENCES TASKS (ID)
);
CREATE INDEX IDX_TASKS_ASSIGNED ON TASKS_ASSIGNED (TASK_ID);

-- SAK-46178
ALTER TABLE rbc_tool_item_rbc_assoc CHANGE ownerId siteId varchar(99);
DROP INDEX rbc_tool_item_owner ON rbc_tool_item_rbc_assoc;
CREATE INDEX rbc_tool_item_active ON rbc_tool_item_rbc_assoc(toolId, itemId, active);
ALTER TABLE rbc_criterion ADD order_index INT DEFAULT NULL;
ALTER TABLE rbc_rating ADD order_index INT DEFAULT NULL;
UPDATE rbc_rating r, rbc_criterion_ratings cr SET r.criterion_id = cr.rbc_criterion_id, r.order_index = cr.order_index WHERE cr.ratings_id = r.id;
UPDATE rbc_criterion c, rbc_rubric_criterions rc SET c.rubric_id = rc.rbc_rubric_id, c.order_index = rc.order_index WHERE rc.criterions_id = c.id;
-- END SAK-46178
