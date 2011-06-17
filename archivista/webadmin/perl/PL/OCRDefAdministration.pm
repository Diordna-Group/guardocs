# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:02 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::OCRDefAdministration;

use strict;

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls,$archiveO)

	IN: class name
	    object (Archivista::BL::Archive APCL)
	OUT: object 

	Constructur

=cut

sub new
  {
    my $cls = shift;
    my $archiveO = shift;	# Object of Archivista::BL::Archive (APCL)
    my $self = {};

    bless $self, $cls;

    my @fields = ("def_name","def_lang1","def_lang2",
		  "def_lang3","def_lang4","def_lang5",
		  "def_quality","def_checkOrientation",
                  "def_cleanBeforeRecognition",
		  "def_suppressScaling",
                  "def_withoutBWConversion",
                  "def_tableCellsFromLines",
                  "def_noOverlappedCells",
		  "def_oneRow");

    $self->{'archiveO'} = $archiveO;
    $self->{'field_list'} = \@fields;

    return $self;
  }

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all fields required to administrate the form

=cut

sub fields
  {
    my $self = shift;
    my $cgiO = shift;
    my $archiveO = $self->archive;
    my $langO = $self->archive->lang;
    my $phOCRLangs = $archiveO->ocrlangs("HASH");
    my $paOCRLangs = $archiveO->ocrlangs("ARRAY");
    my $paQualityDefs = $archiveO->qualityDefs("ARRAY");
    my $phQualityDefs = $archiveO->qualityDefs("HASH");

    my (%fields);

    $fields{'list'} = $self->{'field_list'};

    $fields{'def_name'}{'label'} = $langO->string("OCRDEFINITION");
    $fields{'def_name'}{'name'} = "def_name";
    $fields{'def_name'}{'type'} = "textfield";
    $fields{'def_name'}{'update'} = 1;

    $fields{'def_lang1'}{'label'} = $langO->string("LANGUAGE1");
    $fields{'def_lang1'}{'name'} = "def_lang1";
    $fields{'def_lang1'}{'type'} = "select";
    $fields{'def_lang1'}{'array_values'} = $paOCRLangs;
    $fields{'def_lang1'}{'hash_values'} = $phOCRLangs;
    $fields{'def_lang1'}{'update'} = 1;

    $fields{'def_lang2'}{'label'} = $langO->string("LANGUAGE2");
    $fields{'def_lang2'}{'name'} = "def_lang2";
    $fields{'def_lang2'}{'type'} = "select";
    $fields{'def_lang2'}{'array_values'} = $paOCRLangs;
    $fields{'def_lang2'}{'hash_values'} = $phOCRLangs;
    $fields{'def_lang2'}{'update'} = 1;

    $fields{'def_lang3'}{'label'} = $langO->string("LANGUAGE3");
    $fields{'def_lang3'}{'name'} = "def_lang3";
    $fields{'def_lang3'}{'type'} = "select";
    $fields{'def_lang3'}{'array_values'} = $paOCRLangs;
    $fields{'def_lang3'}{'hash_values'} = $phOCRLangs;
    $fields{'def_lang3'}{'update'} = 1;

    $fields{'def_lang4'}{'label'} = $langO->string("LANGUAGE4");
    $fields{'def_lang4'}{'name'} = "def_lang4";
    $fields{'def_lang4'}{'type'} = "select";
    $fields{'def_lang4'}{'array_values'} = $paOCRLangs;
    $fields{'def_lang4'}{'hash_values'} = $phOCRLangs;
    $fields{'def_lang4'}{'update'} = 1;

    $fields{'def_lang5'}{'label'} = $langO->string("LANGUAGE5");
    $fields{'def_lang5'}{'name'} = "def_lang5";
    $fields{'def_lang5'}{'type'} = "select";
    $fields{'def_lang5'}{'array_values'} = $paOCRLangs;
    $fields{'def_lang5'}{'hash_values'} = $phOCRLangs;
    $fields{'def_lang5'}{'update'} = 1;

    $fields{'def_quality'}{'label'} = $langO->string("QUALITY_OF_TEXT");
    $fields{'def_quality'}{'name'} = "def_quality";
    $fields{'def_quality'}{'type'} = "select";
    $fields{'def_quality'}{'array_values'} = $paQualityDefs;
    $fields{'def_quality'}{'hash_values'} = $phQualityDefs;
    $fields{'def_quality'}{'update'} = 1;

    $fields{'def_checkOrientation'}{'label'} = $langO->string("CHECK_ORIENTATION");
    $fields{'def_checkOrientation'}{'name'} = "def_checkOrientation";
    $fields{'def_checkOrientation'}{'type'} = "checkbox";
    $fields{'def_checkOrientation'}{'update'} = 1;

    $fields{'def_cleanBeforeRecognition'}{'label'} = $langO->string("CLEAN_BEFORE_RECOGNITION");
    $fields{'def_cleanBeforeRecognition'}{'name'} = "def_cleanBeforeRecognition";
    $fields{'def_cleanBeforeRecognition'}{'type'} = "checkbox";
    $fields{'def_cleanBeforeRecognition'}{'update'} = 1;

    $fields{'def_suppressScaling'}{'label'} = $langO->string("SUPPRESS_SCALING");
    $fields{'def_suppressScaling'}{'name'} = "def_suppressScaling";
    $fields{'def_suppressScaling'}{'type'} = "checkbox";
    $fields{'def_suppressScaling'}{'update'} = 1;

    $fields{'def_withoutBWConversion'}{'label'} = $langO->string("WITHOUT_BW_CONVERSION");
    $fields{'def_withoutBWConversion'}{'name'} = "def_withoutBWConversion";
    $fields{'def_withoutBWConversion'}{'type'} = "checkbox";
    $fields{'def_withoutBWConversion'}{'update'} = 1;

    $fields{'def_tableCellsFromLines'}{'label'} = $langO->string("TABLE_CELLS_FROM_LINES");
    $fields{'def_tableCellsFromLines'}{'name'} = "def_tableCellsFromLines";
    $fields{'def_tableCellsFromLines'}{'type'} = "checkbox";
    $fields{'def_tableCellsFromLines'}{'update'} = 1;

    $fields{'def_noOverlappedCells'}{'label'} = $langO->string("NO_OVERLAPPED_CELLS");
    $fields{'def_noOverlappedCells'}{'name'} = "def_noOverlappedCells";
    $fields{'def_noOverlappedCells'}{'type'} = "checkbox";
    $fields{'def_noOverlappedCells'}{'update'} = 1;

    $fields{'def_oneRow'}{'label'} = $langO->string("ONE_ROW");
    $fields{'def_oneRow'}{'name'} = "def_oneRow";
    $fields{'def_oneRow'}{'type'} = "checkbox";
    $fields{'def_oneRow'}{'update'} = 1;

    if ($cgiO->param("adm") eq "edit") {
      my $id = $cgiO->param("id");
      if (defined $id) {
				my $def = $archiveO->parameter("OCRSets")
	  											 ->attribute("Inhalt")
	    										 ->ocr($id);
				$fields{'def_name'}{'value'} = $def->name;
				$fields{'def_lang1'}{'value'} = $def->lang1;
				$fields{'def_lang2'}{'value'} = $def->lang2;
				$fields{'def_lang3'}{'value'} = $def->lang3;
				$fields{'def_lang4'}{'value'} = $def->lang4;
				$fields{'def_lang5'}{'value'} = $def->lang5;
				$fields{'def_quality'}{'value'} = $def->quality;
				$fields{'def_checkOrientation'}{'value'} = $def->checkOrientation;
				$fields{'def_cleanBeforeRecognition'}{'value'} = $def->cleanBeforeRecognition;
				$fields{'def_suppressScaling'}{'value'} = $def->suppressScaling;
				$fields{'def_withoutBWConversion'}{'value'} = $def->withoutBWConversion;
				$fields{'def_tableCellsFromLines'}{'value'} = $def->tableCellsFromLines;
				$fields{'def_noOverlappedCells'}{'value'} = $def->noOverlappedCells;
				$fields{'def_oneRow'}{'value'} = $def->oneRow;
      }
    } else {
      $fields{'def_name'}{'value'} = '';
      $fields{'def_lang1'}{'value'} = 0;
      $fields{'def_lang2'}{'value'} = 0;
      $fields{'def_lang3'}{'value'} = 0;
      $fields{'def_lang4'}{'value'} = 0;
      $fields{'def_lang5'}{'value'} = 0;
      $fields{'def_quality'}{'value'} = 0;
      $fields{'def_checkOrientation'}{'value'} = 0;
      $fields{'def_cleanBeforeRecognition'}{'value'} = 0;
      $fields{'def_suppressScaling'}{'value'} = 0;
      $fields{'def_withoutBWConversion'}{'value'} = 0;
      $fields{'def_tableCellsFromLines'}{'value'} = 0;
      $fields{'def_noOverlappedCells'}{'value'} = 0;
      $fields{'def_oneRow'}{'value'} = 0;
    }

    $fields{'displayBackFormButton'} = 1;

    return \%fields;
  }

