#!/usr/bin/perl

=head1 addImages.pl -> add images to archivista db from output folders

(c) v2.0 - 20.3.2007 by Archivista GmbH, Urs Pfister

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
#use lib qw(/home/cvs/archivista/jobs/im2/objdir/api/);
use ExactImage;
use DBI;

my $db = "avgmbh"; # databases we need to add images
# path where the images are
my $path = "/home/data/archivista/images/";
my $begnr = 8882; # first doc.
my $endnr = 12600; # last doc.
my $lockuser = "addimg"; # Lock user for processing the files
my $dbh;
my %val;
$val{dirsep}="/";

if ($dbh=MySQLOpen("localhost",$db,"root","archivista")) {
  # coonection is ok, so add the images to the database
  addImagesFromFiles($dbh,$db,$lockuser,$path,$begnr,$endnr);
}






=head2 addImagesFromFiles($dbh,$db1,$pfad1,$aktnr,$endnr,$bfact)

Does add all output images from the database db1

=cut

sub addImagesFromFiles {
  my $dbh      = shift;
  my $db1      = shift;
  my $lockuser = shift;
  my $pfad1    = shift;
  my $aktnr    = shift;
  my $endnr    = shift;

  $pfad1 .= $db1.$val{dirsep};
	my $count=1;
  while ( $aktnr <= $endnr ) {
		my $sql = "select Laufnummer,Seiten,Ordner,ArchivArt,Archiviert ".
		          "from $db1.archiv where Laufnummer>=$aktnr limit 1";
    my ($akte,$seiten,$ordner,$art,$output)=$dbh->selectrow_array($sql);
    if ($akte>0) {
      # get the final path and the ext of the image file
      my ($pfad,$ext) = addImagesPfadExt($pfad1,$ordner,$art,$output,$akte);
      for ( my $c = 1 ; $c <= $seiten ; $c++ ) {
        my $file = addImageFromFileName($pfad,"A",$akte,$c,$ext);
				my $pimg = readImageFromFileName($file,$akte,$c,$art,$output);
        addImageToDB($dbh,$db1,$akte,$c,$ext,$pimg);
			}
      $aktnr = $akte; # adjust the current doc to the counter
			$count++;
			print "$count docs added in $db1\n" if $count % 1000 == 0;
    } else {
      $aktnr = $endnr if $akte == 0; # no doc was found, stop process
    }
    $aktnr++; # go to the next document
  }
  $dbh->disconnect();
}






=head1 $pimg = readImageFromFileName($file,$akte,$c,$art,$output)

Read an image from a file and give it back as pointer

=cut

sub readImageFromFileName {
  my $file = shift;
	my $akte = shift;
	my $c = shift;
	my $art = shift;
	my $output = shift;
	my $cont = "";
  if ($art==0) {
	  my $ok;
    my $image = ExactImage::newImage();
	  if ($output==1) {
	    my $pw = $c+1000;
		  $pw = "A".$akte.$pw;
	    my $cont1 = `unzip -p -P$pw $file`;
		  $ok = ExactImage::decodeImage($image,$cont1);
	  } else {
		  $ok = ExactImage::decodeImageFile($image,$file);
	  }
		my $bit = ExactImage::imageColorspace($image);
		if ($ok) {
		  if ($bit ne "gray1") {
			  $cont = ExactImage::encodeImage($image,"tiff",0,"lzw");
			} else {
			  $cont = ExactImage::encodeImage($image,"tiff",100);
			}
		}
		ExactImage::deleteImage($image);
	} else {
    readFile($file,\$cont);
	}
	print "Doc done: $akte-$c\n";
	return \$cont;
}






=head2 addImageToDb($dbh,$db1,$akte,$c,$e1,$e2,$fs,$f1,$w1,$h1,$f2,$w2)

Stores the file(s) to the db and modifies the document according

=cut

sub addImageToDB {
  my $dbh   = shift;
  my $db1   = shift;
  my $akte  = shift;
  my $seite = shift;
  my $ext  = shift;
	my $pimg = shift;
	my $addit = 1;

  my ($sc,$sql,$sql1,$sql2,@row);
	print length($$pimg)."\n";
  $sql1 = $dbh->quote($$pimg);
	print length($sql1)."\n";
  # calculate the unique id
	my $sc = ($akte*1000)+$seite;
	$sql = "select Seite from archivbilder where Seite=$sc";
  @row = $dbh->selectrow_array($sql);
  if ($row[0]==0) {
    $sql = "insert into $db1.archivbilder set Seite=$sc,BildInput=$sql1";
  } else {
    $sql = "update $db1.archivbilder set BildInput=$sql1 where Seite=$sc";
  }
  $dbh->do($sql);
  if ( $seite == 1 ) {
    $sql2 = "BildInputExt='$ext',BildInput=1";
    $sql = "update $db1.archiv set $sql2 where Laufnummer=$akte";
    $dbh->do($sql);
  }
}






