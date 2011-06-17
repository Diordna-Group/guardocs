#!/usr/bin/perl

=head1 images.pl (c) 19.3.2007, v1.0 by Archivista GmbH, Urs Pfister

Import images from a location (namely usb stick) and import them to an
archivista db

=cut

use strict;
use lib qw(/home/cvs/archivista/jobs);
#use lib qw(/home/cvs/archivista/jobs/im2/objdir/api);
use AVDocs;
use ExactImage;

my $lang = self::getLang();
my $msg_img_titel=self::findit("MSG_IMG_TITEL",$lang);
my $msg_img_noconnect=self::findit("MSG_IMG_NOCONNECT",$lang);
my $msg_img_importdone=self::findit("MSG_IMG_IMPORTDONE",$lang);
my $msg_img_slave=self::findit("MSG_IMG_SLAVE",$lang);
my $msg_img_imagesadd=self::findit("MSG_IMG_IMAGESADD",$lang);
my $msg_img_importit=self::findit("MSG_IMG_IMPORTIT",$lang);
my $msg_img_host=self::findit("MSG_IMG_HOST",$lang);
my $msg_img_db=self::findit("MSG_IMG_DB",$lang);
my $msg_img_user=self::findit("MSG_IMG_USER",$lang);
my $msg_img_password=self::findit("MSG_IMG_PASSWORD",$lang);
my $msg_img_fields=self::findit("MSG_IMG_FIELDS",$lang);
my $msg_img_text=self::findit("MSG_IMG_TEXT",$lang);
my $msg_img_none=self::findit("MSG_IMG_NONE",$lang);
my $msg_img_single=self::findit("MSG_IMG_SINGLE",$lang);
my $msg_img_all=self::findit("MSG_IMG_ALL",$lang);
my $msg_img_copy=self::findit("MSG_IMG_COPY",$lang);
my $msg_img_frm=self::findit("MSG_IMG_FRM",$lang);
my $msg_img_ok=self::findit("MSG_IMG_OK",$lang);
my $msg_img_cancel=self::findit("MSG_IMG_CANCEL",$lang);
my $msg_img_login=self::findit("MSG_IMG_LOGIN",$lang);

my $dir = shift; # get the current directory where we search for jpg files

# check if Prima is there
use Prima qw(Application ImageViewer MsgBox Lists Classes Buttons);
eval "use Prima::VB::VBLoader"; die"$@\n" if $@;

my %val; # the global hash value
$val{ds} = "/"; # ATTENTION: Linux (/) or Windows (\\)
$val{jhead} = "jhead"; # extract exif informations
$val{sanebutton} = "/home/cvs/archivista/jobs/sane-button.pl";
my @files; # store the founded files

# load the form and show it
my $frm = Prima::VBLoad("/home/cvs/archivista/jobs/frmImages.fm",
          'frm' => { centered => 1 },);

$frm->set(text => $msg_img_titel); # set title

self::setLabels($frm); # set the language depending string
self::getUserConnection($frm); # read user connection info from sane-button.pl
self::getFiles($dir,\@files); # read all files
@files = grep(/\.jpg|JPG$/,@files);
@files = reverse sort @files;
self::setFiles($frm,\@files);
my @obj=$frm->get(name=>'img');
my $obj = $obj[3];
self::imageLoad($obj,$files[0]); # load the first iamge
run Prima; # Loop to handle all actions






package self;

=head1 setToggle($self)

Select/Unselect a file 

=cut

sub setToggle {
  my $self = shift;
	my $nr = $self->focusedItem;
	$self->toggle_item($nr);
	my $frm = $self->owner;
  my @obj=$frm->get(name=>'chkNone');
  my $obj = $obj[3];
	$obj->uncheck;
  @obj=$frm->get(name=>'chkAll');
  $obj = $obj[3];
	$obj->uncheck;
}






=head1 setFiles($frm,$pfiles)

Add all files to the file list

=cut

sub setFiles {
  my $frm = shift;
	my $pfiles = shift;
  my @obj=$frm->get(name=>'lst');
	$obj[3]->set(items=>$pfiles);
}






=head1 selectAll($self)

Select all files for later import

=cut

sub selectAll {
  my $self = shift;
	my $frm = $self->owner;
  my @obj=$frm->get(name=>'chkNone');
  my $obj = $obj[3];
	$obj->uncheck;
  @obj=$frm->get(name=>'lst');
  $obj = $obj[3];
	$obj->select_all;
}





=head1 deselectAll($self)

Deselect all files (nothing to import)

