#!/usr/bin/perl

=head1 sane-post.pl --- (c) by Archivista GmbH, v1.3 2.10.2005

  Add images coming from sane-client.pl to Archivista database

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my $dbh = MySQLOpen();
if ($dbh) {
  for (my $c=1;$c<1000;$c++) {
    my $sql="select id,host,db,user,pwd,Laufnummer from logs where DONE=1";
    my ($id,$host,$db,$user,$pwd,$lnr)=$dbh->selectrow_array($sql);
		if ($lnr>0) {
		  my $dbh2=MySQLOpen($host,$db,$user,$pwd);
			if ($dbh2) {
			  my $sql="update archiv set Gesperrt='' where Laufnummer=$lnr";
				$dbh2->do($sql);
				$dbh2->disconnect();
			}
      my $sql="update logs set DONE=0,ERROR=0 where id=$id";
			$dbh->do($sql);
		} else {
		  last;
		}
  }
	$dbh->disconnect();
}

