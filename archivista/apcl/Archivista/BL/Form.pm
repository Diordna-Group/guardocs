# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:21 $

package Archivista::BL::Form;

use strict;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init
{
  my $self = shift;

  $self->{'attribute'}->id("Art");
  $self->{'attribute'}->value($self->{'parentO'}->id);
  $self->{'attribute'}->id("Tabelle");
  $self->{'attribute'}->value("archiv");
  $self->{'attribute'}->id("Inhalt");
}

# -----------------------------------------------

sub _initFieldObj
{
  my $self = shift;

  $self->xCoord($self->_parseFieldObj(0));
  $self->yCoord($self->_parseFieldObj(1));
  $self->width1($self->_parseFieldObj(2));
  $self->height($self->_parseFieldObj(3));
  $self->type($self->_parseFieldObj(5));
  $self->parent($self->_parseFieldObj(10));
  $self->fontSize($self->_parseFieldObj(11));
  $self->fontBold($self->_parseFieldObj(12));
  $self->fontItalic($self->_parseFieldObj(13));
  $self->fontUnderline($self->_parseFieldObj(14));
  $self->fontOffset($self->_parseFieldObj(15));
  $self->fontColor($self->_parseFieldObj(16));
  $self->fontName($self->_parseFieldObj(17));
  $self->listTextValue($self->_parseFieldObj(19));
  $self->inputAttitudeType($self->_parseFieldObj(20));
  $self->fieldDependency($self->_parseFieldObj(21));
  $self->valueDependency($self->_parseFieldObj(22));
  $self->userAdd($self->_parseFieldObj(23));
  $self->userLocked($self->_parseFieldObj(24));
  $self->fieldName($self->_parseFieldObj(25));

}

# -----------------------------------------------

sub _initFieldTab
{
  my $self = shift;

  $self->caption($self->_parseFieldTab(1));
  $self->position($self->_parseFieldTab(2));
  $self->width($self->_parseFieldTab(3));
}

# -----------------------------------------------

sub _parseFieldObj
{
  my $self = shift;
  my $keyId = shift; # Position inside the definition (0;1;2;3...)
  my $formElementValue = shift;

  my ($closingSeqOfSemicolon,$definition,@definition);
  
  foreach my $def (split /\r\n/, $self->{'definition'}) {
    my @values = split /;/, $def;
    $def =~ /(;*)$/;
    $closingSeqOfSemicolon = $1;
    if ($values[4] == $self->elementType && 
		  lc($values[18]) eq lc($self->{'element'})) {
      if (defined $formElementValue) {
        # Setter method
        $values[$keyId] = $formElementValue;
      } else {
        # Getter method
        return $values[$keyId];
      }
    }
    $definition = join ";", @values;
    push @definition, $definition . $closingSeqOfSemicolon;
  }
  # For setter method, update the definition
  $self->{'definition'} = join "\r\n", @definition;
  # Update the attribute
  # The new values are so up-to-date. 
	# If we make an $archive->parameter->update
  # the new values are automatically saved to the database
  $self->{'attribute'}->value($self->{'definition'});
  return
}

# -----------------------------------------------

sub _parseFieldTab
{
  my $self = shift;
  my $keyId = shift;
  my $formElementValue = shift;

  my ($closingSeqOfSemicolon,$definition,@definition);

  foreach my $def (split /\r\n/, $self->{'definition'}) {
    my @values = split /;/, $def;
    # Get closing sequence of ';'
    $def =~ /(;*)$/;
    $closingSeqOfSemicolon = $1;
    if (lc($values[0]) eq lc($self->{'element'})) {
      if (defined $formElementValue) {
        $values[$keyId] = $formElementValue;
      } else {
        return $values[$keyId];
      }
    }
    $definition = join ";", @values;
    push @definition, $definition . $closingSeqOfSemicolon;
  }
  $self->{'definition'} = join "\r\n", @definition;
  $self->{'attribute'}->value($self->{'definition'});
  return
}

# -----------------------------------------------

