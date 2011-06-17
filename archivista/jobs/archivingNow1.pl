#!/usr/bin/perl

=head1 archivingNow.pl

This script shows all valid databases for archiving on localhost
and for user root. After selecting the desired databases the
archiving process will be started.

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my $db = shift;
if ($db eq "") {
  print "Usage: $0 database\n";
	die;
}

my $dbh=MySQLOpen();
if ($dbh) {
  if (HostIsSlave($dbh)==0) {
    # first, we need all Archivista databases
	  archivingDatabase1($dbh,$db,0);	
	}
}


