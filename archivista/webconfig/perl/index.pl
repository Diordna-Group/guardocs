#!/usr/bin/perl

=head1 webconfig.pl (c) 2008 by Archivista GmbH, Urs Pfister

Program to configure the ArchivistaBox over the web

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs);

my $vers = 32;
my $linux = `cat /proc/version`;
$vers=64 if $linux =~ /Debian/;
my $avwc = "";
if ($vers==64) {
  use AVWebConf64; # load 64bit version
  $avwc = AVWebConf64->new("WebConfig"); # get object
} else {
  use AVWebConfig; # load 32bit version
  $avwc = AVWebConfig->new("WebConfig"); # get object
}
if($avwc->doAction) { # check if we are logged in
  $avwc->getMain(); # show the appropriate form
} else {
  $avwc->getLogin(); # show login form
}


