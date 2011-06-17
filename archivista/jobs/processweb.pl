#!/usr/bin/perl

=head1 processweb.pl (c) 17.3.2008 by Archivista GmbH, Urs Pfister

This script processes an uploaded file from WebClient

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;
use File::Copy;
use File::stat;
my $SLEEP = 1; # Seconds we wait when no job was found
use constant MAX_PAGES => 640; # max. number of pages/doc (640)
use constant JOB_DONE => 120; # scanadf job was started
use Fcntl qw(:flock SEEK_END); # import LOCK_* and SEEK_END constants

# DBI data for jobs table
my %val;
$val{sane} = "/usr/bin/perl /home/cvs/archivista/jobs/sane-client.pl";
$val{logtype} = "sne"; # type in logs table
$val{webfile} = ""; # uploaded file name
$val{jobid} = shift; # the id from the jobs table
$val{tmp} = "/home/data/archivista/tmp/";
$val{ds} = '/'; # directory separator (/ or \\)
$val{dbhh} = 0;
$val{vers} = check64bit();


logit("web job with $val{jobid} started");
my $res = 0;
for (my $c0=0;$c0<360;$c0++) {
  $val{dbh}=MySQLOpen();
  if ($val{dbh}) {
	  $res=1;
		last;
	}
	sleep 1;
}
if ($res==1) {	  
  if (HostIsSlave($val{dbh})==0) {
    # set back the log id
    $val{logid} = 0;
    # get the next job
    my $sql = "select id,host,db,user,pwd,job from jobs " .
              "where id = $val{jobid}";
    my @f = $val{dbh}->selectrow_array($sql);
	  if ($f[0] == $val{jobid}) {
      # we store the host,db,user,password information for later storage
      $ENV{'AV_SCAN_JOBS_ID'} = $val{jobid};
      $ENV{'AV_SCAN_HOST'} = $f[1];
      $ENV{'AV_SCAN_DB'} = $f[2];
      $ENV{'AV_SCAN_USER'} = $f[3];
      $ENV{'AV_SCAN_PWD'} = $f[4];
      $ENV{'AV_SCAN_OWNER'} = selectValue($val{dbh},$val{jobid},"SCAN_USER2");
      $val{scanid} = selectValue($val{dbh},$val{jobid},"SCAN_DEFINITION");
			$val{webfile} = selectValue($val{dbh},$val{jobid},"WEB_FILE");
      processWeb(\%val);
	    my $status = JOB_DONE;
      $sql = "update jobs set pwd='',status=$status where id=$val{jobid}";
      $val{dbh}->do($sql);
		  logit("web job with $val{jobid} ended");
		}
	}
	$val{dbh}->disconnect();
}






=head1 processWeb($pval)

Process a file with sane-client that was uploaded

=cut

