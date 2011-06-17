#!/usr/bin/perl

=head1 sane-daemon.pl (c) 2.2.2007 by Archivista GmbH, Urs Pfister

This script a) checks the archivista jobs table for documents and b) is 
called from notify-daemon.pl (enotify). From the job table it does call 
scanadf (scan job), from enotify it takes a file name and does process it

=cut

use strict;
use Archivista::Config;    # is needed for the passwords and other settings
use DBI;

my $SLEEP = 1;             # Seconds we wait when no job was found

# DBI data for jobs table
my %val;
my $config = Archivista::Config->new;
$val{host} = $config->get("MYSQL_HOST");
$val{db} = $config->get("MYSQL_DB");
$val{user} = $config->get("MYSQL_UID");
$val{pw} = $config->get("MYSQL_PWD");
undef $config;

$val{log} = '/home/data/archivista/av.log';
$val{ds} = '/'; # directory separator (/ or \\)
$val{path} = "/tmp/scan";
$val{end} = "$val{path}$val{ds}jobend.txt";
$val{stop} = "$val{path}$val{ds}jobstop.txt";
$val{scanadf} = "/usr/bin/scanadf -o $val{path}/job%04d.img";
$val{jobid} = 0; # the id from the jobs table
$val{fname} = ""; # filename for non-SANE jobs
$val{dbh} = undef; # database for logs and jobs tables
$val{sane} = "/usr/bin/perl /home/cvs/archivista/jobs/sane-client.pl";
$val{sanebox} = "/usr/bin/perl /home/cvs/archivista/jobs/sane-box.pl";
$val{ftp} = "/usr/bin/perl /home/cvs/archivista/jobs/axis2sane.pl";
$val{cups} = "/usr/bin/perl /home/cvs/archivista/jobs/cups2axis.pl";
$val{tif} = "/usr/bin/perl /home/cvs/archivista/jobs/tif2axis.pl";
$val{pdf} = "/usr/bin/perl /home/cvs/archivista/jobs/pdf2axis.pl";
$val{tosca} = "/usr/bin/perl /home/cvs/archivista/jobs/tosca2axis.pl";
$val{enventa} = "/usr/bin/perl /home/cvs/archivista/jobs/enventa2axis.pl";
$val{axapta} = "/usr/bin/perl /home/cvs/archivista/jobs/axapta2axis.pl";
$val{xerox} = "/usr/bin/perl /home/cvs/archivista/jobs/xerox2axis.pl";
$val{export} = "/usr/bin/perl /home/cvs/archivista/jobs/exportdb.pl";
$val{web} = "/usr/bin/perl /home/cvs/archivista/jobs/processweb.pl";
$val{mail} = "/usr/bin/perl /home/cvs/archivista/jobs/mail-send.pl";
$val{temppdf} = "/usr/bin/perl /home/cvs/archivista/jobs/temppdf.pl";
$val{webconfig} = "/usr/bin/perl /home/cvs/archivista/jobs/webconfig.pl";
$val{office} = "/usr/bin/perl /home/cvs/archivista/jobs/officeprint.pl";
$val{recpage} = "/usr/bin/perl /home/cvs/archivista/jobs/ocrfromnotes.pl";
$val{ftptif} = "/home/data/archivista/ftp/tiff"; # tif path for ftp scanning
$val{ftppdf} = "/home/data/archivista/ftp/pdf";  # pdf path for ftp scanning
$val{ftptosca} = "/home/data/archivista/ftp/tosca"; # path for tosca erp
$val{ftpenventa} = "/home/data/archivista/ftp/enventa"; # path for tosca erp
$val{ftpaxapta} = "/home/data/archivista/ftp/axapta"; # path for axapta erp
$val{ftpxerox} = "/home/data/archivista/ftp/xerox"; # path for xerox erp
$val{ftpoffice} = "/home/data/archivista/ftp/office"; # path for xerox erp
$val{scanbox} = "/home/data/archivista/ftp/scanbox"; # path for xerox erp
$val{webconfig} = "/etc/webconfig"; # path for xerox erp
$val{maxtime} = 300; # maximum of time for a single upload    

