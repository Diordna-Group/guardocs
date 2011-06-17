#!/usr/bin/perl

=head1 adjustRights.pl -> give one/all user/s rights to access extended tables

(c) v1.0 - 5.8.2008 by Archivista GmbH, Urs Pfister

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

use constant GRANT => 'grant';
use constant REVOKE => 'revoke';

my $db1 = shift; # get the table from command line
stopit() if $db1 eq "";
my $rights = shift; # get the rights from command line
if ($rights eq GRANT || $rights eq REVOKE) {
  my $user = shift;
  my $host = shift;
	$host = "localhost" if $host eq "";
  my $dbh;
  if ($dbh=MySQLOpen()) {
    die if HostIsSlave($dbh); # stop it if we are on slave
    # coonection is ok
	  my @tables = ();
	  my $sql = "show tables from $db1 like 'archimg%'";
	  my $res = $dbh->selectall_arrayref($sql);
	  foreach my $res1 (@$res) { # get all tables
	    push @tables,$$res1[0];
	  }
		my $whe = "";
		if ($user ne "") {
		  $whe = "where user=".$dbh->quote($user)." and host=".$dbh->quote($host);
		}
	  $sql = "select host,user,level from $db1.user $whe";
	  $res = $dbh->selectall_arrayref($sql);
	  foreach my $res1 (@$res) {
	    my $host = $$res1[0];
		  my $user = $$res1[1];
			my $level = $$res1[2];
			changeRights($dbh,$db1,\@tables,$rights,$host,$user,$level);
		}
	}
} else {
  stopit();
}






=head changeRights($dbh,$db1,$ptables,$rights,$host,$user,$level)

Change the rights for one user in all tables

=cut

sub changeRights {
  my ($dbh,$db1,$ptables,$rights,$host,$user,$level) = @_;
	my $sqluser = $dbh->quote($user)."\@".$dbh->quote($host);
  foreach (@$ptables) {
	  my $table = $_;
	  my ($sql1,$sql2,$sql3);
	  if ($rights eq GRANT) {
		  $sql1 = "$rights select on";
			$sql2 = "to";
			$sql3 = "with grant option" if $level==255;
		} else {
		  $sql1 = "$rights all on";
		  my $sql1a = "$rights grant option on";
			$sql2 = "from";
		  my $sql = "$sql1a $db1.$table $sql2 $sqluser $sql3";
			$dbh->do($sql);
		}
		my $sql = "$sql1 $db1.$table $sql2 $sqluser $sql3";
		$dbh->do($sql);
	}
}







=head1 stopit

Command line parameters not ok

=cut

sub stopit {
  print STDERR "$0: database right(grant|revoke) [user] [host]\n";
	die;
}


