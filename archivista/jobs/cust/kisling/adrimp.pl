#!/usr/bin/perl

use strict;
use DBI;

# get the pdf file as file name
my (@fin,$t,@pages,$page,$c,$cl,$p2t,$pdftk);
my $pathin = "/mnt/net/"; # Path where we find the cold files
my $backup = "/mnt/net/backup/"; # backup path (plase where we send 
                                 # the files after processing
my $fext = ".csv";               # csv extenstion
# database information
my $host="192.168.50.40";
my $db="archiv";
my $user="Admin";
my $pw="*****";
my $lockuser="coldkis";

if (-d "/mnt/net/backup") {
  print TimeStamp().": old job still running...\n";
	die;
}
print TimeStamp().": mounting device\n";
system("/home/data/archivista/kis/mount.sh");
# open the mysql connection
my $dbh=MySQLOpen($host,$db,$user,$pw);
if (-d $pathin && -d $backup && $dbh) {
  # pathes and mysql are ok, so read all files
  opendir(FIN,$pathin);
	@fin=readdir(FIN);
	closedir(FIN);
	# if we find later on address files, we need to kill the old entries
	my $first=1;
  foreach(@fin) {
	  # go through each file
    my $f=$_;
    my $f1="$pathin$f";
		if ($f ne "." && $f ne ".." && !-d $f) {
		  # no entries from directories
      my $ext=lc($f1);
			$ext=~/(\.csv)$/;
			$ext=$1;
      if (-e $f1 && $ext eq '.csv') {
			  if ($first==1) {
				  # kill old entries
          my $sql="delete from feldlisten where " .
					        "FeldDefinition='KISKundeName' OR " .
									"FeldDefinition='KISLieferName' OR " .
									"FeldDefinition='HHWKundeName' OR " .
									"FeldDefinition='HHWLieferName'";
	        $dbh->do($sql);
	        $sql="delete from archmaster.archiv";
	        $dbh->do($sql);
					$first=0;
				}
	      my $mand=$f;
    		$mand=~s/(.*)(kis|hhw)(.*)/$2/;
		    if ($mand eq "kis") {
    	    $mand="KIS";
	    	} else {
          $mand="HHW";
		    }
    		my $art=$f;
		    $art=~s/(.*)(liefer|kunden)(.*)/$2/;
    		if ($art eq "liefer") {
		      $art="Liefer";
     		} else {
          $art="Kunde";
    		}
		    my $feld1="$mand$art"."Name";
    		my $feld2="$mand$art"."Nr";
		    print "$f1--$feld1--$feld2\n";
        open(FIN,$f1);
				binmode(FIN);
				my @f=<FIN>;
				close(FIN);
				foreach(@f) {
          my ($anr,$name,$zus,$pf,$str,$land,$plz,$ort) = 
					    unpack("A11A30A30A30A30A3A10A25",$_);
        	# Document is ok, we need the number
					AddEntryBoth($dbh,$feld1,$name,$feld2,$anr);
					AddEntryMaster($dbh,$anr,$name,$zus,$pf,$str,$land,$plz,
					               $ort,$feld1,$feld2);
				}
        my $fb="$backup$f";
		    unlink $fb if (-e $fb);
		    eval(system("mv $f1 $fb")) if (-e $f1);
			}
	  }
  }
} else {
  print "mount points $pathin or $backup are not available\n";
}
print TimeStamp().": unmount device\n";
system("umount /mnt/net");







sub AddEntry {
  my $dbh = shift;
	my $feld = shift;
	my $val = shift;
	my $val1=$dbh->quote($val);
  my $sql="select Definition from feldlisten " .
	        "where Definition=$val1 and FeldDefinition='$feld'";
  my @a=$dbh->selectrow_array($sql);
  if ($a[0]==0) {
    # we need to add it
		$sql="insert into feldlisten set FeldDefinition='$feld'," .
		"Definition=$val1";
		$dbh->do($sql);
	}
}




sub AddEntryBoth {
  my $dbh = shift;
	my $feld1 = shift;
	my $val1 = shift;
	my $feld2 = shift;
	my $val2 = shift;
	my $val1a=$dbh->quote($val1);
	my $val2a=$dbh->quote($val2);
  my $sql="select Code from feldlisten where " .
	        "FeldDefinition='$feld1' and " .
	        "Definition=$val1a and " .
					"FeldCode='$feld2' and " .
					"Code=$val2a";
  my @a=$dbh->selectrow_array($sql);
  if ($a[0]==0) {
    # we need to add it
		$sql="insert into feldlisten set " .
		     "FeldDefinition='$feld1'," .
				 "Definition=$val1a," .
				 "FeldCode='$feld2'," .
				 "Code=$val2a";
		$dbh->do($sql);
	}
}



sub AddEntryMaster {
  my $dbh = shift;
	my $anr = shift;
	my $name = shift;
	my $zus = shift;
	my $pf = shift;
	my $str = shift;
	my $land = shift;
	my $plz = shift;
	my $ort = shift;
	my $feld1 = shift; # Name
	my $feld2 = shift; # Number
	$name=$dbh->quote($name);
	$zus=$dbh->quote($zus);
	$pf=$dbh->quote($pf);
	$str=$dbh->quote($str);
	$land=$dbh->quote($land);
	$plz=$dbh->quote($plz);
	$ort=$dbh->quote($ort);
	my $sql="insert into archmaster.archiv ($feld1,$feld2," .
	        "Zusatzbezeichnung,Postfach,Strasse,Land,PLZ,Ort) " .
	        "values ($name,$anr,$zus,$pf,$str,$land,$plz,$ort)";
	$dbh->do($sql);
}



=head3 DocumentAddDatForm -> Format a date ('yyyy-mm-dd')

=cut

sub datumadd {
  my $d=shift;
	my ($t,$m,$y)=split(/\./,$d);
	$t=sprintf("%02d",$t);
	$m=sprintf("%02d",$m);
	if ($y<70) {
	  $y=$y+2000;
	} else {
    $y=$y+1900;
	}
	$y=sprintf("%04d",$y);
	$d= "'".$y."-".$m."-".$t." 00:00:00'";
	return $d;
}


			



=head3 MySQLOpen -> Open a MySQL handler and gives back a db handler

=cut

sub MySQLOpen {
    my $host = shift;
    my $db = shift;
    my $user = shift;
    my $pw = shift;
    my ($dbh,$ds);
    $ds = "DBI:mysql:host=$host;database=$db";
    $dbh=DBI->connect($ds,$user,$pw);
    return $dbh;
}






=head3 TimeStamp -> Actual date/time stamp (20040323130556)

=cut

sub TimeStamp
{
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

sub SQLStamp
{
  my @t=localtime(time());
  my ($stamp,$y,$m,$d,$h,$mi,$s);
  $y=$t[5]+1900;
  $m=$t[4]+1;
  $m=sprintf("%02d",$m);
  $d=sprintf("%02d",$t[3]);
  $stamp=$y."-".$m."-".$d." 00:00:00";
  return $stamp;
}