use constant JOB_INIT => 100; # ready to start scanadf
use constant JOB_WORK => 110; # prepare the scan process
use constant JOB_WORK2 => 111; # call another script to work with
use constant JOB_WORK3 => 118; # we cancel the job (web upload)
use constant JOB_DONE => 120; # scanadf job was started

logit("sane-daemon started");
my $res = 0;
for (my $c0=0;$c0<360;$c0++) {
  if (MySQLOpen(\%val)) {
	  $res=1;
		last;
	}
	sleep 1;
}
if ($res==1) {	
  my $dbs = checkFTPFolders(\%val); # check for ftp folders
	my $cmd = "/usr/bin/perl /home/cvs/archivista/jobs/sphinxit.pl ".
	          "searchd >>/home/data/archivista/av.log &";
	system($cmd);
  # connection to mysql is ok, script should work ca 1 hour
  for ( my $count = 0 ; $count <= 3600 ; $count++ ) {
    if (HostIsSlave($val{dbh})==0) {
      # get the next job
      my $sql = "select id,host,db,user,pwd,job from jobs " .
                "where status=".JOB_INIT." order by job ASC,id ASC limit 1";
      my @f = $val{dbh}->selectrow_array($sql);
			$val{jobid} = $f[0];
			$val{job} = $f[5];
      if ( $val{jobid} > 0 ) {
			  if ($val{job} ne "WEB") {
          # mark in the jobs table, that we take care about this job
          $sql = "update jobs set status=".JOB_WORK." where id=$f[0]";
          $val{dbh}->do($sql);
				}
        $ENV{'AV_SCAN_JOBS_ID'} = $val{jobid};
        $ENV{'AV_SCAN_HOST'} = $f[1];
        $ENV{'AV_SCAN_DB'} = $f[2];
        $ENV{'AV_SCAN_USER'} = $f[3];
        $ENV{'AV_SCAN_PWD'} = $f[4];
        $ENV{'AV_SCAN_END'} = ""; # we don't have an end file
        if ($val{job} eq "SANE") {
	        jobSane(\%val); # it is a SANE job
				} elsif ($val{job} eq "SCANBOX") {
	        jobScanbox(\%val); # it is a SANE job
				} elsif ($val{job} eq "OCRRECPAGE") {
	        jobRecPage(\%val); # it is a SANE job
        } else {
	        jobCallAnother(\%val); # non SANE job, it is FTP, CUPS...
        }
      } else {
        # wait a moment
        sleep $SLEEP;
      }
    }
  }
  # disconnet mysql connection
  $val{dbh}->disconnect();
}






=head2 jobCallAnother

Reads a file from jobs_data table and calls the application

=cut

