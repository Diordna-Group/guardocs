# Current revision $Revision: 1.8 $
# Latest change by $Author: upfister $ on $Date: 2009/11/12 14:22:02 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::DatabaseAdministration;

use strict;

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls,$archiveO)

	IN: class name
	    object (Archivista::BL::Archive APCL)
	OUT: object

	Constructor

=cut


use constant OCR_NONE => '';
use constant OCR_FR => "FineReader (ArchivistaBox AddOn)";
use constant OCR_TESS => "Tesseract 2.0 (OpenSource)";
use constant OCR_GNU => "Cuneiform 0.3 (OpenSource)";

use constant ENGINE_NONE => '';
use constant ENGINE_MYSQL => "MySQL";
use constant ENGINE_SPHINX => "Sphinx";

sub new {
  my $cls      = shift;
  my $archiveO = shift;    # Object of Archivista::BL::Archive (APCL)
  my $self     = {};

  bless $self, $cls;

  my @fields = (
    "hide_title_field",  
		"hide_exticons",
		"title_field_width",
    "publish_field_name",
		"filename",
		"versions",
		"versionkey",
		"anz_feldlisten",
		"showeditfield",
		"empty_field",
		"ocr",
    "pdf",
		"pdfsingle",
		"fulltext",
		"show_ocr",
		"empty_field",
		"show_fieldsocr",
		"hide_owner",
    "photo_mode",
		"download_link",
		"empty_field",
    "jpeg_quality",
    "jpeg_quality2",
    "preview_scaling",
		"office_images",
		"empty_field",
    "archive_sql",        
		"archive_mbyte",
    "archive_files",
		"empty_field",
		"access_log",
		"access_hash",
  );

  $self->{'archiveO'}   = $archiveO;
  $self->{'field_list'} = \@fields;

  return $self;
}

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash which defines all attribute required to manage the
	information described by this module

=cut

