#!/usr/bin/perl

=head1 sane-button.pl (c) 20.9.2005 by Archivista GmbH, Urs Pfister

This script acts as the backend for a scan button. As soon as numeric 
key and the ENTER key is pressed, the scan job will be started here.

=cut

use strict;
use Archivista::Config; # is needed for the passwords and other settings
use DBI;

my $JOB = "SANE"; # we have a SANE job
my $SLEEP = 1; # Seconds we wait after a job was done

# DBI data for jobs table
my %val;
$val{dirsep} = "/"; # seperate a directory ((windows/linux)
$val{log}       = '/home/data/archivista/av.log';
my $config = Archivista::Config->new;
$val{host} = $config->get("MYSQL_HOST");
$val{db} = $config->get("MYSQL_DB");
$val{user} = $config->get("MYSQL_UID");
$val{pw} = $config->get("MYSQL_PWD");
$val{scanadf} = $config->get("SCAN_ADF_BIN"); # path to scanadf
$val{scanid}; # the name of the scan definition 
$val{jobid}; # the id from the jobs table
$val{logid}; # the id for the logs table
$val{logtype} = "sne"; # type in logs table
$val{nr}; # archviista document number (if existing document)
$val{dbh}; # db handler for logs and jobs tables
$val{dbh2}; # db handler for current scan definition
# Here we can configure where we want to save the images
$val{host1}="localhost"; 
$val{db1}="archivista";
$val{user1}="Admin";
$val{pw1}="archivista";
undef $config;

logit("script started");
if (MySQLOpen(\%val)) {
  my $scan=1;
	$val{user2}=$val{user1};
  if ($val{host1} eq "localhost") {
    my $sql1 = "select uid from sessionweb where host='localhost' ".
		           "and datum > now()-300 order by datum desc limit 1";
		my $sql2 = $sql1;
	  my @user = $val{dbh}->selectrow_array($sql1);
		my $user1 = $user[0];
		$sql1 = "select Inhalt from ".$val{db}.".parameter ".
		        "where Name = 'ACCESS_LOG' and Art='parameter'";
		my @acc = $val{dbh}->selectrow_array($sql1);
		my $acc1 = $acc[0];
		$scan=0 if $acc1==1 && $user1 eq "";
		$val{user2}=$user1 if $user1 ne "";
	}
  # connection to mysql is ok
  # get back the button and the desired id
  my $button = shift;
	my $scanid = shift;
	my $db1 = shift;
	logit("$button -- $scanid -- $db1");
	if ($button == -2 && HostIsSlave($val{dbh})==0 && $scan==1) {
	  # the scan button was pressed
  	logit("Scanning with id: $scanid");
		# now save the entry to the jobs table
		if ($val{host1} ne "") {
		  # if we did choose an alternative scan button, just use it
		  $val{host}=$val{host1};
			if ($db1 ne "") {
			  $val{db}=$db1;
			} else {
			  my @databases = split(',',$val{db1});
				my $database = shift @databases;
				my ($dbname,$id) = split(':',$database);
				$dbname = "archivista" if $dbname eq "";
			  $val{db}=$dbname;
			}
			$val{user}=$val{user1};
			$val{pw}=$val{pw1};
		}
		my $sql = "insert into jobs set " .
		          "job = 'SANE'," .
							"host = ".$val{dbh}->quote($val{host})."," .
							"db = ".$val{dbh}->quote($val{db})."," .
							"user = ".$val{dbh}->quote($val{user})."," .
							"pwd = ".$val{dbh}->quote($val{pw})."," .
							"status = 100";
	  logit("$sql");
		$val{dbh}->do($sql);

    # now get back the last row number
		$sql="select last_insert_id()";
    my @row=$val{dbh}->selectrow_array($sql);
    my $id=$row[0];
		if ($id>0) {
      MySQLOpen2(\%val);
		  # if this is ok, now lets select the scanning definitions
      $sql="select Inhalt from parameter where Name='ScannenDefinitionen'";
    	@row=$val{dbh2}->selectrow_array($sql);
    	my $scandef=$row[0];
	    my @scannen=split("\r\n",$scandef);
			my $c=0;
			my $scantext = "";
			foreach (@scannen) {
			  my @vals = split(";",$scannen[$c]);
			  if ($c==0) {
				  if ($vals[22]<=0) {
					  # old manner just use all definitions
	          # we also want to access definition 0, so 1 minus
            $scanid--;
			      $scanid=0 if $scannen[$scanid] eq "";
			      $scantext=$scannen[$scanid];
						last;
					}
				}
				if ($vals[22] == $scanid && $vals[18] != 1) {
			    $scantext=$scannen[$c];
			    last;
				}
				$c++;
			}
			if ($scantext ne "") {
			  # now, save the definition name to the jobs_data table
			  $sql = "INSERT INTO jobs_data SET " .
			         "jid = $id, " .
			         "param = 'SCAN_DEFINITION', " .
						   "value = " . $val{dbh}->quote($scantext);
		    # save it
			  $val{dbh}->do($sql);
     	  # now, save the definition name to the jobs_data table
			  $sql = "INSERT INTO jobs_data SET " .
			         "jid = $id, " .
			         "param = 'SCAN_USER', " .
						   "value = " . $val{dbh}->quote($val{user2});
			  $val{dbh}->do($sql);
			  $val{dbh2}->disconnect();
			}
		}
	}
  # disconnect
	$val{dbh}->disconnect();
  logit("script ended");
}






