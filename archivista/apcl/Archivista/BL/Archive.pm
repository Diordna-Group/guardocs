# Current revision $Revision: 1.3 $
# Latest change by $Author: upfister $ on $Date: 2009/09/07 10:21:28 $

package Archivista::BL::Archive;

use strict;

use vars qw ( $VERSION );

use Archivista::Config;
use Archivista::BL::Document;
use Archivista::BL::User;
use Archivista::BL::Parameter;
use Archivista::BL::Languages;
use Archivista::BL::Application;
use Archivista::DL::DB;
use Archivista::DL::Archive;
use Archivista::Util::Collection;
use Archivista::Util::IO;
use Archivista::Util::Session;
use Archivista::Util::FS;
use Archivista::Util::Jobs;

$VERSION = '$Revision: 1.3 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init {
  my $self = shift;
  my $access = shift;	      # Can be a session id or an archive name
  my $host = shift;
  my $uid = shift;
  my $pwd = shift;
  my $langCode = shift;
  my ($database);
	
  if (length($access) == 32) {
    # PLEASE NOTE: we can't use database names of 32 bytes length!
    # We have a session id as access variable
    my $session = Archivista::Util::Session->check($access);
    # Check if the session exists
    if (defined $session) {
    	$session->read;
     	$host = $session->host;
     	$database = $session->db;
     	$uid = $session->user;
     	$pwd = $session->password;
     	$langCode = $session->language;
      $self->{'session'} = $session;
	    $self->{'archive_name'} = $database;
    }
  } elsif (defined $access) {
    # In this case we open a new session
    $database = $access;
    $self->{'session'} = Archivista::Util::Session->open(
		                       $database,$host,$uid,$pwd,$langCode);
    $self->{'archive_name'} = $database;
  }
	
  $self->{'db'} = Archivista::DL::DB->new($database,$host,$uid,$pwd);
  $self->{'document_collection'} = Archivista::Util::Collection->new;
  $self->{'user_collection'} = Archivista::Util::Collection->new;
  $self->{'parameter_collection'} = Archivista::Util::Collection->new;
  $self->{'application'} = Archivista::BL::Application->new($self->{'db'});
  $self->{'lang_code'} = $langCode;

  $self->_exception();
}

# -----------------------------------------------

sub _create
  {
    my $self = shift;
    my $archiveName = shift;
    my $cpDataFromArchive = shift;
    my $host = shift;
    my $uid = shift;
    my $pwd = shift;

    Archivista::DL::DB->create($archiveName,$cpDataFromArchive,$host,$uid,$pwd);
  
    $self->_exception();
  }

# -----------------------------------------------

sub _configure
  {
    my $self = shift;
    my $archiveName = shift;
    my $cpDataFromArchive = shift;
    my $config = Archivista::Config->new;
	
    if (defined $cpDataFromArchive) {
      # 2-dim array[n][3]
      my $pausers = $self->users;
      $self->grant($pausers);
    } else {
      # Create SYSOP user
      $self->user("localhost","SYSOP","",255);
      Archivista::BL::Parameter->load($self,$archiveName);
      Archivista::Util::FS->createImageFoldersForArchive($archiveName);
    }

    $self->_exception();
  }

# -----------------------------------------------

sub _documentCollection
  {
    my $self = shift;
    my $documentId = shift;
    my $document = shift;

    if (defined $document) {
      $self->collection("document")->element($documentId,$document);	
    } else {
      return $self->collection("document")->element($documentId);
    }
  }

# -----------------------------------------------

sub _userCollection
  {
    my $self = shift;
    my $userId = shift;
    my $user = shift;

    if (defined $user) {
      $self->collection("user")->element($userId,$user);
    } else {
      return $self->collection("user")->element($userId);
    }
  }

# -----------------------------------------------

sub _parameterCollection
  {
    my $self = shift;
    my $parameterId = shift;
    my $parameter = shift;

    if (defined $parameter) {
      $self->collection("parameter")->element($parameterId,$parameter);
    } else {
      return $self->collection("parameter")->element($parameterId);
    }
  }

# -----------------------------------------------

sub _exception
  {
    my $self = shift;

    if (length($@) > 0) {
      my $exception = $@;
      my $config = Archivista::Config->new;
      my $io = Archivista::Util::IO->new;
      $io->append($config->get("LOG_FILE"),$exception);
      undef $@;
      #delete $self->{'db'};
    }
  }

# -----------------------------------------------
# PUBLIC METHODS

sub load
  {
    my $cls = shift;
    my $access = shift;	      # Can be a session id or an archive name
    my $host = shift;
    my $uid = shift;
    my $pwd = shift;
    my $lang = shift;
    my $self = {};

    bless $self, $cls;

    $self->_init($access,$host,$uid,$pwd,$lang);

    return $self;
  }

# -----------------------------------------------

sub create
  {
    my $cls = shift;
    my $archiveName = shift;
    my $cpDataFromArchive = shift;
    my $host = shift;
    my $uid = shift;
    my $pwd = shift;
    my $sid = shift;
    my $self = {};

    bless $self, $cls;
 
    $self->_create($archiveName,$cpDataFromArchive,$host,$uid,$pwd);
    $self->_init($archiveName,$host,$uid,$pwd,$sid);
    $self->_configure($archiveName,$cpDataFromArchive);

    return $self;
  }

# -----------------------------------------------

sub drop
  {
    my $self = shift;
    my $archive = shift;
 
    # Revoke privileges of all users
    # $self->revoke($self->users);
	
    # Drop the database
    $self->db->drop($archive);

    # Unlink the image folders of the archive
    Archivista::Util::FS->unlinkImageFoldersForArchive($archive);
	
    $self->_exception();
  }

