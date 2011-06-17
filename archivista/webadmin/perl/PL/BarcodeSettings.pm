# Current revision $Revision: 1.2 $
# Latest change by $Author: upfister $ on $Date: 2008/12/13 10:52:49 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::BarcodeSettings;

use strict;

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls,$archiveO)

	IN: class name
	    object (Archivista::BL::Archive APCL)
	OUT: object

	Constructur. Defines the attribute names for barcode settings form

=cut

sub new
{
  my $cls = shift;
  my $archiveO = shift; # Object of Archivista::BL::Archive (APCL)
	my $self = {};

  bless $self, $cls;

#  my @fields = ("name","empty","manual","left","top","width","height",
#								"tolerance","trials","empty","first_barcode_type","second_barcode_type",
#								"orientation","check_character","vertical_stretch");

	my @fields = ("name","first_barcode_type","second_barcode_type",
								"orientation","check_character","vertical_stretch",
								"single_pages");

  $self->{'archiveO'} = $archiveO;
	$self->{'field_list'} = \@fields;
	
  return $self;
}

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all fields (attributes) required to manage the
	information. This hash hold all data need to display the input/update HTML
	form to insert new or edit exiting definitions.

=cut

sub fields
{
  my $self = shift;
  my $cgiO = shift;
	my $archiveO = $self->archive;
  my $langO = $self->archive->lang;
 
  my $pabarcodePosition = $archiveO->barcodePosition("ARRAY");
	my $phbarcodePosition = $archiveO->barcodePosition("HASH");
  my $pabarcodeTypes = $archiveO->barcodeTypes("ARRAY");
	my $phbarcodeTypes = $archiveO->barcodeTypes("HASH");
	my $pabarcodeOrientation = $archiveO->barcodeOrientation("ARRAY");
	my $phbarcodeOrientation = $archiveO->barcodeOrientation("HASH");
  my $pabarcodeVerticalStretch = $archiveO->barcodeVerticalStretch("ARRAY");
	my $phbarcodeVerticalStretch = $archiveO->barcodeVerticalStretch("HASH");
	
	# Add automatic to barcodeTypes
	unshift @$pabarcodeTypes, 0;
	$$phbarcodeTypes{0} = $langO->string("AUTOMATIC");
	# Add automatic to barcodeOrientation
	unshift @$pabarcodeOrientation, 0;
	$$phbarcodeOrientation{0} = $langO->string("AUTOMATIC");

  my (%fields);	
  $fields{'list'} = $self->{'field_list'};
  $fields{'name'}{'label'} = $langO->string("NAME");
	$fields{'name'}{'name'} = "bc_name";
	$fields{'name'}{'type'} = "textfield";
	$fields{'name'}{'update'} = 1;
	$fields{'manual'}{'label'} = $langO->string("BARCODE_POSITION");
	$fields{'manual'}{'name'} = "bc_manual";
	$fields{'manual'}{'type'} = "select";
	$fields{'manual'}{'array_values'} = $pabarcodePosition;
	$fields{'manual'}{'hash_values'} = $phbarcodePosition;
  $fields{'manual'}{'update'} = 1;	
  $fields{'left'}{'label'} = $langO->string("LEFT")." (mm)";
	$fields{'left'}{'name'} = "bc_left";
	$fields{'left'}{'type'} = "textfield";
	$fields{'left'}{'update'} = 1;
	$fields{'top'}{'label'} = $langO->string("TOP")." (mm)";
	$fields{'top'}{'name'} = "bc_top";
	$fields{'top'}{'type'} = "textfield";
	$fields{'top'}{'update'} = 1;
	$fields{'width'}{'label'} = $langO->string("WIDTH")." (mm)";
	$fields{'width'}{'name'} = "bc_width";
	$fields{'width'}{'type'} = "textfield";
	$fields{'width'}{'update'} = 1;
	$fields{'height'}{'label'} = $langO->string("HEIGHT")." (mm)";
	$fields{'height'}{'name'} = "bc_height";
	$fields{'height'}{'type'} = "textfield";
	$fields{'height'}{'update'} = 1;
	$fields{'tolerance'}{'label'} = $langO->string("TOLERANCE_VALUE")." (mm)";
	$fields{'tolerance'}{'name'} = "bc_tolerance";
	$fields{'tolerance'}{'type'} = "textfield";
	$fields{'tolerance'}{'update'} = 1;
	$fields{'trials'}{'label'} = $langO->string("TRIALS");
	$fields{'trials'}{'name'} = "bc_trials";
	$fields{'trials'}{'type'} = "textfield";
	$fields{'trials'}{'update'} = 1;
  $fields{'first_barcode_type'}{'label'} = $langO->string("FIRST_BARCODE_TYPE");
	$fields{'first_barcode_type'}{'name'} = "first_bc_type";
	$fields{'first_barcode_type'}{'type'} = "select";
	$fields{'first_barcode_type'}{'array_values'} = $pabarcodeTypes;
	$fields{'first_barcode_type'}{'hash_values'} = $phbarcodeTypes;
	$fields{'first_barcode_type'}{'update'} = 1;
  $fields{'second_barcode_type'}{'label'} = $langO->string("SECOND_BARCODE_TYPE");
	$fields{'second_barcode_type'}{'name'} = "second_bc_type";
	$fields{'second_barcode_type'}{'type'} = "select";
	$fields{'second_barcode_type'}{'array_values'} = $pabarcodeTypes;
	$fields{'second_barcode_type'}{'hash_values'} = $phbarcodeTypes;
	$fields{'second_barcode_type'}{'update'} = 1;
  $fields{'orientation'}{'label'} = $langO->string("ORIENTATION");
	$fields{'orientation'}{'name'} = "bc_orientation";
	$fields{'orientation'}{'type'} = "select";
	$fields{'orientation'}{'array_values'} = $pabarcodeOrientation;
	$fields{'orientation'}{'hash_values'} = $phbarcodeOrientation;
	$fields{'orientation'}{'update'} = 1;
  $fields{'check_character'}{'label'} = $langO->string("CHECK_CHARACTER");
	$fields{'check_character'}{'name'} = "bc_check_character";
	$fields{'check_character'}{'type'} = "textfield";
  $fields{'check_character'}{'update'} = 1;
	$fields{'vertical_stretch'}{'label'} = $langO->string("VERTICAL_STRETCH");
	$fields{'vertical_stretch'}{'name'} = "bc_vertical_stretch";
	$fields{'vertical_stretch'}{'type'} = "select";
	$fields{'vertical_stretch'}{'array_values'} = $pabarcodeVerticalStretch;
	$fields{'vertical_stretch'}{'hash_values'} = $phbarcodeVerticalStretch;
	$fields{'vertical_stretch'}{'update'} = 1;
	$fields{'single_pages'}{'label'} = $langO->string("SINGLE_PAGES");
	$fields{'single_pages'}{'name'} = "bc_single_pages";
	$fields{'single_pages'}{'type'} = "checkbox";
  $fields{'single_pages'}{'update'} = 1;
	
	

	if ($cgiO->param("adm") eq "edit") {
		my $id = $cgiO->param("id");
		if (defined $id) {
		  my $def = $archiveO->parameter("Barcodes")
												 ->attribute("Inhalt")
												 ->barcode($id);
			$fields{'name'}{'value'} = $def->name;
			$fields{'single_pages'}{'value'} = $def->manual;
		  $fields{'left'}{'value'} = $def->left;
			$fields{'top'}{'value'} = $def->top;
			$fields{'width'}{'value'} = $def->width;
			$fields{'height'}{'value'} = $def->height;
			$fields{'tolerance'}{'value'} = $def->tolerance;
			$fields{'trials'}{'value'} = $def->trials;
			$fields{'first_barcode_type'}{'value'} = $def->firstBarcodeType;
			$fields{'second_barcode_type'}{'value'} = $def->secondBarcodeType;
			$fields{'orientation'}{'value'} = $def->orientation;
			$fields{'check_character'}{'value'} = $def->checkCharacter;
			$fields{'vertical_stretch'}{'value'} = $def->verticalStretch;
		}
	} else {
	}

  $fields{'displayBackFormButton'} = 1;

  return \%fields;
}

