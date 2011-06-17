#!/usr/bin/perl

=head1 archivingAll.pl

Archives all valid databases on localhost with user root.

=cut

use lib "/home/cvs/archivista/jobs";
use strict;
use AVJobs;

my $dbh = MySQLOpen();
if ($dbh) {
  if (HostIsSlave($dbh)==0) {
    my $pdatabases = getValidDatabases($dbh);
	  foreach (@$pdatabases) {
	    archivingDatabase($dbh,$_,0);
	  }
	}
	$dbh->disconnect();
}

