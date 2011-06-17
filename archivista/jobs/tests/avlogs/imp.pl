#!/usr/bin/perl

=head1 imp.pl (c) August 15, 2006 by Archivista GmbH, Urs Pfister & Tobias Binz

Script runs different jobs in different modes.
General: imp.pl $mode $val0 $val1 $val2
x

=cut

use lib "/home/cvs/archivista/jobs";
use strict;
use AVDocs;

my $mode = shift; # get action code
my $val0 = shift; # get database name
my $val1 = shift; # directory to work with
my $val2 = shift; # optional value (namely the records 1-x)

my $go1bit ="/home/cvs/archivista/jobs/im/optimize2bw"; # optimize to 1 bit
my $empty = "/home/cvs/archivista/jobs/im/empty-page"; # check for empty pages
use constant THUMBFILE => "/tmp/thumbnail";



my $av=AVDocs->new(); # open the Archivista object
$av->logMessage("log: ".$av->loglevel);
$av->language($av->LANGUAGE_GERMAN); # used for export values
$av->logMessage("Start: $mode -- $val0 -- $val1 -- $val2");


if ($mode eq "exportdb") {
  if (setdb($val0)) {
	  my $dir = setdir($val1);
	  exportdb($av,$dir,$val2);
	} else {
    $av->logMessage("Exportdb: Wrong database")
  }
} elsif ($mode eq "importdb") {
  if (setdb($val0)) {
	  my $dir = setdir($val1);
	  importdb($av,$dir,$val2,$val0);
	} else {
    $av->logMessage("Importdb: Wrong database")
  } 
} elsif ($mode eq "setpw") {
  setpw($av,$val0,$val1);
} elsif ($mode eq "unlock") {
  if (setdb($val0)) {
	  unlock($av,$val1);
	} else {
    $av->logMessage("Unlock: Wrong database");
	}
} else {
  $av->logMessage("Unknown Mode: $mode");
  return 0;
}







=head1 $ok=setdb($db)

Change to desired db. If none is given use standard.
Return 0 if something goes wrong.

=cut

sub setdb {
  my $db1 = shift;
  $db1=$av->db if $db1 eq ""; # use the default db if none was submitted
	if ($av->setDatabase($db1)) {
	  if ($av->isArchivistaDB) {
      return 1;
		} else {
      return 0;
		}
		
	} else {	
	return 0;
	}
}






=head1 $dir=setdir($dir)

Check given path for tailing / or use default if none is given

=cut

sub setdir {  
  my $dir = shift;
  $dir = $av->usbstick.$av->exportimages if $dir eq ""; # check dir
  $dir = $av->checkDir($dir); # check for correct path name (incl. dir sep.)
	return $dir;
}






=head1 Mode: importdb

Import a Range of Documents into an archivista database
(Default: $db = $av->getDatabase)
(Default: $dir = $av->usbstick.$av->exportimages)

$mode = importdb
$val0 = database
$val1 = directory
$val2 = range 

=cut

