#!/usr/bin/perl

=head1 xerox2axis.pl

Moves a given pdf file to the ftp folder and creates an axis file

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;
use File::Copy;

my $file1 = shift; # get the file name (XST)
my $filenoext = $file1;
$filenoext =~ s/(.*)(\.XST$)/$1/;
my $file = $filenoext.'.PDF';
my $file2 = $filenoext.'.pdf';

print "$file--$file1--$file2\n";


my $dir = "/home/data/archivista/ftp";

my $ds = '/'; # Unix=/, Windows=\
if (-e $file) {
  my ($fname,$db) = getFileDB($file2);
  my $fout = "$dir$ds$fname";
  foreach (my $c=0;$c<100;$c++) {
	  last if (!-e $fout);
  	$fname=TimeStamp().'.pdf';
    $fout = "$dir$ds$fname";
  }
  if (!-e $fout) {
    move($file,$fout);
  	$file=$fname;
    my $pinfo = getInfos("$dir$ds",$file,$db,$fname);
		my $pxrxinfo = getXRXFields($file1);
		my @fields;
		foreach my $key (keys %{$pxrxinfo}) {
		  my $field_name = $pxrxinfo->{$key}->{"MetaDataFieldName"};
		  my $field_value = $pxrxinfo->{$key}->{"MetaDataValue"};
			if ($field_name eq "UserID" || $field_name eq "Profiles") {
			  # get user and scan def (if available) directly 
			  $pinfo->{$field_name}=$field_value;
			} else {
			  $field_name = "Titel" if $field_name eq "Title";
			  $field_value=escape($field_value);
			  $pinfo->{"Fields"} .= ":" if $pinfo->{'Fields'} ne "";
			  $pinfo->{"Fields"} .= "$field_name=$field_value";
			}
		}
    # create axis-file from the infos and delete the csv-file
    createAXIS($pinfo,$fout);
    print "$file\n";
	}
  unlink($file1) if -e $file1;
}






sub getField {
  my $file = shift;
	my $field = shift;
	my $text = "";
	my $infos = getXRXFields($file);
	foreach my $key (keys %{$infos}) {
	    if ($infos->{$key}->{"MetaDataFieldName"} eq $field) {
			  return $infos->{$key}->{"MetaDataValue"};
			}
	}
}





=head2 \%infos = getXRXFields($file)

Returns the Infos in the xrx_dscrpt_metadata section from the Xerox File.

Structure:

$infos->{1}->{MetaDataFieldName}
$infos->{2}->{MetaDataValue}
....

=cut

sub getXRXFields {
  my $file = shift;
	my $text = "";
  my %infos;
  readFile($file,\$text);
  if ($text =~ /\[description xrx_dscrpt_metadata\](.+)end/s) {
    my $fields = $1;
    while ( $fields =~ /(\s\d\{.*?\}){1}/s) {
      $fields =~ s/(\s(\d)\{(.*?)\}){1}//s;
      my $id = $2;
      my $info = $3;
      my %tmp;
      foreach my $line (split("\n",$info)) {
			  if ($line =~ /^\s+\*?\s\w+\s(\w+)\s=\s(.+);$/) {
				  my $name = $1;
					my $value = $2;
          # Remove Quotes
          $value =~ s/^"//; 
					$value =~ s/"$//;
          $tmp{$name} = $value;
        }
      }
      $infos{$id} = \%tmp;
    }
  } else {
    %infos = {};
  }
  return \%infos;
}






=head2 ($fname,$db)=getFileDB($file)

Gives back the filename and the database

=cut

sub getFileDB {
  my $file = shift;
  my @parts = split($ds,$file);
  my $fname = pop @parts;
  my $db = pop @parts;
  if ($db eq "pdf") {
    my $db1 = pop @parts;
		if ($db1 eq "archivista") {
  	  $db = $db1;
		} else {
		  $db = "archivista";
		}
  }
	return ($fname,$db);
}






