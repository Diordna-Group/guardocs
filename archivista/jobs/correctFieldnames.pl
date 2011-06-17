#!/usr/bin/perl

=head1 correctfieldnames.pl

Correct Umlauts from a mysql 4.0 database to 4.x (without umlauts)
Please call this program before conversion to 200904.. (and higher)

=cut

use lib "/home/cvs/archivista/jobs";
use strict;
use AVJobs;
my @from = ("Grundstück");
my @to = ("Grundstueck");
my @opt = ("varchar(60)");
my @fromI = ("GrundstückI");
my @toI = ("GrundstueckI");

my $dbh = MySQLOpen("localhost","archivaudit","root","archivista");
if ($dbh) {
  if (HostIsSlave($dbh)==0) {
	  my $c=0;
	  foreach (@from) {
		  my $fldfrom = $from[$c];
			my $fldto = $to[$c];
			my $fldopt = $opt[$c];
	    my $sql = "alter table archiv change $from[$c] $to[$c] $opt[$c]";
			$dbh->do($sql);
			if ($fromI[$c] ne "") {
			  $sql = "alter table archiv drop index $fromI[$c]";
				$dbh->do($sql);
			}
			if ($toI[$c] ne "") {
			  $sql = "alter table archiv add index $toI[$c] ($to[$c])";
				$dbh->do($sql);
			}
			$sql = "select Laufnummer,Inhalt from parameter ".
			       "where Name like 'Felder%' and Art like 'Felder%' and ".
						 "Tabelle = 'archiv'";
			my $up1 = "update parameter set Inhalt=";
			my $up2 = "where Laufnummer=";
			changeit($dbh,$sql,$from[$c],$to[$c],$up1,$up2);
			$sql = "select Laufnummer,FeldDefinition from feldlisten ".
			       "where FeldDefinition=".$dbh->quote($from[$c]);
			$up1 = "update feldlisten set FeldDefinition=";
			changeit($dbh,$sql,$from[$c],$to[$c],$up1,$up2);
			$sql = "select Laufnummer,FeldCode from feldlisten ".
			       "where FeldCode=".$dbh->quote($from[$c]);
			$up1 = "update feldlisten set FeldCode=";
			changeit($dbh,$sql,$from[$c],$to[$c],$up1,$up2);
			$c++;
		}
	}
	$dbh->disconnect();
}



sub changeit {
  my ($dbh,$sql,$from,$to,$up1,$up2) = @_;
	my $prow = $dbh->selectall_arrayref($sql);
	foreach (@$prow) {
	  my $lnr = $$_[0];
		my $val = $$_[1];
		$val =~ s/($from)/$to/g;
		$sql = $up1.$dbh->quote($val)." ".$up2.$lnr;
		$dbh->do($sql);
	}
}