# -----------------------------------------------

sub alter
  {
    my $self = shift;
    my $palter = shift;
    my $db = $self->db;

    Archivista::DL::Archive->alter($db,$palter);
 
    $self->_exception();
  }

# -----------------------------------------------

sub userDefinedAttributes
  {
    my $self = shift;
    my $retDS = shift;

    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      return $self->db->userDefinedAttributes("ARRAY");
    } elsif (uc($retDS) eq "HASH") {
      return $self->db->userDefinedAttributes("HASH");
    }
  }

# -----------------------------------------------

sub describeAttribute
  {
    # Retrieve informations about an attribute
    # Name, Type (varchar,int,...), Length (1,11,..), Position after attribute
    my $self = shift;
    my $attribute = shift;

    my ($attributeType,$attributeLength,%attribute); 
    my $after = "Seiten";
    my $oudAttribute = "Seiten";
    my $paudAttributes = $self->db->userDefinedAttributes("ARRAY");
    my $phudAttributes = $self->db->userDefinedAttributes("HASH");
  
    # Get the attribute befor $attribute
    foreach my $udAttribute (@$paudAttributes) {
      $after = $oudAttribute if ($udAttribute eq $attribute);
      $oudAttribute = $udAttribute;
    }

    if ($$phudAttributes{$attribute} =~ /(.*?)(\()(.*)(\))/) {
      $attributeType = $1;
      $attributeLength = $3 if ($1 eq "varchar" || $1 eq "int");
    } else {
      $attributeType = $$phudAttributes{$attribute};
    }
	
    $attribute{$attribute}{'attribute_name'} = $attribute;
    $attribute{$attribute}{'attribute_type'} = $attributeType;
    $attribute{$attribute}{'attribute_length'} = $attributeLength;
    $attribute{$attribute}{'attribute_after'} = $after;

    return \%attribute;
  }

# -----------------------------------------------

sub disconnect
  {
    my $self = shift;

    $self->db->dbh->disconnect if defined $self->db->dbh;	
    $self->db->sudbh->disconnect if defined $self->db->sudbh;
    foreach my $key (keys %{$self}) {
      delete $self->{$key};	
    }
    undef $self;
  }

# -----------------------------------------------

sub curDocId
  {
    my $self = shift;
    my $documentId = shift;

    if (defined $documentId) {
      $self->{'cur_doc_id'} = $documentId;
    } else {
      return $self->{'cur_doc_id'};
    }
  }

# -----------------------------------------------

sub curUserId
  {
    my $self = shift;
    my $userId = shift;

    if (defined $userId) {
      $self->{'cur_user_id'} = $userId;
    } else {
      return $self->{'cur_user_id'};
    }
  }

# -----------------------------------------------

sub curParameterId
  {
    my $self = shift;
    my $parameterId = shift;

    if (defined $parameterId) {
      $self->{'cur_parameter_id'} = $parameterId;
    } else {
      return $self->{'cur_parameter_id'};
    }
  }

# -----------------------------------------------

sub name
  {
    my $self = shift;

    return $self->{'archive_name'};
  }

# -----------------------------------------------

sub collection
  {
    my $self = shift;
    my $collectionType = shift;

    return $self->{$collectionType.'_collection'};
  }

# -----------------------------------------------

sub db
  {
    my $self = shift;

    return $self->{'db'};
  }

# -----------------------------------------------

sub document
  {
    my $self = shift;
    my $documentId = shift;

    my $document;
	
    # Check if setter or getter method
    if (defined $documentId) {
      # Setter: load the requested document
      # and add the object to the collection
      $document = Archivista::BL::Document->new($self,$documentId);
      $self->_documentCollection($documentId,$document);
      $self->curDocId($documentId);
    } else {
      # Getter: check if there is a current selected document
      my $curDocId = $self->curDocId();
      if (defined $curDocId) {
	# There is a document, return the object
	$document = $self->_documentCollection($curDocId);
      } else {
	# There isn't a document, create a new one
	$document = Archivista::BL::Document->new($self);
	$documentId = $document->id;
	$self->_documentCollection($documentId,$document);
      }
    }

    $self->_exception();
	
    return $document;
  }

# -----------------------------------------------

sub user 
  {
    my $self = shift;
	
    my $user;
    my $nrOfParam = $#_;

    if ($nrOfParam < 0) {
      # No params -> get the user from the collection
      my $curUserId = $self->curUserId();
      $user = $self->_userCollection($curUserId);
    } elsif ($nrOfParam == 0 or $nrOfParam == 1) {
      my $userId;
      if ($nrOfParam == 0) {
	$userId = shift @_;
      } else {	
	# Two params -> host and username, retrieve the user id
	$user = Archivista::BL::User->new($self);
	$userId = $user->idByHostAndUser(@_);
      }
      $user = Archivista::BL::User->new($self,$userId);
      $self->_userCollection($userId,$user);
      $self->curUserId($userId);
    } elsif ($nrOfParam >= 2) {
      # Three params -> create a new user
      $user = Archivista::BL::User->new($self,undef,@_);
      $self->_userCollection($user->id,$user);
    }
	
    $self->_exception();
	
    return $user;
  }

# -----------------------------------------------