=cut

sub deselectAll {
  my $self = shift;
	my $frm = $self->owner;
  my @obj=$frm->get(name=>'chkAll');
  my $obj = $obj[3];
	$obj->uncheck;
  @obj=$frm->get(name=>'lst');
  $obj = $obj[3];
	$obj->deselect_all;
}






=head1 imageLoad($obj,$image)

Load the temp. thumb file

=cut

sub imageLoad {
  my $obj = shift;
	my $image = shift;
	my $ftemp = "/tmp/usb_file.jpg";
	my $ftemp1 = "/tmp/usb_file1.jpg";
	unlink $ftemp if -e $ftemp;
	unlink $ftemp1 if -e $ftemp1;
	if (!-e $ftemp) {
	  my $cmd = "$val{jhead} -st $ftemp $image 2&>/dev/null";
		system($cmd); # stupid hack because Prima::Image 1.20 can't read thumbs
		$cmd = "convert $ftemp $ftemp1";
		system($cmd);
	  my $x = Prima::Image->create;
		$x->load($ftemp1);
		$x->load($image) if $x->width==0;
		my $width = $x->width;
		my $height = $x->height;
		my $fact = 1;
		if ($width>0 && $height>0) {
		  my $factw = 200/$width;
			my $facth = 200/$height;
			$fact = $facth;
			$fact = $factw if $factw<$facth;
		}
	  $obj->set(image=>$x);
		$obj->zoom($fact);
		unlink $ftemp;
		unlink $ftemp1;
	}
}






=head1 showCurrent($self)

Show the current thumb image

=cut

sub showCurrent {
  my $self = shift;
	my $nr = $self->focusedItem;
	my $file = $self->get_item_text($nr);
	my $frm = $self->owner;
  my @obj=$frm->get(name=>'img');
  my $obj = $obj[3];
	imageLoad($obj,$file);
}






=head1 getFiles($dir,$pfiles)