sub fields {
  my $self     = shift;
  my $cgiO     = shift;
  my $archiveO = $self->archive;
  my $langO    = $self->archive->lang;

  my $pauserDefinedAttributes = $archiveO->userDefinedAttributes;

  # Add en empty element
  unshift @$pauserDefinedAttributes, "";

  my (%fields);
  $fields{'list'}                       = $self->{'field_list'};
  $fields{'hide_title_field'}{'label'}  = $langO->string("HIDE_TITLE_FIELD");
  $fields{'hide_title_field'}{'name'}   = "hide_title_field";
  $fields{'hide_title_field'}{'type'}   = "checkbox";
  $fields{'hide_title_field'}{'update'} = 1;

  $fields{'hide_exticons'}{'label'}  = $langO->string("HIDE_EXTICONS");
  $fields{'hide_exticons'}{'name'}   = "hide_exticons";
  $fields{'hide_exticons'}{'type'}   = "checkbox";
  $fields{'hide_exticons'}{'update'} = 1;

  $fields{'title_field_width'}{'label'}  = $langO->string("TITLE_FIELD_WIDTH");
  $fields{'title_field_width'}{'name'}   = "title_field_width";
  $fields{'title_field_width'}{'type'}   = "textfield";
  $fields{'title_field_width'}{'update'} = 1;

  $fields{'anz_feldlisten'}{'label'}  = $langO->string("MAX_FIELDLIST");
  $fields{'anz_feldlisten'}{'name'}   = "anz_feldlisten";
  $fields{'anz_feldlisten'}{'type'}   = "textfield";
  $fields{'anz_feldlisten'}{'update'} = 1;

  $fields{'publish_field_name'}{'label'} = $langO->string("PUBLISH_FIELD_NAME");
  $fields{'publish_field_name'}{'name'}  = "publish_field_name";
  $fields{'publish_field_name'}{'type'}  = "select";
  $fields{'publish_field_name'}{'array_values'} = $pauserDefinedAttributes;
  $fields{'publish_field_name'}{'update'}       = 1;

  $fields{'filename'}{'label'} = $langO->string("FILENAME");
  $fields{'filename'}{'name'}  = "filename";
  $fields{'filename'}{'type'}  = "select";
  $fields{'filename'}{'array_values'} = $pauserDefinedAttributes;
  $fields{'filename'}{'update'}       = 1;

  $fields{'versions'}{'label'} = $langO->string("VERSIONS");
  $fields{'versions'}{'name'}  = "versions";
  $fields{'versions'}{'type'}  = "select";
  $fields{'versions'}{'array_values'} = $pauserDefinedAttributes;
  $fields{'versions'}{'update'}       = 1;

  $fields{'versionkey'}{'label'} = $langO->string("VERSIONKEY");
  $fields{'versionkey'}{'name'}  = "versionkey";
  $fields{'versionkey'}{'type'}  = "select";
  $fields{'versionkey'}{'array_values'} = $pauserDefinedAttributes;
  $fields{'versionkey'}{'update'}       = 1;

  $fields{'showeditfield'}{'label'}  = $langO->string("SHOW_EDIT_FIELD");
  $fields{'showeditfield'}{'name'}   = "showeditfield";
  $fields{'showeditfield'}{'type'}   = "checkbox";
  $fields{'showeditfield'}{'update'} = 1;

  my @ocr = (OCR_NONE,OCR_FR,OCR_TESS,OCR_GNU);
  $fields{'ocr'}{'label'}  = $langO->string("OCR_RECOGNITION");
  $fields{'ocr'}{'name'}   = "ocr_recognition";
  $fields{'ocr'}{'type'}   = "select";
  $fields{'ocr'}{'array_values'} = \@ocr;
  $fields{'ocr'}{'update'} = 1;

  $fields{'pdf'}{'label'}  = $langO->string("PDF_FILES_ON_OCR");
  $fields{'pdf'}{'name'}   = "pdf_files";
  $fields{'pdf'}{'type'}   = "checkbox";
  $fields{'pdf'}{'update'} = 1;

  $fields{'pdfsingle'}{'label'}  = $langO->string("PDFWHOLEDOC");
  $fields{'pdfsingle'}{'name'}   = "pdfsingle";
  $fields{'pdfsingle'}{'type'}   = "checkbox";
  $fields{'pdfsingle'}{'update'} = 1;

  my @engine = (ENGINE_NONE,ENGINE_MYSQL,ENGINE_SPHINX);
  $fields{'fulltext'}{'label'}  = $langO->string("SEARCH_FULLTEXT");
  $fields{'fulltext'}{'name'}   = "fulltext";
  $fields{'fulltext'}{'type'}   = "select";
  $fields{'fulltext'}{'array_values'} = \@engine;
  $fields{'fulltext'}{'update'} = 1;
	
  $fields{'show_ocr'}{'label'}  = $langO->string("SHOW_OCR");
  $fields{'show_ocr'}{'name'}   = "show_ocr";
  $fields{'show_ocr'}{'type'}   = "checkbox";
  $fields{'show_ocr'}{'update'} = 1;
	
  $fields{'show_fieldsocr'}{'label'}  = $langO->string("SHOW_FIELDSOCR");
  $fields{'show_fieldsocr'}{'name'}   = "show_fieldsocr";
  $fields{'show_fieldsocr'}{'type'}   = "checkbox";
  $fields{'show_fieldsocr'}{'update'} = 1;

  $fields{'hide_owner'}{'label'}  = $langO->string("HIDE_OWNER");
  $fields{'hide_owner'}{'name'}   = "hide_owner";
  $fields{'hide_owner'}{'type'}   = "checkbox";
  $fields{'hide_owner'}{'update'} = 1;

  $fields{'download_link'}{'label'}  = $langO->string("DOWNLOAD_LINK");
  $fields{'download_link'}{'name'}   = "download_link";
  $fields{'download_link'}{'type'}   = "checkbox";
  $fields{'download_link'}{'update'} = 1;
	
  $fields{'photo_mode'}{'label'}  = $langO->string("PHOTO_MODE_ON_LOGIN");
  $fields{'photo_mode'}{'name'}   = "photo_mode";
  $fields{'photo_mode'}{'type'}   = "checkbox";
  $fields{'photo_mode'}{'update'} = 1;

  $fields{'jpeg_quality'}{'label'}  = $langO->string("JPEG_QUALITY");
  $fields{'jpeg_quality'}{'name'}   = "jpeg_quality";
  $fields{'jpeg_quality'}{'type'}   = "textfield";
  $fields{'jpeg_quality'}{'update'} = 1;

  $fields{'jpeg_quality2'}{'label'}  = $langO->string("JPEG_QUALITY2");
  $fields{'jpeg_quality2'}{'name'}   = "jpeg_quality2";
  $fields{'jpeg_quality2'}{'type'}   = "checkbox";
  $fields{'jpeg_quality2'}{'update'} = 1;

  $fields{'preview_scaling'}{'label'}  = $langO->string("PREVIEW_SCALING");
  $fields{'preview_scaling'}{'name'}   = "preview_scaling";
  $fields{'preview_scaling'}{'type'}   = "textfield";
  $fields{'preview_scaling'}{'update'} = 1;

  $fields{'office_images'}{'label'}  = $langO->string("OFFICE_IMAGES");
  $fields{'office_images'}{'name'}   = "office_images";
  $fields{'office_images'}{'type'}   = "checkbox";
  $fields{'office_images'}{'update'} = 1;

  $fields{'archive_sql'}{'label'} =
  $langO->string("CONDITION_ARCHIVING") . " (SQL)";
  $fields{'archive_sql'}{'name'}   = "archive_sql";
  $fields{'archive_sql'}{'type'}   = "textfield";
  $fields{'archive_sql'}{'update'} = 1;

  $fields{'archive_mbyte'}{'label'} =
  $langO->string("ARCHIVE_SIZE") . " (MByte)";
  $fields{'archive_mbyte'}{'name'}   = "archive_mbyte";
  $fields{'archive_mbyte'}{'type'}   = "textfield";
  $fields{'archive_mbyte'}{'update'} = 1;

  $fields{'archive_files'}{'label'}  = $langO->string("ARCHIVE_FILES");
  $fields{'archive_files'}{'name'}   = "archive_files";
  $fields{'archive_files'}{'type'}   = "textfield";
  $fields{'archive_files'}{'update'} = 1;

  $fields{'access_log'}{'label'}  = $langO->string("ACCESS_LOG");
  $fields{'access_log'}{'name'}   = "access_log";
  $fields{'access_log'}{'type'}   = "checkbox";
  $fields{'access_log'}{'update'} = 1;

  $fields{'access_hash'}{'label'}  = $langO->string("ACCESS_HASH");
  $fields{'access_hash'}{'name'}   = "access_hash";
  $fields{'access_hash'}{'type'}   = "textfield";
  $fields{'access_hash'}{'update'} = 1;

  # In this form we won't the back button
  $fields{'displayBackFormButton'} = 0;

  my $hideTitleField =
    $archiveO->parameter("FeldTitel")->attribute("Inhalt")->value;

  my $hideExtIcons =
    $archiveO->parameter("HideExtIcons")->attribute("Inhalt")->value;
		
  my $titleFieldWidth =
    $archiveO->parameter("FeldBreite")->attribute("Inhalt")->value;
		
  my $publishFieldName =
    $archiveO->parameter("PublishField")->attribute("Inhalt")->value;

  my $filename =
    $archiveO->parameter("FILENAME")->attribute("Inhalt")->value;

  my $versions =
    $archiveO->parameter("VERSIONS")->attribute("Inhalt")->value;

  my $versionkey =
    $archiveO->parameter("VERSIONKEY")->attribute("Inhalt")->value;

  my $anz_feldlisten =
    $archiveO->parameter("FeldlistenAnzahl")->attribute("Inhalt")->value;

  my $showeditfield = 
	  $archiveO->parameter("NoRichEdit")->attribute("Inhalt")->value;

  my $ocrRecognition =
    $archiveO->parameter("JobsOCRRecognition")->attribute("Inhalt")->value;

  my $pdfFiles = $archiveO->parameter("PDFFiles")->attribute("Inhalt")->value;

	my $pdfsingle =
	  $archiveO->parameter("PDFWHOLEDOC")->attribute("Inhalt")->value;

	my $fulltext =
	  $archiveO->parameter("SEARCH_FULLTEXT")->attribute("Inhalt")->value;

	my $show_ocr =
	  $archiveO->parameter("SHOW_OCR")->attribute("Inhalt")->value;

	my $show_fieldsocr =
	  $archiveO->parameter("SHOW_FIELDSOCR")->attribute("Inhalt")->value;

	my $hide_owner =
	  $archiveO->parameter("HIDE_OWNER")->attribute("Inhalt")->value;
		
  my $photoMode = $archiveO->parameter("PhotoMode")->attribute("Inhalt")->value;
  my $archiveSQL =
    $archiveO->parameter("ArchivSQL")->attribute("Inhalt")->value;
  my $archiveMByte =
    $archiveO->parameter("ArchivMByte")->attribute("Inhalt")->value;
  my $archiveFiles =
    $archiveO->parameter("ArchivDateien")->attribute("Inhalt")->value;

  my $jpegQuality =
    $archiveO->box_parameter("JpegQuality")->attribute("Inhalt")->value;

  my $jpegQuality2 =
    $archiveO->box_parameter("JpegQuality2")->attribute("Inhalt")->value;

  my $prevScaling =
    $archiveO->box_parameter("PrevScaling")->attribute("Inhalt")->value;

  my $office_images =
    $archiveO->parameter("OfficeImages")->attribute("Inhalt")->value;

	my $accesslog =
	  $archiveO->parameter("ACCESS_LOG")->attribute("Inhalt")->value;

	my $download_link =
	  $archiveO->parameter("DOWNLOAD_LINK")->attribute("Inhalt")->value;
		
  $fields{'hide_title_field'}{'value'} = $hideTitleField;

  if ( defined $titleFieldWidth ) {
    $fields{'title_field_width'}{'value'} = $titleFieldWidth;
  }
  else {
    $fields{'title_field_width'}{'value'} = 3000;
  }
  
	$fields{'hide_exticons'}{'value'} = $hideExtIcons;

  if ( defined $publishFieldName ) {
    $fields{'publish_field_name'}{'value'} = $publishFieldName;
  }

  if ( defined $filename ) {
    $fields{'filename'}{'value'} = $filename;
  }

  if ( defined $versions ) {
    $fields{'versions'}{'value'} = $versions;
  }

  if ( defined $versionkey ) {
    $fields{'versionkey'}{'value'} = $versionkey;
  }

  if ( defined $anz_feldlisten ) {
	  $anz_feldlisten=0 if $anz_feldlisten<0;
		$anz_feldlisten=9999 if $anz_feldlisten>9999;
    $fields{'anz_feldlisten'}{'value'} = $anz_feldlisten;
  }
  else {
    $fields{'anz_feldlisten'}{'value'} = 0;
  }

  if ( defined $showeditfield ) {
    $fields{'showeditfield'}{'value'} = $showeditfield;
  }
  else {
    $fields{'showeditfield'}{'value'} = 0;
  }

  if ( defined $pdfFiles ) {
    $fields{'pdf'}{'value'} = $pdfFiles;
  }
  else {
    $fields{'pdf'}{'value'} = 1;
  }

  if ( defined $pdfsingle ) {
    $fields{'pdfsingle'}{'value'} = $pdfsingle;
  }
  else {
    $fields{'pdfsingle'}{'value'} = 0;
  }

  $fields{'fulltext'}{'value'} = ENGINE_MYSQL;
  if ( defined $fulltext ) {
	  if ($fulltext==0) {
      $fields{'fulltext'}{'value'} = ENGINE_NONE;
		} elsif ($fulltext==1) {
      $fields{'fulltext'}{'value'} = ENGINE_MYSQL;
		} elsif ($fulltext==2) {
      $fields{'fulltext'}{'value'} = ENGINE_SPHINX;
		}
  }

  if ( defined $show_ocr ) {
    $fields{'show_ocr'}{'value'} = $show_ocr;
  } else {
    $fields{'show_ocr'}{'value'} = 0;
	}

  if ( defined $show_fieldsocr ) {
    $fields{'show_fieldsocr'}{'value'} = $show_fieldsocr;
  } else {
    $fields{'show_fieldsocr'}{'value'} = 0;
	}

  if ( defined $hide_owner ) {
    $fields{'hide_owner'}{'value'} = $hide_owner;
  } else {
    $fields{'hide_owner'}{'value'} = 0;
	}

  $fields{'ocr'}{'value'} = OCR_FR;
  if ( defined $ocrRecognition ) {
	  if ($ocrRecognition==0) {
      $fields{'ocr'}{'value'} = OCR_NONE;
		} elsif ($ocrRecognition==1) {
      $fields{'ocr'}{'value'} = OCR_FR;
		} elsif ($ocrRecognition==3) {
      $fields{'ocr'}{'value'} = OCR_GNU
		} elsif ($ocrRecognition==2) {
      $fields{'ocr'}{'value'} = OCR_TESS
		}
  }

  if ( defined $download_link ) {
    $fields{'download_link'}{'value'} = $download_link;
  } else {
    $fields{'download_link'}{'value'} = 1;
	}

  if (defined $accesslog) {
	  $fields{access_log}{value} = $accesslog;
	} else {
	  $fields{access_log}{value} = 0;
	}
	$fields{access_hash}{value} = "";
	
  $fields{'photo_mode'}{'value'} = $photoMode;

  if ( defined $archiveSQL ) {
    $fields{'archive_sql'}{'value'} = $archiveSQL;
  }

  if ( defined $archiveMByte ) {
    $fields{'archive_mbyte'}{'value'} = $archiveMByte;
  }
  else {
    $fields{'archive_mbyte'}{'value'} = 600;
  }

  if ( defined $jpegQuality ) {
    $fields{'jpeg_quality'}{'value'} = $jpegQuality;
  }
  else {
    $fields{'jpeg_quality'}{'value'} = 33;
  }

  if ( defined $jpegQuality2 ) {
    $fields{'jpeg_quality2'}{'value'} = $jpegQuality2;
  }
  else {
    $fields{'jpeg_quality2'}{'value'} = 0;
  }

  if ( defined $prevScaling ) {
    $fields{'preview_scaling'}{'value'} = $prevScaling;
  }
  else {
    $fields{'preview_scaling'}{'value'} = 50;
  }

  if ( defined $office_images ) {
    $fields{'office_images'}{'value'} = $office_images;
  } else {
    $fields{'office_images'}{'value'} = 0;
	}

  if ( defined $archiveFiles ) {
    $fields{'archive_files'}{'value'} = $archiveFiles;
  }
  else {
    $fields{'archive_files'}{'value'} = 1000;
  }

  return \%fields;
}