sub _createDefinition
{
  my $self = shift;
  
  my $definition;
  
  if ($self->elementType <= 1) {
    # We have a FieldObj or a LabelObj
    $definition = $self->xCoord.";";
    $definition .= $self->yCoord.";";
    $definition .= $self->width1.";";
    $definition .= $self->height.";";
    $definition .= $self->elementType.";";
    $definition .= $self->type.";";
    if ($self->elementType == 0) {
      $definition .= "-1;-1;-1;0;";
    } else {
      $definition .= "0;0;0;0;";
    }
    $definition .= $self->parent.";";
    $definition .= $self->fontSize.";";
    $definition .= $self->fontBold.";";
    $definition .= $self->fontItalic.";";
    $definition .= $self->fontUnderline.";";
    $definition .= $self->fontOffset.";";
    $definition .= $self->fontColor.";";
    $definition .= $self->fontName.";";
    $definition .= $self->name.";";
    $definition .= $self->listTextValue.";";
    $definition .= $self->inputAttitudeType.";";
    $definition .= $self->fieldDependency.";";
    $definition .= $self->valueDependency.";";
    $definition .= $self->userAdd.";";
    $definition .= $self->userLocked.";";
    $definition .= $self->fieldName.";";
  } else {
    # We habe a FieldTab
    #$self->{'archiveO'}->session->param("AttributeType",$self->attributeType);
    #$self->{'archiveO'}->session->param("AttributeLength",$self->attributeLength);
    #$self->{'archiveO'}->session->save;
    $definition = $self->name.";";
    $definition .= $self->caption.";";
    $definition .= $self->position.";";
    $definition .= $self->width.";";
  }

  return $definition;
}

# -----------------------------------------------

sub _allFieldObjs
{
  my $self = shift;
  my $attribute = shift;
  my @fields;
  
  foreach my $field (split /\r\n/, $attribute->value) {
    my @values = split /;/, $field;
    push @fields, $values[18] if ($values[4] == 0);
  }

  return \@fields;
}

# -----------------------------------------------

sub _allFieldTabs
{
  my $self = shift;
  my $attribute = shift;
  my @fields;

  foreach my $field (split /\r\n/, $attribute->value) {
    my @values = split /;/, $field;
    push @fields, $values[0];
  }

  return \@fields;
}

# -----------------------------------------------
# PUBLIC METHODS

sub self
{
  my $cls = shift;
  my $attribute = shift; # Object of Archivisita::BL::Attribute
  my $parent = $attribute->parent;
  my $self = {};
  bless $self, $cls;
  $self->{'attribute'} = $attribute;
  $self->{'parentO'} = $parent;
  return $self;
}

# -----------------------------------------------

sub fieldObjs
{
  my $cls = shift;
  my $attribute = shift;
  my $pafields = $cls->_allFieldObjs($attribute);
  my %fieldObjects;

  foreach my $field (@$pafields) {
    $fieldObjects{$field} = $cls->fieldObj($attribute,$field);
  }
  
  return \%fieldObjects;
}

# -----------------------------------------------

sub fieldTabs
{
  my $cls = shift;
  my $attribute = shift;
  my $retDS = shift; # Return data structure (ARRAY or HASH)
  my $pafields = $cls->_allFieldTabs($attribute);

  if (uc($retDS) eq "HASH") {
    my %fieldTabs;
    foreach my $field (@$pafields) {
      $fieldTabs{$field} = $cls->fieldTab($attribute,$field);
    }
    return \%fieldTabs;
  } else {
    return $pafields;
  }
}

# -----------------------------------------------

sub fieldObj
{
  my $cls = shift;
  my $attribute = shift; # Object of Archivista::BL::Attribute
  my $field = shift;
  my $parent = $attribute->parent;
  my $self = {};

  bless $self, $cls;
  
  $self->{'attribute'} = $attribute;
  $self->{'element'} = $field;
  $self->{'namenew'} = $field;
  $self->{'parentO'} = $parent;
  # The fourth position inside the definition
  # Can be 0 (field) or 1 (label)
  $self->{'element_type'} = 0;
  $self->{'definition'} = $attribute->value;  
  $self->_initFieldObj;
  $self->_init;
  
  return $self;
}

