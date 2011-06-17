#!/usr/bin/perl

=head1 avimpexport.pl, (c) 14.9.2005 by Archivista GmbH, Urs Pfister

Skript does import and export documents from archivista databases
The values are:

$mode, $db, $dir, $range

=cut

use lib qw (/home/cvs/archivista/jobs);
use strict;
use DBI;
use Archivista;

my $mode = shift;
my $db1 = shift;
my $dir = shift;
my $val = shift;
my $out = "/mnt/usbdisk/pdf";
$out=$dir if $dir ne "";
my $ds = "/"; # ATTENTION: Linux (/) or Windows (\\)

my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pw = $config->get("MYSQL_PWD");
$db1=$db if $db1 eq "";



# static variables 
my $log = '/home/data/archivista/av.log';
my $path = "$out/"; 

my $file = "export.av5";

# even if we have no password to connect, we need a value
$pw = "" if $pw eq "''";
$user = "SYSOP" if $user eq "archivista";
my $dbh=dbconnect($host,$db1,$user,$pw);
if ($dbh) {
  if (checkdb($dbh)) {
    exportdb($dbh,$val,$path,$file) if $mode eq "exportdb";
  }    
  dbclose($dbh);
}






#--------------------------------------------------------------------------#

=head1 $string=timestamp()
  
  gives back an actual date/time stamp (20040323130556)

=cut

sub timestamp {
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






#--------------------------------------------------------------------------#

=head1 logmessage($message)
  
  writes a message to a log file

=cut

sub logmessage {
  my $stamp = timestamp();
  my $message = shift;
  # $log file name comes from outside
  open(FOUT,">>$log");
  binmode(FOUT);
  my $logtext = $0 ." " . $stamp . " " . $message . "\n";
  print FOUT $logtext;
  close(FOUT);
}






#--------------------------------------------------------------------------#

=head1 $dbh=dbconnect($host,$db,$user,$pw)
  
  connect to a database

=cut

sub dbconnect {
  my $host = shift;
  my $db = shift;
  my $user = shift;
  my $pw = shift;
  my $message;
  my $dsn="DBI:mysql:database=$db;host=$host";
  if($dbh = DBI->connect($dsn,$user,$pw)){
    $message = "Connection ok: $host, $db, $user";
    logmessage($message);
  } else {
    $message = "No connection: $host, $db, $user";
    logmessage($message);
  }
  return $dbh;
}






#--------------------------------------------------------------------------#

=head1 dbclose($dbh)

  close a database handle

=cut

sub dbclose {
  my $dbh = shift;
  $dbh->disconnect;
  my $message = "Connection closed";
  logmessage($message);
}






#--------------------------------------------------------------------------#

=head1 $ver=checkdb($dbh,$sql)

  does a check if it is an archivista database 
  (gives back the version)

=cut

sub checkdb {
  my $dbh = shift;
  my $message;
  my $sql = "select Inhalt from parameter where Name like 'AVVersion%'";
  my @res = $dbh->selectrow_array($sql);
  if ($res[0]>= 520) {
    $message = "Archivista database founded";
  } else {
    $message = "Sorry, no archivista database";
  }
  logmessage($message);
  return $res[0];
}






#--------------------------------------------------------------------------#

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
  $pfields=getfields($dbh,"archiv");
  @fields = @$pfields;

  my $count=0;
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
		if ($fields[$nr]->{name} eq "BildInputExt") {
      $enr=$nr;
			$nr=100;
		}
	}

	$sql = "select * from archiv where (Gesperrt='' or Gesperrt is null) ";
	$sql .=sqlrange($val) . " order by Laufnummer asc";
  my $st = $dbh->prepare($sql);
  my $r = $st->execute;
  while (my @r=$st->fetchrow_array) {
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
    $ext=$r[$enr];
    # now export behind the values all images
    $z.=exportfiles($dbh,$path,$akte,$seiten,$ext,$val,\$count);
    $z.="\r\n";
  }
  $message = "Document(s) $val exported";
  logmessage($message);
}






#--------------------------------------------------------------------------#

