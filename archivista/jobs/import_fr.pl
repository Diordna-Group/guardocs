#!/usr/bin/perl

use strict;
use AVJobs;

open(FIN,"languages.txt");
my @all = <FIN>;
close(FIN);

my $dbh = MySQLOpen();
if ($dbh) {
  foreach (@all) {
	  my ($key,$comm,$en,$de,$fr,$it) = split(/\t/,$_);
		my $sql = "update languages set fr=".$dbh->quote($fr)." ". 
		          "where id=".$dbh->quote($key);
		print "$sql\n";
		$dbh->do($sql);
	}
}

