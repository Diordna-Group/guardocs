#!/usr/bin/perl

my $wait = shift;
my $fin = shift;
my $fout = shift;
#open(FOUT,">>/tmp/mail.lst");
#print FOUT "$fin--$fout--$wait\n";
#close(FOUT);

my $found = 0;
for (my $c=1;$c<$wait;$c++) {
  if (!-e $fout) {
	  sleep 2;
	} else {
	  $found=1;
		last;
	}
	if (!-e $fin) {
		last;
	}
}
if ($found==0 && -e $fin) {
	# stop everything (including open office)
	system("killall soffice &");
}

