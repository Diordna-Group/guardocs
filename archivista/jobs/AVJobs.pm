#!/usr/bin/perl

package AVJobs;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use ExactImage;
use Digest::MD5 qw(md5_hex);
require Exporter;

@ISA    = qw(Exporter);
@EXPORT = qw (getScanDefByNumber
getScanDefByName
getParameterRead
getBoxParameterRead
getParameterReadWithType
getFields
getFileExtension
savePage
updateDoc
saveDoc
checkNewDoc
rotate
checkEmptyPage
readFile
readFile2
writeFile
optimizeBW
FTPaddPages
FTPparseFile
FTPsplitFile
CUPSwaitAndMove
CUPSparseFile
CUPSgetPSFile
jobStart
jobStop
jobCheckStop
jobCheckInit
archivingDatabase
archivingDatabase1
getValidDatabases
checkDatabase
chooseXValues
restartOCRbatch
MySQLOpen
MySQLOpen2
MySQLClose
HostIsSlave
HostIsSlaveSimple
logit
MainAccessLog
recordAddOrUpdate
copyValues
checkLinkFields
DocumentLock
DocumentUnlock
importformatvalue 
exportformatvalue 
emptypath
sqlrange
addLogEntryImport
getLang
findit
escape
unescape
keyvalue
TimeStamp
DateStamp
DocumentAddDatForm
getBlobFile
getBlobTable
createThumbsAndSave
getConnectionValues
OpenOfficeConvert
CheckFileNamePathBase
selectValue
OCRDoOpenSourceLang
getXRandr
archivingDocSetOwner
OCRDoOpenSource
getOCRVals
check64bit
MainUpdateText
MainUpdateTextUpdate
getZeros
);

use DBI;
use File::Copy;
use Archivista::Config;    # only needed for connection

use constant LOG_DONE => 0; # everything is ok, ocr not done
use constant LOG_WORK => 1; # someone is working with the document
use constant LOG_AXISDONE => 2; # axis job is done, sane-client can get it
use constant LOG_OCR => 3; # the ocr engine is saving pdf files
use constant LOG_OCRDONE => 4; # the ocr recognition is done
use constant LOG_SCANSTART => 5; # we did start the scanadf job
use constant LOG_SCANADF => 6; # scanadf is working (on pages)
use constant LOG_SCANDONE => 7; # scanadf job is done, but not yet sane-post.pl

use constant MAX_PAGES => 640; # max. of pages per document (640)

my %val;
$val{dirsep} = "/"; # seperate a directory ((windows/linux)
$val{dirimg} = "/home/data/archivista/images/"; # base path to images
$val{tmpdir} = "/tmp/"; # temp dir (in case we need a temporary file
$val{log}       = '/home/data/archivista/av.log';
$val{ftpin} = "/home/data/archivista/ftp/";       # where we get the axis files
$val{ftpgs} = "gs -dNOPAUSE -dNOPROMPT -dBATCH -q";    # gs with main attributes
$val{cupsin} = "/var/spool/cups-pdf/ANONYMOUS/";    # in folder for cups files
$val{cupsps}  = "/var/spool/cups/"; # folder where we can find the orig. ps file
$val{pdfinfo} = "pdfinfo";          # program to extract pdf information
$val{pdftk}   = "pdftk";            # program to extract pdf pages
$val{pdf2txt} = "pdftotext";        # program to extract text from pdf file
$val{cupsinfo} = "lpstat_cups -W completed -o";    # check what job we got
$val{coldplus} = "/home/data/archivista/cust/cold/coldplus.pl";   # job coldplus
$val{ftpplus} = "/home/data/archivista/cust/ftp/ftpplus.pl";   # job ftpplus
$val{sane} = "/usr/bin/perl /home/cvs/archivista/jobs/sane-client.pl";
$val{autoprg} = "/home/data/archivista/cust/autofields/"; # path autoprogs
$val{ftpprocess} = "/etc/ftp-process.conf"; # send ftp/pdf not to local database
$val{frpath} = '/home/archivista/.wine/drive_c/Programs/Av5e/';

# where we get the Archivista connection
my $config = Archivista::Config->new;
$val{host} = $config->get("MYSQL_HOST");
$val{db}   = $config->get("MYSQL_DB");
$val{user} = $config->get("MYSQL_UID");
$val{pw}   = $config->get("MYSQL_PWD");
undef $config;

$val{avversion} = 520; # actual archivista internal database number
$val{avfoldermax} = 9999; # max. number of folders in archive
$val{avuser} = 500; # archivista user
$val{avowner} = 100; # group for archivista user
# paths for ocr and archiving batch jobs
$val{jobpf} = "/home/archivista/.wine/drive_c/Programs/Av5e/";
$val{jobwr} = "AV5AUTO.WRK";
$val{jobst} = "AV5AUTO.STP";
$val{joben} = "AV5AUTO.END";







=head2 $scandef=getScanDefByNumber($dbh,$db1,$scanid)

Read a scan definition by its number and gives back the string

=cut

sub getScanDefByNumber {
  my ($dbh,$db1,$scanid) = @_;
  # read the scan definitions from the database
  my $scandef = getParameterRead( $dbh, $db1, "ScannenDefinitionen" );
  my @scannen = split( "\r\n", $scandef );
  $scanid = $scannen[0] if $scannen[$scanid] eq "";
  return $scannen[$scanid];
}






=head2 $scandef=getScanDefByName($dbh,$db1,$scanname)

Read scan definition from the database db1 and gives back $scandef
  
=cut

sub getScanDefByName {
  my ($dbh,$db1,$scanname) = @_;
  my ( $scandef, @scannen, @scanval, $scanid, $c );
  # read the scan definitions from the database
  $scandef = getParameterRead( $dbh, $db1, "ScannenDefinitionen" );
  @scannen = split( "\r\n", $scandef );
  # give back the first definition in case we don't find it
  $scanid = 0;
  $c      = 0;
  foreach (@scannen) {
    # go through all definitions
    @scanval = split( ";", $_ );
    if ( $scanval[0] eq $scanname ) {
      $scanid = $c;
    }
    $c++;
  }
  return $scannen[$scanid];
}






=head2 recordAddOrUpdate($dbh,$db1,$pnr,$ppages,$plockuser,$user)

Adds a new Archivista record and/or does lock it

=cut

sub recordAddOrUpdate {
  my ($dbh,$db1,$pnr,$ppages,$plockuser,$user,$owner) = @_;
  $user = "cupsftp" if $user eq "";
  my $user1 = $dbh->quote($user);
  my ( $sql, $r, @row );
  if ( $$pnr == 0 ) {
    # add a document with the acutal date
    my $date1 = DocumentAddDatForm( TimeStamp() );
    my $foldakt = getParameterRead($dbh,$db1,"ArchivOrdner");
		checkJobAdmin($dbh,$db1,"localhost");
		my $o1="''";
		$o1 = $dbh->quote($owner) if $owner ne "";
    $sql = "insert into $db1.archiv set Seiten=0,Ordner=$foldakt, " .
		       "Eigentuemer=$o1,Erfasst=0," .
           "Datum=$date1,UserNeuName=$user1,ErfasstDatum=$date1,ArchivArt=1";
    logit($sql);
    $r = $dbh->do($sql);
    if ( $r == 1 ) {
      # Document is ok, we need the number
      $sql = "select Laufnummer from $db1.archiv " .
             "where Laufnummer=LAST_INSERT_ID()";
      @row = $dbh->selectrow_array($sql);
      $$pnr = $row[0];
      $$ppages = 0;
    }
  }
  if ( $$pnr > 0 ) {
    # update the document so it is locked
    my $locked = $dbh->quote($$plockuser);
    $sql = "update $db1.archiv set Akte=$$pnr,UserModName=$user1," .
           "Gesperrt=$locked " .
           "where Laufnummer=$$pnr";
    $dbh->do($sql);
    # get the actual pages directly from the document
    $sql = "select Seiten from archiv where Akte=$$pnr";
    @row = $dbh->selectrow_array($sql);
    $$ppages = $row[0] if $row[0] >= 0;
  }
}






=head1 checkJobAdmin($dbh,$db1)

Check if we need to update scripts for a box

=cut

sub checkJobAdmin {
  my ($dbh,$db1,$host) = @_;
  my $jobadmin = getParameterReadWithType($dbh,$db1,"JOBADMIN01","JOBADMIN");
  if ($jobadmin ne "") {
	  my @lines = split("\r\n",$jobadmin);
		my $c0=0;
		foreach (@lines) {
		  my $line = $_;
		  my $update = 0;
			my @vals = split(";",$line);
			if ($vals[4]==1) {
			  my @boxes = split(",",$vals[2]);
				my @found = ();
				my $name = $vals[0];
				my $script = $vals[1];
				my $startpos = index($script,"/home/data/archivista/cust/");
				my $user = $vals[6];
				my $pw = pack("H*",$vals[7]);
				my @updated = split(",",$vals[5]);
				my $pres = $dbh->selectall_arrayref("show processlist");
				my $pres1 = $$pres[0];
				my $ip = $$pres1[2];
				$ip =~ s/^(.*?)(:)(.*)/$1/;
				my $c=0;
				foreach (@boxes) {
				  if ($boxes[$c] eq $ip && $startpos==0) {
			      logit("we need to update a script $script");
					  my $c1=0;
						my $writeit=1;
					  foreach (@updated) {
						  $writeit=0 if $updated[$c1] eq $ip;
							$c1++;
						}
						if ($writeit==1) {
						  my $code = unescape($vals[3]);
							open(FOUT,">$script");
							binmode(FOUT);
							print FOUT $code;
							close(FOUT);
							if (-e $script) {
                chown "root","root",$script;
							  chmod 0750,$script;
							}
							push @updated,$ip;
							$vals[5] = join(",",@updated);
							$lines[$c0]=join(";",@vals);
							checkJobAdminUpdate($ip,$db1,$user,$pw,$name,$vals[5],$host);
						}
					}
				  $c++;
				}
			}
			$c0++;
		}
	}
}






=head1 checkJobAdminUpdate($ip,$db1,$user,$pw,$name,$line)

Send command for updating a given jobadmin definition

=cut

