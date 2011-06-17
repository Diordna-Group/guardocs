#!/usr/bin/perl

=head1 sane-button.pl (c) 20.9.2005 by Archivista GmbH, Urs Pfister

This script acts as the backend for a scan button. As soon as numeric 
key and the ENTER key is pressed, the scan job will be started here.

=cut

use strict;
use Archivista::Config;    # is needed for the passwords and other settings
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;

my %val;
my $config = Archivista::Config->new;
$val{host} = $config->get("MYSQL_HOST");
$val{db} = $config->get("MYSQL_DB");
$val{user} = $config->get("MYSQL_UID");
$val{pw} = $config->get("MYSQL_PWD");
undef $config;

my $ocrengine = shift;
$ocrengine = 1 if $ocrengine<0 || $ocrengine>2; 

my $dbh=MySQLOpen($val{host},$val{db},$val{user},$val{pw});
if ($dbh) {
  my $pdbs = getValidDatabases($dbh);
	foreach (@$pdbs) {
	  my $db = $_;
	  my $sql = "update $db.parameter set Inhalt='$ocrengine' ".
		          "where Name = 'JobsOCRRecognition' and ".
							"Art='parameter' and Tabelle='parameter'";
		$dbh->do($sql);
	}
	MySQLClose($dbh);
}

