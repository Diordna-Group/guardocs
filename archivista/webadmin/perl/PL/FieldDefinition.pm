# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:01 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::FieldDefinition;

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

sub new
{
  my $cls = shift;
  my $archiveO = shift; # Object of Archivista::BL::Archive (APCL)
	my $self = {};

  bless $self, $cls;

  my @fields = ("field_old_name","field_name","field_type","field_length","field_position");
	
  $self->{'archiveO'} = $archiveO;
	$self->{'field_list'} = \@fields;
	
  return $self;
}

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all required fields for the HTML form

=cut

sub fields
{
  my $self = shift;
  my $cgiO = shift;
	my $archiveO = $self->archive;
  my $langO = $self->archive->lang;
	my $pafieldTypes = $self->archive->attributeDataTypesByArray;
	my $phfieldTypes = $self->archive->attributeDataTypesByHash;
	my $pauserDefinedAttributes = $self->archive->userDefinedAttributes;
	# Add pages to the user defined attribute list (position after pages -> first
	# user defined attribute
	unshift @$pauserDefinedAttributes, "Seiten";
	my %userDefinedAttributes;
	
	
  foreach my $attribute (@$pauserDefinedAttributes) {
		$userDefinedAttributes{$attribute} = $attribute;
	}
	
	$userDefinedAttributes{'Seiten'} = $langO->string("PAGES");
	
	my (%fields);

  $fields{'list'} = $self->{'field_list'};
	$fields{'field_old_name'}{'name'} = "field_old_name";
	$fields{'field_old_name'}{'type'} = "hidden";
	$fields{'field_old_name'}{'update'} = 1;
  $fields{'field_name'}{'label'} = $langO->string("FIELD_NAME");
	$fields{'field_name'}{'name'} = "field_name";
	$fields{'field_name'}{'type'} = "textfield";
	$fields{'field_name'}{'update'} = 1;
	$fields{'field_type'}{'label'} = $langO->string("TYPE");
	$fields{'field_type'}{'name'} = "field_type";
	$fields{'field_type'}{'type'} = "select";
	$fields{'field_type'}{'array_values'} = $pafieldTypes;
	$fields{'field_type'}{'hash_values'} = $phfieldTypes;
	$fields{'field_type'}{'update'} = 0;
	$fields{'field_length'}{'label'} = $langO->string("LENGTH");
	$fields{'field_length'}{'name'} = "field_length";
	$fields{'field_length'}{'type'} = "textfield";
	$fields{'field_length'}{'update'} = 0;
	$fields{'field_position'}{'label'} = $langO->string("POSITION_AFTER");
	$fields{'field_position'}{'name'} = "field_position";
	$fields{'field_position'}{'type'} = "select";
	$fields{'field_position'}{'array_values'} = $pauserDefinedAttributes;
	$fields{'field_position'}{'hash_values'} = \%userDefinedAttributes;
	$fields{'field_position'}{'update'} = 1;

  if ($cgiO->param("adm") eq "edit") {
		my $id = $cgiO->param("id");
		if (defined $id) {
			my $phattribute = $archiveO->describeAttribute($id);
			$fields{'field_old_name'}{'value'} = $$phattribute{$id}{'attribute_name'};
			$fields{'field_name'}{'value'} = $$phattribute{$id}{'attribute_name'};
			$fields{'field_type'}{'value'} = $$phfieldTypes{$$phattribute{$id}{'attribute_type'}};
			$fields{'field_type'}{'hidden_value'} = $$phattribute{$id}{'attribute_type'};
			$fields{'field_length'}{'value'} = $$phattribute{$id}{'attribute_length'};
			$fields{'field_length'}{'hidden_value'} =	$$phattribute{$id}{'attribute_length'};
			$fields{'field_position'}{'value'} = $$phattribute{$id}{'attribute_after'};
			# On update, delete the attribute itself from the attribute position
			# dropdown
			my @udAttributes = grep !/$id/, @{$fields{'field_position'}{'array_values'}};
			$fields{'field_position'}{'array_values'} = \@udAttributes;
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

	Save the date of a definition to the database by calling the specific method
	from APCL

=cut

sub save
{
  my $self = shift;
	my $cgiO = shift; # Object of CGI.pm
	my $archiveO = $self->archive;
  my $id = $cgiO->param("id");
	
  if (length($cgiO->param("field_name")) > 0) {
  	my (@alter);
		$alter[0]{'attribute_name'} = $cgiO->param("field_name");
		$alter[0]{'attribute_type'} = $cgiO->param("field_type");
		$alter[0]{'attribute_length'} = $cgiO->param("field_length");
		$alter[0]{'after_attribute'} = $cgiO->param("field_position");
		if (defined $id) {
			$alter[0]{'attribute_old_name'} = $cgiO->param("field_old_name");
			$alter[0]{'alter_type'} = "CHANGE";
		} else {
			$alter[0]{'alter_type'} = "ADD";
		}
		$archiveO->alter(\@alter);
	}
}

# -----------------------------------------------

=head1 elements($self,$cgiO)

	IN: object (self)
	OUT: pointer to hash

	Return all elements to display

=cut

sub elements
{
  my $self = shift;
	my $archiveO = $self->archive;
  my $langO = $archiveO->lang;
	my $pauserDefinedAttributes = $archiveO->userDefinedAttributes;
	
	my (@list,%fields);
	# Attributes to display on table
	# Same name as in archivista.languages, $langO->string() will use this
	# attribute definitions (upper case)
	my @attributes = ("field_name");
	
	foreach my $attribute (@$pauserDefinedAttributes) {
		push @list, $attribute;
		$fields{$attribute}{'field_name'} = $attribute;
		$fields{$attribute}{'delete'} = 1;
		$fields{$attribute}{'update'} = 1;
	}

  $fields{'new'} = 1;
  $fields{'attributes'} = \@attributes;
  $fields{'list'} = \@list;

	return \%fields;
}

# -----------------------------------------------

=head1 delete($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Delete a definition thru the APCL method

=cut

sub delete
{
  my $self = shift;
	my $cgiO = shift;
	my $archiveO = $self->archive;
	my $id = $cgiO->param("id");

	if (defined $id) {
	  my (@alter);
		$alter[0]{'attribute_name'} = $id;
		$alter[0]{'alter_type'} = "DROP";
		$archiveO->alter(\@alter);
	}
}

# -----------------------------------------------

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
# $Log: FieldDefinition.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:01  upfister
# Copy to sourceforge
#
# Revision 1.2  2007/05/30 12:56:10  up
# Edit-Bug inside of field definition
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
# Revision 1.4  2005/07/12 17:13:01  ms
# Entwicklung an BarcodeProcess
#
# Revision 1.3  2005/05/27 16:41:23  ms
# Bugfix
#
# Revision 1.2  2005/04/28 16:40:45  ms
# Implementierung der felder definition (alter table)
#
# Revision 1.1  2005/04/27 17:03:12  ms
# Files added to project
#
