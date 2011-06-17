-- MySQL dump 9.11
--
-- Host: localhost    Database: archivista
-- ------------------------------------------------------
-- Server version	4.0.24

--
-- Table structure for table `abkuerzungen`
--

CREATE TABLE abkuerzungen (
  Code varchar(10) NOT NULL default '',
  Definition varchar(50) NOT NULL default '',
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  PRIMARY KEY  (Laufnummer),
  KEY CodeI (Code),
  KEY DefinitionI (Definition),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

--
-- Table structure for table `adressen`
--

CREATE TABLE adressen (
  Anrede varchar(10) NOT NULL default '',
  Vorname varchar(24) NOT NULL default '',
  Nachname varchar(24) NOT NULL default '',
  Zusatzzeile varchar(40) NOT NULL default '',
  Strasse varchar(40) NOT NULL default '',
  Landcode varchar(10) NOT NULL default '',
  PLZ varchar(10) NOT NULL default '',
  Ort varchar(50) NOT NULL default '',
  Land varchar(24) NOT NULL default '',
  Telefon varchar(25) NOT NULL default '',
  Geschäft varchar(25) NOT NULL default '',
  Telefax varchar(25) NOT NULL default '',
  Zusatz varchar(25) NOT NULL default '',
  Internet varchar(50) NOT NULL default '',
  Geburtsdatum datetime default NULL,
  Status varchar(10) NOT NULL default '',
  Temporär varchar(5) NOT NULL default '',
  Briefanrede varchar(44) NOT NULL default '',
  Bemerkungen text,
  Aufnahme datetime NOT NULL default '0000-00-00 00:00:00',
  Eigentuemer varchar(16) NOT NULL default '',
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  Verbindungen blob,
  BemerkungenRTF blob,
  UserModName varchar(16) NOT NULL default '',
  UserModDatum timestamp(14) NOT NULL,
  UserNeuName varchar(16) NOT NULL default '',
  UserNeuDatum timestamp(14) NOT NULL default '00000000000000',
  PRIMARY KEY  (Laufnummer),
  KEY VornameI (Vorname),
  KEY NchnameI (Nachname),
  KEY ZusatzzeileI (Zusatzzeile),
  KEY PLZI (PLZ),
  KEY OrtI (Ort),
  KEY EigentuemerI (Eigentuemer),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

--
-- Table structure for table `adressenplz`
--

CREATE TABLE adressenplz (
  Land varchar(5) NOT NULL default '',
  PLZ varchar(10) NOT NULL default '',
  Ort varchar(50) NOT NULL default '',
  Gebiet varchar(10) default '',
  Markiert tinyint(4) default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  PRIMARY KEY  (Laufnummer),
  KEY LandI (Land),
  KEY PLZI (PLZ),
  KEY OrtI (Ort),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

--
-- Table structure for table `archiv`
--

CREATE TABLE archiv (
  Titel varchar(128) NOT NULL default '',
  Datum datetime NOT NULL default '0000-00-00 00:00:00',
  Akte int(11) default NULL,
  Seiten int(11) NOT NULL default '0',
  Persons varchar(60) default NULL,
  Keywords varchar(60) default NULL,
  Notiz text,
  ErfasstDatum datetime default '0000-00-00 00:00:00',
  Ordner int(11) NOT NULL default '1',
  Farbe tinyint(4) NOT NULL default '0',
  Original tinyint(4) NOT NULL default '0',
  EDVName varchar(128) NOT NULL default '',
  Erfasst tinyint(4) NOT NULL default '0',
  Archiviert tinyint(4) NOT NULL default '0',
  Eigentuemer varchar(16) NOT NULL default '',
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  Verbindungen blob,
  NotizRTF blob,
  Gesperrt varchar(16) NOT NULL default '',
  ArchivArt int(11) NOT NULL default '0',
  BildInput tinyint(4) NOT NULL default '0',
  BildIntern tinyint(4) NOT NULL default '0',
  BildGetSeite int(11) NOT NULL default '0',
  QuelleIntern tinyint(4) NOT NULL default '0',
  BildInputExt varchar(4) NOT NULL default '',
  BildAExt varchar(4) NOT NULL default '',
  QuelleExt varchar(4) NOT NULL default '',
  UserModName varchar(16) NOT NULL default '',
  UserModDatum timestamp(14) NOT NULL,
  UserNeuName varchar(16) NOT NULL default '',
  UserNeuDatum timestamp(14) NOT NULL default '00000000000000',
  PRIMARY KEY  (Laufnummer),
  KEY TitelI (Titel),
  KEY DatumI (Datum),
  KEY AkteI (Akte),
  KEY SeitenI (Seiten),
  KEY ErfasstDatumI (ErfasstDatum),
  KEY OrdnerI (Ordner),
  KEY ErfasstI (Erfasst),
  KEY ArchiviertI (Archiviert),
  KEY EigentuemerI (Eigentuemer),
  KEY MarkiertI (Markiert),
  KEY LaufnummerI (Laufnummer),
  KEY GesperrtI (Gesperrt),
  KEY ArchivArtI (ArchivArt)
) TYPE=MyISAM;

--
-- Table structure for table `archivbilder`
--

CREATE TABLE archivbilder (
  Seite bigint NOT NULL default '0',
  Bild mediumblob,
  BildA mediumblob,
  BildInput longblob,
  Quelle longblob,
  BildX int(11) NOT NULL default '0',
  BildY int(11) NOT NULL default '0',
  BildAX int(11) NOT NULL default '0',
  BildAY int(11) NOT NULL default '0',
  DatumA datetime default NULL,
  PRIMARY KEY  (Seite),
  KEY SeiteI (Seite)
) TYPE=MyISAM MAX_ROWS=10000000 AVG_ROW_LENGTH=20000;

--
-- Table structure for table `archivseiten`
--

CREATE TABLE archivseiten (
  Seite bigint NOT NULL default '0',
  Ausschliessen tinyint(4) NOT NULL default '0',
  Erfasst tinyint(4) NOT NULL default '0',
  Schlüssel varchar(56) NOT NULL default '',
  Text mediumtext,
  Zipped tinyint(4) NOT NULL default '0',
  Indexiert tinyint(4) NOT NULL default '0',
  OCR int(11) NOT NULL default '0',
  Notes blob,
  ScreenQuality int(11) NOT NULL default '0',
  PRIMARY KEY  (Seite),
  KEY SeiteI (Seite),
  KEY AusschliessenI (Ausschliessen),
  KEY ErfasstI (Erfasst),
  KEY IndexiertI (Indexiert),
  FULLTEXT KEY TextI (Text)
) TYPE=MyISAM;

--
-- Table structure for table `feldlisten`
--

CREATE TABLE feldlisten (
  FeldDefinition varchar(64) NOT NULL default '',
  Definition varchar(64) NOT NULL default '',
  FeldCode varchar(64) NOT NULL default '',
  Code varchar(12) NOT NULL default '',
  ID int(11) NOT NULL default '0',
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  PRIMARY KEY  (Laufnummer),
  KEY FeldDefinitionI (FeldDefinition),
  KEY DefinitionI (Definition),
  KEY FeldCodeI (FeldCode),
  KEY CodeI (Code),
  KEY IDI (ID)
) TYPE=MyISAM;


--
-- Table structure for table `literatur`
--

CREATE TABLE literatur (
  Rubrik varchar(50) NOT NULL default '',
  Code varchar(10) NOT NULL default '',
  Titel varchar(70) NOT NULL default '',
  Untertitel varchar(70) NOT NULL default '',
  Autoren varchar(70) NOT NULL default '',
  Verlag varchar(70) NOT NULL default '',
  Auflage varchar(20) NOT NULL default '',
  Sprache varchar(20) NOT NULL default '',
  AnzahlSeiten int(11) NOT NULL default '0',
  Ausgabejahr int(11) NOT NULL default '0',
  ISBNNummer varchar(30) default '',
  Stichwörter varchar(100) NOT NULL default '',
  Notiz blob,
  DatumKauf datetime NOT NULL default '0000-00-00 00:00:00',
  Preis double NOT NULL default '0',
  Eigentuemer varchar(16) NOT NULL default '',
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  Verbindungen blob,
  NotizRTF blob,
  UserModName varchar(16) NOT NULL default '',
  UserModDatum timestamp(14) NOT NULL,
  UserNeuName varchar(16) NOT NULL default '',
  UserNeuDatum timestamp(14) NOT NULL default '00000000000000',
  PRIMARY KEY  (Laufnummer),
  KEY RubrikI (Rubrik),
  KEY CodeI (Code),
  KEY TitelI (Titel),
  KEY UntertitelI (Untertitel),
  KEY AutorenI (Autoren),
  KEY VerlagI (Verlag),
  KEY AnzahlSeitenI (AnzahlSeiten),
  KEY AusgabejahrI (Ausgabejahr),
  KEY StichwörterI (Stichwörter),
  KEY DatumKaufI (DatumKauf),
  KEY PreisI (Preis),
  KEY EigentuemerI (Eigentuemer),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

--
-- Table structure for table `literaturrubrik`
--

CREATE TABLE literaturrubrik (
  Code varchar(10) NOT NULL default '',
  Rubrik varchar(50) NOT NULL default '',
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  PRIMARY KEY  (Laufnummer),
  KEY CodeI (Code),
  KEY RubrikI (Rubrik),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

--
-- Table structure for table `logs`
--

CREATE TABLE logs (
  file varchar(250) default '',
  path varchar(250) default '',
  type char(3) default 'pdf',
  date varchar(250) default '',
  db varchar(64) default '',
  owner varchar(16) default '',
  papersize varchar(10) default 'A4',
  pages int(11) default '0',
  width int(11) default '0',
  height int(11) default '0',
  resx int(11) default '300',
  resy int(11) default '300',
  bits int(11) default '1',
  format int(11) default '1',
  Laufnummer int(11) default '0',
  TIME timestamp(14) NOT NULL,
  DONE int(11) default '0',
  ERROR int(11) default '0',
  ID int(11) NOT NULL auto_increment,
  PRIMARY KEY  (ID)
) TYPE=MyISAM;

--
-- Table structure for table `notizen`
--

CREATE TABLE notizen (
  DatumVon datetime NOT NULL default '0000-00-00 00:00:00',
  PendentAb datetime NOT NULL default '0000-00-00 00:00:00',
  Erledigt tinyint(4) NOT NULL default '0',
  Betrifft varchar(50) NOT NULL default '',
  Stichwörter varchar(50) NOT NULL default '',
  Notiz text,
  Eigentuemer varchar(16) NOT NULL default '',
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  Verbindungen blob,
  NotizRTF blob,
  UserModName varchar(16) NOT NULL default '',
  UserModDatum timestamp(14) NOT NULL,
  UserNeuName varchar(16) NOT NULL default '',
  UserNeuDatum timestamp(14) NOT NULL default '00000000000000',
  PRIMARY KEY  (Laufnummer),
  KEY DatumVonI (DatumVon),
  KEY PendentAbI (PendentAb),
  KEY BetrifftI (Betrifft),
  KEY StichwörterI (Stichwörter),
  KEY EigentuemerI (Eigentuemer),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

--
-- Table structure for table `parameter`
--

CREATE TABLE parameter (
  Art varchar(50) NOT NULL default '',
  Tabelle varchar(50) NOT NULL default '',
  Name varchar(50) NOT NULL default '',
  Beschreibung varchar(128) NOT NULL default '',
  User text NOT NULL,
  Inhalt text,
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  PRIMARY KEY  (Laufnummer),
  KEY ArtI (Art),
  KEY TabelleI (Tabelle),
  KEY NameI (Name),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

--
-- Table structure for table `user`
--

CREATE TABLE user (
  User varchar(16) NOT NULL default '',
  Host varchar(60) NOT NULL default '',
  Alias varchar(250) NOT NULL default '',
  Anzahl int(11) NOT NULL default '50',
  Suchtreffer int(11) NOT NULL default '30',
  PWArt int(11) NOT NULL default '0',
  PWEncrypted tinyint(4) NOT NULL default '0',
  Level int(11) NOT NULL default '0',
  Masseinheit int(11) NOT NULL default '3',
  Korrektur int(11) NOT NULL default '2880',
  ZugriffIntern int(11) NOT NULL default '0',
  ZugriffWeb int(11) NOT NULL default '0',
  AddOn int(11) NOT NULL default '0',
  AddNew varchar(16) NOT NULL default '',
  Workflow int(11) NOT NULL default '0',
  AVStart int(11) NOT NULL default '0',
  AVForm int(11) NOT NULL default '0',
  EMail varchar(120) NOT NULL default '',
  Zusatz varchar(120) NOT NULL default '',
  Bemerkungen text,
  Laufnummer int(11) NOT NULL auto_increment,
  PRIMARY KEY  (Laufnummer),
  KEY UserI (User),
  KEY HostI (Host),
  KEY AliasI (Alias),
  KEY AnzahlI (Anzahl),
  KEY SuchtrefferI (Suchtreffer),
  KEY PWArtI (PWArt),
  KEY LevelI (Level),
  KEY MasseinheitI (Masseinheit),
  KEY KorrekturI (Korrektur),
  KEY ZugriffInternI (ZugriffIntern),
  KEY ZugriffWebI (ZugriffWeb),
  KEY AddOnI (AddOn),
  KEY AddNewI (AddNew),
  KEY WorkflowI (Workflow),
  KEY EMailI (EMail),
  KEY ZusatzI (Zusatz),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

--
-- Table structure for table `workflow`
--

CREATE TABLE workflow (
  Art varchar(50) NOT NULL default '',
  Tabelle varchar(50) NOT NULL default '',
  Name varchar(50) NOT NULL default '',
  Volltext varchar(128) NOT NULL default '',
  User text NOT NULL,
  Inhalt text,
  Markiert tinyint(4) NOT NULL default '0',
  Laufnummer int(11) NOT NULL auto_increment,
  PRIMARY KEY  (Laufnummer),
  KEY ArtI (Art),
  KEY TabelleI (Tabelle),
  KEY NameI (Name),
  KEY LaufnummerI (Laufnummer)
) TYPE=MyISAM;

