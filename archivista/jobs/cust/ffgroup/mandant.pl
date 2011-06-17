#!/usr/bin/perl

# auto1.pl (c) 2011 by Archivista GmbH, Urs Pfister
# Script to update mandants from title field

my $host = shift;
my $db = shift;
my $user = shift;
my $pwd = shift;
my $lnr = shift;

use strict;
use DBI;

my $dns = "DBI:mysql:host=$host;database=$db;";
my $dbh = DBI->connect($dns,$user,$pwd);
if ($dbh) {
  my $sql = "select Titel from archiv where Laufnummer=$lnr";
	my @row = $dbh->selectrow_array($sql);
	if ($row[0] ne "") {
	  my $line = $row[0];
		my $lang = length($line);
		if ($lang>3) {
		  my $mandant = substr($line,0,3);
		  $mandant = "0".$mandant;
			$sql = "update archiv set Mandant=".$dbh->quote($mandant)." ".
			       "where Laufnummer=$lnr";
			$dbh->do($sql);
		}
	}
}