Read all files from a dir (incl. subfolders

=cut

sub getFiles {
  my $dir = shift;
	my $pfiles = shift;
	if (-d $dir) {
	  $dir .= $val{ds} if substr($dir,-1,1) ne $val{ds};
	  opendir(FIN,$dir);
		my @files = readdir(FIN);
		closedir(FIN);
		foreach (@files) {
		  my $file = $_;
		  next if $file eq "." or $file eq "..";
			next if index($file,".",0)==0;
			$file = $dir.$file;
			if (-d $file) {
			  getFiles($file,$pfiles);
			} else {
        push @$pfiles,$file;
			}
		}
	} else {
    push @$pfiles,$dir
	}
}






=head1 exit

Exit the mask (without prompting)

=cut

sub exit {
  exit 0;
}






=head1 importImages($self)

Start to import the selected images

=cut

sub importImages {
  my $self = shift;
	my $frm = $self->owner;
  my @obj=$frm->get(name=>'lst');
  my $obj = $obj[3];
	my @files;
	
	my @selected = @{$obj->selectedItems};
	foreach (@selected) {
	  my $nr = $_;
	  my $file = $obj->get_item_text($nr);
	  push @files,$file; 
  }
	@files = reverse @files;
  
	@obj=$frm->get(name=>'chkText');
  $obj = $obj[3];
	my $bw = $obj->checked;

	@obj=$frm->get(name=>'sld');
  $obj = $obj[3];
	my $high = $obj->value;
	
	@obj=$frm->get(name=>'chkSingle');
  $obj = $obj[3];
	my $single = $obj->checked;

  @obj=$frm->get(name=>'txtFields');
  $obj = $obj[3];
	my $vals = $obj->text;
  my @frag = split(";",$vals);
	my (@flds,@vals);
	foreach(@frag) {
	  my ($fld,$val) = split("=",$_);
		push @flds,$fld;
		push @vals,$val;
	}
  my ($host,$db1,$user,$pw)=readUserConnection($frm);
  @obj=$frm->get(name=>'lbl');
  $obj = $obj[3];
	my $old = $obj->text;
	$obj->set(text=>$msg_img_imagesadd);
  # main loop, open a connection
	my $av2 = AVDocs->new();
  my $av = AVDocs->new($host,$db1,$user,$pw);
  if ($av->dbState==0) {
    Prima::message($msg_img_noconnect);
	} elsif ($av->isHostSlave==0) {
    my $scandef = $av->getScanDefByNumber(0);
	  if ($av->isArchivistaDB) {
		  # if it is an archivista db, then start importing
		  my ($qual,$scale) = getParameters($av);
  	  $av->setTable($av->TABLE_DOCS);
		  my $cakt=0;
			my $cmax=@files;
			my $page=0;
			my $nr=0;
		  foreach (@files) { # add every single file
				$page++ if $single==1 || $page==0;
			  my $fimg = $_;
				$cakt++;
	      @obj=$frm->get(name=>'img');
        my $obj1 = $obj[3];
				imageLoad($obj1,$fimg);
			  my $msg = "$msg_img_importit $_ ($cakt/$cmax)";
				$obj->set(text=>$msg);
			  $av->logMessage("Add $fimg to database $db1");
			  addImage($av,$fimg,$qual,$scale,$page,$bw,$high,\@flds,\@vals,\$nr);
				if ($bw==1 && ($single==0 || $page==640)) {
				  addLog($av2,$nr,$page,$host,$db1,$user,$pw);
				}
        $page=0 if $page>=640;
		  }
			addLog($av2,$nr,$page,$host,$db1,$user,$pw) if $single==1 && $bw==1;
			$obj->set(text=>$old);
	    Prima::message($msg_img_importdone);
		}
	} else {
	  Prima::message($msg_img_slave);
	}
}






=head1 addLog($av,$av2) 

Add log information for ocr recognition

=cut

sub addLog {
	my $av2 = shift;
	my $nr = shift;
	my $page = shift;
	my $host = shift;
	my $db1 = shift;
	my $user = shift;
	my $pw = shift;
	if ($av2->isHostSlave==0 && $nr>0 && $page>0) {
	  my $pfld = [$av2->FLD_LOGDOC,$av2->FLD_LOGPAGES,$av2->FLD_LOGHOST,
	              $av2->FLD_LOGDB,$av2->FLD_LOGUSER,$av2->FLD_LOGPWD,
								$av2->FLD_LOGTYPE];
	  my $pvals = [$nr,$page,$host,$db1,$user,$pw,'imp'];
	  $av2->add($pfld,$pvals,$av2->TABLE_LOGS);
	}
}






=head1 addImage($av,$file,$qual,$scale,$page,$bw,$high)

Add an image to a new document

=cut

sub addImage {
  my $av = shift;
	my $file = shift;
	my $qual = shift;
	my $scale = shift;
	my $page = shift;
	my $bw = shift;
	my $high = shift;
	my $pflds = shift;
	my $pvals = shift;
	my $pnr = shift;
  my $ext = $av->getFileExtension($file,$av->LOWERCASE);
  if ($ext eq "jpg") {
	  $ext="jpeg";
	  my $prg = $val{jhead}." ".$file;
	  my $exif = `$prg`;
		my $date = $exif;
    $date =~ /Date\/Time\s+\:+\s+([0-9]+)\:+([0-9]+)\:+([0-9]+)/;
		$date = "$2\/$3\/$1";
		my $art = 3;
		$art=1 if $bw==1;
		if ($page==1) {
		  if ($date ne '//') {
        $$pnr = $av->add([$av->FLD_TYPE,$av->FLD_DATE],[$art,$date]);
			} else {
        $$pnr = $av->add($av->FLD_TYPE,$art);
			}
			if ($$pflds[0] ne "") {
        $av->update($pflds,$pvals);
			}
		}
    my $img;
	  $av->readFile($file,\$img);
		if ($bw==1) {
		  $qual=0;
			$ext="tiff";
      optimizeBW(\$img,$qual,$ext,$high);
			$exif .= "\nOptimized to b/w by Archivista\n";
		}
    $av->addPage($av->FLD_IMG_INPUT,$img);
		getThumb(\$img,$scale,$qual,$ext);
		$av->updatePage($page,$av->FLD_IMG_IMAGE,$img);
		$av->updatePage($page,$av->FLD_TEXT,$exif);
		$av->unlock();
	}
}






=head1 getParameter($av)

Read quality and scale factor

=cut

sub getParameters {
  my $av = shift;
	my $qual = $av->getParameter("JpegQuality");
	$qual = 33 if $qual<10 || $qual>100;
	my $scale = $av->getParameter("PrevScaling");
	if ($scale>0 && $scale<100) {
	  $scale = $scale / 100;
	} else {
    $scale = 0.2;
	}
	return ($qual,$scale);
}

	




=head1 getThumb($pdate,$scal,$qual)

Create a thumb with the given parameters (changes $pdata)

=cut

sub getThumb {
  my $pdata = shift;
	my $scale = shift;
	my $qual = shift;
	my $ext = shift;
  my $image = ExactImage::newImage(); # decode the image
  ExactImage::decodeImage($image,$$pdata);
	ExactImage::imageScale($image,$scale);
	$$pdata = ExactImage::encodeImage($image,$ext,$qual,'');
	ExactImage::deleteImage($image);
}






=head1 optimizeBW($pimage,$qual,$ext,$high)

Does optimize a jpeg file to tif 

=cut

sub optimizeBW {
  my $pimage = shift;
	my $qual = shift;
	my $ext = shift;
  my $high = shift;
  my $image = ExactImage::newImage(); # decode the image
  ExactImage::decodeImage($image,$$pimage);
  ExactImage::imageOptimize2BW($image,0,0,$high,3,2.1);
	$$pimage = ExactImage::encodeImage($image,$ext,$qual,'');
	ExactImage::deleteImage($image);
}





=head1 setLabels

Fill in the language depending string

=cut

sub setLabels {
  my $frm = shift;
  my @obj=$frm->get(name=>'frmLogin');
  my $log = $obj[3];
	
  @obj=$log->get(name=>'lblHost');
  my $obj = $obj[3];
	$obj->set(text=>$msg_img_host);

  @obj=$log->get(name=>'lblDatabase');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_db);
	
	@obj=$log->get(name=>'lblUser');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_user);
	
	@obj=$log->get(name=>'lblPassword');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_password);

	@obj=$frm->get(name=>'lblFields');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_fields);

	@obj=$frm->get(name=>'chkText');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_text);

	@obj=$frm->get(name=>'chkNone');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_none);

	@obj=$frm->get(name=>'chkSingle');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_single);

	@obj=$frm->get(name=>'chkAll');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_all);

	@obj=$frm->get(name=>'lbl');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_copy);
	
	@obj=$frm->get(name=>'frmLogin');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_login);

	$frm->set(text=>$msg_img_frm);

	@obj=$frm->get(name=>'cmdOk');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_ok);

	@obj=$frm->get(name=>'cmdCancel');
  $obj = $obj[3];
	$obj->set(text=>$msg_img_cancel);
}






