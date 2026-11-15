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

ALTER TABLE accounts ADD COLUMN IF NOT EXISTS twofa_attempts TINYINT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE ucp_login_attempts ADD COLUMN IF NOT EXISTS account_id INT NULL;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS account_email_verify_sent_at INT NULL;