sub importdb {
  my $av = shift;
	my $dir = shift;
	my $val = shift;
	my $db = shift;
	my ($rawfin,@rawfin,@fin,@ext,$posdocnr,$pospages,
	    $posext,$c,$done,$archivart,$thumbext,$scandef);
	if (-e $dir.$av->exportfile) {
		$av->readFile($dir.$av->exportfile,\$rawfin); #open the exportfile
		if ($rawfin) {
		  $av->logMessage("File read and cached");
		} else {
		  $av->logMessage("Could not read File");
			return 0;
	  }
	} else {
	  $av->logMessage("File does not exist");
    return 0;
	}
  $rawfin =~ s/\r//g; #drop all \r (Windows like)
  @rawfin = split("\n",$rawfin); # split to records
  my $flds = shift @rawfin; # get first line (fields)
	$flds =~ s/(.*?)(\t+)$/$1/; # remove ALL tabs at the end
	my @flds = split("\t",$flds); # save the fields in an array
  splice (@flds,3,1); #remove Seiten from fields (addPage does it for us)
#	print "aklsdjfkdjf $what\n";
	pop @flds; # remove Laufnummer
	push @flds, $av->FLD_TYPE;
#  push @flds, $av->FLD_IMAGE_EXT;
  $scandef = $av->getScanDef;
  foreach (@rawfin) { 
	  # go through each line
		my @vals = split("\t",$_); # get the values
		my $seiten = $vals[3];
		splice (@vals,3,1);
#		print "kadjfladfk $what\n";
		my $pimg = pop @vals; # last row stores the images
		pop @vals; # drop the laufnummer;
		my @img = split(";",$pimg); # save the images in an array
    my $ext = $av->getFileExtension($img[0],$av->UPPERCASE);
		if ($ext eq $av->DOC_EXT_BMP) {
		  $archivart = $av->DOC_TYPE_BMP;
			$thumbext = $av->DOC_EXT_JPG;
		} elsif ($ext eq $av->DOC_EXT_JPG) {
      $archivart = $av->DOC_TYPE_JPG;
			$thumbext = $av->DOC_EXT_JPG;
		} else {
      $archivart = $av->DOC_TYPE_TIF;
			$thumbext = $av->DOC_EXT_PNG;
		}
   	push @vals, $archivart;		
#		push @vals, $thumbext;
  	##debug
    my $counter;
		foreach (@flds) {
      print "$_:$vals[$counter]\n";
			$counter++;
		}
		##debug
   	my @hackflds = @flds; # AVDocs->add changes my input field array!
	  my $rec = $av->add(\@hackflds,\@vals);
		if ($rec>0) {
		  ##debug
      my $counter;
			##debug
		  foreach(@img) {
			  ##debug
				foreach (@img) {
          print ".-.-.-$_-.-..-.\n";
				}
				##debug
			  my $file = $dir.$_;
			  my $val;
				$av->readFile($file,\$val);
				if ($val) {
					return 0 if (importcheckEmptyPage($av,$val,$scandef,$ext)==1);
					my $pthumb = createthumbs($av,$ext,$thumbext,\$val);
  				my $cmd = $av->identify." ".THUMBFILE;
					my $inputextent = `$cmd`;
          eval($inputextent =~ /\s{1}([0-9]+)x{1}([0-9]+)\s{1}/);
          my ($imgw,$imgh) =($1,$2);
					print "$imgw x $imgh\n";
					my $ppagefields = [$av->FLD_IMG_INPUT,$av->FLD_IMG_IMAGE,
					                   $av->FLD_IMG_X,$av->FLD_IMG_Y];
					my $ppagevals = [$val,$$pthumb,$imgw,$imgh];
					my $ok = $av->addPage($ppagefields,$ppagevals);
					##debug
					my $gettable = $av->getTable;
					my $getdatabase = $av->getDatabase;
					print "Database: $getdatabase, Table: $gettable\n";
				  open FOUT, ">/tmp/fout";
					print FOUT $val;
					close FOUT;
					my $counter;
					foreach (@$ppagefields) {
            print "$_:\n";
						$counter++;
					}
					open FOUT, ">/tmp/debuginput";
					print FOUT $$pthumb;
					close FOUT;
					open FOUT, ">/tmp/debugthumb";
					print FOUT $$pthumb;
					close FOUT;
					##debug
					if ($ok) {
						$av->logMessage("Page in $rec added");
					} else {
				    $av->logMessage("Could not add Page");
				  }
			  }
			}
		} else {
      $av->logMessage("Could not add the document");
			return 0;
	  }
  	#addlog($rec,$db,$seiten);
		$av->unlock;
	}
}






sub addlog {
  my $laufnummer = shift;
	my $db = shift;
	my $seiten = shift;
  $av->setDatabase($av->DB_DEFAULT);
  my $pf = [$av->FLD_LOGDOC,$av->FLD_LOGDB,$av->FLD_LOGDONE,
            $av->FLD_LOGERROR,$av->FLD_LOGPAGES,$av->FLD_LOGTYPE];
  my $pv = [$laufnummer,$db,0,0,$seiten,"imp"];

	$av->addlog($pf,$pv);
  $av->setDatabase($db);
  $av->setTable($av->TABLE_DOCS);
}






sub createthumbs {
  my $av = shift;
	my $ext = shift;
	my $thumbext = shift;
	my $pfile = shift;
  my $thumb;
	$ext = lc($ext);
  my $cmd = $av->eimi." $ext:- ".$av->eims." 0.5 ".$av->eimo.
          " ".lc($thumbext).":".THUMBFILE;
	print "$cmd\n";
	## Schaurig schlecht, aber ich weiss nicht wie über
	## Pipe aus und danach wieder über Pipe eingelesen werden kann.
	open PH, "| $cmd";
	print PH $$pfile;
	close PH;
	$av->readFile(THUMBFILE,\$thumb);
	return \$thumb;
}






=head1 Mode: exportdb

Export a range of Documents to a Directory in System. 
(Default: $db = $av->getDatabase)
(Default: $dir = $av->usbstick.$av->exportimages)

$mode = exportdb
$val0 = Database to use
$val1 = Directory to export to
$val2 = Range of Documents (e.g. 2-56,8)

=cut

