-- MySQL dump 10.9
--
-- Host: localhost    Database: archivista
-- ------------------------------------------------------
-- Server version	4.1.10-log
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO,MYSQL40' */;

--
-- Table structure for table `application_menu`
--

DROP TABLE IF EXISTS `application_menu`;
CREATE TABLE `application_menu` (
  `id` int(11) NOT NULL auto_increment,
  `languagesId` varchar(32) NOT NULL default '',
  `level` varchar(32) default NULL,
  `link` varchar(255) default NULL,
  `applicationId` varchar(32) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

--
-- Dumping data for table `application_menu`
--


/*!40000 ALTER TABLE `application_menu` DISABLE KEYS */;
LOCK TABLES `application_menu` WRITE;
INSERT INTO `application_menu` VALUES (1,'USER','001','ua=1','WebAdmin'),(3,'FIELDS','002.001','fd=1','WebAdmin'),(4,'MASKS','002.002','md=1','WebAdmin'),(5,'FIELDS_AND_MASKS','002','fd=1','WebAdmin'),(6,'ARCHIVE_ADMINISTRATION','003','da=1','WebAdmin'),(7,'SCANNING','004','sa=1','WebAdmin'),(8,'BARCODE_RECOGNITION','005.001','bs=1','WebAdmin'),(9,'BARCODE_PROCESSING','005.002','bp=1','WebAdmin'),(10,'BARCODES','005','bs=1','WebAdmin'),(15,'DATABASE_CREATION','006','logout=1&admdb=1','WebAdmin'),(16,'LOGOUT','007','logout=1','WebAdmin');
UNLOCK TABLES;
/*!40000 ALTER TABLE `application_menu` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;

