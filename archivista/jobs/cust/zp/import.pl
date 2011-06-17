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


my $pfad = "/home/data/archivista/ftp/proffiximport/";

# open a database handler 
my $dbh=MySQLOpen($host,$db,$user,$pw);
if ($dbh) {
  print "connection ok\n";
  if (HostIsSlave($dbh)==0) {
	  opendir(FIN,$pfad);
		my @files = readdir(FIN);
		closedir(FIN);
		foreach (@files) {
	    my $file = $_;
			next if $file eq "." or $file eq "..";
			$file = "$pfad$file";
			print "$file\n";
			open(FIN,"$file");
			my @lines=<FIN>;
			close(FIN);
			my $first = shift @lines;
			print "$file found\n";
			my $sql = "delete from archivista.feldlisten where " .
				        "FeldDefinition='FirmenName' and " .
								"FeldCode='FirmenNummer'";
			print "$sql\n";
			$dbh->do($sql);
			foreach (@lines) {
        my $line = $_;
				removeRN(\$line);
				my @vals = split(/\t/,$line);
				my $def = $dbh->quote($vals[2]);
				my $code = $dbh->quote($vals[1]);
				$sql = "insert into archivista.feldlisten set " .
				       "FeldDefinition='FirmenName'," .
							 "Definition=$def,".
							 "FeldCode='FirmenNummer',".
							 "Code=$code";
				$dbh->do($sql);
			}
			unlink $file if -e $file;
		}
	}
  $dbh->disconnect();
}






sub removeRN {
  my $pfirst = shift;
  $$pfirst =~ s/\r//g;
	$$pfirst =~ s/\n//g;
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



