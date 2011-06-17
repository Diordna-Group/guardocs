#!/usr/bin/perl

use lib "/home/cvs/archivista/jobs/";
use AVLogs;

my $av = AVLogs->new;

my $pf = ["Laufnummer","db","DONE","ERROR","pages","type"];
my $pv = [999,"testdb",0,0,888,"erp"];

#my $pf = ["papersize"];
#my $pv = ["test"];
my $ok = $av->add($pf,$pv,"logs");
print "$ok\n";
