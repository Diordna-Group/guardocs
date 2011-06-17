-- MySQL dump 9.11
--
-- Host: localhost    Database: archivista
-- ------------------------------------------------------
-- Server version	4.0.24-log

--
-- Table structure for table `application_menu`
--

use archivista;
delete from application_menu;

INSERT INTO application_menu VALUES (1,'USER','001','ua=1','WebAdmin');
INSERT INTO application_menu VALUES (3,'FIELDS','002.001','fd=1','WebAdmin');
INSERT INTO application_menu VALUES (4,'MASKS','002.002','md=1','WebAdmin');
INSERT INTO application_menu VALUES (5,'FIELDS_AND_MASKS','002','fd=1','WebAdmin');
INSERT INTO application_menu VALUES (6,'ARCHIVE_ADMINISTRATION','003','da=1','WebAdmin');
INSERT INTO application_menu VALUES (7,'SCANNING','004','sa=1','WebAdmin');
INSERT INTO application_menu VALUES (8,'BARCODE_RECOGNITION','005.001','bs=1','WebAdmin');
INSERT INTO application_menu VALUES (9,'BARCODE_PROCESSING','005.002','bp=1','WebAdmin');
INSERT INTO application_menu VALUES (10,'BARCODES','005','bs=1','WebAdmin');
INSERT INTO application_menu VALUES (11,'OCRDEFINITIONS','007','ld=1','WebAdmin');
INSERT INTO application_menu VALUES (15,'DATABASE_CREATION','012','logout=1&admdb=1','WebAdmin');
INSERT INTO application_menu VALUES (16,'LOGOUT','013','logout=1','WebAdmin');
INSERT INTO application_menu VALUES (12,'SQLDEFINITIONS','008','sq=1','WebAdmin');
INSERT INTO application_menu VALUES (17,'FORM_RECOGNITION','006','fr=1','Webadmin');
INSERT INTO application_menu VALUES (18,'LOGO_RECOGNITION','006.001','lr=1','WebAdmin');
INSERT INTO application_menu VALUES (19,'USER_EXTERN','001.001','ue=1','WebAdmin');
INSERT INTO application_menu VALUES (20,'USER_GROUPS','001.001','ug=1','WebAdmin');
INSERT INTO application_menu VALUES (22,'EXPORT_DOCS','009','ed=1','WebAdmin');
INSERT INTO application_menu VALUES (23,'MAILS','010','ml=1','WebAdmin');
INSERT INTO application_menu VALUES (24,'OCRLIMIT','007.001','oc=1','WebAdmin');
INSERT INTO application_menu VALUES (25,'JOBADMIN','011','ja=1','WebAdmin');

