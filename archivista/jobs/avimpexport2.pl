#!/usr/bin/perl

=head1 avimpexport.pl, (c) 4.8.2007 by Archivista GmbH, Urs Pfister

Skript does import and export documents from archivista databases
The values are:

$mode, $db, $dir, $range

=cut

use lib qw (/home/cvs/archivista/jobs);
use strict;
use File::Copy;
use DBI;
use Archivista::Config;
#use lib qw(/home/cvs/archivista/jobs/im2/objdir/api/);
use ExactImage;
use AVJobs;

my $mode = shift;
my $db1 = shift;
my $dir = shift;
my $val = shift;

my $out = "/mnt/usbdisk/transfer";
$out=$dir if $dir ne "";
$out =~ s/\/$//;
my $path = "$out/"; # static variables 
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
	  if (HostIsSlave($dbh)==0) {
		  my @files = <$path*.av?>;
			if ($files[0] eq "") {
		    @files = <$path*.AV?>;
			}
			if ($files[0] ne "") {
			  $file=$files[0];
				@files = split("\/",$file);
				$file = pop @files;
			}
      importdb($dbh,$host,$db1,$user,$pw,$path,$file) if $mode eq "importdb2";
		}
    exportdb($dbh,$db1,$val,$path,$file) if $mode eq "exportdb2";
  }    
  MySQLClose($dbh);
}






=head1 exportdb($dbh,$range,$path,$file)

export a document range to a path

=cut

