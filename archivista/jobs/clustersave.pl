#!/bin/perl

use strict;
my $opts = shift; # get backup options

my $ressource = `cat /etc/drbdcheck.conf`;
my @lines = split(/\n/,$ressource);
my $rx = @lines[0];
my $currentip = `ifconfig vmbr0 | grep 'inet addr'`;
$currentip =~ s/(.*?)(inet\saddr:)([0-9.]*)(.*)/$3/;
chomp $currentip;
my ($ip1,$ip2,$ip3,$ip4) = split(/\./,$currentip);
#print "1:$ip1--2:$ip2--3:$ip3--4:$ip4\n";
my $file = "/etc/drbd.conf";
open(FIN,$file);
my @lines = <FIN>;
close(FIN);
my $line = join("",@lines);
$line =~ /($rx)(.*?)(avbox$ip4)(.*?)($ip4)(.*?)(address)(\s*)([0-9.]*)/s;
#print "1:$1--2:$2--3:$3--4:$4--5:$5--6:$6--7:$7--8:$8--9:$9----$currentip\n";
my $ipto = $9;
my ($ir1,$ir2,$ir3,$ir4) = split(/\./,$ipto);
my $resource = "r".$ir3;
my $cmd = "SECONDARYBACKUP\nresource=$resource\nip=$currentip\noptions=$opts";
open(FOUT,">/tmp/secdown");
print FOUT $cmd;
close(FOUT);
if (-e "/tmp/secdown") {
  my $opt = "-B -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
  my $cmd = "scp $opt /tmp/secdown $ipto:/etc/webconfig";
	print "$cmd\n";
	system($cmd);
}