sub parameter_with_type
  {
    my $self = shift;
    my $parameterId = shift;
    my $type = shift;
    my $parameter;

    # Check if setter or getter method
    if (defined $parameterId) {
      # Setter: load the requested user
      # and add the object to the collection
      $parameter = Archivista::BL::Parameter->new($self,$type,$parameterId);
      $self->_parameterCollection($parameterId,$parameter);
      $self->curParameterId($parameterId);
    } else {
      # Getter: check if there is a current parameter
      my $curParameterId = $self->curParameterId();
      if (defined $curParameterId) {
	# There is a parameter, return the object
	$parameter = $self->_parameterCollection($curParameterId);
      } else {
	# There isn't a parameter, create a new one
	$parameter = Archivista::BL::Parameter->new($self,$type);
	$parameterId = $parameter->id;
	$self->_parameterCollection($parameterId,$parameter);
      }
    }
	
    $self->_exception();
	
    return $parameter;
  }

# -----------------------------------------------

sub box_parameter {

   my $self=shift;
   my $parameterId=shift;

   return $self->parameter_with_type($parameterId,'Archivistabox');
}

sub mask_parameter {

   my $self=shift;
	 my $parameterId=shift;

	 return $self->parameter_with_type($parameterId,$parameterId);
}

# -----------------------------------------------

sub parameter {

   my $self=shift;
   my $parameterId=shift;

   return $self->parameter_with_type($parameterId,'parameter');
}

# -----------------------------------------------

sub application
  {
    my $self = shift;
    my $applicationId = shift;
    my $application = $self->{'application'};
    my $lang = $self->lang;
	
    $application->id($applicationId) if (defined $applicationId);
    $application->lang($lang);

    return $application;
  }

# -----------------------------------------------

sub users
  {
    my $self = shift;

    return Archivista::BL::User->all($self);
  }

# -----------------------------------------------

sub archives
  {
    my $self = shift;

    my $db = $self->db;
	
    return Archivista::DL::Archive->all($db);
  }

# -----------------------------------------------

sub makeSelectDataFromParamList
  {
    my $self = shift;
    my $attr_name = shift;
    my $retDS = shift;

    $retDS="ARRAY" if !defined $retDS;

    my @idxlst;
		my $idx=0;

    my $anzahl=scalar @{$self->parameter($attr_name)
		                         ->attribute("Inhalt")
														 ->barcodes("ARRAY")};
								
		$anzahl--; # if we have a ocr definition, one minus
    if ($attr_name ne "OCRSets") {
		  # add a none value if we have a barcode
      push @idxlst,-1;
      $idx++;
			$anzahl++;
		}

    while ($idx<=$anzahl) {
      push @idxlst,$idx;
      $idx++;
    }
		
		if ($attr_name eq "OCRSets") {
      push @idxlst,26; # Erfasst
			push @idxlst,27; # Ausschliessen
		}

    if (uc($retDS) eq "ARRAY") {

      return \@idxlst;

    } else {

      my %valueHash;
      my $names=$self->parameter($attr_name)->attribute("Inhalt")->barcodes("ARRAY");
			my $counter=0;
			if ($attr_name ne "OCRSets") {
        $valueHash{-1}=$self->lang->string('NO2');
        $counter++;
			}

      for my $nm (@$names) {
	      $valueHash{$counter}=$nm;
        $counter++;
      }

			if ($attr_name eq "OCRSets") {
        $valueHash{26}=$self->lang->string('OCR_DONE');
        $valueHash{27}=$self->lang->string('OCR_EXCLUDE');
			}
      return \%valueHash;
    }
  }

# -----------------------------------------------

sub barcodeSelectData {

  my $self=shift;
  my $retDS=shift;

  return $self->makeSelectDataFromParamList("Barcodes",$retDS);
}


# -----------------------------------------------

sub ocrSelectData {

  my $self=shift;
  my $retDS=shift;

  return $self->makeSelectDataFromParamList("OCRSets",$retDS);
}






sub scanDefinitions {
  # POST: pointer to Hash{$defName} -> object of Archivsta::BL::Scan
  #                  Hash{$defName}{'delete'} -> 0/1
  #                  Hash{$defName}{'update'} -> 1
  #       OR
  # 			pointer to Array(DefName)
  # PLEASE NOTE: with my $scanDef = Hash{$defName} we can retrieve the
  # information about the scan definition, for example: $dpi = $scanDef->dpi;
  my $self = shift;
  my $retDS = shift;

  return $self->parameter("ScannenDefinitionen")
	            ->attribute("Inhalt")
							->scans($retDS);
}






sub ocrDefinitions
  {
    # POST: pointer to Hash{$defName} -> object of Archivsta::BL::OCR
    #                  Hash{$defName}{'delete'} -> 0/1
    #                  Hash{$defName}{'update'} -> 1
    #       OR
    # 			pointer to Array(DefName)
    # PLEASE NOTE: with my $ocrDef = Hash{$defName} we can retrieve the
    # information about the ocr definition, for example: $checkOrientation = $ocrDef->checkOrientation;
    my $self = shift;
    my $retDS = shift;

    return $self->parameter("OCRSets")->attribute("Inhalt")->ocrs($retDS);
  }

# -----------------------------------------------

sub ocrs 
  {
    my $self = shift;
    my $retDS = shift;

    $retDS eq "ARRAY" if !defined;

    if (uc($retDS) eq "ARRAY") {
      return $self->ocrDefinitions("ARRAY");
    } else {
      my $phocrdefs = $self->ocrDefinitions("HASH");
      my %lbvalues;
		
      $lbvalues{-1}="NO";
		
      while (my($key,$value)=each(%$phocrdefs)) {
	$lbvalues{$key}=$value->name;
      }
		
      return \%lbvalues;
    }
  }

# -----------------------------------------------