# -----------------------------------------------

=head1 save($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Save the data about a definition to the database. This method handles inserts
	and updates.

=cut

sub save {
  my $self     = shift;
  my $cgiO     = shift;            # Object of CGI.pm
  my $archiveO = $self->archive;

  my $hideTitleField     = $cgiO->param("hide_title_field");
  my $hideExtIcons       = $cgiO->param("hide_exticons");
  my $titleFieldWidth    = $cgiO->param("title_field_width");
  my $publishFieldName   = $cgiO->param("publish_field_name");
  my $filename           = $cgiO->param("filename");
  my $versions           = $cgiO->param("versions");
  my $versionkey         = $cgiO->param("versionkey");
  my $anz_feldlisten     = $cgiO->param("anz_feldlisten");
  my $showeditfield      = $cgiO->param("showeditfield");
  my $photoMode          = $cgiO->param("photo_mode");
  my $pdfFiles           = $cgiO->param("pdf_files");
	my $pdfsingle          = $cgiO->param("pdfsingle");
	my $fulltext           = $cgiO->param("fulltext");
	my $show_ocr           = $cgiO->param("show_ocr");
	my $show_fieldsocr     = $cgiO->param("show_fieldsocr");
	my $hide_owner         = $cgiO->param("hide_owner");
  my $ocrRecognition     = $cgiO->param("ocr_recognition");
  my $download_link      = $cgiO->param("download_link");
  my $archiveSQL         = $cgiO->param("archive_sql");
  my $archiveMByte       = $cgiO->param("archive_mbyte");
  my $archiveFiles       = $cgiO->param("archive_files");
  my $jpegQuality        = $cgiO->param("jpeg_quality");
  my $jpegQuality2       = $cgiO->param("jpeg_quality2");
  my $prevScaling        = $cgiO->param("preview_scaling");
  my $office_images      = $cgiO->param("office_images");
	my $accesslog          = $cgiO->param("access_log");
	my $accesshash         = $cgiO->param("access_hash");

  $hideTitleField = 0 if ( !defined $hideTitleField );
  $hideExtIcons = 0 if ( !defined $hideExtIcons );
  $showeditfield = 0 if ( !defined $showeditfield );
	
  my $ocr = 0; 
	if ($ocrRecognition eq OCR_FR) {
	  $ocr = 1;
	} elsif ($ocrRecognition eq OCR_GNU) {
	  $ocr = 3;
	} elsif ($ocrRecognition eq OCR_TESS) {
	  $ocr = 2;
	}
	
  $anz_feldlisten     = 0 if ( !defined $anz_feldlisten );
  $pdfFiles           = 0 if ( !defined $pdfFiles );
  $pdfsingle          = 0 if ( !defined $pdfsingle );
  $photoMode          = 0 if ( !defined $photoMode );
	$accesslog          = 0 if ( !defined $accesslog);
	$fulltext           = 0 if ( !defined $fulltext);
	$show_ocr           = 0 if ( !defined $show_ocr);
	$show_fieldsocr     = 0 if ( !defined $show_fieldsocr);
	$hide_owner         = 0 if ( !defined $hide_owner);
	$download_link      = 0 if ( !defined $download_link);
	$jpegQuality2       = 0 if ( !defined $jpegQuality2);
  $office_images      = 0 if ( !defined $office_images );

  $archiveO->parameter("FeldTitel")->attribute("Inhalt")
    ->value($hideTitleField);
  $archiveO->parameter->update;

  $archiveO->parameter("HideExtIcons")->attribute("Inhalt")
    ->value($hideExtIcons);
  $archiveO->parameter->update;

  $archiveO->parameter("FeldlistenAnzahl")->attribute("Inhalt")
    ->value($anz_feldlisten);
  $archiveO->parameter->update;
	
  $archiveO->parameter("FeldBreite")->attribute("Inhalt")
    ->value($titleFieldWidth);
  $archiveO->parameter->update;

  $archiveO->parameter("NoRichEdit")->attribute("Inhalt")
    ->value($showeditfield);
  $archiveO->parameter->update;

  $archiveO->parameter("JobsOCRRecognition")->attribute("Inhalt")
    ->value($ocr);
  $archiveO->parameter->update;
  $archiveO->parameter("PublishField")->attribute("Inhalt")
    ->value($publishFieldName);
  $archiveO->parameter->update;

	$archiveO->parameter("FILENAME")->attribute("Inhalt")
    ->value($filename);
  $archiveO->parameter->update;

	$archiveO->parameter("VERSIONS")->attribute("Inhalt")
    ->value($versions);
  $archiveO->parameter->update;

	$archiveO->parameter("VERSIONKEY")->attribute("Inhalt")
    ->value($versionkey);
  $archiveO->parameter->update;

  $archiveO->parameter("PhotoMode")->attribute("Inhalt")->value($photoMode);
  $archiveO->parameter->update;
  $archiveO->parameter("PDFFiles")->attribute("Inhalt")->value($pdfFiles);
  $archiveO->parameter->update;
  $archiveO->parameter("PDFWHOLEDOC")->attribute("Inhalt")->value($pdfsingle);
  $archiveO->parameter->update;
	my $t = $archiveO->parameter("SEARCH_FULLTEXT")->attribute("Inhalt")->value();
  my $text = 1; 
	if ($fulltext eq ENGINE_NONE) {
	  $text = 0;
	} elsif ($fulltext eq ENGINE_MYSQL) {
	  $text = 1;
	} elsif ($fulltext eq ENGINE_SPHINX) {
	  $text = 2;
	}
  $archiveO->parameter("SEARCH_FULLTEXT")
	                     ->attribute("Inhalt")->value($text);
  $archiveO->parameter->update;
	
	if ($text==2 && $t != $text) { # only update if it was changed
	  if (!-e '/tmp/sphinx.wrk') {
		  if ($archiveO->db->host eq "localhost") {
        my $config = Archivista::Config->new;
        my $host = $config->get("MYSQL_HOST");
        my $db = $config->get("MYSQL_DB");
        my $user = $config->get("MYSQL_UID");
        my $pw = $config->get("MYSQL_PWD");
        undef $config;
		    my $dbh1 = $archiveO->db->sudbh;
        my $sql = "INSERT INTO archivista.jobs SET status=110,job='WEBCONF',".
               "host=".$dbh1->quote($host).",db=".$dbh1->quote($db).",".
               "user=".$dbh1->quote($user).",pwd=".$dbh1->quote($pw);
			  $dbh1->do($sql);
				my @row = $dbh1->selectrow_array("SELECT LAST_INSERT_ID()");
        $sql = "INSERT INTO archivista.jobs_data SET jid=$row[0],".
               "param='WEBC_MODE',value='SPHINX_INDEX'";
				$dbh1->do($sql);
        $sql = "UPDATE archivista.jobs SET status=100 where id=$row[0]";
				$dbh1->do($sql);
			} else {
		    print STDERR "sphinx indexer only at localhost allowed...\n";
			}
		} else {
		  print STDERR "sphinx indexer already in progress...\n";
		}
	}
	
  $archiveO->parameter("SHOW_OCR")
	                     ->attribute("Inhalt")->value($show_ocr);
  $archiveO->parameter->update;

  $archiveO->parameter("SHOW_FIELDSOCR")
	                     ->attribute("Inhalt")->value($show_fieldsocr);
  $archiveO->parameter->update;

  $archiveO->parameter("HIDE_OWNER")
	                     ->attribute("Inhalt")->value($hide_owner);
  $archiveO->parameter->update;
	
  $archiveO->parameter("DOWNLOAD_LINK")
	                     ->attribute("Inhalt")->value($download_link);
  $archiveO->parameter->update;
	
  $archiveO->parameter("ArchivSQL")->attribute("Inhalt")->value($archiveSQL);
  $archiveO->parameter->update;
  $archiveO->parameter("ArchivMByte")->attribute("Inhalt")
    ->value($archiveMByte);
  $archiveO->parameter->update;
  $archiveO->parameter("ArchivDateien")->attribute("Inhalt")
    ->value($archiveFiles);
  $archiveO->parameter->update;
  $archiveO->box_parameter("JpegQuality")->attribute("Inhalt")
    ->value($jpegQuality);
  $archiveO->parameter->update;
  $archiveO->box_parameter("JpegQuality2")->attribute("Inhalt")
    ->value($jpegQuality2);
  $archiveO->box_parameter->update;
  $archiveO->box_parameter("PrevScaling")->attribute("Inhalt")
    ->value($prevScaling);
  $archiveO->box_parameter->update;
  $archiveO->parameter("OfficeImages")->attribute("Inhalt")
    ->value($office_images);
  $archiveO->parameter->update;
	
	my $checkok=0;
	if ($accesslog==0) {
	  my $dbh = $archiveO->db->dbh;
		if ($archiveO->db->host eq "localhost") {
		  $dbh = $archiveO->db->sudbh;
		}
		my $sql = "select hash,id from access order by id limit 1";
		my @row = $dbh->selectrow_array($sql);
		my $hash = $row[0];
		my $id = $row[1];
		my $hash1 = substr($hash,0,8);
		if ($hash1 eq $accesshash && $id >0 && $accesshash ne "") {
      $sql = "update access set hash = '$hash"."a' where id=$id";
			$dbh->do($sql);
			$checkok=1;
	  } else {
	    $checkok=0;
		}
	} else {
	  $checkok=1;
	}
	if ($checkok==1) {
    $archiveO->parameter("ACCESS_LOG")->attribute("Inhalt")->value($accesslog);
    $archiveO->parameter->update;
	}
}

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive APCL)

	Return the connection to APCL

