#!/usr/bin/perl


=head1 valuessync.pl

(c) 2006, Archivista GmbH, tb

script looks for Documents with no entries in specified fields.
If it finds some, it will look for FTP Jobs in the same database,
which have the same specified match fields and copy their values 
to the Documents with the empty entries.

=cut

use lib "/home/cvs/archivista/jobs/";
use AVDocs;
use strict;

my $database = "testumgebung";
my @matchfields = ("Auftraggeber","Auftrag");
my @syncfields = ("syncthis1","syncthis2");

my $av = AVDocs->new();

$av->setDatabase($database) || die "Could not change to DB";

#We need an Array with only NULL queries
#because we need to check for them in the db
my @nullarray;
for (my $i = 0; $i <= length @syncfields;$i++) {
  push  @nullarray, undef;
}

my ($psne,$pftp) = getJobsSpec();
my @nullrecs = $av->keys(\@syncfields,\@nullarray);
foreach (@nullrecs) {
	my $key = $_;
	my (@syncs,$isSane,$done);
  #Only check for SANE Jobs
	foreach (@$psne) {
		if ($key eq $_) {
		  $isSane = 1;
		}
	}
	next if ($isSane != 1);
	my @matchings = $av->select(\@matchfields,$av->FLD_DOC,$key);
	#Check if there is an ftp job with the matching values
	foreach (reverse @$pftp) {
		last if ($done == 1);
	  my $laufnummer = $_;
		my @select = $av->select(\@matchfields,$av->FLD_DOC,$laufnummer);
		foreach (@select) {
		  last if ($done == 1);
			my $sel = $_;
			#Its ok if only one of the values in the match field array
			#matches our value. 
      foreach (@matchings) {
			  my $mf = $_;
				if ($sel eq $mf) {
		      @syncs = $av->select(\@syncfields);
			    $done = 1;
				}
			}
		}
	}
	my $ok = $av->update(\@syncfields,\@syncs,$av->FLD_DOC,$key);
}

sub getJobsSpec {
  my (@ftp,@sne);
  $av->setDatabase("archivista") || die "could not change to archivista db";
  $av->setTable($av->TABLE_LOGS) || die "could not find logs table";
  #GET SANE JOBS
	my $pfields = [$av->FLD_LOGTYPE,$av->FLD_LOGDB];
  my $pvals = ["sne",$database];
  my @snekeys = $av->keys($pfields,$pvals);
	my $plnv = [$av->FLD_LOGDOC];
	foreach (@snekeys) {
	  my $key = $_;
    my @ln = $av->select($plnv,$av->FLD_LOGID,$key);
		push @sne, $ln[0];
	}
  #GET FTP JOBS
	my $pfields = [$av->FLD_LOGTYPE,$av->FLD_LOGDB];
  my $pvals = ["ftp",$database];
  my @ftpkeys = $av->keys($pfields,$pvals);
	my $plnv = [$av->FLD_LOGDOC];
	foreach (@ftpkeys) {
	  my $key = $_;
    my @ln = $av->select($plnv,$av->FLD_LOGID,$key);
		push @ftp, $ln[0];
	}
	$av->setDatabase($database) || die "could not change back to $database";
	return \@sne,\@ftp;
}

