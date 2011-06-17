#!/usr/bin/perl

# -----------------------------------------------
# Workflow Cron Script 
#
# Programmed by Markus Stocker
# Archivista GmbH Zurich, Switzerland
#
# Version 0.1, 16.12.2003
# Version 0.2, 28.11.2005
# -----------------------------------------------

use strict;
use DBI;
use Mail::Sendmail;

use Archivista;

# -----------------------------------------------
# Configuration
my $config = Archivista::Config->new();
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $uid = $config->get("MYSQL_UID");
my $pwd = $config->get("MYSQL_PWD");
my $mailfrom = "noreply\@archivista.ch";
my $subject = "Archivista Workflow Module";
my $logfile = "/home/web/cgi-bin/dmt/dmt.log";
my $mailurl = "http://cobra.tiere.zoo/perl/avclient/index.pl";
my $lang = "en";
my $logheader = "****************************\n";
$logheader .= "Archivista Workflow Module Log\n";
$logheader .= "created on ".localtime()."\n";
$logheader .= "****************************\n\n";
# -----------------------------------------------

undef $config;

my (%mail_body);
my $localtime = localtime();

my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db",$uid,$pwd);
my $query = "SELECT Laufnummer, User, Name, Inhalt, Volltext ";
$query .= "FROM workflow ";
$query .= "WHERE Art='Workflow' ";
$query .= "ORDER by User";
my $sth = $dbh->prepare($query);
$sth->execute();

# Checking for jobs
while (my @row = $sth->fetchrow()) {
	my $count = 0;
	my ($matches);
	my ($id,$user,$name,$inhalt,$fulltext) = ($row[0],$row[1],$row[2],$row[3],$row[4]);
	if (length($fulltext) > 0) {
		$inhalt =~ s/(SELECT.*?FROM archiv)(.*)/$1,archivseiten$2/;
		$inhalt =~ s/(SELECT.*?WHERE\s)(.*)/$1MATCH archivseiten.Text AGAINST ('$fulltext' IN BOOLEAN MODE) $2 GROUP BY Akte/;	
	}
	# Job found, execute it
	my $sthd = $dbh->prepare($inhalt);
	$sthd->execute();
	while (my @row = $sthd->fetchrow()) {
		$count++;	
		$matches .= "$row[0]\n";
	}
	if ($count > 0) {
		$mail_body{$user} .= "You have $count matches for $name\n$matches";
		$mail_body{$user} .= "Please check $mailurl?host=$host&db=$db&uid=$user&lang=$lang&workflow=$row[0]\n\n";
	}
 	$sthd->finish();
}

$sth->finish();
$dbh->disconnect();

# Opening log, if logfile don't exists, create it
if (!(-f $logfile)) {
	open FOUT, ">$logfile" or die "Can't open $logfile\n";
	print FOUT $logheader;
	close FOUT;	
}
open FOUT, ">>$logfile" or die "Can't open $logfile\n";

# Sending emails
foreach my $user (keys %mail_body) {
	my $mailto = get_user_email($user);
	my %mail = (To => $mailto, From => $mailfrom, Subject => $subject, Message => $mail_body{$user});
	my $ret = sendmail(%mail);
	print FOUT "$localtime \t sent mail to $user ($mailto)\n" if ($ret == 1);
}

close FOUT;

# -----------------------------------------------
# Functions

sub get_user_email
{
	my $uid = shift;
	return "mstocker\@archivista.ch";	
}