sub ocrlangs 
  {
    my $self = shift;
    my $retDS = shift;

    my $nrOfSupportedLanguages = 66;
    my (@ocrids, %ocrhash);

    $retDS eq "HASH" if !defined;

    for (my $idx = 0; $idx < $nrOfSupportedLanguages; $idx++) {
      my $id = sprintf "%03d", $idx;
      my $ocrlang = $self->lang->string('OCRLANG_'.$id);
      push @ocrids, $idx;
      $ocrhash{$idx} = $ocrlang;
    }
  
    # ms - set undef as default (first) value in the selection box 
    unshift @ocrids,-1;
    $ocrhash{-1} = $self->lang->string('NO2');

    if (uc($retDS) eq "ARRAY") {
      return \@ocrids;
    } else {
      return \%ocrhash;
    }
  }

# -----------------------------------------------

sub qualityDefs {

  my $self=shift;
  my $retDS=shift;

  if (uc($retDS) eq "ARRAY") {

    return [1,2,3];
  } else {

    my %quality_hash=(1 => $self->lang->string('BEST_QUALITY'), 
                      2 => $self->lang->string('NORMAL_QUALITY'), 
                      3 => $self->lang->string('LOW_QUALITY'));

    return \%quality_hash;
  }
}
# -----------------------------------------------

sub barcodeDefinitions
  {
    # The same as for scanDefinitions
    my $self = shift;
    my $retDS = shift;

    return $self->parameter("Barcodes")->attribute("Inhalt")->barcodes($retDS);
  }

# -----------------------------------------------

sub barcodePosition
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;

    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @barcodePosition = (0,1);
      return \@barcodePosition;
    } elsif (uc($retDS) eq "HASH") {
      my %barcodePosition;
      $barcodePosition{0} = $lang->string("AUTOMATIC");
      $barcodePosition{1} = $lang->string("MANUAL_WITH_SETTINGS");
      return \%barcodePosition;
    }
  }

# -----------------------------------------------

sub barcodeTypes
  {
    my $self = shift;
    my $retDS = shift;

    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @barcodeTypes = (1,2,3,4,5,6,7);
      return \@barcodeTypes;
    } elsif (uc($retDS) eq "HASH") {
      my %barcodeTypes;
      $barcodeTypes{1} = "Code39";
      $barcodeTypes{2} = "Code39 (Check)";
      $barcodeTypes{3} = "Code25";
      $barcodeTypes{4} = "Code25 (Check)";
      $barcodeTypes{5} = "EAN13";
      $barcodeTypes{6} = "Code128";
      $barcodeTypes{7} = "EAN8";
      return \%barcodeTypes;
    }
  }

# -----------------------------------------------

sub barcodeOrientation
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;
	
    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @barcodeOrientation = (1,2,3,4,5);
      return \@barcodeOrientation;
    } elsif (uc($retDS) eq "HASH") {
      my %barcodeOrientation;
      $barcodeOrientation{1} = $lang->string("LEFT_TO_RIGHT");
      $barcodeOrientation{2} = $lang->string("BOTTOM_TO_TOP");
      $barcodeOrientation{3} = $lang->string("RIGHT_TO_LEFT");
      $barcodeOrientation{4} = $lang->string("TOP_TO_BOTTOM");
      $barcodeOrientation{5} = $lang->string("LEFT_TO_RIGHT_DOWN");
      return \%barcodeOrientation;
    }
  }

# -----------------------------------------------

sub barcodeVerticalStretch
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;

    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @barcodeVerticalStretch = (0,1,2);
      return \@barcodeVerticalStretch;
    } elsif (uc($retDS) eq "HASH") {
      my %barcodeVerticalStretch;
      $barcodeVerticalStretch{0} = $lang->string("NO_CORRECTION");
      $barcodeVerticalStretch{1} = $lang->string("WITH_DOUBLE_HEIGHT");
      $barcodeVerticalStretch{2} = $lang->string("WITH_TRIPLE_HEIGHT");
      return \%barcodeVerticalStretch;
    }
  }

# -----------------------------------------------

sub barcodeProcessNumber
  {
    my $self = shift;
	
    my @barcodeProcessNumber = (1,2,3,4,5);

    return \@barcodeProcessNumber;
  }

# -----------------------------------------------

sub barcodeProcessLength
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;

    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @barcodeProcessLength;
      for (my $idx = 0; $idx <= 60; $idx++) {
	push @barcodeProcessLength, $idx;
      }
      return \@barcodeProcessLength;
    } elsif (uc($retDS) eq "HASH") {
      my %barcodeProcessLength;
      $barcodeProcessLength{0} = $lang->string("ALL");
      for (my $idx = 1; $idx <= 60; $idx++) {
	$barcodeProcessLength{$idx} = $idx;
      }
      return \%barcodeProcessLength;
    }
  }

# -----------------------------------------------

sub barcodeProcessAttributes
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;
    my $idx = 2;
	
    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my $paattributes = $self->db->userDefinedAttributes;
			# +1 is for DOKNR (Akte/Document) -> comes from hash
      my @attributes = (0 .. $#$paattributes + $idx + 1);
      return \@attributes;
    } elsif (uc($retDS) eq "HASH") {
      my %attributes;
      my $paattributes = $self->db->userDefinedAttributes;
      $attributes{0} = $lang->string("TITLE");
      $attributes{1} = $lang->string("DATE");
      foreach my $attribute (@$paattributes) {
      	$attributes{$idx} = $attribute;
	      $idx++;
      }
			# ducment is also available (docnr=barcode -> does already exists)
			$attributes{$idx} = $lang->string("DOKNR");
      return \%attributes;
    }
  }

