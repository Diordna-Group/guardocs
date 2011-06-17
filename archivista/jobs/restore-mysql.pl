#!/usr/bin/perl

use strict;

my $mysql_dir = "/home/data/archivista/mysql";  #Pfad zu MySQL Datenbanken
my $backup_dir  =  "/mnt/usbdisk/backup/*";  #Basedir für Backup

system("rc apache stop");
system("rc mysql stop");
for(my $c=0;$c<10;$c++) {
  my $cmd="ps -A | grep 'mysql'";
	my $res=`$cmd`;
	print "$res found\n";
	$c=10 if $res eq "";
	sleep 1;
}
system("rm -Rf $mysql_dir");
system("mkdir $mysql_dir");
system("cp -pR $backup_dir $mysql_dir");
system("chown -R mysql.mysql $mysql_dir");
system("chmod -R 660 $mysql_dir");
system("chmod 755 $mysql_dir");
opendir(FIN,$mysql_dir);
my @f=readdir(FIN);
closedir(FIN);
foreach(@f) {
  my $f=$_;
	chomp $f;
	print "$f found\n";
	if ($f ne "." && $f ne "..") {
    my $dirf="$mysql_dir/$f";
		print "$dirf\n";
		if (-d $dirf) {
      my $cmd="chmod 700 $dirf";
		  system($cmd);
			print "$cmd\n";
		}
	}
}
system("/home/archivista/mysql-case-fixup.sh /home/data/archivista/mysql");
system("rc mysql start");
system("rc apache start");