sub jobCallAnother {
  my ($pval) = @_;
  $$pval{fname} = selectValue($pval,"FILENAME"); # get filename
  print "Filename: $$pval{fname}\n";
	my $status = JOB_DONE;
  if ($$pval{job} eq "CUPS") {
	  print "cups\n";
    system ("$$pval{cups} '$$pval{fname}'");
  } elsif ($$pval{job} eq "FTP" || $$pval{job} eq "FTPSLOW") {
	  print "ftp\n";
    system ("$$pval{ftp} '$$pval{fname}'");
	} elsif ($$pval{job} eq "WEB") {
	  print "web\n";
		system ("$$pval{web} '$$pval{jobid}' &") if checkNewWebUpload($pval)==1;
	} elsif ($$pval{job} eq "OFFICE") {
	  print "office\n";
		system ("$$pval{office} $$pval{jobid}");
  } elsif ($$pval{job} eq "MAIL") {
	  print "mail\n";
		my $db2 = $ENV{'AV_SCAN_DB'};
	  my $doc = selectValue($pval,"MAIL_DOC");
    system ("$$pval{mail} $db2 $doc &");
  } elsif ($$pval{job} eq "PDF") {
	  print "pdf\n";
    system ("$$pval{pdf} '$$pval{fname}'");
  } elsif ($$pval{job} eq "TIFF") {
	  print "tif\n";
    system ("$$pval{tif} '$$pval{fname}'");
  } elsif ($$pval{job} eq "TOSCA") {
	  print "tosca\n";
    system ("$$pval{tosca} '$$pval{fname}'");
  } elsif ($$pval{job} eq "ENVENTA") {
	  print "enventa\n";
    system ("$$pval{enventa} '$$pval{fname}'");
  } elsif ($$pval{job} eq "AXAPTA") {
	  print "axapta\n";
    system ("$$pval{axapta} '$$pval{fname}'");
	} elsif ($$pval{job} eq "XEROX") {
	  print "xerox\n";
    system ("$$pval{xerox} '$$pval{fname}'");
	} elsif ($$pval{job} eq "TEMPPDF") {
	  print "tmppdf\n";
    system ("$$pval{temppdf} '$$pval{fname}'");
	} elsif ($$pval{job} eq "EXPORT") {
	  print "export\n";
		$status = JOB_WORK2;
    system ("$$pval{export} '$$pval{jobid}' &");
	} elsif ($$pval{job} eq "WEBCONF") {
	  system ("$$pval{webconfig} '$$pval{jobid}' &");
	} elsif ($$pval{job} eq "JOBS") {
	  jobJobs($pval);
  } else {
    print ("Unknown job type: $$pval{job}\n");
  }
 	if ($$pval{job} ne "WEB" && $$pval{job} ne "OFFICE") {
    my $sql = "update jobs set pwd='',status=$status where id=$$pval{jobid}";
    $$pval{dbh}->do($sql);
	}
}






=head2 jobJobs($pval)

Update a job administration entry 

=cut

sub jobJobs {
  my ($pval) = @_;
	my $sql="select value from jobs_data where ".
	        "param='LINE' and jid=$$pval{jobid}";
	my @row = $$pval{dbh}->selectrow_array($sql);
	my $line = $row[0];
	my @vals = split(";",$line);
	my $name = $vals[0];
	my $boxes = $vals[1];
	$sql="select db from jobs where id=$$pval{jobid}";
	@row = $$pval{dbh}->selectrow_array($sql);
	my $db1 = $row[0];
	if ($db1 ne "" && $line ne "") {
	  $sql = "select Inhalt from $db1.parameter where Name='JOBADMIN' and ".
		       "Art='JOBADMIN01' AND Tabelle='archiv'";
		my @row = $$pval{dbh}->selectrow_array($sql);
		if ($row[0] ne "") {
		  logit("existing jobadmin entry found!");
		  my @lines = split("\r\n",$row[0]);
			my $c=0;
			my $found=0;
			foreach (@lines) {
			  my $line0 = $lines[$c];
				@vals = split(";",$line0);
				if ($vals[0] eq $name) {
				  $vals[5] = $boxes;
					$vals[4]=0 if length($vals[5]) == length($vals[2]);
					my $line = join(";",@vals);
				  $lines[$c] = $line;
					$found=1;
				}
				$c++;
			}
			if ($found==1) {
			  my $line2 = join("\r\n",@lines);
			  $sql = "update $db1.parameter set Inhalt=".$$pval{dbh}->quote($line2).
				  " where Name='JOBADMIN' and Art='JOBADMIN01' and Tabelle='archiv'";
				logit("update JOBADMIN:$line");
				$$pval{dbh}->do($sql);
			}
		}
	}
}






=head2 jobRecPage

Call a page for ocr recognition from WebClient

=cut