=head1 getUserConnection($frm)

Read the password information from sane-button.pl and show it in form

=cut

sub getUserConnection {
  my $frm = shift;
  my $prg = "";
  readFile($val{sanebutton},\$prg);
	my $host = $prg;
	my $db = $prg;
	my $user = $prg;
	my $pw = $prg;
	$host =~ s/^(.*\n)(\$val\{host1\}=\")(.*?)(\";.*)$/$3/sm;
	$db =~ s/^(.*\n)(\$val\{db1\}=\")(.*?)(\";.*)$/$3/sm;
	$user =~ s/^(.*\n)(\$val\{user1\}=\")(.*?)(\";.*)$/$3/sm;
	$pw =~ s/^(.*\n)(\$val\{pw1\}=\")(.*?)(\";.*)$/$3/sm;

  my @obj=$frm->get(name=>'frmLogin');
  my $log = $obj[3];
  @obj=$log->get(name=>'txtHost');
  my $obj = $obj[3];
	$obj->set(text=>$host);
  @obj=$log->get(name=>'txtDatabase');
  $obj = $obj[3];
	$obj->set(text=>$db);
  @obj=$log->get(name=>'txtUser');
  $obj = $obj[3];
	$obj->set(text=>$user);
  @obj=$log->get(name=>'txtPassword');
  $obj = $obj[3];
	$obj->set(text=>$pw);
}







=head1 readUserConnection($frm) 

Read the user information for a connection

=cut

sub readUserConnection {
  my $frm = shift;
  my @obj=$frm->get(name=>'frmLogin');
  my $log = $obj[3];
  @obj=$log->get(name=>'txtHost');
  my $obj = $obj[3];
	my $host = $obj->text;
  @obj=$log->get(name=>'txtDatabase');
  $obj = $obj[3];
	my $db = $obj->text;
  @obj=$log->get(name=>'txtUser');
  $obj = $obj[3];
	my $user = $obj->text;
  @obj=$log->get(name=>'txtPassword');
  $obj = $obj[3];
	my $pw = $obj->text;
	return ($host,$db,$user,$pw);
}






=head1 readFile($file,\$memory)

Reads a file and stores its contents to a pointer (file must exist)

=cut

sub readFile {
  my $file = shift;
	my $pmemory = shift;
  open( FIN, $file );
  binmode(FIN);
  my @f = <FIN>;
  close(FIN);
  $$pmemory = join( "", @f );
  undef @f;
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

