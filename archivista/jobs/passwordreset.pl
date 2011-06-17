#!/usr/bin/perl

# (c) 2006-06-13 by Archivista GmbH, Urs Pfister

=head1 $sucess=passwordreset.pl user@host

Resets the password for the given user.

=cut

use lib qw(/home/cvs/archivista/jobs/);
use strict;
use DBI;
use AVJobs;

my $fulluser = shift;
my $error=1;
my $dbh=MySQLOpen();
if ($dbh) {
	my ($user,$host)=split('@',$fulluser);
	$host="localhost" if $host eq "127.0.0.1"; # local IP
	$host="localhost" if $host eq ""; # no IP means localhost
	# the following two accounts are not allowed because we use them also in the
	# linux system
	exit $error if $user eq "root" and $host eq "localhost"; 
	exit $error if $user eq "SYSOP" and $host eq "localhost";
	if ($user ne "" && $host ne "") {
	  # only set password back if we have a host/user
	  my $user1=$dbh->quote($user);
	  my $host1=$dbh->quote($host);
    my $sql="set  password for $user1\@$host1=Password('')";
		$dbh->do($sql); # send it to the db
		# now, do a check if we really have no password for this user
		$sql = "select User,Host,Password " .
		       "from mysql.user where User=$user1 and	Host=$host1";
		my @row = $dbh->selectrow_array($sql);
		# if we find a user with the given host with an empty password, it is ok
		$error=0 if ($user eq $row[0] && $host eq $row[1] && $row[2] eq ""); 
	}
  $dbh->disconnect;
}
exit $error;
