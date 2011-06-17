#!/usr/bin/perl

=head1 splitTableImages.pl -> split archivbilder in archivexxxxx

(c) v1.0 - 2.8.2008 by Archivista GmbH, Urs Pfister

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;
use locale;
use Encode;

my $file = shift; # give in file name
my $db1 = shift; # check database/folder stucture (0=one table,1-100=x tables)
$db1 = "archivista" if $db1 eq "";
$file = "import.txt" if $file eq "";
my $dbh;
my $sql;
logit("program started with $db1 and file $file");
my $cont = "";
readFile($file,\$cont);
if ($dbh=MySQLOpen()) { # open database and check for slave
  die if HostIsSlave($dbh);
	my @lines = split("\n",$cont);
	foreach my $line (@lines) {
    my $line1 = Encode::encode_utf8($line);
		$line1 = $line;
		logit($line1);
		my ($t1,$t2,$t3,$t4) = split(/\t/,$line1);
    my $nr2 = insert_entry($dbh,$db1,"T1",$t1);
		if ($nr2>0) {
      my $nr3 = insert_entry($dbh,$db1,"T2",$t2,$nr2);
		  if ($nr3>0) {
        my $nr4 = insert_entry($dbh,$db1,"T3",$t3,$nr3);
			  if ($nr4>0) {
          my $nr5 = insert_entry($dbh,$db1,"T4",$t4,$nr4);
			  }
			}
		}
	}
	logit("program ended with $db1 and action $file"); 
}





sub insert_entry {
  my ($dbh,$db1,$fld,$t2,$nr) = @_;
	if ($t2 ne "") {
	  $sql = "select Definition,Laufnummer from $db1.feldlisten ".
		       "where FeldDefinition='$fld' and Definition=".$dbh->quote($t2);
		$sql .= " and ID=$nr" if $nr>0;
		my @res = $dbh->selectrow_array($sql);
		if ($res[0] eq $t2 and $res[1]>0) {
		  logit("$fld => $t2 already available");
			$nr = $res[1];
		} else {
		  logit("$fld => $t2 added");
		  $sql = "insert into $db1.feldlisten set FeldDefinition='$fld',".
			       "Definition=".$dbh->quote($t2);
			$sql .= ",ID=$nr" if $nr>0;
			$dbh->do($sql);
		  my @res = $dbh->selectrow_array("select last_insert_id()");
			$nr = $res[0];
    }
	}
	return $nr;
}


