-- ===========================================================================
-- OpenRP Framework -- database schema
--
-- Structure only: no player data, no map data. Seeds the minimum the gamemode
-- needs to start: the `server` settings row and the two default factions
-- (SAPD and FDSA).
--
-- Usage:   mysql -u root -p < database/schema.sql
-- Then set the same database name / credentials in mysql.ini.
-- ===========================================================================

/*!40101 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

CREATE DATABASE IF NOT EXISTS `omprp` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;
USE `omprp`;

-- Dumping structure for table accounts
CREATE TABLE IF NOT EXISTS `accounts` (
  `account_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_name` varchar(24) NOT NULL,
  `account_password` varchar(65) NOT NULL,
  `account_online` int(11) NOT NULL DEFAULT 0,
  `account_stafflevel` tinyint(4) NOT NULL DEFAULT 0,
  `account_staffrole` int(10) unsigned NOT NULL DEFAULT 0,
  `account_contributor` tinyint(4) NOT NULL DEFAULT 0,
  `account_premiumlevel` tinyint(4) NOT NULL DEFAULT 0,
  `account_respected` int(11) NOT NULL DEFAULT 0,
  `account_reports_done` int(11) NOT NULL DEFAULT 0,
  `account_questions_done` int(11) NOT NULL DEFAULT 0,
  `account_supporter` int(11) NOT NULL DEFAULT 0,
  `account_forumname` varchar(64) DEFAULT 'Undefined',
  `account_discordname` varchar(64) NOT NULL DEFAULT 'Undefined',
  `account_email` varchar(256) NOT NULL DEFAULT 'Undefined',
  `account_email_verifycode` varchar(64) NOT NULL DEFAULT 'Undefined',
  `account_email_verify_sent_at` int(11) DEFAULT NULL,
  `account_email_verified` tinyint(4) NOT NULL DEFAULT 0,
  `account_gunaccess` tinyint(11) NOT NULL DEFAULT 0,
  `account_namestyle` int(11) NOT NULL DEFAULT 1,
  `account_lastip` varchar(32) NOT NULL DEFAULT '0.0.0.0.0',
  `account_setting_tips` int(11) NOT NULL DEFAULT 1,
  `account_setting_gangzones` tinyint(4) NOT NULL DEFAULT 1,
  `account_setting_blinkers` tinyint(4) NOT NULL DEFAULT 1,
  `account_setting_drawdistance` smallint(5) unsigned NOT NULL DEFAULT 750,
  `account_setting_admin_cmd` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `account_setting_admin_wrn` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `account_setting_admin_msg` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `account_setting_helper_msg` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `account_gunban` int(11) NOT NULL DEFAULT 0,
  `account_facban` int(11) NOT NULL DEFAULT 0,
  `account_bikeban` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `account_vehban` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `account_reward_amount` int(11) NOT NULL DEFAULT 0,
  `account_reward_claimed` int(11) NOT NULL DEFAULT 0,
  `account_reward_ipaddress` varchar(64) NOT NULL DEFAULT '0.0.0.0',
  `account_resetpass_token` varchar(24) NOT NULL DEFAULT '0',
  `account_resetpass_expire` int(11) NOT NULL DEFAULT 0,
  `account_registration_legacy` tinyint(4) NOT NULL DEFAULT 0,
  `account_lastlogin` datetime DEFAULT NULL,
  `account_name_style` tinyint(4) NOT NULL DEFAULT 0,
  `account_register_date` int(11) NOT NULL DEFAULT 0,
  `account_ucphandler` int(11) NOT NULL DEFAULT 0,
  `account_discord` varchar(50) DEFAULT NULL,
  `account_quiz_status` enum('pending','passed','failed') NOT NULL DEFAULT 'pending',
  `account_quiz_failed_tries` tinyint(4) DEFAULT NULL,
  `account_quiz_cooldown` timestamp NULL DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `twofa_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `twofa_attempts` tinyint unsigned NOT NULL DEFAULT 0,
  `twofa_last_sent` int(11) DEFAULT 0,
  `twofa_code_hash` varchar(255) DEFAULT NULL,
  `twofa_expires` int(10) unsigned DEFAULT NULL,
  `discord_id` bigint(20) unsigned DEFAULT NULL,
  `discord_verified` tinyint(1) NOT NULL DEFAULT 0,
  `discord_linked_at` int(11) DEFAULT NULL,
  `password_reset_version` int(11) NOT NULL DEFAULT 0,
  `password_reset_at` int(11) DEFAULT 0,
  `password_reset_token` varchar(64) DEFAULT NULL,
  `password_reset_expires` datetime DEFAULT NULL,
  `remember_token_hash` varchar(255) DEFAULT NULL,
  `remember_token_expires` int(11) DEFAULT NULL,
  `account_media_banned` tinyint(1) NOT NULL DEFAULT 0,
  `account_sprintban` int(11) NOT NULL DEFAULT 0,
  `account_ddsetting` tinyint(4) NOT NULL DEFAULT 2,
  `account_ddmessage` tinyint(4) NOT NULL DEFAULT 0,
  `account_rppoints` int(11) NOT NULL DEFAULT 0,
  `account_sports_balance` int(11) DEFAULT 0,
  `admin_message` text DEFAULT NULL,
  `account_quiz_passed` int(11) DEFAULT 0,
  `account_factionteam` tinyint(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`account_id`),
  UNIQUE KEY `uniq_discord_id` (`discord_id`),
  KEY `idx_accounts_online` (`account_online`),
  KEY `idx_accounts_remember_token_hash` (`remember_token_hash`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table account_ip_history
CREATE TABLE IF NOT EXISTS `account_ip_history` (
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `first_seen` int(10) unsigned NOT NULL,
  `last_seen` int(10) unsigned NOT NULL,
  `access_count` int(10) unsigned NOT NULL DEFAULT 1,
  `last_user_agent_hash` char(64) DEFAULT NULL,
  `last_user_agent` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`history_id`),
  UNIQUE KEY `idx_account_ip_history_account_ip` (`account_id`,`ip_address`),
  UNIQUE KEY `uniq_account_ip` (`account_id`,`ip_address`),
  KEY `idx_account_ip_history_ip` (`ip_address`),
  KEY `idx_account_ip_history_account` (`account_id`),
  KEY `idx_account_ip_history_last_seen` (`last_seen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table account_preferences
CREATE TABLE IF NOT EXISTS `account_preferences` (
  `account_id` int(11) NOT NULL,
  `ui_hue` smallint(5) unsigned NOT NULL DEFAULT 210,
  `updated_at` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table actors
CREATE TABLE IF NOT EXISTS `actors` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `model` int(11) NOT NULL DEFAULT 0,
  `pos_x` float(10,4) NOT NULL DEFAULT 0.0000,
  `pos_y` float(10,4) NOT NULL DEFAULT 0.0000,
  `pos_z` float(10,4) NOT NULL DEFAULT 3000.0000,
  `pos_r` float(10,4) NOT NULL DEFAULT 0.0000,
  `world` int(11) NOT NULL DEFAULT 0,
  `interior` int(11) NOT NULL DEFAULT 0,
  `invulnerable` tinyint(1) NOT NULL DEFAULT 0,
  `anim_lib` varchar(50) NOT NULL DEFAULT '',
  `anim_name` varchar(50) NOT NULL DEFAULT '',
  `anim_loop` tinyint(1) NOT NULL DEFAULT 0,
  `anim_freeze` tinyint(1) NOT NULL DEFAULT 0,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `comment` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `world` (`world`),
  KEY `interior` (`interior`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table admin_access_logs
CREATE TABLE IF NOT EXISTS `admin_access_logs` (
  `log_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `account_name` varchar(64) NOT NULL,
  `staff_level` tinyint(4) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `accessed_at` int(11) NOT NULL,
  PRIMARY KEY (`log_id`),
  KEY `idx_account_id` (`account_id`),
  KEY `idx_accessed_at` (`accessed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table admin_action_logs
CREATE TABLE IF NOT EXISTS `admin_action_logs` (
  `log_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(10) unsigned NOT NULL,
  `account_name` varchar(32) NOT NULL,
  `staff_level` int(11) NOT NULL,
  `action_type` varchar(64) NOT NULL,
  `target_type` varchar(64) NOT NULL,
  `target_id` varchar(64) DEFAULT NULL,
  `description` text NOT NULL,
  `reason` text DEFAULT NULL,
  `ip_address` varchar(45) NOT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`log_id`),
  KEY `idx_account` (`account_id`),
  KEY `idx_action` (`action_type`),
  KEY `idx_target` (`target_type`,`target_id`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table admin_notes
CREATE TABLE IF NOT EXISTS `admin_notes` (
  `note_id` int(11) NOT NULL AUTO_INCREMENT,
  `note_account` int(11) NOT NULL,
  `note_admin` varchar(64) NOT NULL,
  `note_date` int(11) NOT NULL,
  `note_text` varchar(256) NOT NULL,
  PRIMARY KEY (`note_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table admin_objects
CREATE TABLE IF NOT EXISTS `admin_objects` (
  `object_id` int(11) NOT NULL AUTO_INCREMENT,
  `model_id` int(11) NOT NULL,
  `pos_x` float NOT NULL,
  `pos_y` float NOT NULL,
  `pos_z` float NOT NULL,
  `rot_x` float NOT NULL,
  `rot_y` float NOT NULL,
  `rot_z` float NOT NULL,
  `interior` int(11) DEFAULT 0,
  `virtual_world` int(11) DEFAULT 0,
  `created_by` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table admin_record
CREATE TABLE IF NOT EXISTS `admin_record` (
  `record_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `character_id` int(11) NOT NULL DEFAULT 0,
  `record_type` int(11) NOT NULL,
  `record_reason` varchar(64) NOT NULL,
  `record_time` int(11) NOT NULL,
  `record_admin` int(11) NOT NULL,
  `record_date` varchar(36) NOT NULL,
  PRIMARY KEY (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table admin_report_logs
CREATE TABLE IF NOT EXISTS `admin_report_logs` (
  `report_log_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `admin_account_id` int(11) NOT NULL,
  `admin_account_name` varchar(32) NOT NULL,
  `reporter_account_id` int(11) NOT NULL,
  `reporter_account_name` varchar(32) NOT NULL,
  `reporter_character_id` int(11) NOT NULL,
  `reporter_character_name` varchar(32) NOT NULL,
  `reported_account_id` int(11) NOT NULL DEFAULT -1,
  `reported_account_name` varchar(32) NOT NULL DEFAULT 'Unknown',
  `reported_character_id` int(11) NOT NULL DEFAULT -1,
  `reported_character_name` varchar(32) NOT NULL DEFAULT 'Unknown',
  `report_reason` varchar(128) NOT NULL,
  `report_unix` int(10) unsigned NOT NULL,
  `accepted_unix` int(10) unsigned NOT NULL,
  `report_date` datetime NOT NULL,
  `accepted_date` datetime NOT NULL,
  PRIMARY KEY (`report_log_id`),
  KEY `idx_admin_account_id` (`admin_account_id`),
  KEY `idx_reporter_account_id` (`reporter_account_id`),
  KEY `idx_report_date` (`report_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table admin_warns
CREATE TABLE IF NOT EXISTS `admin_warns` (
  `warn_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `warn_admin` varchar(24) NOT NULL,
  `warn_reason` varchar(256) NOT NULL,
  `warn_time` int(11) NOT NULL,
  `warn_shown` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`warn_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table atms
CREATE TABLE IF NOT EXISTS `atms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `angle` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping structure for table attachments
CREATE TABLE IF NOT EXISTS `attachments` (
  `attach_character_id` int(11) NOT NULL DEFAULT 0,
  `attach_character_index` int(11) NOT NULL DEFAULT 0,
  `attach_character_array` int(11) NOT NULL DEFAULT 0,
  `attach_character_bone` int(11) NOT NULL DEFAULT 0,
  `attach_character_offsetx` float NOT NULL DEFAULT 0,
  `attach_character_offsety` float NOT NULL DEFAULT 0,
  `attach_character_offsetz` float NOT NULL DEFAULT 0,
  `attach_character_rotx` float NOT NULL DEFAULT 0,
  `attach_character_roty` float NOT NULL DEFAULT 0,
  `attach_character_rotz` float NOT NULL DEFAULT 0,
  `attach_character_scalex` float NOT NULL DEFAULT 0,
  `attach_character_scaley` float NOT NULL DEFAULT 0,
  `attach_character_scalez` float NOT NULL DEFAULT 0,
  `attach_character_visible` int(11) NOT NULL DEFAULT 0,
  `attach_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `attach_character_attach_id` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`attach_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table attachpoint
CREATE TABLE IF NOT EXISTS `attachpoint` (
  `attach_point_id` int(11) NOT NULL AUTO_INCREMENT,
  `attach_point_type` int(11) NOT NULL DEFAULT 0,
  `attach_point_linkedbiz` int(11) NOT NULL DEFAULT 0,
  `attach_point_pos_x` float NOT NULL,
  `attach_point_pos_y` float NOT NULL,
  `attach_point_pos_z` float NOT NULL,
  `attach_point_int` int(11) NOT NULL,
  `attach_point_vw` int(11) NOT NULL,
  PRIMARY KEY (`attach_point_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for event auto_archive_bolos
-- Optional recurring maintenance belongs in deployment configuration, not the base schema.
-- Dumping structure for table banks
CREATE TABLE IF NOT EXISTS `banks` (
  `bank_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `bank_pos_x` float NOT NULL,
  `bank_pos_y` float NOT NULL,
  `bank_pos_z` float NOT NULL,
  `bank_vw` int(11) NOT NULL,
  PRIMARY KEY (`bank_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table bans
CREATE TABLE IF NOT EXISTS `bans` (
  `ban_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL DEFAULT 0,
  `account_name` varchar(24) NOT NULL,
  `account_ip` varchar(16) NOT NULL DEFAULT '0',
  `ban_admin` varchar(255) NOT NULL,
  `ban_reason` varchar(64) NOT NULL,
  `ban_time` int(11) NOT NULL,
  `unban_time` int(11) NOT NULL,
  PRIMARY KEY (`ban_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table blocked_pms
CREATE TABLE IF NOT EXISTS `blocked_pms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `blocked_account_id` int(11) NOT NULL,
  `blocked_account_name` varchar(24) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_block` (`account_id`,`blocked_account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table blocklist
CREATE TABLE IF NOT EXISTS `blocklist` (
  `blocklist_player_id` int(10) unsigned NOT NULL DEFAULT 0,
  `blocklist_blocked_id` int(10) unsigned NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table bolos
CREATE TABLE IF NOT EXISTS `bolos` (
  `bolo_id` int(11) NOT NULL AUTO_INCREMENT,
  `bolo_type` enum('person','vehicle') NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` text NOT NULL,
  `subject_name` varchar(100) DEFAULT NULL,
  `vehicle_plate` varchar(32) DEFAULT NULL,
  `risk_level` enum('low','medium','high') NOT NULL DEFAULT 'medium',
  `status` enum('active','cleared','archived') NOT NULL DEFAULT 'active',
  `issued_by_character` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `cleared_at` datetime DEFAULT NULL,
  `archived_at` datetime DEFAULT NULL,
  `archived_by_character` int(11) DEFAULT NULL,
  `archive_reason` text DEFAULT NULL,
  PRIMARY KEY (`bolo_id`),
  KEY `status` (`status`),
  KEY `faction_id` (`faction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table broadcast_history
CREATE TABLE IF NOT EXISTS `broadcast_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `broadcaster_name` varchar(24) NOT NULL,
  `broadcast_title` varchar(64) NOT NULL,
  `start_time` int(10) unsigned NOT NULL,
  `end_time` int(10) unsigned NOT NULL,
  `duration_seconds` int(10) unsigned NOT NULL DEFAULT 0,
  `peak_listeners` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_broadcaster` (`broadcaster_name`),
  KEY `idx_start_time` (`start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table buyable_skins
CREATE TABLE IF NOT EXISTS `buyable_skins` (
  `buyable_skin_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `buyable_skin_propertyid` int(11) NOT NULL,
  `buyable_skin_skinid` int(10) unsigned NOT NULL,
  `buyable_skin_cost` int(10) unsigned NOT NULL,
  PRIMARY KEY (`buyable_skin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table call_history
CREATE TABLE IF NOT EXISTS `call_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `character_id` int(10) unsigned NOT NULL DEFAULT 0,
  `number` varchar(32) NOT NULL DEFAULT '',
  `call_type` tinyint(4) NOT NULL DEFAULT 0,
  `call_timestamp` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_character` (`character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table career_applications
CREATE TABLE IF NOT EXISTS `career_applications` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(10) unsigned NOT NULL,
  `character_id` int(10) unsigned NOT NULL,
  `character_name` varchar(64) NOT NULL,
  `career_type` varchar(32) NOT NULL,
  `motivation` text NOT NULL,
  `status` enum('pending','approved','rejected','withdrawn') NOT NULL DEFAULT 'pending',
  `rejection_reason` text DEFAULT NULL,
  `reviewed_by` int(10) unsigned DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `submitted_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_account_id` (`account_id`),
  KEY `idx_status` (`status`),
  KEY `idx_submitted_at` (`submitted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table characters
CREATE TABLE IF NOT EXISTS `characters` (
  `player_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `player_name` varchar(24) NOT NULL,
  `player_online` tinyint(4) NOT NULL DEFAULT 0,
  `player_uniqueid` varchar(12) NOT NULL DEFAULT 'undefined',
  `player_ip` varchar(64) NOT NULL DEFAULT '127.0.0.1',
  `player_registered` tinyint(4) NOT NULL DEFAULT 0,
  `player_last_pos_x` float NOT NULL DEFAULT 0,
  `player_last_pos_y` float NOT NULL DEFAULT 0,
  `player_on_duty` float NOT NULL DEFAULT 0,
  `player_last_pos_z` float NOT NULL DEFAULT 0,
  `player_last_pos_a` float NOT NULL DEFAULT 0,
  `player_last_pos_int` int(11) NOT NULL DEFAULT 0,
  `player_last_pos_vw` int(11) NOT NULL DEFAULT 0,
  `player_skinid` smallint(6) NOT NULL DEFAULT 264,
  `player_skin_before` smallint(6) NOT NULL DEFAULT 0,
  `player_skin_model` varchar(128) NOT NULL DEFAULT ' ',
  `player_skin_dir` varchar(128) NOT NULL DEFAULT ' ',
  `player_chatstyle` tinyint(4) NOT NULL DEFAULT 0,
  `player_cash` int(11) NOT NULL DEFAULT 500,
  `player_bankcash` int(11) NOT NULL DEFAULT 250,
  `player_paycheck` int(11) NOT NULL DEFAULT 0,
  `player_level` smallint(6) NOT NULL DEFAULT 1,
  `player_hours` mediumint(9) NOT NULL DEFAULT 0,
  `player_exp` mediumint(9) NOT NULL DEFAULT 8,
  `player_registerdate` int(11) NOT NULL DEFAULT 0,
  `player_logindate` int(11) NOT NULL DEFAULT 0,
  `player_driverslicense` tinyint(4) NOT NULL DEFAULT 0,
  `player_gascan` tinyint(4) NOT NULL DEFAULT 0,
  `player_radio` tinyint(4) NOT NULL DEFAULT 0,
  `player_radiochan1` smallint(6) NOT NULL DEFAULT 0,
  `player_radiochan2` smallint(6) NOT NULL DEFAULT 0,
  `player_radiochan3` smallint(6) NOT NULL DEFAULT 0,
  `player_phnumber` mediumint(9) NOT NULL DEFAULT 0,
  `player_phcolour` tinyint(4) NOT NULL DEFAULT 0,
  `player_phbg` tinyint(4) DEFAULT 0,
  `player_phcredit` mediumint(9) NOT NULL DEFAULT 0,
  `player_phbattery` tinyint(4) NOT NULL DEFAULT 0,
  `player_health` float NOT NULL DEFAULT 100,
  `player_armour` float NOT NULL DEFAULT 0,
  `player_carkey` mediumint(9) NOT NULL DEFAULT -1,
  `player_factionid` tinyint(4) NOT NULL DEFAULT 0,
  `player_factiontier` tinyint(4) NOT NULL DEFAULT 3,
  `player_factionrank` varchar(64) NOT NULL DEFAULT 'None',
  `player_factionsquad` tinyint(4) NOT NULL DEFAULT 0,
  `player_factionsquad2` tinyint(4) NOT NULL DEFAULT 0,
  `player_factionsquad3` tinyint(4) NOT NULL DEFAULT 0,
  `player_factionbadge` smallint(5) unsigned NOT NULL DEFAULT 0,
  `player_factionsuspension` int(10) unsigned NOT NULL DEFAULT 0,
  `player_outstanding_fines` int(11) NOT NULL DEFAULT 0,
  `player_arrest_time` int(11) NOT NULL DEFAULT 0,
  `player_lawyer_used` tinyint(1) NOT NULL DEFAULT 0,
  `player_arrest_x` float NOT NULL DEFAULT 0,
  `player_arrest_y` float NOT NULL DEFAULT 0,
  `player_arrest_z` float NOT NULL DEFAULT 0,
  `player_arrest_vw` int(11) NOT NULL DEFAULT 0,
  `player_arrest_int` int(11) NOT NULL DEFAULT 0,
  `player_arrest_cell` varchar(4) DEFAULT '',
  `player_jfl` tinyint(1) DEFAULT 0,
  `player_soldproperty` int(11) NOT NULL DEFAULT 0,
  `player_rentroom` int(11) NOT NULL DEFAULT -1,
  `player_spawnproperty` int(11) NOT NULL DEFAULT 0,
  `player_maskid` int(11) NOT NULL DEFAULT 0,
  `player_hud_trademark` tinyint(4) NOT NULL DEFAULT 1,
  `player_hud_vehfadein` int(11) NOT NULL DEFAULT 1,
  `player_hud_direction` int(11) NOT NULL DEFAULT 1,
  `player_hud_datetime` int(11) NOT NULL DEFAULT 1,
  `player_hud_vehicle` tinyint(4) NOT NULL DEFAULT 1,
  `player_hud_territory` tinyint(4) NOT NULL DEFAULT 1,
  `player_hud_voicelines` int(11) NOT NULL DEFAULT 0,
  `player_hud_minigame` int(11) NOT NULL DEFAULT 0,
  `player_hud_clock` int(11) NOT NULL DEFAULT 1,
  `player_blunt_strain` smallint(6) NOT NULL DEFAULT 0,
  `player_blunt_progress` mediumint(9) NOT NULL DEFAULT 0,
  `player_bandage_cd` int(11) NOT NULL DEFAULT 0,
  `player_last_bandage_cd` int(11) NOT NULL DEFAULT 0,
  `player_helpup_cd` int(11) NOT NULL DEFAULT 0,
  `player_heal_cd` int(10) unsigned NOT NULL DEFAULT 0,
  `player_ajail_time` int(11) NOT NULL DEFAULT 0,
  `player_weed_seed_0` int(11) NOT NULL DEFAULT 0,
  `player_weed_seed_1` int(11) NOT NULL DEFAULT 0,
  `player_weed_seed_2` int(11) NOT NULL DEFAULT 0,
  `player_weed_seed_3` int(11) NOT NULL DEFAULT 0,
  `player_weed_seed_4` int(11) NOT NULL DEFAULT 0,
  `player_gd_wood` smallint(6) NOT NULL DEFAULT 0,
  `player_gd_metal` smallint(6) NOT NULL DEFAULT 0,
  `player_gd_parts` smallint(6) DEFAULT 0,
  `player_tutorial` int(11) NOT NULL DEFAULT 0,
  `player_ammo_a` int(11) NOT NULL DEFAULT 0,
  `player_ammo_b` int(11) NOT NULL DEFAULT 0,
  `player_ammo_c` int(11) NOT NULL DEFAULT 0,
  `player_ammo_d` int(11) NOT NULL DEFAULT 0,
  `player_ammo_e` int(11) NOT NULL DEFAULT 0,
  `player_ammo_f` int(11) NOT NULL DEFAULT 0,
  `player_ammo_g` int(11) NOT NULL DEFAULT 0,
  `player_ammo_h` int(11) NOT NULL DEFAULT 0,
  `player_ammo_i` int(11) NOT NULL DEFAULT 0,
  `player_ammo_j` int(11) NOT NULL DEFAULT 0,
  `player_ammo_teargas` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_0` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_1` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_2` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_3` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_4` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_5` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_6` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_7` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_8` int(11) NOT NULL DEFAULT 0,
  `player_vl_slot_9` int(11) NOT NULL DEFAULT 0,
  `player_spraytag` int(11) NOT NULL DEFAULT -1,
  `player_property_refund` int(11) NOT NULL DEFAULT 0,
  `player_vehicle_refund` int(11) NOT NULL DEFAULT 0,
  `player_update_reward` int(11) NOT NULL DEFAULT 0,
  `player_respect` int(11) NOT NULL DEFAULT 0,
  `player_fear` int(11) NOT NULL DEFAULT 0,
  `player_fnr_givable` int(11) NOT NULL DEFAULT 0,
  `player_drug_effect_ticks` int(11) NOT NULL DEFAULT 0,
  `player_drug_effect_active` int(11) NOT NULL DEFAULT 0,
  `player_drug_effect_param` int(11) NOT NULL DEFAULT 0,
  `player_drug_effect_type` int(11) NOT NULL DEFAULT 0,
  `player_mole` int(11) NOT NULL DEFAULT -1,
  `player_prop_food` int(11) NOT NULL DEFAULT 0,
  `player_prop_food_timeleft` int(11) NOT NULL DEFAULT 0,
  `player_prop_food_uses` int(11) NOT NULL DEFAULT 0,
  `player_prop_drink` int(11) NOT NULL DEFAULT 0,
  `player_prop_drink_timeleft` int(11) NOT NULL DEFAULT 0,
  `player_prop_drink_uses` int(11) NOT NULL DEFAULT 0,
  `player_prop_cigarette` int(11) NOT NULL DEFAULT 0,
  `player_prop_cigarette_uses_left` int(11) NOT NULL DEFAULT 0,
  `player_prop_menu` int(11) NOT NULL DEFAULT 0,
  `player_prop_crate` int(11) NOT NULL DEFAULT 0,
  `player_hitman` int(11) NOT NULL DEFAULT 0,
  `player_hitman_rank` int(11) NOT NULL DEFAULT 0,
  `player_hitman_killed` int(11) NOT NULL DEFAULT 0,
  `player_hitman_unlocked` int(11) NOT NULL DEFAULT 0,
  `player_robbery_cooldown` int(11) NOT NULL DEFAULT 0,
  `player_fat` float NOT NULL DEFAULT 400,
  `player_muscle` float NOT NULL DEFAULT 400,
  `player_stamina` float NOT NULL DEFAULT 400,
  `player_fightstyle` int(11) NOT NULL DEFAULT 0,
  `player_fightstyle_tick` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_1` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_1_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_2` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_2_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_3` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_3_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_4` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_4_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_5` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_5_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_6` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_6_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_7` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_7_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_8` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_8_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_9` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_9_ammo` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_0` int(11) NOT NULL DEFAULT 0,
  `player_gun_package_0_ammo` int(11) NOT NULL DEFAULT 0,
  `player_soldfurni` int(11) NOT NULL DEFAULT 0,
  `player_spraytag_wipe_cd` int(11) NOT NULL DEFAULT 0,
  `player_spraytag_dynamic` int(11) NOT NULL DEFAULT -1,
  `player_spraytag_dyn_text` varchar(64) NOT NULL DEFAULT '0',
  `player_spraytag_dyn_fcolor` int(11) NOT NULL DEFAULT 0,
  `player_spraytag_dyn_cd` int(11) NOT NULL DEFAULT 0,
  `player_spraytag_static_cd` int(11) NOT NULL DEFAULT 0,
  `player_driver_warnings` int(11) NOT NULL DEFAULT 0,
  `player_chopshop_cd` int(11) NOT NULL DEFAULT 0,
  `player_lockpicks` int(11) NOT NULL DEFAULT 0,
  `player_savings` int(11) NOT NULL DEFAULT 0,
  `player_keep_duty` int(11) NOT NULL DEFAULT 0,
  `player_gym_setup` int(11) NOT NULL DEFAULT 0,
  `player_gym_energy` int(11) NOT NULL DEFAULT 0,
  `player_gym_energy_internal` int(11) NOT NULL DEFAULT 0,
  `player_gym_weight` int(11) NOT NULL DEFAULT 0,
  `player_gym_weight_xp` int(11) NOT NULL DEFAULT 0,
  `player_gym_weight_internal` int(11) NOT NULL DEFAULT 0,
  `player_gym_muscle` int(11) NOT NULL DEFAULT 0,
  `player_gym_muscle_xp` int(11) NOT NULL DEFAULT 0,
  `player_gym_muscle_internal` int(11) NOT NULL DEFAULT 0,
  `player_gym_hunger` int(11) NOT NULL DEFAULT 0,
  `player_gym_hunger_internal` int(11) NOT NULL DEFAULT 0,
  `player_gym_thirst` int(11) NOT NULL DEFAULT 0,
  `player_gym_thirst_internal` int(11) NOT NULL DEFAULT 0,
  `player_soldfuelstation` int(11) NOT NULL DEFAULT 0,
  `player_oajail_reason` varchar(256) NOT NULL DEFAULT '0',
  `player_oajail_admin` varchar(24) NOT NULL DEFAULT '0',
  `player_pager_freq` smallint(5) unsigned NOT NULL DEFAULT 0,
  `player_pager_nick` varchar(12) NOT NULL DEFAULT '0',
  `player_last_mugshot` int(10) unsigned NOT NULL DEFAULT 0,
  `player_gunlicense` int(10) unsigned NOT NULL DEFAULT 0,
  `player_ccwlicense` int(10) unsigned NOT NULL DEFAULT 0,
  `player_guardlicense` int(10) unsigned NOT NULL DEFAULT 0,
  `player_guardfplicense` int(10) unsigned NOT NULL DEFAULT 0,
  `player_strawman` tinyint(4) NOT NULL DEFAULT 0,
  `player_propdup` int(11) NOT NULL DEFAULT -1,
  `player_attribute_sex` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_attribute_age` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_attribute_race` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_attribute_eyes` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_attribute_hair` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_attribute_body` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_attribute_height` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_attribute_desc` varchar(255) NOT NULL DEFAULT 'None',
  `player_skill_pistol` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_sdpistol` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_deagle` tinyint(3) unsigned NOT NULL DEFAULT 2,
  `player_skill_shotgun` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_sawnoff` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_spaz` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_uzi` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_mp5` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_ak47` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_m4` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_skill_sniper` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_ammo_purged` tinyint(4) NOT NULL DEFAULT 1,
  `player_groupid` int(11) NOT NULL DEFAULT 0,
  `player_grouptier` tinyint(4) NOT NULL DEFAULT 0,
  `player_account_hidden` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_account_hidden_name` varchar(255) DEFAULT NULL,
  `player_admin_hidden` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `player_fishingpermit` int(11) NOT NULL DEFAULT 0,
  `player_fishes` int(11) NOT NULL DEFAULT 0,
  `player_biggestfish` int(11) NOT NULL DEFAULT 0,
  `player_rod` int(11) NOT NULL DEFAULT 0,
  `player_bait` int(11) NOT NULL DEFAULT 0,
  `player_fishslot1` varchar(50) NOT NULL DEFAULT 'None',
  `player_fishslot2` varchar(50) NOT NULL DEFAULT 'None',
  `player_fishslot3` varchar(50) NOT NULL DEFAULT 'None',
  `player_fishslot4` varchar(50) NOT NULL DEFAULT 'None',
  `player_fishslot5` varchar(50) NOT NULL DEFAULT 'None',
  `player_fishweight1` int(11) NOT NULL DEFAULT -1,
  `player_fishweight2` int(11) NOT NULL DEFAULT -1,
  `player_fishweight3` int(11) NOT NULL DEFAULT -1,
  `player_fishweight4` int(11) NOT NULL DEFAULT -1,
  `player_fishweight5` int(11) NOT NULL DEFAULT -1,
  `player_customskin` tinyint(1) NOT NULL DEFAULT 0,
  `player_rag_on` tinyint(1) DEFAULT 0,
  `player_last_drug_use` int(11) NOT NULL DEFAULT 0,
  `player_pms_blocked` tinyint(1) NOT NULL DEFAULT 0,
  `player_freshspawn` int(11) DEFAULT 1,
  `player_hud_property_icons` tinyint(1) NOT NULL DEFAULT 1,
  `player_division` int(11) DEFAULT 0,
  `ftj_cooldown` int(11) NOT NULL DEFAULT 0,
  `player_recentdamage` int(11) DEFAULT 0,
  `player_prison_stamps` int(11) DEFAULT 0,
  `player_prison_progress` int(11) DEFAULT 0,
  `player_commissary_cigs` int(11) NOT NULL DEFAULT 0,
  `player_commissary_coffee` int(11) NOT NULL DEFAULT 0,
  `player_commissary_soap` int(11) NOT NULL DEFAULT 0,
  `player_commissary_tpaper` int(11) NOT NULL DEFAULT 0,
  `player_commissary_radio` int(11) NOT NULL DEFAULT 0,
  `character_profession` tinyint(4) NOT NULL DEFAULT 0,
  `character_mechanic_xp` int(11) NOT NULL DEFAULT 0,
  `character_mechanic_level` tinyint(4) NOT NULL DEFAULT 1,
  `character_mechanic_jobs_done` int(11) NOT NULL DEFAULT 0,
  `player_addiction_weed` float NOT NULL DEFAULT 0,
  `player_addiction_coke` float NOT NULL DEFAULT 0,
  `player_addiction_crack` float NOT NULL DEFAULT 0,
  `player_addiction_meth` float NOT NULL DEFAULT 0,
  `player_last_addiction_decay` int(11) NOT NULL DEFAULT 0,
  `character_trucker_xp` int(11) NOT NULL DEFAULT 0,
  `character_trucker_level` tinyint(3) NOT NULL DEFAULT 1,
  `character_trucker_job` tinyint(4) NOT NULL DEFAULT 0,
  `player_pilotslicense` tinyint(4) NOT NULL DEFAULT 0,
  `player_cuff_state` tinyint(4) NOT NULL DEFAULT 0,
  `player_cuff_quit_at` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table character_daily_stats
CREATE TABLE IF NOT EXISTS `character_daily_stats` (
  `character_id` int(11) NOT NULL,
  `day` date NOT NULL,
  `cash` int(11) NOT NULL,
  `bank` int(11) NOT NULL,
  `savings` int(11) NOT NULL,
  PRIMARY KEY (`character_id`,`day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table character_drug_dealers
CREATE TABLE IF NOT EXISTS `character_drug_dealers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `character_id` int(11) NOT NULL,
  `is_dealer` tinyint(1) NOT NULL DEFAULT 0,
  `dealer_rank` tinyint(1) NOT NULL DEFAULT 0,
  `sales_today` int(11) NOT NULL DEFAULT 0,
  `total_sales` int(11) NOT NULL DEFAULT 0,
  `last_sale_time` int(11) NOT NULL DEFAULT 0,
  `street_npc_slot` int(11) NOT NULL DEFAULT -1,
  `street_npc_slot2` int(11) NOT NULL DEFAULT -1,
  `junkie_cooldown_until` int(11) NOT NULL DEFAULT 0,
  `junkie_pending_sale` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `character_id` (`character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table character_licenses
CREATE TABLE IF NOT EXISTS `character_licenses` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `character_id` int(10) unsigned NOT NULL,
  `license_type` varchar(32) NOT NULL,
  `issued_by` int(10) unsigned NOT NULL,
  `issued_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_char_license` (`character_id`,`license_type`),
  KEY `idx_character_id` (`character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table character_login_history
CREATE TABLE IF NOT EXISTS `character_login_history` (
  `login_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `character_id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL DEFAULT 0,
  `login_time` int(10) unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`login_id`),
  KEY `idx_faction_time` (`faction_id`,`login_time`),
  KEY `idx_character_time` (`character_id`,`login_time`),
  KEY `idx_account_time` (`account_id`,`login_time`),
  KEY `idx_login_time` (`login_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table character_vehicle_keys
CREATE TABLE IF NOT EXISTS `character_vehicle_keys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `character_id` int(11) NOT NULL,
  `vehicle_sqlid` int(11) NOT NULL,
  `owner_character_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table contracts
CREATE TABLE IF NOT EXISTS `contracts` (
  `contract_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `contract_status` int(11) NOT NULL DEFAULT 0,
  `contract_hirer` int(11) NOT NULL DEFAULT -1,
  `contract_victim` varchar(34) NOT NULL,
  `contract_fee` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`contract_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table corner_actors
CREATE TABLE IF NOT EXISTS `corner_actors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `zone_id` int(11) NOT NULL DEFAULT 0,
  `faction_id` int(11) NOT NULL DEFAULT 0,
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `pos_a` float NOT NULL DEFAULT 0,
  `skin` int(11) NOT NULL DEFAULT 0,
  `weed_demand` int(11) NOT NULL DEFAULT 0,
  `crack_demand` int(11) NOT NULL DEFAULT 0,
  `cocaine_demand` int(11) NOT NULL DEFAULT 0,
  `meth_demand` int(11) NOT NULL DEFAULT 0,
  `weed_price` int(11) NOT NULL DEFAULT 0,
  `crack_price` int(11) NOT NULL DEFAULT 0,
  `cocaine_price` int(11) NOT NULL DEFAULT 0,
  `meth_price` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table criminalfines
CREATE TABLE IF NOT EXISTS `criminalfines` (
  `fine_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fine_date` datetime NOT NULL DEFAULT current_timestamp(),
  `fine_player_id` int(10) unsigned NOT NULL DEFAULT 0,
  `fine_player_name` varchar(255) DEFAULT NULL,
  `fine_giver_id` int(10) unsigned NOT NULL DEFAULT 0,
  `fine_giver_name` varchar(32) DEFAULT NULL,
  `fine_giver_rank` varchar(32) DEFAULT NULL,
  `fine_reason` varchar(255) DEFAULT NULL,
  `fine_reason_id` smallint(5) unsigned NOT NULL DEFAULT 0,
  `fine_amount` smallint(5) unsigned NOT NULL DEFAULT 0,
  `fine_status` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `fine_revoker` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`fine_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table criminalrecords
CREATE TABLE IF NOT EXISTS `criminalrecords` (
  `record_id` int(11) NOT NULL AUTO_INCREMENT,
  `record_desc` varchar(128) NOT NULL,
  `record_crime_type` smallint(6) NOT NULL DEFAULT -1,
  `record_date` bigint(20) NOT NULL,
  `record_holder` varchar(24) NOT NULL,
  `record_officer` varchar(24) NOT NULL,
  `record_officer_rank` varchar(255) NOT NULL,
  `record_status` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `record_revoker` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table dealerships
CREATE TABLE IF NOT EXISTS `dealerships` (
  `dealer_id` int(11) NOT NULL AUTO_INCREMENT,
  `dealer_type` tinyint(4) NOT NULL,
  `dealer_name` varchar(64) NOT NULL,
  `dealer_color` int(11) NOT NULL,
  `dealer_pos_x` double NOT NULL,
  `dealer_pos_y` double NOT NULL,
  `dealer_pos_z` double NOT NULL,
  `dealer_spawn_x` double NOT NULL,
  `dealer_spawn_y` double NOT NULL,
  `dealer_spawn_z` double NOT NULL,
  `dealer_spawn_a` double NOT NULL,
  `dealer_owner_char_id` int(11) NOT NULL DEFAULT 0 COMMENT '0 = vacant (NPC run, unlimited stock)',
  `dealer_owner_name` varchar(32) NOT NULL DEFAULT '',
  `dealer_bank` int(11) NOT NULL DEFAULT 0,
  `dealer_owner_since` int(11) NOT NULL DEFAULT 0,
  `dealer_owner_last_seen` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`dealer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table dealership_applications
CREATE TABLE IF NOT EXISTS `dealership_applications` (
  `app_id` int(11) NOT NULL AUTO_INCREMENT,
  `dealer_id` int(11) NOT NULL,
  `character_id` int(11) NOT NULL,
  `character_name` varchar(32) NOT NULL,
  `app_message` varchar(128) NOT NULL DEFAULT '',
  `app_created_at` int(11) NOT NULL,
  PRIMARY KEY (`app_id`),
  UNIQUE KEY `uniq_dealer_char` (`dealer_id`,`character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table dealership_stock
CREATE TABLE IF NOT EXISTS `dealership_stock` (
  `dealer_id` int(11) NOT NULL,
  `model_id` int(11) NOT NULL,
  `qty` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`dealer_id`,`model_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table discord_actions
CREATE TABLE IF NOT EXISTS `discord_actions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `discord_id` varchar(32) NOT NULL,
  `action` enum('ban','unban') NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `admin_name` varchar(64) NOT NULL,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table dock_entities
CREATE TABLE IF NOT EXISTS `dock_entities` (
  `entity_slot` tinyint(4) NOT NULL,
  `faction_id` int(11) DEFAULT NULL,
  `entity_bank` int(11) NOT NULL DEFAULT 0,
  `assigned_by` varchar(24) DEFAULT NULL,
  `assigned_at` datetime DEFAULT NULL,
  `entity_missions` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`entity_slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table drugplants
CREATE TABLE IF NOT EXISTS `drugplants` (
  `drug_plant_id` int(11) NOT NULL AUTO_INCREMENT,
  `drug_plant_pos_x` float NOT NULL,
  `drug_plant_pos_y` float NOT NULL,
  `drug_plant_pos_z` float NOT NULL,
  `drug_plant_rot_x` float NOT NULL,
  `drug_plant_rot_y` float NOT NULL,
  `drug_plant_rot_z` float NOT NULL,
  `drug_plant_type` int(11) NOT NULL,
  `drug_plant_growth` int(11) NOT NULL,
  `drug_plant_water` int(11) NOT NULL,
  `drug_plant_water_tick` int(11) NOT NULL DEFAULT 0,
  `drug_plant_buds` int(11) NOT NULL DEFAULT 0,
  `drug_total_grams` float NOT NULL DEFAULT 0,
  `drug_grams_per_bud` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`drug_plant_id`),
  UNIQUE KEY `drug_plant_id` (`drug_plant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table drugs_player_owned
CREATE TABLE IF NOT EXISTS `drugs_player_owned` (
  `player_drug_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `player_drug_index` int(11) NOT NULL,
  `player_drug_characterid` int(11) NOT NULL,
  `player_drug_type` int(11) NOT NULL,
  `player_drug_param` int(11) NOT NULL,
  `player_drug_container` int(11) NOT NULL,
  `player_drug_amount` float NOT NULL,
  PRIMARY KEY (`player_drug_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table drugs_player_packages
CREATE TABLE IF NOT EXISTS `drugs_player_packages` (
  `package_character_id` int(11) NOT NULL,
  `package_ziploc_bag` int(11) NOT NULL,
  `package_wrapped_foil` int(11) NOT NULL,
  `package_pill_bottle` int(11) NOT NULL,
  `package_plastic_cup` int(11) NOT NULL,
  `package_pizza_box` int(11) NOT NULL,
  `package_burger_carton` int(11) NOT NULL,
  `package_milk_carton` int(11) NOT NULL,
  `package_takeaway_bag` int(11) NOT NULL,
  `package_brick` int(11) NOT NULL,
  PRIMARY KEY (`package_character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table drugs_player_stations
CREATE TABLE IF NOT EXISTS `drugs_player_stations` (
  `drug_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `drug_type` int(11) NOT NULL,
  `drug_param` int(11) NOT NULL DEFAULT 0,
  `drug_stage` int(11) NOT NULL DEFAULT 0,
  `drug_ticks` int(11) NOT NULL DEFAULT 0,
  `drug_pos_x` float NOT NULL,
  `drug_pos_y` float NOT NULL,
  `drug_pos_z` float NOT NULL,
  `drug_rot_x` float NOT NULL,
  `drug_rot_y` float NOT NULL,
  `drug_rot_z` float NOT NULL,
  `drug_world` int(11) NOT NULL,
  `drug_interior` int(11) NOT NULL,
  `drug_growth_param_int` int(11) NOT NULL DEFAULT 0,
  `drug_growth_param_float_i` float NOT NULL DEFAULT 0,
  `drug_growth_param_float_ii` float NOT NULL DEFAULT 0,
  `drug_growth_param_float_iii` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`drug_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table drugs_player_supplies
CREATE TABLE IF NOT EXISTS `drugs_player_supplies` (
  `drug_supply_characterid` int(11) NOT NULL,
  `drug_supply_weed_0` int(11) NOT NULL,
  `drug_supply_weed_1` int(11) NOT NULL,
  `drug_supply_weed_2` int(11) NOT NULL,
  `drug_supply_coke_0` int(11) NOT NULL,
  `drug_supply_coke_1` int(11) NOT NULL,
  `drug_supply_coke_2` int(11) NOT NULL,
  `drug_supply_crack_0` int(11) NOT NULL,
  `drug_supply_crack_1` int(11) NOT NULL,
  `drug_supply_crack_2` int(11) NOT NULL,
  `drug_supply_meth_0` int(11) NOT NULL,
  `drug_supply_meth_1` int(11) NOT NULL,
  `drug_supply_meth_2` int(11) NOT NULL,
  UNIQUE KEY `drug_supply_characterid` (`drug_supply_characterid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table emmet
CREATE TABLE IF NOT EXISTS `emmet` (
  `emmet_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `emmet_name` varchar(32) NOT NULL,
  `emmet_pos_x` float DEFAULT NULL,
  `emmet_pos_y` float DEFAULT NULL,
  `emmet_pos_z` float DEFAULT NULL,
  `emmet_pos_a` float DEFAULT NULL,
  `emmet_skin` int(11) DEFAULT NULL,
  `emmet_ownedby` int(11) DEFAULT NULL,
  PRIMARY KEY (`emmet_sqlid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- Dumping structure for table emmet_factions
CREATE TABLE IF NOT EXISTS `emmet_factions` (
  `emmet_faction_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `emmet_faction_fid` int(11) NOT NULL,
  `emmet_faction_index` int(11) NOT NULL,
  `emmet_colt45_stock` int(11) NOT NULL DEFAULT -1,
  `emmet_colt45_unix` int(11) NOT NULL DEFAULT -1,
  `emmet_uzi_stock` int(11) NOT NULL DEFAULT -1,
  `emmet_uzi_unix` int(11) NOT NULL DEFAULT -1,
  `emmet_tec_stock` int(11) NOT NULL DEFAULT -1,
  `emmet_tec_unix` int(11) NOT NULL DEFAULT -1,
  `emmet_ak47_stock` int(11) NOT NULL DEFAULT -1,
  `emmet_ak47_unix` int(11) NOT NULL DEFAULT -1,
  `emmet_shotgun_stock` int(11) NOT NULL DEFAULT -1,
  `emmet_shotgun_unix` int(11) NOT NULL DEFAULT -1,
  `emmet_deagle_stock` int(11) NOT NULL DEFAULT -1,
  `emmet_deagle_unix` int(11) NOT NULL DEFAULT -1,
  PRIMARY KEY (`emmet_faction_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- Dumping structure for table emmet_player
CREATE TABLE IF NOT EXISTS `emmet_player` (
  `emmet_player_account_id` int(11) NOT NULL,
  `emmet_player_colt_tax` int(11) DEFAULT 0,
  `emmet_player_colt_cd` int(11) DEFAULT 0,
  `emmet_player_uzi_tax` int(11) DEFAULT 0,
  `emmet_player_uzi_cd` int(11) DEFAULT 0,
  `emmet_player_tec_tax` int(11) DEFAULT 0,
  `emmet_player_tec_cd` int(11) DEFAULT 0,
  `emmet_player_ak47_tax` int(11) DEFAULT 0,
  `emmet_player_ak47_cd` int(11) DEFAULT 0,
  `emmet_player_shotgun_tax` int(11) DEFAULT 0,
  `emmet_player_shotgun_cd` int(11) DEFAULT 0,
  `emmet_player_deagle_tax` int(11) NOT NULL DEFAULT 0,
  `emmet_player_deagle_cd` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`emmet_player_account_id`),
  UNIQUE KEY `unique_emmet_player_account_id` (`emmet_player_account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table emmet_purchase_logs
CREATE TABLE IF NOT EXISTS `emmet_purchase_logs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `purchased_at` datetime NOT NULL DEFAULT current_timestamp(),
  `faction_id` int(11) NOT NULL,
  `emmet_sqlid` int(11) NOT NULL,
  `emmet_name` varchar(32) NOT NULL,
  `buyer_character_id` int(11) NOT NULL,
  `buyer_account_id` int(11) NOT NULL,
  `buyer_character_name` varchar(32) NOT NULL,
  `buyer_account_name` varchar(32) NOT NULL,
  `buyer_faction_tier` tinyint(3) unsigned NOT NULL,
  `weapon_id` smallint(5) unsigned NOT NULL,
  `weapon_name` varchar(32) NOT NULL,
  `weapon_ammo` int(11) NOT NULL,
  `purchase_price` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_faction_time` (`faction_id`,`purchased_at`),
  KEY `idx_emmet_sqlid` (`emmet_sqlid`),
  KEY `idx_buyer_character_id` (`buyer_character_id`),
  KEY `idx_purchased_at` (`purchased_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table endorsements
CREATE TABLE IF NOT EXISTS `endorsements` (
  `endorsement_id` int(11) NOT NULL,
  `admin_account_id` int(11) DEFAULT NULL,
  `target_account_id` int(11) DEFAULT NULL,
  `endorsed_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`endorsement_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table enex_buypoint
CREATE TABLE IF NOT EXISTS `enex_buypoint` (
  `enex_buypoint_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `enex_buypoint_enexid` int(11) NOT NULL,
  `enex_buypoint_pos_x` float NOT NULL,
  `enex_buypoint_pos_y` float NOT NULL,
  `enex_buypoint_pos_z` float NOT NULL,
  `enex_buypoint_pos_int` int(11) NOT NULL,
  `enex_buypoint_pos_vw` int(11) NOT NULL,
  PRIMARY KEY (`enex_buypoint_sqlid`),
  UNIQUE KEY `enex_buypoint_sqlid_2` (`enex_buypoint_sqlid`),
  KEY `enex_buypoint_sqlid` (`enex_buypoint_sqlid`),
  KEY `enex_buypoint_sqlid_3` (`enex_buypoint_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table enex_master
CREATE TABLE IF NOT EXISTS `enex_master` (
  `enex_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `enex_owner` smallint(6) NOT NULL DEFAULT 0,
  `enex_type` smallint(6) NOT NULL DEFAULT 0,
  `enex_money` int(11) NOT NULL DEFAULT 0,
  `enex_pos_x` float NOT NULL DEFAULT 0,
  `enex_pos_y` float NOT NULL DEFAULT 0,
  `enex_pos_z` float NOT NULL DEFAULT 0,
  `enex_pos_int` mediumint(9) NOT NULL DEFAULT 0,
  `enex_pos_vw` mediumint(9) NOT NULL DEFAULT 0,
  PRIMARY KEY (`enex_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table factions
CREATE TABLE IF NOT EXISTS `factions` (
  `faction_id` int(11) NOT NULL AUTO_INCREMENT,
  `faction_name` varchar(256) NOT NULL DEFAULT 'Undefined',
  `faction_abbrev` varchar(5) NOT NULL DEFAULT 'Null',
  `faction_type` tinyint(4) NOT NULL DEFAULT 1,
  `faction_capabilities` int(11) NOT NULL DEFAULT 0,
  `faction_show_activity` tinyint(1) NOT NULL DEFAULT 1,
  `faction_extra` int(11) NOT NULL DEFAULT 0,
  `faction_chat` tinyint(4) NOT NULL DEFAULT 0,
  `faction_hex` int(11) NOT NULL,
  `faction_bank` int(11) NOT NULL DEFAULT 0,
  `faction_playerslots` tinyint(4) NOT NULL DEFAULT 8,
  `faction_carslots` tinyint(4) NOT NULL DEFAULT 8,
  `faction_spawnvisible` tinyint(4) DEFAULT 0,
  `faction_spawn_x` float NOT NULL DEFAULT 0,
  `faction_spawn_y` float NOT NULL DEFAULT 0,
  `faction_spawn_z` float NOT NULL DEFAULT 0,
  `faction_spawn_a` float NOT NULL DEFAULT 0,
  `faction_spawn_int` int(11) NOT NULL DEFAULT 0,
  `faction_spawn_vw` int(11) NOT NULL DEFAULT 0,
  `faction_spawn_icon` tinyint(4) NOT NULL DEFAULT 0,
  `faction_visible` tinyint(4) NOT NULL DEFAULT 1,
  `faction_perk_cd` int(11) NOT NULL DEFAULT 0,
  `faction_assigned_emmet` tinyint(4) NOT NULL DEFAULT 0,
  `faction_f_on` tinyint(4) NOT NULL DEFAULT 0,
  `faction_active_minutes` int(11) DEFAULT 0,
  `faction_perk_buys` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`faction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table faction_activity
CREATE TABLE IF NOT EXISTS `faction_activity` (
  `faction_id` int(11) NOT NULL,
  `activity_date` date NOT NULL,
  `minutes` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  UNIQUE KEY `unique_faction_day` (`faction_id`,`activity_date`),
  KEY `idx_date` (`activity_date`),
  KEY `idx_faction` (`faction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table faction_armories
CREATE TABLE IF NOT EXISTS `faction_armories` (
  `armory_id` int(11) NOT NULL AUTO_INCREMENT,
  `faction_id` int(11) NOT NULL,
  `armory_type_id` int(11) NOT NULL,
  `armory_name` varchar(64) NOT NULL,
  `armory_desc` varchar(128) NOT NULL DEFAULT '',
  `armory_x` float NOT NULL DEFAULT 0,
  `armory_y` float NOT NULL DEFAULT 0,
  `armory_z` float NOT NULL DEFAULT -1000,
  `armory_int` int(11) NOT NULL DEFAULT 0,
  `armory_vw` int(11) NOT NULL DEFAULT 0,
  `armory_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `armory_squad` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`armory_id`),
  KEY `idx_faction_id` (`faction_id`),
  KEY `idx_armory_type_id` (`armory_type_id`),
  KEY `idx_enabled_position` (`armory_enabled`,`armory_int`,`armory_vw`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table faction_armory_types
CREATE TABLE IF NOT EXISTS `faction_armory_types` (
  `armory_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `faction_id` int(11) NOT NULL,
  `type_name` varchar(32) NOT NULL,
  `type_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`armory_type_id`),
  UNIQUE KEY `unique_faction_armory_type_name` (`faction_id`,`type_name`),
  KEY `idx_faction_id` (`faction_id`),
  KEY `idx_type_enabled` (`type_enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table faction_armory_weapons
CREATE TABLE IF NOT EXISTS `faction_armory_weapons` (
  `armory_weapon_id` int(11) NOT NULL AUTO_INCREMENT,
  `faction_id` int(11) NOT NULL,
  `armory_type_id` int(11) DEFAULT NULL,
  `weapon_id` int(11) NOT NULL,
  `weapon_ammo` int(11) NOT NULL DEFAULT 1,
  `tier_limit` tinyint(4) NOT NULL DEFAULT 0,
  `squad_id` int(11) NOT NULL DEFAULT 0,
  `off_duty_allowed` tinyint(1) NOT NULL DEFAULT 0,
  `weapon_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`armory_weapon_id`),
  KEY `idx_faction_type` (`faction_id`,`armory_type_id`),
  KEY `idx_weapon_enabled` (`weapon_enabled`),
  KEY `idx_sort_order` (`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table faction_conflicts
CREATE TABLE IF NOT EXISTS `faction_conflicts` (
  `conflict_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `faction_id` int(10) unsigned NOT NULL,
  `enemy_faction_id` int(10) unsigned DEFAULT NULL,
  `logged_player_id` int(10) unsigned NOT NULL,
  `conflict_type` enum('attack','defense','brawl') NOT NULL,
  `conflict_location` varchar(100) NOT NULL,
  `conflict_description` text NOT NULL,
  `attacker_deaths` smallint(5) unsigned NOT NULL DEFAULT 0,
  `defender_deaths` smallint(5) unsigned NOT NULL DEFAULT 0,
  `conflict_outcome` enum('attacker_win','defender_win','stalemate','mutual_withdrawal','invalid') NOT NULL DEFAULT 'stalemate',
  `conflict_timestamp` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`conflict_id`),
  KEY `idx_faction_id` (`faction_id`),
  KEY `idx_enemy_faction_id` (`enemy_faction_id`),
  KEY `idx_logged_player_id` (`logged_player_id`),
  KEY `idx_conflict_timestamp` (`conflict_timestamp`),
  KEY `idx_conflict_outcome` (`conflict_outcome`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table faction_divisions
CREATE TABLE IF NOT EXISTS `faction_divisions` (
  `division_id` int(11) NOT NULL AUTO_INCREMENT,
  `faction_id` int(11) NOT NULL,
  `division_name` varchar(64) NOT NULL,
  `division_order` int(11) DEFAULT 0,
  `division_leader` int(11) DEFAULT 0,
  PRIMARY KEY (`division_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table faction_logs
CREATE TABLE IF NOT EXISTS `faction_logs` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `faction_id` int(11) NOT NULL,
  `log_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `action` tinyint(4) NOT NULL,
  `amount` int(11) NOT NULL,
  `balance_after` int(11) NOT NULL,
  `reason` varchar(64) NOT NULL,
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table faction_skins
CREATE TABLE IF NOT EXISTS `faction_skins` (
  `faction_skin_id` int(11) NOT NULL AUTO_INCREMENT,
  `faction_skin_factionid` tinyint(4) NOT NULL,
  `faction_skin_skinid` mediumint(9) NOT NULL,
  `faction_skin_tier` tinyint(4) NOT NULL,
  `faction_skin_squad` tinyint(4) NOT NULL DEFAULT 0,
  `faction_skin_armory_type` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`faction_skin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table faction_spawns
CREATE TABLE IF NOT EXISTS `faction_spawns` (
  `spawn_id` int(11) NOT NULL AUTO_INCREMENT,
  `spawn_faction_id` int(11) NOT NULL,
  `spawn_name` varchar(32) NOT NULL,
  `spawn_x` float NOT NULL DEFAULT 0,
  `spawn_y` float NOT NULL DEFAULT 0,
  `spawn_z` float NOT NULL DEFAULT 0,
  `spawn_a` float NOT NULL DEFAULT 0,
  `spawn_int` int(11) NOT NULL DEFAULT 0,
  `spawn_vw` int(11) NOT NULL DEFAULT 0,
  `spawn_requirement` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`spawn_id`),
  KEY `idx_spawn_faction` (`spawn_faction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table firms
CREATE TABLE IF NOT EXISTS `firms` (
  `firm_id` int(11) NOT NULL AUTO_INCREMENT,
  `firm_name` varchar(64) NOT NULL,
  `firm_abbrev` varchar(8) NOT NULL,
  `firm_field` tinyint(4) NOT NULL DEFAULT 0,
  `firm_status` tinyint(4) NOT NULL DEFAULT 1,
  `firm_owner_char_id` int(11) NOT NULL,
  `firm_bank` int(11) NOT NULL DEFAULT 0,
  `firm_member_slots` int(11) NOT NULL DEFAULT 10,
  `firm_vehicle_slots` int(11) NOT NULL DEFAULT 0,
  `firm_hex` int(11) NOT NULL DEFAULT 0,
  `firm_created_at` int(11) NOT NULL,
  `firm_updated_at` int(11) NOT NULL,
  PRIMARY KEY (`firm_id`),
  UNIQUE KEY `uq_firm_name` (`firm_name`),
  KEY `idx_firm_owner` (`firm_owner_char_id`),
  KEY `idx_firm_field_status` (`firm_field`,`firm_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table firm_logs
CREATE TABLE IF NOT EXISTS `firm_logs` (
  `firm_log_id` int(11) NOT NULL AUTO_INCREMENT,
  `firm_id` int(11) NOT NULL,
  `actor_character_id` int(11) NOT NULL DEFAULT 0,
  `log_type` tinyint(4) NOT NULL DEFAULT 0,
  `log_text` varchar(192) NOT NULL,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`firm_log_id`),
  KEY `idx_firm_logs` (`firm_id`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table firm_members
CREATE TABLE IF NOT EXISTS `firm_members` (
  `firm_member_id` int(11) NOT NULL AUTO_INCREMENT,
  `firm_id` int(11) NOT NULL,
  `character_id` int(11) NOT NULL,
  `firm_rank` tinyint(4) NOT NULL DEFAULT 3,
  `firm_rank_name` varchar(32) NOT NULL DEFAULT 'Employee',
  `firm_permissions` int(11) NOT NULL DEFAULT 0,
  `firm_joined_at` int(11) NOT NULL,
  `firm_last_active` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`firm_member_id`),
  UNIQUE KEY `uq_firm_character` (`firm_id`,`character_id`),
  KEY `idx_character_active_firm` (`character_id`,`firm_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table firm_realestate_desks
CREATE TABLE IF NOT EXISTS `firm_realestate_desks` (
  `firm_id` int(11) NOT NULL,
  `desk_x` double NOT NULL,
  `desk_y` double NOT NULL,
  `desk_z` double NOT NULL,
  `desk_int` int(11) NOT NULL DEFAULT 0,
  `desk_vw` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`firm_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table fnr_cooldowns
CREATE TABLE IF NOT EXISTS `fnr_cooldowns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `giver_id` int(11) NOT NULL,
  `target_id` int(11) NOT NULL,
  `last_given` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_pair` (`giver_id`,`target_id`),
  KEY `idx_giver` (`giver_id`),
  KEY `idx_target` (`target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table fuelmanager
CREATE TABLE IF NOT EXISTS `fuelmanager` (
  `fuelmanager_id` int(11) NOT NULL AUTO_INCREMENT,
  `fuelmanager_owner` int(11) NOT NULL,
  `fuelmanager_pos_x` float NOT NULL,
  `fuelmanager_pos_y` float NOT NULL,
  `fuelmanager_pos_z` float NOT NULL,
  `fuelmanager_pos_int` int(11) NOT NULL DEFAULT 0,
  `fuelmanager_pos_vw` int(11) NOT NULL DEFAULT 0,
  `fuelmanager_income` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`fuelmanager_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table fuelstation
CREATE TABLE IF NOT EXISTS `fuelstation` (
  `fuelstation_id` int(11) NOT NULL AUTO_INCREMENT,
  `fuelstation_type` int(11) NOT NULL,
  `fuelstation_manager_id` int(11) NOT NULL,
  `fuelstation_radius` float NOT NULL,
  `fuelstation_pos_x` float NOT NULL,
  `fuelstation_pos_y` float NOT NULL,
  `fuelstation_pos_z` float NOT NULL,
  `fuelstation_pos_rx` float NOT NULL,
  `fuelstation_pos_ry` float NOT NULL,
  `fuelstation_pos_rz` float NOT NULL,
  `fuelstation_pos_int` int(11) NOT NULL,
  `fuelstation_pos_vw` int(11) NOT NULL,
  PRIMARY KEY (`fuelstation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table furniture
CREATE TABLE IF NOT EXISTS `furniture` (
  `furniture_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `furniture_extraid` int(11) NOT NULL,
  `furniture_model` int(11) NOT NULL,
  `furniture_pos_x` float NOT NULL,
  `furniture_pos_y` float NOT NULL,
  `furniture_pos_z` float NOT NULL,
  `furniture_rot_x` float NOT NULL,
  `furniture_rot_y` float NOT NULL,
  `furniture_rot_z` float NOT NULL,
  `furniture_vw` int(11) NOT NULL,
  `furniture_int` int(11) NOT NULL,
  `furniture_txd_0` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_1` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_2` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_3` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_4` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_5` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_6` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_7` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_8` int(11) NOT NULL DEFAULT -1,
  `furniture_txd_9` int(11) NOT NULL DEFAULT -1,
  PRIMARY KEY (`furniture_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table gangzones
CREATE TABLE IF NOT EXISTS `gangzones` (
  `gz_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `gz_min_x` float NOT NULL,
  `gz_min_y` float NOT NULL,
  `gz_max_x` float NOT NULL,
  `gz_max_y` float NOT NULL,
  `gz_faction` int(11) NOT NULL DEFAULT 0,
  `gz_contested` tinyint(4) NOT NULL DEFAULT 0,
  `gz_zone_name` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`gz_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table gates
CREATE TABLE IF NOT EXISTS `gates` (
  `gate_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `gate_modelid` int(11) NOT NULL,
  `gate_type` tinyint(4) NOT NULL DEFAULT 0,
  `gate_toll` int(11) NOT NULL DEFAULT 0,
  `gate_autoclose` tinyint(4) NOT NULL DEFAULT 0,
  `gate_autoopen` tinyint(4) NOT NULL DEFAULT 0,
  `gate_owner` int(11) NOT NULL,
  `gate_radius` float NOT NULL DEFAULT 2.5,
  `gate_speed` float NOT NULL DEFAULT 0.75,
  `gate_interior` int(11) NOT NULL,
  `gate_virtualworld` int(11) NOT NULL,
  `gate_closed_pos_x` float NOT NULL,
  `gate_closed_pos_y` float NOT NULL,
  `gate_closed_pos_z` float NOT NULL,
  `gate_closed_rot_x` float NOT NULL,
  `gate_closed_rot_y` float NOT NULL,
  `gate_closed_rot_z` float NOT NULL,
  `gate_open_pos_x` float NOT NULL DEFAULT 0,
  `gate_open_pos_y` float NOT NULL DEFAULT 0,
  `gate_open_pos_z` float NOT NULL DEFAULT 0,
  `gate_open_rot_x` float NOT NULL DEFAULT 0,
  `gate_open_rot_y` float NOT NULL DEFAULT 0,
  `gate_open_rot_z` float NOT NULL DEFAULT 0,
  `gate_textureid0` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd0` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename0` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid1` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd1` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename1` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid2` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd2` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename2` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid3` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd3` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename3` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid4` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd4` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename4` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid5` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd5` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename5` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid6` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd6` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename6` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid7` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd7` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename7` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid8` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd8` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename8` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid9` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd9` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename9` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid10` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd10` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename10` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid11` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd11` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename11` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid12` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd12` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename12` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid13` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd13` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename13` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid14` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd14` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename14` varchar(256) NOT NULL DEFAULT 'null',
  `gate_textureid15` int(11) NOT NULL DEFAULT 0,
  `gate_texturetxd15` varchar(256) NOT NULL DEFAULT 'null',
  `gate_texturename15` varchar(256) NOT NULL DEFAULT 'null',
  PRIMARY KEY (`gate_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table gate_factions
CREATE TABLE IF NOT EXISTS `gate_factions` (
  `gate_sqlid` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL,
  PRIMARY KEY (`gate_sqlid`,`faction_id`),
  KEY `idx_gate` (`gate_sqlid`),
  KEY `idx_faction` (`faction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table gd_factory
CREATE TABLE IF NOT EXISTS `gd_factory` (
  `factory` int(11) NOT NULL,
  `wood` int(11) NOT NULL DEFAULT 150,
  `metal` int(11) NOT NULL DEFAULT 150,
  `parts` int(11) NOT NULL DEFAULT 150,
  `slot_0_type` int(11) NOT NULL,
  `slot_0_wood` int(11) NOT NULL,
  `slot_0_metal` int(11) NOT NULL,
  `slot_0_parts` int(11) NOT NULL,
  `slot_0_unix` int(11) NOT NULL DEFAULT 0,
  `slot_1_type` int(11) NOT NULL,
  `slot_1_wood` int(11) NOT NULL,
  `slot_1_metal` int(11) NOT NULL,
  `slot_1_parts` int(11) NOT NULL,
  `slot_1_unix` int(11) NOT NULL DEFAULT 0,
  `slot_2_type` int(11) NOT NULL,
  `slot_2_wood` int(11) NOT NULL,
  `slot_2_metal` int(11) NOT NULL,
  `slot_2_parts` int(11) NOT NULL,
  `slot_2_unix` int(11) NOT NULL DEFAULT 0,
  `slot_3_type` int(11) NOT NULL,
  `slot_3_wood` int(11) NOT NULL,
  `slot_3_metal` int(11) NOT NULL,
  `slot_3_parts` int(11) NOT NULL,
  `slot_3_unix` int(11) NOT NULL DEFAULT 0,
  `slot_4_type` int(11) NOT NULL,
  `slot_4_wood` int(11) NOT NULL,
  `slot_4_metal` int(11) NOT NULL,
  `slot_4_parts` int(11) NOT NULL,
  `slot_4_unix` int(11) NOT NULL DEFAULT 0,
  `ammo_0_type` int(11) NOT NULL DEFAULT -1,
  `ammo_0_amount` int(11) NOT NULL DEFAULT 0,
  `ammo_0_parts` int(11) NOT NULL DEFAULT 0,
  `ammo_0_metal` int(11) NOT NULL DEFAULT 0,
  `ammo_0_unix` int(11) NOT NULL DEFAULT 0,
  `ammo_1_type` int(11) NOT NULL DEFAULT -1,
  `ammo_1_amount` int(11) NOT NULL DEFAULT 0,
  `ammo_1_parts` int(11) NOT NULL DEFAULT 0,
  `ammo_1_metal` int(11) NOT NULL DEFAULT 0,
  `ammo_1_unix` int(11) NOT NULL DEFAULT 0,
  `ammo_2_type` int(11) NOT NULL DEFAULT -1,
  `ammo_2_amount` int(11) NOT NULL DEFAULT 0,
  `ammo_2_parts` int(11) NOT NULL DEFAULT 0,
  `ammo_2_metal` int(11) NOT NULL DEFAULT 0,
  `ammo_2_unix` int(11) NOT NULL DEFAULT 0,
  `ammo_3_type` int(11) NOT NULL DEFAULT -1,
  `ammo_3_amount` int(11) NOT NULL DEFAULT 0,
  `ammo_3_parts` int(11) NOT NULL DEFAULT 0,
  `ammo_3_metal` int(11) NOT NULL DEFAULT 0,
  `ammo_3_unix` int(11) NOT NULL DEFAULT 0,
  `ammo_4_type` int(11) NOT NULL DEFAULT -1,
  `ammo_4_amount` int(11) NOT NULL DEFAULT 0,
  `ammo_4_parts` int(11) NOT NULL DEFAULT 0,
  `ammo_4_metal` int(11) NOT NULL DEFAULT 0,
  `ammo_4_unix` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`factory`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table groups
CREATE TABLE IF NOT EXISTS `groups` (
  `group_data_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `group_data_type` tinyint(4) NOT NULL DEFAULT 0,
  `group_data_name` varchar(64) NOT NULL,
  `group_data_motd` varchar(128) NOT NULL,
  `group_data_chat` tinyint(4) NOT NULL,
  `group_data_hex` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`group_data_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table gym
CREATE TABLE IF NOT EXISTS `gym` (
  `equipment_id` int(11) NOT NULL AUTO_INCREMENT,
  `equipment_type` tinyint(4) NOT NULL,
  `equipment_pos_x` float NOT NULL,
  `equipment_pos_y` float NOT NULL,
  `equipment_pos_z` float NOT NULL,
  `equipment_interior` int(11) NOT NULL,
  `equipment_virtualworld` int(11) NOT NULL,
  PRIMARY KEY (`equipment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table junkie_spawn_locations
CREATE TABLE IF NOT EXISTS `junkie_spawn_locations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `pos_a` float NOT NULL DEFAULT 0,
  `zone_id` int(11) NOT NULL DEFAULT -1,
  `faction_id` int(11) NOT NULL DEFAULT -1,
  `skin` int(11) NOT NULL DEFAULT -1,
  `virtualworld` int(11) NOT NULL DEFAULT 0,
  `interior` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table kiosks
CREATE TABLE IF NOT EXISTS `kiosks` (
  `kiosk_id` int(11) NOT NULL AUTO_INCREMENT,
  `kiosk_name` varchar(256) NOT NULL DEFAULT 'Undefined',
  `kiosk_faction` tinyint(4) NOT NULL DEFAULT -1,
  `kiosk_squad` int(11) NOT NULL DEFAULT 0,
  `kiosk_pos_x` float NOT NULL,
  `kiosk_pos_y` float NOT NULL,
  `kiosk_pos_z` float NOT NULL,
  `kiosk_pos_int` int(11) NOT NULL DEFAULT 0,
  `kiosk_pos_vw` int(11) NOT NULL DEFAULT 0,
  `kiosk_weapon1` tinyint(4) NOT NULL DEFAULT 0,
  `kiosk_weapon1ammo` smallint(6) NOT NULL DEFAULT 0,
  `kiosk_weapon2` smallint(6) NOT NULL DEFAULT 0,
  `kiosk_weapon2ammo` smallint(6) NOT NULL DEFAULT 0,
  `kiosk_weapon3` tinyint(4) DEFAULT 0,
  `kiosk_weapon3ammo` smallint(6) NOT NULL DEFAULT 0,
  `kiosk_weapon4` tinyint(4) NOT NULL DEFAULT 0,
  `kiosk_weapon4ammo` smallint(6) NOT NULL DEFAULT 0,
  `kiosk_weapon5` tinyint(4) NOT NULL DEFAULT 0,
  `kiosk_weapon5ammo` smallint(6) NOT NULL DEFAULT 0,
  PRIMARY KEY (`kiosk_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table licenses
CREATE TABLE IF NOT EXISTS `licenses` (
  `license_id` int(11) NOT NULL AUTO_INCREMENT,
  `license_no` int(11) NOT NULL,
  `license_owner` int(11) NOT NULL,
  `license_type` tinyint(4) NOT NULL,
  `license_subtype` tinyint(4) NOT NULL,
  `license_exp` int(11) NOT NULL,
  `license_issuer` int(11) NOT NULL,
  `license_status` tinyint(4) NOT NULL,
  PRIMARY KEY (`license_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table logs
CREATE TABLE IF NOT EXISTS `logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dir` varchar(1024) NOT NULL,
  `text` varchar(1024) NOT NULL,
  `date` varchar(1024) NOT NULL,
  `ip` varchar(1024) NOT NULL,
  `info` varchar(1024) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table mdc_911_calls
CREATE TABLE IF NOT EXISTS `mdc_911_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `caller_number` int(11) NOT NULL,
  `caller_char_id` int(11) NOT NULL,
  `call_type` tinyint(4) NOT NULL DEFAULT 1,
  `message` text NOT NULL,
  `pos_x` float DEFAULT NULL,
  `pos_y` float DEFAULT NULL,
  `pos_z` float DEFAULT NULL,
  `address` varchar(128) DEFAULT NULL,
  `zone` varchar(64) DEFAULT NULL,
  `city` varchar(64) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_announcements
CREATE TABLE IF NOT EXISTS `mdc_announcements` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(160) NOT NULL,
  `body` text NOT NULL,
  `author_character_id` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL DEFAULT 0,
  `pinned` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ann_faction` (`faction_id`,`deleted_at`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_cases
CREATE TABLE IF NOT EXISTS `mdc_cases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(160) NOT NULL,
  `description` mediumtext DEFAULT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'open',
  `created_by_character_id` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `closed_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cases_status` (`status`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_case_reports
CREATE TABLE IF NOT EXISTS `mdc_case_reports` (
  `case_id` int(10) unsigned NOT NULL,
  `report_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`case_id`,`report_id`),
  KEY `idx_cr_report` (`report_id`),
  CONSTRAINT `fk_cr_case` FOREIGN KEY (`case_id`) REFERENCES `mdc_cases` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cr_report` FOREIGN KEY (`report_id`) REFERENCES `mdc_reports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_evidence
CREATE TABLE IF NOT EXISTS `mdc_evidence` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `report_id` int(10) unsigned DEFAULT NULL,
  `case_id` int(10) unsigned DEFAULT NULL,
  `subject_type` varchar(16) DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `description` varchar(255) NOT NULL DEFAULT '',
  `media_path` varchar(255) DEFAULT NULL,
  `uploaded_by_character_id` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_evidence_report` (`report_id`),
  KEY `idx_evidence_case` (`case_id`),
  KEY `idx_evidence_subject` (`subject_type`,`subject_id`),
  CONSTRAINT `fk_ev_case` FOREIGN KEY (`case_id`) REFERENCES `mdc_cases` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ev_report` FOREIGN KEY (`report_id`) REFERENCES `mdc_reports` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_notes
CREATE TABLE IF NOT EXISTS `mdc_notes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `subject_type` varchar(16) NOT NULL,
  `subject_id` int(11) NOT NULL,
  `body` text NOT NULL,
  `author_character_id` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_notes_subject` (`subject_type`,`subject_id`,`deleted_at`),
  KEY `idx_notes_author` (`author_character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_penal_codes
CREATE TABLE IF NOT EXISTS `mdc_penal_codes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `title` varchar(128) NOT NULL,
  `description` text DEFAULT NULL,
  `category` varchar(64) NOT NULL DEFAULT '',
  `severity` varchar(16) NOT NULL DEFAULT 'misdemeanor',
  `fine_amount` int(10) unsigned NOT NULL DEFAULT 0,
  `jail_minutes` int(10) unsigned NOT NULL DEFAULT 0,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_penal_code` (`code`),
  KEY `idx_penal_enabled` (`enabled`,`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_reports
CREATE TABLE IF NOT EXISTS `mdc_reports` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(160) NOT NULL,
  `body` mediumtext NOT NULL,
  `location` varchar(160) NOT NULL DEFAULT '',
  `status` varchar(16) NOT NULL DEFAULT 'open',
  `author_character_id` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `closed_at` timestamp NULL DEFAULT NULL,
  `closed_by_character_id` int(11) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_reports_status` (`status`,`created_at`),
  KEY `idx_reports_author` (`author_character_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_report_charges
CREATE TABLE IF NOT EXISTS `mdc_report_charges` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `report_id` int(10) unsigned NOT NULL,
  `character_id` int(11) NOT NULL,
  `penal_code_id` int(10) unsigned NOT NULL,
  `count` smallint(5) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_rc_report` (`report_id`),
  KEY `idx_rc_character` (`character_id`),
  KEY `idx_rc_code` (`penal_code_id`),
  CONSTRAINT `fk_rc_code` FOREIGN KEY (`penal_code_id`) REFERENCES `mdc_penal_codes` (`id`),
  CONSTRAINT `fk_rc_report` FOREIGN KEY (`report_id`) REFERENCES `mdc_reports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_report_people
CREATE TABLE IF NOT EXISTS `mdc_report_people` (
  `report_id` int(10) unsigned NOT NULL,
  `character_id` int(11) NOT NULL,
  `role` varchar(16) NOT NULL DEFAULT 'suspect',
  PRIMARY KEY (`report_id`,`character_id`,`role`),
  KEY `idx_rp_character` (`character_id`),
  CONSTRAINT `fk_rp_report` FOREIGN KEY (`report_id`) REFERENCES `mdc_reports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_report_vehicles
CREATE TABLE IF NOT EXISTS `mdc_report_vehicles` (
  `report_id` int(10) unsigned NOT NULL,
  `vehicle_id` int(11) NOT NULL,
  PRIMARY KEY (`report_id`,`vehicle_id`),
  KEY `idx_rv_vehicle` (`vehicle_id`),
  CONSTRAINT `fk_rv_report` FOREIGN KEY (`report_id`) REFERENCES `mdc_reports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_units
CREATE TABLE IF NOT EXISTS `mdc_units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle_sql_id` int(11) NOT NULL,
  `vehicle_model` smallint(6) NOT NULL DEFAULT 0,
  `callsign` varchar(16) NOT NULL,
  `faction_id` int(11) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `angle` float NOT NULL DEFAULT 0,
  `siren_active` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_unit_members
CREATE TABLE IF NOT EXISTS `mdc_unit_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unit_id` int(11) NOT NULL,
  `character_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `callsign` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_member` (`unit_id`,`character_id`),
  KEY `unit_id` (`unit_id`),
  KEY `character_id` (`character_id`),
  KEY `idx_unit_lookup` (`unit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_warrants
CREATE TABLE IF NOT EXISTS `mdc_warrants` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `subject_character_id` int(11) NOT NULL,
  `title` varchar(128) NOT NULL,
  `description` text DEFAULT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'active',
  `issued_by_character_id` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `served_at` timestamp NULL DEFAULT NULL,
  `served_by_character_id` int(11) DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `cancelled_by_character_id` int(11) DEFAULT NULL,
  `cancel_reason` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_warrants_status` (`status`,`created_at`),
  KEY `idx_warrants_subject` (`subject_character_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table mdc_warrant_charges
CREATE TABLE IF NOT EXISTS `mdc_warrant_charges` (
  `warrant_id` int(10) unsigned NOT NULL,
  `penal_code_id` int(10) unsigned NOT NULL,
  `count` smallint(5) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`warrant_id`,`penal_code_id`),
  KEY `idx_wc_code` (`penal_code_id`),
  CONSTRAINT `fk_wc_code` FOREIGN KEY (`penal_code_id`) REFERENCES `mdc_penal_codes` (`id`),
  CONSTRAINT `fk_wc_warrant` FOREIGN KEY (`warrant_id`) REFERENCES `mdc_warrants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table media_images
CREATE TABLE IF NOT EXISTS `media_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `original_name` varchar(255) DEFAULT NULL,
  `file_size` int(11) NOT NULL,
  `mime_type` varchar(100) NOT NULL,
  `views` int(11) DEFAULT 0,
  `uploaded_ip` varchar(45) DEFAULT NULL,
  `uploaded_at` datetime DEFAULT current_timestamp(),
  `title` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `tags` varchar(255) DEFAULT NULL,
  `is_private` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table modshops
CREATE TABLE IF NOT EXISTS `modshops` (
  `mod_shop_id` int(11) NOT NULL AUTO_INCREMENT,
  `mod_shop_type` tinyint(4) NOT NULL,
  `mod_shop_x` float NOT NULL,
  `mod_shop_y` float NOT NULL,
  `mod_shop_z` float NOT NULL,
  PRIMARY KEY (`mod_shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table multiaccount_account_whitelist
CREATE TABLE IF NOT EXISTS `multiaccount_account_whitelist` (
  `whitelist_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` int(10) unsigned NOT NULL,
  `expires_at` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`whitelist_id`),
  UNIQUE KEY `idx_multiaccount_account_whitelist_account` (`account_id`),
  KEY `idx_multiaccount_account_whitelist_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table multiaccount_ip_whitelist
CREATE TABLE IF NOT EXISTS `multiaccount_ip_whitelist` (
  `whitelist_id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(45) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` int(10) unsigned NOT NULL,
  `expires_at` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`whitelist_id`),
  UNIQUE KEY `idx_multiaccount_ip_whitelist_ip` (`ip_address`),
  KEY `idx_multiaccount_ip_whitelist_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table music_sources
CREATE TABLE IF NOT EXISTS `music_sources` (
  `music_id` int(11) NOT NULL AUTO_INCREMENT,
  `music_station` varchar(255) NOT NULL DEFAULT '' COMMENT 'stream url, empty = off',
  `music_x` double NOT NULL,
  `music_y` double NOT NULL,
  `music_z` double NOT NULL,
  `music_int` int(11) NOT NULL DEFAULT 0,
  `music_vw` int(11) NOT NULL DEFAULT 0,
  `music_radius` double NOT NULL DEFAULT 25,
  `music_created_by` varchar(32) NOT NULL DEFAULT '' COMMENT 'account name of the admin who placed it',
  `music_created_at` int(11) NOT NULL DEFAULT 0,
  `music_loop_seconds` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`music_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table notifications
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `type` varchar(32) NOT NULL,
  `title` varchar(96) NOT NULL,
  `body` varchar(255) NOT NULL DEFAULT '',
  `link` varchar(255) DEFAULT NULL,
  `created_at` int(10) unsigned NOT NULL,
  `read_at` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_account_unread` (`account_id`,`read_at`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table passpoints
CREATE TABLE IF NOT EXISTS `passpoints` (
  `passpoint_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `passpoint_desc` varchar(64) NOT NULL,
  `passpoint_linked_desc` varchar(64) NOT NULL DEFAULT '',
  `passpoint_color` int(11) NOT NULL,
  `passpoint_type` int(11) NOT NULL,
  `passpoint_faction` int(11) NOT NULL DEFAULT 0,
  `passpoint_pos_x` float NOT NULL,
  `passpoint_pos_y` float NOT NULL,
  `passpoint_pos_z` float NOT NULL,
  `passpoint_pos_a` float NOT NULL DEFAULT 0,
  `passpoint_linked_x` float NOT NULL DEFAULT 0,
  `passpoint_linked_y` float NOT NULL DEFAULT 0,
  `passpoint_linked_z` float NOT NULL DEFAULT 0,
  `passpoint_linked_a` float NOT NULL DEFAULT 0,
  `passpoint_linked_world` int(11) NOT NULL DEFAULT 0,
  `passpoint_linked_interior` int(11) NOT NULL DEFAULT 0,
  `passpoint_pos_world` int(11) NOT NULL DEFAULT 0,
  `passpoint_pos_interior` int(11) NOT NULL DEFAULT 0,
  `passpoint_radius` float NOT NULL,
  `passpoint_locked` tinyint(4) DEFAULT 0,
  `passpoint_owner` int(11) DEFAULT 0,
  PRIMARY KEY (`passpoint_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table payphones
CREATE TABLE IF NOT EXISTS `payphones` (
  `payphone_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `payphone_number` int(11) NOT NULL DEFAULT 0,
  `payphone_pos_x` float NOT NULL DEFAULT 0,
  `payphone_pos_y` float NOT NULL DEFAULT 0,
  `payphone_pos_z` float NOT NULL DEFAULT 0,
  `payphone_facing` float NOT NULL DEFAULT 0,
  `payphone_worldid` int(11) NOT NULL DEFAULT 0,
  `payphone_interiorid` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`payphone_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table phonebook
CREATE TABLE IF NOT EXISTS `phonebook` (
  `phonebook_id` int(11) NOT NULL AUTO_INCREMENT,
  `character_id` int(11) NOT NULL,
  `phone_number` mediumint(9) NOT NULL,
  `phone_desc` varchar(256) NOT NULL,
  PRIMARY KEY (`phonebook_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table phones
CREATE TABLE IF NOT EXISTS `phones` (
  `phone_number_id` int(11) NOT NULL AUTO_INCREMENT,
  `phone_number_type` int(11) NOT NULL DEFAULT 0,
  `phone_number_owner` int(11) NOT NULL,
  `phone_number_digits` mediumint(9) NOT NULL,
  PRIMARY KEY (`phone_number_id`),
  UNIQUE KEY `phone_number_digits` (`phone_number_digits`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table phone_contacts
CREATE TABLE IF NOT EXISTS `phone_contacts` (
  `phone_contact_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `phone_contact_owner` int(11) NOT NULL DEFAULT 0,
  `phone_contact_number` int(11) NOT NULL DEFAULT 0,
  `phone_contact_desc` varchar(64) NOT NULL DEFAULT '0',
  PRIMARY KEY (`phone_contact_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table phone_logs
CREATE TABLE IF NOT EXISTS `phone_logs` (
  `phone_log_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `phone_log_type` int(11) DEFAULT 0,
  `phone_log_status` int(11) NOT NULL DEFAULT 0,
  `phone_log_sender` int(11) NOT NULL DEFAULT 0,
  `phone_log_recipient` int(11) NOT NULL DEFAULT 0,
  `phone_log_data` varchar(144) NOT NULL,
  `phone_log_unix` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`phone_log_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table player_attachments
CREATE TABLE IF NOT EXISTS `player_attachments` (
  `player_attach_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `player_attach_charid` int(11) NOT NULL,
  `player_attach_model_0` int(11) NOT NULL DEFAULT 0,
  `player_attach_index_0` int(11) NOT NULL DEFAULT 0,
  `player_attach_bone_0` int(11) NOT NULL DEFAULT 0,
  `player_attach_offset_x_0` float NOT NULL DEFAULT 0,
  `player_attach_offset_y_0` float NOT NULL DEFAULT 0,
  `player_attach_offset_z_0` float NOT NULL DEFAULT 0,
  `player_attach_rot_x_0` float NOT NULL DEFAULT 0,
  `player_attach_rot_y_0` float NOT NULL DEFAULT 0,
  `player_attach_rot_z_0` float NOT NULL DEFAULT 0,
  `player_attach_scale_x_0` float NOT NULL DEFAULT 1,
  `player_attach_scale_y_0` float NOT NULL DEFAULT 1,
  `player_attach_scale_z_0` float NOT NULL DEFAULT 1,
  `player_attach_visible_0` int(11) NOT NULL DEFAULT 0,
  `player_attach_model_1` int(11) NOT NULL DEFAULT 0,
  `player_attach_index_1` int(11) NOT NULL DEFAULT 0,
  `player_attach_bone_1` int(11) NOT NULL DEFAULT 0,
  `player_attach_offset_x_1` float NOT NULL DEFAULT 0,
  `player_attach_offset_y_1` float NOT NULL DEFAULT 0,
  `player_attach_offset_z_1` float NOT NULL DEFAULT 0,
  `player_attach_rot_x_1` float NOT NULL DEFAULT 0,
  `player_attach_rot_y_1` float NOT NULL DEFAULT 0,
  `player_attach_rot_z_1` float NOT NULL DEFAULT 0,
  `player_attach_scale_x_1` float NOT NULL DEFAULT 1,
  `player_attach_scale_y_1` float NOT NULL DEFAULT 1,
  `player_attach_scale_z_1` float NOT NULL DEFAULT 1,
  `player_attach_visible_1` int(11) NOT NULL DEFAULT 0,
  `player_attach_model_2` int(11) NOT NULL DEFAULT 0,
  `player_attach_index_2` int(11) NOT NULL DEFAULT 0,
  `player_attach_bone_2` int(11) NOT NULL DEFAULT 0,
  `player_attach_offset_x_2` float NOT NULL DEFAULT 0,
  `player_attach_offset_y_2` float NOT NULL DEFAULT 0,
  `player_attach_offset_z_2` float NOT NULL DEFAULT 0,
  `player_attach_rot_x_2` float NOT NULL DEFAULT 0,
  `player_attach_rot_y_2` float NOT NULL DEFAULT 0,
  `player_attach_rot_z_2` float NOT NULL DEFAULT 0,
  `player_attach_scale_x_2` float NOT NULL DEFAULT 1,
  `player_attach_scale_y_2` float NOT NULL DEFAULT 1,
  `player_attach_scale_z_2` float NOT NULL DEFAULT 1,
  `player_attach_visible_2` int(11) NOT NULL DEFAULT 0,
  `player_attach_model_3` int(11) NOT NULL DEFAULT 0,
  `player_attach_index_3` int(11) NOT NULL DEFAULT 0,
  `player_attach_bone_3` int(11) NOT NULL DEFAULT 0,
  `player_attach_offset_x_3` float NOT NULL DEFAULT 0,
  `player_attach_offset_y_3` float NOT NULL DEFAULT 0,
  `player_attach_offset_z_3` float NOT NULL DEFAULT 0,
  `player_attach_rot_x_3` float NOT NULL DEFAULT 0,
  `player_attach_rot_y_3` float NOT NULL DEFAULT 0,
  `player_attach_rot_z_3` float NOT NULL DEFAULT 0,
  `player_attach_scale_x_3` float NOT NULL DEFAULT 1,
  `player_attach_scale_y_3` float NOT NULL DEFAULT 1,
  `player_attach_scale_z_3` float NOT NULL DEFAULT 1,
  `player_attach_visible_3` int(11) NOT NULL DEFAULT 0,
  `player_attach_model_4` int(11) NOT NULL DEFAULT 0,
  `player_attach_index_4` int(11) NOT NULL DEFAULT 0,
  `player_attach_bone_4` int(11) NOT NULL DEFAULT 0,
  `player_attach_offset_x_4` float NOT NULL DEFAULT 0,
  `player_attach_offset_y_4` float NOT NULL DEFAULT 0,
  `player_attach_offset_z_4` float NOT NULL DEFAULT 0,
  `player_attach_rot_x_4` float NOT NULL DEFAULT 0,
  `player_attach_rot_y_4` float NOT NULL DEFAULT 0,
  `player_attach_rot_z_4` float NOT NULL DEFAULT 0,
  `player_attach_scale_x_4` float NOT NULL DEFAULT 1,
  `player_attach_scale_y_4` float NOT NULL DEFAULT 1,
  `player_attach_scale_z_4` float NOT NULL DEFAULT 1,
  `player_attach_visible_4` int(11) NOT NULL DEFAULT 0,
  `player_attach_model_5` int(11) NOT NULL DEFAULT 0,
  `player_attach_index_5` int(11) NOT NULL DEFAULT 0,
  `player_attach_bone_5` int(11) NOT NULL DEFAULT 0,
  `player_attach_offset_x_5` float NOT NULL DEFAULT 0,
  `player_attach_offset_y_5` float NOT NULL DEFAULT 0,
  `player_attach_offset_z_5` float NOT NULL DEFAULT 0,
  `player_attach_rot_x_5` float NOT NULL DEFAULT 0,
  `player_attach_rot_y_5` float NOT NULL DEFAULT 0,
  `player_attach_rot_z_5` float NOT NULL DEFAULT 0,
  `player_attach_scale_x_5` float NOT NULL DEFAULT 1,
  `player_attach_scale_y_5` float NOT NULL DEFAULT 1,
  `player_attach_scale_z_5` float NOT NULL DEFAULT 1,
  `player_attach_visible_5` int(11) NOT NULL DEFAULT 0,
  `player_attach_model_6` int(11) NOT NULL DEFAULT 0,
  `player_attach_index_6` int(11) NOT NULL DEFAULT 0,
  `player_attach_bone_6` int(11) NOT NULL DEFAULT 0,
  `player_attach_offset_x_6` float NOT NULL DEFAULT 0,
  `player_attach_offset_y_6` float NOT NULL DEFAULT 0,
  `player_attach_offset_z_6` float NOT NULL DEFAULT 0,
  `player_attach_rot_x_6` float NOT NULL DEFAULT 0,
  `player_attach_rot_y_6` float NOT NULL DEFAULT 0,
  `player_attach_rot_z_6` float NOT NULL DEFAULT 0,
  `player_attach_scale_x_6` float NOT NULL DEFAULT 1,
  `player_attach_scale_y_6` float NOT NULL DEFAULT 1,
  `player_attach_scale_z_6` float NOT NULL DEFAULT 1,
  `player_attach_visible_6` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`player_attach_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table player_drugs
CREATE TABLE IF NOT EXISTS `player_drugs` (
  `drug_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `drug_characterid` int(11) NOT NULL,
  `drug_package` tinyint(4) NOT NULL,
  `drug_type` tinyint(4) NOT NULL,
  `drug_grams` float NOT NULL,
  PRIMARY KEY (`drug_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table player_logs
CREATE TABLE IF NOT EXISTS `player_logs` (
  `log_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `log_time` datetime NOT NULL DEFAULT current_timestamp(),
  `log_type` tinyint(3) unsigned NOT NULL,
  `log_char_id` int(10) NOT NULL,
  `logged_name` varchar(32) NOT NULL,
  `logged_playerid` int(10) unsigned NOT NULL DEFAULT 0,
  `logged_ip` varchar(16) NOT NULL,
  `logged_zone` mediumint(8) unsigned NOT NULL,
  `log_entry` varchar(255) NOT NULL,
  PRIMARY KEY (`log_id`),
  KEY `log_type` (`log_type`),
  KEY `log_char_id` (`log_char_id`),
  KEY `log_id` (`log_id`),
  KEY `log_time` (`log_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table player_props
CREATE TABLE IF NOT EXISTS `player_props` (
  `prop_index` int(11) NOT NULL AUTO_INCREMENT,
  `prop_modelid` int(11) NOT NULL,
  `prop_characterid` int(11) NOT NULL DEFAULT 0,
  `prop_offset_x` float NOT NULL DEFAULT 0,
  `prop_offset_y` float NOT NULL DEFAULT 0,
  `prop_offset_z` float NOT NULL DEFAULT 0,
  `prop_rot_x` float NOT NULL DEFAULT 0,
  `prop_rot_y` float NOT NULL DEFAULT 0,
  `prop_rot_z` float NOT NULL DEFAULT 0,
  UNIQUE KEY `prop_index` (`prop_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table player_wardrobes
CREATE TABLE IF NOT EXISTS `player_wardrobes` (
  `player_wardrobe_char_id` int(10) unsigned NOT NULL,
  `player_wardrobe_skin_id` int(10) unsigned NOT NULL,
  `player_wardrobe_skin_lastused` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`player_wardrobe_char_id`,`player_wardrobe_skin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table player_weapons
CREATE TABLE IF NOT EXISTS `player_weapons` (
  `character_id` int(11) NOT NULL,
  `weapon_id` tinyint(4) NOT NULL,
  `weapon_ammo` int(11) NOT NULL,
  UNIQUE KEY `character_id` (`character_id`,`weapon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table player_weapons_attach
CREATE TABLE IF NOT EXISTS `player_weapons_attach` (
  `SQLID` int(11) NOT NULL AUTO_INCREMENT,
  `CharID` int(11) NOT NULL,
  `WeaponID` int(11) NOT NULL,
  `PosX` float NOT NULL DEFAULT 0,
  `PosY` float NOT NULL DEFAULT 0,
  `PosZ` float NOT NULL DEFAULT 0,
  `RotX` float NOT NULL DEFAULT 0,
  `RotY` float NOT NULL DEFAULT 0,
  `RotZ` float NOT NULL DEFAULT 0,
  `Bone` int(11) NOT NULL DEFAULT 0,
  `Hidden` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`SQLID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table pool
CREATE TABLE IF NOT EXISTS `pool` (
  `pool_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `pool_pos_x` float NOT NULL,
  `pool_pos_y` float NOT NULL,
  `pool_pos_z` float NOT NULL,
  `pool_pos_angle` float NOT NULL,
  `pool_pos_int` int(11) NOT NULL,
  `pool_pos_world` int(11) NOT NULL,
  `pool_color` int(11) NOT NULL,
  PRIMARY KEY (`pool_sqlid`),
  UNIQUE KEY `pool_sqlid` (`pool_sqlid`),
  KEY `pool_sqlid_2` (`pool_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table properties
CREATE TABLE IF NOT EXISTS `properties` (
  `property_id` int(11) NOT NULL AUTO_INCREMENT,
  `property_type` tinyint(4) NOT NULL,
  `property_price` int(11) NOT NULL,
  `property_owner` int(11) NOT NULL,
  `property_faction` int(11) NOT NULL DEFAULT 0,
  `property_name` varchar(128) NOT NULL DEFAULT 'Undefined',
  `property_name_color` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `property_locked` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `property_ext_x` float NOT NULL,
  `property_ext_y` float NOT NULL,
  `property_ext_z` float NOT NULL,
  `property_ext_int` int(11) NOT NULL DEFAULT 0,
  `property_ext_vw` int(11) NOT NULL DEFAULT 0,
  `property_int_x` float NOT NULL,
  `property_int_y` float NOT NULL,
  `property_int_z` float NOT NULL,
  `property_int_int` int(11) NOT NULL,
  `property_int_vw` int(11) NOT NULL DEFAULT -1,
  `property_rent` int(11) NOT NULL DEFAULT 0,
  `property_collect` int(11) NOT NULL DEFAULT 0,
  `property_gun_0` int(11) NOT NULL DEFAULT 0,
  `property_ammo_0` int(11) NOT NULL DEFAULT 0,
  `property_gun_1` int(11) NOT NULL DEFAULT 0,
  `property_ammo_1` int(11) NOT NULL DEFAULT 0,
  `property_gun_2` int(11) NOT NULL DEFAULT 0,
  `property_ammo_2` int(11) NOT NULL DEFAULT 0,
  `property_gun_3` int(11) NOT NULL DEFAULT 0,
  `property_ammo_3` int(11) NOT NULL DEFAULT 0,
  `property_gun_4` int(11) NOT NULL DEFAULT 0,
  `property_ammo_4` int(11) NOT NULL DEFAULT 0,
  `property_gun_5` int(11) NOT NULL DEFAULT 0,
  `property_ammo_5` int(11) NOT NULL DEFAULT 0,
  `property_gun_6` int(11) NOT NULL DEFAULT 0,
  `property_ammo_6` int(11) NOT NULL DEFAULT 0,
  `property_gun_7` int(11) NOT NULL DEFAULT 0,
  `property_ammo_7` int(11) NOT NULL DEFAULT 0,
  `property_gun_8` int(11) NOT NULL DEFAULT 0,
  `property_ammo_8` int(11) NOT NULL DEFAULT 0,
  `property_gun_9` int(11) NOT NULL DEFAULT 0,
  `property_ammo_9` int(11) NOT NULL DEFAULT 0,
  `property_buy_type` tinyint(4) NOT NULL DEFAULT 0,
  `property_buy_pos_x` float NOT NULL DEFAULT 4000,
  `property_buy_pos_y` float NOT NULL DEFAULT 4000,
  `property_buy_pos_z` float NOT NULL DEFAULT 4000,
  `property_buy_pos_int` int(11) NOT NULL DEFAULT 0,
  `property_buy_pos_vw` int(11) NOT NULL DEFAULT 0,
  `property_furni_limit` int(11) NOT NULL DEFAULT 0,
  `property_fee` int(11) NOT NULL DEFAULT 0,
  `property_extra_type` int(11) NOT NULL DEFAULT 0,
  `property_extra_pos_x` float NOT NULL DEFAULT 0,
  `property_extra_pos_y` float NOT NULL DEFAULT 0,
  `property_extra_pos_z` float NOT NULL DEFAULT 0,
  `property_extra_pos_int` int(11) NOT NULL DEFAULT 0,
  `property_extra_pos_vw` int(11) NOT NULL DEFAULT 0,
  `property_drugs_type_0` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_0` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_0` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_0` float NOT NULL DEFAULT 0,
  `property_drugs_type_1` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_1` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_1` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_1` float NOT NULL DEFAULT 0,
  `property_drugs_type_2` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_2` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_2` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_2` float NOT NULL DEFAULT 0,
  `property_drugs_type_3` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_3` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_3` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_3` float NOT NULL DEFAULT 0,
  `property_drugs_type_4` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_4` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_4` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_4` float NOT NULL DEFAULT 0,
  `property_drugs_type_5` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_5` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_5` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_5` float NOT NULL DEFAULT 0,
  `property_drugs_type_6` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_6` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_6` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_6` float NOT NULL DEFAULT 0,
  `property_drugs_type_7` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_7` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_7` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_7` float NOT NULL DEFAULT 0,
  `property_drugs_type_8` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_8` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_8` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_8` float NOT NULL DEFAULT 0,
  `property_drugs_type_9` int(11) NOT NULL DEFAULT 0,
  `property_drugs_param_9` int(11) NOT NULL DEFAULT 0,
  `property_drugs_container_9` int(11) NOT NULL DEFAULT 0,
  `property_drugs_amount_9` float NOT NULL DEFAULT 0,
  `property_int_hours` int(11) NOT NULL DEFAULT 12,
  `property_int_mins` int(11) NOT NULL DEFAULT 0,
  `property_int_weather` tinyint(4) NOT NULL DEFAULT 14,
  `property_int_audio_on` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `property_int_audio_x` float NOT NULL DEFAULT 0,
  `property_int_audio_y` float NOT NULL DEFAULT 0,
  `property_int_audio_z` float NOT NULL DEFAULT 0,
  `property_int_audio_id` int(10) unsigned NOT NULL DEFAULT 0,
  `property_int_audio_url` varchar(255) NOT NULL DEFAULT 'NULL',
  `property_firm` int(11) NOT NULL DEFAULT 0,
  `property_tier` tinyint(4) NOT NULL DEFAULT 0,
  `property_firm_price` int(11) NOT NULL DEFAULT 0,
  `property_firm_cost` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table refunds
CREATE TABLE IF NOT EXISTS `refunds` (
  `refund_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `refund_date` datetime NOT NULL DEFAULT current_timestamp(),
  `refund_player_id` int(10) unsigned NOT NULL,
  `refund_issuer_id` int(10) NOT NULL DEFAULT -1,
  `refund_type` int(10) unsigned NOT NULL DEFAULT 0,
  `refund_itemtype` int(10) unsigned NOT NULL DEFAULT 0,
  `refund_subtype` int(10) unsigned NOT NULL DEFAULT 0,
  `refund_infratype` int(10) unsigned NOT NULL DEFAULT 0,
  `refund_amount` float unsigned NOT NULL DEFAULT 0,
  `refund_reason` varchar(255) NOT NULL,
  `refund_claimed` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`refund_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table registrations
CREATE TABLE IF NOT EXISTS `registrations` (
  `registration_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `day` tinyint(4) NOT NULL,
  `month` tinyint(4) NOT NULL,
  `year` mediumint(9) NOT NULL,
  `unix` int(11) DEFAULT NULL,
  PRIMARY KEY (`registration_id`),
  UNIQUE KEY `account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table report_activity
CREATE TABLE IF NOT EXISTS `report_activity` (
  `report_id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` int(11) NOT NULL,
  `reporter_id` int(11) NOT NULL,
  `report` varchar(128) NOT NULL,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table rprf_points
CREATE TABLE IF NOT EXISTS `rprf_points` (
  `rprf_id` int(11) NOT NULL AUTO_INCREMENT,
  `rprf_desc` varchar(64) NOT NULL,
  `rprf_pos_x` double NOT NULL,
  `rprf_pos_y` double NOT NULL,
  `rprf_pos_z` double NOT NULL,
  `rprf_type` tinyint(4) NOT NULL,
  `rprf_faction_type` int(11) NOT NULL DEFAULT -1,
  `rprf_hidden` tinyint(4) NOT NULL DEFAULT 0 COMMENT '1 = pickup and label only show up close by',
  PRIMARY KEY (`rprf_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table rules_quiz_attempts
CREATE TABLE IF NOT EXISTS `rules_quiz_attempts` (
  `attempt_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `score` tinyint(3) unsigned NOT NULL,
  `total_questions` tinyint(3) unsigned NOT NULL,
  `required_score` tinyint(3) unsigned NOT NULL,
  `passed` tinyint(1) NOT NULL DEFAULT 0,
  `answers_json` longtext NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`attempt_id`),
  KEY `idx_rules_quiz_attempts_account_created` (`account_id`,`created_at`),
  KEY `idx_rules_quiz_attempts_passed` (`passed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table server
CREATE TABLE IF NOT EXISTS `server` (
  `server_propertytax` int(11) NOT NULL DEFAULT 0,
  `server_index` int(11) NOT NULL,
  `server_slots_jackpot` int(11) NOT NULL,
  `server_slots_motd_1` varchar(96) NOT NULL,
  `server_slots_motd_2` varchar(96) NOT NULL,
  `server_slots_motd_3` varchar(96) NOT NULL,
  `server_motd_editor` varchar(24) NOT NULL,
  `server_motd_edit_time` int(11) NOT NULL,
  `server_admin_hex` int(11) NOT NULL DEFAULT -1,
  `server_helper_hex` int(11) NOT NULL DEFAULT -1,
  `server_chopshop_factionid` int(11) NOT NULL DEFAULT -1,
  `server_chopshop_collect` int(11) NOT NULL DEFAULT 1500,
  `police_kiosk_x` float NOT NULL DEFAULT 0,
  `police_kiosk_y` float NOT NULL DEFAULT 0,
  `police_kiosk_z` float NOT NULL DEFAULT 0,
  `police_kiosk_vw` int(11) NOT NULL DEFAULT 0,
  `police_kiosk_int` int(11) NOT NULL DEFAULT 0,
  `medic_kiosk_x` float NOT NULL,
  `medic_kiosk_y` float NOT NULL,
  `medic_kiosk_z` float NOT NULL,
  `medic_kiosk_vw` tinyint(4) NOT NULL,
  `medic_kiosk_int` tinyint(4) NOT NULL,
  `dea_kiosk_x` float NOT NULL DEFAULT 0,
  `dea_kiosk_y` float NOT NULL DEFAULT 0,
  `dea_kiosk_z` float NOT NULL DEFAULT 0,
  `dea_kiosk_vw` int(10) unsigned NOT NULL DEFAULT 0,
  `dea_kiosk_int` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `sheriff_kiosk_x` float NOT NULL DEFAULT 0,
  `sheriff_kiosk_y` float NOT NULL DEFAULT 0,
  `sheriff_kiosk_z` float NOT NULL DEFAULT 0,
  `sheriff_kiosk_vw` int(10) unsigned NOT NULL DEFAULT 0,
  `sheriff_kiosk_int` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `server_song_url` varchar(255) NOT NULL DEFAULT 'https://gtalegacy.com/server/audio/welcome.mp3',
  `police_fines_total` int(11) NOT NULL DEFAULT 0,
  `registration_ucp` tinyint(4) NOT NULL DEFAULT 1,
  `admin_motd_1` varchar(96) DEFAULT NULL,
  `admin_motd_2` varchar(96) DEFAULT NULL,
  `admin_motd_3` varchar(96) DEFAULT NULL,
  `admin_motd_editor` varchar(24) DEFAULT NULL,
  `admin_motd_edit_time` int(11) DEFAULT NULL,
  PRIMARY KEY (`server_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table sessions
CREATE TABLE IF NOT EXISTS `sessions` (
  `e_session_id` int(11) NOT NULL AUTO_INCREMENT,
  `e_session_acc` int(11) NOT NULL,
  `e_session_char` int(10) unsigned NOT NULL DEFAULT 0,
  `e_session_web` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `e_session_time` int(11) NOT NULL,
  `e_session_idle` int(11) NOT NULL,
  `e_session_ip` varchar(32) NOT NULL,
  `e_session_duty` int(10) unsigned NOT NULL DEFAULT 0,
  `e_session_unix_store` int(11) NOT NULL DEFAULT 0,
  `e_session_unix_last` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`e_session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table short_urls
CREATE TABLE IF NOT EXISTS `short_urls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `code` varchar(64) NOT NULL,
  `target_url` varchar(2048) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `click_count` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_short_urls_account_code` (`account_id`,`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table sms
CREATE TABLE IF NOT EXISTS `sms` (
  `sms_id` int(11) NOT NULL AUTO_INCREMENT,
  `sms_character_id` int(11) NOT NULL,
  `sms_sender` mediumint(9) NOT NULL,
  `sms_receiver_charid` int(11) NOT NULL,
  `sms_data_type` tinyint(4) NOT NULL,
  `sms_text` varchar(128) NOT NULL,
  `sms_date` int(11) NOT NULL DEFAULT 0,
  `sms_read` tinyint(4) NOT NULL,
  PRIMARY KEY (`sms_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table strawman_logs
CREATE TABLE IF NOT EXISTS `strawman_logs` (
  `strawman_log_id` int(11) NOT NULL AUTO_INCREMENT,
  `strawman_log_note` varchar(512) NOT NULL,
  `strawman_log_interact` tinyint(4) NOT NULL,
  `strawman_log_accountid` int(11) NOT NULL,
  `strawman_log_unix` int(11) NOT NULL,
  PRIMARY KEY (`strawman_log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table street_boss_npcs
CREATE TABLE IF NOT EXISTS `street_boss_npcs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) NOT NULL DEFAULT 0,
  `owner_name` varchar(32) NOT NULL DEFAULT '',
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `pos_a` float NOT NULL DEFAULT 0,
  `skin` int(11) NOT NULL DEFAULT 0,
  `weed_price` int(11) NOT NULL DEFAULT 0,
  `crack_price` int(11) NOT NULL DEFAULT 0,
  `cocaine_price` int(11) NOT NULL DEFAULT 0,
  `virtualworld` int(11) NOT NULL DEFAULT 0,
  `interior` int(11) NOT NULL DEFAULT 0,
  `earnings` int(11) NOT NULL DEFAULT 0,
  `total_sales` int(11) NOT NULL DEFAULT 0,
  `seized` tinyint(4) NOT NULL DEFAULT 0,
  `seized_by` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table street_boss_npc_stock
CREATE TABLE IF NOT EXISTS `street_boss_npc_stock` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `npc_id` int(11) NOT NULL,
  `drug_type` tinyint(4) NOT NULL DEFAULT 0,
  `tier` tinyint(4) NOT NULL DEFAULT 0,
  `amount` float NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `npc_id` (`npc_id`),
  CONSTRAINT `street_boss_npc_stock_ibfk_1` FOREIGN KEY (`npc_id`) REFERENCES `street_boss_npcs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table trucker_contracts

-- Dumping structure for table trucker_industries

-- Dumping structure for table trucker_storages

-- Dumping structure for table ucp_login_attempts
CREATE TABLE IF NOT EXISTS `ucp_login_attempts` (
  `account_id` int(11) DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_name` varchar(24) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `success` tinyint(1) NOT NULL,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table ucp_registration_attempts
CREATE TABLE IF NOT EXISTS `ucp_registration_attempts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_name` varchar(24) NOT NULL,
  `email` varchar(256) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `success` tinyint(1) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table vehicles
CREATE TABLE IF NOT EXISTS `vehicles` (
  `vehicle_sqlid` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle_modelid` smallint(6) NOT NULL DEFAULT 462,
  `vehicle_type` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_jobid` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_siren` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_siren_type` int(11) NOT NULL DEFAULT -1,
  `vehicle_owner` int(11) NOT NULL DEFAULT -1,
  `vehicle_mileage` int(11) NOT NULL DEFAULT 0,
  `vehicle_color_a` smallint(6) NOT NULL DEFAULT -1,
  `vehicle_color_b` smallint(6) NOT NULL DEFAULT -1,
  `vehicle_pos_x` float NOT NULL,
  `vehicle_pos_y` float NOT NULL,
  `vehicle_pos_z` float NOT NULL,
  `vehicle_pos_a` float NOT NULL,
  `vehicle_vw` int(11) NOT NULL DEFAULT 0,
  `vehicle_int` int(11) NOT NULL DEFAULT 0,
  `vehicle_license` varchar(16) NOT NULL DEFAULT '1ABC123',
  `vehicle_fuel` tinyint(4) NOT NULL DEFAULT 25,
  `vehicle_wrong_fuel_amount` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `vehicle_neon` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_1` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_1` smallint(6) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_2` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_2` smallint(6) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_3` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_3` smallint(6) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_4` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_4` smallint(6) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_5` tinyint(4) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_5` smallint(6) NOT NULL DEFAULT 0,
  `vehicle_paintjob` tinyint(4) NOT NULL DEFAULT 3,
  `vehicle_health` float NOT NULL DEFAULT 1000,
  `vehicle_dmg_panels` int(11) NOT NULL DEFAULT 0,
  `vehicle_dmg_doors` int(11) NOT NULL DEFAULT 0,
  `vehicle_dmg_lights` int(11) NOT NULL DEFAULT 0,
  `vehicle_dmg_tires` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_6` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_6` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_7` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_7` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_8` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_8` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_9` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_9` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_wep_10` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_ammo_10` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_1` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_1` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_1` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_1` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_2` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_2` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_2` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_2` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_3` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_3` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_3` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_3` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_4` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_4` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_4` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_4` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_5` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_5` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_5` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_5` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_6` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_6` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_6` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_6` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_7` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_7` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_7` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_7` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_8` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_8` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_8` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_8` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_9` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_9` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_9` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_9` float NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_type_10` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_param_10` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_cont_10` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_drugs_amount_10` float NOT NULL DEFAULT 0,
  `vehicle_doors` int(11) NOT NULL DEFAULT 0,
  `vehicle_parked_at` int(10) unsigned NOT NULL DEFAULT 0,
  `vehicle_impounded` int(11) NOT NULL DEFAULT 0,
  `vehicle_impounded_until` datetime DEFAULT NULL,
  `vehicle_impound_cost` int(10) unsigned NOT NULL DEFAULT 0,
  `vehicle_impound_reason` varchar(255) DEFAULT NULL,
  `vehicle_impounded_by` varchar(255) DEFAULT NULL,
  `vehicle_attach_model1` int(11) NOT NULL DEFAULT 65535,
  `vehicle_attach_x1` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_y1` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_z1` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rx1` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_ry1` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rz1` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_model2` int(11) NOT NULL DEFAULT 65535,
  `vehicle_attach_x2` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_y2` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_z2` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rx2` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_ry2` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rz2` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_model3` int(11) NOT NULL DEFAULT 65535,
  `vehicle_attach_x3` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_y3` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_z3` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rx3` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_ry3` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rz3` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_purchase_date` int(11) DEFAULT NULL,
  `vehicle_squad` int(11) DEFAULT -1,
  `vehicle_trunk_burg_1` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_2` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_3` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_4` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_5` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_6` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_7` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_8` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_9` int(11) NOT NULL DEFAULT 0,
  `vehicle_trunk_burg_10` int(11) NOT NULL DEFAULT 0,
  `vehicle_attach_model4` int(11) NOT NULL DEFAULT 65535,
  `vehicle_attach_x4` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_y4` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_z4` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rx4` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_ry4` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rz4` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_model5` int(11) NOT NULL DEFAULT 65535,
  `vehicle_attach_x5` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_y5` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_z5` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rx5` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_ry5` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_attach_rz5` float(11,3) NOT NULL DEFAULT 0.000,
  `vehicle_pooled_at` int(11) NOT NULL DEFAULT 0 COMMENT 'unix time the car entered the scrap pool, 0 = not pooled',
  `vehicle_pool_value` int(11) NOT NULL DEFAULT 0 COMMENT 'what the scrapper was paid / what a used car firm pays for it',
  `vehicle_sale_price` int(11) NOT NULL DEFAULT 0 COMMENT 'used car lot asking price, 0 = not for sale',
  `vehicle_oil_service_miles` int(11) NOT NULL DEFAULT 0,
  `vehicle_engine_wear` int(11) NOT NULL DEFAULT 0,
  `vehicle_repair_ready_at` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`vehicle_sqlid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table vehicle_components
CREATE TABLE IF NOT EXISTS `vehicle_components` (
  `componentid` smallint(5) unsigned NOT NULL,
  `part` enum('Exhausts','Front Bullbars','Front Bumper','Hood','Hydraulics','Lights','Misc','Rear Bullbars','Rear Bumper','Roof','Side Skirts','Spoilers','Vents','Wheels') DEFAULT NULL,
  `type` varchar(22) NOT NULL,
  `cars` smallint(6) NOT NULL,
  PRIMARY KEY (`componentid`),
  KEY `cars` (`cars`),
  KEY `part` (`part`),
  KEY `type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- Dumping structure for table vehicle_model_parts
CREATE TABLE IF NOT EXISTS `vehicle_model_parts` (
  `modelid` smallint(5) unsigned NOT NULL,
  `parts` bit(9) NOT NULL,
  PRIMARY KEY (`modelid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- Dumping structure for table vehicle_saved_mods
CREATE TABLE IF NOT EXISTS `vehicle_saved_mods` (
  `vehicle_saved_id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle_sql_id` int(11) NOT NULL,
  `vehicle_component_id` smallint(6) NOT NULL,
  PRIMARY KEY (`vehicle_saved_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table vehicle_tickets
CREATE TABLE IF NOT EXISTS `vehicle_tickets` (
  `vt_id` int(11) NOT NULL AUTO_INCREMENT,
  `vt_vehicle_sqlid` int(11) NOT NULL,
  `vt_plate` varchar(32) NOT NULL,
  `vt_amount` int(11) NOT NULL,
  `vt_reason` varchar(128) NOT NULL,
  `vt_issuer_charid` int(11) NOT NULL,
  `vt_issuer_name` varchar(32) NOT NULL,
  `vt_issuer_faction` int(11) NOT NULL,
  `vt_date` datetime DEFAULT current_timestamp(),
  `vt_due` datetime NOT NULL,
  `vt_status` tinyint(4) DEFAULT 0,
  `vt_paid_date` datetime DEFAULT NULL,
  PRIMARY KEY (`vt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table vehicle_trunks
CREATE TABLE IF NOT EXISTS `vehicle_trunks` (
  `trunk_sql_id` int(11) NOT NULL,
  `trunk_veh_sql_id` int(11) NOT NULL,
  `trunk_weapon_1` tinyint(4) NOT NULL,
  `trunk_weapon_ammo_1` int(11) NOT NULL,
  `trunk_weapon_2` tinyint(4) NOT NULL,
  `trunk_weapon_ammo_2` int(11) NOT NULL,
  `trunk_weapon_3` tinyint(4) NOT NULL,
  `trunk_weapon_ammo_3` int(11) NOT NULL,
  `trunk_weapon_4` tinyint(4) NOT NULL,
  `trunk_weapon_ammo_4` int(11) NOT NULL,
  `trunk_weapon_5` tinyint(4) NOT NULL,
  `trunk_weapon_ammo_5` int(11) NOT NULL,
  PRIMARY KEY (`trunk_sql_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table vpn_whitelist
CREATE TABLE IF NOT EXISTS `vpn_whitelist` (
  `whitelist_id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`whitelist_id`),
  UNIQUE KEY `account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table wardrobes
CREATE TABLE IF NOT EXISTS `wardrobes` (
  `wardrobe_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `wardrobe_type` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `wardrobe_owner` int(10) unsigned NOT NULL DEFAULT 0,
  `wardrobe_name` varchar(255) DEFAULT 'Wardrobe',
  `wardrobe_pos_x` float NOT NULL,
  `wardrobe_pos_y` float NOT NULL,
  `wardrobe_pos_z` float NOT NULL,
  `wardrobe_pos_a` float NOT NULL DEFAULT 0,
  `wardrobe_world` int(10) unsigned NOT NULL DEFAULT 0,
  `wardrobe_int` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`wardrobe_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping structure for table weapons
CREATE TABLE IF NOT EXISTS `weapons` (
  `character_id` int(11) NOT NULL,
  `weapon_id` tinyint(4) NOT NULL,
  `weapon_ammo` int(11) NOT NULL,
  UNIQUE KEY `character_id` (`character_id`,`weapon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping structure for table web_commands
CREATE TABLE IF NOT EXISTS `web_commands` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `command` varchar(64) NOT NULL,
  `params` varchar(512) NOT NULL DEFAULT '',
  `status` varchar(16) NOT NULL DEFAULT 'pending',
  `result` varchar(255) DEFAULT NULL,
  `issued_by` int(11) NOT NULL,
  `issued_at` datetime NOT NULL DEFAULT current_timestamp(),
  `processed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Empty optional web integration tables. No custom models or voice channels are seeded.
CREATE TABLE IF NOT EXISTS `faction_custom_models` (
    `faction_model_id` INTEGER NOT NULL AUTO_INCREMENT,
    `faction_model_factionid` INTEGER NOT NULL DEFAULT 0,
    `faction_model_baseid` INTEGER NOT NULL DEFAULT 0,
    `faction_model_skinid` INTEGER NOT NULL DEFAULT 0,
    `faction_model_dff` VARCHAR(191) NOT NULL DEFAULT '',
    `faction_model_txd` VARCHAR(191) NOT NULL DEFAULT '',
    `faction_model_enabled` INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (`faction_model_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `voice_channels` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `channel_key` VARCHAR(191) NOT NULL,
    `department` VARCHAR(16) NOT NULL,
    `parent_id` INTEGER NULL,
    `node_type` VARCHAR(16) NOT NULL DEFAULT 'channel',
    `label` VARCHAR(191) NOT NULL,
    `sort_order` INTEGER NOT NULL DEFAULT 0,
    `locked` INTEGER NOT NULL DEFAULT 0,
    `mutual` INTEGER NOT NULL DEFAULT 0,

    UNIQUE INDEX `voice_channels_channel_key_key`(`channel_key`),
    INDEX `voice_channels_department_idx`(`department`),
    INDEX `voice_channels_parent_id_idx`(`parent_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `voice_groups` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(191) NOT NULL,
    `department` VARCHAR(16) NULL,
    `color` VARCHAR(16) NOT NULL DEFAULT '',
    `sort_order` INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `voice_group_members` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `group_id` INTEGER NOT NULL,
    `character_id` INTEGER NOT NULL,
    `assigned_by` INTEGER NULL,
    `assigned_at` INTEGER NOT NULL DEFAULT 0,

    INDEX `voice_group_members_character_id_idx`(`character_id`),
    UNIQUE INDEX `voice_group_members_group_id_character_id_key`(`group_id`, `character_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `voice_channel_access` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `channel_id` INTEGER NOT NULL,
    `group_id` INTEGER NOT NULL,

    INDEX `voice_channel_access_channel_id_idx`(`channel_id`),
    UNIQUE INDEX `voice_channel_access_channel_id_group_id_key`(`channel_id`, `group_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `player_skins` (
    `player_skin_id` INTEGER NOT NULL AUTO_INCREMENT,
    `player_skin_charid` INTEGER NOT NULL,
    `player_skin_baseid` INTEGER NOT NULL,
    `player_skin_dff` VARCHAR(63) NOT NULL,
    `player_skin_txd` VARCHAR(63) NOT NULL,
    `player_skin_lastused` INTEGER NOT NULL DEFAULT 0,
    `player_skin_disabled` INTEGER NOT NULL DEFAULT 0,

    INDEX `player_skins_player_skin_charid_idx`(`player_skin_charid`),
    PRIMARY KEY (`player_skin_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Seed data
-- ---------------------------------------------------------------------------

-- Global server settings row (the gamemode reads this on start-up).
INSERT INTO `server` (`server_propertytax`, `server_index`, `server_slots_jackpot`, `server_slots_motd_1`, `server_slots_motd_2`, `server_slots_motd_3`, `server_motd_editor`, `server_motd_edit_time`, `server_admin_hex`, `server_helper_hex`, `server_chopshop_factionid`, `server_chopshop_collect`, `police_kiosk_x`, `police_kiosk_y`, `police_kiosk_z`, `police_kiosk_vw`, `police_kiosk_int`, `medic_kiosk_x`, `medic_kiosk_y`, `medic_kiosk_z`, `medic_kiosk_vw`, `medic_kiosk_int`, `dea_kiosk_x`, `dea_kiosk_y`, `dea_kiosk_z`, `dea_kiosk_vw`, `dea_kiosk_int`, `sheriff_kiosk_x`, `sheriff_kiosk_y`, `sheriff_kiosk_z`, `sheriff_kiosk_vw`, `sheriff_kiosk_int`, `server_song_url`, `police_fines_total`, `registration_ucp`, `admin_motd_1`, `admin_motd_2`, `admin_motd_3`, `admin_motd_editor`, `admin_motd_edit_time`) VALUES
	(0, 0, 0, 'Welcome to OpenRP Framework!', 'Edit this message with the MOTD admin command.', '', '', 0, -175619841, -2015655681, -1, 1500, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, NULL, NULL, NULL, NULL, NULL);

-- Default factions. SQL ids 1 and 2 are referenced by FACTION_ID_SAPD / FACTION_ID_FDSA in gamemodes/gamemode.pwn.
-- faction_type: 0 = law enforcement, 3 = EMS/fire (see FACTION_TYPE_* in gamemode.pwn)
-- faction_capabilities is a FAC_CAP_* bitmask. TODO: set the spawn coordinates (faction_spawn_x/y/z/a) for your map; they are 0,0,0 for now.
INSERT INTO `factions` (`faction_id`, `faction_name`, `faction_abbrev`, `faction_type`, `faction_capabilities`, `faction_show_activity`, `faction_extra`, `faction_chat`, `faction_hex`, `faction_bank`, `faction_playerslots`, `faction_carslots`, `faction_spawnvisible`, `faction_spawn_x`, `faction_spawn_y`, `faction_spawn_z`, `faction_spawn_a`, `faction_spawn_int`, `faction_spawn_vw`, `faction_spawn_icon`, `faction_visible`, `faction_perk_cd`, `faction_assigned_emmet`, `faction_f_on`, `faction_active_minutes`, `faction_perk_buys`) VALUES
	(1, 'San Andreas Police Department', 'SAPD', 0, 1535, 1, 0, 1, 1438802175, 0, 25, 25, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0),
	(2, 'Fire Department of San Andreas', 'FDSA', 3, 1948, 1, 0, 0, 1619564799, 0, 25, 25, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0);

-- Weapon armory categories for each faction (add weapons with the faction armory admin commands).
INSERT INTO `faction_armory_types` (`armory_type_id`, `faction_id`, `type_name`, `type_enabled`) VALUES
	(1, 1, 'Standard', 1),
	(2, 1, 'SWAT', 1),
	(3, 2, 'Standard', 1);

-- No default administrator or character is shipped.
-- Create your own once with web-platform/web/scripts/create-admin.mjs.

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
