#!/usr/bin/perl

package AVBase;

use strict;
use AVConfig;
use Wrapper;

our @ISA = qw(AVConfig);

use constant UPPERCASE => 'uc';
use constant LOWERCASE => 'lc';




=head1 new

Get back a new object

=cut

sub new {
  my $class = shift;
	my $self = $class->SUPER::new();
	return $self;
}






=head1 logMessage($message,$file)

Writes a message (incl. a timestamp and script) to the log file

=cut

sub logMessage {
  my $self = shift;
  my ($message,$file) = @_;
  my $stamp   = $self->timeStamp();
  my $logtext = $0 . " " . $stamp . " " . $message;
	$self->writeMessage($logtext);
	$self->writeMessage($logtext,$file) if $file ne "";
}






=head1 writeMessage($message,$file,[$user,$group])

Writes a $message to $file and changes the rights to $user
If $file is not available, we use the global logfile
Attention: We only set the $user if there is a $file

=cut

sub writeMessage {
  my $self = shift;
  my ($message,$file,$user,$group) = @_;
	$file = $self->logfile if $file eq "";
	open(FOUT,">>$file");
  binmode(FOUT);
  print FOUT "$message\n";
  close(FOUT);
	$self->setFileOwner($file,$user,$group) if $user ne "" && $group ne "";
}






=head1 $ok=jobStart($mess,$wait)

Checks if a job is running (OCR or archiving)

=cut

sub jobStart {
  my $self = shift;
  my ($mess,$wait) = @_;
	$wait = 20 if $wait <5 || $wait >600;
	my $ok = 0;
	for(my $c=0;$c<=$wait;$c++) {
	  if ($self->jobCheckNotStarted()) {
		  $self->logMessage($mess,$self->joblog);
		  $self->writeMessage($mess,$self->jobwork,$self->user);
			$c = $wait;
			$ok = 1;
		}
		sleep 1;
	}
	return $ok;
}






=head1 $ok=jobStop($mess,$wait)

Check if ocr/another batch job is already started.
If it is started, try to stop it and after given time $wait
try to start the new job and gives back an 1 (success)

=cut

sub jobStop {
  my $self = shift;
  my ($mess,$wait) = @_;
	$wait = 20 if $wait <5 || $wait >600;
	my $ok=0;
  my $notstarted=$self->jobCheckNotStarted();
	if ($notstarted==0) {
	  if (!-e $self->jobstop) {
		  $self->logMessage($mess.": call for a stop",$self->joblog);
		  $self->writeMessage($mess,$self->jobstop,$self->user);
	    for (my $c=0;$c<$wait;$c++) {
		    if (-e $self->jobend) {
		      $self->logMessage($mess.": end is reached",$self->joblog);
	        $self->JobKill($mess);
		      $ok=1;
			    $c=$wait;
		    }
	      sleep 1;
		  }
		}
		$notstarted=0;
	} else {
		$self->logMessage($mess.": not started",$self->joblog);
	  $ok=1;
	}
	return $ok
}






=head1 $ok=jobEnded($mess)

The end of a job is reached, remove temp. files (gives back always 1)

=cut

sub jobEnded {
  my $self = shift;
  my ($mess) = @_;
	# stop a job
	$self->logMessage($mess,$self->joblog);
	unlink $self->jobwork if -e $self->jobwork;
  unlink $self->jobend if -e $self->jobend;
  unlink $self->jobstop if -e $self->jobstop;
	return 1;
}






=head1 $cancel=jobCheckStop($mess)

Checks if a running job should be stopped

=cut

sub jobCheckStop {
  my $self = shift;
  my ($mess) = @_;
	my $cancel = 0;
	if (-e $self->jobwork && -e $self->jobstop) {
	  $self->writeMessage($mess,$self->jobend);
		$self->logMessage($mess,$self->joblog);
		$cancel=1;
	}
	return $cancel;	
}
	





=head1 $notstarted=jobCheckNotStarted()

