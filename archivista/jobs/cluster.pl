#!/usr/bin/perl

use strict;

print "$0 (c) v1.0, 22.4.2011 by Archivista GmbH -- Cluster setup programm\n";

my $info = `pveca -l`;
my @infos = split(/\n/,$info);
my @ips = ();
my $backup = "";
shift @infos;
foreach (@infos) {
	my ($nr,$none,$ip,$role,$active,$rest) = split(" ",$_);
	if ($active eq "A") {
	  $backup = $ip if $role eq "M";
		push @ips,$ip;
	}
}
@ips = sort @ips;
set_drbd(\@ips);
set_ip(\@ips);

#my $mdrive = get_masterdrive();



sub get_masterdrive {
  my $info = `df | grep '/var/lib/vz'`;
	my ($drive,$rest) = split(" ",$info);
	if ($drive ne "") {
	  print "data drive is:$drive\n";
		if ($drive eq "/dev/md4") {
		  my ($none,$dev,$md) = split(/\//,$drive);
			print "md drive is:$md\n";
      my $info = `cat /proc/mdstat | grep $md`;
			my @parts = split(" ",$info);
      my $md1 = shift @parts;
			$none = shift @parts;
			my $active = shift @parts;
			my $type = shift @parts;
			my $drivecount=0;
			my $driveletter = "a";
			foreach (@parts) {
			  print "part:$_\n";
				$drivecount++;
				$driveletter++;
			}
			if ($md1 eq $md && $active eq "active") {
			  print "$md has $drivecount drive with $type\n";
				if ($type eq "raid10") {
				  print "firstletter is $driveletter\n";
					my $secstart = $drivecount+1;
					my $seccount = 0;
					foreach (@parts) {
					  my $size = `sfdisk -s /dev/sd$driveletter 2>/dev/null`;
						if ($size>0) {
						  $seccount++;
						  $driveletter++;
						} else {
						  last;
						}
					}
					my $sectype = "";
					my $seccount2 = $seccount*2;
					if ($drivecount == $seccount) {
					  $sectype = $type;
					} elsif ($type eq "raid10" && $seccount2 == $drivecount) {
					  $sectype = "raid0";
					}
					if ($sectype ne "" && $seccount>0) {
					  print "$seccount drives for secondary with $sectype\n";
					}
				}
			}
		}
	}
	return $drive;
}



sub set_ip {
  my ($pips) = @_;
	my @drbd = ();
	my $currentip = `ifconfig vmbr0 | grep 'inet addr'`;
  $currentip =~ s/(.*?)(inet\saddr:)([0-9.]*)(.*)/$3/;
	chomp $currentip;
	my $count = @$pips;
	if ($count<3 || $count>5) {
	  print "We at this time only support clusters from 3 to 5 machines\n";
		die;
	}
	my $nr=1;
	foreach my $ip (@$pips) {
		system("scp $ip:/etc/network/interfaces /interfaces$nr");
		open(FIN,"/interfaces$nr");
		my @lines = <FIN>;
		close(FIN);
		my $line = join("",@lines);
		$line =~ s/(.*?)(\nauto\seth)(.*?$)/$1/s;
		$line =~ s/(\n*$)/\n\n/s;
		my ($ip0,$ip4) = get_parts($ip);
		my $part = "";
		my $ethnr = 1;
		my $masknr = $nr;
		for (my $nr2=1;$nr2<=$count;$nr2++) {
			next if $nr2==$nr;
			$part .= "\nauto eth$ethnr\niface eth$ethnr inet static\n";
			my $fastip = "$ip0.0.$masknr.$ip4";
			$part .= "  address $fastip\n";
			$part .= "  netmask 255.255.255.0\n\n";
			$ethnr++;
			$masknr++;
			$masknr=1 if $masknr>$count;
		}
		$line .= "\n$part";
		open(FOUT,">/interfaces$nr");
		print FOUT $line;
		close(FOUT);
		system("scp /interfaces$nr $ip:/etc/network/interfaces");
		system("scp /drbd.conf $ip:/etc");
		open(FOUT,">/cmd$nr");
		print FOUT "NETWORKRESET";
		close(FOUT);
		if ($ip ne $currentip) {
		  print "restarting server $ip\n";
		  system("scp /cmd$nr $ip:/etc/webconfig");
		}
		$nr++;
  }
	print "restarting current server\n";
	system("/etc/init.d/networking restart");
}



sub set_drbd {
  my ($pips) = @_;
	my $array = 1;
	my $portbase = 7790;
	my $count = @$pips;
	open(FIN,"/etc/drbd.template");
	my @lines = <FIN>;
	close(FIN);
	my $line = join("",@lines);
	my $init = $line;
	$init =~ s/(.*?)(\nresource)(.*)/$1/s;
	my $res = $line;
	$res =~ s/(.*?)(\nresource)(.*)/$2$3/s;
	foreach my $ip (@$pips) {
	  my $rnr = "r$array";
		my $port = $portbase + $array;
		print "first ip:$ip\n";
		my ($ip0,$ip4) = get_parts($ip);
		my $firstip = "$ip0.0.$array.$ip4";
		my $firstname = "avbox$ip4";
		my $nr2 = $array;
		if ($array==1) {
		  $nr2 = $count-1;
		} elsif ($array==$count) {
		  $nr2 = 1;
		} else {
		  $nr2--;
			$nr2--;
		}
		my $ip2 = $$pips[$nr2];
		print "second ip:$ip2\n";
		($ip0,$ip4) = get_parts($ip2);
		my $secip = "$ip0.0.$array.$ip4";
		my $secname = "avbox$ip4";
		print "$firstip=>$secip\n";
		$array++; 
    my $res1 = $res;
		$res1 =~ s/(\[ip1\])/$firstip/g;
		$res1 =~ s/(\[box1\])/$firstname/g;
		$res1 =~ s/(\[ip2\])/$secip/g;
		$res1 =~ s/(\[box2\])/$secname/g;
		$res1 =~ s/(\[port\])/$port/g;
		$res1 =~ s/(\[rnr\])/$rnr/g;
		$init .= $res1;
	}
	open(FOUT,">/drbd.conf");
	print FOUT $init;
	close(FOUT);
}



sub get_parts {
  my ($ip) = @_;
	my @parts = split(/\./,$ip);
	my $ip0 = "10"; # use 10.x.y.z as default
	my $ip1 = shift @parts;
	my $ip4 = pop @parts;
	$ip0 = "172" if $ip1 eq "10";
	return ($ip0,$ip4);
}


