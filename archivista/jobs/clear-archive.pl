#!/usr/bin/perl

=head1 Main

This Programm was designed to clean up the archive table.
It expects two parameter.

Fisrt: 'Folders' or 'Documents'
Second: Database
Third: X-Y or X

=cut

use strict;
use DBI;
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;

use Archivista::Config;
my $config = Archivista::Config->new;
my $pw = $config->get("MYSQL_PWD");
my $user = "root";
my $host = "localhost";

use constant TABLE => 'archiv';

my ($action,$database,$range,$res,$x,$y,$dsn,$dbh);

$action = shift;
$database = shift;
$range = shift;

my $return;
if($database) {
  if(check_action($action)) {
    ($x,$y) = split('-',$range);
    if (check_range(\$x,\$y)) {
		  if ($dbh=MySQLOpen($host,$database,$user,$pw)) {
        if (checkDatabase($dbh,$database)) {
          my $rows = clear($action,$dbh,$x,$y);
          $dbh->disconnect();
					$return = $rows;
        }
      }
    }
  }
}
print $return;






=head1 check_action

Check if Action is known

=cut

sub check_action {
  my $action = shift;

  my $ok = 0;
  foreach my $a ('Folders','Documents') {
    if ($action eq $a) {
      $ok = 1;
    }
  }
  return $ok;
}






=head1 check_range

=cut

sub check_range {
  my ($tmp,$px,$py);
  $px = shift;
  $py = shift;

	# Check if both values are set
	# before we check if start (x) is greater than end (y).
  $$py = $$px if ($$py eq '');

  if($$px > $$py) {
    $tmp = $$px;
    $$px = $$py;
    $$py = $tmp;
  }

  if($$px > 0) {
    if($$py >= $$px) {
      return 1;
    } else {
      return 0;
    }
  } else {
    return 0;
  }
}






=head1 clear

=cut

sub clear {
  my ($action,$dbh,$x,$y,$min,$max);
  $action = shift;
  #my $av = shift;
  $dbh = shift;
  $x = shift;
  $y = shift;
	my $rows = 0;

  if($action eq 'Folders') {
    for(my $ordner = $x;$ordner <=$y;$ordner++) {
      while(my $akte = get_doc($dbh,"min",$ordner)) {
        clear_pages_images($dbh,$akte);
        clear_doc($dbh,$akte);
				$rows++;
      }
    }
  } elsif($action eq 'Documents') {
    for(my $akte = $x;$akte<=$y;$akte++) {
      clear_pages_images($dbh,$akte);
      clear_doc($dbh,$akte);
			$rows++;
    }
  }
	return $rows;
}







sub get_doc {
  my ($dbh,$function,$folder,$sql,$res);
  $dbh = shift;
  $function = shift;
  $folder = shift;
  $sql = "select $function(Laufnummer) from archiv where Ordner = $folder";
  $res = $dbh->selectrow_arrayref($sql);
  return $res->[0];
}






sub clear_pages_images {
  my ($dbh,$akte,@tables,$table,$seitemin,$seitemax,$sql);
  $dbh = shift;
  $akte = shift;
  @tables = ('archivseiten','archivbilder');
  $seitemin = $akte*1000;
  $seitemax = ($akte*1000)+999;
  foreach $table (@tables) {
    $sql = "delete from $table "
            . "where Seite between $seitemin and $seitemax";
    $dbh->do($sql);
  }
}






sub clear_doc {
  my ($dbh,$akte,$table,$sql,$res);
  $dbh = shift;
  $akte = shift;
  $table = 'archiv';
  $sql = "delete from $table where Laufnummer = $akte";
  $res = $dbh->do($sql);
  return $res;
}