=head2 ($path,$ext)=addImagesPfadExt($pfad1,$ordner,$art)

Give back the whole folder and the extension of a document

=cut

sub addImagesPfadExt {
  my $pfad1 = shift;
  my $ordner = shift;
  my $art = shift;
	my $output = shift;
	my $akte = shift;
	my $ext = "";
	if ($output==1) {
    $pfad1 .= "output".$val{dirsep}.getArchivingFolderName($ordner);
	} else {
	  my $mod = $akte % 100;
		$pfad1 .= "input".$val{dirsep}."in".sprintf("%04d",$mod).$val{dirsep};
	}
  $ext = getArchivingExt($art,$output);
  return ($pfad1,$ext);
}






=head2 $pfadpart=getArchivingFolderPath($folder)

According folder number we calculate path part

=cut

sub getArchivingFolderName {
  my $ordner = shift;
  # folders are always in format (ARCH0001,ARCH0002..)
  my $pfad = "ARCH".sprintf("%04d",$ordner).$val{dirsep};
  return $pfad;
}






=head2 $ext=getArchivingExt($art,$zipped)

Give back the extension from the field value ArchivArt

=cut

sub getArchivingExt {
  my $art = shift;
  my $zipped = shift;
  my $ext = "JPG";
  $ext = "PNG" if $art == 2;
  $ext = "TIF" if $art == 1;
  if ($zipped) {
    $ext = "ZIP" if $art == 0;
  } else {
    $ext = "BMP" if $art == 0;
  }
  return $ext;
}






=head2 $file=addImageFromFileName($pfad,$mode,$akte,$seite,$ext)

Checks if the file is in the folder (incl. lower/upper case cases)

=cut

sub addImageFromFileName {
  my $pfad  = shift;
  my $mode  = shift;
  my $akte  = shift;
  my $seite = shift;
  my $ext   = shift;

  my $file1 = getFileNameNr( $akte, $seite, $mode ) . "\.";
  my $found = 1;
  if ( -e "$pfad$file1$ext" ) {
    # CAPITAL.EXT
  } else {
    $ext = lc($ext);
    if ( -e "$pfad$file1$ext" ) {
      # CAPITAL.ext
    } else {
      $ext  = uc($ext);
      $pfad = lc($pfad);
      $file1 = lc($file1);
      if ( -e "$pfad$file1$ext" ) {
        # capital.EXT
      } else {
        $ext = lc($ext);
        # if capital.ext also not here then the file is not ok
        $found = 0 if ( !-e "$pfad$file1$ext" );
      }
    }
  }
  my $file;
  $file = "$pfad$file1$ext";
  return $file;
}






=head2 getFileNameNr($document,$page,$mode)

Gives back a file name from a doc./page/mode
  
=cut

sub getFileNameNr {
  my $document  = shift;
  my $page = shift;
  my $mode = shift;
  my $t1 = getFileNameCalc( $document, 5 );
  my $t2 = getFileNameCalc( $page, 2 );
  $mode = "A" if ! defined $mode;
  my $fn=$mode . $t1 . $t2;
  return $fn;
}






=head2 $fnamepart=getFileNameCalc($input,$count)

Returns an archive filename.

=cut

sub getFileNameCalc {
  my ( $input, $count ) = @_;
  my ( $res, $res1, $t, $tcount );
  while ( $input != 0 ) {
    $res = $input % 26;
    $res1 = $res + 65;
    $t  = chr($res1) . $t;
    $input = $input - $res;
    $input = $input / 26;
  }
  $t = "0" x ( $count - length($t) ) . $t;
  return $t;
}






=head2 $dbh=MySQLOpen($host,$db,$user,$pw)

=head2 $dbh=MySQLOpen($host,$db,$user,$pw)

Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen {
  my $host = shift;
  my $db   = shift;
  my $user = shift;
  my $pw   = shift;
  my ( $ds, $dbh );
  $ds = "DBI:mysql:host=$host;database=$db";
  $dbh = DBI->connect($ds,$user,$pw,{PrintError=>1,RaiseError=>0});
  return $dbh;
}






=head2 readFile($file,\$memory)

Reads a file and stores its contents to a pointer (file must exist)

=cut

sub readFile {
  my $file    = shift;
  my $pmemory = shift;
  open( FIN, $file );
  binmode(FIN);
	$$pmemory = "";
	while(my $line = <FIN>) {
	  $$pmemory .= $line;
	}
  close(FIN);
}



