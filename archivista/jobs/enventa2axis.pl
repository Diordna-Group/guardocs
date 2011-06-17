#!/usr/bin/perl

=head1 enventa2axis.pl (c) 16.12.2010 v1.0 by Archivista GmbH, Urs Pfister

Reads an pdf file, extracts the meta keys and does send it to an axis file

=cut

use strict;
use File::Copy;
use File::Temp "tempfile";
use File::Basename "basename";
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;

my $dir = "/home/data/archivista/ftp"; # destination path
my $tdir = "/home/data/archivista/tmp/"; # temp dir for text
my $ds = '/'; # Unix=/, Windows=\
my $file = shift; # get the file name (incl. path)
my $fpdf = "";
if (-e $file) {
  # file does exist
  my ($fname,$db) = getFileDB($file); # get the desired file name and db
	my ($fh, $ftxtin)  = tempfile("$tdir/enventa-XXXX");
	my $cmd = "pdftotext $file $ftxtin";
	my $res = system($cmd);
	close($fh);
	my $content = "";
	readFile2($ftxtin,\$content,1);
	my $fields = "";
	$content =~ /(@@)(.*)(@@)/;
	if ($1 eq "@@" && $2 ne "" && $3 eq "@@") {
	  my @parts = split(/@@.*?@@/,$2);
		foreach my $line (@parts) {
		  my @parts1 = split(':',$line);
			my $field = shift @parts1;
			my $val = join(':',@parts1);
			$val = escape($val);
			$fields .= ":" if $fields ne "";
			$fields .= "$field=$val";
		}
	}
	logit("enventa=>$fields");
  $fpdf = $file;
  my @parts = split(/\//,$file);
	my $fpdf = pop @parts;
	$fname = $fpdf;
  my $fout = "$dir$ds$fpdf";
  foreach (my $c=0;$c<100;$c++) {
	  last if (!-e $fout); # check for a unique file name
  	$fname=TimeStamp().'.pdf';
    $fout = "$dir$ds$fname";
  }
  if (!-e $fout) {
	  # if in destination dir the file is not available, just move it
    move($file,$fout);
    my $pinfo = getInfos("$dir$ds",$fname,$db);
		$$pinfo{Fields} = $fields if $fields ne "";
		$$pinfo{ImportSource} = "1"; # we don't want an OCR text recognition
    # create axis-file from the infos and delete the csv-file
    createAXIS($pinfo,$dir); # create axis information
	}
}



=head2 ($fname,$db)=getFileDB($file)

Gives back the filename and the database

=cut

sub getFileDB {
  my $file = shift;
  my @parts = split($ds,$file);
  my $fname = pop @parts;
  my $db = pop @parts;
  if ($db eq "enventa") {
    my $db1 = pop @parts;
		if ($db eq "archivista") {
  	  $db = $db1;
		} else {
		  $db = "archivista";
		}
  }
	return ($fname,$db);
}



=head2 \%infos=getInfos($dir,$file,$db)

Extract some meta information out of pdf file

=cut

sub getInfos {
  my $dir = shift;
  my $file = shift;
	my $db = shift;
  my %info;
  my $line = getIdentify("$dir$file");
  my @lines = split("\n",$line);
  my @temp = split(" ",$lines[0]);
  $file =~ s/\..*/\.pdf/g;
  #$file =~ s/-//g;
  $info{'File name'}="$dir$file";
  $file =~ s/\..*//g;
  $info{'Date'}=$file;
  $info{'Destination'}=$db; # desired database
  $info{'Paper size'}="A4";
  $info{'Number of pages'}=$#lines + 1;
  ($info{'Width'},$info{'Height'})=split('x',$temp[2]);
	# correction from points to pixels
	$info{Width} = int $info{Width} * 4.166;
	$info{Height} = int $info{Height} * 4.166;
  $info{'X Resolution (DPI)'}=300;
  $info{'Y Resolution (DPI)'}=300;
	#always use 1 bit images
  $info{'Bits per pixel'}=1;
  $info{'Format'}=$temp[1];
  if($info{'Height'} > $info{'Width'}){
    $info{'Paper Orientation'}='Portrait';
  } 
  else {
    $info{'Paper Orientation'}='Landscape';
  }
  return \%info;
}



=head2 String getIdentify( $dir,$file )

Returns the Information of identify $file.

=cut

sub getIdentify {
  my $file = shift;
  my $result;
  my $system = "identify -ping \"$file\"";
  $result = `$system`;
  return $result;
}



=head2 void createAXIS( $phash,$dir )

Writes an Index-File like AXIS for our PDF-File.

=cut

sub createAXIS {
  my $phash = shift;
  my $outfile = $phash->{'File name'};
  $outfile =~ s/\.pdf/\.txt/g;
  open(FOUT,">$outfile");
  binmode(FOUT);
  foreach my $key (keys %$phash){
    print FOUT "$key"," "x(21-length($key)),"= ",$phash->{"$key"},"\n";
  }
  print FOUT "NonAxisFile"," "x9,"= 1\n";
  print FOUT "NoOCRfromCUPS"," "x9,"= 1\n";
  close(FOUT);
}

