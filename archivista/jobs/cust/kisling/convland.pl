#!/usr/bin/perl

use strict;
use DBI;

# get the pdf file as file name
my (@fin,$t,@pages,$page,$c,$cl,$p2t,$pdftk);

my $host = "192.168.50.40";
my $db = "archiv";
my $user = "Admin";
my $pw = "*****";
my $st = 95800;
my $end = 160000;

my $dbh=MySQLOpen($host,$db,$user,$pw);
if ($dbh) {
  my $c=$st;
	while (1) {
    my $sql = "select Land,PLZ,Laufnummer from archiv " .
	            "where PLZ != '' and Land is null and Laufnummer>$c limit 1";
		my @row=$dbh->selectrow_array($sql);
		if ($row[2] >0) {
		  $c=$row[2];
      my $land = $row[0];
			my $plz = $row[1];
			$plz =~ /^([a-zA-Z0-9]+)(\s+)(.*)/;
			my $l=$1;
			my $p=$3;
			if ($l ne "" && $p ne "") {
			  $l=$dbh->quote($l);
				$p=$dbh->quote($p);
        my $sql1="update archiv set Land=$l,PLZ=$p where Laufnummer=$row[2]";
				$dbh->do($sql1);
        print "$c -- plz: --$1--$2--$3\n";
			}
		} else {
		  last;
		}
	}
	$dbh->disconnect();
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



