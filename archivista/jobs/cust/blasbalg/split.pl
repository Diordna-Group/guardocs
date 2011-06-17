#!/usr/bin/perl

use strict;
open(FIN,"./blasbalg.txt");
my @lines=<FIN>;
close(FIN);

my $c=0;
my $c1=1;
open(FOUT,">./blasbalg$c1.txt");
foreach (@lines) {
  my $line = $_;
  if ($c % 1280 == 0) {
	  close(FOUT);
	  open(FOUT,">./blasbalg$c1.txt");
		$c1++;
	}
	$line =~ s/\t/\x08/g;
	$line =~ s/\a/\r\n/g;
	print FOUT $line;
	$c++;
}
close(FOUT);
