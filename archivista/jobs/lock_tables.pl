#!/usr/bin/perl

use strict;
use DBI;

my $file = "/home/data/archivista/mysql/log-pos";
my $user = "root";
my $pass = shift;
my $host = "localhost";

sleep(15); # Give the Bash Script some time to create the log-pos file

if (-e $file) {
  # Our file was created
	# Connected to db
  my $dsn = "DBI:mysql:host=$host;";
  my $dbh = DBI->connect($dsn,$user,$pass);
  
	if ($dbh) {
    my $sql = "FLUSH TABLES WITH READ LOCK";
    $dbh->do($sql);

	  # Do not need to execute $sql again
    # because the connection is still alive
		# just wait a second
    sleep(0.5) while (-e $file);

	  $dbh->disconnect();
  } else {
	  die("No Database Connection");
	}
}
