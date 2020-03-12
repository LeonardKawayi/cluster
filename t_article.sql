/*
 Navicat MySQL Data Transfer

 Source Server         : 本地环境
 Source Server Type    : MySQL
 Source Server Version : 80019
 Source Host           : localhost:3306
 Source Schema         : blog_system

 Target Server Type    : MySQL
 Target Server Version : 80019
 File Encoding         : 65001

 Date: 12/03/2020 16:55:26
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_article
-- ----------------------------
DROP TABLE IF EXISTS `t_article`;
CREATE TABLE `t_article` (
  `id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `content` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created` date DEFAULT NULL,
  `modified` date DEFAULT NULL,
  `categories` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `tags` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `allow_comment` tinyint(1) DEFAULT NULL,
  `thumbnail` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------
-- Records of t_article
-- ----------------------------
BEGIN;
INSERT INTO `t_article` VALUES (1, 'hello world!', 'hello world! im coming.', '2020-03-12', '2020-03-12', '1', '2', 1, '4');
INSERT INTO `t_article` VALUES (2, 'java', 'java', '2020-03-12', '2020-03-12', 'java', 'java', 0, 'java');
INSERT INTO `t_article` VALUES (3, 'c', 'c', '2020-03-12', '2020-03-12', 'c', 'c', 0, 'c');
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
