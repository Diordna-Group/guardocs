#!/usr/bin/perl

=head1 avimpexport.pl, (c) 4.8.2007 by Archivista GmbH, Urs Pfister

Skript does import and export documents from archivista databases
The values are:

$mode, $db, $dir, $range

=cut

use lib qw (/home/cvs/archivista/jobs);
use strict;
use DBI;
use Archivista::Config;
#use lib qw(/home/cvs/archivista/jobs/im2/objdir/api/);
use ExactImage;
use AVJobs;

my $mode = shift;
my $db1 = shift;
my $dir = shift;
my $val = shift;
my $out = "/mnt/usbdisk/pdf";
$out=$dir if $dir ne "";
my $path = "$out/"; 
my $file = "export.av5";
my $ds = "/"; # ATTENTION: Linux (/) or Windows (\\)

my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pw = $config->get("MYSQL_PWD");
$db1=$db if $db1 eq "";

# even if we have no password to connect, we need a value
$pw = "" if $pw eq "''";
$user = "SYSOP" if $user eq "archivista";
my $dbh=MySQLOpen($host,$db1,$user,$pw);
if ($dbh) {
  if (checkDatabase($dbh,$db1,1)) {
    exportdb($dbh,$val,$path,$file) if $mode eq "exportdb";
		if (HostIsSlave($dbh)==0) {
      importdb($dbh,$host,$db1,$user,$pw,$path,$file) if $mode eq "importdb";
		}
  }    
	MySQLClose($dbh);
}






=head1 exportdb($dbh,$range,$path,$file)

export a document range to a path

=cut

sub exportdb {
  my $dbh = shift;
  my $range = shift;
  my $path = shift;
  my $file = shift;
  my ($pa,@a,$sql,$sql1,$message,@fields,$pfields,$ext,$enr);
	my ($nr,$maxfld,$notiz,$fname,$z,$first,$typ);

  emptypath($path);
  $pfields=getFields($dbh,"archiv");
  @fields = @$pfields;

  $first=1;
  $nr=0;
	# read all fields until Laufnummer
  for($nr=0;$nr<100;$nr++) {
    $z.=$fields[$nr]->{name}."\t";
    $notiz=$nr if $fields[$nr]->{name} eq "Notiz";
    $maxfld=$nr;
    $nr=100 if $fields[$nr]->{name} eq "Laufnummer";
  }
  $z.="\r\n";
	
	# get the InputExtension
  for($nr=0;$nr<100;$nr++) {
		if ($fields[$nr]->{name} eq "ArchivArt") {
      $enr=$nr;
			$nr=100;
		}
	}

	$sql = "select * from archiv where (Gesperrt='' or Gesperrt is null) ";
	$sql .=sqlrange($val) . " order by Laufnummer asc";

  my $st = $dbh->prepare($sql);
  my $r = $st->execute;
  while (my @r=$st->fetchrow_array) {
	  if ($first==1) {
  	  $fname="$path$file";
      open(FOUT,">>$fname");
      print FOUT $z;
			$first=0;
		}
			
    # gets the current record for export
    $z="";
    for (my $c=0;$c<=$maxfld;$c++) {
       my $val=$r[$c];
       my $typ=$fields[$c]->{type};
       $z.=exportformatvalue($val,$typ);     
    }
    my $akte=$r[$maxfld];
    my $seiten=$r[3];
		# the imput file format is stored 
    my $art=$r[$enr];
		$ext="TIF";
		$ext="JPG" if $art==3;
		$ext="PNG" if $art==2;
    # now export behind the values all images
    $z.=exportfiles($dbh,$path,$akte,$seiten,$ext);
    $z.="\r\n";
    print "$z";
    print FOUT $z;
  }
  close(FOUT) if $first==0;

  $message = "Document(s) $val exported";
  logit($message);
}