=cut

sub archive {
  my $self = shift;

  return $self->{'archiveO'};
}

1;

__END__

=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: DatabaseAdministration.pm,v $
# Revision 1.8  2009/11/12 14:22:02  upfister
# Strings for Note field and flexible table height (stored in cookie)
#
# Revision 1.7  2009/07/21 09:05:46  upfister
# Jpeg compression + backup file + bug in avimpexport2.pl (archivseten)
#
# Revision 1.6  2009/07/20 09:41:01  upfister
# Update for ocr recognition for splitted tables + not calling sphinx after
# setting change, only if it is enabled
#
# Revision 1.5  2009/05/25 16:59:49  upfister
# Sphinx updates (creating from scratch and in background)
#
# Revision 1.4  2009/05/20 23:11:39  upfister
# Update all indexes when activation a new one
#
# Revision 1.3  2009/05/18 06:52:14  upfister
# Add flag for sphinx search engine
#
# Revision 1.2  2009/04/01 09:50:23  upfister
# Add field filename to field
#
# Revision 1.1.1.1  2008/11/09 09:21:00  upfister
# Copy to sourceforge
#
# Revision 1.18  2008/10/13 02:05:36  up
# Cuneiform is nr. 3
#
# Revision 1.17  2008/08/16 20:52:12  up
# ArchiveExtended goes elsewhere
#
# Revision 1.16  2008/08/16 20:50:23  up
# extended_archive goes elsewhere
#
# Revision 1.15  2008/08/14 21:27:59  up
# Tesseract with Cuneiform changed
#
# Revision 1.14  2008/08/13 21:43:35  up
# Change to Cuneiform
#
# Revision 1.13  2008/07/28 16:24:35  up
# Extended folder structure
#
# Revision 1.12  2008/04/02 22:26:47  up
# Extended icons
#
# Revision 1.11  2007/07/21 04:07:12  up
# Add Tesseract selection
#
# Revision 1.10  2007/07/07 16:55:52  up
# Separation of form is different
#
# Revision 1.9  2007/07/07 06:09:27  up
# Add flag for open source ocr
#
# Revision 1.8  2007/06/06 12:58:08  rn
# Changes for max. Elments in Drop-Down
#
# Revision 1.7  2007/03/30 09:13:41  up
# Switch on/off Downlaod-Link
#
# Revision 1.6  2007/03/28 19:45:43  up
# Show/hide download link
#
# Revision 1.5  2007/03/19 02:51:09  up
# Add fields for hiding owner and viewing ocr text
#
# Revision 1.4  2007/02/26 22:23:10  up
# Add check for switch off access log
#
# Revision 1.3  2007/02/23 23:22:04  up
# Enable/Disable search fulltext field
#
# Revision 1.2  2007/02/13 14:54:47  up
# Add entry for access log table
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.10  2006/05/18 10:43:14  up
# Default value for pdf processing (single pages)
#
# Revision 1.9  2006/05/17 20:55:06  up
# Adding all single files in one pdf file
#
# Revision 1.8  2006/03/21 10:50:01  up
# Check for jobs while before shutdown
#
# Revision 1.7  2006/02/19 17:20:29  up
# No global barcode recognition (scan def. based)
#
# Revision 1.6  2006/01/31 15:06:09  mw
# Added two fields: delete_input and archive_files.
#
# Revision 1.5  2006/01/17 11:01:23  mw
# Defaultwert für JpegQuality auf 33 gesetzt.
#
# Revision 1.3  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.2  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.6  2005/07/14 12:20:18  ms
# Added JobsBarcodeRecognition checkbox
#
# Revision 1.5  2005/06/17 18:21:56  ms
# Implementation scan from webclient
#
# Revision 1.4  2005/06/10 17:37:14  ms
# Remove publish menu item
#
# Revision 1.3  2005/06/08 16:57:01  ms
# Fertigstellung Archiv verwalten und Publizieren
#
# Revision 1.2  2005/05/27 15:43:38  ms
# Entwicklung an database administration
#
# Revision 1.1  2005/04/21 16:40:47  ms
# Files added to project
#
