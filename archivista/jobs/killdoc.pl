#!/usr/bin/perl

use strict;
use DBI;

print "Killdoc (c) 2007 by Archivista GmbH, Urs Pfister\n";
print "Program does kill all documents from the logs table\n";
print "Please confirm with code 2504\n";
my $ant=<>;
chomp $ant;
die if $ant != 2504;

my $ds = "DBI:mysql:host=192.168.50.40:database=archiv";
my $dbh = DBI->connect($ds,"Admin1","effi1");

my $ds2 = "DBI:mysql:host=localhost:database=archivista";
my $dbh2 = DBI->connect($ds2,"root","effi1");

my $sql = "select Laufnummer,pages from logs";
my $prows = $dbh2->selectall_arrayref($sql);

foreach (@$prows) {
  my $pr = $_;
  my $doc = @$pr[0];
	my $pages = @$pr[1];
	for (my $pag=1;$pag<=$pages;$pag++) {
	  my $bildpage = ($doc*1000)+$pag;
		my $sql = "delete from archivbilder where Seite=$bildpage";
		print "$sql\n";
		$dbh->do($sql);
		$sql = "delete from archivseiten where Seite=$bildpage";
		$dbh->do($sql);
		$sql = "delete from archiv where Laufnummer=$doc";
		$dbh->do($sql);
	  print "$doc--$pag--$pages\n";
	}
}



