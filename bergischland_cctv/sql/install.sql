CREATE TABLE IF NOT EXISTS `cameras` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NOT NULL DEFAULT 'public',
    `x` DOUBLE NOT NULL,
    `y` DOUBLE NOT NULL,
    `z` DOUBLE NOT NULL,
    `rotation` FLOAT NOT NULL DEFAULT 0,
    `range` INT NOT NULL DEFAULT 35,
    `fov` INT NOT NULL DEFAULT 70,
    `status` VARCHAR(20) NOT NULL DEFAULT 'ONLINE',
    `owner` VARCHAR(100) NOT NULL DEFAULT '',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `recordings` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `camera_id` INT NOT NULL,
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME NULL DEFAULT NULL,
    `destroyed` TINYINT(1) NOT NULL DEFAULT 0,
    `destroyed_at` DATETIME NULL DEFAULT NULL,
    `recording_data` LONGTEXT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_recordings_camera_id` (`camera_id`),
    KEY `idx_recordings_destroyed` (`destroyed`),
    CONSTRAINT `fk_recordings_camera`
        FOREIGN KEY (`camera_id`) REFERENCES `cameras` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `evidence` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `recording_id` BIGINT NOT NULL,
    `officer_identifier` VARCHAR(255) NOT NULL,
    `officer_name` VARCHAR(255) NOT NULL,
    `case_number` VARCHAR(100) NULL DEFAULT NULL,
    `reason` TEXT NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_evidence_recording` (`recording_id`),
    CONSTRAINT `fk_evidence_recording`
        FOREIGN KEY (`recording_id`) REFERENCES `recordings` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `camera_access` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `camera_id` INT NOT NULL,
    `identifier` VARCHAR(255) NOT NULL,
    `access_type` VARCHAR(20) NOT NULL DEFAULT 'user',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_camera_access` (`camera_id`, `identifier`, `access_type`),
    CONSTRAINT `fk_camera_access_camera`
        FOREIGN KEY (`camera_id`) REFERENCES `cameras` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS `idx_cameras_status` ON `cameras` (`status`);
CREATE INDEX IF NOT EXISTS `idx_cameras_type` ON `cameras` (`type`);
