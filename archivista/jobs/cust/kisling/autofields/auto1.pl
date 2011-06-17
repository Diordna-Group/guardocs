#!/usr/bin/perl

# auto1.pl (c) 2007 by Archivista GmbH, Urs Pfister
# Script to update scan for kisling, konsolidierung

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
  my $sql = "select MandantNr,Geschaeftsjahr,Buchungsperiode ".
	          "from archiv where Laufnummer=$lnr";
	my $sql1 = "Bereich='Rechnungswesen',".
	           "Unterbereich='Konsolidierung',".
						 "Belegart='Konsol',";
	my @row = $dbh->selectrow_array($sql);
	if ($row[0] == 300) {
		$sql1 .= "Eigentuemer='HHWRW',";
	} elsif ($row[0] == 100) {
		$sql1 .= "Eigentuemer='KISRW',";
	}
	my $gjahr = $row[1];
	my $buch = $row[2];
	if ($gjahr>31) {
	  $gjahr=$gjahr+1900;
		$buch="19$buch";
	} elsif ($gjahr>=0 && $gjahr<=30) {
	  $gjahr=$gjahr+2000;
		$buch="20$buch";
	}
	if ($gjahr>1900) {
	  $sql1 .= "Geschaeftsjahr=$gjahr,Buchungsperiode='$buch'";
	}
	$sql1 = "update $db.archiv set $sql1 where Laufnummer=$lnr";
	$dbh->do($sql1);
}