sub exportdb {
  my $dbh = shift;
	my $db1 = shift;
  my $range = shift;
  my $path = shift;
  my $file = shift;
  my ($pa,@a,$sql,$sql1,$message,@fields,$pfields,$ext,$enr,$qnr);
	my ($nr,$maxfld,$notiz,$fname,$z,$first,$typ,$quelle);

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
  $z.="NotizRTF\t\r\n";
	
	# get the InputExtension
  for($nr=0;$nr<100;$nr++) {
	  if ($fields[$nr]->{name} eq "ArchivArt") {
		  $enr=$nr;
		} elsif ($fields[$nr]->{name} eq "QuelleExt") {
		  $qnr=$nr;
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
		$quelle=$r[$qnr];
		$quelle="pdf" if $quelle eq "";
    # now export behind the values all images
    $z.=exportfiles($dbh,$path,$akte,$seiten,$ext,$quelle);
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
	my $quelle = shift;
  my $pfadname;
  my $fname;
  my $out="\t";
	my $sql1 = "select Ordner,Archiviert from archiv where Laufnummer=$akte";
	my ($ordner,$arch) = $dbh->selectrow_array($sql1);
  my @sources;
  for(my $c=1;$c<=$seiten;$c++) {
    my $seite=$akte*1000+$c;
    my $pblob=getBlobFile($dbh,"BildInput",$seite,$ordner,$arch);
    if ($$pblob ne "") {
      $fname="$akte"."_"."$c\.$typ";
			my $fname1="Z:\\transfer\\".$fname;
      $out.="$fname1;";
      $pfadname="$pfad$fname";
      open(FOUT1,">$pfadname");
      binmode(FOUT1);
      print FOUT1 $$pblob;
      close(FOUT1);
      $pblob=getBlobFile($dbh,"Quelle",$seite,$ordner,$arch);
			if ($$pblob ne "") {
        $fname="$akte"."_"."$c\.$quelle";
        $pfadname="$pfad$fname";
        open(FOUT1,">$pfadname");
        binmode(FOUT1);
        print FOUT1 $$pblob;
        close(FOUT1);
				push @sources,$pfadname;
			}
      $pblob=getBlobFile($dbh,"BildA",$seite,$ordner,$arch);
			if ($$pblob ne "") {
        $fname="$akte"."_"."$c\.zip";
        $pfadname="$pfad$fname";
        open(FOUT1,">$pfadname");
        binmode(FOUT1);
        print FOUT1 $$pblob;
        close(FOUT1);
			}
	    my $sql = "select Text from archivseiten where Seite = $seite";
      my @r=$dbh->selectrow_array($sql);
      if ($r[0] ne "") {
        $fname="$akte"."_"."$c\.TXT";
        $pfadname="$pfad$fname";
        open(FOUT1,">$pfadname");
        binmode(FOUT1);
        print FOUT1 $r[0];
        close(FOUT1);   
		  }
    } else {
      $out.=";";
    }
  }
  if ($sources[0] ne "") {
    my $pdf1="/tmp/all.pdf";
    my $dopdf="pdftk ".join(" ",@sources)." output $pdf1";
    system("$dopdf");
		foreach (@sources) {
		  my $file = $_;
		  unlink $file if -e $file;
		}
		move($pdf1,$sources[0]);
	}
  return $out;
}






=head1 importdb($dbh,$host,$db,$user,$pw,$path,$file)

import documents to an archivista db

=cut

sub importdb {
  my $dbh = shift;
	my $host = shift;
  my $db = shift;
	my $user = shift;
	my $pw = shift;
  my $path = shift;
  my $file = shift;

  my ($pa,@a,$sql,$sql1,$message,@fields,$pfields,$nr);
	my ($records,$maxfld,$notiz,$fname,$z);

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
        logit("Archivista file format checked - is ok");
        $nr=100;
      }
    }

    # now process all records
		$records = 0;
    foreach(@r) {
		  $records++;
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
          my $ext=importfiles($dbh,$host,$db,$user,$pw,$path,
					                    $lrow,$n[3],$n[$maxfld+2]);
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
  $message = "$records Document(s) imported";
  logit($message);
}






=head1 importfiles ($dbh,$path,$akte,$seiten,$files)

imports images to the table archivbilder

=cut

sub importfiles {
  my $dbh = shift;
	my $host = shift;
  my $db = shift;
	my $user = shift;
	my $pw = shift;
  my $path = shift;
  my $akte = shift;
  my $seiten = shift;
  my $files = shift;

  my ($ext,$maxseiten,$archivart,$source,$bild,$zip,$sext);
	my $ocrdone = 0;
  my @f=split(";",$files);
  for(my $c=0;$c<$seiten;$c++) {
	  # we add a page
    my $f1=$f[$c];
    if ($f1 ne "") {
      my $f2="$path$f1";
		  # change the path to UNIX
			$f1=~s/\\/\//g;
			# split all subdirectories
			my @f1=split('/',$f1);
			my ($f1a,$f1b);
			$f1a = pop @f1;
			$f1b = pop @f1;
			# create the file name
			$f2=$path;
			$f2.=$f1b.'/' if $f1b ne "" && $f1b ne "transfer";
			$f2.=$f1a;
			$f1=$f1a;

   		if (-e lc($f2)) {
			  # the file comes with lower case
				$f2=lc($f2);
				$f1=uc($f1);
			}

      if (-e $f2) {
        if ($ext eq "") {
          $f1 =~ /(.*)?(\.)(JPG|TIF|PNG)$/;
          $ext=$3 if ($3 eq "JPG" or $3 eq "TIF" or $3 eq "PNG");
        }
 
        if ($c==0) {
				  # add source file
				  my (@f4,$f3a,$f3b);
          $f3a=$f2;
					$f3a=~/(.*)(\..*)$/;
					$f3a=$1;
					$f3a=substr($f3a,0,length($f3a)-1).'A.*';
					$f3b=`ls $f3a`;
					chomp $f3b;
				  if (-e $f3b) {
					  $f3b=~/(\.)(.*?)$/;
						$sext=uc($2);
            readFile2($f3b,\$source);
					}
				}
				readFile2($f2,\$bild);
        if ($bild ne "") {
	        $maxseiten++;
          my $seite=$akte*1000+$maxseiten;
          my $sql="insert into archivbilder set ".
				          "Seite=$seite,BildInput=".$dbh->quote($bild);
					if ($source ne "") {
					  # we got a source file
					  $sql.=",Quelle=".$dbh->quote($source);
					  $source="";
					}
          my $fzip = $f2;
					$fzip =~ s/(\.[a-zA-Z])$/.zip/;
					if (-e $fzip) {
            readFile2($fzip,\$zip);
						if ($zip ne "") {
					    $sql.=",BildA=".$dbh->quote($zip);
							$zip="";
						}
					}
          $dbh->do($sql);
          my $img = ExactImage::newImage();
          ExactImage::decodeImage($img,$bild);
		      my $bit = ExactImage::imageColorspace($img);
					my $sc = getScanDefByNumber($dbh,$db1); 
          createThumbsAndSave($dbh,$db1,$dbh,$img,$bit,$akte,$seite,$sc,$bit);
					ExactImage::deleteImage($img);
					$bild="";
        }
				my @parts = split("\/",$f2);
				my $fname = pop @parts;
				my $text = "";
				$fname =~ s/(\.[a-z]{3,3}$)/.txt/;
				$fname =~ s/(\.[A-Z]{3,3}$)/.TXT/;
				$fname =~ s/(^[a-z]{1,1})/t/;
				$fname =~ s/(^[A-Z]{1,1})/T/;
				push @parts, $fname;
				$fname = join("\/",@parts);
				if (-e $fname) {
				  $ocrdone=4;
	        open(FIN,"$fname");
          binmode(FIN);
          my @f3=<FIN>;
          close(FIN);
          $text=join("",@f3);
				}
        my $seite=$akte*1000+$maxseiten;
        my $text1=$dbh->quote($text);
				my $sql = "select Seite from archivseiten where Seite=$seite";
				my @row = $dbh->selectrow_array($sql);
				if ($row[0]>0) {
          $sql="update archivseiten set Text=$text1 where Seite=$seite";
				} else {
          $sql="insert into archivseiten set Seite=$seite,Text=$text1";
				}
 			  $dbh->do($sql);
			}
    } else {
      $c=$seiten+1;
    }
  }
  addLogEntryImport($dbh,$host,$db1,$user,$pw,$akte,$seiten,'imp',0,$ocrdone);
  if ($sext ne "") {
	  $sext=$dbh->quote($sext);
    my $sql="update archiv set QuelleIntern=1,QuelleExt=$sext ".
		     "where Laufnummer=$akte";
	  $dbh->do($sql);
		$sext="";
	}
	if ($ext eq "PNG") {
	  my $sql="update archiv set ArchivArt=2,BildInputExt='PNG' ".
		        "where Laufnummer=$akte";
		$dbh->do($sql);
	}
  return $ext;
}











