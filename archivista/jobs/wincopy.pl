#!/usr/bin/perl

# winupload.pl -> script for uploading a document via web client
# (c) 2008 by Archivista GmbH, Urs Pfister

use strict;
use File::Copy;

my $backspace = checkWindowsLinux();
my $dirin = shift;
my $dirtemp = shift;
my $break = shift;
my $upload = shift;

if ($dirin eq "" && $dirtemp eq "" && $break eq "") {
  print "$0 v1.0 (c) 2010 by Archivista GmbH, watch a dir and call upload prg\n";
	print "$0 dirin dirtemp seconds (to wait between checks for uploads) [upload]\n";
	print "   => [upload] optional, without it call winupload.pl or winupload.exe\n";
	print "   => you can stop the program if you create a file wincopy.stp\n";
	exit
}
$dirin = "." if !-d $dirin;
$dirtemp = "/tmp" if !-d $dirtemp && $backspace eq "/";
$dirtemp = "c:\\temp" if !-d $dirtemp && $backspace eq "\\";
die "no temp dir found" if !-d $dirtemp;
$break = 3 if $break<=3;
$break = 60 if $break>=60;
if (!-f $upload) {
  $upload = ".$backspace"."winupload.exe";
	if (!-f $upload) {
    $upload = ".$backspace"."winupload.pl";
	}
}
die "no upload program defined" if !-f $upload;



while(1) {
  opendir(FDIR,$dirin);
	my @files = readdir(FDIR);
	closedir(FDIR);
	foreach (@files) {
	  my $file = $_;
		my $file1 = lc($file);
		next if $file eq "." || $file eq "..";
		my $pos = index($file,'.');
		if ($pos==0) {
      print "hidden file $file won't be processed\n";
      next;
		}
		if ($file eq "wincopy.stp") {
		  print "wincopy.stp file found, terminate program\n";
	    my $filestop = "$dirin$backspace$file";
	    unlink $filestop if -e $filestop;
			exit;
		} elsif ($file1 eq $0 || 
		         $file1 eq "winupload.exe" || 
						 $file1 eq "winupload.pl" || 
						 $file1 eq "winupload.dat" || 
						 $file1 eq "wincopy.pl" || 
						 $file1 eq "wincopy.exe"
						 ) {
		  # nothing to do
		} else {
		  my $filein = "$dirin$backspace$file";
			my $fileout = "$dirtemp$backspace$file";
			sleep $break;
			if (-e $filein) {
			  unlink $fileout if -e $fileout;
		    my $res = move("$filein","$fileout");
			  if ($res==1) {
				  if (-e $fileout) {
		        print "$file to upload...\n";
			      my $cmd = "$upload \"$fileout\"";
			      $res = system($cmd);
				    if ($res==0) {
				      print "$cmd successfully started\n";
				      unlink $fileout if -e $fileout;
				    } else {
				      print "$cmd generated an ERROR\n";
						}
					} else {
					   print "could not move $filein to $fileout\n"; 
				  }
				} else {
				  print "file $filein proably locked\n";
				}
			}
			sleep $break;
		}
	}
	sleep $break
}




sub checkWindowsLinux {
  my @vars = @INC;
  my $vars = join("",@vars);
	my $poswin = index($vars,"\\");
	my $poslinux = index($vars,"/");
	my $backspace = "/";
	$backspace = "\\" if $poswin>$poslinux;
	return $backspace;
}



