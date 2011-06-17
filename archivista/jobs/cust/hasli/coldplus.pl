#!/usr/bin/perl

my $db = shift;
my $title = shift;
my $pdffile = shift;
my $psfile = shift;
my $for = shift;
my $printer = shift;
my $ret="";
if (-e $pdffile) {
  if ($printer eq "archivhasli-cold" || $printer eq "archivaudit-cold") {
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
				$text =~ /^(Rechnung)(\s+)([0-9]*)/sm;
				$text =~ /^(Detail)(\s+)([0-9]*)/sm;
				if (($1 eq "Rechnung" || $1 eq "Detail") && $3>0) {
				  $ret = "Belegart=$1:KontoWer=$3";
					if ($1 eq "Rechnung") {
				    $text =~ /^([0-9]{2,2}\.{1,1}[0-9]{2,2}\.{1,1}[0-9]{4,4})/sm;
						if ($1 ne "" && $1 ne "Rechnung") {
					    $ret .= ":" if $ret ne "";
					    $ret .= "DatumVon=$1";
						}
					} else {
				    $text =~ /([0-9]{6,10})/s;
						if ($1 ne "" && $1 ne "Detail") {
					    $ret .= ":" if $ret ne "";
					    $ret .= "Was=$1";
						}
					}
				}
			}
		}
	}
}
$ret = "$db;$ret";
print $ret;