=head1 exportfiles ($dbh, $pfad, $akte, $seiten, $typ (JPG/TIF)
 
  does export all images of one document

=cut

sub exportfiles {
  my $dbh = shift;
  my $pfad = shift;
  my $akte = shift;
  my $seiten = shift;
  my $typ = shift;
	my $val = shift;
	my $pcount = shift;
  my $pfadname;
  my $fname;
  my $out;

  for(my $c=1;$c<=$seiten;$c++) {
    my $seite=$akte*1000+$c;
    my $sql = "select BildInput from archivbilder where Seite = $seite";
    my @r=$dbh->selectrow_array($sql);
    if ($r[0] ne "") {
      #$fname="$akte"."_"."$c\.$typ";
			my @loctime = localtime();
			my $day = sprintf("%02d",$loctime[3]);
			my $month = sprintf("%02d",$loctime[4]+1);
			my $year = sprintf("%04d",$loctime[5]+1900);
			my $date = $year.$month.$day;
			$$pcount++;
			$fname = $date ."-".sprintf("%04d",$$pcount)."\.$typ";
			my $message = "$fname";
			logmessage($message);
      $out.="$fname;";
      $pfadname="$pfad$fname";
      open(FOUT1,">$pfadname");
      binmode(FOUT1);
      print FOUT1 $r[0];
      close(FOUT1);
    } else {
      $out.=";";
    }
  }
  return $out;
}






#--------------------------------------------------------------------------#

=head1 exportformatvalue ($val,$typ)

  does format a mysql field value to the archivista export format

=cut

sub exportformatvalue {
  my $val = shift;
  my $typ = shift;

  my $t="";
  if ($val ne "") {
    if ($typ eq "varchar" or $typ eq "text") {
      $t=$val;
    } elsif ($typ eq "int") {
      $t=$val;
    } elsif ($typ eq "tinyint") {
      if ($val==0) {
        $t="Nein";
      } else {
        $t="Ja";
      }
    } elsif ($typ eq "double") {
      $t=$val;
    } elsif ($typ eq "datetime") {
      $t=DocumentAddDatGerman($val);
    }
  }
  $t.="\t";
  return $t;
}






#--------------------------------------------------------------------------#

=head1 emptypath($path)

  remove $path and create it again

=cut

sub emptypath {
  my $path = shift;
  if (-d $path) {
    system("rm -Rf $path");
    print "$path killed\n";
  }
  system("mkdir $path");
}






#--------------------------------------------------------------------------#

=head1 sqlrange($range)

  gives back an sql fragment either 'and Laufnummer=x' or
                                    'and Laufnummer between x and y'

=cut

sub sqlrange {
  my $val = shift;
  my ($sql,$x,$y);

  # check if we only have one document or several documents
  $val=~/^(\d+)(-*)(\d*)/;
  $x=$1;
  $y=$3;
 
  if ($y != ''){
    $sql = "and Laufnummer between $x and $y" if ($y>0 && $y>$x);
  } else {
    $sql = "and Laufnummer=$x" if ($x>0);
  }
  return $sql; 
}






#--------------------------------------------------------------------------#

=head1 getfields ($dbh, $table)
 
 gets back in an pointer of an array a hash 
 containing all name, type und sizes of an mysql table
 
=cut

sub getfields {
  my $dbh = shift;
  my $table = shift;
  my $sql = "describe $table";

  my $nr=0;
  my $st=$dbh->prepare("describe archiv");
  my $r=$st->execute;
  my @fields;
  while (my @row=$st->fetchrow_array) {
    my %f;
    $f{name}=$row[0];
    my $name="";
    my $lang=0;
    ($name,$lang)=$row[1]=~/(.*)\((.*)\)/;
    $name=$row[1] if $name eq "";
    $f{type}=$name;
    $f{size}=$lang;
    $fields[$nr]=\%f;
    $nr++;
  }
  return \@fields;  
}






#--------------------------------------------------------------------------#

=head1 DocumentAddDatForm -> Format a date ('yyyy-mm-dd')

=cut

sub DocumentAddDatForm {
  my $d=shift;
  $d= "'".substr($d,0,4)."-".substr($d,4,2)."-".substr($d,6,2)." 00:00:00'";
  return $d;
}






#--------------------------------------------------------------------------#

=head1 DocumentAddDatGerman -> Format a date ('ddmmyyyy'')

=cut

sub DocumentAddDatGerman {
  my $d=shift;
  $d=substr($d,8,2).substr($d,5,2).substr($d,0,4);
  return $d;
}






#--------------------------------------------------------------------------#

=head1 DocumentAddDatSQL -> german date to SQL ('yyyy-mm-dd 00:00:00')

=cut

sub DocumentAddDatSQL {
  my $d=shift;
  $d= "'".substr($d,6,4)."-".substr($d,3,2)."-".substr($d,0,2)." 00:00:00'";
  return $d;
}
