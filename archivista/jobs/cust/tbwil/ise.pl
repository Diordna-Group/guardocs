#!/usr/bin/perl

################################################# What it is

=head1 ise.pl --- (c) by Archivista GmbH, 18.5.2007
       
Check /mnt/net/Rechnungen for subfolders and create an axis file from all txt
files, after it move the files to the /home/data/archivista/ftp structure

=cut

use strict;
use DBI;
use lib qq(/home/cvs/archivista/apcl/Archivista);
use Archivista::Config;
use File::Copy;
my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pw = $config->get("MYSQL_PWD");
undef $config;


my $net = "/home/data/archivista/cust/tbwil";
my $mount = "$net/mount.sh";
my $pfad = "$net/net/";
my $pfad1 = "$net/net/Rechnungen/";
my $dbname = "archiv";
my $ext = '.txt';
my $out = "/home/data/archivista/ftp/";
my $backup = "$net/net/Rech\_save";
my $ds = "/";






=head2 Functionality

This script is responsible for barcode and ocr recognitions.

=cut

# open a database handler 
my $dbh=MySQLOpen($host,$db,$user,$pw);
if ($dbh) {
  print "connection ok\n";
  if (HostIsSlave($dbh)==0) {
	  system($mount);
		my $pdirs = readDirFiles($pfad1);
	  foreach (@$pdirs) {
	    my $dir1 = $_;
			next if $dir1 eq "." or $dir1 eq "..";
			next if $dir1 =~ /\@/;
			my $dir2 = $pfad1.$dir1;
			if (-d $dir2) {
				processFolder($dbh,$dir2,$dbname,$ext,$out);
				print "move $dir2 -> $backup\n";
				system("mv $dir2 $backup");
			}
		}
	  print "unmount /mnt/net\n";
	  system("umount /mnt/net");
	}
  $dbh->disconnect();
}






sub processFolder {
  my $dbh = shift;
	my $dir2 = shift;
	my $dbname = shift;
	my $ext = shift;
	my $out = shift;
  print "Process folder: $dir2\n";
	my $pfiles = readDirFiles($dir2);
	my @index = grep(/$ext$/,@$pfiles);
	foreach (@index) {
	  my $file1 = $_;
		my $dir3 = $dir2 . $ds;
		my $pinfo = processFile($dbh,$dir3,$file1,$dbname,$ext,$out);
	}
}






sub processFile {
  my $dbh = shift;
  my $dir = shift;
  my $file = shift;
	my $db = shift;
	my $ext = shift;
	my $out = shift;
	print "Process: $dir$file\n";
	my $pinfos = getInfos($dir,$file,$db);
	my $fields = getFields($dbh,$dir,$file);
	my $filepdf = $$pinfos{'File name'};
  my $fout = $out.$filepdf;
  foreach (my $c=0;$c<100;$c++) {
	  last if (!-e $fout); # check for a unique file name
  	my $fname=TimeStamp().'.pdf';
    $fout = "$out$fname";
  }
  if (!-e $fout) {
    $$pinfos{'File name'}= $fout;
	  # if in destination dir the file is not available, just move it
    copy("$dir$filepdf",$fout);
		$$pinfos{Fields} = $fields if $fields ne "";
		$$pinfos{ImportSource} = "1"; # we don't want an OCR text recognition
    # create axis-file from the infos and delete the csv-file
    createAXIS($pinfos,$dir); # create axis information
	}
}






sub getFields {
  my $dbh = shift;
  my $dir = shift;
	my $file = shift;
	my $file1 = "$dir$file";
	my $text = getFile($file1);
	my $out;
	my @lines = split(/\r\n/,$text);
	shift @lines if $lines[0] eq "BATCHSTART";
	my $f1 = $lines[0];
	my $v1 = $lines[1];
	$v1 =~ s/:/ /g;
	removeRN(\$f1);
	removeRN(\$v1);
	my @flds = split(/\t/,$f1);
	my @vals = split(/\t/,$v1);
	my $c=-1;
	foreach(@flds) {
	  $c++;
		next if $flds[$c] eq "V_Dateiname";
		$flds[$c] = "Datum" if $flds[$c] eq "V_Datum";
		$flds[$c] = "VP_ID_Subjekt" if $flds[$c] eq "V_ID_Subjekt";
		$out .= ":" if $out ne "";
		if ($flds[$c] eq "V_Betrag") {
      $vals[$c] =~ s/\'//g;
		}
		$out .= $flds[$c]."=".$vals[$c]; 
	}
	return $out;
}






