#!/usr/bin/perl

use lib "/home/cvs/archivista/jobs/";

use AVLogs;

my $av = AVLogs->new();

my $pfields = [$av->FLD_LOGDOC,$av->FLD_LOGID,$av->FLD_LOGDB,
							 $av->FLD_LOGUSER,$av-FLD_LOGPWD];
my $pwfield = [$av->FLD_LOGTYPE,$av->SQL_OR,">".$av->FLD_LOGDOC,
							 $av->FLD_LOGDONE,$av->FLD_LOGERROR];
my $pwvals  = ["sne","imp",0,0,0];
my @sel = $av->newselectlog($pfields,$pwfield,$pwvals,$av->TABLE_LOGS);


my $pf = [$av->FLD_LOGDONE];
my $pv = [2];
$av->updatelog($pf,$pv);

print "=@sel=\n";
