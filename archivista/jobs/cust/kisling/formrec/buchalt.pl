#!/usr/bin/perl

use strict;

my $file = shift;
open(FIN,$file);
binmode(FIN);
my @lines = <FIN>;
close(FIN);
my $txt = join("",@lines);
$txt =~ s/\r/ /g; # replace all return with space
$txt =~ s/\n/ /g; # " all newlines 
$txt =~ s/\t/ /g; # " all tabs
$txt =~ s/\s\././g; # " space and point goes to point
$txt =~ s/\.\s/./g; # " point and space goes to point
$txt =~ s/\s{2,2}/ /g; # replace two 2 spaces with 1
$txt =~ /^(.*)([0-9]{2,2})(\.)([0-9]{2,2})(\.)([0-9]{2,2})(.*)$/;
if ($2 ne "" && $4 ne "" && $6 ne "") {
  $txt="20$6$4";
} else {
  $txt="";
}
print $txt;
