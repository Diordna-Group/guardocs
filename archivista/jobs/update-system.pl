#!/usr/bin/perl

#use warnings;
use strict;

my $iso = shift; # iso file for update
my $auto = shift; # do it without asking for it ($auto=1)

print "\n$0 -- (c) 2008 by Archivista GmbH, R. Nuridini\n".
      "Update ArchivistaBox from console given an archivista\n".
			"ISO file. The installation always is made to the \n".
			"alternative partition (i.e. active:hda1 -> installs:hda2)\n\n";

my ($ant,$go);

if ($iso ne "" && $auto != 1) {
	print "Do you want to update (does overwrite non active partition)? [y|n] ";
  $ant = <>;
	chomp $ant;
	$ant = lc($ant);
} elsif ($iso ne "" && $auto == 1) {
  $ant = "y";
	sleep 5;
} else {
  print STDERR "No archivista_xxx.iso as parameter\n";
	exit 1;
}

die if $ant ne "y";

if ( ! -e $iso ) {
  # File does not exists
	print STDERR "ISO-File $iso not found\n";
	exit 1;
} else {
  if ( ! checkIso($iso) ) {
	  print STDERR "Error while Checking ISO\n";
		exit 2;
	}
	# ISO is mounted and passed the checks
}
my $partition = getUnusedPartition();
if ( ! $partition ) {
  print STDERR "Root Partition Number is not (1 or 2)\n";
	exit 3;
} else {
  my ($cmd);
	$cmd = "mkdir -p /mnt/target";
	system($cmd);
	$cmd = "mount $partition /mnt/target";
	system($cmd);
  $cmd = "/home/archivista/update.sh ";
	system($cmd);
	print "\n\n$0 ========================== ArchivistaBox\n\n".
	      "If none of the above messages is saying the opposit, it looks\n".
	      "like you updated the alternative partition. Have a look at the \n".
				"master boot record, mount the alternative partition and check if\n".
				"/etc/fstab and /boot/grub/menu.lst are correct. If so, you can \n".
				"try to reboot! Good luck!\n\n";
	open(FOUT,">/tmp/update.txt");
	print FOUT "ok\n";
	close(FOUT);
}



foreach my $sys ("/mnt/live",$iso,"/mnt/target") {
  if ( system( "umount $sys" ) ) { 
    print STDERR "Error unmounting $sys\n";
	  exit 4;
  }
}



=head2 1/0=checkIso($file)

Small check if ISO-File is ok. (does live.squash exist?)

=cut

sub checkIso {
  my ($file);
  $file = shift;
	my ($mdir,$ldir,$cmd,$res);
	$mdir = "/media/cdrom/";
	$ldir = "/mnt/live/";
	$res = 0;
	$cmd = "mkdir -p $ldir";
	system($cmd);
	$cmd = "mkdir -p $mdir";
  # NOT Bash return values 0 => Error. x != 0 Success
	if ( system($cmd) ) {
	  print STDERR "Error creating $mdir\n";
	} else {
	  $cmd = "mount -o loop $file $mdir";
		if ( system($cmd) ) {
	    print STDERR "Error mounting $file\n";
		} else {
		  if (-e "$mdir/live.squash") {
			  $cmd = "mount -t squashfs -o loop $mdir/live.squash $ldir";
				system($cmd);
			  $res = 1;
			} else {
	      print STDERR "Error ISO-File has no live system\n";
			}
		}
	}
	return $res;
}






=head2 getUnusedPartition

Returns the Name of the unused Partition.

=cut

sub getUnusedPartition {
  my $unused_dev = "";
	foreach my $line ( split("\n",`mount`) ) {
	  if ($line =~ /^(\/dev\/.+)\son\s\/\s.+$/) {
		  my ($dev,$dev_nr);
		  $dev = $1;
			my ($cmd);
			$cmd = "mkdir -p /mnt/update";
			system($cmd);
			$cmd = "mount --bind / /mnt/update/";
			system($cmd);
			# Return the last char (device number)
			$dev_nr = chop($dev);
			if ($dev_nr == 1) {
			  $dev_nr = 2;
		    $unused_dev = $dev.$dev_nr;
			} elsif ($dev_nr == 2) {
			  $dev_nr = 1;
		    $unused_dev = $dev.$dev_nr;
			} else {
			  # Device Number is not 1 or 2! Something is strange.
				# Please Check the Installed Partitions
				$unused_dev = 0;
			}
			last;
		}
	}
	return $unused_dev;
}






