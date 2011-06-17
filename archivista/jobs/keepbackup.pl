#!/usr/bin/perl

# (c) 2010 by Archivista GmbH, Urs Pfister
# keep an old directory (namely backup) with an number from 1-x

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;

my $backupdir1=shift;
$backupdir1 = "/mnt/usb/data/archivista" if $backupdir1 eq "";
my $conf="";

readFile2("/etc/usb-backup-webconfig.conf",\$conf);
my @vals = split("\n",$conf);
my $val = $vals[2];
my ($name,$keep) = split("=",$val);
if ($name eq "keep") {
  my $keepbackup=$keep;
  my $last = "$backupdir1-$keepbackup";
  logit("keep old backups: $keepbackup");
	if (-d $last) {
	  my $cmd = "rm -Rf $last";
    logit("remove backup $last");
		system($cmd);
	}
	for(my $c=$keepbackup;$c>1;$c--) {
	  my $c1 = $c;
		$c1--;
	  my $moveback = "$backupdir1-$c1";
		$moveback = "$backupdir1" if $c1==1;
	  $last = "$backupdir1-$c";
		if (-d "$moveback") {
      logit("folder $moveback founded");
		  if (!-e "$last") {
        logit("now move from $moveback to $last");
	      my $cmd = "mv $moveback $last";
        system($cmd);
			}
		}
	}
}

