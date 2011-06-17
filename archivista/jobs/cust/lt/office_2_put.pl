#!/usr/bin/perl

=head1 putfiles.pl (c) 2009 by Archivista GmbH

Copy all files from files.txt file into office folder

=cut

use strict;

use File::Copy;

my @extensions = ("doc",
                  "xls",
                  "png",
                  "tif",
                  "jpg",
                  "gif",
									"bmp",
									"ppt",
					        "pdf"); # put here (above) the extensions you want to import

my $nr=0;
my $done=0;
my $database = shift;
my $max = shift;
my $infile = shift;
my $outfile = shift;
if ($database eq "" || $max<=0 || !-e $infile || -e $outfile) {
	print "Plese give in the database name, maximum files you want to process,\n".
	      "the infile (files.txt from readfiles.pl) and the outfile (log.txt).\n\n".
	      "Usage: $0 database number infile outfile\n".
				"Example: $0 archivista 100 files.txt log.txt\n\n".
				"Hint: The following extensions will be included: ".
				join(" ",@extensions)."\n\n";
	exit;
}

open(FIN,$infile);
my @files = <FIN>;
close(FIN);
	
open(FOUT,">$outfile");
foreach (@files) {
  $nr++;
	my $file = $_;
	chomp $file;
	my @parts = split(/\./,$file);
	my $ext = pop @parts;
	$ext = lc($ext);
	my $found = 0;
	foreach my $ext2 (@extensions) { 
	  if ($ext eq $ext2) {
	    $done++;
	    print "$done--$nr--$file\n";
	    print FOUT "import--$done--$nr--$file\n";
		  my $out = "/home/data/archivista/ftp/office/$database/$done.$ext";
		  system("cp -p \"$file\" $out");
			$found=1;
			last;
		}
	}
	if ($found==0) {
	  print FOUT "not--$done--$nr--$file\n";
	}
	last if $done>=$max;
}

