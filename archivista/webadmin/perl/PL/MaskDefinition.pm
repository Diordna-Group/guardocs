# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:02 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::MaskDefinition;

use strict;

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls,$archiveO)

	IN: class name
	    object (Archivista::BL::Archive)
	OUT: object

	Constructur
	
=cut

sub new
{
  my $cls = shift;
  my $archiveO = shift; # Object of Archivista::BL::Archive (APCL)
  my $self = {};

  bless $self, $cls;

  my @fields = ("mask_definition","mask_definition_name","field_name",
                "field_type","field_parent","field_label","field_position",
                "field_width","user_add","user_locked");
  
  $self->{'archiveO'} = $archiveO;
  $self->{'field_list'} = \@fields;
  
  return $self;
}

# -----------------------------------------------

=head1 selection($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all mask definition available to select

=cut

sub selection
{
  my $self = shift;
  my $cgiO = shift;
  my $archiveO = $self->archive;
  my $langO = $self->archive->lang;
  my $maskDefinition = $cgiO->param('mask_definition');
	my ($message);

  my $maskNextDefinition = $archiveO->maskNextDefinition;
  my $phmaskDefinitions = $archiveO->maskDefinitions;
  my @maskDefinitions = sort keys %$phmaskDefinitions;
  my $value = "00";
  $value = $maskDefinition if (length($maskDefinition) > 0);

  # Check if user deleted a mask definition
	my $nr = $#maskDefinitions;
  if ($cgiO->param('submit') eq $langO->string("DELETE")) {
	  if ($maskDefinition eq "00") {
      $message = $langO->string('MASK_KILLFIRST');
    } elsif ($maskDefinition ne $maskDefinitions[$nr]) {
		  $message = $langO->string('MASK_KILLNOTLAST');
		} else {
      $archiveO->mask_parameter("FelderObj".$maskDefinition)->delete;
      $archiveO->mask_parameter("FelderTab".$maskDefinition)->delete;
      $maskDefinition="00";
	    $maskNextDefinition = $archiveO->maskNextDefinition;
      $phmaskDefinitions = $archiveO->maskDefinitions;
      @maskDefinitions = sort keys %$phmaskDefinitions;
      $value = "00";
      $value = $maskDefinition if (length($maskDefinition) > 0);
		}
	}
	
  if ($cgiO->param('edit_selection') == 1) {
    # Check if we must change a mask definition name
    my $editMaskDefinitionName = $cgiO->param('edit_selection_name');
    my $editMaskDefinitionValue = $cgiO->param('edit_selection_value');
    $$phmaskDefinitions{$editMaskDefinitionValue} = 
		  $editMaskDefinitionName;
    $value = $editMaskDefinitionValue;
    # Update value on database
    $archiveO->mask_parameter("FelderObj".$value)
		  ->maskDefinitionName($editMaskDefinitionName);
  } elsif ($cgiO->param('new_selection') == 1) {
     # Define the name for the new mask definition
    my $maskDefinitionName = $cgiO->param('new_selection_name');
    my $maskDefinitionValue = $cgiO->param('new_selection_value');
    $$phmaskDefinitions{$maskDefinitionValue} = 
		  $maskDefinitionName; # Values like Felddefinition 1
    push @maskDefinitions, $maskDefinitionValue; # Values like 00,01,02
    $value = $maskDefinitionValue;
  } elsif (length($cgiO->param('mid')) > 0) {
    $value = $cgiO->param('mid');
  }
  
  my %selection;
  $selection{'label'} = $langO->string("MASK");
  $selection{'field_name'} = "mask_definition";
  $selection{'array_values'} = \@maskDefinitions;
  $selection{'hash_values'} = $phmaskDefinitions;
  $selection{'value'} = $value;
  $selection{'new_selection_value'} = $maskNextDefinition;
  $selection{'display_rename'} = 1;
  $selection{'display_delete'} = 1;
  $selection{'display_create'} = 1;
	$selection{'message'} = $message;
  return \%selection; 
}

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all required fields to manage mask definitions

=cut

sub fields
{
  my $self = shift;
  my $cgiO = shift;
  my $archiveO = $self->archive;
  my $langO = $self->archive->lang;
  my ($maskDefinition,$maskDefinitionName);
  
  # Retrieve or set the field definition value to work with
  if (length($cgiO->param('mask_definition')) > 0 
      && $cgiO->param('submit') ne $langO->string("DELETE")) {
    $maskDefinition = $cgiO->param('mask_definition');
  } elsif (length($cgiO->param('mid')) > 0) {
    $maskDefinition = $cgiO->param('mid');
  }
	
  if ($cgiO->param('edit_selection') == 1) {
    $maskDefinition = $cgiO->param('edit_selection_value');
  }
  
  # Define the name for the new mask definition
  if ($cgiO->param('new_selection') == 1) {
    $maskDefinitionName = $cgiO->param('new_selection_name');
    $maskDefinition = $cgiO->param('new_selection_value');
  }
  
  my $pauserDefinedAttributes = $self->archive->
	  userDefinedAttributes;
  my $phfieldTypes = $self->archive->maskFieldTypes;
  my @fieldTypes = sort keys %$phfieldTypes;
  my $pafieldParents = $self->archive->
	  mask_parameter("FelderObj".$maskDefinition)->
		 maskParentFields("ARRAY");
  my $phfieldParents = $self->archive->
	  mask_parameter("FelderObj".$maskDefinition)->
		  maskParentFields("HASH");
  # Add a NULL entry to the parents dropdown
  unshift @$pafieldParents, "";
  my $idx = 0;
  my (@position,%position,%fields);

  foreach my $attribute (@$pauserDefinedAttributes) {
    push @position, $idx;
    $position{$idx} = $attribute;
    $idx++;
  }
  
  $fields{'list'} = $self->{'field_list'};
  $fields{'mask_definition'}{'name'} = "mask_definition";
  $fields{'mask_definition'}{'type'} = "hidden";
  $fields{'mask_definition'}{'value'} = $maskDefinition;
  $fields{'mask_definition'}{'update'} = 1;
  $fields{'mask_definition_name'}{'name'} = "mask_definition_name";
  $fields{'mask_definition_name'}{'type'} = "hidden";
  $fields{'mask_definition_name'}{'value'} = $maskDefinitionName;
  $fields{'mask_definition_name'}{'update'} = 1;
  $fields{'field_name'}{'label'} = $langO->string("FIELD_NAME");
  $fields{'field_name'}{'name'} = "field_name";
  $fields{'field_name'}{'type'} = "select";
  $fields{'field_name'}{'array_values'} = $pauserDefinedAttributes;
  $fields{'field_name'}{'update'} = 1;
  $fields{'field_label'}{'label'} = $langO->string("LABEL");
  $fields{'field_label'}{'name'} = "field_label";
  $fields{'field_label'}{'type'} = "textfield";
  $fields{'field_label'}{'update'} = 1;
  $fields{'field_type'}{'label'} = $langO->string("FIELD_TYPE");
  $fields{'field_type'}{'name'} = "field_type";
  $fields{'field_type'}{'type'} = "select";
  $fields{'field_type'}{'array_values'} = \@fieldTypes;
  $fields{'field_type'}{'hash_values'} = $phfieldTypes;
  $fields{'field_type'}{'update'} = 1;
  $fields{'field_parent'}{'label'} = $langO->string("FIELD_PARENT");
  $fields{'field_parent'}{'name'} = "field_parent";
  $fields{'field_parent'}{'type'} = "select";
  $fields{'field_parent'}{'array_values'} = $pafieldParents;
  $fields{'field_parent'}{'hash_values'} = $phfieldParents;
  $fields{'field_parent'}{'update'} = 1;
  $fields{'field_position'}{'label'} = $langO->string("POSITION");
  $fields{'field_position'}{'name'} = "field_position";
  $fields{'field_position'}{'type'} = "textfield";
#  $fields{'field_position'}{'array_values'} = \@position;
#  $fields{'field_position'}{'hash_values'} = \%position;
  $fields{'field_position'}{'update'} = 1;
  $fields{'field_width'}{'label'} = $langO->string("WIDTH");
  $fields{'field_width'}{'name'} = "field_width";
  $fields{'field_width'}{'type'} = "textfield";
  $fields{'field_width'}{'update'} = 1;
  $fields{'user_add'}{'label'} = $langO->string("NEW_ENTRIES_ONLY_FOR_USER");
  $fields{'user_add'}{'name'} = "user_add";
  $fields{'user_add'}{'type'} = "textfield";
  $fields{'user_add'}{'update'} = 1;
  $fields{'user_locked'}{'label'} = $langO->string("INPUT_ONLY_FOR_USER");
  $fields{'user_locked'}{'name'} = "user_locked";
  $fields{'user_locked'}{'type'} = "textfield";
  $fields{'user_locked'}{'update'} = 1;
  
  if ($cgiO->param("adm") eq "edit") {
    my $id = $cgiO->param("id"); # field id -> field name
    my $mid = $cgiO->param("mid"); # mask ID -> FelderObjXY
    if (defined $id) {
      my $fieldObj = $archiveO->mask_parameter("FelderObj".$mid)
			  ->attribute("Inhalt")->field($id);
      my $fieldTab = $archiveO->mask_parameter("FelderTab".$mid)
			  ->attribute("Inhalt")->field($id);
      
      $fields{'field_name'}{'value'} = $fieldObj->name;
      $fields{'field_type'}{'value'} = $fieldObj->type;
      $fields{'field_parent'}{'value'} = $fieldObj->parent;
      $fields{'field_position'}{'value'} = $fieldTab->position;
      $fields{'field_width'}{'value'} = $fieldTab->width;
      $fields{'field_label'}{'value'} = $fieldTab->caption;
      $fields{'user_add'}{'value'} = $fieldObj->userAdd;
      $fields{'user_locked'}{'value'} = $fieldObj->userLocked;
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

	Save the values for a mask definition to the database thru APCL

=cut

sub save
{
  my $self = shift;
  my $cgiO = shift; # Object of CGI.pm
  my $archiveO = $self->archive;
	my $dbh = $archiveO->db->dbh;
  my $id = $cgiO->param("id");
  my ($user);
  my $maskDefinition = $cgiO->param("mask_definition");
  my $maskDefinitionName = $cgiO->param("mask_definition_name");
  my $fieldNameNew = $cgiO->param("field_name");
  my $fieldLabel = $cgiO->param("field_label");
  my $fieldType = $cgiO->param("field_type");
  my $fieldParent = $cgiO->param("field_parent");
  my $fieldPosition = $cgiO->param("field_position");
  my $fieldWidth = $cgiO->param("field_width");
  my $userAdd = $cgiO->param("user_add");
  my $userLocked = $cgiO->param("user_locked");

  if ($cgiO->param("submit") eq $self->archive->lang->string("SAVE")) {
    if ($id ne "") {
			# Update the form element
      my $fieldName = $id;
			
      my $updateField = $archiveO->mask_parameter("FelderObj".$maskDefinition)
                                 ->attribute("Inhalt")
                                 ->field($fieldName);

      $updateField->type($fieldType);
      $updateField->parent($fieldParent);
      $updateField->userAdd($userAdd);
      $updateField->userLocked($userLocked);
      $updateField->namenew($fieldNameNew);
      $updateField->update;

      my $updateTab = $archiveO->mask_parameter("FelderTab".$maskDefinition)
                               ->attribute("Inhalt")
                               ->field($fieldName);
      $updateTab->caption($fieldLabel);
      $updateTab->position($fieldPosition);
      $updateTab->width($fieldWidth);
      $updateTab->namenew($fieldNameNew);
      $updateTab->update;
    } else {
      my $fieldName = $cgiO->param("field_name");
			if ($fieldName ne "") {
        my $newField = $archiveO->mask_parameter("FelderObj".$maskDefinition)
                                ->attribute("Inhalt")
                                ->field;
        $newField->name($fieldName);
        $newField->type($fieldType);
        $newField->parent($fieldParent);
        $newField->userAdd($userAdd);
        $newField->userLocked($userLocked);
        if (length($maskDefinitionName) > 0) {
          # We have a new definition
          $newField->fieldName($maskDefinitionName);
        }
        $newField->add;

        if ($maskDefinition ne "00") {
			    my ($sql,@row);
          $sql = "select Inhalt from parameter where " .
  	  		       "Name='FelderTab$maskDefinition' and " .
	  	  	       "Art='FelderTab$maskDefinition' and " .
		  	  			 "Tabelle='archiv'";
    			my @row = $dbh->selectrow_array($sql);
	    		if ($row[0] eq "") {
		  		  # the desired FelderTabXX entry does not exist,
			  		# so check for the first one
            $sql = "select Inhalt from parameter where " .
	                 "Name='FelderTab00' and " .
		  						 "Art='FelderTab00' and " .
			  					 "Tabelle='archiv'";
  			    @row = $dbh->selectrow_array($sql);
					  if ($row[0] ne "") {
					    # first definition found, so add it to XX
					    my $nval = $dbh->quote($row[0]);
              $sql = "insert into parameter set " .
	  		             "Name='FelderTab$maskDefinition', " .
		  					  	 "Art='FelderTab$maskDefinition', " .
			  					   "Tabelle='archiv',Inhalt=$nval";
						  $dbh->do($sql);
					  }
			    }
				}
			
        my $newTab = $archiveO->mask_parameter("FelderTab".$maskDefinition)
                              ->attribute("Inhalt")
                              ->field;
        $newTab->name($fieldName);
        $newTab->caption($fieldLabel);
        $newTab->position($fieldPosition);
        $newTab->width($fieldWidth);
			  # FelderTabXX information always does exist, so just update
        $newTab->update;
			}
    }
  }
}

# -----------------------------------------------

=head1 elements($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all definitions

=cut

sub elements
{
  my $self = shift;
  my $cgiO = shift;
  my $archiveO = $self->archive;
	my $dbh = $archiveO->db->dbh;
  my $langO = $archiveO->lang;
	
  my $maskDefinition = "00"; # always select the first definition
  if (length($cgiO->param('mask_definition')) > 0
      && $cgiO->param('submit') ne $langO->string("DELETE")) {
    # We selected an existing mask definition
    $maskDefinition = $cgiO->param('mask_definition');
  } elsif ($cgiO->param('edit_selection') == 1) {
    $maskDefinition = $cgiO->param('edit_selection_value');
  } elsif ($cgiO->param('new_selection') == 1) {
    # We define a new mask, set this one for the table (empty table!)
    $maskDefinition = $cgiO->param('new_selection_value');
  } elsif (length($cgiO->param('mid')) > 0) {
    $maskDefinition = $cgiO->param('mid');
  }
 
  my (@list,%fields,$field,@row,$sql,@el,@el1,$inc,@attributes);
	$inc = 0;
  # Attributes to display on table
  @attributes = ("field_name");
  $sql = "select Inhalt from parameter where " .
	       "Name='FelderObj$maskDefinition' and " .
	       "Art='FelderObj$maskDefinition' and " .
	       "Tabelle='archiv' limit 1";
	@row = $dbh->selectrow_array($sql);
	if ($row[0] ne "") {
	  @el = split("\r\n",$row[0]);
		foreach (@el) {
		  @el1 = split(";",$_);
		  if ($el1[4] == 0) {
			  # take only field elements
				$field = $el1[18];
			  push @list, $field;
				$fields{$field}{'field_name'} = $field;
        $fields{$field}{'update'} = 1;
				# MOD 26.3.2006 -> we want also that we can delete 1 element
        $fields{$field}{'delete'} = 1;
        #$fields{$field}{'delete'} = 1 if ($inc>0);
				$inc++;
      }
		}
	}
  $fields{'new'} = 1;
  $fields{'mask_definition'} = $maskDefinition;
  $fields{'attributes'} = \@attributes;
  $fields{'list'} = \@list;
  return \%fields;
}

# -----------------------------------------------

=head1 delete($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Delete a definition from the database thru APCL

=cut

sub delete
{
  my $self = shift;
  my $cgiO = shift;
  my $archiveO = $self->archive;
  my $id = $cgiO->param("id");
  if (defined $id) {
    my $maskDefinition = $cgiO->param('mid');
    $archiveO->mask_parameter("FelderObj".$maskDefinition)
             ->attribute("Inhalt")->field($id)->remove;
  }
}

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive)

	Return the object of APCL

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
# $Log: MaskDefinition.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:02  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.8  2006/03/27 10:26:19  up
# Mask definition again, rotation b/w images, barcode recognition (multiple
# barcodes)
#
# Revision 1.7  2006/03/13 08:14:50  up
# OCR definitions now working correct, mask definition with language strings
#
# Revision 1.6  2006/03/06 09:35:55  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.5  2006/01/24 20:43:38  mw
# Es wird jetzt archivO->mask_parameter verwendet.
#
# Revision 1.4  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.3  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
#
# Revision 1.2  2005/07/19 09:29:34  ms
# Load mask definition 00 as default
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.11  2005/07/18 18:16:22  ms
# Anpassungen Barcode
#
# Revision 1.10  2005/07/12 17:13:01  ms
# Entwicklung an BarcodeProcess
#
# Revision 1.9  2005/06/02 18:29:14  ms
# Bugfix
#
# Revision 1.8  2005/05/27 16:41:23  ms
# Bugfix
#
# Revision 1.7  2005/05/27 15:43:38  ms
# Entwicklung an database administration
#
# Revision 1.6  2005/05/26 15:53:48  ms
# Anpassungen für LinuxTag
#
# Revision 1.5  2005/05/11 18:23:49  ms
# Entwicklung masken definitionen
#
# Revision 1.4  2005/05/06 15:43:39  ms
# Edit mask name, sql definitions for user
#
# Revision 1.3  2005/05/04 16:59:29  ms
# Entwicklung an Masken Definition
#
# Revision 1.2  2005/04/29 16:23:42  ms
# Entwicklung an masken definition
#
# Revision 1.1  2005/04/27 17:03:12  ms
# Files added to project
#
