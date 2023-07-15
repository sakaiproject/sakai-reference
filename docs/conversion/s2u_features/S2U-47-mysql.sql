-- S2U-47 --
CREATE TABLE `meeting_providers` (
  `provider_id` varchar(99) NOT NULL,
  `provider_name` varchar(255) NOT NULL,
  PRIMARY KEY (`provider_id`)
);

CREATE TABLE `meetings` (
  `meeting_id` varchar(99) NOT NULL,
  `meeting_description` text,
  `meeting_end_date` datetime DEFAULT NULL,
  `meeting_owner_id` varchar(99) DEFAULT NULL,
  `meeting_site_id` varchar(99) DEFAULT NULL,
  `meeting_start_date` datetime DEFAULT NULL,
  `meeting_title` varchar(255) NOT NULL,
  `meeting_url` varchar(255) DEFAULT NULL,
  `meeting_provider_id` varchar(99) DEFAULT NULL,
  PRIMARY KEY (`meeting_id`),
  KEY `FK_m_mp` (`meeting_provider_id`),
  CONSTRAINT `FK_m_mp` FOREIGN KEY (`meeting_provider_id`) REFERENCES `meeting_providers` (`provider_id`)
);

CREATE TABLE `meeting_properties` (
  `prop_id` bigint NOT NULL AUTO_INCREMENT,
  `prop_name` varchar(255) NOT NULL,
  `prop_value` varchar(255) DEFAULT NULL,
  `prop_meeting_id` varchar(99) DEFAULT NULL,
  PRIMARY KEY (`prop_id`),
  KEY `FK_mp_m` (`prop_meeting_id`),
  CONSTRAINT `FK_mp_m` FOREIGN KEY (`prop_meeting_id`) REFERENCES `meetings` (`meeting_id`)
);

CREATE TABLE `meeting_attendees` (
  `attendee_id` bigint NOT NULL AUTO_INCREMENT,
  `attendee_object_id` varchar(255) DEFAULT NULL,
  `attendee_type` int DEFAULT NULL,
  `attendee_meeting_id` varchar(99) DEFAULT NULL,
  PRIMARY KEY (`attendee_id`),
  KEY `FK_ma_m` (`attendee_meeting_id`),
  CONSTRAINT `FK_ma_m` FOREIGN KEY (`attendee_meeting_id`) REFERENCES `meetings` (`meeting_id`)
);
-- S2U-47 --