sub exportdb {
  my $av = shift;
	my $dir = shift;
	my $val = shift;
	return 0 if ($av->removeDir($dir)==0); # old dir not deleted (error)
  return 0 if ($av->createDir($dir)==0); # export dir not ok
	my $posdocnr = $av->fieldpos($av->FLD_DOC); # fields we want to export
	return 0 if $posdocnr==-1; # FLD_DOC not found, something is wrong
	my $pospages = $av->fieldpos($av->FLD_PAGES); # position of page field
	my $posext = $av->fieldpos($av->FLD_INPUT_EXT); # image extension pos
	
	my $pflds = [$av->FLD_LOCKED, $av->FLD_DOC]; # get all records to export
	my $pvals = ["",$val];
  my @keys = $av->keys($pflds,$pvals); 

  my $filekeys = $dir.$av->exportfile; # compose file for field values
	$av->logMessage("Export starts");
	my $a=exportGetFields($posdocnr);
	foreach (@keys) {
    my $file = $_;
		$av->logMessage("$file will be exported...");
$av->key($_);
my @select = $av->select(); # get the current record
		for(my $nr=0;$nr<=$posdocnr;$nr++) {
		  $a.=$select[$nr]."\t"; # store the needed fields
		}
		my $pages = $select[$pospages];
		my $ext = $select[$posext];
		for (my $nr=1;$nr<=$pages;$nr++) {
		  my $fname;
	    my $img = $av->selectPage($nr,$av->FLD_IMG_INPUT);
			if ($img ne "") {
        $fname = "$file"."_"."$nr\.$ext";
        $av->writeFile($dir.$fname,\$img);
			}
		  $a.=$fname.";";
		}
		$a.="\r\n";
	}
	$av->logMessage("Write $filekeys");
	$av->writeFile($filekeys,\$a);
}







sub exportGetFields {
	my $posdocnr = shift;
	my $a;
	my @fields=$av->fieldnames();
	for (my $nr=0;$nr<=$posdocnr;$nr++ ) {
    $a.=$fields[$nr]."\t";
	}
	$a.="\r\n";
	return $a;
}






=head2 importcheckEmptyPage($dbh,$file,$ext)

  return: 1=empty Page, 0=no empty pages, -1=not activated

=cut

sub importcheckEmptyPage {
  my $av = shift;
	my $file = shift;
  my $scandef = shift;
  my $ext = shift;
	
  my (@row,@scannen,$aktdef,@scanval,$emptypages,$tmpimg);
	my ($tmpimg2,$supresspage,$cmd,$killit,$res,$pFields,$pSearchFields);
	my ($pSearchVals);

  $tmpimg=$file; # get the name of the tmp image file
	# we need to have a look in the scan definitions
	@scannen=split("\r\n",$scandef);
  $aktdef=$scannen[0];
	@scanval=split(";",$aktdef);
	# bingo, we get the actual value for empty pages
  $emptypages=$scanval[23];
  
	# now extract max. of dark and rand pixels
	my $rand=0;
  ($emptypages,$rand)=split /\./,$emptypages;
  $emptypages = $emptypages/1000;
	# rand pixel must be a maximum of 8
  $rand = $rand - ($rand % 8);


  if ($emptypages>0) {
	 
    # empty pages are activated
    $supresspage = 1;
    if ($ext eq $av->DOC_EXT_JPG) {
		  # we don't have a black/white image, so let's create one
		  $tmpimg2=$tmpimg."\.".lc($av->DOC_EXT_TIF);
      unlink $tmpimg2 if (-e $tmpimg2);
			# convert a colour/grayscale image to black/white (as fast as possible)
      $cmd="$go1bit -i $tmpimg -r 1 -o $tmpimg2";
      system("$cmd");
			$killit=1;
			$tmpimg=$tmpimg2;
		}
 	  # black/white is easy (direkt page analysis)
    $cmd="$empty -i $tmpimg -p $emptypages";
    $cmd.=" -m $rand" if $rand>0;
    $res=system("$cmd");
		# we got 256 (does mean there is no empty page)
    $supresspage=0 if $res==256;
		unlink $tmpimg if $killit==1;
  } else {
	  # we don't check it any longer
	  $supresspage=-1;
	}
	return $supresspage;
}





sub setpw {
  my $av = shift;
  my $user = shift;
	my $pw = shift;
  
	
	my $pfield = [];
	my $pval = [];
	my $condfield = ();
	my $condval = ();
	$av->update($pfield,$pval,$condfield,$condval,$av->TABLE_USER);
	
}




=head1 Mode: unlock

Unlock a range of documents in a database.
$mode = unlock
$val0 = database
$val1 = document range

=cut

sub unlock {
  my $av = shift;
	my $val = shift;
	if ($av->unlock($val)) { # check AVDoc->unlock return value
    return 1; 
	} else {
	  $av->logMessage("Could not unlock Document range $val");
    return 0;
	}
}