Checks if the OCR job (batch) is already started

=cut

sub jobCheckNotStarted {
  my $self = shift;
	my $notstarted = 1;
	$notstarted=0 if -e $self->jobwork;
	return $notstarted;
}






=head1 $stamp=timeStamp 

Actual date/time stamp (20040323130556)

=cut

sub timeStamp {
  my $self = shift;
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





=head1 setFileOwner($file,[$user,$group])

Set a user and group id to a file, if none, use default user/group

=cut

sub setFileOwner {
  my $self = shift;
  my ($file,$user,$group) = @_;
	if ($user==0 && $group==0) {
	  $user=$self->avuser;
		$group=$self->avgroup;
	}
	chown $user,$group, ($file) if -e $file;
}







=head1 $res=writeFile($file,$pcontent,$killold)

Saves a file (if needed with check) from a pointer variable (1=success)

=cut

sub writeFile {
  my $self = shift;
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






=head1 readFile($file,\$memory)

Reads a file and stores its contents to a pointer (file must exist)

=cut

sub readFile {
  my $self = shift;
  my ($file,$pmemory) = @_;
  open( FIN, $file );
  binmode(FIN);
	$$pmemory = "";
	while (my $line = <FIN>) {
	  $$pmemory .= $line;
	}
  close(FIN);
}






=head1 readFile2($file,$pout,$killit)

Get the file back as a pointer

=cut

sub readFile2 {
  my $self = shift;
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






=head1 getFileExtension($fname,[$case])

Return the extension of a file or in other words the filetype.
If $case is UPPERCASE or LOWERCASE (see constants), adjust lc/uc

=cut

sub getFileExtension {
  my $self = shift;
  my ($fn,$case) = @_;
  my @sections=split(/\./,$fn); # split into parts
	my $res=$sections[$#sections]; # get last element
	$res='' if $res eq $fn; # if only one part, it is not an extension
	$res=lc($res) if $case eq $self->LOWERCASE;
	$res=uc($res) if $case eq $self->UPPERCASE;
	return $res;
}






=head1 ($imgw,$imgh,$depth) = getImagePosInfo($file)

Gives back actual width/height and depth of an image (with identify)

=cut

sub getImageInfo {
  my $self = shift;
  my ($file) = @_;
  my ($imgw,$imgh,$depth,$art,$col);
	my $i = $self->identify;
  my $id = `$i $file`;

  # extract the file information 123x234 DirectClass/PseudoClass 256c/2c
  eval( $id =~ /\s{1}([0-9]+)x{1}([0-9]+).*?\s{1}(.+?)\s{1}(.+?)\s{1}/ );
  $imgw = $1;
  $imgh = $2;
  $art  = $3;
  $col  = $4;
  if ( $art eq "DirectClass" ) {
    # color file
    $depth = 24;
  } else {
    # gray or black/width
    $depth = ( $col eq "256c" ) ? 8 : 1;
  }
  $self->logMessage("$file with $imgw x $imgh and $depth bits");
  return ( $imgw, $imgh, $depth );
}






=head1 $res = getImageResolutionFromScanDef($scandef) 

Gives back the resolution of the scan definition

=cut

sub getImageResolutionFromScanDef {
  my $self = shift;
  my ($scandef) = @_;
  my @scanval = split(";",$scandef);
	my $depth = $scanval[1];
	# we get the resolution
  my $resolution = $scanval[2];
	if ($resolution<72 || $resolution>9600) {
	  # in case the resolution is non sense, set defaults
	  if ($depth <1 || $depth >2) {
		  # gray/color
		  $resolution=150;
		} else {
		  # everything else (b/w)
		  $resolution=300;
		}
	}
	return $resolution;
}






=head1 getRotationAngleWithADF($page,$scanId)

This method calculates the rotation of the image with respect to the scanmode.

=cut

sub getRotationAngleWithADF {
  my $self = shift;
  my ($page,$scanId) = @_;
  my $factor=0;

  my @scanval = split(";",$scanId);
	my $rotate = $scanval[7];
	my $adfMode = $scanval[11];
 
  $factor=3 if (($adfMode==-2) && ($page & 1));
  $factor=1 if (($adfMode==-2) && (!($page & 1)));
  my $angle=($rotate+$factor)*90;
  return $angle%360;
}






=head1 $return=rotateImage($fname,$page,$scanId)

Rotates the incomming picture with respect of its type.
This method returns the orientation of the document:

0=portrait
1=landscape

This does mean, rotation of 180 is done, but we have the same image x/y
values, so we give back a zero values

=cut

sub rotateImage {
  my $self = shift;
  my ($fname,$page,$scanId) = @_;
  my $rotation=$self->getRotationAngleWithADF($page,$scanId);
  my $type=$self->getFileExtension($fname);
  return 0 if (!$rotation);
	
  my $inFile=$fname;
  my $outFile=$inFile . ".$type";
  my $cmd="";

  my $rotation1 = $rotation;
  if ($rotation1==90) {
	  $rotation1=270;
  } elsif ($rotation==270) {
	  $rotation1=90;
  } 
	$cmd=$self->eimi." $inFile ".$self->eimr." $rotation1 ".$self->eimo." $outFile";
  if (!system($cmd)) {
    rename $outFile,$inFile;
		if ($rotation==180) {
			return 0;
		}	else {
    	return 1;
		}
  }
  return 0;
}






=head1 $res=createDir($path,$user,$group)

Creates the directory $path with the $user,$group rights

=cut

sub createDir {
  my $self = shift;
  my ($path,$user,$group) = @_;
  my $res=0;
	if (!-e $path || !-d $path) {
	  mkdir $path;
		$self->setFileOwner($path,$user,$group);
	}
	$res=1 if -d $path;
	return $res;
}





=head1 @files = getFilesFromDir($dir,$inclPath)

Gives back all files from a directory

=cut

sub getFilesFromDir {
  my $self = shift;
  my ($dir,$inclPath) = @_;
  opendir(FOUT,$dir);
	my @files=readdir(FOUT);
	closedir(FOUT);
	my @res;
	foreach(@files) {
	  my $f = $_;
		if ($f ne "." && $f ne "..") {
		  push @res,$f;
		}
	}
	return @res;
}






=head1 $dir=checkDir($dir)

Checks a path for needed ending dir separator and gives back the path name

=cut

sub checkDir {
  my $self = shift;
  my ($dir) = @_;
  my $ds=$self->dirsep;
	$dir =~ s/$ds$//;
	$dir .= $ds;
	return $dir;
}






=head1 $res=removeDir($path)

Remove the $path from the file system, result codes are:

0=folder could not be killed
1=success (folder was removed)
2=folder not available,

=cut

sub removeDir {
  my $self = shift;
  my ($path) = @_;
  my $res=1;
  return 2 if (!-e $path);
	# remove the temp path
	my $cmd = $self->rmdirall.$path;
	system($cmd);
	$res=0 if -e $path;
	return $res;
}










=head1 $kbused=getDiskSpaceUsed($dir)

Returns the used diskspace on the root filesystem in kbytes.

=cut

sub getDiskSpaceUsed {
  my $self = shift;
  my ($dir) = @_;
	# get actual size of a folder and give back the number of files
	my $cmd = "du --max-depth 0 -k $dir | awk '{print \$1}'";
	my $folderSize = `$cmd`;
  $folderSize =~ s/\r//;
  $folderSize =~ s/\n//;
  return $folderSize;
}






=head1 $kbfree=getDiskSpaceFree($dir)

Returns the available diskspace on the root filesystem in kbytes.

=cut

sub getDiskSpaceFree {
  my $self = shift;
  my ($dir) = @_;
  return `df -k $dir | sed 1d | awk -F' ' '{ print $4 }'`;
}






# must be
1;



