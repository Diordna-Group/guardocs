#!/usr/bin/perl

=head1 stopJobs.pl

Stop running jobs and wait some seconds

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my $sec = shift;
$sec=20 if $sec==0;
my $ret=jobStop($sec,"Try to stop all jobs (Shutdown)");
exit 1 if $ret==0;

