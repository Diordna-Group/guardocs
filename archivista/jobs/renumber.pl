#!/usr/bin/perl

=head1 renumber.pl -> renumber everything from scratch

(c) v1.0 - 27.5.2010 by Archivista GmbH, Urs Pfister

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my $host = "localhost";
my $db1 = "archivista";
my $user = "root";
my $pwd = "";

if (my $dbh=MySQLOpen($host,$db1,$user,$pwd)) {
  die if HostIsSlave($dbh);
  my $archivfolders=getBlockTableCheck($dbh,"",$db1);
	my $sql = "select count(*) from archiv";
	my @row = $dbh->selectrow_array($sql);
	my $max = $row[0];
	$sql = "select Laufnummer from archiv order by Laufnummer";
	logit($sql);
	my $prow = $dbh->selectall_arrayref($sql);
	my $c=1;
	foreach my $row1 (@$prow) {
    my $c1 = $$row1[0];
		$sql = "update archiv set Akte=$c where Laufnummer=$c1";
		logit($sql);
		$dbh->do($sql);
		$c++;
	}
	for (my $c=1;$c<=$max;$c++) {
	  my $sql = "select Laufnummer,Archiviert,Ordner,Seiten ".
		          "from archiv where Akte = $c";
		logit($sql);
	  my ($lnr,$archiviert,$folder,$seiten) = $dbh->selectrow_array($sql);
		my $table = "archivbilder";
		my $tablego = getBlobTable($dbh,$folder,$archiviert,$table,$archivfolders);
		if ($c != $lnr) {
		  for (my $c1=1;$c1<=$seiten;$c1++) {
			  my $nr = ($c*1000)+$c1;
				my $nr2 = ($lnr*1000)+$c1;
				changeit($dbh,$tablego,$nr,$nr2);
				changeit($dbh,"archivseiten",$nr,$nr2);
			}
			$sql = "update archiv set Laufnummer=$c where Laufnummer=$lnr";
			logit($sql);
			$dbh->do($sql);
		}
  }
}



sub changeit {
  my ($dbh,$table,$nr,$nr2) = @_;
  my $sql = "select Seite from $table where Seite=$nr";
	my @row = $dbh->selectrow_array($sql);
	if ($row[0]>0) {
	  $sql = "delete from $table where Seite=$nr";
		$dbh->do($sql);
	}
	$sql = "update $table set Seite=$nr where Seite=$nr2";
	$dbh->do($sql);
}



sub getBlockTableCheck {
  my ($dbh,$archivfolders,$db1) = @_;
	if ($archivfolders eq "") {
	  $db1 .= "." if $db1 ne "";
    my $sql = "select Inhalt from ".$db1."parameter where Art = " .
           "'parameter' AND Name='ArchivExtended'";
    my @row = $dbh->selectrow_array($sql);
		$archivfolders = $row[0];
	}
	return $archivfolders;
}


