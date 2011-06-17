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
			my ($rechnr,$knr,$dat) = split(" ",$in[3]);
			$ret="Datum=$dat:Rechnungsnummer=$rechnr:FirmenNummer=$knr";
		}
	}
}
$ret = "archivista;$ret";
open(FOUT,">>/tmp/eins.txt");
binmode(FOUT);
print FOUT "$ret--$pdffile--$db--$psfile\n";
close(FOUT);
print $ret;