# -----------------------------------------------

sub labelObj
{
  my $cls = shift;
  my $attribute = shift;
  my $label = shift;
  my $parent = $attribute->parent;
  my $self = {};

  bless $self, $cls;

  $self->{'attribute'} = $attribute;
  $self->{'element'} = $label;
  $self->{'parentO'} = $parent;
  $self->{'element_type'} = 1;
  $self->{'definition'} = $attribute->value;
  $self->_initFieldObj;
  $self->_init;
  
  return $self;
}
# -----------------------------------------------

sub fieldTab
{
  my $cls = shift;
  my $attribute = shift;
  my $field = shift;
  my $parent = $attribute->parent;
  my $archive = $attribute->archive;
  my $self = {};

  bless $self, $cls;

  $self->{'attribute'} = $attribute;
  $self->{'archiveO'} = $archive;
  $self->{'element'} = $field;
  $self->{'namenew'} = $field;
  $self->{'parentO'} = $parent;
  $self->{'element_type'} = 2;
  $self->{'definition'} = $attribute->value;
  $self->_initFieldTab;
  $self->_init;
  
  return $self;
}

# -----------------------------------------------

sub fieldTabOrderByPosition
{
  # Retrieve the fields defined on FieldTab00
  # and return them ordered by position as a
  # pointer to array(string fields)
  my $self = shift;

  my (@oFields,%fields);
  my $order = 0;
  
  my $parameter = $self->{'parentO'}->id("FelderTab00");
  $self->{'attribute'}->id("Inhalt");
  my @fields = split /\r\n/, $self->{'attribute'}->value;
  
  # First save the field name and its position to a hash
  foreach (@fields) {
    my ($name,undef,$position) = split /;/, $_;
    $fields{$name} = $position;
  }

  # Now sort the values (positions) of the hash elements
  # and push the fields to the ordered array (@oFields)
  foreach (sort { $fields{$a} <=> $fields{$b} } keys %fields) {
    push @oFields, $_;
  }

  return \@oFields;
}

# -----------------------------------------------

sub add
{
  my $self = shift;

  $self->{'definition'} .= "\r\n" if (length($self->{'definition'}) > 0);
  $self->{'definition'} .= $self->_createDefinition;
  # Set the new definition as attribute value of the object (parameter)
  $self->{'attribute'}->value($self->{'definition'});
  # Execute the update method of the parameter object
  # So we save the attribute values to the parameter table
  if ($self->{'parentO'}->exists == 0) {
    $self->{'parentO'}->insert;
  }
  $self->{'parentO'}->update;
}

# -----------------------------------------------

sub remove
{
  my $self = shift;

  my @newDefinitions;
  my @oldDefinitions = split /\r\n/, $self->{'definition'};
  foreach my $definition (@oldDefinitions) {
    my @values = split /;/, $definition;
    if ($self->elementType <= 1) {
      # We have a FieldObj or a LabelObj
      if (!($values[4] eq $self->elementType && 
          lc($values[18]) eq lc($self->name))) { 
        push @newDefinitions, $definition;
      }
    } elsif ($self->elementType == 2) {
      # We DONT talk to a FieldTab (is only done by editing fields)
    }
  }

  $self->{'definition'} = join "\r\n", @newDefinitions;
  $self->{'attribute'}->value($self->{'definition'});
  $self->{'parentO'}->update;
}

# -----------------------------------------------

sub update
{
  my $self = shift;
  
  my @newDefinitions;
  my @oldDefinitions = split /\r\n/, $self->{'definition'};

  foreach my $definition (@oldDefinitions) {
    my @values = split /;/, $definition;
    if ($self->elementType <= 1) {
      if ($values[4] eq $self->elementType &&
          lc($values[18] eq lc($self->name))) {
        $definition = $self->_createDefinition;
      }
      push @newDefinitions, $definition;
    } elsif ($self->elementType == 2) {
      if ($values[0] eq $self->name) {
        $definition = $self->_createDefinition;
      }
      push @newDefinitions, $definition;
    }
  }

  $self->{'definition'} = join "\r\n", @newDefinitions;
  $self->{'attribute'}->value($self->{'definition'});
  $self->{'parentO'}->update;
}

