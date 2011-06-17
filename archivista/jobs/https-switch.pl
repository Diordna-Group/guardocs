#!/usr/bin/perl

use strict;
my $switch = shift;
my $disabled = 0;
my $changed = 0;
my $file = "/etc/apache2/sites-available/pve.conf";
if (-e $file) {
  open(FIN,$file);
	binmode(FIN);
	my @lines = <FIN>;
	close(FIN);
	my $line = join("",@lines);
	$line =~ /(#)(RewriteRule)(.*?)(\[)(L,R)(\])/;
	if ($1 eq "#") {
	  print "SSL currently deactivated\n";
		$disabled = 1;
	} else {
	  print "SSL currently activated\n";
	}
	if ($switch==0 && $disabled==0) {
	  print "Now disabling SSL\n";
	  $line =~ s/(RewriteRule)(.*?)(\[)(L,R)(\])/#$1$2$3$4$5/;
		$changed=1;
	} elsif ($switch==1 && $disabled==1) {
	  print "Now activating SSL\n";
	  $line =~ s/(#)(RewriteRule)(.*?)(\[)(L,R)(\])/$2$3$4$5$6/;
		$changed=1;
  } else {
	  print "Nothing to do\n";
	}
  if ($changed==1) {
	  open(FOUT,">$file");
	  binmode(FOUT);
    print FOUT $line;	
		close(FOUT);
	}
} else {
  print "ERROR: No apache file $file\n";
}


