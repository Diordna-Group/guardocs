#!/usr/bin/perl

use strict;
use lib qw(/home/cvs/archivista/jobs);
use CGI;
use AVLanguages;

my $avw = AVLanguages->new("Languages","languages",255);
my $pfields = ['id','de','en','fr','it'];
$avw->setHeader($pfields);
if($avw->check) {
  $avw->getMain();
} else {
  $avw->getLogin();
}
$avw->printHtml();

