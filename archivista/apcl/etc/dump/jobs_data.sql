-- MySQL dump 10.9
--
-- Host: localhost    Database: archivista
-- ------------------------------------------------------
-- Server version	4.1.10-log
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO,MYSQL40' */;

--
-- Table structure for table `jobs_data`
--

DROP TABLE IF EXISTS `jobs_data`;
CREATE TABLE `jobs_data` (
  `jid` int(11) NOT NULL default '0',
  `param` varchar(32) NOT NULL default '',
  `value` varchar(255) default NULL
) TYPE=MyISAM;

--
-- Dumping data for table `jobs_data`
--


/*!40000 ALTER TABLE `jobs_data` DISABLE KEYS */;
LOCK TABLES `jobs_data` WRITE;
INSERT INTO `jobs_data` VALUES (3,'SCAN_DEFINITION','A4 (SW)'),(4,'SCAN_DEFINITIONS','A4+%28SW%29'),(5,'SCAN_DEFINITION','A4 (SW)'),(6,'SCAN_DEFINITION','A4 (Grau)'),(7,'SCAN_DEFINITION','A4 (Grau)');
UNLOCK TABLES;
/*!40000 ALTER TABLE `jobs_data` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;