# -----------------------------------------------

sub barcodeProcessStart
  {
    my $self = shift;
    my $retDS = shift;

    my @barcodeProcessStart;
    for (my $idx = 1 ; $idx <= 60; $idx++) {
      push @barcodeProcessStart, $idx;
    }
	
    return \@barcodeProcessStart;
  }

# -----------------------------------------------

sub barcodeProcessCharacter
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;

    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @barcodeProcessCharacter;
      for (my $idx = 0; $idx <= 60; $idx++) {
	push @barcodeProcessCharacter, $idx;
      }
      return \@barcodeProcessCharacter;
    } elsif (uc($retDS) eq "HASH") {
      my %barcodeProcessCharacter;
      $barcodeProcessCharacter{0} = $lang->string("ALL");
      for (my $idx = 1; $idx <= 60; $idx++) {
	$barcodeProcessCharacter{$idx} = $idx;
      }
      return \%barcodeProcessCharacter;
    }
  }

# -----------------------------------------------

sub barcodeNumberOf
  {
    my $self = shift;

    return 6;
  }

# -----------------------------------------------

sub barcodeProcessNumberOf
  {
    my $self = shift;

    return 8;
  }

# -----------------------------------------------

sub userLevelsByArray
  {
    my $self = shift;
	
    my @userLevels = (0,1,2,3,255);

    return \@userLevels;
  }

# -----------------------------------------------

sub userLevelsByHash
  {
    my $self = shift;
    my $lang = $self->lang;
	
    my %userLevel;
    $userLevel{0} = $lang->string("LEVEL_0");
    $userLevel{1} = $lang->string("LEVEL_1");
    $userLevel{2} = $lang->string("LEVEL_2");
    $userLevel{3} = $lang->string("LEVEL_3");
    $userLevel{255} = $lang->string("LEVEL_255");

    return \%userLevel;
  }

# -----------------------------------------------

sub attributeDataTypesByArray
  {
    my $self = shift;

    # This values must agree with Archivista::DL::Archive::attributeDbType!
    my @attributeDataTypes = ("varchar","int","double","datetime","tinyint");

    return \@attributeDataTypes;
  }

# -----------------------------------------------

sub attributeDataTypesByHash
  {
    my $self = shift;
    my $lang = $self->lang;

    # Hash keys are the same values as in sub attributeDataTypesByArray
    my %attributeDataTypes;
    $attributeDataTypes{'varchar'} = $lang->string("TEXT");
    $attributeDataTypes{'int'} = $lang->string("NUMBER_INTEGER");
    $attributeDataTypes{'double'} = $lang->string("NUMBER_DOUBLE");
    $attributeDataTypes{'datetime'} = $lang->string("DATETIME");
    $attributeDataTypes{'tinyint'} = $lang->string("YES_NO");

    return \%attributeDataTypes;
  }

# -----------------------------------------------

sub passwordTypes
  {
    my $self = shift;
    my $retDS = shift;		# Return datastructure (ARRAY or HASH)
    my $lang = $self->lang;
	
    $retDS = "ARRAY" if (! defined $retDS);
	
    if (uc($retDS) eq "ARRAY") {
      my @passwordTypes = (0,1,2,3);
      return \@passwordTypes;
    } elsif (uc($retDS) eq "HASH") {
      my %passwordTypes;
      $passwordTypes{'0'} = $lang->string("NO_PASSWORD");
      $passwordTypes{'1'} = $lang->string("NORMAL_LOGIN");
      $passwordTypes{'2'} = $lang->string("NEW_PASSWORD_EMPTY_NOT_ALLOWED");
      $passwordTypes{'3'} = $lang->string("NEW_PASSWORD_EMPTY_ALLOWED");
      return \%passwordTypes;
    }
  }

# -----------------------------------------------

sub imageTypes
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;
	
    $retDS = "ARRAY" if (! defined $retDS);
	
    if (uc($retDS) eq "ARRAY") {
      my @imageTypes = (1,2,3);
      return \@imageTypes;
    } elsif (uc($retDS) eq "HASH") {
      my %imageTypes;
      $imageTypes{'1'} = $lang->string("TIFF");
      $imageTypes{'2'} = $lang->string("PNG");
      $imageTypes{'3'} = $lang->string("JPEG");
      return \%imageTypes;
    }
  }

# -----------------------------------------------

sub scanTypes
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;

    $retDS = "ARRAY" if (! defined $retDS);
	
    if (uc($retDS) eq "ARRAY") {
      my @scanTypes = (0,1,2);
      return \@scanTypes;
    } elsif (uc($retDS) eq "HASH") {
      my %scanTypes;
      $scanTypes{'0'} = $lang->string("BLACK_WHITE");
      $scanTypes{'1'} = $lang->string("GRAYSCALES_8_BIT");
      $scanTypes{'2'} = $lang->string("COLOR_24_BIT");
      return \%scanTypes;
    }
  }

# -----------------------------------------------

sub scanRotations
  {
    my $self = shift;
    my $retDS = shift;
	
    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @scanRotations = (0,1,2,3);
      return \@scanRotations;
    } elsif (uc($retDS) eq "HASH") {
      my %scanRotations;
      $scanRotations{'0'} = "0°";
      $scanRotations{'1'} = "90°";
      $scanRotations{'2'} = "180°";
      $scanRotations{'3'} = "270°";
      return \%scanRotations;
    }
  }

# -----------------------------------------------

