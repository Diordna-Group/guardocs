#!/usr/bin/perl

# Script to extract UserName (short version) and title of the
# PDF file according the extracted information from a pdfinfo
# (c) v0.1 9.11.2006 by Archivista GmbH, Urs Pfister

my $fname = shift; # title of the document (goes to Titel)

my $title = $fname;
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
my $ret="";
if ($title ne "") {
  $ret = "Titel=$title";
}
print $ret;

