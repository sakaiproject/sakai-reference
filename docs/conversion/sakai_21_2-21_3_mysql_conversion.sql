-- Start SAK-41604
ALTER TABLE RBC_EVALUATION ADD COLUMN EVALUATED_ITEM_OWNER_TYPE INT;
-- End SAK-41604

-- SAK-45987
CREATE TABLE rbc_returned_criterion_out (
  id BIGINT AUTO_INCREMENT NOT NULL,
  comments LONGTEXT NULL,
  criterion_id BIGINT DEFAULT NULL NULL,
  points DOUBLE DEFAULT NULL NULL,
  pointsAdjusted BIT NOT NULL,
  selected_rating_id BIGINT DEFAULT NULL NULL,
  CONSTRAINT PK_RBC_RETURNED_CRITERION_OUT PRIMARY KEY (id)
);

CREATE TABLE rbc_returned_criterion_outs (
  rbc_returned_evaluation_id BIGINT NOT NULL,
  rbc_returned_criterion_out_id BIGINT NOT NULL,
  UNIQUE (rbc_returned_criterion_out_id)
);

CREATE TABLE rbc_returned_evaluation (
  id BIGINT AUTO_INCREMENT NOT NULL,
  original_evaluation_id BIGINT NOT NULL,
  overallComment VARCHAR(255) NULL,
  CONSTRAINT PK_RBC_RETURNED_EVALUATION PRIMARY KEY (id)
);

CREATE INDEX FK3sroha5yjh3cbvq0on02wf3fk ON rbc_returned_criterion_out(criterion_id);
CREATE INDEX rbc_ret_orig_id ON rbc_returned_evaluation(original_evaluation_id);
CREATE INDEX returned_evaluation_id_key ON rbc_returned_criterion_outs(rbc_returned_evaluation_id);

ALTER TABLE rbc_returned_criterion_out ADD CONSTRAINT FK3sroha5yjh3cbvq0on02wf3fk FOREIGN KEY (criterion_id) REFERENCES rbc_criterion (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_returned_criterion_outs ADD CONSTRAINT returned_criterion_out_id_fk FOREIGN KEY (rbc_returned_criterion_out_id) REFERENCES rbc_returned_criterion_out (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE rbc_returned_criterion_outs ADD CONSTRAINT returned_evalution_id_fk FOREIGN KEY (rbc_returned_evaluation_id) REFERENCES rbc_returned_evaluation (id) ON UPDATE RESTRICT ON DELETE RESTRICT;
-- END SAK-45987