sub getInfos {
  my $dir = shift;
  my $file = shift;
	my $db = shift;
  my %info;
	my $filepdf = $file;
  $filepdf =~ s/\..*/\.pdf/g;
  my $pages = getPages("$dir$filepdf");
  $info{'File name'}=$filepdf;
  $file =~ s/\..*//g;
  $info{'Date'}=$file;
  $info{'Destination'}=$db; # desired database
  $info{'Paper size'}="A4";
  $info{'Number of pages'}=$pages;
	$info{Width} = 2479;
	$info{Height} = 3509;
  $info{'X Resolution (DPI)'}=300;
  $info{'Y Resolution (DPI)'}=300;
  $info{'Bits per pixel'}=1;
  $info{'Format'}=1;
  if($info{'Height'} > $info{'Width'}){
    $info{'Paper Orientation'}='Portrait';
  } else {
    $info{'Paper Orientation'}='Landscape';
  }
  return \%info;
}






sub getPages {
  my $file = shift;
  my $result;
  my $system = "pdfinfo $file";
  $result = `$system`;
	my $pages = $result;
	$pages =~ s/^(.*?)(Pages:)(\s+)([0-9])(.*)$/$4/s;
  return $pages;
}







sub createAXIS {
  my $phash = shift;
  my $outfile = $phash->{'File name'};
  $outfile =~ s/\.pdf/\.ftp/g;
  open(FOUT,">$outfile");
  binmode(FOUT);
  foreach my $key (keys %$phash){
    print FOUT "$key"," "x(21-length($key)),"= ",$phash->{"$key"},"\n";
  }
  close(FOUT);
}






sub removeRN {
  my $pfirst = shift;
  $$pfirst =~ s/\r//g;
	$$pfirst =~ s/\n//g;
}






=head3 TimeStamp -> Actual date/time stamp (20040323130556)

=cut

sub TimeStamp {
  my @t=localtime(time());
  my ($stamp,$y,$m,$d,$h,$mi,$s);
  $y=$t[5]+1900;
  $m=$t[4]+1;
  $m=sprintf("%02d",$m);
  $d=sprintf("%02d",$t[3]);
  $h=sprintf("%02d",$t[2]);
  $mi=sprintf("%02d",$t[1]);
  $s=sprintf("%02d",$t[0]);
  $stamp=$y.$m.$d.$h.$mi.$s;
  return $stamp;
}







=head3 SQLStamp -> Actual date as SQL string (2004-03-23 00:00:00)

=cut

sub SQLStamp {
  my @t=localtime(time());
  my ($stamp,$y,$m,$d,$h,$mi,$s);
  $y=$t[5]+1900;
  $m=$t[4]+1;
  $m=sprintf("%02d",$m);
  $d=sprintf("%02d",$t[3]);
  $stamp=$y."-".$m."-".$d." 00:00:00";
  return $stamp;
}






=head3 MySQLOpen -> Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen {
  my $host = shift;
  my $db = shift;
  my $user = shift;
  my $pw = shift;
  my ($dbh,$ds);
  $ds = "DBI:mysql:host=$host;database=$db";
  $dbh=DBI->connect($ds,$user,$pw,{RaiseError=>0,PrintError=>0});
  return $dbh;
}






=head1 $slave=HostIsSlave($dbh)

gives back a 1 if we are in slave mode

=cut

sub HostIsSlave {
  my $dbh = shift;
  my $hostIsSlave = 0;
  my $sth = $dbh->prepare("SHOW SLAVE STATUS");
  $sth->execute();
  if ($sth->rows) {
    my @row = $sth->fetchrow_array();
    $hostIsSlave = 1 if ($row[9] eq 'Yes');
  }
  $sth->finish();
	return $hostIsSlave;
}






=head3 getFile -> Read a file and give it back as text

=cut

sub getFile {
  my $datei = shift;
  my (@a,$inhalt);
  if (-f $datei) {
    open(FIN,$datei);
    binmode(FIN);
    @a=<FIN>;
    close(FIN);
    $inhalt=join("",@a);
  }
  return $inhalt;
}






sub readDirFiles {
  my $pfad1 = shift;
	opendir(FIN,$pfad1);
	my @files = readdir(FIN);
	closedir(FIN);
	return \@files;
}	