sub jobRecPage {
  my ($pval) = @_;
  my $doc = selectValue($pval,"DOC");
  my $page = selectValue($pval,"PAGE");
  my $host = $ENV{'AV_SCAN_HOST'};
	my $db = $ENV{'AV_SCAN_DB'};
  my $user = $ENV{'AV_SCAN_USER'};
	my $pw = $ENV{'AV_SCAN_PWD'};
	my $go = "$host $db $user $pw $doc $page";
  my $sql = "update jobs set pwd='',status=".JOB_DONE." ".
            "where id=$$pval{jobid}";
  $$pval{dbh}->do($sql);
	system("nice -n -15 $$pval{recpage} $go &");
}






=head2 jobScanbox

calls directly scanbox processing

=cut

sub jobScanbox {
  my ($pval) = @_;
  $ENV{'SCAN_FILE'} = selectValue($pval,"FILENAME");
	jobScanboxChooseScandef($pval);
	logit("scanbox job started");
	system("nice -n -15 $$pval{sanebox} &");
  $ENV{'SCAN_FIELDS'} = "";
	my $lastpages = 0; # we check for current starting filename
	my $sql = "select value from jobs_data where ".
	          "jid=$$pval{jobid} and param='FILENAME'";
	my @res = $$pval{dbh}->selectrow_array($sql);
	my $full = $res[0];
	my @parts = split("-",$full);
	pop @parts;
	pop @parts;
	my $base = join("-",@parts); # current base name (same for all files)
	my $nrlast = 0;
	my $maxtries = 20;
	my $akttries = 0;
	while (1) { # endless loop needs to have a stopp (even if sane-box goes away)
	  my @files = <$base*>;  # get the current files
		my $nr = @files; # count them
		logit("$akttries of $maxtries with $nr of pages!"); # save to state
		if ($nr>0 && $nr != $nrlast) { # we have some changes, so set it back
		  $akttries=0;
		} else { # there are no changes, so check if we have max. loops
		  $akttries++;
			if ($akttries==$maxtries) { # we have max. of loops, so stopp it
			  logit("SCANJOB with $base images was probably stopped!");
				last; # exit of the loop
			}
		}
		$nrlast = $nr; # always store the number of the current pages
	  my $sql = "select status from jobs where id=$$pval{jobid}";
		my @res = $$pval{dbh}->selectrow_array($sql);
		if ($res[0]==JOB_DONE) { # job, ended (normal end of loop)
      logit("scanbox job ended");
		  last;
		}
		sleep 2; # wait 2 seconds in between
	}
}






