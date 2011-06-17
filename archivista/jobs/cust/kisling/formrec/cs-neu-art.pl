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
$txt =~ /^(.*?)(Postenauszug)(.*)$/;
if ($2 eq "Postenauszug") {
  $txt="Posten";
} else {
  $txt =~ /^(.*?)(Kontoauszug)(.*)$/;
  if ($2 eq "Kontoauszug") {
    $txt="Konto";
  } else {
    $txt =~ /^(.*?)(Tagesauszug)(.*)$/;
    if ($2 eq "Tagesauszug") {
		  $txt="Tages";
	  } else {
      $txt="";
	  }
	}
}
print $txt;
