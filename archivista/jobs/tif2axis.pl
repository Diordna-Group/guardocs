#!/usr/bin/perl

=head1 cannon2axis.pl

Checks for tiff-files in ftp folder. If it does find a tiff,
it tries to create an pdf-file from the tiff and creates an axis-file

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;
my $file = shift;

my $dir = "/home/data/archivista/ftp";
my $ds = '/'; # Unix=/, Windows=\
# get infos from the csv-file and from the tiff-file
my $pinfo = getInfos($file);
# create pdf from tiff-file and delete tiff-file
tiff2pdf($file,$pinfo->{'File name'},$dir);
# create axis-file from the infos and delete the csv-file
createAXIS($pinfo,$file,$dir);
print "$file\n";
# finish the reset is done by axis2sane.pl






=head2 \%infos=getInfos($file)

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
  my $file = shift;
  my %info;
  my $line = getIdentify($file);
	my @parts = split('/',$file);
	$file = pop @parts;
	my $db = pop @parts;
	$db = "archivista" if $db eq "" || $db eq "tiff";
  my @lines = split("\n",$line);
  my @temp = split(" ",$lines[0]);
  my $nfname = getUser($file);
  $file =~ s/\.[a-zA-Z]{3,4}$/\.pdf/g;
  $nfname .= $file;
  $info{'File name'}=$nfname;
  $info{'Date'}=$file;
  $info{'Destination'}=$db;
  $info{'Paper size'}="A4";
  $info{'Number of pages'}=$#lines + 1;
  ($info{'Width'},$info{'Height'})=split('x',$temp[2]);
  $info{'X Resolution (DPI)'}=300;
  $info{'Y Resolution (DPI)'}=300;
	my $pos = 3; # in 32 bit edition, identify gives color position at pos 3
	$pos = 4 if check64bit==64; # in 64 bit, it is position 4
	my $pos1 = $pos+1;
  if($temp[$pos] eq 'DirectClass'){
    $info{'Bits per pixel'}=24;
  } elsif($temp[$pos] eq 'PseudoClass'){
    if($temp[$pos1] eq '256c'){
      $info{'Bits per pixel'}=8;
    } else{
      $info{'Bits per pixel'}=1;
    }
  } else {
    $info{'Bits per pixel'}=1;
  }
  $info{'Format'}=$temp[1];
  if($info{'Height'} > $info{'Width'}){
    $info{'Paper Orientation'}='Portrait';
  } else {
    $info{'Paper Orientation'}='Landscape';
  }
  return \%info;
}






=head2 String getIdentify($file)

Returns the Information of identify $file.

=cut

sub getIdentify{
  my $file = shift;
  my $result;
  my $system = "identify -ping \"$file\"";
  $result = `$system`;
  return $result;
}






=head2 String getUser($file)

Give back the user we want to send the file (default is Admin-)

=cut

sub getUser{
  my $file = shift;
  my $user;
  $user = "";
  return $user;
}






=head2 void tiff2pdf ( $tiffile,$pdffile,$dir,$dirc )

Makes a PDF-File from the Tiff-File. And than Removes the Tiff-File.

=cut

sub tiff2pdf {
  my $tiffile = shift;
  my $pdffile = shift;
	my $dir = shift;
	my $opt = "";
	$opt =  "-r o -u i -x 1 -y 1" if check64bit()==64;
  my $system = "tiff2pdf $opt -o \"$dir/$pdffile\" \"$tiffile\"";
  system($system);
  unlink("$tiffile");
}






=head2 void createAXIS( $phash,$file,$dir )

Writes an Index-File like AXIS for our PDF-File. Deletes the old csv-File.

=cut

sub createAXIS{
  my $phash = shift;
  my $file = shift;
  my $dir = shift;
  $file =~ s/\..*/\.csv/g;
  my $outfile = $phash->{'File name'};
  $outfile =~ s/\.pdf/\.txt/g;
  open(FOUT,">$dir/$outfile");
  binmode(FOUT);
  foreach my $key (keys %$phash){
    print FOUT "$key"," "x(21-length($key)),"= ",$phash->{"$key"},"\n";
  }
  print FOUT "NonAxisFile"," "x9,"= 1\n";
  close(FOUT);
  unlink("$dir/$file");
}



