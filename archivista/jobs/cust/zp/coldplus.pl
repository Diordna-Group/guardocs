#!/usr/bin/perl

my $db = shift;
my $title = shift;
my $pdffile = shift;
my $psfile = shift;
my $for = shift;
my $ret="";
if (-e $pdffile) {
  my $txt = '/tmp/cold.txt';
  unlink $txt if -e $txt;
	if (! -e $txt) {
    my $cmd="pdftotext -raw $pdffile $txt";
		system($cmd);
		if (-e $txt) {
      open(FIN,$txt);
			my @in = <FIN>;
			close(FIN);
			my $text = join("",@in);
			$text =~ /(Offerte|Auftragsbestätigung|Rechnugn|Lieferschein)(\s{1,1})([0-9]+)/;
			if ($1 ne "" && $2 eq " " && $3 > 0) {
			  $ret .= "Dokumententyp=$1:DokNummer=$3:";
			}
			$text =~
			  /(Datum:)(\s{1,1})([0-9]{2,2}\.[0-9]{2,2}\.[0-9]+)/; 
			if ($1 eq "Datum:" && $2 eq " " && $3 ne "") {
			  $ret .= "Datum=$3:";
			}
			$text =~
			  /(Auftrag:)(\s{1,1})([0-9]+)/; 
			if ($1 eq "Auftrag:" && $2 eq " " && $3 > 0) {
			  $ret .= "UCNummer=$3:";
			}
			$text =~
			  /(Kunden-Nr:)(\s{1,1})([0-9]+)/; 
			if ($1 eq "Kunden-Nr:" && $2 eq " " && $3 > 0) {
			  $ret .= "FirmenNummer=$3";
			}
		}
	}
}
$ret = "archivista;$ret";
open(FOUT,">>/tmp/eins.txt");
binmode(FOUT);
print FOUT "$ret--$pdffile--$db--$psfile\n";
close(FOUT);
print $ret;