# -----------------------------------------------

=head1 save($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Save the data of a definition to the database. This method performs either an
	insert for new items or an update of existing items.

=cut

sub save
{
  my $self = shift;
	my $cgiO = shift; # Object of CGI.pm
	my $archiveO = $self->archive;
  my $id = $cgiO->param("id");

  my ($barcodeDef);
	my $name = $cgiO->param("bc_name");
#	my $manual = $cgiO->param("bc_manual");
#	my $left = $cgiO->param("bc_left");
#	my $top = $cgiO->param("bc_top");
#	my $width = $cgiO->param("bc_width");
#	my $height = $cgiO->param("bc_height");
#	my $tolerance = $cgiO->param("bc_tolerance");
#	my $trials = $cgiO->param("bc_trials");
	my $firstBarcodeType = $cgiO->param("first_bc_type");
	my $secondBarcodeType = $cgiO->param("second_bc_type");
	my $orientation = $cgiO->param("bc_orientation");
	my $checkCharacter = $cgiO->param("bc_check_character");
	my $verticalStretch = $cgiO->param("bc_vertical_stretch");
	my $singlepages = $cgiO->param("bc_single_pages");
  $singlepages=0 if $singlepages != 1;

  if ($cgiO->param("submit") eq $self->archive->lang->string("SAVE")) {
		if (defined $id) {
			# Update the scan definition
		  $barcodeDef = $archiveO->parameter("Barcodes")
				   			  					 ->attribute("Inhalt")
														 ->barcode($id);
		} else {
			$barcodeDef = $archiveO->parameter("Barcodes")
		  											 ->attribute("Inhalt")
														 ->barcode;
		}

    $barcodeDef->name($name);
#   $barcodeDef->manual($manual);
#		$barcodeDef->left($left);
#		$barcodeDef->top($top);
#	  $barcodeDef->width($width);
#		$barcodeDef->height($height);
#		$barcodeDef->tolerance($tolerance);
#		$barcodeDef->trials($trials);
		$barcodeDef->firstBarcodeType($firstBarcodeType);
		$barcodeDef->secondBarcodeType($secondBarcodeType);
		$barcodeDef->orientation($orientation);
		$barcodeDef->checkCharacter($checkCharacter);
		$barcodeDef->verticalStretch($verticalStretch);
		$barcodeDef->manual($singlepages);
		
 		if (defined $id) {
			$barcodeDef->update;
		} else {
			$barcodeDef->add;
	  }
	}
}

# -----------------------------------------------

=head1 elements($self)

	IN: object (self)
	OUT: pointer to hash

	Return a pointer to hash of elements to display inside of the table

=cut

sub elements
{
  my $self = shift;
	my $archiveO = $self->archive;
  my $langO = $archiveO->lang;
	my $pabarcodeDefs = $archiveO->barcodeDefinitions("ARRAY");
  my $phbarcodeDefs = $archiveO->barcodeDefinitions("HASH");

	my (@list,%barcodeDefs);
	# Attributes to display on table
	my @attributes = ("Name");
	
	foreach my $def (@$pabarcodeDefs) {
		push @list, $def;
		my $name = $$phbarcodeDefs{$def}->name;
		$barcodeDefs{$def}{'Name'} = $name;
		$barcodeDefs{$def}{'delete'} = $$phbarcodeDefs{$def}{'delete'};
		$barcodeDefs{$def}{'update'} = $$phbarcodeDefs{$def}{'update'};
	}

  # Display 'new' Link for new entries
  $barcodeDefs{'new'} = 1;
  $barcodeDefs{'attributes'} = \@attributes;
  $barcodeDefs{'list'} = \@list;

	return \%barcodeDefs;
}

# -----------------------------------------------

=head1 delete($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Remove a definition from the database

=cut

sub delete
{
  my $self = shift;
	my $cgiO = shift;
	my $archiveO = $self->archive;
	my $id = $cgiO->param("id");

	if (defined $id) {
		$archiveO->parameter("Barcodes")
		  			 ->attribute("Inhalt")
						 ->barcode($id)
						 ->remove;
	}
}

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive)

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
# $Log: BarcodeSettings.pm,v $
# Revision 1.2  2008/12/13 10:52:49  upfister
# Add parameter for single page barcode recognition
#
# Revision 1.1.1.1  2008/11/09 09:21:00  upfister
# Copy to sourceforge
#
# Revision 1.2  2008/03/07 10:42:51  up
# Barcode vertical stretch
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.4  2005/07/18 10:39:53  ms
# Anpassungen: nicht benötigte Felder wurden rausgenommen
#
# Revision 1.3  2005/07/13 14:41:34  ms
# Bugfix Barcodes
#
# Revision 1.2  2005/07/12 17:13:01  ms
# Entwicklung an BarcodeProcess
#
# Revision 1.1  2005/07/11 16:45:28  ms
# Files added to project
#
