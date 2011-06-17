# Current revision $Revision: 1.4 $
# Latest change by $Author: upfister $ on $Date: 2010/03/04 15:02:52 $

package PL::ScanDefAdministration;

use strict;

=head1 new($cls,$archiveO)

IN: class name
    object (Archivista::BL::Archive APCL)
OUT: object
Constructor

=cut

sub new {
  my $cls = shift;
  my $archiveO = shift;   # Object of Archivista::BL::Archive (APCL)
  my $self = {};
  bless $self, $cls;
  my @fields = ("def_name","def_key","def_notactive","def_scan_type","def_dpi",
		  "def_brightness","def_contrast","def_threshold", "def_emptypages",
			"def_deskew","def_autocrop",
		  "def_bwopt_on","def_bwopt_radius","def_bwopt_threshold",
			"def_bwopt_outputdpi","def_jpeg_compr","def_double_feed",
		  "def_x","def_y","def_left","def_top",
		  "def_auto_fields","def_box_bc","def_form_rec",
		  "def_rotation","def_split","def_adf",
		  "def_nr_of_pages","def_wait_seconds",
		  "def_sleep","def_ocr","def_new_docs","def_new_pages");
  $self->{'archiveO'} = $archiveO;
  $self->{'field_list'} = \@fields;
  return $self;
}






=head1 fields($self,$cgiO)

IN: object (self)
    object (CGI.pm)
OUT: pointer to hash

Return a pointer to hash of all fields and information about the fields which
must be displayed in the form to add new definitions or update existing
definitions.

=cut

