#!/usr/bin/perl

=head1 bigint.pl -> give archivseiten, archivbilder and archimg% big key

(c) v1.0 - 19.5.2010 by Archivista GmbH, Urs Pfister

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my $db1 = shift; # check database/folder stucture (0=one table,1-100=x tables)
$db1 = "archivista" if $db1 eq "";

my $dbh;
logit("program started with: $db1");
if ($dbh=MySQLOpen()) { # open database and check for slave
  die if HostIsSlave($dbh);
	my $tb = "";
	my $sql = "show tables like 'archimg%'";
	my @row = $dbh->selectrow_array($sql);
	push @row, "archivseiten";
	push @row, "archivbilder";
	foreach (@row) {
	  my $table = $_;
		$sql = "alter table $db1.$_ modify Seite bigint";
	  logit($sql);
		$dbh->do($sql);
	}
	$dbh->disconnect();
}
logit("program ended with: $db1");




