#!/usr/bin/perl

use strict;
use AVLogs;

#my $testlog="a;b;c;d;e;f;g;h;i;j;kafjdla;akfjdlökfjd;alkdjf";

my $lognr;
my $av = AVLogs->new();

my $pf = ["papersize","DONE","type"];
my $pv = ["A4","3","pdf"];
my $ret=$av->addlog($pf,$pv) && print "added log\n";
print "$ret\n";

die;




for ($lognr=0;$lognr<=10;$lognr++){
  my @select = $av->selectlog($lognr);
	my $pfield = ["papersize","DONE","type"];
	my $pval = ["A4","3","pdf"];
  my $ok = $av->updatelog($pfield,$pval); 
	print "=====$ok====\n"



  #foreach (@select) {
  #  print $_."\n";
  #}
}

my $pf = ["papersize"];
my $pv = ["A34"];
$av->addlog($pf,$pv) && print "added log\n";
#$av->deletelog($pf,$pv) && print "deleted log\n";

my $pfields = ["papersize","DONE","type"];
my $pvals = ["A4","3","pdf"];

my $ok = $av->update($pfields,$pvals);
print "=====$ok\n";