sub adfTypes
  {
    my $self = shift;
    my $retDS = shift;
	
    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @adfTypes = (1,-1,-2,-3);
      return \@adfTypes;
    } elsif (uc($retDS) eq "HASH") {
      my %adfTypes;
      $adfTypes{'1'} = "ADF simplex";
      $adfTypes{'-1'} = "ADF duplex";
      $adfTypes{'-2'} = "ADF 270/90°";
      $adfTypes{'-3'} = "ADF Rear";
      return \%adfTypes;
    }
  }

# -----------------------------------------------

sub lang
  {
    my $self = shift;
    my $langCode = shift;

    if (defined $langCode) {
      $self->{'lang_code'} = $langCode;
      $self->{'languages'} = Archivista::BL::Languages->new($self,$langCode);
    } elsif (defined $self->{'lang_code'}) {
      $self->{'languages'} = Archivista::BL::Languages->new($self,$self->{'lang_code'});
    } else {
      $self->{'lang_code'} = "de";
      $self->{'languages'} = Archivista::BL::Languages->new($self,$self->{'lang_code'});
    }

    return $self->{'languages'};
  }

# -----------------------------------------------

sub documentOwners
  {
    my $self = shift;
    my $retDS = shift; # Return data structure (ARRAY, HASH) array default
    my $db = $self->db;
    my $lang = $self->lang;	# Archivista::BL::Languages object
	
    $retDS = "ARRAY" if (! defined $retDS);
    $retDS = uc($retDS);

    my $pdocumentOwners = Archivista::DL::AvUser->documentOwners($db,$retDS);

    if ($retDS eq "ARRAY") {
      unshift @$pdocumentOwners, "";
    } elsif ($retDS eq "HASH") {
      $$pdocumentOwners{''} = $lang->string("ALL");
    }

    return $pdocumentOwners;
  }

# -----------------------------------------------

sub maskDefinitions
  {
    # POST: pointer to Hash(maskDefinitionNumber,maskDefinitionName)
    my $self = shift;
    my $db = $self->db;
    my $p1 = Archivista::DL::Parameter->maskDefinitions($db);
		return $p1;
  }

# -----------------------------------------------

sub maskNextDefinition
  {
    my $self = shift;
    my $db = $self->db;

    my $phdefinitions = Archivista::DL::Parameter->maskDefinitions($db);
    my @definitions = sort keys %$phdefinitions;
    my $maxDefinition = pop @definitions;
    my $maxIntDefinition = int $maxDefinition;
    my $nextIntDefinition = $maxIntDefinition + 1;
    my $nextDefinition = sprintf "%02d", $nextIntDefinition;

    return $nextDefinition;
  }

# -----------------------------------------------

sub maskFieldTypes
  {
    my $self = shift;
    my $lang = $self->lang;

    my %maskFieldTypes;
    # Please note: the keys for the hash must be the same as saved on FelderObj at
    # the fifth position (x;y;w;h;type;)
    $maskFieldTypes{'0'} = $lang->string("NORMAL");
    $maskFieldTypes{'4'} = $lang->string("DEFINITION");
    $maskFieldTypes{'5'} = $lang->string("1TON");
    $maskFieldTypes{'6'} = $lang->string("NUMBER_CODE");
    $maskFieldTypes{'7'} = $lang->string("MULTI");
    $maskFieldTypes{'3'} = $lang->string("TEXT_CODE");

    return \%maskFieldTypes;	
  }

# -----------------------------------------------

sub maskDefinition
  {
    # PRE: mask definition number (i.e. 00, 01 ...)
    # POST: pointer to Hash{$fieldName}{'field_name'}
    # 								 Hash{$fieldName}{'fieldObj object'}
    # 								 Hash{$fieldName}{'fieldTab object'}
    my $self = shift;
    my $definition = shift;
    my $retDS = shift;

    $retDS = "HASH" if (! defined $retDS);

    if (uc($retDS) eq "HASH") { 
      my %maskDefinition;
      # Retrieve data (FelderObj/FelderTab) for all fields of a definition 
      my $phfieldsObj = $self->mask_parameter("FelderObj".$definition)
	                           ->attribute("Inhalt")->fields;

      my $phfieldsTab = $self->mask_parameter("FelderTab".$definition)
			                       ->attribute("Inhalt")->fields("HASH");
      foreach my $fieldName (keys %$phfieldsObj) {
	      $maskDefinition{$fieldName}{'field_name'} = $fieldName;
	      $maskDefinition{$fieldName}{'field_object'} = $$phfieldsObj{$fieldName};
	      $maskDefinition{$fieldName}{'field_tab'} = $$phfieldsTab{$fieldName};
      }
      return \%maskDefinition;
    } else {
      return $self->mask_parameter
			  ("FelderTab".$definition)
	        ->attribute("Inhalt")->fields("ARRAY");
    }
  }

# -----------------------------------------------

sub userSqlDefinitions
  {
    my $self = shift;
    my $db = $self->db;
	
    return Archivista::DL::Parameter->userSqlDefinitions($db);
  }

# -----------------------------------------------

sub session
  {
    my $self = shift;

    return $self->{'session'};
  }

# -----------------------------------------------

sub jobs
  {
    my $self = shift;
    my $job = shift;

    $self->{'jobs'} = Archivista::Util::Jobs->new($self->{'db'});
    $self->{'jobs'}->param("job",$job);
	
    return $self->{'jobs'};
  }

# -----------------------------------------------

sub grant
  {
    my $self = shift;
    my $pausers = shift;	# 2-dim array[n][3] host,user,level

    Archivista::BL::User->grant($self,$pausers);
  }

# -----------------------------------------------

sub revoke
  {
    my $self = shift;
    my $pausers = shift;	# 2-dim array[n][3] host,user,level

    Archivista::BL::User->revoke($self,$pausers);
  }

