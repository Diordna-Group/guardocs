#!/usr/bin/perl

################################################# What it is

=head1 createpdf.pl --- (c) by Archivista GmbH, 10.9.2005
       
Create pdf files and/or ocr recognition in archivista archives

=cut

use strict;
use DBI;
use lib qq(/home/cvs/archivista/apcl/Archivista);
use Archivista::Config;
my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pw = $config->get("MYSQL_PWD");
undef $config;

my $title = "V_ID_Vertrag\t".
"V_Gueltigvon\t".
"V_Gueltigbis\t".
"V_ID_Sammelrechnung\t".
"V_ID_Objekt\t".
"V_Objekt_StrasseHaus\t".
"V_Objekt_Postleitzahl\t".
"V_Objekt_Ortsname\t".
"VP_ID_Subjekt\t".
"V_GueltigvonVP\t".
"V_GueltigbisVP\t".
"VP_Anrede\t".
"VP_Name\t".
"VP_Zusatzname\t".
"VP_Vorname\t".
"VP_StrasseHaus\t".
"VP_Postleitzahl\t".
"VP_Ortsname";

my %ftype = ("V_ID_Vertrag" => "int",
            "V_Gueltigvon" => "datetime",
            "V_Gueltigbis" => "datetime",
            "V_ID_Sammelrechnung" => "int",
            "V_ID_Objekt" => "int",
            "V_Objekt_StrasseHaus" => "varchar",
            "V_Objekt_Postleitzahl" => "varchar",
            "V_Objekt_Ortsname" => "varchar",
            "VP_ID_Subjekt" => "int",
            "V_GueltigvonVP" => "datetime",
            "V_GueltigbisVP" => "datetime",
            "VP_Anrede" => "varchar",
            "VP_Name" => "varchar",
            "VP_Zusatzname" => "varchar",
            "VP_Vorname" => "varchar",
            "VP_StrasseHaus" => "varchar",
            "VP_Postleitzahl" => "varchar",
            "VP_Ortsname" => "varchar",
					);

my $posdef = 12;
my $posnr = 0;






=head2 Functionality

This script is responsible for barcode and ocr recognitions.

=cut

# open a database handler 
my $dbh=MySQLOpen($host,$db,$user,$pw);
if ($dbh) {
  if (HostIsSlave($dbh)==0) {
		my @flds = split(/\t/,$title);
		my $sql = "";
		my $lastnr = 1;
		my $aktnr = 0;
		my $aktvertr = 0;
		my $aktsubj = 0;
		while ($lastnr>0) {
		  $sql = "select Laufnummer,V_ID_Vertrag,VP_ID_Subjekt " .
			       "from archiv.archiv where ".
			       "(((V_ID_Vertrag is not null and V_ID_Vertrag!=0) and ".
						 "(VP_ID_Subjekt is null or VP_ID_Subjekt=0)) or " .
						 "((V_ID_Vertrag is null or V_ID_Vertrag=0) and VP_ID_Subjekt>0)) " .
						 "and Laufnummer>=$lastnr";
			print "$sql\n";
			my @row = $dbh->selectrow_array($sql);
			print "$row[0]\n";
			if ($row[0]>0) {
			  $aktnr=$row[0];
				$aktvertr=$row[1];
				$aktsubj=$row[2];
				print "$aktnr--$aktvertr--$aktsubj\n";
				my $sql1 = "Laufnummer";
				foreach (@flds) {
					$sql1 .= ",$_";
				}
				$sql1 = "select $sql1 from archiv_master.archiv where ";
				if ($aktvertr>0) {
				  $sql1 .= "V_ID_Vertrag=$aktvertr";
				} else {
				  $sql1 .= "VP_ID_Subjekt=$aktsubj limit 1";
				}
			  my @row = $dbh->selectrow_array($sql1);
				print "$row[0]\n";
				if ($row[0]>0 || $row[8]>0) {
				  shift @row;
					my $sql2="";
					my $c=0;
					foreach (@flds) {
					  my $fld = $_;
						if ($aktvertr==0) {
						  if ($fld eq "V_ID_Vertrag" || $fld eq "V_Gueltigvon" ||
							    $fld eq "V_Gueltigbis") {
								$c++;
								next;
							}
						}
						my $type = $ftype{$fld};
						my $fval = $row[$c];
						if ($fval ne "") {
						  if ($type eq "varchar" or $type eq "datetime") {
							  $fval = $dbh->quote($fval);
						  }
						  $sql2.="," if $sql2 ne "";
						  $sql2.="$fld=$fval";
						}
						$c++;
					}
					my $sql3 = "update archiv.archiv set ";
					if ($aktvertr>0) {
					  $sql3 .= "Bereich='Kommunikation',VertragArt='Digital-TV'";
					} else {
					  $sql3 .= "Bereich='Administration',VertragArt='Rechnungen'";
					}
					$sql3 .= ",$sql2 where Laufnummer=$aktnr";
					print "$sql3\n";
					$dbh->do($sql3);
				}
				$lastnr=$aktnr+1;
			} else {
			  print "end\n";
			  $lastnr=0;
			}
		}
	}
  $dbh->disconnect();
}






sub removeRN {
  my $pfirst = shift;
  $$pfirst =~ s/\r//g;
	$$pfirst =~ s/\n//g;
}






=head3 TimeStamp -> Actual date/time stamp (20040323130556)

=cut

sub TimeStamp
{
  my @t=localtime(time());
  my ($stamp,$y,$m,$d,$h,$mi,$s);
  $y=$t[5]+1900;
  $m=$t[4]+1;
		  print "but but but\n";
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



