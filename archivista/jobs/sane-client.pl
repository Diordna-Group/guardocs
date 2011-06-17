#!/usr/bin/perl

=head1 sane-client.pl --- (c) by Archivista GmbH, v1.2 18.9.2005

Add images coming from scanadf to Archivista
        
=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use AVJobs;
use AVScan;

use constant JOB_INIT => 100; # ready to start scanadf
use constant JOB_WORK => 110; # prepare the scan process
use constant JOB_WORK2 => 111; # call another script to work with
use constant JOB_DONE => 120; # scanadf job was started
use constant LOG_DONE => 0; # everything is ok, ocr not done
use constant LOG_WORK => 1; # someone is working with the document
use constant LOG_AXISDONE => 2; # axis job is done, sane-client can get it
use constant LOG_OCR => 3; # the ocr engine is saving pdf files
use constant LOG_OCRDONE => 4; # the ocr recognition is done
use constant LOG_SCANSTART => 5; # we did start the scanadf job
use constant LOG_SCANADF => 6; # scanadf is working (on pages)
use constant LOG_SCANDONE => 7; # scanadf job is done, but not yet sane-post.pl

logit("job server started");
my $scandef = $ENV{'AV_SCAN_DEFINITION'};
my $fields = $ENV{'SCAN_FIELDS'};
my $obj = AVScan->new($scandef,$fields);
$obj->host($ENV{'AV_SCAN_HOST'});
$obj->database($ENV{'AV_SCAN_DB'});
$obj->user($ENV{'AV_SCAN_USER'});
$obj->password($ENV{'AV_SCAN_PWD'});
$obj->job($ENV{'AV_SCAN_JOBS_ID'});
$obj->owner($ENV{'AV_SCAN_OWNER'});
$obj->doc($ENV{'AV_SCAN_TO_DOCUMENT'});
$obj->ds($ENV{'AV_SCAN_PATH_DS'}) if $ENV{'AV_SCAN_PATH_DS'} ne "";
$obj->path($ENV{'AV_SCAN_PATH'}) if $ENV{'AV_SCAN_PATH'} ne "";
$obj->base($ENV{'AV_SCAN_BASE'}) if $ENV{'AV_SCAN_BASE'} ne "";
$obj->ext($ENV{'AV_SCAN_EXT'}) if $ENV{'AV_SCAN_EXT'} ne "";
$obj->end($ENV{'AV_SCAN_END'}) if $ENV{'AV_SCAN_END'} ne "";
$obj->rotate2($ENV{'PAGE_ROTATION'});
$obj->source($ENV{'AV_SOURCE'});
$obj->source2($ENV{'AV_SOURCE2'});
$obj->nolog($ENV{'AV_SCAN_NO_LOG'});
$obj->addtext($ENV{'AV_SOURCE3'});
$obj->jobstop($ENV{'AV_SCAN_STOP'}) if $ENV{'AV_SCAN_STOP'} ne "";
$obj->versions($ENV{'SCAN_VERSIONS'});
$obj->versions_val($ENV{'SCAN_VERSIONS_VAL'});
$obj->versionkey($ENV{'SCAN_VERSIONKEY'});
$obj->versionkey_val($ENV{'SCAN_VERSIONKEY_VAL'});
$obj->officeimages($ENV{'AV_OFFICE_IMAGES'});

$obj->dbh(MySQLOpen());
if ($obj->dbh) {
  $obj->dbh2(MySQLOpen($obj->host,$obj->database,$obj->user,$obj->password));
	if ($obj->dbh2) {
    if (HostIsSlaveSimple($obj->dbh2)==0) {
		  initvals($obj);
			my $nr=1; # image number
	    while($nr>0) {
				checkNextFile($obj,$nr,$ENV{SCAN_FILE});
				if ($obj->file ne "") {
          savePage($obj);
          $nr++;
				} elsif ($obj->last==1) {
				  jobEnd($obj);
					$nr=0; # stop it (last page achieved)
				} else {
          sleep 2;
				}
			}
		}
    $obj->dbh2->disconnect();  
  }
  $obj->dbh->disconnect();
}






sub initvals {
  my ($obj) = @_;
  $obj->folder(getParameterRead($obj->dbh2,$obj->database,"ArchivOrdner"));
  $obj->quality(getBoxParameterRead($obj->dbh2,$obj->database,
	                                  "JpegQuality",1,100,33));
  $obj->quality2(getBoxParameterRead($obj->dbh2,$obj->database,
	                                  "JpegQuality2",0,100,0));
  $obj->factor(getBoxParameterRead($obj->dbh2,$obj->database,
	                                 "PrevScaling",0,90,20));
  $obj->factor(20) if $obj->factor<10 && $obj->factor!=0;
  $obj->pdf(getParameterRead($obj->dbh2,$obj->database,"PDFFiles"));
	$obj->nosingle(getParameterRead($obj->dbh2,$obj->database,"PDFWHOLEDOC"));
  my $res = getParameterReadWithType($obj->dbh2,$obj->database,
                                   'UserExtern01','UserExtern01');
  my @exLoginVals=split(';',$res);
  $obj->lcuser($exLoginVals[6]);
  $obj->defuser($exLoginVals[7]);
  $obj->pages(0);
	if ($obj->doc>0) {
	  logit("add pages to document:".$obj->doc);
		my $sql = "select Seiten from archiv where Laufnummer=".$obj->doc();
		my ($seiten) = $obj->dbh2->selectrow_array($sql);
		$seiten=640 if $seiten>640;
		$obj->pages($seiten) if $seiten>0;
	}
	$obj->getfields();
  $obj->barcodeinit();
}






sub checkNextFile {
  my ($obj,$nr,$file) = @_;
 	my $fi1 = $obj->path.$obj->base.sprintf("%04d",$nr).'.'.$obj->ext;
  $obj->file(''); # reset a page
  if ($obj->end eq "") {
	  $fi1 = $file if $file ne ""; # file is comming from processweb.pl
	  if (-e $fi1) {
	    $obj->file($fi1);
		} else {
		  $obj->last(1); # no more files
		}
	} else {
    my $nr2 = $nr+1;
    my $fi2 = $obj->path.$obj->base.sprintf("%04d",$nr2).'.'.$obj->ext;
    $obj->file($fi1) if -e $fi2;
	  if ($obj->file eq '') {
	    if (-e $obj->end) {
        $obj->file($fi1) if -e $fi1;
	      $obj->last(1); # we got last file
	    }
	  }
	}
}






sub jobEnd {
  my ($obj) = @_;
  my $job = "job server ended";
	my $sql = "";
	if ($obj->job) {
	  $job .= " (".$obj->job.")";
	  if ($obj->pages==1) {
	    $sql = "select param from jobs_data where ".
			          "jid=".$obj->job." and param='SCAN_TO_DOCUMENT'";
		  my @row = $obj->dbh->selectrow_array($sql);
		  if ($row[0] ne "") {
		    $sql = "update jobs_data set value='".$obj->doc."' where ".
			         "jid=".$obj->job." and param='SCAN_TO_DOCUMENT'";
	    } else {
		    $sql = "insert into jobs_data set value='".$obj->doc."',".
			         "jid=".$obj->job.",param='SCAN_TO_DOCUMENT'";
		  }
			$obj->dbh->do($sql);
		}
    # mark in the jobs table, that the job finished
    $sql = "update jobs set pwd='',status=".JOB_DONE." where id=".$obj->job;
    $obj->dbh->do($sql);
	}
	saveDoc($obj);
	logit($job);
}

