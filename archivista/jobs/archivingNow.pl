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

my $dbh=MySQLOpen();
if ($dbh) {
  if (HostIsSlave($dbh)==0) {
    # first, we need all Archivista databases
    my $pdb = getValidDatabases($dbh); 
	  # second, we let the user choose which databases s(he) wants to process
	  my $lang = getLang();
    my $msg_dbs=findit("ARCHIVING_NOW_CHOOSE_DB",$lang);
	  my $psel = chooseXValues($pdb,$msg_dbs);
    for my $db (@$psel) {
	    archivingDatabase($dbh,$db,0);	
	  }
	}
}


