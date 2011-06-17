#!/usr/bin/perl

use strict;
my $name = shift;

my @lines = `dmesg`;
@lines = reverse @lines;
for (my $c=0;$c<=@lines;$c++) {
  my $line = $lines[$c];
	if (index($line,"usb0: register 'cdc_ether' at usb")==0) {
	  chomp $line;
		my $mac = substr($line,-17);
		my ($ip,$up);
    if ($mac eq "52:8a:a7:03:f9:54") {
		  $up = "192.168.4.14";
		  $ip = "192.168.4.15";
		} elsif ($mac eq "06:e5:6c:84:1b:8b") { 
		  $up = "192.168.4.16";
		  $ip = "192.168.4.17";
		}
	  system("ifdown $name");
		system("ifconfig $name $up");
    system("iptables -A POSTROUTING -t nat -s $ip/24 -j MASQUERADE");
		system("echo 1 > /proc/sys/net/ipv4/ip_forward");
		last;
	}
}