=head1 exportfiles ($dbh, $pfad, $akte, $seiten, $typ (JPG/TIF)
 
does export all images of one document

=cut

sub exportfiles {
  my $dbh = shift;
  my $pfad = shift;
  my $akte = shift;
  my $seiten = shift;
  my $typ = shift;
  my $pfadname;
  my $fname;
  my $out;
	my $sql1 = "select Ordner,Archiviert from archiv where Laufnummer=$akte";
	my ($ordner,$arch) = $dbh->selectrow_array($sql1);
  for(my $c=1;$c<=$seiten;$c++) {
    my $seite=$akte*1000+$c;
    my $pblob=getBlobFile($dbh,"BildInput",$seite,$ordner,$arch);
		if ($$pblob ne "") {
      $fname="$akte"."_"."$c\.$typ";
      $out.="$fname;";
      $pfadname="$pfad$fname";
      open(FOUT1,">$pfadname");
      binmode(FOUT1);
      print FOUT1 $$pblob;
      close(FOUT1);
    } else {
      $out.=";";
    }
  }
  return $out;
}






=head1 importdb($dbh,$host,$db,$user,$pw,$path,$file)

import documents to an archivista db

=cut

sub importdb {
  my $dbh = shift;
	my $host = shift;
  my $db1 = shift;
	my $user = shift;
	my $pw = shift;
  my $path = shift;
  my $file = shift;
  my ($pa,@a,$sql,$sql1,$message,@fields,$pfields,$nr,$maxfld,$notiz,$fname,$z);

  # get back all fields
  $pfields=getFields($dbh,"archiv");
  @fields = @$pfields;

  my $pfadname="$path$file";
  if (-e $pfadname) {
    print "$pfadname found!\n";
    # import file is ok
    open(FIN,$pfadname);
    my @r=<FIN>;
    close(FIN);
  
    # remove all \r -> problem of std archivista export file
    $nr=0;
    foreach(@r) {
      my $l=$_;
      $l=~tr/\r//;
      $r[$nr]=$l;
      $nr++;
    }

    # remove first line and get position of Laufnummer
    my $f=shift @r;
    my @f=split("\t",$f);
    $nr=0; 
    for(my $c=0;$c<100;$c++) {
      if ($f[$c] eq "Laufnummer") {
        $maxfld=$c;
        print "Archivista file format checked - is ok\n";
        $nr=100;
      }
    }

    # now process all records
    foreach(@r) {
      my $sql;
      my @n = split("\t",$_);

      # create an sql command with all fields (but not with Laufnummer)
      for($nr=0;$nr<$maxfld;$nr++) {
        my $val=$n[$nr];
        my $feld=$f[$nr];
        if ($val ne "") {
          # there is a value
          my $nr1=0;
          foreach (@fields) {
            if ($fields[$nr1]->{name} eq $feld) {
						  next if $feld eq "EDVName";
              my $typ=$fields[$nr1]->{type};
              my $size=$fields[$nr1]->{size};
              $sql.=importformatvalue($dbh,$sql,$val,$feld,$typ,$size);
            }
            $nr1++;
          }
        }
      }
    
      # now import the images to the database
      $sql.=", Gesperrt='importdb'";
      $sql="insert into archiv set ".$sql if $sql ne "";
      my $res=$dbh->do($sql);
      if ($res) {
        my @lr=$dbh->selectrow_array("select last_insert_id()");
        my $lrow=$lr[0];
        if ($lrow>0) {
          my $ext=importfiles($dbh,$host,$db1,$user,$pw,
					                    $path,$lrow,$n[3],$n[$maxfld+1]);
					my $erfasst=0;
					$erfasst=1 if $n[3]>0; # if pages set it to Erfasst=1
          $sql="update archiv set Erfasst=$erfasst,".
					     "Archiviert=0,Akte=$lrow,Gesperrt='',".
               "BildInput=1,BildInputExt='$ext' where Laufnummer=$lrow";
          $dbh->do($sql);
        }
      }
    }
  }
  
  # remove the old import files
  # emptypath($path);
  $message = "Document(s) $val imported";
  logit($message);
}







=head1 importfiles ($dbh,$path,$akte,$seiten,$files)

imports images to the table archivbilder

=cut

sub importfiles {
  my $dbh = shift;
	my $host = shift;
  my $db1 = shift;
	my $user = shift;
	my $pw = shift;
  my $path = shift;
  my $akte = shift;
  my $seiten = shift;
  my $files = shift;

  my ($ext,$maxseiten,$emptypage,$archivart);
  my @f=split(";",$files);
  for(my $c=0;$c<$seiten;$c++) {
	  # we add a page
    my $f1=$f[$c];
    if ($f1 ne "") {
      my $f2="$path$f1";
			if (-e lc($f2)) {
			  # the file comes with lower case
				$f2=lc($f2);
				$f1=uc($f1);
			}
      if (-e $f2) {
        if ($ext eq "") {
          $f1 =~ /(.*)?(\.)(JPG|TIF)$/;
          $ext=$3 if ($3 eq "JPG" or $3 eq "TIF");
        }

        open(FIN,"$f2");
        binmode(FIN);
        my @f3=<FIN>;
        close(FIN);
        my $bild=join("",@f3);
        my $bild1=$dbh->quote($bild);
        if ($bild ne "") {
	        $maxseiten++;
          my $seite=$akte*1000+$maxseiten;
          my $sql="insert into archivbilder set Seite=$seite,BildInput=$bild1";
          $dbh->do($sql);
					$bild1="";
          my $img = ExactImage::newImage();
          ExactImage::decodeImage($img,$bild);
		      my $bit = ExactImage::imageColorspace($img);
					my $sc = getScanDefByNumber($dbh,$db1); 
          createThumbsAndSave($dbh,$db1,$dbh,$img,$bit,$akte,$seite,$sc,$bit);
					ExactImage::deleteImage($img);
        }
			}
    } else {
      $c=$seiten+1;
    }
  }
  addLogEntryImport($dbh,$host,$db1,$user,$pw,$akte,$seiten,'imp');
  return $ext;
}


