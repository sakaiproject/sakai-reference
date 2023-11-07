-- S2U-46 --
CREATE TABLE `mc_site_synchronization` (
  `id` varchar(99) NOT NULL,
  `site_id` varchar(255) NOT NULL,
  `team_id` varchar(255) NOT NULL,
  `forced` bit(1) DEFAULT NULL,
  `date_from` datetime DEFAULT NULL,
  `date_to` datetime DEFAULT NULL,
  `status` int DEFAULT NULL,
  `status_updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKmc_ss` (`site_id`,`team_id`)
);

CREATE TABLE `mc_group_synchronization` (
  `id` varchar(99) NOT NULL,
  `parentId` varchar(99) DEFAULT NULL,
  `group_id` varchar(255) NOT NULL,
  `channel_id` varchar(255) NOT NULL,
  `status` int DEFAULT NULL,
  `status_updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKmc_gs` (`parentId`,`group_id`,`channel_id`),
  CONSTRAINT `FKmc_gs_ss` FOREIGN KEY (`parentId`) REFERENCES `mc_site_synchronization` (`id`) ON DELETE CASCADE
);

CREATE TABLE `mc_config_item` (
  `item_key` varchar(255) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`item_key`)
);

CREATE TABLE `mc_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `context` longtext,
  `event` varchar(255) DEFAULT NULL,
  `event_date` datetime DEFAULT NULL,
  `status` int DEFAULT NULL,
  PRIMARY KEY (`id`)
);
