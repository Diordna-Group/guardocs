#!/usr/bin/perl

use lib "/home/cvs/archivista/jobs";

use strict;
use AVDocs;

my $host = "localhost";
my $database = "testumgebung";
my $av = AVDocs->new();

$av->setDatabase($database);
$av->deleteAll($av->TABLE_DOCS);

my (@ftp,@sne);

my $pfields = ["Auftraggeber","Auftrag","syncthis1","syncthis2"];
my $pvals = ["meier","m01","meierstrasse","meierort"];
my $ok = $av->add($pfields,$pvals);
push @ftp, $ok;
print $ok."\n";

my $pfields = ["Auftraggeber","Auftrag","syncthis1","syncthis2"];
my $pvals = ["meier","m01","meierstrasseneu","meierort"];
my $ok = $av->add($pfields,$pvals);
push @ftp, $ok;
print $ok."\n";



my $pfields = ["Auftraggeber","Auftrag"];
my $pvals = ["egli","e01"];
my $ok = $av->add($pfields,$pvals);
push @sne, $ok;
print $ok."\n";

my $pfields = ["Auftraggeber","Auftrag","syncthis1","syncthis2"];
my $pvals = ["egli","e01","eglistrasse","egliort"];
my $ok = $av->add($pfields,$pvals);
push @ftp, $ok;
print $ok."\n";

my $pfields = ["Auftraggeber"];
my $pvals = ["egli"];
my $ok = $av->add($pfields,$pvals);
push @sne, $ok;
print $ok."\n";

my $pfields = ["Auftrag"];
my $pvals = ["m01"];
my $ok = $av->add($pfields,$pvals);
push @sne, $ok;
print $ok."\n";





#LOGS EINTRAEGE!
$av->setDatabase("archivista");
$av->setTable($av->TABLE_LOGS);
$av->deleteAll($av->TABLE_LOGS);
my $pfields = [$av->FLD_LOGTYPE,$av->FLD_LOGHOST,$av->FLD_LOGDB,$av->FLD_LOGDOC];
my $c;
foreach (@ftp) {
  my $pvals = ["ftp",$host,$database,$ftp[$c]];
	$av->add($pfields,$pvals);
	$c++;
}

my $pfields = [$av->FLD_LOGTYPE,$av->FLD_LOGHOST,$av->FLD_LOGDB,$av->FLD_LOGDOC];
my $d;
foreach (@sne) {
  my $pvals = ["sne",$host,$database,$sne[$d]];
	$av->add($pfields,$pvals);
	$d++
}

$av->close;