# -----------------------------------------------

=head1 save($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Save the date about a definition

=cut

sub save
  {
    my $self = shift;
    my $cgiO = shift;		# Object of CGI.pm
    my $archiveO = $self->archive;
    my $id = $cgiO->param("id");

    my ($ocrDef);
    my $name = $cgiO->param("def_name");
    my $lang1 = $cgiO->param("def_lang1");
    my $lang2 = $cgiO->param("def_lang2");
    my $lang3 = $cgiO->param("def_lang3");
    my $lang4 = $cgiO->param("def_lang4");
    my $lang5 = $cgiO->param("def_lang5");
    my $quality = $cgiO->param("def_quality");

    my $checkOrientation = $cgiO->param("def_checkOrientation");
    $checkOrientation=0 if ! defined $checkOrientation;

    my $cleanBeforeRecognition = $cgiO->param("def_cleanBeforeRecognition");
    $cleanBeforeRecognition=0 if ! defined $cleanBeforeRecognition;

    my $suppressScaling = $cgiO->param("def_suppressScaling");
    $suppressScaling=0 if ! defined $suppressScaling;

    my $withoutBWConversion = $cgiO->param("def_withoutBWConversion");
    $withoutBWConversion=0 if ! defined $withoutBWConversion;

    my $tableCellsFromLines = $cgiO->param("def_tableCellsFromLines");
    $tableCellsFromLines=0 if ! defined $tableCellsFromLines;

    my $noOverlappedCells = $cgiO->param("def_noOverlappedCells");
    $noOverlappedCells=0 if ! defined $noOverlappedCells;

    my $oneRow = $cgiO->param("def_oneRow");
    $oneRow=0 if ! defined $oneRow;

    if ($cgiO->param("submit") eq $self->archive->lang->string("SAVE")) {
      my $attr=$archiveO->parameter("OCRSets")->attribute("Inhalt");
      if (defined $id) {
				# Update the ocr definition
				$ocrDef = $attr->ocr($id);
      } else {
				$ocrDef = $attr->ocr;
      }

      $ocrDef->name($name);
      $ocrDef->lang1($lang1);
      $ocrDef->lang2($lang2);
      $ocrDef->lang3($lang3);
      $ocrDef->lang4($lang4);
      $ocrDef->lang5($lang5);
      $ocrDef->quality($quality);
      $ocrDef->checkOrientation($checkOrientation);
      $ocrDef->cleanBeforeRecognition($cleanBeforeRecognition);
      $ocrDef->suppressScaling($suppressScaling);
      $ocrDef->withoutBWConversion($withoutBWConversion);
      $ocrDef->tableCellsFromLines($tableCellsFromLines);
      $ocrDef->noOverlappedCells($noOverlappedCells);
      $ocrDef->oneRow($oneRow);

      if (defined $id) {
				$ocrDef->update;
      } else {
				$ocrDef->add;
      }
    }
  }






=head1 copy($cgi)

Copy the information from the database to a file

=cut

sub copy {
  my $self = shift;
	my $cgi = shift;
	my ($txt,$file);
	my $id = $cgi->param('id');
	my $archiv = $self->archive;
	my $ocrDef = $archiv->parameter("OCRSets")->attribute("Inhalt")->ocr($id);

	my $transfer = { def_name => 'name',
	                 def_lang1 => 'lang1',
	                 def_lang2 => 'lang2',
	                 def_lang3 => 'lang3',
	                 def_lang4 => 'lang4',
	                 def_lang5 => 'lang5',
	                 def_quality => 'quality',
									 def_checkOrientation => 'checkOrientation',
	                 def_cleanBeforeRecognition => 'cleanBeforeRecognition',
									 def_suppressScaling => 'suppressScaling',
									 def_withoutBWConversion => 'withoutBWConversion',
									 def_tableCellsFromLines => 'tableCellsFromLines',
									 def_noOverlappedCells => 'noOverlappedCells',
									 def_oneRow => 'oneRow',
	               };
	foreach $id (keys %{$transfer}) {
	  my ($func,$value);
	  $func = $transfer->{$id};
    $value = "Copy of " if $id eq 'def_name';
		$value .= $ocrDef->$func();
    $txt .= "$id=$value;\n";
	}
	
	$file = $self->_getFileName();
	open(FOUT,">",$file);
	binmode(FOUT);
	print FOUT $txt;
	close(FOUT);
}






=head1 paste($cgi)

Load OCR-Information from file and store it.

=cut

sub paste {
  my $self = shift;
	my $cgi = shift;

	my ($file,$txt); 

  $file = $self->_getFileName();

	open(FIN,"<",$file);
	binmode(FIN);
	while(<FIN>) {
	  $txt .= $_;
	}
	close(FIN);

  # id=value;id2=value2;...
	my @lines = split(";\n",$txt);
	foreach my $line (@lines) {
		$line =~ /^(\w+)=(.+)?$/;
		my $id = $1;
		my $value = $2;
		# Set CGI Param
		$cgi->param(-name=>$id,-value=>$value);
	}
	# Save needs submit to be $lang->string("SAVE");
	# Else it does not do anything
	my $value = $self->archive->lang->string("SAVE");
	$cgi->param(-name=>'submit',-value=>$value);
	$self->save($cgi);
	# delete file after pasting
	unlink $file;
}






# _getFileName
#
# return /tmp/$user-$host.scandef for copy paste
##

sub _getFileName {
  my $self = shift;
  my $file;
	$file = "/tmp/".$self->archive->session->user();
	$file .= "-".$self->archive->session->host().".ocrdef";
	return $file;
}






# -----------------------------------------------

=head1 elements($self)

	IN: object (self)
	OUT: pointer to hash

	Get a pointer to hash of all definitions to display

=cut

sub elements
  {
    my $self = shift;
    my $archiveO = $self->archive;
    my $langO = $archiveO->lang;
    my $paocrDefs = $archiveO->ocrs("ARRAY");
    my $phocrDefs = $archiveO->ocrDefinitions("HASH");

    my (@list,%ocrDefs);
    # Attributes to display on table
    my @attributes = ("Name");

    foreach my $def (@$paocrDefs) {
      push @list, $def;
      my $name = $phocrDefs->{$def}->name;
      $ocrDefs{$def}{'Name'} = $name;
      $ocrDefs{$def}{'delete'} = $$phocrDefs{$def}{'delete'};
			$ocrDefs{$def}{'copy'} = 1;
      $ocrDefs{$def}{'update'} = $$phocrDefs{$def}{'update'};
    }
    $ocrDefs{'new'} = 1;
		$ocrDefs{'paste'} = 1;
    $ocrDefs{'attributes'} = \@attributes;
    $ocrDefs{'list'} = \@list;

    return \%ocrDefs;
  }

# -----------------------------------------------

=head1 delete($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Remove a definition

=cut

sub delete
  {
    my $self = shift;
    my $cgiO = shift;
    my $archiveO = $self->archive;
    my $id = $cgiO->param("id");

    if (defined $id) {
      $archiveO->parameter("OCRSets")
							 ->attribute("Inhalt")
	  					 ->ocr($id)
	    				 ->remove;
    }
  }

# -----------------------------------------------

=head1 archive($self)
	
	IN: object (self)
	OUT: object (Archivista::BL::Archive)

	Return the object to APCL

=cut

sub archive
  {
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
# $Log: OCRDefAdministration.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:02  upfister
# Copy to sourceforge
#
# Revision 1.2  2007/05/31 14:44:42  rn
# Add copy&paste functionality to WebAdmin in
# ScanDefinition,OCRDefinition and SQLDefinition forms.
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.1  2005/11/15 12:00:55  up
# File added to project
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
