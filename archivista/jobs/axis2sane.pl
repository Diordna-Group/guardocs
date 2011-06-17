#!/usr/bin/perl

=head1 axis2sane.pl

Prepare ftp scanned (axis,xerox,cups-pdf) files from a ftp source and 
adds the pages to the database with sane-client.pl. Script is called 
from sane-daemon.pl

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use AVJobs;

my %finfo; # store the information from an axis file
my $file=shift; 
if ($file) { 
  # if we got file, process it
	if (FTPparseFile($file,\%finfo)) {
		# split the pdf file into images
   	my $fout = FTPsplitFile(\%finfo);
		if ($fout) {
		  # add now the pages to the appropriate database
		  FTPaddPages($fout,\%finfo);
  	}
  }
}


