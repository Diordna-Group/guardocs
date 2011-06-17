#!/usr/bin/perl

use strict;
use DBI;

# get the pdf file as file name
my (@fin,$t,@pages,$page,$c,$cl,$p2t,$pdftk);

my $host = "192.168.50.40";
my $db = "archiv401";
my $user = "Admin";
my $pw = "*****";
my $st = 95800;
my $end = 160000;

my $dbh=MySQLOpen($host,$db,$user,$pw);
if ($dbh) {
  my $c=$st;
  my $sql = "select Laufnummer from archiv where Seiten>0 and " .
	          "Bereich='Lieferanten'";
	my $prows=$dbh->selectall_arrayref($sql);
	foreach (@$prows) {
	  my $lnr = $$_[0];
		my $sql="select Laufnummer from archiv.archiv where Laufnummer=$lnr";
		my @row1=$dbh->selectrow_array($sql);
		if ($row1[0]==0) {
		  print "not found $lnr\n";
		}
	}
	$dbh->disconnect();
}


=head3 MySQLOpen -> Open a MySQL handler and gives back a db handler

=cut

sub MySQLOpen {
    my $host = shift;
    my $db = shift;
    my $user = shift;
    my $pw = shift;
    my ($dbh,$ds);
    $ds = "DBI:mysql:host=$host;database=$db";
    $dbh=DBI->connect($ds,$user,$pw);
    return $dbh;
}



