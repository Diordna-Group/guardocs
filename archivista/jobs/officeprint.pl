#!/usr/bin/perl

=head1 processweb.pl (c) 17.3.2008 by Archivista GmbH, Urs Pfister

This script processes an uploaded file from WebClient

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;
my %val;
$val{jobid} = shift; # the id from the jobs table

use constant JOB_INIT => 100; # ready to start scanadf
use constant JOB_WORK => 110; # prepare the scan process
use constant JOB_WORK2 => 111; # call another script to work with
use constant JOB_DONE => 120; # scanadf job was started

$val{dbh} = MySQLOpen();
if ($val{dbh}) {
  if (HostIsSlave($val{dbh})==0) {
    # get the next job
    my $sql = "select id,host,db,user,pwd,job from jobs " .
              "where id = $val{jobid}";
    my ($id,$host,$db,$user,$pwd,$type) = $val{dbh}->selectrow_array($sql);
		if ($id==$val{jobid}) {
      my $fname = selectValue(\%val,"FILENAME");
	    logit("officeprint with $fname");
			my @parts = split(/\//,$fname);
			my $fname1 = pop @parts;
			my $db1 = pop @parts;
			my $type = pop @parts;
			my $ftp = pop @parts;
			$db = $db1 if $ftp eq "ftp" && $type eq "office";
      my $scandef = getScanDefByNumber($val{dbh},$db,0);
			saveJob($val{dbh},$host,$db,$user,$pwd,$fname,$scandef,0);
      $sql="update jobs set pwd='',status=".JOB_DONE." where id=$val{jobid}";
      $val{dbh}->do($sql);
		}
	}
}






=head1 saveJob($dbh,$host,$db,$user,$pwd,$filename,$def,$nr)

Create a web upload job

=cut

sub saveJob {
  my ($dbh,$host,$db,$user,$pwd,$filename,$def,$nr) = @_;
  my $sql = "INSERT INTO jobs SET job='WEB',status=".JOB_WORK."," .
     "host=".$dbh->quote($host).",db=".$dbh->quote($db)."," .
     "user=".$dbh->quote($user).",pwd=".$dbh->quote($pwd);
	$dbh->do($sql);
  $sql = "select LAST_INSERT_ID()";
	my ($id) = $dbh->selectrow_array($sql);
  $sql = "insert into jobs_data set jid=$id,";
	my $sql1 = $sql."param='SCAN_DEFINITION',value=".$dbh->quote($def);
	$dbh->do($sql1);
	$sql1 = $sql."param='WEB_FILE',value=".$dbh->quote($filename);
	$dbh->do($sql1);
	$sql1 = $sql."param='WEB_DEF',value=".$dbh->quote($nr);
	$dbh->do($sql1);
  $sql = "UPDATE jobs set status=".JOB_INIT." where id=$id";
	$dbh->do($sql);
}






=head1 $val=selectValue($pval,$attr)

Give back a volue from job_data table

=cut

sub selectValue {
  my ($pval,$attr) = @_;
	my $attr1 = $$pval{dbh}->quote($attr);
  my $sql = "select value from jobs_data " .
            "where jid=$$pval{jobid} and param=$attr1 limit 1";
  my @f = $$pval{dbh}->selectrow_array($sql);
  # store the actual scan definition
	return $f[0];
}

