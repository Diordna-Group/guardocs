#!/usr/bin/perl

################################################# What it is

=head1 createpdf.pl --- (c) by Archivista GmbH, 10.9.2005
       
Create pdf files and/or ocr recognition in archivista archives

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


my $mount = "/home/data/archivista/cust/tbwil/mount.sh";
my $pfad = "/home/data/archivista/cust/tbwil/net/";
my $title = "V_ID_Vertrag\t".
"V_Gueltigvon\t".
"V_Gueltigbis\t".
"V_ID_Sammelrechnung\t".
"V_ID_Objekt\t".
"V_Objekt_StrasseHaus\t".
"V_Objekt_Postleitzahl\t".
"V_Objekt_Ortsname\t".
"VP_ID_Subjekt\t".
"V_GueltigVonVP\t".
"V_GueltigBisVP\t".
"VP_Anrede\t".
"VP_Name\t".
"VP_Zusatzname\t".
"VP_Vorname\t".
"VP_StrasseHaus\t".
"VP_Postleitzahl\t".
"VP_Ortsname";

my %ftype = ("V_ID_Vertrag" => "int",
            "V_GueltigVon" => "datetime",
            "V_GueltigBis" => "datetime",
            "V_ID_Sammelrechnung" => "int",
            "V_ID_Objekt" => "int",
            "V_Objekt_StrasseHaus" => "varchar",
            "V_Objekt_Postleitzahl" => "varchar",
            "V_Objekt_Ortsname" => "varchar",
            "VP_ID_Subjekt" => "int",
            "V_GueltigVonVP" => "datetime",
            "V_GueltigBisVP" => "datetime",
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
  print "connection ok\n";
  if (HostIsSlave($dbh)==0) {
	  system($mount);
	  opendir(FIN,$pfad);
		my @files = readdir(FIN);
		closedir(FIN);
		foreach (@files) {
	    my $file = $_;
			next if $file eq "." or $file eq "..";
			#my $file1 = `date`;
			my $back = "$pfad"."SAVE/"."$file";
			$file = "$pfad$file";
			print "$file\n";
			open(FIN,"$file");
			my @lines=<FIN>;
			close(FIN);
			my $first = shift @lines;
			removeRN(\$first);
			if (lc($first) eq lc($title)) {
			  print "$file found\n";
			  my @flds = split(/\t/,$first);
				my $sql = "delete from archiv.feldlisten where " .
				          "FeldDefinition='VP_Name' and " .
									"FeldCode='V_ID_Vertrag'";
				$dbh->do($sql);
				$sql = "delete from archiv_master.archiv";
				$dbh->do($sql);
				my $lnr=0;
				foreach (@lines) {
					if (($lnr % 1000)==0) {
					  my $tm = `date`;
				    print "$lnr at $tm\n";
					}
					$lnr++;
          my $line = $_;
					removeRN(\$line);
					my @vals = split(/\t/,$line);
					my $def = $dbh->quote($vals[$posdef]);
					my $code = $dbh->quote($vals[$posnr]);
					$sql = "insert into archiv.feldlisten set " .
					       "FeldDefinition='VP_Name'," .
								 "Definition=$def,".
								 "FeldCode='V_ID_Vertrag',".
								 "Code=$code";
					$dbh->do($sql);
					my $sql="";
					my $c=0;
					foreach (@flds) {
					  my $fld = $_;
						my $type = $ftype{$fld};
						my $fval = $vals[$c];
						if ($fval ne "") {
						  if ($type eq "varchar") {
							  $fval = $dbh->quote($fval);
						  } elsif ($type eq "datetime") {
						    my ($day,$mon,$year) = split(/\./,$fval);
							  $fval = "'$year-$mon-$day 00:00:00'";
						  } else {
						    $fval="0" if $fval=="";
						  }
						  $sql.="," if $sql ne "";
						  $sql.="$fld=$fval";
						}
						$c++;
					}
					$sql = "insert into archiv_master.archiv set " .
					       "Bereich='Kommunikation',VertragArt='Digital-TV',$sql";
					$dbh->do($sql);
					#my @row=$dbh->selectrow_array("select last_insert_id()");
					#if ($row[0]>0) {
					#  $sql = "update archiv_master.archiv set Akte=$row[0]";
					#	$dbh->do($sql);
					#}
				}
				$sql = "update archiv set Akte=Laufnummer";
				$dbh->do($sql);
			  print "delete $file--$back\n";
			  unlink $back if -e $back;
				move($file,$back);
				last;
			}
		}
	}
  $dbh->disconnect();
	print "unmount /home/data/archivista/cust/tbwil/net\n";
	system("umount /home/data/archivista/cust/tbwil/net");
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