# -----------------------------------------------

sub clearDocument
  {
    my $self = shift;
    my $documentId = shift;

    undef $self->{'cur_document_id'};
	
    if (defined $documentId) {
      $self->collection("document")->remove($documentId);
    } else {
      $self->collection("document")->clear;
    }
  }

# -----------------------------------------------

sub clearUser
  {
    my $self = shift;
    my $userId = shift;

    undef $self->{'cur_user_id'};
	
    if (defined $userId) {
      $self->collection("user")->remove($userId);
    } else {
      $self->collection("user")->clear;
    }
  }

# -----------------------------------------------

sub clearParameter
  {
    my $self = shift;
    my $parameterId = shift;

    undef $self->{'cur_parameter_id'};

    if (defined $parameterId) {
      $self->collection("parameter")->remove($parameterId);
    } else {
      $self->collection("parameter")->clear;
    }
  }

# -----------------------------------------------

sub hostIsSlave
  {
    my $self = shift;

    return $self->db->hostIsSlave();
  }

1;



# -----------------------------------------------

sub doublefeedTypes
  {
    my $self = shift;
    my $retDS = shift;
    my $lang = $self->lang;
	
    $retDS = "ARRAY" if (! defined $retDS);

    if (uc($retDS) eq "ARRAY") {
      my @ddTypes = (0,1,2,3,4);
      return \@ddTypes;
    } elsif (uc($retDS) eq "HASH") {
      my %ddTypes;
      $ddTypes{'0'} = $lang->string("SCAN_DOUBLEFEED_NONE");
      $ddTypes{'1'} = $lang->string("SCAN_DOUBLEFEED_DEFAULT");
      $ddTypes{'2'} = $lang->string("SCAN_DOUBLEFEED_THICKNESS");
      $ddTypes{'3'} = $lang->string("SCAN_DOUBLEFEED_LENGTH");
      $ddTypes{'4'} = $lang->string("SCAN_DOUBLEFEED_BOTH");
      return \%ddTypes;
    }
  }

# -----------------------------------------------




__END__

=head1 NAME

  Archivista::BL::Archive;

=head1 SYNOPSYS

  # Create a new document
  $archive->document;

  # Create a new document and return it's id
  my $curDocumentId = $archive->document->id;

  # Select the document given an id
  $archive->document($curDocumentId);

  # Create and select a document
  $archive->document($archive->document->id);

  # Set a current document
  $archive->curDocId($documentId);

  # Set a current user
  $archive->curUserId($userId);

  # Create a user
  my $userId = $archive->user(undef,"localhost","root","admin");

  # Select a user
  $archive->user($userId);
	
	# Clear the document collection
  $archive->clearDocument;

  # Remove a document from the document collection
  $archive->clearDocument($documentId);

  # Clear the user collection
  $archive->clearUser;

  # Remove a user from the user collection
  $archive->clearUser($userId);
	
=head1 DESCRIPTION

  This package provide methods to deal with documents, users and parameters

  Please note: the clearXY() methods are required to remove a selected object
  from the collection. For example if we select a document then we make some
  changes (for example to the attributes of the document), after we update these
  changes we have to remove the selected object from the collection befor we can
  perhaps create another document. 

=head1 DEPENDENCIES

  Archivista::BL::Document
  Archivista::BL::User
  Archivista::BL::Parameter
  Archivista::DL::DB
  Archivista::Util::Collection

=head1 EXAMPLE

  use Archivista;

  my $archive = Archivista->archive("averl","localhost","root","admin");

  $archive->document;
  my $documentId = $archive->document->id;
	
  my $userId = $archive->user(undef,"localhost","user","pass");
	$archive->user($userId);
	
=head1 TODO


=head1 AUTHOR

  Markus Stocker, Archivista GmbH Zurich

=cut

