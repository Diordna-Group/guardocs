#!/usr/bin/perl

use DBI;
use Archivista;

my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $uid = $config->get("MYSQL_UID");
my $pwd = $config->get("MYSQL_PWD");

my $debiancnf = "/etc/mysql/debian.cnf";

my $dbh = DBI->connect("DBI:mysql:host=$host;database=",$uid,$pwd);

# Read the debian.cnf file
open FIN, $debiancnf;
my @fin = <FIN>;
close FIN;

my %data;

# Check all configuration lines
foreach my $cnfline (@fin) {
	next if !( $cnfline =~ /=/);
	my ($key, $value) = split /=/, $cnfline;
	chomp $value;
	$key =~ s/\s//g;
	$value =~ s/\s//g;
	$data{$key} = $value;
}

# Add debian-sys-maint user to mysql
my $query = "GRANT ALL ON *.* TO " .
						"'$data{'user'}'\@'$data{'host'}' " .
						"IDENTIFIED BY '$data{'password'}'";
$dbh->do($query);

print "User $data{'user'} \@ $data{'host'} added to mysql!\n";

$dbh->disconnect;
