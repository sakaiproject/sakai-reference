-- SAK-46974
ALTER TABLE MFR_MESSAGE_T ADD SCHEDULER NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE MFR_MESSAGE_T ADD SCHEDULED_DATE TIMESTAMP DEFAULT NULL;
-- End SAK-46974
-- SAK-46436
ALTER TABLE TASKS ADD TASK_OWNER VARCHAR2(99 CHAR);

CREATE TABLE TASKS_ASSIGNED
(
   ID              NUMBER(19,0) NOT NULL,
   TASK_ID         NUMBER(19,0) NOT NULL,
   ASSIGNATION_TYPE   VARCHAR2(5) NOT NULL,
   OBJECT_ID       VARCHAR2(99 CHAR),
   PRIMARY KEY(ID),
   CONSTRAINT FK_TASKS_ASSIGNED_TASKS FOREIGN KEY(TASK_ID) REFERENCES TASKS (ID)
);

CREATE SEQUENCE TASKS_ASSIGNED_S MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20;
CREATE INDEX IDX_TASKS_ASSIGNED ON TASKS_ASSIGNED (TASK_ID);

-- SAK-46178
RENAME COLUMN rbc_tool_item_rbc_assoc.ownerId TO siteId;
DROP INDEX rbc_tool_item_owner;
CREATE INDEX rbc_tool_item_active ON rbc_tool_item_rbc_assoc(toolId, itemId, active);
ALTER TABLE rbc_criterion ADD order_index NUMBER(1,0) NULL;
ALTER TABLE rbc_rating ADD order_index NUMBER(1,0) NULL;
UPDATE rbc_rating r, rbc_criterion_ratings cr SET r.criterion_id = cr.rbc_criterion_id, r.order_index = cr.order_index WHERE cr.ratings_id = r.id;
UPDATE rbc_criterion c, rbc_rubric_criterions rc SET c.rubric_id = rc.rbc_rubric_id, c.order_index = rc.order_index WHERE rc.criterions_id = c.id;
-- END SAK-46178
