#!/usr/bin/perl

=head1 splitTableImages.pl -> split archivbilder in archivexxxxx

(c) v1.0 - 2.8.2008 by Archivista GmbH, Urs Pfister

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

use constant TYPE_CHAR => 'varchar'; # mysql field types
use constant TYPE_CHARFIX => 'char';
use constant TYPE_TIMESTAMP => 'timestamp';
use constant TYPE_YESNO => 'tinyint';
use constant TYPE_INT => 'int';
use constant TYPE_BLOB => 'blob';
use constant TYPE_TEXT => 'text';
use constant TYPE_MEDIUMBLOB => 'mediumblob';
use constant TYPE_LONGBLOB => 'longblob';
use constant TYPE_DATE => 'datetime';
use constant TYPE_KEY => 'PRI';
use constant TYPE_FULLTEXT => 'fulltext';

my $db1 = shift; # check database/folder stucture (0=one table,1-100=x tables)
my $action = shift;
die "usage: $0 database add|remove\n" if $db1 eq "" || $action eq "";

my $dbh;
logit("program started with $db1 and action $action");
if ($dbh=MySQLOpen()) { # open database and check for slave
  die if HostIsSlave($dbh);
	my $sql = "select Inhalt from $db1.parameter where Name='SHOW_FIELDSOCR'";
	my @row = $dbh->selectrow_array($sql);
	if (($row[0] == 1) && $action eq "add") {
	  logit("fields2ocr is enabled");
	  updateFields($dbh,$db1,0);
	} elsif ($row[0] == 0 && $action eq "remove") {
	  updateFields($dbh,$db1,1);
	} elsif ($row[0] == 1 && $action eq "remove") {
	  logit("please switch off option in WebAdmin");
	} else {
	  logit("please switch on option in WebAdmin");
	}
	logit("program ended with $db1 and action $action"); 
}



sub updateFields {
  my ($dbh,$db1,$kill) = @_;
  my $pfields=getFields($dbh,"archiv",$db1);
  my @fields = @$pfields;
  my $notiz=0;
  for(my $nr=0;$nr<100;$nr++) {
    if ($fields[$nr]->{name} eq "Notiz") {
		  $notiz=$nr;
			last;
		}
	}
	my $count = 0;
	if ($notiz>0) {
	  logit("note table field at postion $notiz");
	  my $sql = "select Laufnummer from $db1.archiv order by Laufnummer asc";
		my $prow = $dbh->selectall_arrayref($sql);
		my @rows = ();
		foreach (@$prow) {
		  my $akt = $$_[0];
			push @rows,$akt;
		}
		foreach my $akt (@rows) {
		  $count++;
		  $sql = "select * from $db1.archiv where Laufnummer=$akt limit 1";
	    my @row = $dbh->selectrow_array($sql);
			my $doc = $row[2];
			my $pages = $row[3];
			$akt = $doc+1;
			if ($doc>0) {
			  if ($doc % 1000 ==0) {
			    logit("process document at $doc doc with $pages pages");
				}
			  my %text = ();
				if ($kill != 1) {
			    for (my $c=0;$c<$notiz;$c++) {
			      next if $c==2 || $c==3; # do not add Akte/Seiten
			      my $val = $row[$c];
			      my $fld = $fields[$c]->{name}; 
				    my $type = $fields[$c]->{type};
            if ($type eq TYPE_CHAR || $type eq TYPE_TEXT || 
				        $type eq TYPE_CHARFIX) {
					    MainUpdateText($fld,$val,\%text);
            } elsif ($type eq TYPE_YESNO) {
				      # nothing to do
            } elsif ($type eq TYPE_DATE) {
				      # nothing to do
            } else {
              MainUpdateText($fld,$val,\%text);
					  }
					}
				}
			  MainUpdateTextUpdate($dbh,$db1,$doc,$pages,\%text,$kill);
			}
	  }
	}
	logit("$count documents processed");
}

