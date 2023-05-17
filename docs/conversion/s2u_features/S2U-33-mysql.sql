-- S2U-33 --
CREATE TABLE `tagservice_tagassociation` (
  `id` varchar(99) NOT NULL,
  `tag_id` varchar(255) NOT NULL,
  `item_id` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK7tc7vcvcb0bw8moqdu3giik6o` (`tag_id`,`item_id`)
);
-- END S2U-33 --
