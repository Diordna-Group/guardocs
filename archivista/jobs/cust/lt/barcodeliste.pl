#!/usr/bin/perl

=head1 fieldimport.pl $importfile

(c) 2009, Archivista GmbH, Urs Pfister

imports Fieldnames and Codes from an import file.

=cut

use lib "/home/cvs/archivista/jobs";

use strict;
use AVDocs;

my $outfile = shift;
my $anz = shift;
$outfile = "barcodes.txt" if $outfile eq "";
$anz = 64 if $anz <= 0;

my $database = "archivlt";
my $av = AVDocs->new();
$av->setDatabase($database);
if ($av->setTable($av->TABLE_FIELDLISTS)) {
  my $out = "";
  my @keys = $av->keys("FeldCode","MandantNr");
	@keys = sort @keys;
	foreach (@keys) {
	  my @rec = $av->select("Code","Laufnummer",$_);
	  print "$rec[0]\n";
		for (my $c=0;$c<$anz;$c++) {
		  $out .= "00".$rec[0].sprintf("%04d",$c)."\r\n";
		}
	}
	$av->writeFile($outfile,\$out,1);
}




