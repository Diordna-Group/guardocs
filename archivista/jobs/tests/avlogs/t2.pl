#!/usr/bin/perl

use lib "/root/class3/";

use strict;
use AVDB;

my $ec = "/home/cvs/archivista/jobs/im/econvert";

my $av = AVDB->new;
my $tstamp0 = time;
my $c;
foreach (</tmp/eins/*>) {
  print $_."\n";
  my $ext = $av->getFileExtension($_,$av->UPPERCASE);
	my $lext = lc($ext);
  my $cmd = `$ec -i $lext:$_ --rotate 180 -o $lext:$_.rot.$ext`; 
  $c++;
}
my $tstamp1 = time;
print "$c Bilder rotiert mit econvert\n".
      "Anfangszeit: $tstamp0 Abschlusszeit: $tstamp1\n";


my $sec = $tstamp1 - $tstamp0;
print "Dauer: $sec Sekunden\n";
