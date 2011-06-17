#!/usr/bin/perl

use strict;

my $drives = shift;
my $type = shift;
my $letter = shift;
if ($drives eq "" || $type eq "" || $letter eq "") {
  print "$0 (c) 2011 by Archivista GmbH\n";
	print "usage: $0 drives raidlevel startdriveletter (example: $0 2 0 e)\n";
	exit 0;
}

my @cmds = ();
my $letter1=$letter;
for (my $count=1;$count<=$drives;$count++) {
  my $cmd = "sfdisk -d /dev/sda | sfdisk --force /dev/sd$letter1";
	push @cmds,$cmd;
	$letter1++;
}

create_md(\@cmds,"md7",3,2,$letter,1,0);
create_md(\@cmds,"md8",4,$drives,$letter,$type,128);

foreach my $cmd (@cmds) {
  print "$cmd starts in 5 seconds...\n";
	sleep 5;
	system($cmd);
}


sub create_md {
  my ($pcmds,$md,$partnr,$drives,$letter,$type,$chunk) = @_;
  my $check = `cat /proc/mdstat | grep '$md'`;
  if ($check eq "") {
    my $cmd = "yes yes | mdadm --create --force /dev/$md ".
		          "--raid-disks=$drives --level=$type";
		$cmd .= " --assume-clean";
		$cmd .= " --chunk=$chunk" if $chunk>0;
	  my $letter1 = $letter;
	  for (my $count=1;$count<=$drives;$count++) {
	    my $dev = "/dev/sd$letter1$partnr";
			my $check = `df | grep '$dev'`;
			if ($check ne "") {
			  print "$dev is mounted, stop it!\n";
				die;
			}
		  $cmd .= " $dev";
		  $letter1++;
	  }
		push @$pcmds,$cmd;
	} else {
	  print "drive $md already does exist\n";
		die;
	}
}



