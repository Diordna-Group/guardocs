#!/usr/bin/perl

# Script to extract UserName (short version) and title of the
# PDF file according the extracted information from a pdfinfo
# (c) v0.1 9.11.2006 by Archivista GmbH, Urs Pfister

use strict;
use File::Copy;

my $db = shift; # database name (you can change it)
my $title = shift; # title of the document (goes to Titel)
my $pdffile = shift; # pdf file name (for own work)
my $psfile = shift; # ps file name (for own work)
my $for = shift; # author of the document (goes to Eigentuemer)

my $folder = "/home/data/archivista/cust/cold/";
my $logo = $folder.$db.'.pdf';
#open(FOUT,">>/tmp/fuenf.txt");
#print FOUT "$db---------$logo\n";
#close(FOUT);

$logo = $folder."archivista.pdf" if !-e $logo;

my $file2 = "/tmp/cupstemp.pdf";
my $seite1 = "/tmp/cupsseite1.pdf";
my $text1 = "/tmp/cupsseite1.txt";
unlink $file2 if -e $file2;
unlink $psfile if -e $psfile;
copy($pdffile,$file2);
my $cmd = "pdftk $file2 background $logo output $pdffile >>/tmp/eins.txt";
system($cmd);
$cmd = "pdftk $file2 cat 1 output $seite1 >>/tmp/eins.txt";
system($cmd);
unlink $text1 if -e $text1;
$cmd = "pdftotext $seite1";
system($cmd);
my $ret = "archiv;";
$ret .= "MandantNr=300:HHWLieferNr=232995:Bereich=Lieferanten:".
        "Unterbereich=Rechnungen:Eigentuemer=HHWlief:Belegart=HHW";
if (-e $text1) {
  open(FIN,$text1);
	my @text1 = <FIN>;
	close(FIN);
	my $text2 = join("",@text1);
	$text2 =~ /(RECHNUNG\sNR.)(.*?)([0-9]{6,10})/;
	if ($3 >0) {
	  my $rechnr = $3;
		my $datum = "";
	  $text2 =~ /(Datum\s)([0-9]{2,2}\.[0-9]{2,2}\.[0-9]{4,4})/;
		if ($2 ne "") {
		  $datum = $2;
		}
	  $ret.=":Zahlreferenz=$rechnr:Datum=$datum";
	}
}
print $ret;




