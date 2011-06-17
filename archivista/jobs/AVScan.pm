
package AVScan;
use strict;
use Wrapper;

sub name {wrap(@_)} # 0 => name of scan definition
sub depth {wrap(@_)} # 1 => 1=b/w,8=gray,24=color
sub dpi {wrap(@_)} # 2 => resolution in dpi
sub width {wrap(@_)} # 3 => page width (1440 units = 1 inch)
sub height {wrap(@_)} # 4 => page height (")
sub left {wrap(@_)} # 5 => left position (")
sub top {wrap(@_)} # 6 => top position (")
sub rotate {wrap(@_)} # 7 => rotate (0=none,1=90,2=180,3=270 degree)
sub postprocess {wrap(@_)} # 8 => not used on ArchivistaBox
sub splitpage {wrap(@_)} # 9 => split page in middle
sub ocr {wrap(@_)} # 10 => ocr definition
sub adf {wrap(@_)} # 11 => feeder (0=flatbed,1=adf,-1=duplex,-2=rear,2+=>wait
sub maxpages {wrap(@_)} # 12 => max. of pages to scan
sub brightness {wrap(@_)} # 13 => brightness (0-1000)
sub contrast {wrap(@_)} # 14 => contrast (0-1000)
sub gamma {wrap(@_)} # 15 => camma correction (not used on ArchivistaBox)
sub newdoc {wrap(@_)} # 16 => new doc after pages from value #20
sub deskew {wrap(@_)} # 17 => deskew pages (not yet implemented)
sub clean {wrap(@_)} # 18 => clean pages (not yet implemented)
sub autocrop {wrap(@_)} # 19 => autocrop pages (only fast autocroping)
sub newdocpages {wrap(@_)} # 20 => new document after x pages (if #16 enabled)
sub sleepinit {wrap(@_)} # 21 => time to sleep before we scan
sub scanner {wrap(@_)} # 22 => address of scanner (not used)
sub checkemptypage {wrap(@_)} # 23 => x.y=x=border,y=below %% of black
sub bwoptimize {wrap(@_)} # 24 => black/white optimization on (#1=gray/color)
sub bwradius {wrap(@_)} # 25 => pixel we use (1,2,3.. the more the slower)
sub bwoutdpi {wrap(@_)} # 26 => scale to output while bw optimization
sub autofields {wrap(@_)} # 27 => fill in some fields or call programms
sub barcodedef {wrap(@_)} # 28 => 0=no barcodes,1=recognize barcodes
sub bwthreshold {wrap(@_)} # 29 => 0=threshold value automaticially,128..255
sub formrec {wrap(@_)} # 30 => use form recognition
sub compression {wrap(@_)} # 31 => use jpeg compression (scanner depending)
sub doublefeed {wrap(@_)} # 32 => use double feed detection

