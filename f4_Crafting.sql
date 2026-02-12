-- ═══════════════════════════════════════════════════════════════════════════════════════
-- F4-Crafting System - Database Schema
-- Author: F4 Development
-- Description: Database table for storing crafting bench locations
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Create crafting tables table
CREATE TABLE IF NOT EXISTS `f4_crafting` (
    `id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier for each crafting bench',
    `x` FLOAT NOT NULL COMMENT 'X coordinate of the bench',
    `y` FLOAT NOT NULL COMMENT 'Y coordinate of the bench',
    `z` FLOAT NOT NULL COMMENT 'Z coordinate of the bench',
    `heading` FLOAT NOT NULL DEFAULT 0 COMMENT 'Rotation/heading of the bench',
    `craft_queue` LONGTEXT NULL COMMENT 'Pending crafted items queue in JSON format',
    `queue_updated_at` DATETIME NULL DEFAULT NULL COMMENT 'Last queue update timestamp',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stores crafting bench positions';

ALTER TABLE `f4_crafting`
    ADD COLUMN IF NOT EXISTS `craft_queue` LONGTEXT NULL COMMENT 'Pending crafted items queue in JSON format',
    ADD COLUMN IF NOT EXISTS `queue_updated_at` DATETIME NULL DEFAULT NULL COMMENT 'Last queue update timestamp';