sub fields {
  my $self = shift;
  my $cgiO = shift;
  my $archiveO = $self->archive;
  my $langO = $self->archive->lang;
  my $pascanTypes = $archiveO->scanTypes("ARRAY");
  my $phscanTypes = $archiveO->scanTypes("HASH");
  my $pabcTypes = $archiveO->barcodeSelectData("ARRAY");
  my $phbcTypes = $archiveO->barcodeSelectData("HASH");
  my $paocrTypes = $archiveO->ocrSelectData("ARRAY");
  my $phocrTypes = $archiveO->ocrSelectData("HASH");
  my $pascanRotations = $archiveO->scanRotations("ARRAY");
  my $phscanRotations = $archiveO->scanRotations("HASH");
  my $paADFTypes = $archiveO->adfTypes("ARRAY");
  my $phADFTypes = $archiveO->adfTypes("HASH");
	my $paFormRec = $self->formRec("ARRAY");
	my $phFormRec = $self->formRec("HASH");
  my $paDoublefeedTypes = $archiveO->doublefeedTypes("ARRAY");
  my $phDoublefeedTypes = $archiveO->doublefeedTypes("HASH");

  # Add an empty item to adf types
  unshift @$paADFTypes, "0";
  $$phADFTypes{'0'} = $langO->string("NO");
  # Add auto pilot as adf type
  push @$paADFTypes, "2";
  $$phADFTypes{'2'} = $langO->string("AUTO_PILOT");
  
  my (%fields);  
  $fields{'list'} = $self->{'field_list'};
  $fields{'def_name'}{'label'} = $langO->string("NAME");
  $fields{'def_name'}{'name'} = "def_name";
  $fields{'def_name'}{'type'} = "textfield";
  $fields{'def_name'}{'update'} = 1;

  $fields{'list'} = $self->{'field_list'};
  $fields{'def_key'}{'label'} = $langO->string("CODE");
  $fields{'def_key'}{'name'} = "def_key";
  $fields{'def_key'}{'type'} = "textfield";
  $fields{'def_key'}{'update'} = 1;

	$fields{'def_notactive'}{'label'} = $langO->string("NOTACTIVE");
  $fields{'def_notactive'}{'name'} = "def_notactive";
  $fields{'def_notactive'}{'type'} = "checkbox";
  $fields{'def_notactive'}{'update'} = 1;

  $fields{'def_scan_type'}{'label'} = $langO->string("SCAN_TYPE");
  $fields{'def_scan_type'}{'name'} = "def_scan_type";
  $fields{'def_scan_type'}{'type'} = "select";
  $fields{'def_scan_type'}{'array_values'} = $pascanTypes;
  $fields{'def_scan_type'}{'hash_values'} = $phscanTypes;
  $fields{'def_scan_type'}{'update'} = 1;

  $fields{'def_dpi'}{'label'} = $langO->string("RESOLUTION")." (dpi)";
  $fields{'def_dpi'}{'name'} = "def_dpi";
  $fields{'def_dpi'}{'type'} = "textfield";
  $fields{'def_dpi'}{'update'} = 1;

  $fields{'def_brightness'}{'label'} = $langO->string("BRIGHTNESS");
  $fields{'def_brightness'}{'name'} = "def_brightness";
  $fields{'def_brightness'}{'type'} = "textfield";
  $fields{'def_brightness'}{'update'} = 1;

  $fields{'def_contrast'}{'label'} = $langO->string("CONTRAST");
  $fields{'def_contrast'}{'name'} = "def_contrast";
  $fields{'def_contrast'}{'type'} = "textfield";
  $fields{'def_contrast'}{'update'} = 1;

  $fields{'def_threshold'}{'label'} = $langO->string("GAMMA");
  $fields{'def_threshold'}{'name'} = "def_threshold";
  $fields{'def_threshold'}{'type'} = "textfield";
  $fields{'def_threshold'}{'update'} = 1;

  $fields{'def_emptypages'}{'label'} = $langO->string("EMPTYPAGES");
  $fields{'def_emptypages'}{'name'} = "def_emptypages";
  $fields{'def_emptypages'}{'type'} = "textfield";
  $fields{'def_emptypages'}{'update'} = 1;

  $fields{'def_deskew'}{'label'} = $langO->string("SCAN_DESKEW");
  $fields{'def_deskew'}{'name'} = "def_deskew";
  $fields{'def_deskew'}{'type'} = "checkbox";
  $fields{'def_deskew'}{'update'} = 1;
 
  $fields{'def_autocrop'}{'label'} = $langO->string("SCAN_AUTOCROP");
  $fields{'def_autocrop'}{'name'} = "def_autocrop";
  $fields{'def_autocrop'}{'type'} = "checkbox";
  $fields{'def_autocrop'}{'update'} = 1;

  $fields{'def_bwopt_on'}{'label'} = $langO->string("SCANBW_OPTON");
  $fields{'def_bwopt_on'}{'name'} = "def_bwopt_on";
  $fields{'def_bwopt_on'}{'type'} = "checkbox";
  $fields{'def_bwopt_on'}{'update'} = 1;
 
  $fields{'def_bwopt_radius'}{'label'} = $langO->string("SCANBW_RADIUS");
  $fields{'def_bwopt_radius'}{'name'} = "def_bwopt_radius";
  $fields{'def_bwopt_radius'}{'type'} = "textfield";
  $fields{'def_bwopt_radius'}{'update'} = 1;

  $fields{'def_bwopt_threshold'}{'label'} = $langO->string("SCANBW_THRESHOLD");
  $fields{'def_bwopt_threshold'}{'name'} = "def_bwopt_threshold";
  $fields{'def_bwopt_threshold'}{'type'} = "textfield";
  $fields{'def_bwopt_threshold'}{'update'} = 1;
	
  $fields{'def_bwopt_outputdpi'}{'label'} = $langO->string("SCANBW_OUTPUTDPI");
  $fields{'def_bwopt_outputdpi'}{'name'} = "def_bwopt_outputdpi";
  $fields{'def_bwopt_outputdpi'}{'type'} = "textfield";
  $fields{'def_bwopt_outputdpi'}{'update'} = 1;

  $fields{'def_jpeg_compr'}{'label'} = $langO->string("SCAN_JPEG");
  $fields{'def_jpeg_compr'}{'name'} = "def_jpeg_compr";
  $fields{'def_jpeg_compr'}{'type'} = "textfield";
  $fields{'def_jpeg_compr'}{'update'} = 1;

	$fields{'def_double_feed'}{'label'} = $langO->string("SCAN_DOUBLEFEED");
  $fields{'def_double_feed'}{'type'} = "select";
  $fields{'def_double_feed'}{'name'} = "def_double_feed";
  $fields{'def_double_feed'}{'array_values'} = $paDoublefeedTypes;
  $fields{'def_double_feed'}{'hash_values'} = $phDoublefeedTypes;
  $fields{'def_double_feed'}{'update'} = 1;

  $fields{'def_x'}{'label'} = $langO->string("SCAN_WIDTH")." (mm)";
  $fields{'def_x'}{'name'} = "def_x";
  $fields{'def_x'}{'type'} = "textfield";
  $fields{'def_x'}{'update'} = 1;

  $fields{'def_y'}{'label'} = $langO->string("SCAN_HEIGHT")." (mm)";
  $fields{'def_y'}{'name'} = "def_y";
  $fields{'def_y'}{'type'} = "textfield";
  $fields{'def_y'}{'update'} = 1;

  $fields{'def_left'}{'label'} = $langO->string("POSITION_LEFT_BORDER").
	                               " (mm)";
  $fields{'def_left'}{'name'} = "def_left";
  $fields{'def_left'}{'type'} = "textfield";
  $fields{'def_left'}{'update'} = 1;
	
  $fields{'def_top'}{'label'} = $langO->string("POSITION_TOP_BORDER").
	                              " (mm)";
  $fields{'def_top'}{'name'} = "def_top";
  $fields{'def_top'}{'type'} = "textfield";
  $fields{'def_top'}{'update'} = 1;

  $fields{'def_auto_fields'}{'label'} = $langO->string("AUTO_FIELDS");
  $fields{'def_auto_fields'}{'name'} = "def_auto_fields";
  $fields{'def_auto_fields'}{'type'} = "textfield";
  $fields{'def_auto_fields'}{'update'} = 1;

  $fields{'def_box_bc'}{'label'} = $langO->string("BOX_BARCODEDEF");
  $fields{'def_box_bc'}{'name'} = "def_box_bc";
  $fields{'def_box_bc'}{'type'} = "select";
  $fields{'def_box_bc'}{'array_values'} = $pabcTypes;
  $fields{'def_box_bc'}{'hash_values'} = $phbcTypes;
  $fields{'def_box_bc'}{'update'} = 1;

  $fields{'def_form_rec'}{'label'} = $langO->string("FORM_RECOGNITION");
  $fields{'def_form_rec'}{'name'} = "def_form_rec";
  $fields{'def_form_rec'}{'type'} = "select";
  $fields{'def_form_rec'}{'array_values'} = $paFormRec;
  $fields{'def_form_rec'}{'hash_values'} = $phFormRec;
  $fields{'def_form_rec'}{'update'} = 1;

  $fields{'def_rotation'}{'label'} = $langO->string("ROTATION");
  $fields{'def_rotation'}{'name'} = "def_rotation";
  $fields{'def_rotation'}{'type'} = "select";
  $fields{'def_rotation'}{'array_values'} = $pascanRotations;
  $fields{'def_rotation'}{'hash_values'} = $phscanRotations;
  $fields{'def_rotation'}{'update'} = 1;

	$fields{'def_split'}{'label'} = $langO->string("SPLIT_PAGE");
  $fields{'def_split'}{'name'} = "def_split";
  $fields{'def_split'}{'type'} = "checkbox";
  $fields{'def_split'}{'update'} = 1;
	
  $fields{'def_adf'}{'label'} = $langO->string("MORE_PAGES");
  $fields{'def_adf'}{'name'} = "def_adf";
  $fields{'def_adf'}{'type'} = "select";
  $fields{'def_adf'}{'array_values'} = $paADFTypes;
  $fields{'def_adf'}{'hash_values'} = $phADFTypes;
  $fields{'def_adf'}{'update'} = 1;

  $fields{'def_nr_of_pages'}{'label'} = $langO->string("NR_PAGES_AUTO_PILOT");
  $fields{'def_nr_of_pages'}{'name'} = "def_nr_of_pages";
  $fields{'def_nr_of_pages'}{'type'} = "textfield";
  $fields{'def_nr_of_pages'}{'update'} = 1;

  $fields{'def_wait_seconds'}{'label'} = $langO->string("BREAK_AUTO_PILOT");
  $fields{'def_wait_seconds'}{'name'} = "def_wait_seconds";
  $fields{'def_wait_seconds'}{'type'} = "textfield";
  $fields{'def_wait_seconds'}{'update'} = 1;

  $fields{'def_sleep'}{'label'} = $langO->string("BREAK_BEFOR_SCAN");
  $fields{'def_sleep'}{'name'} = "def_sleep";
  $fields{'def_sleep'}{'type'} = "textfield";
  $fields{'def_sleep'}{'update'} = 1;

  $fields{'def_scanner_address'}{'label'} = $langO->string("SCANNER_ADDRESS");
  $fields{'def_scanner_address'}{'name'} = "def_scanner_address";
  $fields{'def_scanner_address'}{'type'} = "textfield";
  $fields{'def_scanner_address'}{'update'} = 1;

  $fields{'def_ocr'}{'label'} = $langO->string("BOX_OCRDEF");
  $fields{'def_ocr'}{'name'} = "def_ocr";
  $fields{'def_ocr'}{'type'} = "select";
  $fields{'def_ocr'}{'array_values'} = $paocrTypes;
  $fields{'def_ocr'}{'hash_values'} = $phocrTypes;
  $fields{'def_ocr'}{'update'} = 1;
   
	$fields{'def_new_docs'}{'label'} = $langO->string("OPEN_NEW_DOCUMENTS");
  $fields{'def_new_docs'}{'name'} = "def_new_docs";
  $fields{'def_new_docs'}{'type'} = "checkbox";
  $fields{'def_new_docs'}{'update'} = 1;
		
  $fields{'def_new_pages'}{'label'} = $langO->string("OPEN_NEW_PAGES");
  $fields{'def_new_pages'}{'name'} = "def_new_pages";
  $fields{'def_new_pages'}{'type'} = "textfield";
  $fields{'def_new_pages'}{'update'} = 1;

  if ($cgiO->param("adm") eq "edit") {
    my $id = $cgiO->param("id");
    if (defined $id) {
	    my $def = $archiveO->parameter("ScannenDefinitionen")
	                       ->attribute("Inhalt")
	                       ->scan($id);
	    $fields{'def_name'}{'value'} = $def->name;
	    $fields{'def_key'}{'value'} = $def->key;
	    $fields{'def_notactive'}{'value'} = $def->notactive;
    	$fields{'def_scan_type'}{'value'} = $def->scanType;
    	$fields{'def_dpi'}{'value'} = $def->dpi;
     	$fields{'def_brightness'}{'value'} = $def->brightness;
     	$fields{'def_contrast'}{'value'} = $def->contrast;
     	$fields{'def_threshold'}{'value'} = $def->gamma;
     	$fields{'def_emptypages'}{'value'} = $def->emptyPages;
			$fields{'def_deskew'}{'value'} = $def->adjust;
			$fields{'def_autocrop'}{'value'} = $def->truncate;
     	$fields{'def_bwopt_on'}{'value'} = $def->optimizeOn;
     	$fields{'def_bwopt_radius'}{'value'} = $def->optimizeRadius;
     	$fields{'def_bwopt_threshold'}{'value'} = $def->optimizeThreshold;
     	$fields{'def_bwopt_outputdpi'}{'value'} = $def->optimizeOutputDPI;
     	$fields{'def_jpeg_compr'}{'value'} = $def->jpegCompression;
     	$fields{'def_double_feed'}{'value'} = $def->detectDoubleFeed;
     	$fields{'def_x'}{'value'} = $def->x;
     	$fields{'def_y'}{'value'} = $def->y;
     	$fields{'def_left'}{'value'} = $def->left;
     	$fields{'def_top'}{'value'} = $def->top;
     	if ($def->autoFields ne "") {
     	  $fields{'def_auto_fields'}{'value'} = $def->autoFields;
     	}
     	$fields{'def_box_bc'}{'value'} = $def->boxBarcodeDef;
     	$fields{'def_form_rec'}{'value'} = $def->formRecognition;
     	$fields{'def_rotation'}{'value'} = $def->rotation;
			$fields{'def_split'}{'value'} = $def->splitPage;
     	$fields{'def_adf'}{'value'} = $def->adf;
     	$fields{'def_nr_of_pages'}{'value'} = $def->numberOfPages;
     	$fields{'def_wait_seconds'}{'value'} = $def->waitSeconds;
     	$fields{'def_sleep'}{'value'} = $def->sleep;
     	$fields{'def_ocr'}{'value'} = $def->ocr;
			$fields{'def_new_pages'}{'value'} = $def->newDocAfterPages;
			$fields{'def_new_docs'}{'value'} = $def->newDocument; 
    }
  } else {
    $fields{'def_key'}{'value'} = 999;
    $fields{'def_notactive'}{'value'} = 0;
    $fields{'def_scan_type'}{'value'} = 1;
    $fields{'def_dpi'}{'value'} = 150;
    $fields{'def_brightness'}{'value'} = 0;
    $fields{'def_contrast'}{'value'} = 0;
    $fields{'def_threshold'}{'value'} = 0;
    $fields{'def_emptypages'}{'value'} = 0;
		$fields{'def_deskew'}{'value'} = 1;
		$fields{'def_autocrop'}{'value'} = 0;
    $fields{'def_bwopt_on'}{'value'} = 0;
    $fields{'def_bwopt_radius'}{'value'} = 3;
    $fields{'def_bwopt_threshold'}{'value'} = 190;
    $fields{'def_bwopt_outputdpi'}{'value'} = 300;
    $fields{'def_jpeg_compression'}{'value'} = '';
    $fields{'def_double_feed'}{'value'} = 0;
    $fields{'def_x'}{'value'} = 210;
    $fields{'def_y'}{'value'} = 297;
    $fields{'def_left'}{'value'} = 0;
    $fields{'def_top'}{'value'} = 0;
		$fields{'def_split'}{'value'} = 0;
    $fields{'def_auto_fields'}{'value'}="";
    $fields{'def_box_bc'}{'value'}="-1";
    $fields{'def_form_rec'}{'value'}="0";
    $fields{'def_sleep'}{'value'} = 0;
    $fields{'def_ocr'}{'value'}="0";
	  $fields{'def_new_pages'}{'value'} = 0;
		$fields{'def_new_docs'}{'value'} = 0; 
  }
  $fields{'displayBackFormButton'} = 1;
  return \%fields;
}






