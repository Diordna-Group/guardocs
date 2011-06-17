#!/bin/perl

use strict;

my $res = shift;
my $ip = shift;
my $options = shift;
my @options = split(',',$options);
my $device = shift @options;
my $keepbackup = shift @options;
open(FOUT,">>/home/data/archivista/av.log");
print FOUT "$0--$res--$ip--$options\n";
close(FOUT);

system("drbdadm down $res");
system("mkdir /mnt/backup") if !-e "/mnt/backup";
system("echo 'error' > /mnt/backup/error");
system("mount /dev/md8 /mnt/backup");
system("mkdir /mnt/save") if !-e "/mnt/save";
system("echo 'error' > /mnt/save/error");
system("mount $device /mnt/save");
if (!-e "/mnt/backup/error" && !-e "/mnt/save/error") {
  # we can do a backup
	my @restart = ();
	my @backup = ();
	foreach my $id (@options) {
          print "do backup for $id\n";
	  my $id1 = $id;
          my $running1 = $id1;
	  if (length($id)>1) {
			my $running1 = substr($id,-1);
                  if ($running1 eq "+") {
		    $id1 = substr($id,0,length($id)-1);
                 }
			push @restart,$id1 if $running1 eq "+";
		}
		push @backup,$id1;
	}
	my $start = join(",",@restart);
  my $cmd = "CLUSTERVMUP\noptions=$start";
  open(FOUT,">/tmp/clustervmup$res");
  print FOUT $cmd;
  close(FOUT);
  my $opt = "-B -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
  if (-e "/tmp/clustervmup$res") {
    my $cmd = "scp $opt /tmp/clustervmup$res $ip:/etc/webconfig";
    system($cmd);
	}
	foreach my $dir (@backup) {
	  my $backupdir1 = "/mnt/save/$dir";
		if ($keepbackup>1) {
		  my $last = "$backupdir1-$keepbackup";
			if (-d $last) {
			  my $cmd = "rm -Rf $last";
        system($cmd);
			}
		  for(my $c=$keepbackup;$c>1;$c--) {
			  my $c1 = $c;
				$c1--;
			  my $moveback = "$backupdir1-$c1";
				$moveback = "$backupdir1" if $c1==1;
		    my $last = "$backupdir1-$c";
				if (-d "$moveback") {
				  if (!-e "$last") {
			      my $cmd = "mv $moveback $last";
						system($cmd);
					}
				}
			}
		}
    if (!-d "$backupdir1") {
      mkdir "$backupdir1";
    }
    my $cmd = "scp $opt $ip:/etc/qemu-server/$dir.conf /mnt/save/$dir";
    system($cmd);
		$cmd = "cp -rp /mnt/backup/images/$dir /mnt/save";
		system($cmd);
	}
	system("umount /mnt/save");
	system("umount /mnt/backup");
	system("drbdadm up $res");
}

