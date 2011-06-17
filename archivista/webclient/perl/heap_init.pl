#!/usr/bin/perl

# Current revision $Revision: 1.1.1.1 $
# On branch $Name:  $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:13 $

###
# Init Skript fuer die Heap Table, deren eigenen Datenbank und eines eigenen Benutzers
# Commandozeile: perl heap_init.pl [database || heap] 
# Bei Angabe des Parameters database wird die Datenbank neu erstellt
# (nur benutzen wenn diese noch nicht existiert)
# Bei Angabe des Parameters heap wird nur die Heap Tabelle neu erstellt
# 
#
###

use strict;
use DBI;
use inc::Global;

my ($dbh,$sth,$inc,$query,@query);
my $mode = shift;
my $silent = shift;

#open(STDERR,"nul") if ($silent);

my $host = avdb_host();
my $login_uid = avdb_uid();
my $login_pwd = avdb_pwd();
my $new_db = avdb_db();
my $new_table = "sessionweb";
my $port = "3336";

if (length($mode) == 0) {
    print "\nUsage: perl heap_init.pl [database || heap]\n\n";
    print "    [database]: create a new database for heap table\n";
    print "                (only if the database don't exists)\n";
    print "    [heap]:     create a new heap table\n\n";
} else {
    print "Connecting to local database server ... " if (undef $silent);
    my $con="DBI:mysql:host=$host;database=;port=$port";
    $dbh = DBI->connect($con,$login_uid,$login_pwd,
			{PrintError=>0,RaiseError=>0});
    print "done\n" if (undef $silent);

    if ($mode eq "database") {
			print "Creating new database $new_db ... " if (undef $silent);
			$sth = $dbh->prepare("CREATE DATABASE IF NOT EXISTS $new_db");
			$sth->execute();
			print "done\n" if (undef $silent);
    }

    print "Using database $new_db ... " if (undef $silent);
    $sth = $dbh->prepare("USE $new_db");
    $sth->execute();

    if (undef $silent) {
			print "done\n";
			print "Creating new heap table $new_table ... ";
    }

    for ($inc=1; $inc<=50; $inc++) {
			$query = sprintf "%04d", $inc;
			push @query, "s$query int unsigned";
    }

    $query = join ",", @query;

    $sth = $dbh->prepare("CREATE TABLE IF NOT EXISTS $new_table (
												 sid varchar(32),host varchar(64),db varchar(64),
												 uid varchar(16),pwd varchar(128),lang varchar(4),
												 ilimit int,titleField tinyint,titleFieldWidth varchar(4),
												 avstart varchar(255),publishField varchar(255),
												 photoMode tinyint,avform int,alias varchar(255),
												 akte int,seite int,
												 ocr int,modus varchar(10),query varchar(255),
												 degrees int,width varchar(10),height varchar(10),
												 volltext varchar(255),aktenCount int,datum timestamp,
												 selecttype varchar(3),target varchar(50),
												 webinput varchar(255),weboutput varchar(255),
												 searchspeed tinyint,searchmax int(11),
												 statussearch tinyint,exteditaction varchar(50),
												 exteditowner varchar(50),orderby varchar(25),$query) type=heap"); 
		$sth->execute();

    if (undef $silent) {
			print "done\n";
			print "\n";
			print "Please change UID, PWD, DB values for the \n";
			print "$new_db database on inc::Global.pm\n";
    }
    $sth->finish();
    $dbh->disconnect();
}

# Log record
# $Log: heap_init.pl,v $
# Revision 1.1.1.1  2008/11/09 09:21:13  upfister
# Copy to sourceforge
#
# Revision 1.2  2008/03/07 08:43:04  up
# Update to 128 password session table
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.3  2006/11/16 17:16:05  up
# Longer fields for host,db,pwd
#
# Revision 1.2  2005/10/25 17:14:37  ms
# Adding order by attribute feature and between search option for date/integer values
#
# Revision 1.1  2005/07/19 09:26:04  ms
# Initial import for new CVS structure
#
# Revision 1.4  2005/06/02 14:11:04  ms
# ExtEditAction und Owner in avclient heap tabelle speichern
#
# Revision 1.3  2005/05/27 15:46:02  ms
# Neues Passwort Abfrage, Titelfeld, Titelbreite, Photomodus
#
# Revision 1.2  2005/04/15 18:21:53  ms
# Anpassungen open source edition
#
# Revision 1.1.1.1  2005/04/14 09:23:46  ms
# Import projekt
#
# Revision 1.2  2005/04/08 18:19:42  ms
# Entwicklung thumb ansicht im tabellen frame
#
# Revision 1.1.1.1  2005/03/01 16:43:44  ms
# Initial project import
#
# Revision 1.3  2004/08/09 09:25:50  ms
# Erweiterung durch die Funktionalitaet der Suche in der Statuszeile
#
# Revision 1.2  2004/07/28 13:45:43  ms
# Added CVS branch information to the files
#
# Revision 1.1.1.1  2004/07/28 13:31:09  ms
# Initial import of archivista webclient
#
