#!/usr/bin/perl

# check for a corrupted software raid and reapir it (c) 2011 by Archivista GmbH

use strict;

my $repair = "";
my $pmd1 = getDriveStatus("md1",\$repair); # findout faild partitions
my $pmd2 = getDriveStatus("md2",\$repair);
my $pmd3 = getDriveStatus("md3",\$repair);
my $pmd4 = getDriveStatus("md4",\$repair);
removeDrive($pmd1); # remove the first broken hard disk (partition)
removeDrive($pmd2);
removeDrive($pmd3);
removeDrive($pmd4);
formatDrive($repair); # format a complete new harddisk
addDrive($pmd1); # add the partions
addDrive($pmd2);
addDrive($pmd3);
addDrive($pmd4);



# give back a hash that contains information about a software raid partition

sub getDriveStatus {
  my ($mdrive,$prepair) = @_;
  my $out = `cat /proc/mdstat`;
	my %parts = {};
	print "\n";
	$parts{mddrive} = $mdrive;
	my $recovery = $out;
	my $res = $recovery =~ /recovery/;
	if ($res==1) {
	  print "$out\n";
		print "No operation while drive recovering\n\n";
		die;
	}
	$out =~ /(.*?)(\n)($mdrive)(\s{1,1}\:\s{1,1})(.*?)(\n)(.*?)(\n)/s;
	if ($3 eq $mdrive && $4 eq " : " && $5 ne "" && $7 ne "") {
	  my $drives = $5;
		my $status = $7;
		my @drives = split(" ",$drives);
		my $res = $status =~ /(\[)([U_]*)(\])$/;
		if ($res == 1) {
      $status = $2;
		} else {
		  $status = "";
		}
		while (@drives) {
		  my $part = pop @drives;
      my $res = $part =~ /([a-z]*?)([0-9]*?)(\[)([0-9])(\])/;
			$parts{partition} = $2;
			if ($res == 1) {
			  print "partition $1 with number $4\n";
				$parts{$1} = $4;
			} elsif ($part eq "raid1" || $part eq "raid0" || $part eq "raid10" ||
			         $part eq "raid5" || $part eq "raid50" || $part eq "raid60") {
				print "raid type is:$part\n";
				$parts{type} = $part;
			} elsif ($part eq "active") {
			  print "raid is active\n";
				$parts{active} = 1;
			}
		}
		my $totaldrives = length($status);
		$parts{drives} = $totaldrives;
		my $curdrive = "sda";
		$curdrive = "sdc" if $mdrive eq "md3";
		for (my $c=0;$c<$totaldrives;$c++) {
		  if ($parts{$curdrive} eq "") {
				if ($$prepair eq "") {
					$$prepair = $curdrive;
					$parts{repair} = $curdrive;
			    $parts{$curdrive} = -2;
				} elsif ($$prepair eq $curdrive) {
					$parts{repair} = $curdrive;
			    $parts{$curdrive} = -2;
				} else {
			    $parts{$curdrive} = -1;
				}
				my $msg = "drive $curdrive is missing";
				$msg .= ", will be repaired" if $parts{$curdrive}==-2;
				print "$msg\n";
			}
			$curdrive++;
    }
	}
	print "\n";
	return \%parts;
}



# check if we have a fresh harddisk (where we need a partition table)

sub formatDrive {
  my ($drive) = @_;
	if ($drive ne "") {
	  my $fromdrive = "sda";
		$fromdrive = "sdb" if $drive eq "sda";
		my $cmd = "sfdisk -d /dev/$drive";
                my $file = "/tmp/mdresult";
		my $res = `$cmd 2>$file`;
                my $line = "";
                if (-e $file) {
                  open(FIN,$file);
                  my @lines = <FIN>;
                  close(FIN);
                  $line = join("",@lines);
                }
                $res .= $line;
		my $nopart = "No partitions found";
		my $check = $res =~ /$nopart/;
		if ($check==1) {
      print "Failed drive $drive will be formated with parts from $fromdrive\n";
      my $cmd = "sfdisk -d /dev/$fromdrive | sfdisk --force /dev/$drive";
		  print "$cmd\n";
		  my $res = `$cmd`;
		  print "$res\n";
		} else {
		  print "Drive $drive is not empty, we won't format it!\n";
		}
	}
}



# remove partitions from an array

sub removeDrive {
  my ($pdrive) = @_;
	my $curdrive = "sda";
	$curdrive = "sdc" if $$pdrive{mddrive} eq "md3";
	for (my $c=0;$c<$$pdrive{drives};$c++) {
    if ($$pdrive{$curdrive} == -2) {
		  my $mdrive = "/dev/".$$pdrive{mddrive};
			my $sdrive = "/dev/".$curdrive.$$pdrive{partition};
		  my $cmd = "mdadm --manage $mdrive --fail $sdrive";
			print "$cmd\n";
			my $res = `$cmd`;
			print "$res\n";
		  $cmd = "mdadm --manage $mdrive --stop $sdrive";
			print "$cmd\n";
			$res = `$cmd`;
			print "$res\n\n";
		}
		$curdrive++;
	}
}



# add the missed drive back (syncronisation will be done automaticially)

sub addDrive {
  my ($pdrive) = @_;
	my $curdrive = "sda";
	$curdrive = "sdc" if $$pdrive{mddrive} eq "md3";
	for (my $c=0;$c<$$pdrive{drives};$c++) {
    if ($$pdrive{$curdrive} == -2) {
		  my $mdrive = "/dev/".$$pdrive{mddrive};
			my $sdrive = "/dev/".$curdrive.$$pdrive{partition};
		  my $cmd = "mdadm --manage $mdrive --add $sdrive";
			print "$cmd\n";
			my $res = `$cmd`;
			print "$res\n";
			$cmd = "echo 1000000 > /proc/sys/dev/raid/speed_limit_max";
			$res = `$cmd`;
			print "$res\n";
		}
		$curdrive++;
	}
}


