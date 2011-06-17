#!/usr/bin/perl

use strict;

my $mysql="/home/data/archivista/mysql";
my $backup="/mnt/usbdisk/backup";

system("rc apache stop");
system("rc mysql stop");
system("rm -Rf $backup/*");
sleep 4;
my $cmd="rsync -r $mysql/ $backup/";
print "$cmd\n";
system($cmd);
my $err=$?;
$err=1 if $err!=0;
sleep 2;
system("rc mysql start");
system("rc apache start");
exit $err;
