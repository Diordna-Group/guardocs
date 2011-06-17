#! /usr/bin/perl

use strict;
use File::Copy;

my $pathin = "/home/data/archivista/cust/laepp/cold";
my $pathout = "/home/data/archivista/ftp/axapta/laeppdb";
my $ds = "/";
my $max = 10000;
my $checkfile = "$pathin$ds"."bad";

if (-e $checkfile) {
  print "mount needed\m";
  system("/home/data/archivista/cust/laepp/mount1.sh");
}

if (-d $pathin && -d $pathout) {
  opendir(FIN,$pathin);
  my @a = readdir(FIN);
  closedir(FIN);

  my (@TXT,@PDF);
  foreach (@a) {
	  my $f = $_;
		if ($f ne "." && $f ne "..") {
      print "$_\n";
			if ($f =~ /(\.TXT)$/) {
			  push @TXT,$f;
			} elsif ($f =~ /(\.pdf)$/) {
				push @PDF,$f;
			}
		}
  }

  @TXT = sort @TXT;
	@PDF = sort @PDF;
  my $c=0;
	foreach (@PDF) {
	  $c++;
		last if $c>$max;
	  moveit($_);
	  print "$_\n";
	}
	
	$c=0;
  foreach (@TXT) {
	  $c++;
		last if $c>$max;
	  moveit($_);
    print "$_\n";
	}
}






sub moveit {
  my $file = shift;
	my $fin = "$pathin$ds$file";
	my $fout = "$pathout$ds$file";
	if (!-e $fout) {
	  print "$fin-->$fout\n";
	  move($fin,$fout);
	}
}
