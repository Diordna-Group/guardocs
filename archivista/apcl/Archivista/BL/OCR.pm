# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:21 $

package Archivista::BL::OCR;

use strict;
use Archivista::Config;
use Archivista::Util::FS;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init
{
  my $self = shift;

  $self->{'attribute'}->id("Art");
  $self->{'attribute'}->value("parameter");
  $self->{'attribute'}->id("Tabelle");
  $self->{'attribute'}->value("parameter");
  $self->{'attribute'}->id("Inhalt");
}

# -----------------------------------------------

sub _initOCRDefinition
{
  my $self = shift;

  $self->name($self->_parseOCRDefinition(0));
  $self->lang1($self->_parseOCRDefinition(1));
  $self->lang2($self->_parseOCRDefinition(2));
  $self->lang3($self->_parseOCRDefinition(3));
  $self->lang4($self->_parseOCRDefinition(4));
  $self->lang5($self->_parseOCRDefinition(5));
  $self->quality($self->_parseOCRDefinition(6));
  $self->checkOrientation($self->_parseOCRDefinition(7));
  $self->cleanBeforeRecognition($self->_parseOCRDefinition(8));
  $self->suppressScaling($self->_parseOCRDefinition(9));
  $self->withoutBWConversion($self->_parseOCRDefinition(10));
  $self->tableCellsFromLines($self->_parseOCRDefinition(11));
  $self->noOverlappedCells($self->_parseOCRDefinition(12));
  $self->oneRow($self->_parseOCRDefinition(13));
}

# -----------------------------------------------

sub _parseOCRDefinition
{
  my $self = shift;
  my $keyId = shift; # Position inside the definition (0;1;2;3...)
  my $ocrDefinitionValue = shift;

  my ($definition,@definition);

  foreach my $def (split /\r\n/, $self->{'definition'}) {
    my @values = split /;/, $def;
    if ($values[0] eq $self->id()) {
      if (defined $ocrDefinitionValue) {
        # Setter method
        $values[$keyId] = $ocrDefinitionValue;
      } else {
        # Getter method
        return $values[$keyId];
      }
    }
    $definition = join ";", @values;
    push @definition, $definition . ";";
  }
  # For setter method, update the definition
  $self->{'definition'} = join "\r\n", @definition;
  # Update the attribute
  # The new values are so up-to-date. If we make an $archive->parameter->update
  # the new values are automatically saved to the database
  $self->{'attribute'}->value($self->{'definition'});

  return
}

# -----------------------------------------------

sub _createOCRDefinition
{
  my $self = shift;

  my $definition;

  $definition.=$self->name.";";
  $definition.=$self->lang1.";";
  $definition.=$self->lang2.";";
  $definition.=$self->lang3.";";
  $definition.=$self->lang4.";";
  $definition.=$self->lang5.";";
  $definition.=$self->quality.";";
  $definition.=$self->checkOrientation.";";
  $definition.=$self->cleanBeforeRecognition.";";
  $definition.=$self->suppressScaling.";";
  $definition.=$self->withoutBWConversion.";";
  $definition.=$self->tableCellsFromLines.";";
  $definition.=$self->noOverlappedCells.";";
  $definition.=$self->oneRow.";";

  return $definition;
}

# -----------------------------------------------

sub _allOCRDefinitions
{
  my $self = shift;
  my $attribute = shift;
  my @ocrDefinitions;

  foreach my $definition (split /\r\n/, $attribute->value) {
    my @values = split /;/, $definition;
    push @ocrDefinitions, $values[0];
  }

  return \@ocrDefinitions;
}

# -----------------------------------------------
# PUBLIC METHODS

sub definition
{
  my $cls = shift;
  my $attribute = shift; # Object of Archivisita::BL::Attribute

  my $ocrDefinition = shift;
  my $parent = $attribute->parent;
  my $self = {};

  bless $self, $cls;

  $self->{'ocr_definition'}=$ocrDefinition;
  $self->{'ocr_definition_id'}=$ocrDefinition;
  $self->{'attribute'} = $attribute;
  $self->{'parentO'} = $parent;
  $self->{'definition'} = $attribute->value;

  $self->_initOCRDefinition;
  $self->_init;

  return $self;
}

# -----------------------------------------------

sub definitions
{
  # Return an array or hash representation of all ocr definitions
  # Pointer to Array(DefName)
  # Pointer to Hash(DefName, Object of Archivista::BL::OCR)
  #            Hash(DefName, 'delete') -> 0/1
  #            Hash(DefName, 'update') -> 1
  my $cls = shift;
  my $attribute = shift;
  my $retDS = shift;

  $retDS = "ARRAY" if (! defined $retDS);

  my $padefinitions = $cls->_allOCRDefinitions($attribute);

  if (uc($retDS) eq "ARRAY") {
    return $padefinitions;
  } elsif (uc($retDS) eq "HASH") {
    my %ocrDefinitions;
    my $count=0;
    foreach my $definition (@$padefinitions) {
      $ocrDefinitions{$definition} = $cls->definition($attribute,$definition);
      if (( $count==0 ) || (( $count > 0 ) && (($count+1) < @$padefinitions))) {
	$ocrDefinitions{$definition}{'delete'} = 0;
      } else {
	$ocrDefinitions{$definition}{'delete'} = 1;
      }
      $count++;
      $ocrDefinitions{$definition}{'update'} = 1;
    }
    return \%ocrDefinitions;
  }
}

