#!/usr/bin/perl

use strict;
use Time::Local;
use constant FILE => "/tmp/lcdcheck";
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;
logit("lcdcheck started");
sleep 3;
my $msg=`lsusb | grep 'Microchip Technology Inc.'`;
if ($msg ne "") {
  open(FH,FILE);
  my $date = timelocal ( localtime ( (stat FH)[9] ) );
  close(FH);
  my $now = timelocal ( localtime ( ) );
  my $diff = $now - $date;
  if (!-e FILE || $diff > 60) {
	  open(FOUT,">".FILE);
		print FOUT "start";
		close(FOUT);
    system("killall LCDd");
    sleep 1;
    system("LCDd");
    sleep 1;
    system("perl /home/cvs/archivista/jobs/lcdscan.pl &");
		sleep 30;
		logit("now kile file ".FILE);
		system("rm -f ".FILE);
	}
}


