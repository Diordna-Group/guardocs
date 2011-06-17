#!/usr/bin/perl

# Script to extract UserName (short version) and title of the
# PDF file according the extracted information from a pdfinfo
# (c) v0.1 9.11.2006 by Archivista GmbH, Urs Pfister

my $db = shift; # database name (you can change it)
my $title = shift; # title of the document (goes to Titel)
my $pdffile = shift; # pdf file name (for own work)
my $psfile = shift; # ps file name (for own work)
my $for = shift; # author of the document (goes to Eigentuemer)

if (length($title)>120) {
  $title = substring($title,0,119);
}
$title =~ s/Microsoft Word - //g;
$title =~ s/Microsoft Office //g;
$title =~ s/;/ /g;
$title =~ s/:/ /g;
$title =~ s/=/ /g;

# to give values back you need to print it
# at first position you need to include the db name, followed by a ;
# after its you need to add the field=value, separated with a :
$title = quoteit($title); # remove special chars in title field  
my $ret = "$db;Titel=$title:Eigentuemer=$for";
print $ret;


# unquote the special chars \344 => ä in cups spool files
sub quoteit {
  my $a = shift;
  my $do=1;
  while ($do==1) {
	  # do it as long it is needed
	  my $aold = $a; # make a copy
    $a =~ s/^(.*?)(\\)([0-7]{3,3})(.*)$/$1$3$4/; # search first one
	  if ($2 eq "\\" && $a ne $aold) { # if \ found and we got a new hit
      my $a1 = $1; # everything bevore
      my $a2 = chr(oct($3)); # convert char
      my $a3 = $4; # everything behind
      $a = "$a1$a2$a3"; # compose new string
	  } else {
	    $do=0; # no hit, so exit
	  }
	}
	return $a; # give back the converted string
}



