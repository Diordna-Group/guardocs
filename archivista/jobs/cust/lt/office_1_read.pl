#!/usr/bin/perl

=head1 readfiles.pl (c) 2009 by Archivista GmbH

Read all files from a path (incl. sub folders

=cut

use strict;

my @files = ();
my $dir = shift;
my $file = shift;
if ($dir eq "" || $file eq "") {
  print "Give in a) path you want to create a file structure and b) file.\n".
	      "After it you find a list in file (will be overwritten)\n".
	      "Example (path must be mounted): $0 /mnt/net files.txt\n\n";
	exit;
}

getFiles($dir,\@files);
open(FOUT,">$file");
foreach (@files) {
  print FOUT "$_\n";
}
close(FOUT);



=head1 getFiles($dir,$pfiles)

Read all files from a dir (incl. subfolders

=cut

sub getFiles {
  my $dir = shift;
	my $pfiles = shift;
	if (-d $dir) {
	  $dir .= "/" if substr($dir,-1,1) ne "/";
	  opendir(FIN,$dir);
		my @files = readdir(FIN);
		closedir(FIN);
		foreach (@files) {
		  my $file = $_;
		  next if $file eq "." or $file eq "..";
			next if index($file,".",0)==0;
			$file = $dir.$file;
			if (-d $file) {
			  getFiles($file,$pfiles);
			} else {
        push @$pfiles,$file;
			}
		}
	} else {
    push @$pfiles,$dir
	}
}


