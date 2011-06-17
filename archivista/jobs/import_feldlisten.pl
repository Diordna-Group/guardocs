#!/usr/bin/perl

=head1 import_feldlisten.pl

This script imports the table feldlisten with its values
(you first have to export the table feldlisten with the
RichClient) and holds the links between all fields.

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;
my $db = shift;
my $file = shift;

my $dbh=MySQLOpen();
if ($dbh) {
  if (-e $file) {
    open(FIN,"$file");
		my @a=<FIN>;
		close(FIN);
		shift @a;
		foreach(@a) {
		  my @z = split("\t",$_);
			my $sql="insert into $db.feldlisten set ";
			$sql .= "FeldDefinition = " . $dbh->quote($z[0]) . ",";
			$sql .= "Definition = " . $dbh->quote($z[1]) . ",";
			$sql .= "FeldCode = " . $dbh->quote($z[2]) . ",";
			$sql .= "Code = " . $dbh->quote($z[3]) . ",";
			$sql .= "ID = $z[4],";
			$sql .= "Laufnummer = $z[6]";
			print ".";
			$dbh->do($sql);
		}
	}
}
$dbh->disconnect;