=head2 $dbh=MySQLOpen(%$val)

  Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen {
  my $pval = shift;
  my ($ds);
  $ds = "DBI:mysql:host=$$pval{host};database=$$pval{db}";
  $$pval{dbh}=DBI->connect($ds,$$pval{user},$$pval{pw});
  return $$pval{dbh};
}






=head2 $dbh=MySQLOpen2(%$val)

  Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen2 {
  my $pval = shift;
  my ($ds);
  $ds = "DBI:mysql:host=$$pval{host};database=$$pval{db}";
  $$pval{dbh2}=DBI->connect($ds,$$pval{user},$$pval{pw});
  return $$pval{dbh2};
}






=head1 $slave=HostIsSlave($dbh)

gives back a 1 if we are in slave mode

=cut

sub HostIsSlave {
  my $dbh = shift;
  my $hostIsSlave = 0;
  my $sth = $dbh->prepare("SHOW SLAVE STATUS");
  $sth->execute();
  if ($sth->rows) {
    my @row = $sth->fetchrow_array();
    $hostIsSlave = 1 if ($row[9] eq 'Yes');
  }
  $sth->finish();
	if ($hostIsSlave==0) {
	  my @row = $dbh->selectrow_array("SHOW VARIABLES LIKE 'server%'");
		$hostIsSlave=1 if $row[1]>1;
	}
	return $hostIsSlave;
}




=head1 logit($message)

Writes a message to a log file

=cut

sub logit {
  my $stamp   = TimeStamp();
  my $message = shift;
  # $log file name comes from outside
  my @parts = split($val{dirsep},$0);
  my $prg = pop @parts;
  open( FOUT, ">>$val{log}" );
  binmode(FOUT);
  my $logtext = $prg . " " . $stamp . " " . $message . "\n";
  print FOUT $logtext;
  close(FOUT);
}





=head2 $stamp=TimeStamp 

Actual date/time stamp (20040323130556)

=cut

sub TimeStamp {
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y     = $t[5] + 1900;
  $m     = $t[4] + 1;
  $m     = sprintf( "%02d", $m );
  $d     = sprintf( "%02d", $t[3] );
  $h     = sprintf( "%02d", $t[2] );
  $mi    = sprintf( "%02d", $t[1] );
  $s     = sprintf( "%02d", $t[0] );
  $stamp = $y . $m . $d . $h . $mi . $s;
  return $stamp;
}












