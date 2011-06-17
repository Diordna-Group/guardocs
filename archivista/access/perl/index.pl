#!/usr/bin/perl

use strict;
use lib qw(/home/cvs/archivista/jobs);
use CGI;
use AVWeb;
my $avw = AVWeb->new("AccessLog","access",255,"-");
my $prow = ['id','host','db','user','document','action',
            'additional','moddate','checkstate'];
$avw->setHeader($prow);
$avw->noedit(1); # Don't let the user edit the acces table
if($avw->check) {
  $avw->getMain();
} else {
  $avw->getLogin();
}
$avw->printHtml();