# Log record
# $Log: Archive.pm,v $
# Revision 1.3  2009/09/07 10:21:28  upfister
# Wront type declaration for ocr language definitions (hash instead of array)
#
# Revision 1.2  2009/08/16 23:34:13  upfister
# Small update in old class
#
# Revision 1.1.1.1  2008/11/09 09:19:20  upfister
# Copy to sourceforge
#
# Revision 1.5  2008/08/15 17:00:20  up
# Show error message when password is not ok
#
# Revision 1.4  2008/05/20 18:28:29  up
# Barcode orientation (left/right and top/bottom)
#
# Revision 1.3  2008/03/08 20:06:02  up
# Detect doublefeed
#
# Revision 1.2  2008/03/08 19:50:46  up
# Adding double feed control
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.17  2006/11/07 17:09:44  up
# Changes for scanning definitions
#
# Revision 1.16  2006/05/18 10:58:46  up
# Wrong label for ocr parameter (type of font: typogrpahic was courrier font)
#
# Revision 1.15  2006/03/27 10:26:18  up
# Mask definition again, rotation b/w images, barcode recognition (multiple
# barcodes)
#
# Revision 1.14  2006/03/13 08:14:50  up
# OCR definitions now working correct, mask definition with language strings
#
# Revision 1.13  2006/03/06 09:35:54  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.12  2006/02/19 17:23:43  up
# Changes in barcode recognition
#
# Revision 1.11  2006/02/09 17:45:57  mw
# Selection for the ADF-Raw Mode inserted.
#
# Revision 1.10  2006/01/24 22:27:13  mw
# Merge von Rev 1.8 und 1.9
#
# Revision 1.9  2006/01/24 20:41:40  mw
# mask_parameter behandelt die Parameter fuer Maskendefinitionen
#
# Revision 1.7  2006/01/17 10:16:03  mw
# Unterscheidung zwischen normalen Parametern (Art=parameter) und
# Boxparametern (Art=Archivistabox) wurde eingeführt
#
# Revision 1.6  2005/11/17 11:21:42  ms
# Implementing all OCR languages
#
# Revision 1.5  2005/11/15 12:28:03  ms
# Updates Herr Wolff
#
# Revision 1.4  2005/10/26 16:50:15  up
# *** empty log message ***
#
# Revision 1.3  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
#
# Revision 1.2  2005/07/19 18:22:47  ms
# Textcode has value 3 not 8!
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.43  2005/07/13 19:06:05  ms
# Bugfix sub lang (de as default language)
#
# Revision 1.42  2005/07/13 18:20:35  ms
# Anpassungen Barcode
#
# Revision 1.41  2005/07/13 13:56:14  ms
# Bugfix Barcodes
#
# Revision 1.40  2005/07/12 17:12:35  ms
# Anpassungen für Barcode
#
# Revision 1.39  2005/07/11 16:45:48  ms
# Implementing Barcode Module
#
# Revision 1.38  2005/07/08 16:55:06  ms
# Implementierung Menu
#
# Revision 1.37  2005/06/17 18:22:19  ms
# Implementation scan from webclient
#
# Revision 1.36  2005/06/15 17:37:45  ms
# Bugfix
#
# Revision 1.35  2005/06/15 15:47:09  ms
# Implementation scan definition parsing
#
# Revision 1.34  2005/06/08 16:56:01  ms
# Anpassungen an _exception
#
# Revision 1.33  2005/06/02 18:29:53  ms
# Implementing update for mask definition
#
# Revision 1.32  2005/06/01 13:20:49  ms
# New password request
#
# Revision 1.31  2005/05/12 13:01:42  ms
# Last changes for archive server (v.1.0)
#
# Revision 1.30  2005/05/11 18:22:43  ms
# Changes for mask definition (archive server)
#
# Revision 1.29  2005/05/06 15:43:03  ms
# Bugfix an FieldTab/FieldObj, edit mask definition name, sql definitions for user
#
# Revision 1.28  2005/05/04 16:59:56  ms
# Changes for archive server mask definitions
#
# Revision 1.27  2005/04/29 16:25:26  ms
# Mask definition development
#
# Revision 1.26  2005/04/28 16:40:20  ms
# Anpassungen fuer die felder definition (alter table)
#
# Revision 1.25  2005/04/28 14:06:07  ms
# *** empty log message ***
#
# Revision 1.24  2005/04/28 13:15:30  ms
# Implementing alter table module
#
# Revision 1.23  2005/04/27 17:03:23  ms
# *** empty log message ***
#
# Revision 1.22  2005/04/27 16:18:52  ms
# Anpassungen an GRANT/REVOKE
#
# Revision 1.21  2005/04/22 17:27:48  ms
# Anpassungen für Archivverwaltung
#
# Revision 1.20  2005/04/21 14:57:01  ms
# Diverse Anpassungen
#
# Revision 1.19  2005/04/21 14:17:31  ms
# Implementing method userLevels which returns a hash(level,description) of each
# archivista user level
#
# Revision 1.18  2005/04/20 17:56:51  ms
# Set language as parameter on connecting (Archivista::archive) to an archive
#
# Revision 1.17  2005/04/20 17:42:14  ms
# *** empty log message ***
#
# Revision 1.16  2005/04/20 16:15:57  ms
# *** empty log message ***
#
# Revision 1.15  2005/04/15 18:12:29  ms
# Don't delete the session on Archive::disconnect
#
# Revision 1.14  2005/04/14 17:43:36  ms
# *** empty log message ***
#
# Revision 1.13  2005/04/06 18:19:16  ms
# Entwicklung an der session datenbank
#
# Revision 1.12  2005/03/31 18:18:14  ms
# Weiterentwicklung an formular elemente (hinzufügen neuer elemente)
#
# Revision 1.11  2005/03/31 13:44:26  ms
# Implementierung der copy data from database Funktionalität
#
# Revision 1.10  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.9  2005/03/23 12:01:44  ms
# Anpassungen an GRANT / REVOKE
#
# Revision 1.8  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.7  2005/03/21 18:33:20  ms
# Erzeugung neuer archivista datenbanken
#
# Revision 1.6  2005/03/18 18:58:45  ms
# Enwicklung an der Benutzerfunktionalität
#
# Revision 1.5  2005/03/17 17:12:59  ms
# Weiterentwicklung Hinzufügen der Parameter-Tabelle
#
# Revision 1.4  2005/03/15 18:39:22  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.3  2005/03/14 17:29:11  ms
# Weiterentwicklung an APCL: einfuehrung der klassen BL/User sowie Util/Exception
#
# Revision 1.2  2005/03/11 18:58:47  ms
# Weiterentwicklung an Archivista Perl Class Library
#
# Revision 1.1.1.1  2005/03/11 14:01:22  ms
# Archivista Perl Class Library Projekt imported
#
# Revision 1.3  2005/03/11 11:05:40  ms
# Added delete method to DL/Archive.pm
#
# Revision 1.2  2005/03/10 17:57:55  ms
# Weiterentwicklung an der Klassenbibliothek
#
# Revision 1.1  2005/03/10 11:44:47  ms
# Files moved to BL (business logic) directory
#
# Revision 1.2  2005/03/08 15:49:35  ms
# currentDocument / currentPage
#
# Revision 1.1  2005/03/08 15:19:28  ms
# Files added
#
