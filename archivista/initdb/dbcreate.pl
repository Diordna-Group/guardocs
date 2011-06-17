#!/usr/bin/perl

# script to create a normal archivista structure v5.2
# (c) Archivista GmbH, www.archivista.ch

use DBI;
use strict;

# global settings
my $mserv = "/etc/init.d/mysql ";
my $mstop = "stop";
my $mstart = "start";
my $mdir = "/home/data/archivista/mysql";
my $idir = "/home/data/archivista/images";
my $ddir = "$idir/archivista";
my $mydbnew = "mysql_install_db";
my $dinst = "/home/cvs/archivista/initdb";
my $debian_user = "./debian-mysql-user.pl";

# remove and create image structure
eval(system("rm -R $idir"));
eval(system("mkdir $idir"));
eval(system("mkdir $ddir"));
eval(system("mkdir $ddir/input"));
eval(system("mkdir $ddir/output"));
eval(system("mkdir $ddir/screen"));
eval(system("mkdir $ddir/temp"));
eval(system("chown -R archivista.archivista $idir"));

# remove and create database structure
eval(system("$mserv $mstop"));
eval(system("rm -R $mdir"));
eval(system("mkdir $mdir"));
eval(system("chown -R mysql.mysql $mdir"));
eval(system($mydbnew));
eval(system("chown -R mysql.mysql $mdir"));
eval(system("$mserv $mstart"));

sleep 5;

eval(system("mysql -u root <$dinst/archivista_db.sql"));
eval(system("mysql -u root <$dinst/archivista_lang.sql"));
eval(system("mysql -u root <$dinst/archivista_data.sql"));
eval(system("mysql -u root <$dinst/archivista_user.sql"));
eval(system("mysql -u root <$dinst/archivista_menu.sql"));

my $my="mysql";
my $hs="localhost";

my $dbh=DBI->connect("DBI:mysql:host=$hs;database=$my;port=3306",
         "root","",{PrintError=>1,RaiseError=>0});

my $t1= "archiv,archivseiten,archivbilder,parameter,user,".
        "adressen,adressenplz,notizen,literatur,literaturrubrik,".
      	"feldlisten,workflow,abkuerzungen,archives,languages,jobs,".
				"jobs_data,application_menu";
my @tab = split(",",$t1);

my $db = "archivista";

grantUser($dbh,"localhost",$db,"Admin","archivista",@tab);
grantUser($dbh,"localhost",$db,"SYSOP","archivista",@tab);

my $sql="delete from user where User='root' and Host='archivista'";
$dbh->do($sql);
$sql="set password=Password('archivista')";
$dbh->do($sql);

$sql="flush privileges";
$dbh->do($sql);
$dbh->disconnect();

#create Debian user again
#eval(system($debian_user));

sub grantUser {
  my $dbh = shift;
  my $hst = shift;
  my $db = shift;
  my $usr = shift;
  my $pw = shift;
  my @tab = @_;
  my $st = "grant all on";
  my $id = "identified by";
  my $gr = "with grant option";

  my ($sql);
	
  #$sql=qq(revoke all on *.* from '$usr'\@'$hst');
	#$dbh->do($sql);
	
  #$sql=qq(revoke grant option on *.* from '$usr'\@'$hst');
	#$dbh->do($sql);
	
  foreach my $tb (@tab) {
    $sql = "$st $db.$tb to '$usr'\@'$hst' $id '$pw' $gr";
    $dbh->do($sql);
  }
}

