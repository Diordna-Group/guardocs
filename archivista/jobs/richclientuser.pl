#!/usr/bin/perl

# (c) 2006-06-13 by Archivista GmbH, Urs Pfister

=head1 $sucess=passwordreset.pl user@host

Resets the password for the given user.

=cut

use lib qw(/home/cvs/archivista/jobs/);
use strict;
use DBI;
use AVJobs;
use fields;

my $val = {};
my $log = "/home/cvs/archivista/jobs/log.xt";
my $success = 0;

$val->{modus} = shift;
$val->{user} = shift;
$val->{pw} = shift;
$val->{mess} = shift;
$val->{yes} = shift;
$val->{no} = shift;

my ($user,$host) = split('@',$val->{user});

if ($user ne ""  && ($host ne "" && $host ne "localhost")) {
  my $dbh = MySQLOpen();
  if($dbh){
    # Database Handler OK
    # Look now if our User exists
    if(existsUser($dbh,$user,$host)){
      if($val->{modus} eq "status"){
        # If Modus equal STATUS then getStatus of user with host
        $success = getStatus($dbh,$user,$host);
      } else {
        # If Modus equal something else use setPriv.
        $success = setPriv($dbh,$user,$host,$val->{modus},$val->{pw});
      }
    } else {
      # compose Xdialog construc
      my $cmd = qq(Xdialog --stdout --ok-label ").$val->{yes}.
			          qq(" --cancel-label ").$val->{no}.
								qq(" --yesno ").$val->{mess}.qq(" 8 60 );
      # get back all select entries
      my $ant = system($cmd);
      if ($ant==0) {
        print "User $user added\n";
        $success = setPriv($dbh,$user,$host,"grant",$val->{pw});
        $success = 3 if $success==1;
      }
    }
  }
  $dbh->disconnect();
}
exit $success;






=head2 (boolean)=existsUser ( $dbh, $user, $host );

Looks if User $user with $host exists. Returns 1 for true and 0 for False.

=cut

sub existsUser {
  my $dbh = shift;
  my $user = shift;
  my $host = shift;

  my $sql = "select User from mysql.user where "
          . "User=".$dbh->quote($user)." and Host=".$dbh->quote($host);

  my @row = $dbh->selectrow_array($sql);
  if($row[0]){
    return 1; # User/host found return 1 for successful
  } else {
    return 0; # User/host not found return 0 for error
  }
}





=head2 (status)=getStatus ( $dbh, $user, $host )

Returns 1 if User Rights don't exist. Returns 2 if User Rights exists.

=cut

sub getStatus {
  my $dbh = shift;
  my $user = shift;
  my $host = shift;

  my $sql = "select Table_priv from mysql.tables_priv "
          . "where Db='archivista' and User=".$dbh->quote($user)
          . "and Host=".$dbh->quote($host)." and table_name='jobs';";

  my @row = $dbh->selectrow_array($sql);

  my $sql2 = "select Table_priv from mysql.tables_priv "
          . "where Db='archivista' and User=".$dbh->quote($user)
          . "and Host=".$dbh->quote($host)." and table_name='jobs_data';";

  my @row2 = $dbh->selectrow_array($sql2);

  if($row[0] && $row2[0]){
    return 2;  # It exist so we return 2 (to revoke privileges)
  } else {
    return 1;  # Doesn't exist return 1 (to grant privileges)
  }
}





=head2 (boolean)=setPriv ( $dbh, $user, $host, $modus )

if $modus equals grant it grants the Rights for $user with $host.
if $modus equals revoke it revokes the Rights from $user with $host.
It Returns 0 if all went well else it returns 0.

=cut

sub setPriv {
  my $dbh = shift;
  my $user = shift;
  my $host = shift;
  my $modus = shift;
  my $pass = shift;

  my ($sql,$sql2,$sqlpw);
  my $userhost = $dbh->quote($user).'@'.$dbh->quote($host);
  if($modus eq "grant"){
    # Set sql and sql2 for GRANT
    $sql = "grant select,insert,update,delete on archivista.jobs to $userhost";
    $sql2 = "grant select,insert,update,delete on archivista.jobs_data to $userhost";
  } elsif ($modus eq "revoke") {
    # Set sql and sql2 for REVOKE
    $sql = "revoke all on archivista.jobs from $userhost";
    $sql2 = "revoke all on archivista.jobs_data from $userhost";
  }
  # Executs $sql and $sql2 saves to $res and $res2
  my $res = execQuery($dbh,$sql);
  my $res2 = execQuery($dbh,$sql2);
  execQuery($dbh,"flush privileges");

  if ($pass ne "") {
    # set the password for a given user
    $pass=$dbh->quote($pass);
	  if (check64bit()==64) {
      $sqlpw = "set Password for $userhost=OLD_PASSWORD($pass)";
		} else {
      $sqlpw = "set Password for $userhost=PASSWORD($pass)";
		}
    my $respw = execQuery($dbh,$sqlpw);
  }

  # if $res and $res2 equal 1 return 1 for ok else 0 for error
  if($res && $res2){
    return 1;
  } else {
    return 0;
  }
}





=head2 $res=execQuery($dbh,$sql)

Executs the SQL-Query ($sql) and returns 1 or 0

=cut

sub execQuery {
  my $dbh = shift;
  my $sql = shift;

  if ($dbh->do($sql)){
    return 1;
  } else {
    return 0;
  }
}

