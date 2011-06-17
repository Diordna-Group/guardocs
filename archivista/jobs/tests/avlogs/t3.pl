#!/usr/bin/perl

use lib "/home/cvs/archivista/jobs/";

use AVLogs;

my $av = AVLogs->new();

$av->selectlog(3);

my $pf = [$av->FLD_LOGDONE];
my $pv = [2];
$av->updatelog($pf,$pv);


