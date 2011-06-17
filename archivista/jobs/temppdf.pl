#!/usr/bin/perl

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

=head1 Functionality

This script has to be started via sane-daemon.pl. It creates a temp.
pdf file so the user can download it or delete it later

The input value format is: db;doc;action (add/delete)

=cut

my $dbh;
my $in = shift;
my ($db,$doc,$act) = split(/:/,$in);
if ($dbh=MySQLOpen()) {
  if (HostIsSlave($dbh)==0 && $doc>0) {
	  logit("start pdf temp job for doc $doc in $db");
		my $nr = ($doc*1000)+1;
		if ($act eq "delete") {
	    logit("delete temp pdf file for doc $doc in $db");
		  my $sql = "update $db.archivbilder set Quelle='' where Seite=$nr";
			$dbh->do($sql);
			$sql="update $db.archiv set QuelleExt='',QuelleIntern=0 " .
			     "where Laufnummer=$doc";
			$dbh->do($sql);
		} elsif ($act eq "add") {
	    logit("add temp pdf file for doc $doc in $db");
		  my $sql = "select Seiten,ArchivArt,Gesperrt from $db.archiv " .
			          "where Laufnummer=$doc";
			my @row=$dbh->selectrow_array($sql);
			my $seiten = $row[0];
			my $art = $row[1];
			my $gesperrt = $row[2];
			if ($seiten>0 && ($art==1 || $art==3) && $gesperrt eq "") {
			  my $ext="JPG";
				$ext="TIF" if $art==1;
        doJobPDFonly($dbh,$doc,$db,$seiten,$ext,1);
			}
    }
	} else {
	  logit("can't do anything in slave");
	}
  $dbh->disconnect();
}






=head1 doJobPDFonly 

Just create pdf files, no ocr needed

=cut

sub doJobPDFonly {
  my $dbh = shift;
  my $lnr = shift;
  my $db1 = shift;
  my $seiten = shift;
  my $extinput = shift;
	my $pdfwholedoc = shift;
  my ($sql,$c,@felder);
  my ($ppdf,$pfile,$img);
  
  $sql="update $db1.archiv set Gesperrt='temppdf',QuelleIntern=1,".
	     "QuelleExt='PDF' where Laufnummer=$lnr";
  $dbh->do($sql);
  my @files = ();
  for(my $c=1;$c<=$seiten;$c++) {
    my $nr1=$lnr*1000+$c;
		for(my $c2=0;$c2<5;$c2++) {
      $sql="select BildInput from $db1.archivbilder where Seite=$nr1";
      @felder=$dbh->selectrow_array($sql);
      $img=$felder[0];
			if (length($img)>0) {
			  $c2=5;
			} else {
				sleep 1;
			}
		}
    my $c1=sprintf("%04d",$c);
    $ppdf="/tmp/seite$c1".".pdf";
		push @files,$ppdf;
    if ($extinput eq "JPG") {
      $pfile="/tmp/seite$c1".".jpg";
      open(FOUT,">$pfile");
      binmode(FOUT);
      print FOUT $img;
      close(FOUT);
      system("jpeg2ps $pfile | epstopdf --filter > $ppdf");
    } else {
      $pfile="/tmp/seite$c1".".tif";
      open(FOUT,">$pfile");
      binmode(FOUT);
      print FOUT $img;
      close(FOUT);
      system("tiff2pdf $pfile > $ppdf");
    }
		if ($pdfwholedoc==0) {
      my $nr1=($lnr*1000)+$c;
			my $pf = getFile($ppdf);
      $sql="update $db1.archivbilder set Quelle=".$dbh->quote($$pf).
           "where Seite=$nr1";
      $dbh->do($sql);
			$$pf="";
		}
		sleep 1;
  }
	if ($pdfwholedoc==1) {
    my $pdf1="/tmp/all.pdf";
    my $dopdf="pdftk ".join(" ",@files)." output $pdf1";
    system("$dopdf");
    my $nr1=($lnr*1000)+1;
		my $pf = getFile($pdf1);
    $sql="update $db1.archivbilder set Quelle=".$dbh->quote($$pf).
         "where Seite=$nr1";
    $dbh->do($sql);
		$$pf="";
	}
  $sql="update $db1.archiv set Gesperrt='' where Laufnummer=$lnr";
  $dbh->do($sql);
  eval(system("rm /tmp/all.pdf"));
  eval(system("rm /tmp/seite*.pdf"));
  eval(system("rm /tmp/seite*.jpg"));
  eval(system("rm /tmp/seite*.tif"));
}






=head1 getFile -> Read a file and give it back as text

=cut

sub getFile {
  my $datei = shift;
  my (@a,$inhalt);
  if (-f $datei) {
    open(FIN,$datei);
    binmode(FIN);
		while(my $line = <FIN>) {
		  $inhalt .= $line;
		}
    close(FIN);
  }
  return \$inhalt;
}


