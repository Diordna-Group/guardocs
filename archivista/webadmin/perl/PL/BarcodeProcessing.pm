# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:00 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::BarcodeProcessing;

use strict;

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls,$archiveO)

	IN: class name
	    object (Archivista::BL::Archive (APCL)
	OUT: object

	Construtor for this class. Define the required fields to display the
	information and save the archive object (APCL) to this object
	
=cut

sub new
{
  my $cls = shift;
  my $archiveO = shift; # Object of Archivista::BL::Archive (APCL)
	my $self = {};

  bless $self, $cls;

  my @fields = ("bc_definition","bc_number","bc_length",
								"bc_attribute","bc_start","bc_character");
	
  $self->{'archiveO'} = $archiveO;
	$self->{'field_list'} = \@fields;
	
  return $self;
}

# -----------------------------------------------

=head1 selection($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of select items of all barcode definitions

=cut

sub selection
{
  my $self = shift;
	my $cgiO = shift;
	my $archiveO = $self->archive;
	my $langO = $self->archive->lang;
	my $bcDefinition = $cgiO->param('bc_definition');
	
	# Check if user deleted a mask definition
	if ($cgiO->param('submit') eq $langO->string("DELETE")) {
		$archiveO->parameter("Barcodes")
						 ->attribute("Inhalt")
						 ->barcode($bcDefinition)
						 ->remove;
		undef $bcDefinition;
	}
	
#	my $maskNextDefinition = $archiveO->maskNextDefinition;
  my $pabcDefinitions = $archiveO->barcodeDefinitions("ARRAY");
  my $value = "Barcode";
	
	$value = $bcDefinition if (length($bcDefinition) > 0);

	if ($cgiO->param('edit_selection') == 1) {
		# Check if we must change a barcode definition name
		my $editBCDefinitionNameNew = $cgiO->param('edit_selection_name');
		my $editBCDefinitionNameOld = $cgiO->param('edit_selection_value'); 
		$value = $editBCDefinitionNameNew;
		# Update value on database
		my $bc = $archiveO->parameter("Barcodes")
						 					->attribute("Inhalt")
						 					->barcode($editBCDefinitionNameOld);
		$bc->name($editBCDefinitionNameNew);
		$bc->update;
		# Get the updated barcode definition names
		$pabcDefinitions = $archiveO->barcodeDefinitions("ARRAY");
	} elsif ($cgiO->param('new_selection') == 1) {
 		# Define the name for the new barcode definition
		my $bcDefinitionName = $cgiO->param('new_selection_name');
    push @$pabcDefinitions, $bcDefinitionName;
		$value = $bcDefinitionName;
	} elsif (length($cgiO->param('bcid')) > 0) {
		$value = $cgiO->param('bcid');
	}
	
	my %selection;
	$selection{'label'} = $langO->string("BARCODE_DEFINITION");
	$selection{'field_name'} = "bc_definition";
	$selection{'array_values'} = $pabcDefinitions;
	$selection{'value'} = $value;
  $selection{'display_rename'} = 0;
	$selection{'display_delete'} = 0;
	$selection{'display_create'} = 0;
#	$selection{'new_selection_value'} = $maskNextDefinition;
	
	return \%selection; 
}

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all input fields to display for new items or on
	updating an existing item. This hash holds all required information about all
	attributes, like if they can be updated, type and possible values for select
	menus

=cut

sub fields
{
  my $self = shift;
  my $cgiO = shift;
	my $archiveO = $self->archive;
  my $langO = $self->archive->lang;
  my ($bcDefinition);
	
	# Retrieve or set the field definition value to work with
  if (length($cgiO->param('bc_definition')) > 0 
			&& $cgiO->param('submit') ne $langO->string("DELETE")) {
		$bcDefinition = $cgiO->param('bc_definition');
	} elsif (length($cgiO->param('bcid')) > 0) {
		$bcDefinition = $cgiO->param('bcid');
	} else {
	  my $pabcDefinitions = $archiveO->barcodeDefinitions("ARRAY");
		$bcDefinition = shift @$pabcDefinitions;
	}

 	if ($cgiO->param('edit_selection') == 1) {
		$bcDefinition = $cgiO->param('edit_selection_value');
	}
	
  # Define the name for the new mask definition
  if ($cgiO->param('new_selection') == 1) {
		$bcDefinition = $cgiO->param('new_selection_value');
	}
	
	my (%fields);

  $fields{'list'} = $self->{'field_list'};
	$fields{'bc_definition'}{'name'} = "bc_definition";
	$fields{'bc_definition'}{'type'} = "hidden";
	$fields{'bc_definition'}{'value'} = $bcDefinition;
	$fields{'bc_definition'}{'update'} = 1;
	$fields{'bc_number'}{'label'} = $langO->string("BARCODE");
	$fields{'bc_number'}{'name'} = "bc_number";
	$fields{'bc_number'}{'type'} = "select";
	$fields{'bc_number'}{'array_values'} = $archiveO->barcodeProcessNumber;
	$fields{'bc_number'}{'update'} = 1;
  $fields{'bc_length'}{'label'} = $langO->string("LENGTH");
	$fields{'bc_length'}{'name'} = "bc_length";
	$fields{'bc_length'}{'type'} = "select";
	$fields{'bc_length'}{'array_values'} = $archiveO->barcodeProcessLength("ARRAY");
	$fields{'bc_length'}{'hash_values'} = $archiveO->barcodeProcessLength("HASH");
	$fields{'bc_length'}{'update'} = 1;
  $fields{'bc_attribute'}{'label'} = $langO->string("FIELD");
	$fields{'bc_attribute'}{'name'} = "bc_attribute";
	$fields{'bc_attribute'}{'type'} = "select";
	$fields{'bc_attribute'}{'array_values'} = $archiveO->barcodeProcessAttributes("ARRAY");
	$fields{'bc_attribute'}{'hash_values'} = $archiveO->barcodeProcessAttributes("HASH");
	$fields{'bc_attribute'}{'update'} = 1;
  $fields{'bc_start'}{'label'} = $langO->string("START");
	$fields{'bc_start'}{'name'} = "bc_start";
	$fields{'bc_start'}{'type'} = "select";
	$fields{'bc_start'}{'array_values'} = $archiveO->barcodeProcessStart;
	$fields{'bc_start'}{'update'} = 1;
	$fields{'bc_character'}{'label'} = $langO->string("CHARACTER");
	$fields{'bc_character'}{'name'} = "bc_character";
	$fields{'bc_character'}{'type'} = "select";
	$fields{'bc_character'}{'array_values'} = $archiveO->barcodeProcessCharacter("ARRAY");
	$fields{'bc_character'}{'hash_values'} = $archiveO->barcodeProcessCharacter("HASH");
	$fields{'bc_character'}{'update'} = 1;
	
  if ($cgiO->param("adm") eq "edit") {
		my $id = $cgiO->param("id"); # field id -> field name
		if (defined $id) {
		  my $bcid = $cgiO->param("bcid");
			my $bc = $archiveO->parameter("Barcodes")
												->attribute("Inhalt")
												->barcode($bcid);
			
			$fields{'bc_number'}{'value'} = $bc->processingBarcodeNumber($id);
			$fields{'bc_length'}{'value'} = $bc->processingBarcodeLength($id);
			$fields{'bc_attribute'}{'value'} = $bc->processingBarcodeAttribute($id);
			$fields{'bc_start'}{'value'} = $bc->processingBarcodeStart($id);
			$fields{'bc_character'}{'value'} = $bc->processingBarcodeCharacter($id);
		}
	}

  $fields{'displayBackFormButton'} = 1;

  return \%fields;
}

# -----------------------------------------------

=head1 save($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Method to save the new or edited data of an item to the database

=cut

sub save
{
  my $self = shift;
	my $cgiO = shift; # Object of CGI.pm
	my $archiveO = $self->archive;
  my $id = $cgiO->param("id");

  my ($user);
	
	my $bcDefinition = $cgiO->param("bc_definition");
  my $number = $cgiO->param("bc_number");
	my $length = $cgiO->param("bc_length");
	my $attribute = $cgiO->param("bc_attribute");
	my $start = $cgiO->param("bc_start");
	my $character = $cgiO->param("bc_character");
 
 	if ($cgiO->param("submit") eq $self->archive->lang->string("SAVE")) {
		if (defined $id) {
			my $bc = $archiveO->parameter("Barcodes")
												->attribute("Inhalt")
												->barcode($bcDefinition);
			$bc->processingBarcodeNumber($id,$number);
			$bc->processingBarcodeLength($id,$length);
			$bc->processingBarcodeAttribute($id,$attribute);
			$bc->processingBarcodeStart($id,$start);
			$bc->processingBarcodeCharacter($id,$character);
			$bc->update;
		}
	}
}

# -----------------------------------------------

=head1 elements($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Retrieve all elements to display inside of the table
	
=cut

sub elements
{
  my $self = shift;
	my $cgiO = shift;
	my $archiveO = $self->archive;
  my $langO = $archiveO->lang;
	my $bcDefinition = "Barcode";
	
	if (length($cgiO->param('bc_definition')) > 0
			&& $cgiO->param('submit') ne $langO->string("DELETE")) {
		# We selected an existing barcode definition
		$bcDefinition = $cgiO->param('bc_definition');
	} elsif ($cgiO->param('edit_selection') == 1) {
		$bcDefinition = $cgiO->param('edit_selection_value');
	} elsif ($cgiO->param('new_selection') == 1) {
	  # We define a new barcode definition
		$bcDefinition = $cgiO->param('new_selection_value');
	} elsif (length($cgiO->param('bcid')) > 0) {
		$bcDefinition = $cgiO->param('bcid');
	}

  my $bc = $archiveO->parameter("Barcodes")
										->attribute("Inhalt")
										->barcode($bcDefinition);
										
 	my $pauserDefinedAttributes = $archiveO->userDefinedAttributes;
  unshift @$pauserDefinedAttributes, $langO->string("DATE");
	unshift @$pauserDefinedAttributes, $langO->string("TITLE");
	push @$pauserDefinedAttributes, $langO->string("DOKNR");

	my (@list,%fields);
	my $inc = 0;
	# Attributes to display on table
	# Same name as in archivista.languages, $langO->string() will use this
	# attribute definitions (upper case)
	my @attributes = ("barcode","length","field","start","character");
 
	for (my $idx = 0; $idx < $archiveO->barcodeProcessNumberOf; $idx++) {
	  my $number = $bc->processingBarcodeNumber($idx);
		my $length = $bc->processingBarcodeLength($idx);
		$length = $langO->string("ALL") if ($length == 0);		
		my $attributeIndex = $bc->processingBarcodeAttribute($idx);
		my $attributeName = $$pauserDefinedAttributes[$attributeIndex];
		my $start = $bc->processingBarcodeStart($idx);
		my $character = $bc->processingBarcodeCharacter($idx);
		my $bcDefinitionParam = $cgiO->escape($bcDefinition);
		$character = $langO->string("ALL") if ($character == 0);
		push @list, $idx;
	
		$fields{$idx}{'barcode'} = $number if ($number > -1);
		$fields{$idx}{'length'} = $length if ($length > -1);
		$fields{$idx}{'field'} = $attributeName if ($attributeIndex > -1);
		$fields{$idx}{'start'} = $start if ($start > -1);
		$fields{$idx}{'character'} = $character if ($character > -1);
		# Please note: without leading '&'
		$fields{$idx}{'url_params'} = "bcid=$bcDefinitionParam"; 
		$fields{$idx}{'update'} = 1;
		$fields{$idx}{'delete'} = 1; 
		$inc++;
	}

  $fields{'new'} = 0;
	$fields{'bc_definition'} = $bcDefinition;
	$fields{'attributes'} = \@attributes;
	$fields{'list'} = \@list;

	return \%fields;
}

# -----------------------------------------------

=head1 delete($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Delete an element from the database

=cut

sub delete
{
  my $self = shift;
	my $cgiO = shift;
	my $archiveO = $self->archive;
	my $id = $cgiO->param("id");

	if (defined $id) {
	  my $bcid = $cgiO->param('bcid');
		my $id = $cgiO->param('id'); # Index of barcode processing definition
		$archiveO->parameter("Barcodes")
		  			 ->attribute("Inhalt")
						 ->barcode($bcid)
						 ->resetProcessingBarcode($id);
	}
}

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive)

	Return the APCL archive object saved on this object

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
# $Log: BarcodeProcessing.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:00  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.4  2006/03/27 10:26:19  up
# Mask definition again, rotation b/w images, barcode recognition (multiple
# barcodes)
#
# Revision 1.3  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.2  2005/10/26 16:43:15  ms
# Bugfixing of &
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.4  2005/07/13 15:12:25  ms
# Bugfix barcodeProcessAttributes
#
# Revision 1.3  2005/07/13 14:41:34  ms
# Bugfix Barcodes
#
# Revision 1.2  2005/07/12 17:13:01  ms
# Entwicklung an BarcodeProcess
#