=head1 save($self,$cgiO)

IN: object (self)
    object (CGI.pm)
OUT: -

Save the data of a definition to the database. This method performs updates
and inserts of new definitions.

=cut

sub save {
  my $self = shift;
  my $cgiO = shift;		# Object of CGI.pm
  my $archiveO = $self->archive;
  my $id = $cgiO->param("id");

  my ($scanDef);
  my $name = $cgiO->param("def_name");
  my $key = $cgiO->param("def_key");
	$key = $key - (2*$key);
  my $notactive = $cgiO->param("def_notactive");
  $notactive=0 if ($notactive != 1);
  my $scanType = $cgiO->param("def_scan_type");
  my $dpi = $cgiO->param("def_dpi");
  my $brightness = $cgiO->param("def_brightness");
  my $contrast = $cgiO->param("def_contrast");
	my $threshold = $cgiO->param("def_threshold");
  my $emptypages = $cgiO->param("def_emptypages");
  my $deskew = $cgiO->param("def_deskew");
  $deskew=0 if ($deskew != 1);
  my $autocrop = $cgiO->param("def_autocrop");
  $autocrop=0 if ($autocrop != 1);
  my $optimizeon = $cgiO->param("def_bwopt_on");
  $optimizeon=0 if ($optimizeon != 1);
  my $optimizeradius = $cgiO->param("def_bwopt_radius");
	my $optimizethreshold = $cgiO->param("def_bwopt_threshold");
  my $optimizeoutputdpi = $cgiO->param("def_bwopt_outputdpi");
  my $jpeg_compr = $cgiO->param("def_jpeg_compr");
  my $double_feed = $cgiO->param("def_double_feed");
  my $x = $cgiO->param("def_x");
  my $y = $cgiO->param("def_y");
  my $left = $cgiO->param("def_left");
  my $top = $cgiO->param("def_top");
  my $autofields = $cgiO->param("def_auto_fields");
  my $boxbc = $cgiO->param("def_box_bc");
  my $formrec = $cgiO->param("def_form_rec");
  my $rotation = $cgiO->param("def_rotation");
	my $split = $cgiO->param("def_split");
  $split=0 if ($split != 1);
  my $adf = $cgiO->param("def_adf");
  my $nrOfPages = $cgiO->param("def_nr_of_pages");
  my $waitSeconds = $cgiO->param("def_wait_seconds");
  my $sleep = $cgiO->param("def_sleep");
  my $ocr = $cgiO->param("def_ocr");
  my $open_new_documents = $cgiO->param("def_new_docs");
	$open_new_documents=0 if $open_new_documents!=1;
	my $open_new_pages = $cgiO->param("def_new_pages");
  if ($cgiO->param("submit") eq $self->archive->lang->string("SAVE")) {
    if (defined $id) {
	    # Update the scan definition
	    $scanDef = $archiveO->parameter("ScannenDefinitionen")
	                        ->attribute("Inhalt")
	                        ->scan($id);
    } else {
	    $scanDef = $archiveO->parameter("ScannenDefinitionen")
	                        ->attribute("Inhalt")
	                        ->scan;
    }
    $scanDef->name($name);
    $scanDef->key($key);
    $scanDef->notactive($notactive);
    $scanDef->scanType($scanType);
    $scanDef->dpi($dpi);
    $scanDef->brightness($brightness);
    $scanDef->contrast($contrast);
		$scanDef->gamma($threshold);
    $scanDef->emptyPages($emptypages);
		$scanDef->adjust($deskew);
		$scanDef->truncate($autocrop);
    $scanDef->optimizeOn($optimizeon);
    $scanDef->optimizeRadius($optimizeradius);
    $scanDef->optimizeThreshold($optimizethreshold);
    $scanDef->optimizeOutputDPI($optimizeoutputdpi);
    $scanDef->jpegCompression($jpeg_compr);
    $scanDef->detectDoubleFeed($double_feed);
    $scanDef->x($x);
    $scanDef->y($y);
    $scanDef->left($left);
    $scanDef->top($top);
    $scanDef->autoFields($autofields);
    $scanDef->boxBarcodeDef($boxbc);
		$scanDef->formRecognition($formrec);
		$scanDef->splitPage($split);
    $scanDef->rotation($rotation);
    $scanDef->adf($adf);
    $scanDef->numberOfPages($nrOfPages);
    $scanDef->waitSeconds($waitSeconds);
    $scanDef->sleep($sleep);
    $scanDef->ocr($ocr);
		$scanDef->newDocument($open_new_documents);
		$scanDef->newDocAfterPages($open_new_pages);
    if (defined $id) {
	    $scanDef->update;
    } else {
	    $scanDef->add;
    }
  }
}