=head2 \%infos=getInfos( $dir,$file )

  Returns an Pointer to an Hash with the need Information.
  As that are: 

  File Name:         We get the FILE NAME from the perl script
                     so we don't need to parse it.
  Date:              The Name of the File is also the DATE when it was scanned.
  Destination:       If thier's an DESTINATION in the csv-file then we get that
                     else we send it to the default Database.
  Paper Size:        Default is A4 if their aren't other infos.
  Number of Pages:   We get the number of Pages from pdfinfo.
  Width:             We get the WIDTH from identify $file
  Height:            We get the HEIGHT from identify $file
  X/Y Resolution:    Default 300
  Bits per Pixel:    We get that info from identify it's 4th and 5th info
                     if the 4th is DirectClass -> 24 Bits
                     if the 4th is PseudoClass and the 5th is 256c -> 8 Bits
                 and if the 4th is PseudoClass and the 5th is 2c -> 1 Bits
  Format:            We allways get TIFF-files
  Profil:            We can't get this Info so it's empty
  Paper Orientation: If Height is larger than Width we have Portrait 
                                                      else Landscape

=cut

sub getInfos {
  my $dir = shift;
  my $file = shift;
	my $db = shift;
  my %info;
  my $line = getIdentify("$dir$file");
  my @lines = split("\n",$line);
	foreach (@lines) {
    my ($name,$val) = split(/\s{2,10}/,$_);
		if ($name eq "Pages:") {
      $info{'Number of pages'}=$val;
		} elsif ($name eq "Page size:") {
      my @temp = split(" ",$val);
      $info{'Width'}=$temp[0];
			$info{'Height'}=$temp[2];
		}
	}
  $info{'Format'}=1;	
  $info{'Bits per pixel'}=1;
	my $found = 0;
	my $tbase = "/tmp/$file";
  my $pages = $info{'Number of pages'};
	my $zeros = getZeros($pages);
	my $tfile = $tbase."-".sprintf($zeros,1).".ppm";
	unlink $tfile if -e $tfile;
	if (!-e $tfile) {
	  my $cmd = "pdftoppm -f 1 -l 1 $dir$file $tbase";
		system($cmd);
		if (-e $tfile) {
		  $cmd = "identify -ping $tfile";
			my $res = `$cmd`;
			my @res1 = split(" ",$res);
	    my $pos = 3; # in 32 bit edition, identify gives color position at pos 3
	    $pos = 4 if check64bit==64; # in 64 bit, it is position 4
	    my $pos1 = $pos+1;
	    if($res1[$pos] eq 'DirectClass'){
        $info{'Bits per pixel'}=24;
      } elsif($res1[$pos] eq 'PseudoClass'){
        $info{'Bits per pixel'}=8 if $res1[$pos1] eq '256c';
			}
	    unlink $tfile if -e $tfile;
    }
	}
  $info{'Format'}=3 if $info{'Bits per pixel'}!=1;
  $file =~ s/\.[a-zA-Z]{3,3}$/\.pdf/g;
  $info{'File name'}="$file";
  $info{'Date'}=$file;
  $info{'Destination'}=$db; # desired database
  $info{'Paper size'}="A4";
	# correction from points to pixels
	$info{Width} = int $info{Width} * 4.166;
	$info{Height} = int $info{Height} * 4.166;
  $info{'X Resolution (DPI)'}=300;
  $info{'Y Resolution (DPI)'}=300;
  if($info{'Height'} > $info{'Width'}){
    $info{'Paper Orientation'}='Portrait';
  } else {
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
  my $system = "pdfinfo \"$file\"";
  $result = `$system`;
  return $result;
}






=head2 void createAXIS( $phash,$dir )

Writes an Index-File like AXIS for our PDF-File.

=cut

sub createAXIS {
  my $phash = shift;
	my $outfile = shift;
  $outfile =~ s/\.pdf/\.txt/g;
  open(FOUT,">$outfile");
  binmode(FOUT);
  foreach my $key (keys %$phash){
    print FOUT "$key"," "x(21-length($key)),"= ",$phash->{"$key"},"\n";
  }
  print FOUT "NonAxisFile"," "x10,"= 1\n";
  close(FOUT);
}