sub checkJobAdminUpdate {
  my ($ip,$db1,$user,$pw,$name,$boxes,$host) = @_;
	my $db2 = "archivista";
	if ($ip eq "localhost") {
	  $user = "root";
		$host = "localhost";
		$pw = $val{pw};
	}
	my $dbh = MySQLOpen($host,$db2,$user,$pw);
	if ($dbh) {
    my $sql1 = "INSERT INTO $db2.";
    my $sql = $sql1."jobs SET job='JOBS',status=110," .
               "host='localhost',db=".$dbh->quote($db1)."," .
               "user=".$dbh->quote($user).",pwd=''";
		$dbh->do($sql);
		$sql = "SELECT LAST_INSERT_ID()";
    my @rows = $dbh->selectrow_array($sql);
		my $id = $rows[0];
		if ($id>0) {
		  my $line = $name.";".$boxes;
      $sql=$sql1."jobs_data set jid=$id,param='LINE',value=".$dbh->quote($line);
			$dbh->do($sql);
      $sql = "UPDATE $db2.jobs SET status=100 where id=$id";
			$dbh->do($sql);
			logit($sql);
    }
	}
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






=head1 dd.mm.yyyy=DateStamp

Give back a string with the date 

=cut

sub DateStamp {
  my ($date) = @_;
  my @t = localtime( $date );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y = $t[5] + 1900;
  $m = $t[4] + 1;
  $m = sprintf( "%02d", $m );
  $d = sprintf( "%02d", $t[3] );
  $stamp = $d.'.'.$m.'.'.$y;
  return $stamp;
}






=head2 $stamp=SQLStamp

Actual date as SQL string (2004-03-23)

=cut

sub SQLStamp {
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y     = $t[5] + 1900;
  $m     = $t[4] + 1;
  $m     = sprintf( "%02d", $m );
  $d     = sprintf( "%02d", $t[3] );
  $stamp = $y . "-" . $m . "-" . $d . " 00:00:00";
  return $stamp;
}






=head2 $sqldat=DocumentAddDatForm(yyyymmdd)

Format a date ('yyyy-mm-dd 00:00:00')

=cut

sub DocumentAddDatForm {
  my $d = shift;
  $d = "'".substr($d,0,4)."-".substr($d,4,2)."-".substr($d,6,2)." 00:00:00'";
  return $d;
}






=head2 $@fields=getFields ($dbh, $table)

Gets back in a pointer of an array a hash 
containing all name, type und sizes of an mysql table

=cut

sub getFields {
  my $dbh   = shift;
  my $table = shift;
	my $db1 = shift;
	$table = "archiv" if $table eq "";
	if ($db1 ne "") {
	  $table = "$db1.$table";
	}
  my $sql   = "describe $table";
  my $nr = 0;
  my $st = $dbh->prepare($sql);
  my $r  = $st->execute;
  my @fields;
  while ( my @row = $st->fetchrow_array ) {
    my %f;
    $f{name} = $row[0];
    my $name = "";
    my $lang = 0;
    ( $name, $lang ) = $row[1] =~ /(.*)\((.*)\)/;
    $name = $row[1] if $name eq "";
    $f{type}     = $name;
    $f{size}     = $lang;
    $fields[$nr] = \%f;
    $nr++;
  }
  return \@fields;
}






=head2 savePage($obj)

Save one single page to the database (incl. all processing)

=cut

sub savePage {
	my $obj = shift;
  my $image = ExactImage::newImage();
	my $image2 = "";
	$obj->logit("start to save ".$obj->file);
	my $size = -s $obj->file;
	if ($size>0) { # there is some content in the file!!! 
	  logit("start reading ".$obj->file);
    my $res = ExactImage::decodeImageFile($image,$obj->file);
    my $w = ExactImage::imageWidth($image);
    my $h = ExactImage::imageHeight($image);
		if (($w==0 && $h==0) || $res!=1) {
	    logit("image ".$obj->file."has a problem, try to fix it with convert");
		  my $cmd = "convert ".$obj->file." ".$obj->file;
			system($cmd);
      $res = ExactImage::decodeImageFile($image,$obj->file);
		}
    ExactImage::imageSetXres($image,$obj->dpi);
    ExactImage::imageSetYres($image,$obj->dpi);
	  ExactImage::imageFastAutoCrop($image) if $obj->autocrop==1;
	  if (checkEmptyPage($obj,$image)==0) {
	    savePageChecks($obj,$image);
		  checkSplitDoc($obj,$image);
      rotate($obj,$image); # check for rotation (according feeder)
		  if ($obj->splitpage) {
		    $obj->logit("split page");
        my $w = ExactImage::imageW1dth($image);
        my $h = ExactImage::imageHeight($image);
		    if ($w>0 && $h>0) {
			    my $w1 = int ($w/2);
			    my $w1a = $w1+1;
			    my $w2 = $w-$w1;
          $image2 = ExactImage::copyImage($image);
          ExactImage::imageCrop($image2,$w1a,0,$w2,$h);
			    ExactImage::imageCrop($image,0,0,$w1,$h);
			  }
		  }
      savePageDo($obj,$image);
		  if ($image2 ne "") {
		    savePageDo($obj,$image2);
        ExactImage::deleteImage($image2);
		  }
	  } else {
		  logit("we got an empty page");
			if ($obj->jobstop ne "") {
		    # check for auto pilot mode (and empty page)
			  logit("jop stopped because of empty page!");
        writeFile($obj->jobstop,\"stop") 
			}
		}
	  ExactImage::deleteImage($image);
		if ($obj->officeimages==1) {
			if (-e $obj->file) {
		    $obj->source2($obj->file.".zip");
			  unlink $obj->source2 if -e $obj->source2;
		    my $cmd = "zip -j '".$obj->source2."' '".$obj->file."'";
		    my $res = system($cmd);
			}
		}
	  unlink $obj->file if -e $obj->file;
  } else {
	  logit("Error: file empty");
    $obj->error(1);
  }
  $obj->last(1) if $obj->error!=0;
}






=head2 savePageDo($obj,$image)

Process one single page

=cut

sub savePageDo {
  my $obj = shift;
	my $image = shift;
	my ($img1,$img2);
  optimizeBW($obj,$image);
  my $bits = ExactImage::imageColorspace($image);
	if ($obj->pages==0) {
		$obj->archtype(1) if $bits eq "gray1" && $obj->archtype==3;
		$obj->archtype(3) if $bits ne "gray1" && $obj->archtype==1;
		$obj->archtype(3) if $bits eq "rgb8" && $obj->archtype==1;
		$obj->archtype(3) if $bits eq "gray8" && $obj->archtype==1;
	}
	if ($obj->archtype!=1) {
	  ExactImage::imageConvertColorspace($image,"gray") if $bits eq "gray1";
		if ($obj->quality2==1) {
		  logit("compress it all the time");
	    ExactImage::imageInvert($image);
	    ExactImage::imageInvert($image);
		}
    $img1 = ExactImage::encodeImage($image,"jpeg",$obj->quality,'');
  } else {
	  ExactImage::imageConvertColorspace($image,"gray1") if $bits ne "gray1";
    $img1 = ExactImage::encodeImage($image,"tiff",100,'');
  }  
  if ($obj->factor>0) {
		my $width = ExactImage::imageWidth($image);
		my $height = ExactImage::imageHeight($image);
		if ($width>1024 && $height>786) {
      my $fact1 = $obj->factor/100;
		  if ($obj->archtype!=1) {
        ExactImage::imageScale($image,$fact1);
        $img2 = ExactImage::encodeImage($image,"jpeg",$obj->quality,'');
      } else {
        ExactImage::imageBilinearScale($image,$fact1);
        $img2 = ExactImage::encodeImage($image,"tiff");
      }
	  }
	}
	my $page = $obj->pages;
	$page++;
	$obj->pages($page);
  my $seite = $obj->doc * 1000 + $obj->pages;
	$obj->logit("save docpage:".$seite);
  my $sql = "insert into archivbilder set Seite=$seite,BildInput=";
	$sql .= $obj->dbh2->quote($img1).",Bild=".$obj->dbh2->quote($img2);
	if ($obj->dbh2->do($sql)) {
	  updateDoc($obj,5);
	} else {
	  $obj->error(1);
	}
	MainAccessLog($obj->dbh,$obj->database,$obj->dbh2,$obj->doc,$obj->pages,
	              "add_page",$obj->user,$obj->host) if $obj->error==0;
}






=head1 updateDoc($obj)

Update the document, don't unlock it

=cut

sub updateDoc {
  my ($obj,$step) = @_;
	if (($obj->pages % $step)==0) {
	  my $sql = "update archiv set Erfasst=1,Seiten=".$obj->pages." ".
		          "where Laufnummer=".$obj->doc;
	  $obj->dbh2->do($sql);
  }
}






=head1 saveDoc($obj,$maxpages)

Adjust the current document

=cut

sub saveDoc {
  my ($obj,$maxpages) = @_;
	my $id = "";
  for (my $c=$obj->pagesstart;$c<=$obj->pages;$c++) {
	  my $nr = ($obj->doc*1000)+$c;
    my $sql = "insert into ".$obj->database.".archivseiten set Seite=".$nr.
		       ",OCR=".$obj->ocr.",Erfasst=".$obj->ocrerfasst.
					 ",Ausschliessen=".$obj->ocrexclude;
    $obj->dbh2->do($sql);
	}

	if ($obj->versions ne "") {
	  $id = $obj->versionkey_val;
	  if ($obj->versions_val>0) {
	    my $sql = "select Laufnummer from archiv where ".
		         $obj->versions."=".$obj->dbh2->quote($obj->versions_val).
				  	 " and Laufnummer != ".$obj->doc." order by Laufnummer desc";
      my @row = $obj->dbh2->selectrow_array($sql);
	    my $oldnr = $row[0];
	    if ($oldnr>0) {
	      $id = $oldnr;
		    copyValues($obj->dbh2,$obj->database,$obj->fields,$oldnr,$obj->doc);
		  }
		} else {
	    my $sql = "update archiv set ".$obj->versions."=".
			          $obj->dbh2->quote($obj->doc)." where Laufnummer=".$obj->doc;
			$obj->dbh2->do($sql);
		}
	}

	if ($obj->doc>0 && $obj->ftpplus==0) { # check ftpplus once
	  $obj->ftpplus(1);
    my $prg = $val{ftpplus};
    if ( -e $prg ) {
      # Program is available
      my $cmd = "$prg '".$obj->title."' '".$ENV{AV_SCAN_BASE}."'";
			logit("$cmd");
      my $autofields = `$cmd`;
			logit("ftpplus values:$autofields");
	    AutoFields($obj,$autofields) if $autofields ne "";
		}
	}
	AutoFields($obj,$obj->autofields) if $obj->autofields ne "";
	if ($obj->autoprog==1) {
	  foreach (@{$obj->autoprogs}) {
	    AutoPrg($obj,$_);
	  }
	}
	if ($obj->nolog==0) { # add if not single page upload from web upload/office
	  FTPaddPagesSource($obj,$maxpages); # pdf file
	  FTPaddPagesSource2($obj); # mail zip file (delete source file)
	}

	
	my $erfasst="0";
	$erfasst="1" if $obj->pages>0;
  my $sql="update archiv set Erfasst=$erfasst,".
	        "Gesperrt='',Seiten=".$obj->pages.",".
					"ArchivArt=".$obj->archtype." ". # correct type after processing
	        "where Laufnummer=".$obj->doc;
	$obj->dbh2->do($sql);

  my $filename = getParameterRead($obj->dbh2,$obj->database,"FILENAME");
	if ($filename ne "" && $obj->pagesframe_end==0) {
	  $sql = "select EDVName from ".$obj->database.".archiv ".
		       "WHERE Laufnummer=".$obj->doc;
		my @row = $obj->dbh2->selectrow_array($sql);
		if ($row[0] ne "") {
		  my ($type,$name) = split(';',$row[0]);
			my $fname;
			$fname = $type if $name eq "";
			$fname = $name if $type eq "office";
			if ($fname ne "") {
			  $sql = "update ".$obj->database.".archiv ".
				       "set $filename=".$obj->dbh2->quote($fname)." ".
							 "where Laufnummer=".$obj->doc;
				$obj->dbh2->do($sql);
			}
    }	
  }
	if ($obj->host eq "localhost") {
    my $index = getParameterRead($obj->dbh2,$obj->database,"SEARCH_FULLTEXT");
		if ($index==2) {
	    my $cmd = "/usr/bin/perl /home/cvs/archivista/jobs/sphinxit.pl ".
	              "indexone ".$obj->database." >>/home/data/archivista/av.log";
	    system($cmd);
		}
	}
	
	my $frec = $obj->formrec;
	if ($obj->nolog==0) {
    addLogEntryImport($obj->dbh,$obj->host,$obj->database,$obj->user,
	    $obj->password,$obj->doc,$obj->pages,'sne',$frec,1,$obj->logdone);
	}

	if ($obj->pagesframe_end>0 || $ENV{'AV_EDVNAME_KILL'}==1) { 
	   # remove EDVName in splitted docs or in processweb
     my $sql = "update archiv set EDVName='' where Laufnummer=".$obj->doc;
     $obj->dbh2->do($sql);
	}
	if ($maxpages==0) {
	  # we have a new document, but max_pages was not reached, so init them
	  $obj->pagesframe_beg(0);
		$obj->pagesframe_end(0);
	}
}






=head1 checkNewDoc($obj)

Check if we need to add a new document

=cut

sub checkNewDoc {
  my $obj = shift;
	$obj->error(0);
  if ($obj->doc>0) {
	  if ($obj->locked==0) {
      my $sql = "update archiv set Gesperrt=".
			          $obj->dbh2->quote($obj->lockuser)." ".
		            "where Laufnummer=".$obj->doc." and Gesperrt='' ".
				  			"and Archiviert=0 and ArchivArt=".$obj->archtype;
		  if ($obj->dbh2->do($sql)) {
		    $obj->locked(1);
		  } else {
		    $obj->error(1);
			}
		}
		if ($obj->locked==1 && $obj->pagesloaded==0) {
		  my $sql = "select Seiten from archiv where Laufnummer=".$obj->doc;
			my @row = $obj->dbh2->selectrow_array($sql);
			if ($row[0]<MAX_PAGES) { # we can add more pages
			  $obj->pages($row[0]);
				my $start=$row[0]+1;
				$obj->pagesstart($start);
				$obj->pagesloaded(1);
			} else {
			  $obj->pages(MAX_PAGES);
			}
		}
		if ($obj->pages>=MAX_PAGES) { # got maximum of pages, so add new document
      my $pages = $obj->pages();
			$obj->pagesframe_beg($obj->pagesframe_end()+1);
		  saveDoc($obj,1);
			$obj->pagesframe_end($obj->pagesframe_end()+$pages);
			$obj->doc(0);
			$obj->pages(0);
			$obj->pagesloaded(0);
			$obj->pagesstart(0);
			$obj->locked(0);
		}
	}
	if ($obj->doc==0 && $obj->error==0) {
	  $obj->logit("add new doc for db: ".$obj->database);
    my $date1 = DocumentAddDatForm( TimeStamp() );
		checkOwner($obj);
		checkJobAdmin($obj->dbh2,$obj->database,$obj->host);
		my $ext = 'TIF';
		$ext='JPG' if $obj->depth>1 && $obj->bwoptimize==0;
    my $sql = "insert into archiv set Seiten=0,Ordner=".$obj->folder.",".
		       "Eigentuemer=".$obj->dbh2->quote($obj->owner).",".
					 "UserNeuName=".$obj->dbh2->quote($obj->user).",".
           "Datum=$date1,ErfasstDatum=$date1,ArchivArt=".$obj->archtype.",".
	         "BildInput=1,BildIntern=1,BildInputExt='$ext',Erfasst=0,".
					 "Gesperrt=".$obj->dbh2->quote($obj->lockuser);
		$obj->logit($sql);
		my $res = $obj->dbh2->do($sql);
		if ($res==1) {
		  $obj->logit("added ok");
      # Document is ok, we need the number
      $sql = "select LAST_INSERT_ID()";
      my @row = $obj->dbh2->selectrow_array($sql);
      $obj->doc($row[0]);
			if ($obj->doc>0) {
			  $sql = "update archiv set Akte=".$obj->doc." ".
				       "where Laufnummer=".$obj->doc;
				$obj->logit($sql);
				$obj->dbh2->do($sql);
			} else {
			  $obj->error(1);
			}
			$obj->pages(0);
			$obj->pagesloaded(1);
			$obj->pagesstart(1);
			$obj->locked(1);
		}
  }
}






=head1 $sqlpseudopart=AutoFields($obj,$autofields)

Create an sql fragment from a string Field1=Value1:Field2=Value2

=cut

sub AutoFields {
  my ($obj,$autofields) = @_;
  # check ALWAYS for autofields
  my $sql = ""; # new sql string for barcode information    
  # add the values from autofields
  my @p=split(":",$autofields);
  for (my $idx = 0; $idx <=20; $idx++) {
    my ($f,$v) = split("=",$p[$idx]);
		if ($f eq "" && $v eq "") {
		  last; # no more information go out  
    } else {		
      # there must allways be a fields and value string
      my $sql1 = checkBarcodeAddAutoFields($obj->dbh2,$f,$v,$obj->fields,$obj);
			if ($sql1 ne "") {
			  $sql .= "," if $sql ne "";
			  $sql .= $sql1;  
			}
    }
  }
  if ($sql ne "") {
    # if we could find values for fields, so lets store them
    $sql = "update archiv set $sql where Laufnummer=".$obj->doc;
    $obj->dbh2->do($sql);
  }
	
}






=head1 AutoPrg($obj,$prg)

Update the document with programmed fields

=cut

sub AutoPrg {
  my ($obj,$prg) = @_;
  my $prgdo = $val{autoprg} = "/home/data/archivista/cust/autofields/".$prg;
	if (-e $prgdo) {
	  $obj->logit("autoprog:$prg");
	  system("$prgdo ".$obj->host." ".$obj->database." ".
		        $obj->user." ".$obj->password." ".$obj->doc);
	}
}






=head2 savePageChecks($obj,$image)

Check if and to which doc (i.e. barcodes) we can save a page

=cut

sub savePageChecks {
  my ($obj,$image) = @_;
  # do the barcode recognition
  my $barcode = "";
	if ($obj->barcodedef>0) {
	  if (check64bit()==64) {
	    $barcode = checkBarcode64($obj,$image);
		} else {
	    $barcode = checkBarcode($obj,$image);
		}
		# check if current == last barcode AND singe page mode is not on
	  $barcode="" if $barcode eq $obj->lastbarcode && $obj->bc_singlepages==0;
	  $obj->lastbarcode($barcode) if $barcode ne ""; # hold last barcode
    if ($barcode ne "") {
		  logit("new barcode:$barcode");
      # the barcode is ok, so we need anyway a new record
			if ($obj->pages>0) {
	      saveDoc($obj); # close the current doc
		    $obj->doc(0);
			} else {
			  # check if we really have no pages (processweb.pl upload)
		    my $sql = "select Seiten from archiv where Laufnummer=".$obj->doc;
			  my @row = $obj->dbh2->selectrow_array($sql);
			  $obj->pages($row[0]);
				if ($obj->pages>0) {
				  my $oldlog = $obj->nolog(0);
	        saveDoc($obj); # close the current doc
				  $obj->nolog($oldlog);
		      $obj->doc(0);
				}
			}
      if ($obj->bc_doc==1) {
        my $sql = "select Laufnummer,Seiten from archiv where " .
                  "Laufnummer=$barcode";
        my @row1=$obj->dbh2->selectrow_array($sql);
        if ($row1[0]>0 && $row1[1]==0) {
          # store to an existing document (if no pages are there)
          $obj->doc($barcode); # barocde is document number
					$sql = "update archiv set UserNeuName=".
					       $obj->dbh2->quote($obj->user)." where ".
								 "Laufnummer=".$obj->doc." and Gesperrt=''";
					$obj->dbh2->do($sql);
				  $obj->pages(0);
				  $obj->pagesloaded(0);
				  $obj->pagesstart(0);
				  $obj->locked(0);
		    }
		  }
		  checkNewDoc($obj);
      # we need a pointer to an array with all fields, where we find a hash
      # with name, type, size -> so we can save the values to sql
      my @bc = split(";",$obj->bc_string);
      my $bcs=21; # start of the first sub setting
      my $sql = ""; # new sql string for barcode information  
      for (my $idx = 0; $idx <=7; $idx++) {
        # get the actual sub setting of the barcode definition
        my $bcset = $bc[$bcs+$idx];
        $sql .= checkBarcodeAddField($obj,$barcode,$bcset,$idx);
      }
      # update the values from the barcode
      if ($sql ne "") {
        # if we could find values for fields, so lets store them
        $sql = "update archiv set $sql where Laufnummer=".$obj->doc;
        $obj->dbh2->do($sql);
      }
	  }
	}
	checkNewDoc($obj) if $obj->initialized==0;
} 
 
 
 
 
 


=head2 checkOwner($obj)

If activated set lowercase for user and if none gives a default user

=cut

sub checkOwner {
  my ($obj) = @_;
  if ($obj->lcuser==1 || $obj->defuser ne "") {
	  my $tmpuser = $obj->owner;
		my $owner = "";
    # if User not SYSOP or Admin
    unless ($tmpuser eq "SYSOP" || $tmpuser eq "Admin" ) {
		  if ($obj->lcuser == 1) {
        # Check if both are uppercase if not set everything to lowercase
        my $tmp = uc($tmpuser);
        if ($tmpuser ne $tmp) {
          # We have not uppercase so change it to lowercase
          # Set UserName to Lowercase if the option is activated
          $owner = lc($tmpuser);
				}
			}
			if ($obj->defuser ne "" && $tmpuser eq "") {
			  # we have no value in Eigentuemer field and a def user
			  $owner = $obj->defuser; 
			}
		}
		$obj->owner($owner) if $owner ne "";
  }
}






=head2 $barcode=checkBarcode($obj,$image)

Do the barcode recognition and gives back the barcode if it does match

=cut

sub checkBarcode {
  my ($obj,$image) = @_;
  my $barcode1;
	if ($obj->bc_stretch==1) {
    $barcode1 = ExactImage::imageDecodeBarcodesExt($image,$obj->bc_type,
		            $obj->bc_length,$obj->bc_length);
	} else {
	  my $cimage = ExactImage::copyImage($image);
    ExactImage::imageScale($cimage,1,$obj->bc_stretch);
    $barcode1 = ExactImage::imageDecodeBarcodesExt($cimage,$obj->bc_type,
		            $obj->bc_length,$obj->bc_length);
	  ExactImage::deleteImage($cimage);
	}
  my @barcodes;
  for (my $i;$i<scalar(@$barcode1);$i+=2) {
    push @barcodes,@$barcode1[$i];
  }
  my $barcode;
  foreach (@barcodes) {
    # do a check for every barcode, the first one we take
    $barcode = $_;
		$obj->logit("barcode found:$barcode");
    chomp $barcode;
    if ($barcode ne "" && $obj->bc_chars ne "") {
      # if we have a barcode and if we have checkChars, we test the first chars
      my @checks = split(",",$obj->bc_chars);
      my $found = 0;
      foreach (@checks) {
        my $check1 = $_;
        my $fpos = index $barcode,$check1;
        $found=1 if $fpos==0;
      }
      $barcode="" if $found==0;
    }
    last if $barcode ne "";
  }
  return $barcode;
}






=head2 $barcode=checkBarcode64($obj,$image)

Do the barcode recognition and gives back the barcode if it does match

=cut

sub checkBarcode64 {
  my ($obj,$image) = @_;
  my $barcode1;
	my ($typ1,$typ2) = split(/\|/, $obj->bc_type);
	my $opt = "";
	if ($typ1 eq "any") {
	  $opt = "-Senable";
	} elsif ($typ1 ne "" && $typ2 eq "") {
	  $opt = "-Sdisable -S".checkBarcode64Typ($typ1).".enable";
	} elsif ($typ1 ne "" && $typ2 ne "") {
	  $opt = "-Sdisable -S".checkBarcode64Typ($typ1).".enable ".
		       "-S".checkBarcode64Typ($typ2).".enable";
	}
	if ($obj->bc_length>0) {
	  $opt .= " -Smin-length=".$obj->bc_length." -Smax-length=".$obj->bc_length;
  }
	$opt .= " --raw";
	my $cmd = "zbarimg $opt ".$obj->file;
	my $barcode0 = `$cmd`;
	my @barcode1 = split(/\n/,$barcode0);
  my @barcodes;
  for (my $i;$i<scalar(@barcode1);$i+=2) {
    push @barcodes,$barcode1[$i];
  }
  my $barcode;
  foreach (@barcodes) {
    # do a check for every barcode, the first one we take
    $barcode = $_;
		$obj->logit("barcode found:$barcode");
    chomp $barcode;
    if ($barcode ne "" && $obj->bc_chars ne "") {
      # if we have a barcode and if we have checkChars, we test the first chars
      my @checks = split(",",$obj->bc_chars);
      my $found = 0;
      foreach (@checks) {
        my $check1 = $_;
        my $fpos = index $barcode,$check1;
        $found=1 if $fpos==0;
      }
      $barcode="" if $found==0;
    }
    last if $barcode ne "";
  }
  return $barcode;
}






=head1 $type=checkBarcode64Type($typ32)

Convert the code names between old and new barcode solution

=cut

sub checkBarcode64Typ {
  my $typ = shift;
	if ($typ eq "code25") {
	  $typ = "i25";
	}
	return $typ;
}






=head2 $sqlpart=checkBarcodeAddField($obj,$barcode,$bcset,$notfirst)

We find out which part of the barcode goes to wich field
  
=cut

sub checkBarcodeAddField {
  my ($obj,$barcode,$bcset,$notfirst) = @_;
  my @bc1 = split(",",$bcset);
  my $bcLength=$bc1[1]; # length of the barcode
  my $bcField=$bc1[2]; # field to store the barcode
  my $bcStart=$bc1[3]; # start position in barcode
  my $bcCharacter=$bc1[4]; # end position in barcode
  my $sql;
  my $subBarcode = $barcode;
  my ($name,$type);
  if (length($barcode) == $bcLength || $bcLength==0) {
    if ($bcLength>0 && $bcStart>0 && $bcCharacter>0) {
      $subBarcode = substr $subBarcode,$bcStart-1,$bcCharacter;
    }
    # remove all leading spaces
    $subBarcode =~ s/^\s+//;
    # get name,type and size of field
    my ($c,$cok,$cres);
    # we don't want Akte/Seite, but the corresponding field nr
    # Unfortunately, this structure is not the same between
    # Web- and RichClient
    $c=0;
    $cok=0;
    $cres=0;
    foreach(@{$obj->fields}) {
      my $name=${$obj->fields}[$c]->{name};
      if ($name ne "Seiten" and $name ne "Akte") {
        if ($cok==$bcField) {
          $cres=$c;
        }
        $cok++;
      }
      $c++;
    }
    $name=${$obj->fields}[$cres]->{name};
    $type=${$obj->fields}[$cres]->{type};
    my $size=${$obj->fields}[$cres]->{size};

    if ($type eq "datetime") {
      # we have a date
      if (length($subBarcode)==6) {
         # date has six chars, go to eight chars
         my $y=substr $subBarcode,0,2;
         if ($y<=30) {
           $subBarcode="20$subBarcode";
         } else {
           $subBarcode="19$subBarcode";
         }
      }
      # format the date string
      $sql="$name=".DocumentAddDatForm("$subBarcode");
    } elsif ($type eq "varchar") {
      # we have a text value
      # if field has less chars then subbarcode, then adjust it
      $subBarcode = substr $subBarcode,0,$size if length($subBarcode)>$size;
      $sql="$name=".$obj->dbh2->quote($subBarcode);
    } elsif ($type eq "int" || $type eq "tinyint" || $type eq "double") {
      # we have a number value
      $subBarcode = substr $subBarcode,0,$size if length($subBarcode)>$size;
      $sql="$name=$subBarcode";
    }
    
  }
  # if we did found something, then add the separate char (, )
  $sql = ", ".$sql if $sql ne "" && $notfirst>0;
  checkLinkFields($obj->dbh2,\$sql,$name,$type,$subBarcode);
  return $sql;
}






=head2 checkLinkFields($dbh,$psql,$name,$type,$val)

Check if we have a code/definition pair for a given value

=cut

sub checkLinkFields {
  my $dbh = shift;
  my $psql = shift;
  my $name = shift;
  my $type = shift;
  my $val = shift;
  return if $type eq "datetime";
  if ($name ne "") {
    if ($type eq "int") {
      $val = int $val;
    }
    # give back the connected field (if available)
    my $sql1="select Definition,FeldDefinition from feldlisten where " .
             "FeldCode=".$dbh->quote($name)." and " .
             "Code=".$dbh->quote($val)." limit 1";
    my @fld = $dbh->selectrow_array($sql1);
    my $def2 = $fld[0];
    my $fld2 = $fld[1];
    $$psql .= ",$fld2=".$dbh->quote($def2) if ($def2 ne "" && $fld2 ne "");
  }
}






=head2 $sqlpart=checkBarcodeAddAutoFields($dbh,$field,$val,@$fields,$notfirst)

We add desired default values to the database
  
=cut

sub checkBarcodeAddAutoFields {
  my ($dbh,$fld,$val,$pfields,$obj) = @_;
  my @fields = @$pfields;
  $val = unescape($val);
  my ($cres,$c,$sql);
  $cres=-1;
  $c=0;
  foreach(@fields) {
    my $name = $fields[$c]->{name};
    if ($name ne "Seiten" and $name ne "Akte") {
      # compare to the actual field name
      if ($name eq $fld) {
        $cres=$c;
      }
    }
    $c++;
  }
  if ($cres>=0) {
    my $name=$fields[$cres]->{name};
    my $type=$fields[$cres]->{type};
    my $size=$fields[$cres]->{size};
		if ($name eq "Eigentuemer") {
		  $val = substr($val,0,15);
			$obj->owner($val);
			checkOwner($obj);
			$val = $obj->owner();
		}
    if ($type eq "datetime") {
      # we have a date
      if (length($val)==6) {
        # date has six chars, go to eight chars
        my $y=substr $val,0,2;
        if ($y<=30) {
          $val="20$val";
        } else {
          $val="19$val";
        }
      } elsif (length($val)==10) {
        # Date in format ex: 25.06.2006
        my ($day,$month,$year) = split(/\./,$val);
        $val = "$year$month$day"; 
      }
      # format the date string
      $sql="$name=".DocumentAddDatForm("$val");
    } elsif ($type eq "varchar") {
      # we have a text value
      # if field has less chars then subbarcode, then adjust it
      $sql="$name=".$dbh->quote($val);
    } elsif ($type eq "int" || $type eq "tinyint" || $type eq "double") {
      # we have a number value
      $sql="$name=$val";
    }
    checkLinkFields($dbh,\$sql,$fld,$type,$val);
  }
  return $sql;
}






=head2 $supr=checkEmptyPage($obj,$tmpimg)

Checks if the page is empty (1=empty, 0=not activated or not empty)

=cut

sub checkEmptyPage {
  my ($obj,$tmpimg) = @_;
	my $emptypages = $obj->checkemptypage;
  my $rand = 0;
	my $supress = 0;
  ( $emptypages, $rand ) = split /\./, $emptypages;
  $emptypages = $emptypages / 1000;
  # rand pixel must be a maximum of 8
  $rand = $rand - ( $rand % 8 );
  if ( $emptypages > 0 ) {
    # empty pages are activated
    $supress = 1;
    # Make a working copy for isEmpty so that the original is still unmodified
    my $tmpimg2 = ExactImage::copyImage($tmpimg);
    if ($obj->depth>1) {
      # convert a colour/grayscale image to black/white
      ExactImage::imageOptimize2BW($tmpimg2,0,0,128,1,2.1);
    }
    $rand = 0 if $rand < 0;
    # black/white is analysis
    my $res = ExactImage::imageIsEmpty($tmpimg2,$emptypages,$rand);
		$supress=0 if $res!=1;
    ExactImage::deleteImage($tmpimg2);
  }
  return $supress;
}






=head2 $res=writeFile($file,$pcontent,$killold)

Saves a file (if needed with check) from a pointer variable (1=success)

=cut

sub writeFile {
  my ($file,$pcontent,$killold) = @_;
  my ($res);
  if ($killold) {
    unlink $file if (-e $file);
  }
  if (!-e $file) {
    open(FOUT,">>$file");
    binmode(FOUT);
    print FOUT $$pcontent;
    close(FOUT);
    $res=1 if (-e $file);
  }
  return $res;
}






=head2 readFile($file,\$memory)

Reads a file and stores its contents to a pointer (file must exist)

=cut

sub readFile {
  my ($file,$pmemory) = @_;
  open( FIN, $file );
  binmode(FIN);
	$$pmemory = undef; # reset pmemory 
	while(my $line = <FIN>) {
	  $$pmemory .= $line;
	}
  close(FIN);
}







=head1 readFile2($file,$pout,$killit)

Get the file back as a pointer

=cut

sub readFile2 {
  my ($file1,$pout,$killit) = @_;
  my $buf = "";
	$$pout = "";
	eval { open (FH, '< :raw', $file1) or die $!; };
	my $length = 4096*1024;
  while (my $read = sysread( FH, $buf, $length) ) {
    $$pout .= $buf;
	}
	if ($killit==1) {
	  unlink $file1 if -e $file1;
	}
}






=head2 optimizeBW($obj,$image)

Check if we need a black/white optimization

=cut

sub optimizeBW {
  my ($obj,$image) = @_;
  if ($obj->bwoptimize==1 && $ENV{AV_OPTIMIZE_OFF}==0) {
	  $obj->bwdepth(1); # set to black/white optimization
    # we have a gray or color image
    # we need to have a look in the scan definitions
		my $bwoutdpi = $obj->bwoutdpi;
		$bwoutdpi=0 if ExactImage::imageXres($image)==$obj->bwoutdpi;
		if ($obj->depth>1) {
      ExactImage::imageOptimize2BW($image,0,0,$obj->bwthreshold,
		                              $obj->bwradius,2.1,$bwoutdpi);
		}
  }
}






=head2 $val=getParameterRead($dbh,$db1,$val)

Read a value form the parameter table and give it back as string

=cut

sub getParameterRead {
  my ($dbh,$db1,$val) = @_;
  return getParameterReadWithType($dbh,$db1,'parameter',$val);
}






=head2 $val=getBoxParameterRead($dbh,$db1,$val,$min,$max,$def)

Read a BOX value form the parameter table and give it back as string

=cut

sub getBoxParameterRead {
  my ($dbh,$db1,$val,$min,$max,$def) = @_;
  my $res = getParameterReadWithType($dbh,$db1,'ArchivistaBox',$val);
  $res=$def if ($res<$min || $res>$max);
  return $res;
}






=head2 $val=getParameterReadWithType($dbh,$db1,$type,$val)

Reads a value from the parameter table and gives it back as a string

=cut

sub getParameterReadWithType {
  my ($dbh,$db1,$type,$val) = @_;
  my $val1 = $dbh->quote($val);
  my ( $sql, @row, );
  # we need to have a look in the scan definitions
  $sql = "select Inhalt from $db1.parameter where Art = " .
         $dbh->quote($type) . " AND Name=$val1";
  @row = $dbh->selectrow_array($sql);
  return $row[0];
}






=head2 FTPaddPages($dbh,$host,$db,$user,$pw,$ftpin,$logid,$fout,$pfinfo) 

Add all pages of a given pdf/ps file with sane-client.pl

=cut

sub FTPaddPages {
  my ($fout,$pfinfo) = @_;
  my $ftpin  = $val{ftpin};
  # check if we have a pdf AND (optional) postscript file (cups)
  my ( $pdffile, $psfile ) = _FTPgetFileNames( $ftpin, $pfinfo );
  # check for the desired database, so we can get options
  my $destdb = $$pfinfo{Destination};
  $destdb =~ s/(.*?)(-)(.*?)$/$3/;
	my $dbh = MySQLOpen();
	if ($dbh) {
	  my $db = $val{db};
	  $db = $destdb if checkDatabase($dbh,$destdb);
    $ENV{'AV_OPTIMIZE_OFF'} = 1; # we dont want B/W optimisation
	  if ($$pfinfo{'Profile'} eq "" && $$pfinfo{'NoOCRfromCUPS'}==0) {
      # load the first definition if there is none available
		  # AND if we are NOT in CUPS mode
      $$pfinfo{'Profile'}=getScanDefByNumber($dbh,$db,0);
	  }
    my $checkdef=getScanDefByName($dbh,$db,$$pfinfo{'Profile'});
    my @valdefs=split(";",$checkdef);
	  if ($valdefs[0] eq $$pfinfo{'Profile'} && $$pfinfo{'Profile'} ne "") {
		  # if we have only the name of a def and the name exists,
		  # we switch to this scan def 
	    $$pfinfo{'Profile'} = $checkdef;
      $ENV{'AV_OPTIMIZE_OFF'} = 0; # we dont want B/W optimisation
	  }
	  $dbh->disconnect();
    my $fields = $$pfinfo{'Fields'};
    $ENV{'SCAN_FIELDS'} = $fields;
	  my $rotate = 0;
	  $rotate = 90 if $$pfinfo{'Paper orientation'} eq 'Landscape';
    $ENV{'PAGE_ROTATION'} = $rotate;
    $ENV{'AV_SCAN_BASE'} = $fout;
    $ENV{'AV_SCAN_EXT'} = 'jpg'; 
    $ENV{'AV_SCAN_EXT'} = 'tif' if $$pfinfo{'Bits per pixel'}==1;
    $ENV{'AV_SCAN_DEFINITION'} = $$pfinfo{'Profile'};
    $ENV{'AV_SOURCE'}=$pdffile if $psfile ne "" || $$pfinfo{'ImportSource'}==1;
		$ENV{'AV_SCAN_HOST'} = $val{host};
    $ENV{'AV_SCAN_DB'} = $db;
	  $ENV{'AV_SCAN_USER'} = $val{user};
	  $ENV{'AV_SCAN_PWD'} = $val{pw};
	  $ENV{'AV_SCAN_PATH'} = $ftpin;
		$ENV{'AV_SOURCE2'} = $$pfinfo{'SourceFile'}; # mail zip file
		if ($$pfinfo{'NoOCRfromCUPS'}) { # we don't want ocr
      $ENV{'AV_SOURCE3'}=$pdffile;
		}
		if (-e $val{ftpprocess}) {
		  my $text="";
		  readFile($val{ftpprocess},\$text);
			my @vals = split("\n",$text);
	    $ENV{'AV_SCAN_HOST'} = $vals[0] if $vals[0] ne "";
      $ENV{'AV_SCAN_DB'} = $vals[1] if $vals[1] ne "";
	    $ENV{'AV_SCAN_USER'} = $vals[2] if $vals[2] ne "";
	    $ENV{'AV_SCAN_PWD'} = $vals[3] if $vals[3] ne "";
		}
   	system($val{sane});
    # remove the source files if they exist
    unlink $pdffile if ( -e $pdffile );
    unlink $psfile  if ( -e $psfile );
	}
}






=head3 FTPaddPagesSource($obj,$maxpages);

Extract pdf pages and text and store the information to the db

=cut

sub FTPaddPagesSource {
  my ($obj,$maxp) = @_;
  # check if we should add pdf files at all
	if (-e $obj->source || -e $obj->addtext) {
	  my $file = $obj->source;
		$file = $obj->addtext if !-e $file; 
		my $start = 1; 
    $start=$ENV{AV_PAGE_START} if $ENV{AV_PAGE_START}>0;
		my $part = 0;
		my $end = $obj->pages;
		if ($ENV{AV_PAGE_LAST}>0) {
      $end=$ENV{AV_PAGE_LAST};
			$part = 1;
		}
		$part=1 if $obj->pagesframe_beg>0; # doc. reached MAX_PAGES
		my $found = 0;
		if ($obj->nosingle==1) { # store everything in one doc
      $found = FTPaddPagesSourceAllPages($obj,$start,$end,$file,$part,$maxp);
		} else { # all pages individuallly
      $found = FTPaddPagesSourceSinglePages($obj,$start,$end,$file,$part);
		}
		if ($found==1) {
		  $obj->logdone(4); # say to ocr we don't want it (source file);
		}
		# say to the document that we have an internal PDF file
    my $sql = "update archiv set QuelleExt='PDF',QuelleIntern=1 ".
              "where Laufnummer=".$obj->doc;
    $obj->dbh2->do($sql);
  }
}





=head1 FTPaddPagesSourceSinglePages($obj,$start,$end,$file,$part)

Store the pdf pages and/or text in single pages

=cut

sub FTPaddPagesSourceSinglePages {
  my ($obj,$start,$end,$file,$part) = @_;
  my $pdftk = $val{pdftk};
	my $c1 = 1;
	my $found = 0;
	$c1 = $start if $part==0;
	for (my $c=$start;$c<=$end;$c++) { 
    my $nr = ( $obj->doc * 1000 ) + $c1;
    # we need two temp. files for the actual page (pdf/txt files)
    my $pdf1 = $file . "$c-s";
    my $ptxt = $file . "$c-t";
    # extract the actual pdf page
    my $cmd = "$pdftk ".$file." cat $c output $pdf1";
	  logit($cmd);
    my $res = system($cmd);
    if ( $res == 0 ) {
      if ( -e $pdf1 ) {
				my $text = "";
				FTPaddPagesSourcePDF($obj,$nr,$pdf1) if $obj->pdf==1;
				FTPaddPagesSourceText($obj,$pdf1,$ptxt,\$text);
				$found=1 if $text ne "";
				FTPaddPagesSourceTextSave($obj,\$text,$nr);
			}
		}
		unlink $pdf1 if -e $pdf1;
		unlink $ptxt if -e $ptxt;
	  $c1++;
	}
	return $found;
}





=head FTPaddPagesSourceTextSave($obj,$ptext,$nr)

Save a single page of text in db

=cut

sub FTPaddPagesSourceTextSave {
  my ($obj,$ptext,$nr) = @_;
	if ($$ptext ne "") {
    my $txt = $obj->dbh2->quote($$ptext);
	  my $sql1 = "update archivseiten set Text=$txt where Seite=$nr";
    $obj->dbh2->do($sql1);
	}
}





=head FTPaddPagesSourcePDF($obj,$nr,$pdf1)

Save one/more pdf pages to a document page

=cut

sub FTPaddPagesSourcePDF {
  my ($obj,$nr,$pdf1) = @_;
  # the actual pdf page is extracted, now read it
  my $pmem;
  # read the content
  readFile( $pdf1, \$pmem );
  $pmem = $obj->dbh2->quote($pmem);
  my $sql = "update archivbilder set Quelle=$pmem where Seite=$nr";
  # save the page to the database table
  $obj->dbh2->do($sql);
}






=head1 FTPaddPagesSourceAllPages($obj,$start,$end,$file,$part)

Save all pdf pages to one document and store page texts if needed

=cut

sub FTPaddPagesSourceAllPages {
  my ($obj,$start,$end,$file,$part,$maxpages) = @_;
	my $found = 0;
  my $pdftk = $val{pdftk};
	my $pdf1 = $file;
  my $ptxt = $file . "-t";
	my $res = 0;
	my $seiten = $end - $start + 1;
	if ($part==1 && ($start>1 || $obj->pagesframe_beg>0)) {
	  my $frame = $obj->pagesframe_end();
	  my $start1 = $start + $frame;
		my $end1 = $end + $frame;
    $pdf1 = $file . "-s";
    # extract the actual pdf pages
    my $cmd = "$pdftk '$file' cat $start1-$end1 output '$pdf1'";
	  logit($cmd);
    $res = system($cmd);
	} 
  if ($res==0) {
		my $text="";
    my $nr = ( $obj->doc * 1000 ) + 1;
		FTPaddPagesSourcePDF($obj,$nr,$pdf1) if $obj->pdf==1;
	  FTPaddPagesSourceText($obj,$pdf1,$ptxt,\$text);
		if ($text ne "") {
		  my @pages = split(/\14/,$text);
			my $c1 = 1;
	    $c1 = $start if $part==0;
			for (my $c=$start;$c<=$end;$c++) {
			  my $c2 = $c1 - 1;
				my $text1 = $pages[$c2];
				$found=1 if $text1 ne "";
        my $nr1 = ( $obj->doc * 1000 ) + $c1;
				FTPaddPagesSourceTextSave($obj,\$text1,$nr1);
				$c1++;
			}
		}
	} else {
	  logit("error while text extracting");
	}
	if ($maxpages==0) {
	  unlink $pdf1 if -e $pdf1 && $part==1;
	}
	unlink $ptxt if -e $ptxt;
	return $found;
}






=head FTPaddPagesSourceText($obj,$pdf1,$ptxt,$presult)

Extract page text from a pdf file and give back the text

=cut

sub FTPaddPagesSourceText {
  my ($obj,$pdf1,$ptxt,$presult) = @_;
  # now extract the page text
  my $pdf2txt = $val{pdf2txt};
  my $cmd1 = "$pdf2txt -layout '$pdf1' '$ptxt'";
  my $res = system($cmd1);
  if ($res==0 ) {
    if ( -e $ptxt ) {
	    if (check64bit()==64) {
			  my $ptxt1 = $ptxt.".ttt";
				unlink $ptxt1 if -e $ptxt1;
        my $cmd = "iconv -c -f utf8 -t iso-8859-1 '$ptxt' -o '$ptxt1'";
				my $res = system("$cmd");
				if (-e "$ptxt1") {
				  unlink "$ptxt" if -e "$ptxt";
					move("$ptxt1","$ptxt");
				}
			}
      # there is a txt file, so add the text to the database table
      readFile( $ptxt, $presult );
		}
	}
}






=head3 FTPaddPagesSource2($obj);

Store mail zip file to BildA

=cut

sub FTPaddPagesSource2 {
  my ($obj) = @_;
	logit($obj->source2);
	if (-e $obj->source2 && ($obj->pagesframe_end==0 || $obj->officeimages==1)) {
	  if ($obj->pages>0) {
      my $nr = ($obj->doc*1000)+1;
			my $pmem;
      readFile($obj->source2,\$pmem);
      $pmem = $obj->dbh2->quote($pmem);
      my $sql = "update archivbilder set BildA=$pmem where Seite=$nr";
      $obj->dbh2->do($sql);
      if ($ENV{'AV_SOURCE_NOTKILL'}==0) {
			  my $res=unlink $obj->source2 if -e $obj->source2;
			}
		}
	}
}






=head3 _FTPgetFileNames($path,$pfinfo)

Give back the pdf AND postscript file name if they exist

=cut

sub _FTPgetFileNames {
  my $path   = shift;
  my $pfinfo = shift;

  # file name without extension
  my $fout = $$pfinfo{'File name'};
  my $fps  = $fout;
  $fps =~ s/(.*)(\.pdf)$/$1.ps/;
  if ( $fps ne $fout ) {
    # check if the postscript file is available
    if ( -d $path ) {
      $fps = "$path$fps";
      $fps = "" if ( !-e $fps );
    } else {
      $fps = "";
    }
  } else {
    $fps = "";
  }
  # check if the pdf file is available
  $fout = "$path$fout";
  $fout = "" if ( !-e $fout );
  # give back both file names
  return ( $fout, $fps );
}






=head3 %newhash=_FTPinitHash($pfinfo)

Give us back a new empty hash for the values from axis file

=cut

sub _FTPinitHash {
  my $pfinfo = shift;

  %$pfinfo = (
    'File name'          => '',    # file
    'Date'               => '',    # date
    'Destination'        => '',    # db or owner (at{'destdb'})
    'Paper size'         => '',    # size (A4)
    'Number of pages'    => '',    # pages
    'Width'              => '',    # Pixel x
    'Height'             => '',    # Pixel y
    'X Resolution (DPI)' => '',    # 75-9600
    'Y Resolution (DPI)' => '',    # 75-9600
    'Bits per pixel'     => '',    # 1/8/24
    'Format'             => '',    # Tiff/JPEG
    'Profile'            => '',    # Scan-Defination
    'Paper orientation'  => '',    # Portrait/Landscape
    'Fields'             => '',    # Additional fields
    'ImportSource'       => '',    # 1=import of source file
		'NonAxisFile'        => '',    # normal axis file (no user file name)
		'UserID'             => '',    # userid (unido) -> goes to owner
		'NoOCRfromCUPS'      => '',    # don't call scan def (no ocr after it) 
		'SourceFile'         => '',    # source file (mail archiving)
  );
}






=head2 FTPparseFile ($file,$pfinfo)

Parse the $file from path ftpin and get all informations out of it

=cut

sub FTPparseFile {
  my $file   = shift;
  my $pfinfo = shift;
  my ($res);

  if ($file) {
    logit("Key file $file found");
    # we read all the files, extract the key information
    _FTPinitHash($pfinfo);    # initialize the hash (no old values)
    # read the axis file
    open FIN, "$file" or die "Can't open $file\n";
		my $meta = 0;
    while (<FIN>) {
		  my $line = $_;
      chomp $line;
			if ( $line =~ /\[Metadata\]/ ) {
			  $meta = 1;
			} elsif ($line =~ /\[^(Metadata)\]/ ) {
			  # if we have [something] then we have left the meta mode
			  $meta = 0;
			}
      # go to each line of the file and split it at "= "
			my ($key,$value) = keyvalue($line,"= ");
      # remove \r and \n chars
      $value =~ s/\n//g;
      $value =~ s/\r//g;
      if ( $value ne "" ) {
        # there is a value, remove spaces after key
        $key =~ s/\s*$//;
				if ($meta == 1) {
				  # We have meta Values.
					# They are saved in Fields
					if ($key eq "UserID") {
					  # Set UserID in the pfinfo hash not in Fields
					  $value = escape($value); # don't forget quoting
					  $$pfinfo{"Fields"} .= ":" if $$pfinfo{"Fields"} ne "";
					  $$pfinfo{"Fields"} .= "Eigentuemer=$value";
					} elsif ($key eq "Title") {
					  $key = "Titel"; # Title to Titel (not possible in db)
			    }
					if ($key ne "UserID") {
					  $value = escape($value); # don't forget quoting
					  $$pfinfo{"Fields"} .= ":" if $$pfinfo{"Fields"} ne "";
					  $$pfinfo{"Fields"} .= "$key=$value";
					}
				} else {
          foreach my $k1 ( keys %$pfinfo ) {
            # go through the hash and if it is there, store the value
            if ( $k1 eq $key ) {
              $$pfinfo{$key} = $value;
            }
          }
				}
      }
    }
    close FIN;
    # kill the axis txt file
    my $f1 = "$file";
    unlink $f1 if ( -e $f1 );
    $res = 1;
  }
  return $res;
}







=head2 FTPsplitFile ($pfinfo)

Extracts the images from a given pdf file

=cut

sub FTPsplitFile {
  my $pfinfo = shift;
  my $path   = $val{ftpin};
  my $gogs   = $val{ftpgs};

  # file name without extension
  my $fout = $$pfinfo{'File name'};
  $fout = checkPathAlreadyHere($fout,$path);
  $$pfinfo{'File name'} = $fout;
  $fout =~ s/(.*)(\.pdf)$/$1/;
	if ($fout eq $$pfinfo{'File name'}) {
    $fout =~ s/(.*)(\.jpg)$/$1/;
		if ($fout ne $$pfinfo{'File name'}) {
		  my $fout1 = $fout."0001.jpg";
			my $in = $path.$$pfinfo{'File name'};
			my $out = "$path$fout1";
		  move($in,$out);
		} else {
		  $fout="";
		}
		return $fout;
  }		  
  # extract resolution information
  my $rx = $$pfinfo{'X Resolution (DPI)'};
  $rx = 300 if ( $rx < 75 || $rx > 9600 );
  my $ry = $$pfinfo{'Y Resolution (DPI)'};
  $ry = 300 if ( $ry < 75 || $ry > 9600 );

  # normally we want tiff g4
  my $dev = "tiffg4";
  my $ext = "tif";

  # check, if we have to process jpeg
  $dev = "jpeggray" if ( $$pfinfo{'Bits per pixel'} == 8 );
  $dev = "jpeg"     if ( $$pfinfo{'Bits per pixel'} == 24 );
  $ext = "jpg"      if ( $dev eq "jpeggray" || $dev eq "jpeg" );

  # check for a postscript file (from cups2axis.pl)
  my $fpdf = $$pfinfo{'File name'};
  my $fps  = $fpdf;
  $fps =~ s/(.*)(\.pdf)/$1.ps/;
  my $ppdf = "$path$fpdf";
  my $pps  = "$path$fps";
  my $fin  = $ppdf;
  $fin = $pps if ( -e $pps );
  # we use gs to extract jpg files
  my $f1="$gogs -sDEVICE=$dev -r$rx"."x$ry " . # device and resolution
         "-sOutputFile=\"$path$fout".'%04d.'."$ext\" \"$fin\""; # out/in file
  logit("Extract image files from $fin\n");
  my $res = system("$f1");
  # if processing was not sucessfully, then kill fout file
	if ($res != 0) {
	  logit("Use second raster engine");
		$res = _FTPsplitExtended($ppdf,"$path$fout",$dev,$ext);
	}
	$fout = "" if $res!=0;
  return $fout;
}






=head1 $file=checkPathAlreadyHere($file,$path)

Check if the given path is inside the file name

=cut

sub checkPathAlreadyHere {
  my ($file,$path) = @_;
	if (index($file,$path)==0) {
	  my @parts = split(/\//,$file);
		$file = pop @parts;
	}
	return $file;
}






sub _FTPsplitExtended {
  my ($fin,$fout,$dev,$ext) = @_;
	my $maxpage=0;
	my $res=-1;
  my $out = `pdfinfo $fin`;
	$out =~ /(Pages:)(\s+)([0-9]+)/;
	$maxpage = $3;
	my $zeros = getZeros($maxpage);
	my $opt = "";
	$opt = "-mono" if $dev eq "tiffg4";
	$opt = "-gray" if $dev eq "jpeggray";
  my $ext1 = "pbm";
  $ext1 = "pgm" if $dev eq "jpeggray";
	$ext1 = "ppm" if $dev eq "jpeg";
	if ($maxpage>0) {
	  my $cmd = "pdftoppm $opt -r 300 -f 1 -l $maxpage $fin $fout";
		$res = system($cmd);
		if ($res==0) {
		  logit("all images created");
		  for (my $c=1;$c<=$maxpage;$c++) {
		    my $fout2 = $fout."-".sprintf($zeros,$c).".$ext1";
			  my $fout3 = $fout.sprintf("%04d",$c).".$ext";
			  unlink $fout3 if -e $fout3;
			  move($fout2,$fout3);
		  }
		}
	}
	return $res;
}






=head2 CUPSgetPSFile($file,$file2)

Gets the apprpriate postscript file from a cups-pdf file

=cut

sub CUPSgetPSFile {
  my $file  = shift;
  my $file2 = shift;

  my $cupsps = $val{cupsps};
  my $ftpin  = $val{ftpin};
  my $fps    = $file;
  my $res    = 0;
	my $printer = "";
  my ( $db, $user, $defname );

  # now lets have a look at the original ps file
  $fps =~ s/^(job_)([0-9]+)(.*)(pdf)$/$2/;
  if ( $fps > 0 ) {
    # store the job number
    my $fnr = $fps;

    # we got the job number
    $fps = "d" . sprintf( "%05d", $fps ) . "-001";
    my $fin  = "$cupsps$fps";
    my $fout = "$ftpin$file2";
    if ( -e $fin ) {
      unlink $fout if -e $fout;
      # move the file to the ftp folder
      $res = move( $fin, $fout );

      # now get the desired database
      my $jobs = `$val{cupsinfo}`;
      my @l = split( "\n", $jobs );
      foreach ( reverse @l ) {
        # go through all lines and split with empty chars
        my @l1 = split( " ", $_ );
				my $line = join("",@l1);
				# check for unwanted chars (printer is behind @) -> leuthold
				my @parts0 = split("@",$line);
				my $l2 = pop @parts0;
        # now lets have a look at printer-jobnr
        my @parts = split( "-", $l2 );
				my $pr = shift @parts;
				my $nr = pop @parts;
				my $def = join("-",@parts);
        if ( $nr == $fnr ) {
          # we did find a job number, so store db and user
          $db = $pr;
					$defname = $def;
					$printer = "$db-$defname" if $defname ne "";
          last;
        }
      }
    }
  }
  return ( $res, $db, $defname, $printer );
}






=head2 CUPSparseFile ($file,$psfile)

Create an axis key file with pdfinfo

=cut

sub CUPSparseFile {
  my $file   = shift;
  my $psfile = shift;
  my $db     = shift;
	my $defname = shift;
	my $fieldsgl = shift;
	my $sourcefile = shift;
	my $printer = shift;
  # if we got no desitination, then add standard
  $db = "archivista" if $db eq "";
  my $pdfinfo = $val{pdfinfo};
  my $dir     = $val{ftpin};
  my $color   = 0;
  my $out     = "";
  my $first   = 1;
  my $psdf    = "$dir$psfile";
  if ( -e $psdf ) {
    # check ps file for orientation
    open( FIN, $psdf );
    while (<FIN>) {
      my $line = $_;
      $line =~ /^(\%\%Orientation:\s)([a-zA-Z]*)(.*)?$/;
      if ( $2 eq "Portrait" or $2 eq "Landscape" ) {
        # check for landscape orientation
        if ( $first == 1 ) {
          $out .= "Paper orientation     = $2\n";
          $first = 0;
        }
      }
      # check for a color printer
      $line =~ /^(\%\%TargetDevice:\s)(.*)(Color)(.*)?$/;
      $color = 1 if $3 eq "Color";
      # check for end of comments, so we don't read the full file
      $line =~ /^(\%\%)(EndComments)(.*)$/;
      last if $2 eq "EndComments";
    }
    close(FIN);

    my $keys  = `$pdfinfo $dir$file`;
    my $title = $keys;
    $title =~ s/(.*)(Creator\:)(\s+)(.*?)(\n.*)/$4/s;
    $title =~ s/(.*)(Producer\:)(\s+)(.*?)(\n.*)/$4/s if $title eq $keys;
    if ( $title ne $keys ) {
      # document is correct
      # extract title (Fields for COLDplus)
      # check for COLDplus
      my $for = $keys;
			$for =~ s/(.*)(Author\:)(\s+)(.*?)(\n.*)/$4/s;
      if ($for ne $keys) {
        $for =~ s/\s//g; # we did found an author, remove spaces
      } else {
        $for = ""; # not found, not used
      }
      my $fields = $keys;
      $fields =~ s/(.*)(Title\:)(\s+)(.*?)(\n.*)/$4/s;
      # if there was no match, no title, clear the fields
      $fields = "" if $fields eq $keys;
			my $fields2 = $fields;
			CUPSCheckOffice(\$db,\$fields,$file,$psfile,$title,\$sourcefile);
      CUPSCheckCOLDplus(\$db,$fields2,$file,$psfile,$for,\$fields,$printer);
      # extract pages
      my $pages = $keys;
      $pages =~ s/(.*)(\nPages\:)(\s+?)([0-9]+)(.*)/$4/s;
      # extract sizex
      $keys =~ /(Page\ssize\:)(\s+)([0-9]+)?(\sx\s)([0-9]+)?(.*)/;
      my $sizex = int $3 * 4.19498;
      # extract sizey
      $keys =~ /(Page\ssize\:)(\s+)([0-9]+)?(\sx\s)([0-9]+)?(.*)/;
      my $sizey = int $5 * 4.16158;
      # compose axis file
      my @row;
      $row[0] = "Destination           = $db";
      $row[1] = "File name             = $file";
      if ( $color == 0 ) {
        $row[2] = "Bits per pixel        = 1";
        $row[5] = "Format                = TIF";
      } else {
        $row[2] = "Bits per pixel        = 24";
        $row[5] = "Format                = JPEG";
      }
      $row[3] = "X Resolution (DPI)    = 300";
      $row[4] = "Y Resolution (DPI)    = 300";
      $row[6] = "Number of pages       = $pages";
      $row[7] = "Width                 = $sizex";
      $row[8] = "Height                = $sizey";
			$row[9] = "NonAxisFile           = 1";
			$row[10] = "NoOCRfromCUPS        = 1";
			if ($defname ne "") {
				my $dbh = MySQLOpen();
				if ($dbh) {
				  my $scandef = getScanDefByName($dbh,$db,$defname);
					my @valdefs = split(";",$scandef);
					if ($valdefs[0] eq $defname) {
					  my $depth = 1;
		        $depth = 8 if $valdefs[1]==1;
		        $depth = 24 if $valdefs[1]==2;
            $row[2] = "Bits per pixel        = $depth";
            $row[3] = "X Resolution (DPI)    = $valdefs[2]";
            $row[4] = "Y Resolution (DPI)    = $valdefs[2]";
						if ($depth==1) {
              $row[5] = "Format                = TIF";
            } else {
              $row[5] = "Format                = JPEG";
            }
			      $row[11] = "Profile              = $defname";
					}
				}
			}
			if ($sourcefile ne "") {
			  $row[12] = "SourceFile           = $sourcefile";
			}
      $out .= join( "\n", @row ) . "\n";
			if ($fieldsgl ne "") {
			  $fields.=":" if $fields ne "";
				$fields.=$fieldsgl;
			}
      # add field values (form COLDplus)
      $out .= "Fields                = $fields";
      my $fout = $file;
      $fout =~ s/^(.*?)(\.)(pdf)$/$1/;
      $fout .= '.txt';
      $fout = "$dir$fout";
      open( FOUT, ">$fout" );
      print FOUT $out;
      close(FOUT);
    }
  }
}






=head2 $vals=CUPSCheckOffice($pdb,$pfields,$file,$psfile,$title)

Checks if we have a locally office printerd document

=cut

sub CUPSCheckOffice {
  my $pdb     = shift;
  my $pfields = shift;
  my $file    = shift;
  my $psfile  = shift;
  my $title   = shift;
	my $psourcefile = shift;
  $file   = $val{ftpin} . $file;
  $psfile = $val{ftpin} . $psfile;
	my $vers = "3.0";
  $vers = "3.2" if check64bit()==64;
	if ($title eq "(OpenOffice.org $vers)") {
	  my $name = $$pfields;
		$name =~ s/^\(//;
		$name =~ s/\)$//;
		my $pfad = "/home/data/archivista/ftp/officeout/$$pdb/$name";
		my @files = <$pfad*>;
		if (-e $files[0]) {
		  my $filein = $files[0];
		  my @parts = split(/\//,$files[0]);
			my $nameold = pop @parts;
			my @parts1 = split("_",$nameold);
			shift @parts1;
			my $namenew = join("_",@parts1);
			push @parts,$namenew;
			my $fileout = join("/",@parts);
			unlink $fileout if -e $fileout;
			my $res=move($filein,$fileout);
			if ($res==1) {
			  my $zipname = $fileout.".zip";
        unlink($zipname) if (-e $zipname); # make sure we never append
			  my $cmd = "zip -j $zipname $fileout";
				$res = system($cmd);
				if ($res==0) {
			    logit("sourcefile added:$zipname");
			    $$psourcefile=$zipname;
			    $namenew = escape($namenew); # don't forget quoting
				  $$pfields = "EDVName=office;$namenew";
				  logit("pfields:$$pfields");
				}
			}
    }		
	}
}






=head2 $vals=CUPSCheckCOLDplus($db,$file)

Checks if we have a coldplus program and gives back the field values

=cut

sub CUPSCheckCOLDplus {
  my $pdb     = shift;
  my $fields  = shift;
  my $file    = shift;
  my $psfile  = shift;
  my $for     = shift;
	my $pfields = shift;
	my $printer = shift;
  $file   = $val{ftpin} . $file;
  $psfile = $val{ftpin} . $psfile;
  my $prg = $val{coldplus};
  if ( -e $prg ) {
	  logit("coldplus with file $file");
    # Program is available
    my $cmd    = "$prg $$pdb '$$pfields' $file $psfile $for $printer";
    my $fields = `$cmd`;
    if ( $fields ne "" ) {
      my $db = $fields;
      $db     =~ s/^(.*?)(;)(.*)$/$1/;
      $fields =~ s/(.*?)(;)(.*)$/$3/;
      $$pdb     = $db;
      $$pfields = $fields;
		}
	}
}






=head2 CUPSwaitAndMove($file)

Moves the file to the ftp folder

=cut

sub CUPSwaitAndMove {
  my $file = shift;
  my $cupsin = $val{cupsin};
  my $ftpin  = $val{ftpin};
  my $res;
  my $file1 = $file;
  # we only use simple file names (ghostscript does not like strong names)
  $file1 =~ s/(.*?)(\-)(.*)/cups-$1./;
  # give a simple name to the ps file
  my $file2 = "$file1" . 'ps';
  # and now to the pdf file
  $file1 .= 'pdf';
  my $fin  = "$cupsin$file";
  my $fout = "$ftpin$file1";
  unlink $fout if ( -e $fout );
  # move the file to the ftp dir
  $res = move( $fin, $fout );
  return ( $res, $file1, $file2 );
}







=head2 ($doc,$pag,$folder,$typ)=GETnEXTfReeDocument($dbh,$dbn,$dnr,$desc,$sql)

Gives back the next free document we can process

=cut

sub getNextFreeDocument {
  my $dbh = shift;
  my $db1 = shift;
  my $aktnr = shift;
  my $desc = shift;
  my $sqladd = shift;
  # compose base framgent
  my $sql = "select Laufnummer,Seiten,Ordner,ArchivArt from $db1.archiv " .
            "where Gesperrt='' ";
  # add an additional part (if available)
  $sql .= $sqladd if ($sqladd ne "");
  if ($desc) {
    # calcluate last document
    $sql .= "and Laufnummer<=$aktnr order by Laufnummmer desc ";
  } else {
    # calculate first document
    $sql .= "and Laufnummer>=$aktnr order by Laufnummer ";
  }
  # we only want 1 document
  $sql .= "limit 1";
  # do the sql command
  my ( $akte, $seiten, $ordner, $art ) = $dbh->selectrow_array($sql);
  return ($akte,$seiten,$ordner,$art);
}






=head2 $pfadpart=getArchivingFolderPath($folder)

According folder number we calculate path part

=cut

sub getArchivingFolderName {
  my $ordner = shift;
  # folders are always in format (ARCH0001,ARCH0002..)
  my $pfad = "ARCH".sprintf("%04d",$ordner).$val{dirsep};
  return $pfad;
}






=head2 $ext=getArchivingExt($art,$zipped)

Give back the extension from the field value ArchivArt

=cut

sub getArchivingExt {
  my $art = shift;
  my $zipped = shift;
  my $ext = "JPG";
  $ext = "PNG" if $art == 2;
  $ext = "TIF" if $art == 1;
  if ($zipped) {
    $ext = "ZIP" if $art == 0;
  } else {
    $ext = "BMP" if $art == 0;
  }
  return $ext;
}







=head2 $file1=getFileToPng($file,$akte,$seite)

Converts the png file into a png file and gives back the fine name

=cut

sub getFileToPng {
  my $file  = shift;
  my $akte  = shift;
  my $seite = shift;
  my ($file1);
  if ( -e $file ) {
    # file is ok (we actually have a tif file) -> convert it to png
    $file1 = "$val{tmpdir}$akte-$seite.png";
    unlink $file1 if ( -e $file1 );
    my $cmd = "$val{tifpng} $file";
    my $res = system($cmd);
    $file1 = "" if $res > 0;    # we got and error
  }
  return $file1;
}






=head2 $file1=getFileUnzip($mode,$akte,$seite,$file)

Does a zip file unzip to a bmp and convert it to a tif file

=cut

sub getFileUnzip {
  my $mode  = shift;
  my $akte  = shift;
  my $seite = shift;
  my $file  = shift;

  my $pw1   = $seite + 1000;
  my $pw    = "$mode$akte$pw1";
  my $file1 = "$val{tmpdir}$akte-$seite.bmp";

  # unzip the file with the pw and store it to a temp file
  my $cmd = "$val{unzip} $pw $file >$file1";
  if ( !system($cmd) ) {
    # we got 0, so it is ok
    my $file2 = "$val{tmpdir}$akte-$seite.tif";
    unlink $file2 if ( -e $file2 );
    # now we need to translate the bmp to the tif file
    $cmd = "$val{bmptif} $file1 $file2";
    if ( !system($cmd) ) {
      # we got no error, so the file is ok
      # remove the bmp file, we only want the tif
      unlink $file1 if ( -e $file1 );
      $file1 = $file2;
    } else {
      # we got an error, so the file is not ok, kill the bmp file
      unlink $file1 if ( -e $file1 );
      $file1 = "";
    }
  }
  return $file1;
}







=head2 $rowsaffected=DocumentLock($dbh,$db1,$akte,$lockuser)

Locks a document to a given user

=cut

sub DocumentLock {
  my $dbh      = shift;
  my $db1      = shift;
  my $akte     = shift;
  my $lockuser = shift;
  $lockuser = $dbh->quote($lockuser);
  my $sql = "update $db1.archiv set Gesperrt=$lockuser where Akte=$akte";
  my $res = $dbh->do($sql);
  return $res;
}






=head2 $rowsaffected=DocumentUnlock($dbh,$db1,$akte)

Unlocks a document

=cut

sub DocumentUnlock {
  my $dbh  = shift;
  my $db1  = shift;
  my $akte = shift;
  my $sql  = "update $db1.archiv set Gesperrt='' where Akte=$akte";
  my $res  = $dbh->do($sql);
  return $res;
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







=head2 $dbh=MySQLOpen($host,$db,$user,$pw)

Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen {
  my $host = shift;
  my $db   = shift;
  my $user = shift;
  my $pw   = shift;
  $host = $val{host} if $host eq "";
  $db   = $val{db}   if $db   eq "";
  $user = $val{user} if $user eq "";
  $pw   = $val{pw}   if $pw   eq "";
  my ( $ds, $dbh );
  $ds = "DBI:mysql:host=$host;database=$db";
  $dbh = DBI->connect($ds,$user,$pw,{PrintError=>1,RaiseError=>0});
  return $dbh;
}






=head2 $dbh2=MySQLOpen2($logid,$dbh,$pwd)

Open a second MySQL connection and gives back a db handler 2

=cut

sub MySQLOpen2 {
  my $logid = shift;
  my $dbh   = shift;
  my $pwd   = shift; # attention needs to be the last parameter (if no passwd)
  my ( $host, $db, $user, $ds, $dbh2 );
  if ($dbh) {
    my $sql = "select host,db,user from logs where ID=$logid";
    my @row = $dbh->selectrow_array($sql);
    $host = $row[0];
    $db   = $row[1];
    $user = $row[2];
  }
  $ds = "DBI:mysql:host=$host;database=$db";
  $dbh2 = DBI->connect($ds,$user,$pwd,{PrintError=>1,RaiseError=>0});
  return $dbh2;
}






=head1 MySQLClose($dbh) 

Close mysql connection

=cut

sub MySQLClose {
  my $dbh = shift;
	logit("Close db connection");
	$dbh->disconnect;
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
  return $hostIsSlave;
}






=head1 $slave=HostIsSlaveSimple($dbh)

gives back a 1 if we are in slave mode (user session)

=cut

sub HostIsSlaveSimple {
  my $dbh = shift;
  my $hostIsSlave = 0;
  my @row = $dbh->selectrow_array("SHOW VARIABLES LIKE 'server%'");
  $hostIsSlave=1 if $row[1]>1;
  return $hostIsSlave;
}






=head2 getFileNameNr($document,$page,$mode)

Gives back a file name from a doc./page/mode
  
=cut

sub getFileNameNr {
  my ($document,$page,$mode) = @_;
  my $t1 = getFileNameCalc( $document, 5 );
  my $t2 = getFileNameCalc( $page, 2 );
  $mode = "A" if ! defined $mode;
  my $fn=$mode . $t1 . $t2;
  return $fn;
}






=head2 $fname=getSourceFileNameNr($document,$mode)

Returns an archive source-filename.

=cut

sub getSourceFileNameNr {
  my ($document,$mode) = @_;
  my $t1 = getFileNameCalc( $document, 5 );
  my $t2 = "0A";
  $mode = "A" if ! defined $mode;
  my $fn=$mode . $t1 . $t2;
  return $fn;
}






=head2 $fnamepart=getFileNameCalc($input,$count)

Returns an archive filename.

=cut

sub getFileNameCalc {
  my ( $input, $count ) = @_;
  my ( $res, $res1, $t, $tcount );
  while ( $input != 0 ) {
    $res = $input % 26;
    $res1 = $res + 65;
    $t  = chr($res1) . $t;
    $input = $input - $res;
    $input = $input / 26;
  }
  $t = "0" x ( $count - length($t) ) . $t;
  return $t;
}






=head2 $kbused=getDiskSpaceUsed($dir)

Returns the used diskspace on the root filesystem in kbytes.

=cut

sub getDiskSpaceUsed {
  my $folderName=shift;
  # get actual size of a folder and give back the number of files
  my $cmd = "du --max-depth 0 -k $folderName | awk '{print \$1}'";
  my $folderSize = `$cmd`;
  $folderSize =~ s/\r//;
  $folderSize =~ s/\n//;
  return $folderSize;
}






=head2 $kbfree=getDiskSpaceFree($dir)

Returns the available diskspace on the root filesystem in kbytes.

=cut

sub getDiskSpaceFree {
  my $dir=shift;
  return `df -k $dir | sed 1d | awk -F' ' '{ print $4 }'`;
}






=head2 $source=archivingDocExtractSource($dbh,$db1,$doc,$pages,$ext,$tpath)

Extract source file from archivbilder in temp folder and gives back the file

=cut

sub archivingDocSource {
  my ($dbh,$db1,$doc,$pag,$tpath) = @_;
  my (@row,$sql,$ext,$s1,$s2,$l1,$l2,$file,$file1,$img,$res);
  # first, we need the extension of the source file (lower case)
  $sql = "select QuelleExt from $db1.archiv where Laufnummer=$doc";
  @row = $dbh->selectrow_array($sql);
  $ext = lc($row[0]);
  if ($ext ne "") {
    # ext is ok, so check if in the first Seite there is a source file
    $s1 = ($doc*1000)+1;
    $sql = "select length(Quelle) from $db1.archivbilder where Seite=$s1";
    @row = $dbh->selectrow_array($sql);
    $l1 = $row[0];
    if (length($l1>0)) {
      # there is a source file, so now check if it is a single page/pdf
      $s2 = ($doc*1000)+$pag;
      $sql = "select length(Quelle) from $db1.archivbilder where Seite=$s2";
      @row = $dbh->selectrow_array($sql);
      $l2 = $row[0];
      if (length($l2>0) && $ext eq "pdf" && $pag>1) {
        # we have pdf files in every page
        $file=archivingDocSourceSingle($dbh,$db1,$doc,$pag,$tpath,$ext);
      } else {
        # we only have a single file, so extract it
        $file = getSourceFileNameNr($doc,"A")."\.".$ext;
        $file1 = "$tpath$file";
        $sql = "select Quelle from $db1.archivbilder where Seite=$s1";
        @row = $dbh->selectrow_array($sql);
        $img = $row[0];
        $res=writeFile($file1,\$img,1);
        $file="" if $res==0; 
      }
    }  
  }
  logit("Source $file of doc $doc is ok") if $file ne "";
  return $file;
}






=head2 $file=archivingDocSourceSingle($dbh,$db1,$doc,$pag,$tpath,$ext)

Combine single pdf pages to one big pdf file

=cut

sub archivingDocSourceSingle {
  my ($dbh,$db1,$doc,$pag,$tpath,$ext) = @_;
  my ($pf,$anz,$file,$file1,$fin,$fld,$cmd,$res);
  # we have single page pdf files, so combine them together
  $fld = "Quelle";
  $pf = archivingDocExtractImages($dbh,$db1,$doc,$pag,$tpath,$fld,$ext);
  $anz = @$pf;
  if ($anz>0 && $anz==$pag) {
    # all files are ok, now combine them to a single pdf file
    $file = getSourceFileNameNr($doc,"A")."\.".$ext;
    $file1 = "$tpath$file";
    foreach (@$pf) {
      # create a single name string
      $fin .= "$tpath$_ ";
    }
    $cmd = "$val{pdftk} $fin cat output $file1";
    $res = system($cmd);
    $file="" if ($res>0); # unmark file if no success
    foreach (@$pf) {
      # delete old files
      $fin = "$tpath$_ ";
      unlink $fin if (-e $fin);
     }
  }  
  return $file;  
}






=head2 $pfiles=archivingDocExtractImages($dbh,$db1,$doc,$pages,$ext,$tpath)

Extract files from archivbilder in temp folder and gives back the files

=cut

sub archivingDocExtractImages {
  my ($dbh,$db1,$doc,$pages,$tpath,$field,$ext) = @_;
  my ($c,$c1,$sql,@row,@files);
  for ($c=1;$c<=$pages;$c++) {
    $c1 = ($doc*1000)+$c;
    $sql = "select $field from $db1.archivbilder where Seite=$c1";
    my @row = $dbh->selectrow_array($sql);
    my $img = $row[0];
    my $file = getFileNameNr($doc,$c,"A")."\.".$ext;
    my $file1 = "$tpath$file";
    my $res = writeFile($file1,\$img,1);
    if ($res==1) {
      push @files, $file;
    } else {
      @files = ();
      $c=$pages;
    }
  }
  return \@files;
}






=head2 archivingCheckDirs($db1)

Check if the archiving folder output does exist for a given database

=cut

sub archivingCheckDirs {
  my $db1 = shift;
  my ($apath,$ds,$tout,$res);
  # get a temp path for the document
  $ds = $val{dirsep};
  $apath = "$val{dirimg}$db1";
  if (!-e $apath || !-d $apath) {
    mkdir $apath; 
    archivingDocSetOwner($apath);
  }
  if (-d $apath) {
    $tout = "$ds"."output";
    $apath = "$apath$tout";
    if (!-e $apath || !-d $apath) {
      mkdir $apath;
      archivingDocSetOwner($apath);
    }
  }
}






=head2 $res=archivingDocument($dbh,$db1,$doc,$pag,$typ,$f,$s,$pf,$ps,$pf,$ki)

Process a single document and gives back 1 if the archiving process is ok

=cut

sub archivingDocument {
  my ($dbh,$db1,$doc,$pag,$typ,$files,$size,$pfiles,$psize,$pfolder) = @_;
  my ($apath,$apath1,$tpath,$ext,$fld,$pf,$ds,$tout,$psave,$res);
  # get a temp path for the document
  $ds = $val{dirsep};
  $tout = "output$ds";
  $apath = "$val{dirimg}$db1$ds$tout";
  $tpath = "$val{dirimg}$db1-$doc"."s$ds";
  $apath1=archivingDocPathCheck($apath,$$pfolder); # check if folder is ok
  if (-d $apath1) {
    # the archiving folder does exist
    unlink $tpath if (!-d $tpath && -e $tpath);
    mkdir $tpath if (!-d $tpath);
    if (-d $tpath) {
      # the temp path does exist, so extract files to it
      $ext = getArchivingExt($typ);
      $fld = "BildInput";
      $pf = archivingDocExtractImages($dbh,$db1,$doc,$pag,$tpath,$fld,$ext);
      my $anz = @$pf;
      if ($anz>0 && $anz==$pag) {
        # extraction was ok, now extract source file (if needed)
        my $source = archivingDocSource($dbh,$db1,$doc,$pag,$tpath);
        $apath1=archivingDocFolder($dbh,$db1,$doc,$tpath,$apath,$apath1,$anz,
                                   $files,$size,$pfiles,$psize,$pfolder);
        if ($apath1) {
          # now save the files to the folder
          my $err=0;
          foreach (@$pf) {
            $res=archivingDocMoveFile($tpath,$apath1,$_);
            if ($res==0 && $err==0) {
              logit("Error at doc $doc with file $_");
              $err=1;
            }
          }
          if ($source ne "" && $res>0) {
            # move the source file
            $res=archivingDocMoveFile($tpath,$apath1,$source);
          }
        }
      }
    }
  }
  if ($res>0) {
    my $sql="update $db1.archiv set Archiviert=1, " .
            "Ordner=$$pfolder where Laufnummer=$doc";
    $dbh->do($sql);
    logit("Doc. $doc with $pag page(s) archived");
    logit("Folder $$pfolder: $$psize KByte(s) and $$pfiles files");
  } else {
    logit("ERROR: Doc. $doc NOT rchieved");
  }
  # remove the temp path
  my $cmd = "rm -Rf $tpath";
  system($cmd);
}






=head2 archivingDocFolder

Gives back the current archiving folder for the actual document
=cut

sub archivingDocFolder {
  my $dbh = shift;
  my $db1 = shift;
  my $doc = shift;
  my $tpath = shift;
  my $apath = shift;
  my $apath1 = shift;
  my $anz = shift;
  my $files = shift;
  my $size = shift;
  my $pfiles = shift;
  my $psize = shift;
  my $pfolder = shift;

  if ($$psize==0 || $$pfiles==0) {
    # no old size, so it is the first time (does mean: get size/files)
    $$psize = getDiskSpaceUsed($apath1);
    opendir(FOUT,$apath1);
    my @files = readdir(FOUT);
    closedir(FOUT);
    my $anz = @files;
    $$pfiles = $anz-2;
    $$pfiles--;
    $$pfiles--;
  }
          
  # now check if we need a new folder
  my $size1 = getDiskSpaceUsed($tpath);
  $$psize += $size1;
  $$pfiles += $anz;

  if ($$pfiles>$files || $$psize>$size) {
    # we need a new folder
    $$pfolder++;
    archivingFolderUpdate($dbh,$db1,$$pfolder);
    $$pfiles = $anz;
    $$psize = $size1;
    logit("New folder $$pfolder at $doc");
    $apath1=archivingDocPathCheck($apath,$$pfolder); # get new folder
  }
  # check if the maximum number of folder is achieved
  $apath1="" if $$pfolder>$val{avfoldermax};
  return $apath1;
}






=head2 $path = archivingDocPathCheck($pathin,$folder)

Check if the desired folder does exist and gives it back

=cut

sub archivingDocPathCheck {
  my $apath = shift;
  my $folder = shift;
  my $apath1;
  if (-d $apath) {
    # base folder does exist, so get actual folder (and check it)
    $apath1 = $apath.getArchivingFolderName($folder);
    mkdir $apath1 if (!-e $apath1);
    archivingDocSetOwner($apath1);  
  }
  return $apath1;
} 






=head2 $res=archivingDocumentMoveFile($pathin,$pathout,$file)

Move an file from temp to archiving folder

=cut

sub archivingDocMoveFile {
  my $tpath = shift;
  my $apath = shift;
  my $file = shift;
  my ($res,$fin,$fout,$error);
  $fin = "$tpath$file";
  $fout = "$apath$file";
  if (-e $fin && !-e $fout) {
    # move the file to the new folder location
    $res=move($fin,$fout);
    archivingDocSetOwner($fout);    
  }
  return $res;
}






=head2 archivingDocSetOwner($fout) 

Set to a file/folder the standard user

=cut

sub archivingDocSetOwner {
  my $fout = shift;
  # change ownership to archivista user
  chown $val{avuser},$val{avowner},$fout if (-e $fout);
}
  
  




=head2 archivingFolderUpdate($dbh,$db1,$folder)

Store the folder in the parameter table

=cut

sub archivingFolderUpdate {
  my $dbh = shift;
  my $db1 = shift;
  my $folder = shift;
  # update the folder number
  my $sql="update $db1.parameter set Inhalt=$folder where " .
          "Name='ArchivOrdner' and Art='parameter' and " .
          "Tabelle='parameter'";
  $dbh->do($sql);
}






=head2 $res=archivingDatabase($dbh,$dbname)

Establishes the connection to the database and also starts the
archiving process.

=cut

sub archivingDatabase {
  my ($dbh,$db1) = @_;
  my $lockuser = "avarch";
  logit("Start archiving in $db1");
  if (jobStart(20,"archiving")==1) {  
    # first we need the smallest and biggest document
    my $sql="select min(Laufnummer), max(Laufnummer) " .
            "from $db1.archiv " .
            "where Archiviert=0 and Erfasst=1 and Seiten>0 ";
    my ($aakt,$amax) = $dbh->selectrow_array($sql);
    # current folder, files, size, path
    my $foldakt = getParameterRead($dbh,$db1,"ArchivOrdner");
		my $foldstart = $foldakt;
    logit("Current folder is: $foldakt");
    my $files = getParameterRead($dbh,$db1,"ArchivDateien");
    my $size = getParameterRead($dbh,$db1,"ArchivMByte")*1024;
    my $killinput = getParameterRead($dbh,$db1,"ArchivingDeleteInput");
    my ($fakt,$sakt); # hold the number of files and the size
    # now extract the additional conditions
    my $sqladd = getParameterRead($dbh,$db1,"ArchivSQL");
    $sqladd =~ s/(^\s*)(.*?)(\s*$)/$2/;
    # we only want the not archived and those who have pages
    $sqladd = "and ($sqladd) " if ($sqladd ne "");
    $sqladd .= "and Archiviert=0 and Erfasst=1 and Seiten>0 ";
    archivingCheckDirs($db1); # check for existing folders
    while ($aakt<=$amax) {
      # archive document after document
      my ($doc,$pag,$fold,$art)=getNextFreeDocument($dbh,$db1,$aakt,0,$sqladd);
      if ( $doc > 0 and DocumentLock($dbh,$db1,$doc,$lockuser ) ) {
        # we only process documents if > 0 and if current doc is unlocked
        my $error=archivingDocument($dbh,$db1,$doc,$pag,$art,$files,$size,
                                  \$fakt,\$sakt,\$foldakt,$killinput);
        DocumentUnlock($dbh,$db1,$doc); # Unlock document after processing it
        $aakt = $doc; # adjust the doc number to the counter
      } else {
        $aakt = $amax if $doc == 0; # no doc was found, stop process
      }  
      $aakt++; # go to the next document
      if (jobCheckStop(30,"archiving")==1) {
        # if someone want to cancel the job, so do it
        $aakt=$amax+1;
      }
    }
    # update the folder pointer to the current position
    $sql = "update $db1.parameter set Inhalt=$foldakt where " .
           "Name='ArchivOrdner' and Art='parameter' and Tabelle='parameter'";
		$dbh->do($sql);
    my $splittedfolders = getParameterRead($dbh,$db1,"ArchivExtended");
		if ($splittedfolders > 0) {
		  my $cmd = "/usr/bin/perl /home/cvs/archivista/jobs/splitTableImages.pl";
		  logit("$cmd $db1 $splittedfolders $foldstart");
		  my $res = system("$cmd $db1 $splittedfolders $foldstart");
		}
    dumpKeyInfos($dbh,$db1);
    burnCD($dbh,$db1) if -e "/etc/wodim.conf"; # only burn CD/DVD if configured
    jobStop(40,"archiving");
  } else {
    logit("Another job is running, please wait for the end or stop it!");
  }
  logit("Ending archiving process in $db1");
}






=head2 $res=archivingDatabase1($dbh,$dbname,$killinput)

Establishes the connection to the database and also starts the
archiving process.

=cut

sub archivingDatabase1 {
  my $dbh = shift;
  my $db1 = shift;
  my $killit = shift;
  my $lockuser = "avarch";

  logit("Start archiving in $db1");
  if (jobStart(20,"archiving")==1) {  
   # current folder, files, size, path
    my $foldakt = getParameterRead($dbh,$db1,"ArchivOrdner");
		my $foldstart = $foldakt;
    logit("Current folder is: $foldakt");
    my $files = getParameterRead($dbh,$db1,"ArchivDateien");
    my $size = getParameterRead($dbh,$db1,"ArchivMByte")*1024;
    my $killinput = getParameterRead($dbh,$db1,"ArchivingDeleteInput");
    my ($fakt,$sakt); # hold the number of files and the size
    # now extract the additional conditions
    my $sqladd = getParameterRead($dbh,$db1,"ArchivSQL");
    $sqladd =~ s/(^\s*)(.*?)(\s*$)/$2/;
    # we only want the not archived and those who have pages
    my $sql="select Laufnummer,Seiten,Ordner,ArchivArt " .
            "from $db1.archiv " .
            "where Archiviert=0 and Erfasst=1 and Seiten>0 ";
    $sql .= "and ($sqladd) " if $sqladd ne "";
    my $res = $dbh->selectall_arrayref($sql);
    archivingCheckDirs($db1); # check for existing folders
		foreach my $res1 (@$res) {
		  my $doc = $$res1[0];
			my $pag = $$res1[1];
			my $fold = $$res1[2];
			my $art = $$res1[3];
      if ( $doc > 0 ) {
        # we only process documents if > 0 and if current doc is unlocked
        my $error=archivingDocument($dbh,$db1,$doc,$pag,$art,$files,$size,
                                  \$fakt,\$sakt,\$foldakt,$killinput);
			}
    }
    # update the folder pointer to the current position
    $sql = "update $db1.parameter set Inhalt=$foldakt where " .
           "Name='ArchivOrdner' and Art='parameter' and Tabelle='parameter'";
    $dbh->do($sql);
	  my $splittedfolders = getParameterRead($dbh,$db1,"ArchivExtended");
		if ($splittedfolders > 0) {
		  my $cmd = "/usr/bin/perl /home/cvs/archivista/jobs/splitTableImages.pl";
		  logit("$cmd $db1 $splittedfolders $foldstart");
		  my $res = system("$cmd $db1 $splittedfolders $foldstart");
		}
    dumpKeyInfos($dbh,$db1);
    burnCD($dbh,$db1) if -e "/etc/wodim.conf"; # only burn CD/DVD if configured
    jobStop(10,"archiving");
  } else {
    logit("Another job is running, please wait for the end or stop it!");
  }
  logit("Ending archiving process in $db1");
}




=head2 dumpKeyInfos

Dumps the Infos of a Folder into the ARCH00XX Folder.

=cut

sub dumpKeyInfos {
  my ($dbh,$db) = @_;
  my $mysqldump = "/usr/opt/mysql/bin/mysqldump";
  my $table = "archiv";
  my $user = $val{user};
  my $pw   = $val{pw};
  my $folder = "/home/data/archivista/images/$db/output/";
  my $last_folder = getParameterRead($dbh,$db,"ArchivOrdner");
  # Remove one from the last folder because the last isn't finish yet
  $last_folder -= 1;
  for (my $c=$last_folder;$c>0;$c--) {
    my $folder_nr   = "ARCH".sprintf("%04d",$c);
    my $folder_name = $folder.$folder_nr;
    last if !-e $folder_name;
    my $outfile = $folder_name."/".lc($folder_nr).".sql";
    if (!-e $outfile) {
      my $cmd="$mysqldump -u$user -p$pw -w \"ordner=$c\" $db $table >$outfile";
      system($cmd);
    }
  }
}






=head2 burnCD

=cut

sub burnCD {
  my ($dbh,$db) = @_;
  my $folder = "/home/data/archivista/images/$db/output/";
  my $first_folder_nr = _getFirstFolder($folder);
  my $last_folder_nr = getParameterRead($dbh,$db,"ArchivOrdner");
  # The last Folder that we got from Parameter is not yet finish.
  # So we take one less.
  $last_folder_nr -= 1;
  if($first_folder_nr) {
    if ($last_folder_nr <= $first_folder_nr) {
      logit("The Images are not ready to be burned on CD/DVD.");
    } else {
      my $size = 0;
      my $last = 0;
      my $maxSize = getParameterRead($dbh,$db,"ArchivMByte");
      # We need bytes so convert it to bytes
      $maxSize = $maxSize*1024*1024;
      my $folder_nr;
      for ($folder_nr = $first_folder_nr;
           $folder_nr < $last_folder_nr;
           $folder_nr++) {
        my $work_folder = $folder."ARCH".sprintf("%04d",$folder_nr);
        $size += _sizeOfDir($work_folder);
        if($size >= $maxSize) {
          # Remove one because we don't want to be more than the maxSize
          $folder_nr -= 1;
          $last = 1;
        }
        last if $last == 1;
      }
      my $cmd;
      $cmd ="/home/archivista/wodim.sh $db $first_folder_nr"."-"."$folder_nr";
      logit("$cmd");
      my $ret = system($cmd);
      logit("CD/DVD burning ended with code $ret");
      if($ret == 0) {
        logit("CD/DVD was successfully. Now move folder(s)");
        my $exported = "/home/data/archivista/images/$db/export/";
        if(!-e $exported ) {
          my $cmd = "mkdir $exported";
          system($cmd);
        }
        my $start = $first_folder_nr;
        my $end = $folder_nr;
        for (my $c=$start;$c<=$end;$c++) {
          my $folder_name = "ARCH".sprintf("%04d",$c);
          my $from_folder = $folder.$folder_name;
          my $to_folder =  $exported.$folder_name;
          move($from_folder,$to_folder);
          logit("Move folder from $from_folder to $to_folder");
        }
      }
    }
  }
}







# get the folder number (not with 000X but with X)

sub _getFirstFolder {
  my $folder = shift;
  my $output;
  opendir(DIR,$folder);
  my @folders = readdir(DIR);
  closedir(DIR);
  foreach my $f (@folders) {
    next if $f =~ /^\./;
    # get the number of ARCH00X;
    my $nr = int substr($f,4,4);
    $output = $nr if $nr < $output;
    # Set output if we havent defined it
    $output = $nr if not defined($output);
  }
  return $output;
}






# calculate the size of a directory

sub _sizeOfDir {
  my $folder = shift;
  opendir(DIR,$folder);
  my @files = readdir(DIR); 
  closedir(DIR);
  my $size = 0;
  my @stats = stat($folder);
  # Add Folder Size
  $size += $stats[7];
  foreach my $file (@files) {
    next if $file =~ /^\./;
    my $work_file = $folder."/".$file;
    if(-d $work_file) {
      $size += _sizeOfDir($work_file);
    } else {
      my @stats = stat($work_file);
      $size += $stats[7];
    }
  }
  return $size;
}






=head2 $cancel=jobCheckStop($wait,$mess)

Checks if a running job should be stopped

=cut

sub jobCheckStop {
  my ($wait,$mess) = @_;
  my $pf = $val{jobpf};
  my $wr = $val{jobwr};
  my $st = $val{jobst};
  my $en = $val{joben};
  my $cancel = 0;
  if (-e "$pf$wr" && -e "$pf$st") {
	  $wait = 10 if $wait>60;
		$wait = 10 if $wait<1;
	  sleep $wait;
    open(FOUT,">$pf$en");
    my $ms = TimeStamp() . " stop: $mess\n";
    print FOUT $ms;
    close(FOUT);
    $cancel=1;
  }
  return $cancel;  
}






=head jobCheckInit

Check if the ocr job is running, give a time to wait, but after it close it

=cut

sub jobCheckInit {
  my ($mess) = @_;
  my $pf = $val{jobpf};
  my $wr = $val{jobwr};
  my $st = $val{jobst};
	my $file1 = "$pf$wr";
	my $file2 = "$pf$st";
	if (-e $file1) {
	  $mess = "init" if $mess eq "";
	  writeFile($file2,\$mess);
    jobCheckStop(60,"Initialize $0 now, ocr seems to hang");
		jobStop(10,"now stop it");
	}
}






=head2 $ok=jobStop($wait,$jmess)

Tries to stop a job

=cut

sub jobStop {
  my ($wait,$mess) = @_;
	$wait = 10 if $wait>60;
	$wait = 10 if $wait<1;
	sleep $wait;
	$mess = "job stopped" if $mess == "";
	logit("$mess");
  my $pf = $val{jobpf};
  my $wr = $val{jobwr};
  my $st = $val{jobst};
  my $en = $val{joben};
  # stop a job
  unlink "$pf$wr" if (-e "$pf$wr");
  unlink "$pf$en" if (-e "$pf$en");
  unlink "$pf$st" if (-e "$pf$st");
  return 1;
}






=head2 $ok=jobStart($wait,$mess)

Checks if a job is running (OCR or archiving)

=cut

sub jobStart {
  my ($wait,$mess) = @_;
  my $pf = $val{jobpf};
  my $wr = $val{jobwr};
  my $ok = 0;
  # start job action 
  for(my $c=0;$c<=$wait;$c++) {
    if (!-e "$pf$wr") {
      open(FOUT,">$pf$wr");
      my $ms = TimeStamp() . " start: $mess\n";
      print FOUT $ms;
      close(FOUT);
      $c = $wait;
      $ok = 1;
    }
    sleep 1;
  }
  return $ok;
}






=head2 $ver=checkDatabase($dbh,$dbname,$log)

Does a check if it is an archivista database (and logs it if wished)
(gives back the version)

=cut

sub checkDatabase {
  my $dbh = shift; # db handler
  my $db1 = shift; # database name
  my $log = shift; # log (1=yes,0=no)
  my ($message,$sql,@res);
	$sql = "show tables from $db1";
	my $ptab = $dbh->selectall_arrayref($sql);
	foreach (@$ptab) {
	  my @row = @{$_};
		if ($row[0] eq "parameter") {
      $sql = "select Inhalt from $db1.parameter where Name like 'AVVersion%'";
      @res = $dbh->selectrow_array($sql);
      if ($res[0]>= $val{avversion}) {
        $message = "Archivista database found";
			}
		}
  }
  $message = "Sorry, $db1 is not an archivista database" if $message eq "";
  return $res[0];
}






=head2 $pav=getValidDatabases($dbh)

Gives back a list of all archivista databases

=cut

sub getValidDatabases {
  my $dbh = shift; # db handler
  my $sql = "show databases";
  my ($pdbs,@av);
  $pdbs = $dbh->selectall_arrayref($sql);
  foreach (@$pdbs) {
    my $db = $$_[0];
    push @av,$db if (checkDatabase($dbh,$db)>=$val{avversion});
  }
  return \@av;
}






=head2 $psel=chooseXValues($pvals,$text)

Uses Xdialog to get a selection of a list

=cut

sub chooseXValues {
  my $pvals = shift;
  my $text = shift;
  my $args = "";
  for my $db (@$pvals) {
    # compose all values
    my $tag   = "'" . $db . "'";
    my $item  = "''";
    my $value = "'" . "0" . "'";
    $args .= " $tag $item $value";
  }
  # special handling of height so it shoes correct
  my $height = ( @$pvals - 1 ) * 2 + 7;
  $height = 11 if $height==7;
  # compose Xdialog construc
  my $cmd = qq(Xdialog --stdout --checklist "$text" ) .
            qq("$height" "30" "$height" $args);
  # get back all select entries
  my $RC = `$cmd`;
  my @lines = split "\n", $RC;
  my @selection = split "/", $lines[0];
  # return the values as a pointer of an array
  return \@selection;
}






=head2 restartOCRbatch($db,$range) 

Restart the OCR batch for some documents again

=cut

sub restartOCRbatch {
  my ($db1,$range,$host,$user,$pw) = @_;
  my $dbh=MySQLOpen();
  if ($dbh) {
    if (HostIsSlave($dbh)==0) {
      # first, we need all Archivista databases
      my $host1 = $dbh->quote($host);
      my $user1 = $dbh->quote($user);
      my $db2 = $dbh->quote($db1);
      my $pw1 = $dbh->quote($pw);
      my $dbh2 = MySQLOpen($host,$db1,$user,$pw);
      if ($dbh2) {
        if (HostIsSlaveSimple($dbh2)==0) {
          my $pdb = getValidDatabases($dbh2); 
          foreach (@$pdb) {
            if ($_ eq $db1) {
				      restartOCRbatch1($dbh,$db1,$range,$dbh2,$host1,$db2,$user1,$pw1);
				    }
			    }
        } else {
          logit("No ocr in slave mode at $host and $db1");
        }
        $dbh2->disconnect();
			} else {
        logit("Restart of ocr batch failed -- no connection at $host in $db1");
			}
		} else {
      logit("No ocr in slave mode at current box");
		}
    logit("End activate ocr batch again in $db1");
	  $dbh->disconnect();
  } else {
    logit("Restart of ocr batch failed -- no connection at current box");
	}
}






=head1 restartOCRbatch1($dbh,$db1,$range,$dbh2,$host1,$db2,$user1,$pw1)

Restart all ocr jobs in one database

=cut

sub restartOCRbatch1 {
  my ($dbh,$db1,$range,$dbh2,$host1,$db2,$user1,$pw1) = @_;
  my ($sql,@row);
  logit("Start activate ocr batch again in $db1");
  my $archivfolders = ""; # check if we have extended tables
	$archivfolders = getBlockTableCheck($dbh,$archivfolders,$db1);
	my $maxfiles = 10000;
	my $curfiles = 0;
  # get back the range of document (or nothing if all docs.
  my ($sqladd,$aakt,$amax) = getSQLrange($range);
  # we want to reprocess documents again
  $sql="select min(Laufnummer), max(Laufnummer) " .
       "from $db1.archiv where Erfasst=1 and Seiten>0 $sqladd";
  ($aakt,$amax) = $dbh2->selectrow_array($sql);
  while ($aakt<=$amax) {
    # archive document after document
    my ($doc,$pag,$fold,$art)=getNextFreeDocument($dbh2,$db1,$aakt,0,$sqladd);
    if ($pag>0) {
		  $curfiles++;
			if ($curfiles<=$maxfiles) {
			  restartOCRbatchCheckTable($dbh,$db1,$dbh2,$doc,$archivfolders);
			}
      # only process documents that have pages
      $sql = "select ID,DONE,ERROR from logs where Laufnummer=$doc " .
             "and db=$db2 and host=$host1 and user=$user1"; # check db
      @row = $dbh->selectrow_array($sql);
      if ($row[0]==0) {
        # no log entry found
        $sql = "insert into logs set " .
               "host=$host1,db=$db2,user=$user1,pwd=$pw1," .
               "type='sne',Laufnummer=$doc,DONE=".LOG_DONE.
               ",pages=$pag";
        $dbh->do($sql);
      } else {
        # there was a log entry found
        my $done=$row[1];
        my $err=$row[2];
        if (($done==LOG_DONE || $done==LOG_AXISDONE ||
             $done==LOG_OCRDONE) && $err==0) {
          $sql="update logs set DONE=".LOG_DONE." where ID=$row[0]";
          $dbh->do($sql);
        }
      }
      $aakt = $doc;
    } else {
      $aakt = $amax if $doc == 0; # no doc was found, stop process
    }
    $aakt++; # go to the next document
  }
}



sub restartOCRbatchCheckTable {
  my ($dbh,$db1,$dbh2,$doc,$archivfolders) = @_;
	if ($archivfolders>0) {
	  my $sql = "select Akte,Archiviert,Ordner,Seiten from $db1.archiv where ".
	            "Laufnummer = $doc";
	  my ($lnr,$archiviert,$folder,$seiten) = $dbh2->selectrow_array($sql);
		my $table = "archivbilder";
		my $tablego = getBlobTable($dbh2,$folder,$archiviert,$table,$archivfolders);
		if ($tablego ne $table && $doc == $lnr) {
		  for (my $c=1;$c<=$seiten;$c++) {
			   my $nr = ($doc*1000)+$c;
			   $sql = "select Seite from $db1,archivbilder where Seite=$nr";
				 my ($res) = $dbh2->selectrow_array($sql);
				 if ($res==0) {
				   $sql = "insert into $db1.archivbilder ".
					        "(Seite,Bild,BildA,BildInput,Quelle) ".
					        "select Seite,Bild,BildA,BildInput,Quelle ".
									"from $tablego where Seite=$nr";
					 logit("insert temp image $nr to $db1.archivbilder");
					 $dbh2->do($sql);
				 }
			}
		}
	}
}






=head2 ($sql,$start,$ende)=getSQLrange($range)

Gives back an sql fragment either 'and Laufnummer=x' or
'and Laufnummer between x and y' and start/end document

=cut

sub getSQLrange {
  my $val = shift;
  my ($sql,$x,$y,$start,$ende);
  # check if we only have one document or several documents
  $val=~/^(\d+)(-*)(\d*)/;
  $x=$1;
  $y=$3;
  if ($y != ''){
	  if ($y>0 && $y>$x) {
      $sql = "and Laufnummer between $x and $y ";
		} else {
		  $sql = "and Laufnummer=$x ";
		}
  } else {
    $sql = "and Laufnummer=$x " if ($x>0);
  }
  $start=$x if $x>0;
  $ende=$x if $x>0;
  $ende=$y if $y>0;
  return ($sql,$start,$ende); 
}






=head2 getFileExtensions

Return the extension of a file or in other words the filetype.

=cut

sub getFileExtension {
  my $fn=shift;
  my @sections=split(/\./,$fn);
  return $sections[$#sections];
}






=head2 get_rotation($obj)

This method calculates the rotation of the image with respect to the scanmode.

=cut

sub rotateADF {
  my $obj = shift;
  my $factor=0;
  $factor=3 if ($obj->adf==-2) && (($obj->pages & 1));
  $factor=1 if ($obj->adf==-2) && (!($obj->pages & 1));
  my $angle=$factor*90;
  return $angle%360;
}






=head2 rotate

Rotates the incomming picture with respect of its type.
This method returns the orientation of the document:

0=portrait
1=landscape

=cut

sub rotate {
  my $obj = shift;
  my $image = shift;
  my $rotation=rotateADF($obj);
	$rotation = (($rotation + ($obj->rotate)) % 360);
	$rotation = (($rotation + $obj->rotate2) % 360);
  return 0 if (!$rotation);
  # We want to rotate our picture because the scanner gives it reversed
  # if we have a 90� Rotation we need to make it 270 and vice versa
  my $rotation1 = $rotation;
  if ($rotation==90) {
    $rotation1=270;
  } elsif ($rotation==270) {
    $rotation1=90;
  } 
  ExactImage::imageRotate($image,$rotation1);
}






=head1 checkSplitDoc($obj)

Check if we need to open a new document

=cut

sub checkSplitDoc {
  my ($obj,$image) = @_;
  if ($obj->newdocpages>0 && $obj->pages>=$obj->newdocpages) {
	  saveDoc($obj); # close the current doc
		my $oldnr = $obj->doc;
		$obj->doc(0);
		checkNewDoc($obj);
    copyValues($obj->dbh2,$obj->database,$obj->fields,$oldnr,$obj->doc);
	}
}






=head1 copyValues($dbh,$pfields,$lold,$lnew)

Copy the fields from one document to another

=cut

sub copyValues {
  my ($dbh,$db1,$pfields,$lold,$lnew) = @_;
  return if $lold==0;
  my $sql=""; # now get all field values from the old document
  my (@flds,@typ);
  foreach(@$pfields) {
    my $f1 = $_->{name};
    last if $f1 eq "Laufnummer"; # stop for field Notes
    my $t1 = $_->{type};
    # don't update Document, Datum and Pages
    if ($f1 ne "Akte" && $f1 ne "Datum" &&
		    $f1 ne "Seiten" && $f1 ne "Gesperrt") {
      $sql .= "," if $sql ne "";
      $sql .= $f1;
      push @flds,$f1;
      push @typ,$t1;
    }  
  }
  $sql = "select $sql from $db1.archiv where Laufnummer=$lold";
  my @row = $dbh->selectrow_array($sql);
  $sql=""; # now update the old values to the new document
  my $c=0;
  foreach(@row) {
    my $v = $_;
    my $dont = 0;
    if ($typ[$c] eq "varchar" or $typ[$c] eq "datetime") {
      $v = $dbh->quote($v);
    } else {
      $dont=1 if $v eq "";
    }
    if ($dont==0) {
      $sql .= "," if $sql ne "";
      $sql .= $flds[$c]."=".$v;
    }
    $c++;
  }
  if ($sql ne "") {
    $sql = "update $db1.archiv set $sql where Laufnummer=$lnew";
		logit($sql);
    $dbh->do($sql);
  }
}






=head1 MainAccessLog()

Check if we need to log the the actions

=cut

sub MainAccessLog {
  my ($dbh,$db1,$dbh2,$doc,$page,$action,$user,$host) = @_;
  return if $dbh2==0 or $dbh==0;
  my $dbhgo = $dbh2;
  $dbhgo = $dbh if $host eq "localhost";
  if (getParameterRead($dbh2,$db1,"ACCESS_LOG")) {
    my $string = "page=$page;";
    if ($action eq "add_page") {
      my $pagedoc = ($doc*1000)+$page;
      my $sql = "select BildInput from $db1.archivbilder where Seite=$pagedoc";
      my @row = $dbh2->selectrow_array($sql);
      my $imagehash = md5_hex $row[0];
      $string .= "imagehash=$imagehash;";
      $sql = "select UserModDatum,UserModName from $db1.archiv ".
			       "where Laufnummer=$doc";
      @row = $dbh2->selectrow_array($sql);
      $string .= "moddate=$row[0];moduser=$row[1];";
    }
    my $sql = "host=".$dbh->quote($val{host});
    $sql .= ",db=".$dbh->quote($db1);
    $sql .= ",user=".$dbh->quote($user);
    $sql .= ",document=".$doc;
    $sql .= ",action=".$dbh->quote($action);
    $sql .= ",additional=".$dbh->quote($string);
    $sql = "insert into access set $sql";
    $dbhgo->do($sql);
    $sql = "select LAST_INSERT_ID()";
    my @row = $dbhgo->selectrow_array($sql);
    my $id = $row[0];
    my $id2 = $id-1;
    my $hash = "";
    if ($id2>0) {
      my $sql2 = "select hash from access where id=$id2";
      @row = $dbhgo->selectrow_array($sql);
      $hash = $row[0];
    }
    $string = "$sql$hash";
    $hash = md5_hex $string;
    $sql = "update access set hash=".$dbh->quote($hash)." ".
           "where id=$id";
    $dbhgo->do($sql);
  }
}






=head1 emptypath($path)

remove $path and create it again

=cut

sub emptypath {
  my $path = shift;
  if (-d $path) {
    system("rm -Rf $path");
    print "$path killed\n";
  }
  system("mkdir $path");
}






=head1 sqlrange($range)

gives back an sql fragment either 'and Laufnummer=x' or
'and Laufnummer between x and y'

=cut

sub sqlrange {
  my $val = shift;
  my ($sql,$x,$y);
  # check if we only have one document or several documents
  $val=~/^(\d+)(-*)(\d*)/;
  $x=$1;
  $y=$3;
  if ($y != ''){
	  if ($y>0 && $y>$x) {
      $sql = "and Laufnummer between $x and $y";
		} else {
		  $sql = "and Laufnummer=$x";
		}
  } else {
    $sql = "and Laufnummer=$x" if ($x>0);
  }
  return $sql; 
}






=head1 $d=DocumentAddDatGerman($d)

Format a date ('dd.mm.yyyy'')

=cut

sub DocumentAddDatGerman {
  my $d=shift;
  $d=substr($d,8,2).".".substr($d,5,2).".".substr($d,0,4);
  return $d;
}






=head1 $d=DocumentAddDatSQL($d)

German date to SQL ('yyyy-mm-dd 00:00:00')

=cut

sub DocumentAddDatSQL {
  my $d=shift;
  $d= "'".substr($d,6,4)."-".substr($d,3,2)."-".substr($d,0,2)." 00:00:00'";
  return $d;
}






=head1 exportformatvalue($val,$typ)

does format a mysql field value to the archivista export format

=cut

sub exportformatvalue {
  my $val = shift;
  my $typ = shift;
  my $t="";
  if ($val ne "") {
    if ($typ eq "varchar" or $typ eq "text") {
      $t=$val;
    } elsif ($typ eq "int") {
      $t=$val;
    } elsif ($typ eq "tinyint") {
      if ($val==0) {
        $t="Nein";
      } else {
        $t="Ja";
      }
    } elsif ($typ eq "double") {
      $t=$val;
    } elsif ($typ eq "datetime") {
      $t=DocumentAddDatGerman($val);
    }
  }
  $t.="\t";
  return $t;
}






=head1 importformatvalue ($dbh,$bisher,$val,$feld,$typ,$size)

does format a mysql field value to the archivista export format

=cut

sub importformatvalue {
  my ($dbh,$bisher,$val,$feld,$typ,$size) = @_;
  my $t="";
  if ($val ne "") {
    if ($typ eq "varchar") {
      if (length($val)>$size) {
        $val = substr $val, 0, $size-1;
      }   
      $t=$dbh->quote($val);
    } elsif ($typ eq "text") {
      $t=$dbh->quote($val);
    } elsif ($typ eq "int") {
      $t=int $val;
    } elsif ($typ eq "tinyint") {
      if ($val eq "Ja") {
        $t=1
      } else {
        $t=0
      }
    } elsif ($typ eq "double") {
      $t=$val;
    } elsif ($typ eq "datetime") {
      $t=DocumentAddDatSQL($val);
    }
    if ($t ne "") {
      $t="$feld=$t";
      if ($bisher ne "") {
        $t=", ".$t;
      }
    }
  }
  return $t;
}






=head1 addLogEntryImport($dbh,$host,$db,$user,$pw,$akte,$seiten)

Add a log entry from import

=cut

sub addLogEntryImport {
  my ($dbh,$host,$db,$user,$pw,$akte,$seite,$mod,$formrec,$old,$done) = @_;
	$formrec=0 if $formrec eq '';
	$done=0 if $done eq '';
	$done=0 if $done != 4;
	my $pw1 = $pw;
	$pw1 = "" if $host eq "localhost";
	if ($old) {
	  my $sql = "delete from archivista.logs where Laufnummer=$akte and ".
		          "host=".$dbh->quote($host)." and db=".$dbh->quote($db)." and ".
						  "DONE=".LOG_DONE." and ERROR=0";
		$dbh->do($sql);
	}
  my $sql="insert into archivista.logs set ".
	        "host=".$dbh->quote($host).",".
	        "db=".$dbh->quote($db).",".
	        "user=".$dbh->quote($user).",".
	        "pwd=".$dbh->quote($pw1).",".
	        "Laufnummer=$akte,".
					"idstart=$akte,".
					"formrec=$formrec,".
					"pages=$seite,".
					"DONE=$done,ERROR=0,TYPE='$mod'";
	$dbh->do($sql);
}






=head1 $string=findit($id)

Get back a string (given an id), lang comes from global var

=cut

sub findit {
  my $id = shift;
	my $lang = shift;
	my $cmd = ". /home/archivista/strings.in;";
	$cmd .= "findit '$id' $lang";
	my $cmd1 = `$cmd`;
	chomp $cmd1;
	return $cmd1;
}
	





=head1 $lang=lang()

Give back the language id (en/de)

=cut

sub getLang {
	my $cmd = ". /home/archivista/strings.in;";
	$cmd .= "get_keyboard";
	return `$cmd`;
}






=head1 $val=escape($val)

Quote special chars in value parts (axis/xerox/autofields)

=cut

sub escape {
  my $str = shift;
  $str =~ s/([^a-zA-Z0-9_.-])/sprintf("%%%02x", ord($1))/ge;
	return $str;
}






=head1 $val=unescape($val)

Unquote special chars in value parts (axis/xerox/autofields)

=cut

sub unescape {
  my $str = shift;
  $str =~ tr/+/ /;
	$str =~ s/\\$//;
  $str =~ s/%([0-9a-fA-Z]{2})/pack("c",hex($1))/eg;
  $str =~ s/\r?\n/\n/g;
	return $str;
}






=head1 ($key,$value)=keyvalue($line,$seperator)

Separates at the first seperator to key and value.

=cut

sub keyvalue {
  my $line = shift;
	my $seperator = shift;
  my @vals = split( $seperator, $line );
	my $key = shift @vals;
	my $value = join($seperator,@vals);
	return ($key,$value);
}






=head1 $pblob=getBlobFile($dbh,$fld,$page,$ordner,$arch,$tbl,$archfolders)

Give back a file from the blob table archivbilder or archimg...

=cut

sub getBlobFile {
  my $dbh = shift;
  my $field = shift;
	my $page = shift;
	my $ordner = shift;
	my $archiviert = shift;
	my $table = shift;
	my $archivfolders = shift;
	$table = getBlobTable($dbh,$ordner,$archiviert,$table,$archivfolders);
  my $sql = "select $field from $table where Seite=$page";
  my @row = $dbh->selectrow_array($sql);
  return \$row[0];
}






=head1 $pblob=getBlobTable($dbh,$ordner,$arch,$tbl,$archfolders)

Give back the correct table name for blob table archivbilder

=cut

sub getBlobTable {
  my $dbh = shift;
	my $ordner = shift;
	my $archiviert = shift;
	my $table = shift;
	my $archivfolders = shift;
	$table = "archivbilder" if $table ne "archivseiten";
	$archivfolders = getBlockTableCheck($dbh,$archivfolders);
	if ($archiviert==1 && $archivfolders>0 && $table eq "archivbilder") {
	  my $nr = int(($ordner-1)/$archivfolders);
		$nr = $nr * $archivfolders;
		$table = "archimg".sprintf("%05d",$nr);
	}
	return $table;
}






=head archivfilders = getBlockTableCheck($dbh,$archivfolders,$db1)

Check if we have extended tables or not

=cut

sub getBlockTableCheck {
  my ($dbh,$archivfolders,$db1) = @_;
	if ($archivfolders eq "") {
	  $db1 .= "." if $db1 ne "";
    my $sql = "select Inhalt from ".$db1."parameter where Art = " .
           "'parameter' AND Name='ArchivExtended'";
    my @row = $dbh->selectrow_array($sql);
		$archivfolders = $row[0];
	}
	return $archivfolders;
}






=head2 createThumbsAndSave($dbh,$db1,$dbh2,$img,$depth,$nr,$page,$sd,$od)

Create thumbnails from the original images

=cut

sub createThumbsAndSave {
  my $dbh    = shift;
  my $db1    = shift;
  my $dbh2   = shift;
  my $image  = shift;
  my $depth  = shift;
  my $nr     = shift;
  my $page   = shift;
  my $scanid = shift;
  my $depthold = shift;
  my $seite = $nr * 1000 + $page;
  if ($depth != $depthold) {
    imageReadAndSave($dbh2,$db1,$image,"BildInput",$depth,$seite);
  }
  my $fact=getBoxParameterRead($dbh,$db1,"PrevScaling",0,100,20);
  $fact=10 if $fact<10 && $fact !=0;
  if ($fact>0) {
    my $fact1 = $fact/100;
		my $width = ExactImage::imageWidth($image);
		my $height = ExactImage::imageHeight($image);
		if ($width>1024 && $height>786) {
      if ($depth==1) {
        ExactImage::imageBilinearScale($image,$fact1);
      } else {
        ExactImage::imageScale($image,$fact1);
      }
      imageReadAndSave($dbh2,$db1,$image,"Bild",$depth,$seite);
		} else {
		  logit("no screen copy (under 1024x768)");
		}
  }
  updateArchivTable($dbh2,$db1,$nr,$seite,$depth,$scanid);
}






=head1 updateArchivTable($dbh2,$db1,$nr,$seite,$depth,$scanid)

Update the archiv table to the current values

=cut

sub updateArchivTable {
  my $dbh2 = shift;
  my $db1 = shift;
  my $nr = shift;
  my $seite = shift;
  my $depth = shift;
  my $scanid = shift;
  my $ext1="TIF";
  my $ext2="PNG";
  my $archivart=1;
  if ($depth>1) {
    $ext1="JPG";
    $ext2="JPG";
    $archivart=3;
  }
  my $sql = "update $db1.archiv set BildInputExt='$ext1',BildAExt='$ext2', " .
         "Erfasst=1,ArchivArt=$archivart where Laufnummer=$nr";
  $dbh2->do($sql);
  if ($scanid ne "") {
    # add the page to the archivseiten table
    my @scan = split(";",$scanid);
    my $ocr = $scan[10];
    my $erf = 0;
    my $excl = 0;
    $ocr=0 if ($ocr <0);
    if ($ocr==26) {
      $erf = 1;
      $excl = 0;
    } elsif ($ocr==27) {
      $erf = 0;
      $excl = 1;
    }
    $ocr=0 if ($ocr >20);
    $sql = "insert into $db1.archivseiten set Seite=$seite, " .
           "OCR=$ocr,Erfasst=$erf,Ausschliessen=$excl";
    $dbh2->do($sql);
  }
}






=head2 imageReadAndSave($dbh,$db1,$image,$feld,$depth)

Save an image to the archivbilder table

=cut

sub imageReadAndSave {
  my $dbh = shift;
  my $db1 = shift;
  my $image = shift; # The ExactImage image object
  my $feld = shift;
  my $depth = shift;
  my $seite = shift;
  my $image1 = "";
  my $sql1 = "update $db1.archivbilder set ";
  my $sql2 = " where Seite=$seite";
  my $w = ExactImage::imageWidth($image);
  my $h = ExactImage::imageHeight($image);
  if ($depth == 1) {
    $image1 = ExactImage::encodeImage($image,"tiff");
  } else {
    my $fact=getBoxParameterRead($dbh,$db1,"JpegQuality",10,100,33);
    $image1 = ExactImage::encodeImage($image,"jpeg",$fact);
  }
  $image1 = $dbh->quote($image1);
  my $sql = "$sql1 $feld=$image1";
  my $name = "Bild";
  $name .= "A" if $feld eq "BildInput";
  my $namex = $name."X";
  my $namey = $name."Y";
  $sql .= ",$namex=$w,$namey=$h" if $w>0 && $h>0;
  $sql .= $sql2;
  eval( $dbh->do($sql));
}






=head1 ($host,$db,$user,$pw)=getConnectionValues()

Give back the connection information

=cut

sub getConnectionValues {
  return ($val{host},$val{db},$val{user},$val{pw});
}






=head1 $res=OpenOfficeConvert($fin1,$path,$base1)

Create a pdf file from openoffice file and give back res (0=not,1=ok)

=cut

sub OpenOfficeConvert {
  my ($fin1,$path,$base1,$stage) = @_;
  my $fin1q = qq{'$fin1'};
  my $fin2 = "$path$base1\.pdf";
  my $prof = '. /etc/profile'; # import default settings
  my $disp = 'export DISPLAY=:0'; # export display to default
	my $pfad = "/opt/openoffice.org3/program";
	my $opt = "-nofirststartwizard -invisible";
	if (check64bit()==64) {
	  $pfad = "/usr/bin" if check64bit()==64;
		$opt = "-nologo";
	}
  my $prg = qq(/bin/su - archivista -c "$prof; $disp;)." ".
	          "$pfad/soffice $opt ".
			  	  qq{macro:///Standard.MyConversions.SaveAsPDF\\\(};
  my $prg1 = $prg.$fin1q.'\) "';
	my $res = 0;
	$res = system($prg1);
	if (!-e "$fin2" && $stage==0) {
    my $fin1a = "$path$base1\.txt";
    my $fin1q = qq{'$fin1a'};
    unlink $fin1a if -e $fin1a;
    $res=move($fin1,$fin1a) if !-e $fin1a;
    if ($res==1) {
      $fin1 = $fin1a;
      $prg1 = $prg.$fin1q.'\) "';
	    $res = system($prg1);
    } else {
		  $res=-1;
	  }
	}
	return ($res,$fin1,$fin2);
}






=head1 ($fin1,$path,$base1)=CheckFileNamePathBase($fnew)

Give back a new file name, the path and the base

=cut

sub CheckFileNamePathBase {
  my ($fnew) = @_;
  my $path = $val{tmpdir};
	my @parts = split(/\./,$fnew);
	my $ext = pop @parts;
	my $base = join("\.",@parts);
	$base = "document" if $base eq "";
	my $base1 = $base;
	$ext = "txt" if $base eq "";
	$ext = "txt" if $ext eq "";
	my $fin1 = "$path$base\.$ext";
	for (my $c=0;$c<10;$c++) {
	  if (-e $fin1) {
	    $base1 = "$base-$c";
		  $fin1 = "$path$base1\.$ext";
			sleep 1;
		} else {
		  last;
		}
	}
	return ($fin1,$path,$base1);
}






=head1 $val=selectValue($dbh,$jobid,$attr)

Give back a volue from job_data table

=cut

sub selectValue {
  my ($dbh,$jobid,$attr) = @_;
	my $attr1 = $dbh->quote($attr);
  my $sql = "select value from jobs_data " .
            "where jid=$jobid and param=$attr1 limit 1";
  my @f = $dbh->selectrow_array($sql);
  # store the actual scan definition
	return $f[0];
}






=head1 $langs = OCRDoOpenSourceLang($dbh,$db1,$dbh2,$ocr,$nr)

Get the current language(s) string

=cut

sub OCRDoOpenSourceLang {
  my $dbh = shift;
  my $db1 = shift;
	my $dbh2 = shift;
	my $ocr = shift;
	my $onr = shift;
	
  my $sql = "select Inhalt from $db1.parameter where Name = 'OCRSets'";
	my @row = $dbh2->selectrow_array($sql);
	my $ocr1 = $row[0];
	my $langs = "";
	if ($ocr1 ne "") {
		my @defs = split(/\r\n/,$ocr1);
		my $found = 0;
		my $c = 0;
		foreach (@defs) {
		  my $ocrdef = $_;
		  my @entries = split(";",$ocrdef);
			if ($entries[0] eq $ocr && $ocr ne "") {
			  $found=$c;
				last;
			}
			if ($ocr eq "" && $onr==$c) {
			  $found=$c;
				last;
			}
			$c++;
		}
		my @entries1 = split(";",$defs[$found]);
		for (my $c1=1;$c1<=5;$c1++) {
		  my $idx = $entries1[$c1];
			if ($idx>=0) {
			  my $id = 'OCRLANG_'.sprintf("%03d",$idx);
				$id = $dbh2->quote($id);
				$sql = "select en from archivista.languages where id=$id";
				my @langall = $dbh->selectrow_array($sql);
				if ($langall[0] ne "") {
				  $langs .= "," if $langs ne "";
					$langs .= $langall[0];
				}
			}
		}
	}
	return $langs;
}






=head2 $xrandr=getXRandr()

Give back if we have to fix intel graphic card

=cut

sub getXRandr {
  my ($profile_cmd,$display_cmd) = @_;
	my $xrandr = "";
  if (! -e "/tmp/xrandr.done") {
    my $card = `lspci`;
    $card =~ /(Display controller:)(\s)(.+?)(\s)/;
	  if ($1 eq "Display controller:" && $3 eq "Intel") {
		  my $randr = "/usr/X11/bin/xrandr";
		  logit("Intel card found");
		  my $cmd1 = "$profile_cmd; $display_cmd; $randr";
			my $res = `$cmd1`;
		  $res =~ /(VGA\sconnected)(\s)([0-9]+)(x)([0-9]+)(\+)(.*)/;
		  logit("Current resolution:$3--$5");
		  if ($1 eq "VGA connected" && $3>0 && $5>0 && $5>=768) {
	      my $x1=$3;
	      my $y1=$5;
				my $minimal = "1024x768";
				$minimal = "800x600" if $5==768;
        $xrandr = $cmd1." --size $minimal; $randr --size ".$x1."x".$y1.";";
        logit("$xrandr");
				system($xrandr);
	      system("touch /tmp/xrandr.done");
	    } else {
			  sleep 30;
			}
	  } else {
	    system("touch /tmp/xrandr.done");
	  }	
  }
	return $xrandr;
}






=head2 OCRDoOpenSource($fin,$fout,$lang,$doocr)

Do an ocr job with the open sourc ocr ocrad

=cut

sub OCRDoOpenSource {
  my $fin = shift;
	my $fout = shift;
	my $lang = shift;
	my $doocr = shift;
	my $dopdf = shift;
	my $pdfwhole = shift;
	my @fins = split(",",$fin);
	my @fouts = split(",",$fout);
	my $c=0;

	foreach (@fins) {
	  my $file = $_;
	  my $out = $file;
		my $base = "$val{frpath}$file";
		$base =~ s/(.*)(\.[a-z]{3,3})$/$1_files/;
		my $txt = $fouts[$c];
    my $image = ExactImage::newImage();
    if (ExactImage::decodeImageFile($image,"$val{frpath}$file")) {
		  my $bits = ExactImage::imageColorspace($image);
			if (check64bit()==64 && $doocr==3) {
		    $out =~ s/(.*)(\.[a-z]{3,3})$/$1.bmp/;
				if ($bits ne "gray1") {
          ExactImage::imageConvertColorspace($image,"gray1");
				}
			} else {
			  if ($bits ne "gray1") {
		       $out =~ s/(.*)(\.[a-z]{3,3})$/$1.tif/;
           ExactImage::imageConvertColorspace($image,"gray1");
			  }
			}
			ExactImage::encodeImageFile($image,"$val{frpath}$out");
			ExactImage::deleteImage($image);
			$file = $out if check64bit()==64 && $doocr==3; # need bmp file av64bit
			my $ord="";
			my $txt1 = $txt;
		  $txt1 =~ s/(.*)(\.[a-z]{3,3})$/$1/;
			if ($doocr==3) {
		    $ord = "export CF_DATADIR=/usr/share/cuneiform/;" if check64bit()==64;
				$ord = $ord."cuneiform ";
				my $lng1 = lc(substr($lang,0,3)) if length($lang)>3;
				$lng1 = "fra" if $lng1 eq "fre";
				$ord .= "-l $lng1 " if $lng1 ne "";
				if ($dopdf !=0) {
				  if (check64bit()==64) {
				    $ord .= "-f hocr ";
				  } else {
				    $ord .= "-f html ";
				  }
				}
		    $ord .= "$val{frpath}$out -o $val{frpath}$txt";
			} else {
			  $ord = "tesseract ";
				my $lng1 = "";
				my @lang1 = split(",",$lang);
				$lang = $lang1[0];
				if ($lang eq "German") {
				  $lng1 = "deu";
				} elsif ($lang eq "GermanNewSpelling") {
				  $lng1 = "deu-f";
				} elsif ($lang eq "French") {
				  $lng1 = "fra";
				} elsif ($lang eq "Italian") {
				  $lng1 = "ita";
				} elsif ($lang eq "Spanish") {
          $lng1 = "spa";
				} elsif ($lang eq "Dutch") {
          $lng1 = "nld";
				} else {
				  $lng1 = "eng";
				}
				$ord .= "$val{frpath}$out $val{frpath}$txt1";
				$ord .= " -l $lng1" if $lng1 ne "";
			}
			#logit("$ord");
		  system("$ord");

      my $txt3 = "";
			if ($doocr==3 && $dopdf==1) {
			  # if we have pdf enabled and are in cuneiform, so get pdf
			  my $txt2 = $txt.'.hocr';
				$txt3 = $txt.'.txt';
				unlink "$val{frpath}$txt2" if -e "$val{frpath}$txt2";
				move("$val{frpath}$txt","$val{frpath}$txt2");
			  my $cmd = "hocr2pdf -s -i $val{frpath}$file -t $val{frpath}$txt3 ".
				          "-o $val{frpath}$txt < $val{frpath}$txt2";
				#logit($cmd);
				system($cmd);
				unlink "$val{frpath}$txt2" if -e "$val{frpath}$txt2";
				system("rm -rf $base") if -d $base;
			}
		  unlink("$val{frpath}$out") if -e "$val{frpath}$out";
      my $cuneiutf = 0;
			$cuneiutf=1 if check64bit()==64 && $doocr==3;
			if ($doocr==2 || $cuneiutf==1) {
				my $tout3 = $txt;
				$tout3 = $txt3 if check64bit()==64 && $dopdf==1 && $doocr==3;
			  my $txt2 = $txt1.'_1.txt';
        $ord = "iconv -c -f utf8 -t iso-8859-1 " .
				       " $val{frpath}$tout3 -o $val{frpath}$txt2";
				system("$ord");
				#logit($ord);
				unlink "$val{frpath}$tout3" if -e "$val{frpath}$tout3";
				move("$val{frpath}$txt2","$val{frpath}$tout3");
			}
		}
		$c++;
	}
}






=head1 ($dopdf,$doocr,$pdfwholedoc,$osocr)=getOCRVals($dbh2,$db1)

Check for the user defined ocr/pdf parameters

=cut

sub getOCRVals {
  my $dbh2 = shift;
	my $db1 = shift;
  my $sql = "select Inhalt from $db1.parameter where Name = 'PDFFiles'";
  my @felder=$dbh2->selectrow_array($sql);
  my $dopdf=$felder[0];
	$dopdf=1 if $dopdf eq "";
 
  $sql = "select Inhalt from $db1.parameter where " .
         "Name = 'JobsOCRRecognition'";
  @felder=$dbh2->selectrow_array($sql);
  my $doocr=$felder[0];
	$doocr=1 if $doocr eq "";
 
  $sql = "select Inhalt from $db1.parameter where Name = 'PDFWHOLEDOC'";
  @felder=$dbh2->selectrow_array($sql);
  my $pdfwholedoc=$felder[0];
	$pdfwholedoc=1 if $pdfwholedoc eq "";
	# Activate Tesseract if ArchivistaOCR option is not available
	if (!-e '/home/archivista/.wine/drive_c/Programs/Av5e/avocr.exe') {
	  $doocr=3 if $doocr==1;
	}
  $sql = "select Inhalt from $db1.parameter where Name = 'OCRLIMIT01'";
	my ($vals) = $dbh2->selectrow_array($sql);
	my ($limit,$start,$end) = split(";",$vals);
	return ($dopdf,$doocr,$pdfwholedoc,$limit,$start,$end);
}






=head1 vers=check64bit 

Give back if we are under 32 or 64 bit

=cut

sub check64bit {
  my $vers = 32;
	my $linux = `cat /proc/version`;
	$vers=64 if $linux =~ /Debian/;
	return $vers;
}






=head1 MainUpdateText($fld,$val,%text) 

Store all fields we have right to save

=cut

sub MainUpdateText {
  my ($fld,$val,$ptext) = @_;
	my @parts = split("_",$fld);
  my $fld1 = pop @parts;
	$val = "NULL" if $val eq "";
	$$ptext{$fld1} = $val;
}






=head1 MainUpdateTextUpdate($dbh,$db1,$doc,$pages,$ptext)

Save the new values to page text table

=cut

sub MainUpdateTextUpdate {
  my ($dbh,$db1,$doc,$pages,$ptext,$kill) = @_;
	if ($pages>0) {
    my $seitennr = ($doc*1000)+1;
		my $sql = "select Text,Seite from $db1.archivseiten where Seite=$seitennr";
		my @row = $dbh->selectrow_array($sql);
		my $string = $row[0];
		my $seite = $row[1];
		my $insert = 0;
		$insert=1 if $seite==0;
		my $sep = "-" x 40;
		$sep = "\r\n".$sep."\r\n";
		my @parts = split($sep,$string);
		my $text = "";
		$text = pop @parts if $parts[1] ne "";
		if ($kill != 1) {
		  my @fields = split("\r\n",$text);
		  my %saved = ();
		  foreach my $line (@fields) {
        my @parts1 = split(": ",$line);
			  my $fld1 = shift @parts1;
			  my $val1 = join(": ",@parts1);
			  if (!exists $$ptext{$fld1}) {
			    $$ptext{$fld1} = $val1;
			  }
		  }
		  my $out = "";
		  foreach my $fld2 (keys %$ptext) {
		    $out .= "\r\n" if $out ne "";
			  $out .= "$fld2: ".$$ptext{$fld2};
		  }
		  push @parts,$out;
		}
		my $outtext = join($sep,@parts);
		$outtext = $sep . $outtext if $insert==1;
    $sql = "update $db1.archivseiten set ";
		$sql = "insert into $db1.archivseiten set Seite=$seitennr," if $insert==1;
		$sql .= "Text = ".$dbh->quote($outtext);
		$sql .= " where Seite=$seitennr" if $insert==0;
		$dbh->do($sql);
	}
}






=head1 $formated=getZeros($pages)

Give back the format string we need for pdftoppm (different 32/64 bit)

=cut

sub getZeros {
  my ($pages) = @_;
  my $zeros = 6;
	$zeros = "%0".$zeros."d";
  return $zeros;
}
=head1
	# version 3.02 of xpdf does not have the zero problem
	if (check64bit()==64) {
	  if ($pages<10) {
		  $zeros = 1;
		} elsif ($pages<100) {
		  $zeros = 2;
		} elsif ($pages<1000) {
		  $zeros = 3;
		} elsif ($pages<10000) {
      $zeros = 4;
		} elsif ($pages<100000) {
		  $zeros = 5;
		}
	}
=cut





# must be
1;

