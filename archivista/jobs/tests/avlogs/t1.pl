#!/usr/bin/perl

use strict;

use lib "/root/class3/";
use Prima::noX11;
use IPA 'all';
use AVDB;

my $av = AVDB->new;
my $c;
my $tstamp0 = time;
foreach (</tmp/eins/*>) {
my $ext = $av->getFileExtension($_,$av->UPPERCASE);
print "$_\n";
my $x = Prima::Image-> load("$_");
die "$@" unless $x;
my $img = mirror($x,type=>IPA::Geometry::horizontal);
my $name = "$_";
die "$@" unless $img-> save($_."rot.".$ext); 
$c++;
}
my $tstamp1 = time;
print "$c Bilder mit IPA rotiert\nAnfangszeit:". 
       "$tstamp0 Abschlusszeit: $tstamp1\n";

my $sec = $tstamp1 - $tstamp0;
print "Dauer: $sec Sekunden\n";
