#!/usr/bin/perl

=head1 avimpexport.pl, (c) 4.8.2007 by Archivista GmbH, Urs Pfister

Skript does import and export documents from archivista databases
The values are:

$mode, $db, $dir, $range

=cut

use lib qw (/home/cvs/archivista/jobs);
use strict;
use AVJobs;
my $go=1;

my $dbh=MySQLOpen();
if ($dbh) {
  my (@nr,@code,@name,@typ);
  my $sql = "select Laufnummer,PatientenNr,PatientenName,Dokumententyp ".
	          "from archiv order by Laufnummer";
	my $prows = $dbh->selectall_arrayref($sql);
	my $c=0;
	foreach (@$prows) {
	  my $prow1 = $_;
		$nr[$c] = $$prow1[0];
		$code[$c] = $$prow1[1];
		$name[$c] = $$prow1[2];
		$typ[$c] = $$prow1[3];
		$c++;
	}
	my $cnr=-1;
	my $crech=-1;
	my $ckorr=-1;
	$c=0;
	foreach (@nr) {
	  print "current code:$code[$c]---with $cnr-----at pos $c--\n"; 
	  if ($cnr>=0 && $code[$c] != 100000 && $code[$c] != 200000) {
	    $sql = "update archiv set ".
			       "Dokumententyp='Patientenakte' ".
						 "where Laufnummer=".$nr[$cnr];
			goUpdate($dbh,$sql,$go);
			if ($ckorr>0) {
			  $sql = "update archiv set ".
				       "Dokumententyp='Korrespondenz',".
							 "PatientenNr=".$dbh->quote($code[$cnr]).",".
							 "PatientenName=".$dbh->quote($name[$cnr])." ".
							 "where Laufnummer=".$nr[$ckorr];
			  goUpdate($dbh,$sql,$go);
			}
			if ($crech>0) {
			  $sql = "update archiv set ".
				       "Dokumententyp='Rechnungen',".
							 "PatientenNr=".$dbh->quote($code[$cnr]).",".
							 "PatientenName=".$dbh->quote($name[$cnr])." ".
							 "where Laufnummer=".$nr[$crech];
			  goUpdate($dbh,$sql,$go);
			}
			$cnr=-1;
			$ckorr=-1;
			$crech=-1;
		}
	  if ($cnr==-1 && ($code[$c] != 100000 || $code[$c] != 200000)) {
		  print "new number at $c\n";
			$cnr=$c;
		} elsif ($cnr>=0 && $code[$c]==100000) {
		  print "new korrespondenz at $c\n";
		  $ckorr = $c;
		} elsif ($cnr>=0 && $code[$c]==200000) {
		  print "new rechnungen at $c\n";
		  $crech = $c;
		}
		$c++;
	}
}


sub goUpdate {
  my ($dbh,$sql,$go) = @_;
	print "$sql\n";
	if ($go==1) {
    $dbh->do($sql);
	} else {
	  <>;
	}
}
