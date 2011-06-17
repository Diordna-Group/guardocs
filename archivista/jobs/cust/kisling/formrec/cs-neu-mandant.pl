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
$txt =~ /^(.*?)(Kontokorrent)(.*?)(734709)(\-)(31)(.*)$/;
if ($4 eq "734709" && $5 eq '-' && $6 eq "31") {
  $txt="100";
} else {
  $txt =~ /^(.*?)(Kontokorrent)(.*?)(590237)(\-)(91)(.*)$/;
  if ($4 eq "590237" && $5 eq '-' && $6 eq "91") {
    $txt="300";
	} else {
    $txt="";
	}
}
print $txt;
