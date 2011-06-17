#!/usr/bin/perl

use strict;
use lib qw(/home/cvs/archivista/jobs);
use CGI;
use AVFieldlists;

my $avw = AVFieldlists->new("Fieldlists","feldlisten",255,,1);
my $pfields = 
  ['Laufnummer','FeldDefinition','Definition','FeldCode','Code','ID'];
$avw->setHeader($pfields);
if($avw->check(1)) { # fieldlists is in all tables, so send a 1
  $avw->getMain();
} else {
  $avw->getLogin();
}
$avw->printHtml();