# -----------------------------------------------

sub name
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'element'} = $value;
  } else {
    return $self->{'element'};
  }
}

# -----------------------------------------------

sub namenew
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'namenew'} = $value;
    # save a new field both in the FelderObjXX and FelderTabXX string
    $self->_parseFieldObj(18,$value);
    $self->_parseFieldTab(0,$value);
  } else {
    if (defined $self->{'namenew'}) {
      return $self->{'namenew'};
    } else {
      return $self->{'element'};
    }
  }
}

# -----------------------------------------------
#
#sub attributeType
#{
# my $self = shift;
#  my $value = shift;
#
#  if (defined $value) {
#    $self->{'attribute_type'} = $value;
#  } else {
#    return $self->{'attribute_type'};
#  }
#}
#
# -----------------------------------------------
#
#sub attributeLength
#{
# my $self = shift;
#  my $value = shift;
#
#  if (defined $value) {
#    $self->{'attribute_length'} = $value;
#  } else {
#    return $self->{'attribute_length'};
#  }
#}
#
# -----------------------------------------------

sub elementType
{
  my $self = shift;

  return $self->{'element_type'};
}

# -----------------------------------------------

sub xCoord
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'x_coord'} = $value;
    # We save the new value to the attribute
    $self->_parseFieldObj(0,$value);
  } else {
    if (defined $self->{'x_coord'}) {
      return $self->{'x_coord'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub yCoord
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'y_coord'} = $value;
    $self->_parseFieldObj(1,$value);
  } else {
    if (defined $self->{'y_coord'}) {
      return $self->{'y_coord'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub width1 
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'width1'} = $value;
    $self->_parseFieldObj(2,$value);
  } else {
    if (defined $self->{'width1'}) {
      return $self->{'width1'};
    } else {
      return 1500;
    }
  }
}

# -----------------------------------------------

sub height
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'height'} = $value;
    $self->_parseFieldObj(3,$value);
  } else {
    if (defined $self->{'height'}) {
      return $self->{'height'};
    } else {
      return 300;
    }
  }
}

# -----------------------------------------------

sub type
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'type'} = $value;
    $self->_parseFieldObj(5,$value);
  } else {
    if (defined $self->{'type'}) {
      return $self->{'type'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub parent
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'parent'} = $value;
    $self->_parseFieldObj(10,$value);
  } else {
    if (defined $self->{'parent'}) {
      return $self->{'parent'};
    } elsif ($self->{'element_type'} == 0) {
      return -1;
    } elsif ($self->{'element_type'} == 1) {
      return 0;
    }
  }
}

# -----------------------------------------------

sub fontSize
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'font_size'} = $value;
    $self->_parseFieldObj(11,$value);
  } else {
    if (defined $self->{'font_size'}) {
      return $self->{'font_size'};
    } else {
      return 8;
    }
  }
}

# -----------------------------------------------

