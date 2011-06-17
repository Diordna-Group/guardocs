#!/usr/bin/perl

=head1 cups2axis.pl

Checks for pdf files in cups-pdf folder. If it does find a pdf,
it tries to move the file to the ftp folder and creates an axis file

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use AVJobs;

# get the next file from ftp dir
my $file=shift; # get the file to process
$file =~ s/.*\///;
if ($file) {
  # file was found, now check if it is not any longer in process
	my ($res,$file1,$file2) = CUPSwaitAndMove($file);
	if ($res) {
		# we now can work with the file, so get original ps name
		my ($res,$db,$defname) = CUPSgetPSFile($file,$file2);
		if ($res) {
      # file was sucessfully moved, so create the meta key file
      CUPSparseFile($file1,$file2,$db,$defname);
    }
	}
}


