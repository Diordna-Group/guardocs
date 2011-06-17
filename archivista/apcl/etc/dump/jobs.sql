-- MySQL dump 10.9
--
-- Host: localhost    Database: archivista
-- ------------------------------------------------------
-- Server version	4.1.10-log
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO,MYSQL40' */;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
CREATE TABLE `jobs` (
  `id` int(11) NOT NULL auto_increment,
  `job` enum('SANE') NOT NULL default 'SANE',
  `host` varchar(16) default NULL,
  `db` varchar(16) default NULL,
  `user` varchar(16) default NULL,
  `timemod` timestamp NOT NULL,
  `timeadd` timestamp NOT NULL default '0000-00-00 00:00:00',
  `status` int(11) default NULL,
  `error` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

--
-- Dumping data for table `jobs`
--


/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
LOCK TABLES `jobs` WRITE;
INSERT INTO `jobs` VALUES (3,'SANE','localhost','testdb','SYSOP','2005-06-17 18:12:26','0000-00-00 00:00:00',120,NULL),(4,'SANE','localhost','testdb','SYSOP','2005-06-17 18:18:37','0000-00-00 00:00:00',120,NULL),(5,'SANE','localhost','testdb','SYSOP','2005-06-17 18:20:51','0000-00-00 00:00:00',120,NULL),(6,'SANE','localhost','testdb','SYSOP','2005-06-17 18:25:05','0000-00-00 00:00:00',120,NULL),(7,'SANE','localhost','testdb','SYSOP','2005-06-17 19:37:38','0000-00-00 00:00:00',120,NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;

