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
    my $cmd="pdftotext $pdffile $txt";
		system($cmd);
		if (-e $txt) {
      open(FIN,$txt);
			my @in = <FIN>;
			close(FIN);
			my $text = join("",@in);
			my $knr = "";
			my $dat = "";
			my $typ = "";
			my $id = "";
			$text =~ /(##KundeNr=)([0-9]+?)(##)/;
			if ($1 eq "##KundeNr=" && $2 ne "" && $3 eq "##") {
			  $knr = "KundeNr=$2";
				$ret = $knr;
      }
			$text =~ /(##Datum=)([0-9]{2,2}\.[0-9]{2,2}\.[0-9]{4,4})(##)/;
			if ($1 eq "##Datum=" && $2 ne "" && $3 eq "##") {
			  $dat = "Datum=$2";
				$ret .= ":" if $ret ne "";
				$ret .= $dat;
      }
			$text =~ /(##Belegtyp=)([A-Za-z0-9]+?)(##)/;
			if ($1 eq "##Belegtyp=" && $2 ne "" && $3 eq "##") {
			  $typ = "Belegtyp=$2";
				$ret .= ":" if $ret ne "";
				$ret .= $typ;
      }
			$text =~ /(##NummerID=)([A-Za-z0-9]+?)(##)/;
			if ($1 eq "##NummerID=" && $2 ne "" && $3 eq "##") {
			  $id = "NummerID=$2";
				$ret .= ":" if $ret ne "";
				$ret .= $id;
      }
		}
	}
}
$ret = "gewa;$ret";
#open(FOUT,">>/tmp/eins.txt");
#binmode(FOUT);
#print FOUT "$ret--$pdffile--$db--$psfile\n";
#close(FOUT);
print $ret;