sub processWeb {
  my $pval   = shift;
	my $file = $val{tmp}."job-$$pval{jobid}.upl";
	my $file1 = $val{tmp}."job-$$pval{jobid}";
	my $depth = 0;
	my $date = "";
	if (-e $$pval{webfile}) {
    my $mdate = stat($$pval{webfile})->mtime;
		$date = DateStamp($mdate);
	}
	if (!-e $file && -e $$pval{webfile}) {
	  move($$pval{webfile},$file);
		my @parts = split(/\//,$$pval{webfile});
		$$pval{webfile} = pop @parts;
	}
	if (-e $file) {
	  logit("uploaded file $file found");
    my $def = selectValue($val{dbh},$val{jobid},"WEB_DEF"); # get scan def
		my $ocr = 0;
		my $depth = 0;
    my $host = $ENV{'AV_SCAN_HOST'};
    my $db = $ENV{'AV_SCAN_DB'};
    my $user = $ENV{'AV_SCAN_USER'};
		my $pwd = $ENV{'AV_SCAN_PWD'};
		my $dbh = MySQLOpen($host,$db,$user,$pwd);
		if ($def ne "") {
			if ($dbh) {
		    processWebScanDef($dbh,$db,$pval,$def,\$ocr,\$depth);
			} else {
			  $def="";
			}
		} else {
      $ocr = selectValue($val{dbh},$val{jobid},"WEB_OCR"); # get ocr
      $depth = selectValue($val{dbh},$val{jobid},"WEB_BITS"); # get bits
		}
		$depth = 0 if $depth == 1;
		$depth = 1 if $depth == 8;
		$depth = 2 if $depth == 24;
		$depth = 0 if $depth <0 || $depth>2;
		my $opt = "";
		$opt = "-mono" if $depth==0;
		$opt = "-gray" if $depth==1;
		my $source = "";
		my $format = processWebFormat(\$file,\$source,$pval);
		processWebPages($pval,$format,$ocr,$depth,$opt,$def,$file,
		                $file1,$source,$date,$dbh,$db);
    if ($dbh) {
      $dbh->disconnect();
		}
	}
}
			





=head processWebScanDef($dbh,$pval,$dev,$pocr,$pdepth)

Give back the current ocr and depth of the choosen scan def

=cut

sub processWebScanDef {
  my ($dbh,$db,$pval,$def,$pocr,$pdepth) = @_;
	my $scandefs = getParameterRead($dbh,$db,"ScannenDefinitionen");
	my @lines = split("\r\n",$scandefs);
	$def = int $def;
	my $scandef = $lines[$def];
	$scandef = $lines[0] if $scandef eq "";
	my @olddef = split(";",$$pval{scanid});
	my $oldfields = $olddef[27];
	my @newdef = split(";",$scandef);
	if ($newdef[27] ne $oldfields) { # don't change it if we have same scan def
	  $newdef[27] .= ":" if $newdef[27] ne "" && $oldfields ne "";
	  $newdef[27] .= $oldfields if $oldfields ne "";
	}
	$scandef = join(";",@newdef);
	$$pval{scanid} = $scandef;
  my @svals = split(";",$scandef);
  $$pdepth = $svals[1]; # bitmap (1/8/24)
  $$pocr = $svals[10]; # desired ocr option
}






=head1 processWebPages($pval,$form,$ocr,$depth,$opt,$def,$file,$f1,$source)

Process all pages that are ready to process (either als pdf or image file)

=cut

sub processWebPages {
  my ($pval,$format,$ocr,$depth,$opt,$def,$file,
	    $file1,$source,$date,$dbh,$db) = @_;
	my $seite = 1;
	my $res = 0;
	my $file2 = "";
	my $maxpage = 0;
	my $cpus = `cat /proc/cpuinfo | grep 'processor'`;
	my @lines = split(/\n/,$cpus);
	my $fast = 0;
	my $firstdoc = 0;
	my $versions = 0;
	my $versfld = "";
	my $officeimages = 0;
	$fast = 1 if $lines[1] ne "";
	while ($seite>0 && $format ne "") {
	  ($res,$file2)=processWebPageSingle($file,$file1,$seite,\$maxpage,
		                                   $format,$depth,$opt,\$fast,$pval);
		if ($res==0) {
		  if ($seite==1) {
	      $officeimages = getParameterRead($dbh,$db,"OfficeImages");
			  $versions = processWebVersions($dbh,$db,$pval);
	      my @svals = split(";",$$pval{scanid});
				$svals[1] = $depth; # bitmap (1/8/24)
				$svals[7] = 0 if $def eq ""; # no rotation
				$svals[10] = $ocr; # desired ocr option
        $svals[11] = 1; # adf mode (simplex)
        $svals[24] = 0; # no bw/optimization
				if ($$pval{webfile} ne "" && ($format eq "PDF" || $officeimages==1)) {
			    my $filename = escape("office;".$$pval{webfile});
			    $svals[27] .= ":" if $svals[27] ne "";
			    $svals[27] .= "EDVName=$filename";
				}
				if ($date ne "") {
				  # add date if it is available
			    $svals[27] .= ":" if $svals[27] ne "";
			    $svals[27] .= "Datum=$date";
				}
				if ($versions ne "") {
			    $svals[27] .= ":" if $svals[27] ne "";
			    $svals[27] .= "$versions";
				}
				if (-e $source) {
				  if ($ocr != 27) { # if we did not tell him not to do any ocr
		        $svals[10] = -1; # no ocr from office documents
					}
				}
				my $sc = join(";",@svals);
        $ENV{'AV_SCAN_DEFINITION'} = join(";",@svals);
			}
			$res=processWebPageDo($pval,$seite,\$maxpage,$file,$source,
			                      $file2,$format,$depth,\$firstdoc,$officeimages);
		}
		$seite++; # go to next page
		$seite=0 if $res != 0;
    unlink $file2 if -e $file2;
	}
	unlink $source if -e $source;
  unlink $file if -e $file;
}






=head $retval=processWebVersions($dbh,$db,$pval)

Check if a source file is under control (adjust file name)

=cut

sub processWebVersions {
  my ($dbh,$db,$pval) = @_;
	my $retval = "";
	my $filename = "";
	my $docval = "";
	my $keyval = "";
  my $docfld = getParameterRead($dbh,$db,"VERSIONS");
	my $keyfld = getParameterRead($dbh,$db,"VERSIONKEY");
	if ($docfld ne "" && $keyfld ne "") {
	  my @parts = split(/\_/,$$pval{webfile});
	  $docval = shift @parts;
	  $keyval = shift @parts;
		if ($docval ne "" && $keyval ne "") {
		  $filename = join("_",@parts)  
		} else {
		  $docval="";
			$keyval="";
		}
		my $sql = "select $docfld,$keyfld from archiv ".
		          "where $docfld=".$dbh->quote($docval)." and ".
							"$keyfld > 0 ".
							"order by Laufnummer desc limit 1";
		my ($docval1,$keyval1) = $dbh->selectrow_array($sql);
		if ($docval1 eq $docval && $keyval eq $keyval1 && $docval ne "") {
		  # get in current version
			$keyval = $keyval + 0.1;
			$retval = "$docfld=$docval:$keyfld=$keyval";
		  $$pval{webfile} = $filename;
		} elsif ($docval1 eq $docval && $keyval ne $keyval1 && $docval ne "") {
		  # get in old version
			$keyval = $keyval - (2*$keyval);
			$retval = "$docfld=$docval:$keyfld=$keyval";
		  $$pval{webfile} = $filename;
		} else {
		  # no version at all found
			$retval = "$keyfld=1.0";
		}
	}
  $ENV{'SCAN_VERSIONS'}=$docfld;
  $ENV{'SCAN_VERSIONS_VAL'}=$docval;
  $ENV{'SCAN_VERSIONKEY'}=$keyfld;
  $ENV{'SCAN_VERSIONKEY_VAL'}=$keyval;
	return $retval;
}






=head1 processWebPageDo($pval,$seite,$pmaxpage,$file,$source,$f2,$form,$dept,$f)

Process one single page with sane-client.pl

=cut

sub processWebPageDo {
  my ($pval,$seite,$pmaxpage,$file,$source,$file2,
	    $format,$depth,$pdoc,$officeimages) = @_;
	my $res = -1;
	if (-e $file2) {
    logit("process page $seite in $file2");
    $ENV{'SCAN_DEPTH'}=$depth;
    $ENV{'SCAN_FILE'}=$file2;
    my $doc = selectValue($val{dbh},$val{jobid},"SCAN_TO_DOCUMENT");
		$$pdoc=$doc if $doc>0 && $$pdoc==0;
    $ENV{'AV_SCAN_TO_DOCUMENT'} = $doc;
		$ENV{'AV_EDVNAME_KILL'}=1 if $doc>0 && $doc != $$pdoc;
    if (((($seite % MAX_PAGES)==0) || $seite==$$pmaxpage) && $format eq "PDF") {
		  my $frame = int($seite/MAX_PAGES);
			my $start = ($frame*MAX_PAGES)+1;
			my $last = $seite;
		  if (($seite % MAX_PAGES)==0) {
        $ENV{'AV_SOURCE_NOTKILL'} = 1; # don't kill source file (not last time)
			  $start = $last - MAX_PAGES;
				$start = $start+1;
			} 
			$ENV{'AV_SCAN_NO_LOG'} = 0;
			$ENV{'AV_PAGE_START'} = $start;
			$ENV{'AV_PAGE_LAST'} = $last;
		} else {
		  # no ocr only in case we have a PDF file 
		  if ($format eq "PDF") {
	      $ENV{'AV_SCAN_NO_LOG'} = 1;
			} else {
			  if ($officeimages==1) {
	         $ENV{'AV_OFFICE_IMAGES'} = 1;
				   $source = $file;
				} else {
			    $ENV{'AV_SCAN_NO_LOG'} = 0;
				}
			}
	  }
	  if (-e $source) {
	    $ENV{'AV_SOURCE2'} = $source;
	    $ENV{'AV_SOURCE3'} = $file;
	  }
    my $cmd = "$$pval{sane}";
    $res = system($cmd);
	  $res = -1 if $format ne "PDF" && $officeimages==0;
	}
	return $res;
}






=head1 processWebPageSingle($file,$file1,$seite,$pmaxpage,$format,$depth,$opt)

Prepare one page for importing with sane-client.pl (create an image from pdf)

=cut

sub processWebPageSingle {
  my ($file,$file1,$seite,$pmaxpage,$format,$depth,$opt,$pfast,$pval) = @_;
	my $res = 0;
	my $file2 = "";
  if ($format eq "PDF") {
		if ($$pmaxpage==0) {
		  my $out = `pdfinfo '$file'`;
			$out =~ /(Pages:)(\s+)([0-9]+)/;
			$$pmaxpage = $3;
		}
	  my $ext = "pbm";
	  $ext = "pgm" if $depth==1;
	  $ext = "ppm" if $depth==2;
		my $zeros = getZeros($$pmaxpage);
	  my $cmd = "";
	  $file2 = $file1."-".sprintf($zeros,$seite).".$ext";
		if ($$pfast>0) {
		  if ($$pfast<=$$pmaxpage) {
	      my $file2a = $file1."-".sprintf($zeros,$$pfast).".$ext";
		    if ($seite==1) {
			    my $exe = "nice -n -20 pdftoppm";
					my $bk = " &";
					$bk = "" if $seite==$$pmaxpage;
          $cmd="$exe $opt -r 300 -f $seite -l $$pmaxpage '$file' '$file1'$bk";
	        $res = system($cmd);
			  }
			  for (my $c=0;$c<20;$c++) {
			    if (-s $file2a) {
						#checkFinished($file2a);
				    if ($file2 ne $file2a) {
					    move($file2a,$file2);
						}
					  $$pfast++;
				    $res=0;
				    last; 
				  } else {
				    $res=1;
				    sleep 2;
				  }
			  }
			} else {
			  # last page
				$res=1;
			}
	  } else {
      $cmd = "pdftoppm $opt -r 300 -f $seite -l $seite '$file' '$file1'";
	    $res = system($cmd);
	  }
	} else {
	  $file2 = $file;
	}
	return ($res,$file2);
}






=head1 checkFinished($file)

Check if the file is available

=cut

sub checkFinished {
  my ($file) = @_;
	for (my $c=0;$c<10;$c++) {
	  my $res = open(my $fh, ">>$file");
		if ($res) {
	    $res = flock($fh, LOCK_EX);
	    if ($res) {
		    logit("we can lock $file");
	      $res=seek($fh, 0, SEEK_END);
			  logit("end achieved, $file ok") if $res!=0;
		    my $res1 = flock($fh, LOCK_UN);
		  } else {
        logit("locking $file was not possible");
		  }
	    close($fh);
		} else {
      logit("opening of $file failed");
		}
		last if $res!=0;
		sleep 2;
	}
}





=head1 $format=processWebFormat($file)

Give back the current format ("" if no format found)

=cut

sub processWebFormat {
  my $pfile = shift;
	my $psource = shift;
	my $pval = shift;
	my $fnew = $$pval{webfile};
	my $identify = "pdfinfo '$$pfile'";
	my $cmdinfo = `$identify`;
	my $format = "";
	$format = "PDF" if $cmdinfo =~ 'PDF version';
	if ($format eq "" || $format eq "PDF") {
    $identify = "identify -ping $$pfile";
    my $cmdinfo = `$identify`;
	  my @infos = split(" ",$cmdinfo);
	  my $format1 = $infos[1];
	  if ($format1 ne "PNM" && $format1 ne "PNG" && $format1 ne "TIF" &&
	      $format1 ne "JPEG" && $format1 ne "GIF" && $format1 ne "BMP" &&
			  $format1 ne "TIFF") {
		  logit("convert $$pfile with openoffice or pdf");
			my ($fin1,$path,$base1) = CheckFileNamePathBase($fnew);
			processWebFormatPDF($pfile,$psource,\$format,$fin1,$path,$base1,$pval);
		} else {
		  $format=$format1; # we accept a bitmap page
		}
	}
	return $format;
}






=head processWebFormatPDF($pfile,$psource,$pformat,$fin1,$path,$base1)

Create a pdf from an office file (if it is not a pdf or image file)

=cut

sub processWebFormatPDF {
  my ($pfile,$psource,$pformat,$fin1,$path,$base1,$pval) = @_;
	my $fin2 = "";
  my $res=system("chown archivista.users '$$pfile'");
  $res=move($$pfile,$fin1) if !-e $fin1;
  if ($res==1) {
	  if ($$pformat ne "PDF") {
	    my $cmd2 = "chmod a+rwx $$pval{tmp}";
			system($cmd2);
			($res,$fin1,$fin2) = OpenOfficeConvert($fin1,$path,$base1);
	  } else {
		  logit("we have a pdf file $fin1");
	    # it is a pdf file
		  $fin2=$fin1;
		  $res=0;
		}
	}
	if ($res==0 && -e "$fin2") {
	  my $fin3 = "$path$base1\.zip";
	  unlink "$fin3" if -e "$fin3";
		my $cmd = "zip -j '$fin3' '$fin1'";
		$res = system($cmd);
		unlink "$fin1" if -e "$fin1" && $$pformat ne "PDF";
		if ($res==0) {
			$$psource = $fin3;
		  $$pfile = $fin2;
		  $$pformat = "PDF";
		} else {
			$$pfile = $fin2;
		  $$pformat = "PDF";
		}
	} else {
	  unlink $fin1 if -e $fin1;
	}
}