sub fontBold
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'font_bold'} = $value;
    $self->_parseFieldObj(12,$value);
  } else {
    if (defined $self->{'font_bold'}) {
      return $self->{'font_bold'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub fontItalic
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'font_italic'} = $value;
    $self->_parseFieldObj(13,$value);
  } else {
    if (defined $self->{'font_italic'}) {
      return $self->{'font_italic'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub fontUnderline
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'font_underline'} = $value;
    $self->_parseFieldObj(14,$value);
  } else {
    if (defined $self->{'font_underline'}) {
      return $self->{'font_underline'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub fontOffset
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'font_offset'} = $value;
    $self->_parseFieldObj(15,$value);
  } else {
    if (defined $self->{'font_offset'}) {
      return $self->{'font_offset'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub fontColor
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'font_color'} = $value;
    $self->_parseFieldObj(16,$value);
  } else {
    if (defined $self->{'font_color'}) {
      return $self->{'font_color'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub fontName
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'font_name'} = $value;
    $self->_parseFieldObj(17,$value);
  } else {
    if (defined $self->{'font_name'}) {
      return $self->{'font_name'};
    } else {
      return "MS Sans Serif";
    }
  }
}

# -----------------------------------------------

sub listTextValue
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'list_text_value'} = $value;
    $self->_parseFieldObj(19,$value);
  } else {
    return $self->{'list_text_value'};
  }
}

# -----------------------------------------------

sub inputAttitudeType
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'input_attitude_type'} = $value;
    $self->_parseFieldObj(20,$value);
  } else {
    if (defined $self->{'input_attitude_type'}) {
      return $self->{'input_attitude_type'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub fieldDependency
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'field_dependency'} = $value;
    $self->_parseFieldObj(21,$value);
  } else {
    return $self->{'field_dependency'};
  }
}

# -----------------------------------------------

sub valueDependency
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'value_dependency'} = $value;
    $self->_parseFieldObj(22,$value);
  } else {
    return $self->{'value_dependency'};
  }
}

# -----------------------------------------------

sub userAdd
{
  # PRE: value = comma separated string of usernames
  # POST: comma separated string of usernames
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'user_add'} = $value;
    $self->_parseFieldObj(23,$value);
  } else {
    return $self->{'user_add'};
  }
}

# -----------------------------------------------

sub userLocked
{
  # PRE: value = comma separated string of usernames
  # POST: comma separated string of usernames 
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'user_locked'} = $value;
    $self->_parseFieldObj(24,$value);
  } else {
    return $self->{'user_locked'};
  }
}

# -----------------------------------------------

sub fieldName
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'field_name'} = $value;
    $self->_parseFieldObj(25,$value);
  } else {
    return $self->{'field_name'};
  }
}

# -----------------------------------------------

sub caption
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'caption'} = $value;
    $self->_parseFieldTab(1,$value);
  } else {
    return $self->{'caption'};
  }
}

# -----------------------------------------------

sub position
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'position'} = $value;
    $self->_parseFieldTab(2,$value);
  } else {
    if (defined $self->{'position'}) {
      return $self->{'position'};
    } else {
      return 0;
    }
  }
}

# -----------------------------------------------

sub width 
{
  my $self = shift;
  my $value = shift; 

  if (defined $value) {
    $self->{'width'} = $value;
    $self->_parseFieldTab(3,$value);
  } else {
    if (defined $self->{'width'}) {
      return $self->{'width'};
    } else {
      return 0;
    }
  }
}

1;

__END__

=head1 NAME

  Archivista::BL::Form;

=head1 SYNOPSYS


=head1 DESCRIPTION


=head1 DEPENDENCIES


=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: Form.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:21  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.3  2006/03/06 09:35:55  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.2  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.10  2005/06/02 18:29:53  ms
# Implementing update for mask definition
#
# Revision 1.9  2005/05/06 15:43:03  ms
# Bugfix an FieldTab/FieldObj, edit mask definition name, sql definitions for user
#
# Revision 1.8  2005/05/04 16:59:56  ms
# Changes for archive server mask definitions
#
# Revision 1.7  2005/04/29 16:25:26  ms
# Mask definition development
#
# Revision 1.6  2005/04/28 13:15:30  ms
# Implementing alter table module
#
# Revision 1.5  2005/04/07 17:42:49  ms
# Entwicklung von alter table fuer das hinzufuegen und loeschen von feldern in der
# datenbank
#
# Revision 1.4  2005/04/01 17:52:56  ms
# Weiterentwicklung an FelderTab/FelderObj
#
# Revision 1.3  2005/03/31 18:18:14  ms
# Weiterentwicklung an formular elemente (hinzufügen neuer elemente)
#
# Revision 1.2  2005/03/24 12:14:31  ms
# UML Dokumentation und Fertigstellung FelderTab / FelderObj
#
# Revision 1.1  2005/03/23 17:35:46  ms
# File added to project
#