sub dbh {wrap(@_)} # database handler for jobs/logs table
sub dbh2 {wrap(@_)} # database handler for documents (archive)
sub host {wrap(@_)}  # host for archive
sub database {wrap(@_)} # database for archive
sub user {wrap(@_)} # user we connect
sub password {wrap(@_)}  # password we connect
sub file {wrap(@_)} # next file we want to store into archive
sub base {wrap(@_)} # base name of the file to process (job/partfilename)
sub ext {wrap(@_)} # extension of the file (img/jpg/tif)
sub end {wrap(@_)} # file that does indicate the last file
sub last {wrap(@_)} # 1=there are no more files to process,0=there are files
sub path {wrap(@_)} # path where we find the next file
sub source {wrap(@_)} # source file we can add to archive (goes to first page)
sub source2 {wrap(@_)} # source file 2 (goes to BildA instead of Quelle)
sub nosingle {wrap(@_)} # save the source (pdf) file as a single file
sub pdf {wrap(@_)} # 0=no pdf to save,1=save pdf 
sub log {wrap(@_)} # 0=no additional log information, 1=show log information
sub ds {wrap(@_)} # path directory separator (ds)
sub job {wrap(@_)} # current job number (scan process)
sub doc {wrap(@_)} # current doc we want to save
sub pages {wrap(@_)} # current pages we have in doc
sub title {wrap(@_)} # field value for title field
sub owner {wrap(@_)} # current owner for the doc
sub lcuser {wrap(@_)} # 0=normal user names, 1=lower case user names
sub defuser {wrap(@_)} # default user in case we don't have one
sub archtype {wrap(@_)} # current archive type (1=tiff,3=jpg)
sub archived {wrap(@_)} # is document archived
sub folder {wrap(@_)} # folder number 
sub lockuser {wrap(@_)} # lock user we work with
sub locked {wrap(@_)} # the document was/is not locked
sub pagesloaded {wrap(@_)} # the current number of pages is already loaded
sub pagesstart {wrap(@_)} # we start at the following page
sub pagesframe_beg {wrap(@_)} # document is splitted, starting page
sub pagesframe_end {wrap(@_)} # document is splitted, ending page
sub error {wrap(@_)} # flag for error (0=no error,1=error)
sub doclist {wrap(@_)} # all finished documents (not yet unlocked)
sub lastbarcode {wrap(@_)} # last recognised barcode (if barcodes)
sub quality {wrap(@_)} # jpeg quality factor for saving images
sub quality2 {wrap(@_)} # jpeg quality factor for ALWAYS saving images
sub factor {wrap(@_)} # thumbnail factor (0=non,10-100=% of original image)
sub ocrerfasst {wrap(@_)} # the ocr was already done
sub ocrexclude {wrap(@_)} # no ocr at all (exclude page)
sub bwdepth {wrap(@_)} # depth after optimization
sub rotate2 {wrap(@_)} # rotate value from cold job
sub autoprog {wrap(@_)} # 0=no program for document, 1=programm for document
sub autoprogs {wrap(@_)} # all user programs (autoprog must be 1)
sub fields {wrap(@_)} # fields in table archive (if initialized)
sub bc_string {wrap(@_)} # the current barcode definition
sub bc_type {wrap(@_)} # type of barcdoe (code39 code128 etc)
sub bc_multiple {wrap(@_)} # more then one barcode
sub bc_singlepages {wrap(@_)} # recognize barcode after very page
sub bc_length {wrap(@_)} # length of the barcode
sub bc_orient {wrap(@_)} # orientation of the barcode
sub bc_stretch {wrap(@_)} # stretch the image to find out barcode better
sub bc_chars {wrap(@_)} # check chars for barcode
sub bc_doc {wrap(@_)} # 0=normal barcode, 1=barcode for document
sub initialized {wrap(@_)} # we did save the first page (0=no,1=yes)
sub nolog {wrap(@_)} # if it set to 1, we don't add a log entry (processweb)
sub logdone {wrap(@_)} # if it set to 1, we say to log table ocr is done
sub addtext {wrap(@_)} # extract and save text from pdf file
sub jobstop {wrap(@_)} # file we use to stop a job
sub ftpplus {wrap(@_)} # default=0, no check for ftpplus,1=done
sub versions {wrap(@_)} # field for versioning
sub versionkey {wrap(@_)} # field for version key field
sub versions_val {wrap(@_)} # field for versioning
sub versionkey_val {wrap(@_)} # field for version key field
sub officeimages {wrap(@_)} # field for version key field


=head1 $as=new($scandef)

Stores the values from a scan definition to attributes

=cut

sub new {
  my $class = shift;
  my ($scandef,$fields)  = @_;
  my @vals= split(";",$scandef);
	$vals[1] = 24 if $vals[1]==2;
	$vals[1] = 8 if $vals[1]==1;
	$vals[1] = 1 if $vals[1]==0;
	$vals[2] = 300 if $vals[2]<72 || $vals[2]>9600;
  my @opt = qw(name depth dpi width height left top rotate postprocess
	             splitpage ocr adf maxpages brightness contrast gamma newdoc
							 deskew clean autocrop newdocpages sleepinit scanner
							 checkemptypage bwoptimize bwradius bwoutdpi autofields
							 barcodedef bwthreshold formrec compression doublefeed);
  my $self = {};
	bless $self,$class;
  my $c=0;
  foreach (@opt) {
	  $self->$_($vals[$c]);
		$c++;
	}
	$self->_init();
	$self->logit($scandef);
	$self->_autofields($fields);
	return $self;
}





