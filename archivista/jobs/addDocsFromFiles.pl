#!/usr/bin/perl

=head1 addDocsFromFiles.pl -> add Docs to archivista db from input folder

  (c) v1.0 - 23.04.2006 by Archivista GmbH, Rijad Nuridini

  Read Directory. (ARCHXXXX)
  foreach Directory. Read all Files.
  foreach File. Decode Name -> AkteNr and Seitennr and Typ.
  foreach value in hash. insert into archiv.

  Typ:
      0 = BMP/ZIP
      1 = JPEG
      2 = PNG
      3 = TIFF
	
	 ATANTION. the Database must exist or else their's gonna be an error.
=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my @dbs = ("kirche"); # databases we need to add images
my $path = "/home/data/archivista/images/"; # path where the images are
#my $path = "/home/rijad/kirche/kirche/"; # path where the images are
my $dbh;


if ($dbh=MySQLOpen()) {
  # coonection is ok
  foreach my $db (@dbs) {
    my %phash;
    my $input = "$path$db/output";
    my $dir = getDirectorys("$input");
    foreach my $dir (@$dir){
      next if $dir =~ /^\.(.+)?/;
      next if $dir !~ /arch(\d{4})/i;
      my $ordnr = $1;
      $ordnr =~ s/^0+//;
      my $files = getFiles("$input/$dir");
      foreach (@$files){
        getInfo($_,\%phash);
      }
      insertDoc($dbh,\%phash,$ordnr,$db);
    }
  }
}

################################################################################

=head2 \@directorys getDirectorys ( $pathtodir )

=cut

################################################################################
sub getDirectorys {
################################################################################
  my $dir = shift;
  opendir(DIN,$dir);
  my @output = readdir(DIN);
  closedir(DIN);
  return \@output;
}

###############################################################################

=head2 \@files getFiles ( $dir )

  Returns all Files that beginn with an a followed by an mix of zeros and 
	alphabets then a point and anything else.

	example:
	  a000bc0b.png

=cut

###############################################################################
sub getFiles {
###############################################################################
  my $dir = shift;
  my @output;
  opendir(DIN,$dir);
  my @files = readdir(DIN);
  closedir(DIN);
  foreach (@files){
    push(@output,$_) if $_ =~ /^a[0|a-z]{7}\..+$/;
  }
  return \@output;
}

################################################################################

=head2 void getInfo ( $fname, \%phash )

  Saves The Infos of the File into an Hash. The Infos are Document-Number and
	the Number of Pages. The first 5 chars after the a are the Document-Number The
	2 Chars after that are the Number of the Page. This Number of Pages and the
	Typ of the Files will be saved in an Array and then save in the hash with the
	Document-Number as a Key.

=cut

################################################################################
sub getInfo {
################################################################################
  my $fname = shift;
  my $phash = shift;
  my @values;
  my %tem;
  my $typ;

  $fname =~ /^a(.{5})(.{2})\.(.+)$/;

  my $aktnr = decode($1);
  my $seitnr = decode($2);

  $typ = 0 if $3 =~ /[B|b][M|m][P|p]/i;
  $typ = 1 if $3 =~ /[J|j][P|p]([E|e])?[G|g]/i;
  $typ = 2 if $3 =~ /[P|p][N|n][G|g]/i;
  $typ = 3 if $3 =~ /[T|t][I|i][F|f]([F|f])?/i;

  $values[0] = $seitnr;
  $values[1] = $typ;
  $phash->{$aktnr} = \@values;

}

################################################################################

=head2 $res decode ( $fname )

  Decodes the Filename and returns the Int Value of it. The Programm calls the
	decode Function sepratly for the Document-Number and for the PageNumber

	example:
	  a0000b0b.png  Document-Number: 1 and PageNumber: 1

=cut

################################################################################
sub decode {
################################################################################
  my @value = split("",shift);
  my $res = 0;
  my $exp = 0;
  foreach my $val (reverse @value){
    next if $val eq 0;
    $val = ord($val) - 97;
    $res += $val * 26**$exp;
    $exp++;
  }
  return $res;
}

###############################################################################

=head2 void insertDoc ( $dbh, \%phash, $ordnr ,$db )

  Foreach Key (Document-Number) in the Hash it inserts an Row into the Database
	$db .

=cut

###############################################################################
sub insertDoc {
###############################################################################
  my $dbh = shift;
  my $phash = shift;
  my $ordnr = shift;
	my $db = shift;
  foreach my $aktnr (keys %$phash){
    my $seiten = $phash->{$aktnr}->[0];
    my $typ = $phash->{$aktnr}->[1];
    my $sql = "insert into $db.archiv(Ordner,Akte,Laufnummer,Seiten,ArchivArt)"
		        . "values($ordnr,$aktnr,$aktnr,$seiten,$typ)";
    $dbh->do($sql);
  }
}

