#!/usr/bin/perl

# auto1.pl (c) 2007 by Archivista GmbH, Urs Pfister
# Script to update scan for kisling, konsolidierung

my $host = "192.168.50.40";
my $db = "archiv";
my $user = "scan";
my $pwd = "****";

use strict;
use DBI;

my $dns = "DBI:mysql:host=$host;database=$db;";
my $dbh = DBI->connect($dns,$user,$pwd);
my @lnr;
if ($dbh) {
  my $sql2 = "select Laufnummer from archiv where ".
	           "Geschaeftsjahr>0 and Unterbereich='Konsolidierung'";
  print "$sql2\n";
  my $prow = $dbh->selectall_arrayref($sql2);
	foreach (@$prow) {
	  push @lnr,$$_[0];
	}

  foreach (@lnr) {
	  my $lnr = $_;
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
		print "$sql1\n";
  	$dbh->do($sql1);
	}
}