=head1 logit($message)

Writes a message to a log file

=cut

sub logit {
  my $self = shift;
  my $message = shift;
	if ($self->log!=0) {
    my @parts = split(/\//,$0);
    my $prg = pop @parts;
    open( FOUT, ">>/home/data/archivista/av.log");
    binmode(FOUT);
    print FOUT "$prg $message\n";
    close(FOUT);
	}
}






sub _init {
  my ($self) = @_;
	$self->log(1);
	$self->archtype(1); # set type of archive depending from scandef
	$self->archtype(3) if $self->depth!=1 && $self->bwoptimize==0;
	$self->lockuser("sane431"); # default lock user
	$self->rotate(90) if $self->rotate==1; # set rotation factor
	$self->rotate(180) if $self->rotate==2;
	$self->rotate(270) if $self->rotate==3;
  $self->ocr(0) if $self->ocr<=0; # set to default ocr if none
  $self->ocrerfasst(0);
  $self->ocrexclude(0);
  if ($self->ocr==26) { # mark page as ocr processed
	  $self->ocrerfasst(1);
  } elsif ($self->ocr==27) { # don't do any ocr recognition
	  $self->ocrexclude(1);
	}
  $self->bwradius(1) if $self->bwoptimize==1 && $self->bwradius==0;
	$self->bwradius(1) if $self->bwradius<1 || $self->bwradius>5;
	$self->bwoutdpi(300) if $self->bwoutdpi<100 || $self->bwoutdpi>600;
  $self->bwthreshold(0) if $self->bwthreshold<0 || $self->bwthreshold>255;
	$self->bwdepth($self->depth);
	my $bcdef = int $self->barcodedef;
  $self->barcodedef($bcdef);
	$self->path('/tmp/scan/'); # set default paths/filenames to scan job
	$self->base('job');
	$self->ext('img');
	$self->owner('');
	my $frec = $self->formrec; # correct form recognition (FormRecognitionXX > X)
	$frec = substr($frec,-2,2);
	$frec = int $frec;
	$self->formrec($frec);
	$self->newdocpages(0) if $self->newdocpages<0;
	$self->newdocpages(1) if $self->newdocpages==0 && $self->newdoc==1;
	$self->newdocpages(0) if $self->newdoc==0;
}






sub _autofields {
  my ($self,$fields) = @_;
	my ($autofields,@autoprgs,$autoprg);
	$self->autofields('') if $self->autofields eq '0';
	if ($self->autofields ne "") {
	  # check if we have a program for autofields
		my @autoparts = split(":",$self->autofields);
		foreach (@autoparts) { # go through all parts
		  my $singlepart = $_;
		  my ($autoprg1,$autoprg2) = split("=",$singlepart);
		  if ($autoprg1 eq $singlepart && $autoprg2 eq "") {
			  $autoprg=1; # we have a auto programm 
			  push @autoprgs,$singlepart;
			} else { # normal autofield part
			  $autofields.=":" if $autofields ne "";
			  $autofields.=$singlepart;
			}
		}
	}
  if ($fields ne "") {
    # combine the fields to autofields from a cold plus/ftp plus definition
    $autofields .= ":" if $autofields ne "";
    $autofields .= $fields;
  }
	$self->autofields($autofields);
	$self->autoprog($autoprg);
	$self->autoprogs(\@autoprgs);
}






sub getfields {
  my ($self) = @_;
	if ($self->dbh2 && $self->fields eq "") {
    my $sql   = "describe archiv";
    my $st = $self->dbh2->prepare($sql);
    my $r  = $st->execute;
    my @fields;
		my $nr = 0;
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
		$self->fields(\@fields);
	}
}






sub barcodeinit {
  my ($self) = @_;
  my %bctypes = ( # hash with types of barcode recognition
     0 => 'any', 1 => 'code39', 2 => 'code39', 3 => 'code25',
     4 => 'code25', 5 => 'ean13', 6 => 'code128', 7 => 'ean8'
  );
  if ($self->barcodedef>0) { # Barcode recognition is on, so check it  
		my $barcodedef = $self->barcodedef;
    $barcodedef--; # we need to calculate -1 for the correct barcode definition;
    $barcodedef=0 if $barcodedef<0 || $barcodedef>99; # def must be between 0-99
    my $sql="select Inhalt from parameter where Name='Barcodes'";
    my @row=$self->dbh2->selectrow_array($sql);
    my $row0=join("",@row); # get all barcode definitions in one string
    $row0 =~ s/\r//g; # now remove \r chars
    my @row1=split("\n",$row0); # now split it single lines
    my $bcstring=$row1[$barcodedef];
    $bcstring=$row1[0] if $bcstring eq ""; # now get the current barcode def
    my @bc=split(";",$bcstring);
    # get the first definition (we need the length)
    my $bcset=$bc[21]; # here we find the first sub definition
    my @bc1 = split(",",$bcset); # split it
    my $bclength=$bc1[1]; # length of the barcode
    my $firstBCType=$bc[2];
    my $secondBCType=$bc[5];
		my @singles = split(/,/,$bc[1]); # get first value (position l,t,x,y,t,m)
		my $singlepages = $singles[6]; # inside position it is the last element
	  my $orient=$bc[3]; # 0=any,1=le/ri,2=tp/dw,3=ri/le,4=dw/up,5=le/ri+tp/dw
	  my $orientval = 15;
	  $orientval = 1 if $orient==1;
	  $orientval = 2 if $orient==2;
	  $orientval = 4 if $orient==3;
	  $orientval = 8 if $orient==4;
	  $orientval = 3 if $orient==5;
    my $checkCharakter=$bc[4];
	  my $stretch=$bc[6];
	  $stretch++;
	  $stretch=1 if $stretch<1 || $stretch>3;
    my $topt1 = $bctypes{$firstBCType}; # first barcode type
    my $topt2 = $bctypes{$secondBCType}; # second barcode type
	  my $multiple = 0; 
	  $multiple = 1 if $topt1 ne "" && $topt2 ne "";
    my $tany = $bctypes{0}; # any does mean, we want every barcode
    # prepare now the barcode string for the barcode recognition
    if ($topt1 ne $tany && $topt2 ne $tany && $topt1 ne $topt2) {
       # we don't have any any and bc1 is different from bc2
       $topt1 .= "|$topt2";
    } elsif ($topt1 eq $tany) {
       # let's use the second barcode if the first one is any
       $topt1 = $topt2;
    }
    $topt1 = $tany if $topt1 eq "";
    my $fld=$bc1[2]; # field to store the barcode
    my $c=0;
    my $cok=0;
    my $cres=-1;
    my $res=0;
    foreach (@{$self->fields}) {
      my $name=${$self->fields}[$c]->{name};
      if ($name ne "Seiten" and $name ne "Akte") {
        if ($cok==$fld) {
          $cres=$c;
					last;
        }
        $cok++;
      }
      $c++;
    }
    # if we could not find a field it must be the doc. number
    $self->bc_doc(1) if ${$self->fields}[$cres]->{name} eq "Notiz";
		$self->bc_string($bcstring);
		$self->bc_type($topt1);
		$self->bc_length($bclength);
		$self->bc_orient($orientval);
		$self->bc_stretch($stretch);
		$self->bc_chars($checkCharakter);
		$self->bc_multiple($multiple);
		$self->bc_singlepages($singlepages);
	}
}

1;

