-- S2U-32 --
CREATE TABLE tagservice_tagassociation (
  id varchar2(99) NOT NULL,
  tag_id varchar2(255) NOT NULL,
  item_id varchar2(255) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT UK7tc7vcvcb0bw8moqdu3giik6o UNIQUE (tag_id,item_id)
);
-- END S2U-32 --