# -----------------------------------------------

sub add
{
  my $self = shift;

  $self->{'definition'} .= "\r\n" if (length($self->{'definition'}) > 0);
  $self->{'definition'} .= $self->_createOCRDefinition;

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
    if ($values[0] ne $self->id()) {
      push @newDefinitions, $definition;
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

    if ($values[1] eq $self->id()) {

      $definition = $self->_createOCRDefinition;
    }
    push @newDefinitions, $definition;
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
    $self->{'ocr_definition'} = $value;
    $self->_parseOCRDefinition(0,$value);
  } else {
    return $self->{'ocr_definition'};
  }
}

# -----------------------------------------------

sub id
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'ocr_definition_id'} = $value;
    $self->_parseOCRDefinition(0,$value);
  } else {
    return $self->{'ocr_definition_id'};
  }
}

# -----------------------------------------------

sub lang1
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'lang1'} = $value;
    $self->_parseOCRDefinition(1,$value);
  } else {
    return $self->{'lang1'};
  }
}

# -----------------------------------------------

sub lang2
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'lang2'} = $value;
    $self->_parseOCRDefinition(2,$value);
  } else {
    return $self->{'lang2'};
  }
}

# -----------------------------------------------

sub lang3
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'lang3'} = $value;
    $self->_parseOCRDefinition(3,$value);
  } else {
    return $self->{'lang3'};
  }
}

# -----------------------------------------------

sub lang4
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'lang4'} = $value;
    $self->_parseOCRDefinition(4,$value);
  } else {
    return $self->{'lang4'};
  }
}

# -----------------------------------------------

sub lang5
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'lang5'} = $value;
    $self->_parseOCRDefinition(5,$value);
  } else {
    return $self->{'lang5'};
  }
}

# -----------------------------------------------

sub quality
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'quality'} = $value;
    $self->_parseOCRDefinition(6,$value);
  } else {
    return $self->{'quality'};
  }
}

# -----------------------------------------------

sub checkOrientation
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'checkOrientation'} = $value;
    $self->_parseOCRDefinition(7,$value);
  } else {
    return $self->{'checkOrientation'};
  }
}

# -----------------------------------------------

sub cleanBeforeRecognition
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'cleanBeforeRecognition'} = $value;
    $self->_parseOCRDefinition(8,$value);
  } else {
    return $self->{'cleanBeforeRecognition'};
  }
}

# -----------------------------------------------

sub suppressScaling
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'suppressScaling'} = $value;
    $self->_parseOCRDefinition(9,$value);
  } else {
    return $self->{'suppressScaling'};
  }
}

# -----------------------------------------------

sub withoutBWConversion
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'withoutBWConversion'} = $value;
    $self->_parseOCRDefinition(10,$value);
  } else {
      return $self->{'withoutBWConversion'};
  }
}

# -----------------------------------------------

sub tableCellsFromLines
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'tableCellsFromLines'} = $value;
    $self->_parseOCRDefinition(11,$value);
  } else {
      return $self->{'tableCellsFromLines'};
  }
}

# -----------------------------------------------

sub noOverlappedCells
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'noOverlappedCells'} = $value;
    $self->_parseOCRDefinition(12,$value);
  } else {
    return $self->{'noOverlappedCells'};
  }
}

# -----------------------------------------------

sub oneRow
{
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'oneRow'} = $value;
    $self->_parseOCRDefinition(13,$value);
  } else {
      return $self->{'oneRow'};
  }
}

1;



__END__

=head1 NAME

  Archivista::BL::OCR;

=head1 SYNOPSYS


=head1 DESCRIPTION


=head1 DEPENDENCIES


=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: OCR.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:21  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/11/15 12:26:45  ms
# File added to project
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.12  2005/06/19 20:27:17  ms
# Adding scanFormat method
#
# Revision 1.11  2005/06/19 20:04:01  ms
# Bugfix Art/Tabelle on parameter table
# Saving scan type to bits info for logs table
#
# Revision 1.10  2005/06/19 02:10:23  ms
# Fehlerhafte Berechnung Seitenmasse (UP)
#
# Revision 1.9  2005/06/18 21:15:19  ms
# Bugfix auto-pilot / wait seconds
#
# Revision 1.8  2005/06/18 20:00:29  ms
# Bugfix
#
# Revision 1.7  2005/06/18 19:31:26  ms
# Added all param for scanadf
#
# Revision 1.6  2005/06/18 19:04:28  ms
# Changed scan file suffix to sne (SANE)
#
# Revision 1.5  2005/06/17 22:08:08  ms
# Implementing scan over webclient
#
# Revision 1.4  2005/06/17 18:22:19  ms
# Implementation scan from webclient
#
# Revision 1.3  2005/06/15 17:37:45  ms
# Bugfix
#
# Revision 1.2  2005/06/15 15:47:09  ms
# Implementation scan definition parsing
#
# Revision 1.1  2005/06/10 17:36:37  ms
# File added to project
#
