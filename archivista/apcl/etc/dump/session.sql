-- MySQL dump 10.9
--
-- Host: localhost    Database: archivista 
-- ------------------------------------------------------
-- Server version	4.1.10-log
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO,MYSQL40' */;

--
-- Table structure for table `session`
--

DROP TABLE IF EXISTS `session`;
CREATE TABLE `session` (
  `sid` varchar(32) NOT NULL default '',
  `host` varchar(16) NOT NULL default '',
  `db` varchar(16) NOT NULL default '',
  `user` varchar(16) NOT NULL default '',
  `password` varchar(16) default NULL,
	`language` varchar(2) default 'de',
  PRIMARY KEY  (`sid`)
) TYPE=Heap;

--
-- Dumping data for table `session`
--


/*!40000 ALTER TABLE `session` DISABLE KEYS */;
LOCK TABLES `session` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `session` ENABLE KEYS */;

--
-- Table structure for table `session_data`
--

DROP TABLE IF EXISTS `session_data`;
CREATE TABLE `session_data` (
  `sid` varchar(32) NOT NULL default '',
  `param` varchar(32) NOT NULL default '',
  `value` varchar(255) default NULL
) TYPE=Heap;

--
-- Dumping data for table `session_data`
--


/*!40000 ALTER TABLE `session_data` DISABLE KEYS */;
LOCK TABLES `session_data` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `session_data` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;

