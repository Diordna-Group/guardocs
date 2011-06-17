#!/usr/bin/perl

use strict;
use DBI;

# database information
my $host="192.168.50.40";
my $db="archiv";
my $user="Admin";
my $pw="*****";

my $dbh=MySQLOpen($host,$db,$user,$pw);
if ($dbh) {
  my $next=1;
  while($next>0) {
	  my $upt = "";
    my $sql = "select Laufnummer,Datum,MandantNr,Eigentuemer, " .
		        "Bereich,Unterbereich,HHWLieferNr " .
	          "from archiv where UserNeuName='formrec' and " .
						"(MandantNr='100' or MandantNr='300') and " .
						"(Geschaeftsjahr IS NULL or Geschaeftsjahr='') " .
						"and Laufnummer>=$next order by laufnummer limit 1";
		my ($lnr,$dat,$mnr,$own,$ber,$uber,$lief) = $dbh->selectrow_array($sql);
		if ($lnr>0) {
		  if ($ber = "Lieferanten" && $uber="Rechnungen" && $lief>0) {
			  my $sql1 = "select Laufnummer,HHWLieferName,Zusatzbezeichnung,".
				           "Strasse,Postfach,PLZ,Ort from archmaster.archiv ".
									 "where HHWLieferNr=$lief limit 1";
				my ($lnr1,$name,$zus,$str,$pf,$plz,$ort) = $dbh->selectrow_array($sql1);
				if ($lnr1>0) {
				  $upt .= "HHWLieferName=".$dbh->quote($name).",";
				  $upt .= "PLZ=".$dbh->quote($plz).",";
				  $upt .= "Ort=".$dbh->quote($ort).",";
				  $upt .= "Zusatzbezeichnung=".$dbh->quote($zus).",";
				  $upt .= "Strasse=".$dbh->quote($str).",";
				  $upt .= "Postfach=".$dbh->quote($pf).",";
				}
			} else {
			  if ($own="KISRWv" && $mnr='300') {
			    $upt .= "Eigentuemer='HHWRWv',"
			  }
			}
			my $dat1 = $dat;
			$dat1 =~ /([0-9]{4,4})-([0-9]{2,2})/;
			if ($1 ne "" && $2 ne "") {
			  $upt .= "Geschaeftsjahr='$1',Buchungsperiode='$1$2'";
			}
			if ($upt ne "") {
			  my $sql2 = "update archiv set $upt where Laufnummer=$lnr";
				$dbh->do($sql2);
				print "$sql2\n";
			}
		}
		last if $lnr==0;
		$next=++$lnr;
	}
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



