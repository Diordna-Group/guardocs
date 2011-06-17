#!/usr/bin/perl

use strict; 

my $res = shift;
my $primary = shift;
print "$0 (c) v1.0 by Archivista GmbH, Programm to start drbd drive\n";
if ($res eq "") {
  print "usage: $0 resource [1], ex: $0 r1 1 -> start primary\n";
	die;
}
systemgo("modprobe drbd");
if ($primary==1) {
	my $state = `cat /proc/drbd | grep ' 0: ' | grep 'Primary/Secondary'`;
	if ($state ne "") {
	  print "$res is already primary, stop creation of $res\n";
	  die;
	}
} else {
	my $state = `cat /proc/drbd | grep ' 1: ' | grep 'Secondary/Primary'`;
	if ($state ne "") {
	  print "$res is already secondary, stop creation of $res\n";
    die;
	}
}
if ($primary==1 && !-e "/var/lib/vz.tgz") {
  systemgo("mount -a");
  my $needed = `du -s /var/lib/vz/`;
	my ($size,$rest) = split(" ",$needed);
  $needed = `df / | grep '/dev/'`;
	my ($rest1,$rest2,$rest3,$free,$rest4) = split(" ",$needed);
	my $available = $free - $size;
	print "$free -- $size -- $available\n";
	if ($available<0) {
	  print "not enough space for restoring /var/lib/vz for primary $res\n";
		die;
	} else {
	  systemgo("/etc/init.d/mysql stop");
		systemgo("tar cvfz /var/lib/vz.tgz /var/lib/vz");
		systemgo("umount /var/lib/vz");
	}
}
createres($res);
sleep 3;
if ($primary==1) { 
  my $ready=0;
	my $count=1;
  while ($ready==0) {
	  print "$count try to switch to master $res\n";
	  my $state = `cat /proc/drbd | grep ' 0: ' | grep 'Secondary/Secondary'`;
		if ($state ne "") {
      systemgo("drbdadm -- --clear-bitmap new-current-uuid $res");
			$ready=1;
		} else {
      createres($res);
		}
	  $count++;
	  $ready=1 if $count>20;
    sleep 5;
	}
	systemgo("drbdadm primary $res",3);
	my $state = `cat /proc/drbd | grep ' 0: ' | grep 'Primary/Secondary'`;
	if ($state ne "") {
	  systemgo("mkfs.ext4 -i 131072 /dev/drbd0",3);
		open(FIN,"/etc/fstab");
		my @lines = <FIN>;
		close(FIN);
		my $line = join("",@lines);
		$line =~ s/(\n\/dev\/)(.*?)(\s)(\/var\/lib\/vz)/$1drbd0$3$4/;
		open(FOUT,">/etc/fstab");
		print FOUT $line;
		close(FOUT);
		systemgo("mount -a");
		systemgo("cd /;tar xvfz /var/lib/vz.tgz");
		systemgo("echo \"$res\" >/etc/drbdcheck.conf");
		systemgo("sysv-rc-conf drbdcheck on");
	  systemgo("/etc/init.d/mysql start");
	}
}
systemgo("sysv-rc-conf drbd on");



sub systemgo {
  my ($cmd,$sleep) = @_;
	print "$cmd\n";
	system($cmd);
	sleep $sleep if $sleep>0;
}



sub createres {
  my ($res) = @_;
  systemgo("drbdadm down $res",1);
  systemgo("yes yes | drbdadm create-md $res");
  systemgo("drbdadm attach $res",1);
  systemgo("drbdadm syncer $res",1);
  systemgo("drbdadm connect $res",1);
}