=head1 copy($self->cgi)

Copys a scandefinition to /tmp/$user-$host.scandef

=cut

sub copy {
  my $self = shift;
	my $cgi = shift;
  my $scanObj = $self->archive->scanDefinitions("HASH")->{$cgi->param('id')};
	my $scanname = $scanObj->name();
	my $sql = "select Inhalt from parameter where Name='ScannenDefinitionen' ".
	          "and Art LIKE 'parameter' and Tabelle LIKE 'parameter' limit 1";
	my @row = $self->archive->db->dbh->selectrow_array($sql);
	my @scandefs = split("\r\n",$row[0]);
	my $out = "";
	foreach (@scandefs) {
	  my $scandef = $_;
	  my @scan1 = split(";",$scandef);
		if ($scan1[0] eq $scanname) {
		  $out = $scandef;
			last;
		}
	}
	my $file = $self->_getFileName("scandef");
	open(FOUT,">",$file);
	binmode(FOUT);
	print FOUT $out;
	close(FOUT);
}






=head1 paste($self->cgi)

Read /tmp/$user-$host.scandef and save it to Database.

=cut

sub paste {
  my $self = shift;
	my $cgi = shift;
	my ($file,$txt); 
  $file = $self->_getFileName("scandef");
	open(FIN,"<",$file);
	binmode(FIN);
	$txt = <FIN>;
	close(FIN);
	if ($txt ne "") {
	  my @vals = split(";",$txt);
	  my $newname = $vals[0];
	  my $sql = "select Inhalt,Laufnummer from parameter ".
	          "where Name='ScannenDefinitionen' ".
	          "and Art LIKE 'parameter' and Tabelle LIKE 'parameter' limit 1";
	  my @row = $self->archive->db->dbh->selectrow_array($sql);
	  my @scandefs = split("\r\n",$row[0]);
	  while ($newname ne "") {
	    my $found=0;
	    foreach (@scandefs) {
	      my $scandef = $_;
	      my @scan1 = split(";",$scandef);
		    if ($scan1[0] eq $newname) {
			    $found=1;
				  $newname = "Copy of ".$newname;
				  next;
			  }
		  }
		  if ($found==0) {
		    $vals[0] = $newname;
			  $newname="";
		  }
	  }
		my $lastnr = @scandefs;
		if ($lastnr>0) {
		  $lastnr--;
		  my $lastdef = $scandefs[$lastnr];
		  my @vals1 = split(";",$lastdef);
		  my $lastnr1 = $vals1[22];
		  $lastnr1++;
		  $vals[22] = $lastnr1;
		}
	  $txt = join(";",@vals);
	  my $scandefs = $row[0]."\r\n".$txt;
	  my $scanquote = $self->archive->db->dbh->quote($scandefs);
	  $sql = "update parameter set Inhalt=$scanquote ".
	         "where Laufnummer=$row[1]";
	  $self->archive->db->dbh->do($sql);
	  # delete file after pasting
	  unlink $file;
	}
}






