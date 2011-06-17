#!/usr/bin/perl

# (c) 15.11.2006 by Archivista GmbH, Urs Pfister
# does create the new sessions table for Archivista web applications

use strict;

use lib qw(/home/cvs/archivista/jobs);
use AVDB; # use AVDB class for job (sessions table goes to archivista db)
my $recreate = shift; # get optional parameter for recreate table

use constant TABLE_SESSIONS => 'sessions'; # table name
use constant RECREATE => 'recreate'; # command to drop the old table

my $o=AVDB->new();
if ($o->dbState) {
  if ($recreate eq RECREATE) {
	  print "delete the old ".TABLE_SESSIONS." table\n";
    my $sql = "drop table ".TABLE_SESSIONS;
		$o->_setRows($sql);
	}
  if (!$o->setTable(TABLE_SESSIONS)) {
	  print "table ".TABLE_SESSIONS." not available\n";
    my $sql = "create table ".TABLE_SESSIONS." (" .
		          "sid varchar(32) default '' primary key, " .
							"host varchar(60) default 'localhost', " .
							"index hostI (host), " .
							"db varchar(64) default '', " .
							"index dbI (db), " .
							"user varchar(16) default '', " .
							"index userI (user), " .
							"pw varchar(64) default '', " .
							"index pwI (pw), " .
							"vals text default '', " .
							"date timestamp, " .
							"index dateI (date))";
		$o->_setRows($sql);
		if ($o->isError) {
		  print "ERROR ".$o->isError." reported!\n";
		} else {
		  print "table ".TABLE_SESSIONS." created\n";
	  }	
	} else {
	  print "table ".TABLE_SESSIONS." does already exist, " .
		      "Please run '$0 recreate' to recreate it\n";
	}
	$o->close;
}