sub jobScanboxChooseScandef {
  my ($pval) = @_;
	my @parts = split(/\//,$ENV{'SCAN_FILE'});
	my $fname = pop @parts;
	my @parts1 = split(/\./,$fname);
	my $ext = pop @parts1;
	my $base = join('.',@parts1);
	my @parts2 = split('-',$base);
	my $side = pop @parts2;
	my $page = pop @parts2;
	my $scandef = pop @parts2;
	my $prefixcount = 1;
	my $dbname = "archivista"; # default database to use
	my $scanid = -1; # no specific scandef  
	if ($scandef>0 and $scandef<10) {
	  $scanid = $scandef-1;
	  # fixed scanbox available
		$prefixcount = 2;
		logit("Scanbox found scandef:$scandef");
	}
	my $autofields = "";
	if ($parts2[0] ne "" && $parts2[$prefixcount] ne "") {
	  pop @parts2;
		pop @parts2 if $prefixcount==2;
	  $autofields = join('-',@parts2);
		logit("Scanbox prefix found:$autofields");
    $ENV{'SCAN_FIELDS'} = $autofields;
	}
  if ($scanid>=0) {
    my $prg = "/home/cvs/archivista/jobs/sane-button.pl";
    my $host = `sed -n "s/\\\$val{host1} *= *\\"\\(.*\\)\\"; */\\1/p\" $prg`;
    my $db1 = `sed -n "s/\\\$val{db1} *= *\\"\\(.*\\)\\"; */\\1/p\" $prg`;
    my $user = `sed -n "s/\\\$val{user1} *= *\\"\\(.*\\)\\"; */\\1/p\" $prg`;
    my $pw =  `sed -n "s/\\\$val{pw1} *= *\\"\\(.*\\)\\"; */\\1/p\" $prg`;
    chomp $host;
    chomp $db1;
    chomp $user;
    chomp $pw;
		my @ids = (); 
    my @dbs = split(",",$db1);
    my $c=0;
    foreach (@dbs) { # remove scan definitions (scan box values)
      my $name = $_;
      my ($dbname,$id) = split(':',$name);
			$id--;
			$id=0 if $id eq "";
			$ids[$c]=$id;
	    $dbs[$c]=$dbname;
	    $c++;
		}
		if ($dbs[$scanid] ne "") {
		  $scanid = $ids[$scanid];
      $ENV{'AV_SCAN_HOST'} = $host;
      $ENV{'AV_SCAN_DB'} = $dbs[$scanid];
      $ENV{'AV_SCAN_USER'} = $user;
      $ENV{'AV_SCAN_PWD'} = $pw;
			my $sql = "update jobs set host=".$$pval{dbh}->quote($host).",".
			          "db=".$$pval{dbh}->quote($dbs[$scanid]).",".
			          "user=".$$pval{dbh}->quote($user).",".
			          "pwd=".$$pval{dbh}->quote($pw)." ".
								"where id=".$$pval{jobid};
			$$pval{dbh}->do($sql);
		}
	}
	$scanid=0 if $scanid<0;
  $ENV{'AV_SCAN_DEFINITION'} = selectScandef($pval,$scanid);
}





=head2 jobSane

calls directly scanadf batch scanning program

=cut

sub jobSane {
  my ($pval) = @_;
  $ENV{'AV_SCAN_DEFINITION'} = selectValue($pval,"SCAN_DEFINITION");
	$ENV{'AV_SCAN_OWNER'} = selectValue($pval,"SCAN_USER2");
  $ENV{'AV_SCAN_TO_DOCUMENT'} = selectValue($pval,"SCAN_TO_DOCUMENT");
  $ENV{'AV_SCAN_END'} = $$pval{end}; # we have an end file
	if ($ENV{'AV_SCAN_DEFINITION'} ne "") {
	  logit("scanjob started");
    my @sv = split( ";", $ENV{'AV_SCAN_DEFINITION'});
    my $v = $sv[11];
  	my $pause = $v;
	  my $anzSeiten = $sv[12];
    my $source = "Normal";
    $source = "ADF Front" if ( $v > 0 );
    $source = "ADF Duplex" if ( $v < 0 );
    $source = "ADF Back" if ( $v == -3);
	  $source = "Normal" if ( $v >= 2);
	  if ($anzSeiten>1 && $pause>=2 && $source eq "Normal") {
	    # we have a stop file (empty pages)
      $ENV{'AV_SCAN_STOP'} = $$pval{stop}; 
	  }
		mkdir $$pval{path} if !-e $$pval{path};
		system("rm -rf $$pval{path}$$pval{ds}*");
		system("nice -n -15 $$pval{sane} &");
    # Process the scan request (twice if we first got an error)
    processSane($pval,1) if (processSane($pval,0));
		system("touch $$pval{end}");
		logit("scanadf ended");
		while (1) { 
		  my $sql = "select status from jobs where id=$$pval{jobid}";
			my @res = $$pval{dbh}->selectrow_array($sql);
			if ($res[0]==JOB_DONE) {
		    $|=1; # send a bell to indicate that the scan job ended
        print "\a";
        logit("scanjob ended");
			  last;
			}
			sleep 2;
		}
	}
}
 





=head2 $ret=processSane(%$pval) 

Initiate a sane process (scan values come from Archivista db

=cut

sub processSane {
  my $pval   = shift;
  my $lerror = shift;

  my ($sql,@row,$scandef,@sv,$aktdef,$v,$mode,$source,$x,$y,$left,$top,$res);
  my ($brightness,$contrast,$threshold,$system,$scnr,$c,$wait,@scannen,$resolution);

  @sv = split( ";", $ENV{'AV_SCAN_DEFINITION'});
  # 1,8,24 Bit-Scanning
  $v = $sv[1];

  $mode = "Lineart";
  $mode = "Gray" if ( $v == 1 );
  $mode = "Color" if ( $v == 2 );

  # dpi (resolution)
  $resolution = $sv[2];

  # page dimensions
  $x    = int( ( $sv[3] / 56.692 ) + 0.499 );
  $y    = int( ( $sv[4] / 56.692 ) + 0.499 );
  $left = int( ( $sv[5] / 56.692 ) + 0.499 );
  $top  = int( ( $sv[6] / 56.692 ) + 0.499 );

  # adf (feeder or not)
  $v = $sv[11];
	my $pause = $v;
	my $anzSeiten = $sv[12];
  $source = "Normal";
  $source = "ADF Front" if ( $v > 0 );
  $source = "ADF Duplex" if ( $v < 0 );
  $source = "ADF Back" if ( $v == -3);
	$source = "Normal" if ( $v >= 2);
  if ( $lerror > 0 ) {
    # if we had an error in the first try, we use another source
    if ( $source eq "Normal" ) {
      $source = "ADF Front";
    } else {
      $source = "Normal";
    }
  } else {
    # we wait the appropriate number of seconds
    $wait = $sv[21];
    sleep $wait;
  }

  # brightness/contrast
  $brightness = int $sv[13] / 10;
  $contrast   = int $sv[14] / 10;
  $threshold  = int $sv[15];

  #compose system command
  $system = "--mode '$mode' ";
  $system .= "--source '$source' " if ( length($source) > 0 );
  $system .= "-e 1 " if $source eq "Normal";
  $system .= "--resolution '$resolution' ";
  $system .= "--contrast $contrast ";
  $system .= "--brightness $brightness ";
	if ($threshold <= 255 && $threshold > 0) {
	  if ($mode eq "Lineart") {
      $system .= "--threshold $threshold ";
	  } else {
      $system .= "--gamma $threshold ";
		}
	}
	$system .= "--page-width $x "; 
	$system .= "--pagewidth $x "; 
  $system .= "-x $x ";
	$system .= "--page-height $y "; 
	$system .= "--pageheight $y "; 
  $system .= "-y $y ";
  $system .= "-l $left ";
  $system .= "-t $top ";
	$system .= "--compression JPEG --compression-arg $sv[31] " if $sv[31] ne "";
	$system .= "--buffermode=yes ";
	if ($sv[32]==0) {
	  $system .= "--df-action Continue ";
	} elsif ($sv[32]==1) {
	  $system .= "--df-action Default ";
	} elsif ($sv[32]==2) {
	  $system .= "--df-action Stop --df-thickness yes ";
	} elsif ($sv[32]==3) {
	  $system .= "--df-action Stop --df-length yes ";
	} elsif ($sv[32]==4) {
	  $system .= "--df-action Stop --df-thickness yes --df-length yes ";
	}
	my $variance = $sv[29]; # black/white optimization for fujitsu scanners
	if ($mode eq "Lineart" && $variance>0) {
	  $variance = 255 if $variance>255;
	  $system .= "--variance $variance ";
	}
  # give back the result of scanadf
	my $res1 = 0;
  for (my $c=1;$c<=$anzSeiten;$c++) {
    my $system1 = "";
    $system1 = "-s $c -e $c" if $source eq "Normal";
    my $cmd = "$$pval{scanadf} $system $system1";
    $res1 = system($cmd);
		$res = $res1 if $c==1;
    last if $source ne "Normal";
    if ($ENV{'AV_SCAN_STOP'} ne "" && -e $$pval{stop}) {
		  # we have a stop file (empty pages with flatbeed mode)
			last;
		}
    sleep $pause if $pause>2 && $c<$anzSeiten;
	}
	return $res;
}






=head2 $dbs=checkFTPFolders()

According the dbs (table archives), check all folders

=cut

sub checkFTPFolders {
  my ($pval) = @_;
  my ($err,$dbs);
  $err = checkFTPFolder($$pval{ftppdf});
  $err = checkFTPFolder($$pval{ftpoffice}) if $err==0;
  $err = checkFTPFolder($$pval{ftptif}) if $err==0;
  $err = checkFTPFolder($$pval{ftptosca}) if $err==0;
  $err = checkFTPFolder($$pval{ftpenventa}) if $err==0;
  $err = checkFTPFolder($$pval{ftpaxapta}) if $err==0;
  $err = checkFTPFolder($$pval{ftpxerox}) if $err==0;
  $err = checkFTPFolder($$pval{scanbox}) if $err==0;
  $err = checkFTPFolder($$pval{webconfig}) if $err==0;
	system("chown -R www-data.www-data ".$$pval{webconfig});
  if ($err==0) {
    $dbs = getDatabases($pval);
    my @dbs = split(';',$dbs);
		push @dbs,'archivista';
    foreach (@dbs) {
      my $path = $_;
      my $path1 = $$pval{ftppdf}.$$pval{ds}.$path;
      checkFTPFolder($path1);
	    $path1 = $$pval{ftpoffice}.$$pval{ds}.$path;
      checkFTPFolder($path1);
      $path1 = $$pval{ftptif}.$$pval{ds}.$path;
      checkFTPFolder($path1);
      $path1 = $$pval{ftpenventa}.$$pval{ds}.$path;
      checkFTPFolder($path1);
      $path1 = $$pval{ftptosca}.$$pval{ds}.$path;
      checkFTPFolder($path1);
      $path1 = $$pval{ftpaxapta}.$$pval{ds}.$path;
      checkFTPFolder($path1);
      $path1 = $$pval{ftpxerox}.$$pval{ds}.$path;
      checkFTPFolder($path1);
    }
  }
  return $dbs;
}






=head2 $ret=checkFTPFolder($path)

Checks if a folder does exist and gives back 1=success,0=no sucess

=cut

sub checkFTPFolder {
  my $path = shift;
  # Check if a path is available
  if (!-d $path) {
    eval(mkdir $path);
    system("chown ftp.users $path");
  }
  my $err=1; # default we set an error
  $err=0 if -d $path; # no error if path is ok
  return $err;
}






=head2 $dbs=getDatabases()

Gives back all $dbs in a single string (separated with an empty char)

=cut

sub getDatabases {
  my ($pval) = @_;
  my $dbs;
  my $sql="select * from archives";
  my $st = $$pval{dbh}->prepare($sql);
  my $rv = $st->execute();
  while ( my @r = $st->fetchrow_array) {
    if ($r[0] ne "") {
      $dbs .= ';' if $dbs ne "";
      $dbs .= $r[0];
    }
  }
  return $dbs;
}






=head2 $dbh=MySQLOpen(%$val)

Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen {
  my $pval = shift;
  my ($ds);
  $ds = "DBI:mysql:host=$$pval{host};database=$$pval{db}";
  $$pval{dbh} = DBI->connect( $ds, $$pval{user}, $$pval{pw},
                            { RaiseError => 0, PrintError => 0 } );
  logit("DBConnection-0 failed") if !defined $$pval{dbh};
  return $$pval{dbh};
}






=head2 $slave=HostIsSlave($dbh)

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






=head2 logit($message)

Writes a message to a log file

=cut

sub logit {
  my $message = shift;
  my $stamp  = TimeStamp();
  my @parts = split(/\//,$0);
  my $prg = pop @parts;
  my $logtext = $prg . " " . $stamp . " " . $message . "\n";
  open( FOUT, ">>$val{log}" );
  binmode(FOUT);
  print FOUT $logtext;
  close(FOUT);
}






=head2 $stamp=TimeStamp 

Actual date/time stamp (20040323130556)

=cut

sub TimeStamp {
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y = $t[5] + 1900;
  $m = $t[4] + 1;
  $m = sprintf( "%02d", $m );
  $d = sprintf( "%02d", $t[3] );
  $h = sprintf( "%02d", $t[2] );
  $mi = sprintf( "%02d", $t[1] );
  $s = sprintf( "%02d", $t[0] );
  $stamp = $y . $m . $d . $h . $mi . $s;
  return $stamp;
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






=head1 $val=selectParam($pval,$attr)

Give back a volue from job_data table

=cut

sub selectScandef {
  my ($pval,$attr) = @_;
	my %val2 = {};
	my $def1 = "";
	$val2{host} = $ENV{'AV_SCAN_HOST'};
	$val2{db} = $ENV{'AV_SCAN_DB'};
  $val2{user} = $ENV{'AV_SCAN_USER'};
	$val2{pw} = $ENV{'AV_SCAN_PWD'};
  if (MySQLOpen(\%val2)) {
    my $sql = "select Inhalt from ".$val2{db}.".parameter ".
		          "where Art='parameter' " .
              "and Tabelle='parameter' and Name='ScannenDefinitionen'";
    my @f = $val2{dbh}->selectrow_array($sql);
    # store the actual scan definition
	  my $def = $f[0];
	  my @defs = split(/\r\n/,$def);
	  $def1 = $defs[$attr];
	  $def1 = $defs[0] if $def1 eq "";
    $val2{dbh}->disconnect();
	}
	return $def1;
}








=head $res=checkNewWebUpload($pval)

Check for new web upload (incl. test if old job hangs or if we need to wait)

=cut

sub checkNewWebUpload {
  my ($pval) = @_;
	my $start=0;
	sleep 2;
	my $sql = "select timeadd from jobs where id=$$pval{jobid}";
	my @res = $$pval{dbh}->selectrow_array($sql);
	if ($res[0]==0) { # if we have no timeadd, then add it (start processing)
	  $sql = "update jobs set timemod=now(),timeadd=timemod ".
		       "where id=$$pval{jobid}";
		$$pval{dbh}->do($sql); 
		$start=1;
	} else { # we already did start it, so calculate difference
	  $sql = "select unix_timestamp(timemod)-unix_timestamp(timeadd), ".
		       "unix_timestamp(timemod) from jobs where id=$$pval{jobid}";
		@res = $$pval{dbh}->selectrow_array($sql);
		my $timediff = $res[0];
		my $timemod = $res[1];
		$sql = "select unix_timestamp(now())";
		@res = $$pval{dbh}->selectrow_array($sql);
		my $timenow = $res[0]; 
		my $currentdiff = $timenow-$timemod;
		if ($timediff>0) {
		  # we got a result (every thing is ok)
      $sql = "update jobs set pwd='',status=".JOB_DONE." ".
             "where id=$$pval{jobid}";
      $$pval{dbh}->do($sql);
			logit("job $$pval{jobid} sucessfully ended!");
		} else {
		  if ($currentdiff>$$pval{maxtime}) {
			  # stop everything (including open office)
			  system("killall soffice &");
				sleep 2;
        $sql = "update jobs set pwd='',status=".JOB_WORK3." ".
             "where id=$$pval{jobid}";
        $$pval{dbh}->do($sql);
			  logit("job $$pval{jobid} CANCELED after ".$$pval{maxtime}." seconds!");
			}
		}
	}
	return $start; # give back success (1) or failure (0)
}