# _getFileName
#
# return /tmp/$user-$host.scandef for copy paste
##

sub _getFileName {
  my $self = shift;
	my $type = shift;
  my $file;
	$file = "/tmp/".$self->archive->session->user();
	$file .= "-".$self->archive->session->host().".$type";
	if (!-e $file) {
	  my @files = </tmp/*$type>;
		foreach (@files) {
		  my $file1 = $_;
			if (-e $file1) {
			  $file = $file1;
				last;
			}
		}
	}
	return $file;
}






=head1 elements($self)

IN: object (self)
OUT: pointer to hash

Returns a pointer to a hash of all definitions to display

=cut

sub elements {
  my $self = shift;
  my $pascanDefs = $self->archive->scanDefinitions("ARRAY");
  my (%scanDefs,@list);
  # Attributes to display on table
	my @attributes = ("Code","Name","NotActive");

  my $sql = "select Inhalt from parameter where Name='ScannenDefinitionen' ".
	          "and Art LIKE 'parameter' and Tabelle LIKE 'parameter' limit 1";
	my @row = $self->archive->db->dbh->selectrow_array($sql);
	my @scandefs = split("\r\n",$row[0]);
	
	my $c=0;
  foreach my $def (@$pascanDefs) {
	  push @list,$def;
    $scanDefs{$def}{'Name'} = $def;
		my $def1 = $scandefs[$c];
		my @vals2 = split(";",$def1);
    $scanDefs{$def}{'Code'} = $vals2[22];
		my $notactive = $vals2[18];
    $notactive = "" if $notactive != 1;		
    $scanDefs{$def}{'NotActive'} = $notactive;
		if ($c>0) {
      $scanDefs{$def}{'delete'}=1;
		} else {
			$scanDefs{$def}{'delete'}=0;
		}
		$scanDefs{$def}{'copy'} = 1;
		$scanDefs{$def}{'update'} = 1;
		$c++;
  }
	$scanDefs{'paste'} = 1;
  $scanDefs{'new'} = 1;
	$scanDefs{'list'}=\@list;
	$scanDefs{'attributes'} = \@attributes;
  return \%scanDefs;
}






=head1 delete($self,$cgiO)
	
IN: object (self)
    object (CGI.pm)
OUT: -

Delete a definition from the database thru APCL

=cut

sub delete {
  my $self = shift;
  my $cgiO = shift;
  my $archiveO = $self->archive;
  my $id = $cgiO->param("id");
  if (defined $id) {
    $archiveO->parameter("ScannenDefinitionen")
	           ->attribute("Inhalt")
	           ->scan($id)
	           ->remove;
  }
}






=head1 archive($self)

IN: object (self)
OUT: object (Archivista::BL::Archive)

Return the APCL object

=cut

sub archive {
  my $self = shift;
  return $self->{'archiveO'};
}




=head1 formRec($art)

Give back a list with the names (numbers) or a hash (numbers and names)

=cut

sub formRec {
  my $self = shift;
	my $art = shift;
	my $sql = "select Art,Name,Inhalt from parameter where ".
	          "Art LIKE 'FormRecognition__' and Tabelle='archiv' order by Art";
	my $prows = $self->archive->db->dbh->selectall_arrayref($sql);
	my (@nrs,@names,%hash);
	push @nrs,"FormRecognition00";
	push @names,$self->archive->lang->{'NO2'};
	foreach my $prow (@$prows) {
	  push @nrs, $$prow[0];
	  push @names, $$prow[1];
	}
	if ($art eq "ARRAY") {
	  return \@nrs;
	} else {
		my $c=0;
	  foreach (@nrs) {
		  $hash{$_}=$names[$c];
			$c++;
		}
		return \%hash;
	}
}


1;

__END__

=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: ScanDefAdministration.pm,v $
# Revision 1.4  2010/03/04 15:02:52  upfister
# Updated code (active for scan definitions is on, not active most be set)
#
# Revision 1.3  2010/03/04 11:08:26  upfister
# Update for flexible scan definitions
#
# Revision 1.2  2008/11/24 12:49:09  upfister
# Adding threshold/Gamma
#
# Revision 1.1.1.1  2008/11/09 09:21:03  upfister
# Copy to sourceforge
#
# Revision 1.11  2008/04/25 08:42:07  up
# Bugs solved in copy/paste
#
# Revision 1.10  2008/04/03 07:23:39  up
# AutoCrop / Deskew
#
# Revision 1.9  2008/03/08 20:06:42  up
# Detect Doublefeed
#
# Revision 1.8  2007/07/27 04:02:29  up
# Copy scan defs over host
#
# Revision 1.7  2007/07/25 16:55:33  up
# JPEG/double feed
#
# Revision 1.6  2007/07/06 15:36:33  up
# Split page in the middle
#
# Revision 1.5  2007/06/12 09:49:37  rn
# Bug: Copy&Paste if there is already a Scandefinition with the Same name
#
# Revision 1.4  2007/05/31 14:44:42  rn
# Add copy&paste functionality to WebAdmin in
# ScanDefinition,OCRDefinition and SQLDefinition forms.
#
# Revision 1.3  2007/04/15 22:18:32  up
# Add form recognition parameter
#
# Revision 1.2  2007/02/19 15:56:29  up
# Threshold values
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.8  2006/11/07 17:08:38  up
# Changes for updating scan definitions
#
# Revision 1.7  2006/11/07 09:25:33  up
# Splitting new documents
#
# Revision 1.6  2006/11/06 12:27:24  up
# Changes for splitting documents
#
# Revision 1.5  2006/05/06 16:49:14  up
# Bugs: First document, scanning to another database
#
# Revision 1.4  2006/03/13 08:14:50  up
# OCR definitions now working correct, mask definition with language strings
#
# Revision 1.3  2006/02/19 17:20:29  up
# No global barcode recognition (scan def. based)
#
# Revision 1.2  2006/01/23 10:36:38  mw
# Einbau einer Combobox für Barcode und für OCR-Definitionen
#
# Revision 1.1  2005/11/29 18:23:48  ms
# Added POD
#
# Revision 1.4  2005/11/24 17:39:30  up
# Bugs from implementation autofields and multiple barcode definitions
#
# Revision 1.3  2005/11/24 04:07:43  up
# Modifications for different barcode definitions
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.7  2005/07/12 17:13:01  ms
# Entwicklung an BarcodeProcess
#
# Revision 1.6  2005/06/18 21:24:10  ms
# Bugfix 0.0.0.0 -> localhost
#
# Revision 1.5  2005/06/18 21:18:17  ms
# Bugfix auto-pilot
#
# Revision 1.4  2005/06/17 18:21:56  ms
# Implementation scan from webclient
#
# Revision 1.3  2005/06/15 17:37:56  ms
# Bugfix
#
# Revision 1.2  2005/06/15 15:48:31  ms
# *** empty log message ***
#
# Revision 1.1  2005/06/15 15:48:03  ms
# File added to project
