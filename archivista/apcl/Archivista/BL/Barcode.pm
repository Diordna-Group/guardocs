# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:20 $

package Archivista::BL::Barcode;

use strict;
use Archivista::Config;

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

sub _initBarcodeDefinition
{
  my $self = shift;

	$self->name($self->_parseBarcodeDefinition(0));
	$self->position($self->_parseBarcodeDefinition(1));
	$self->firstBarcodeType($self->_parseBarcodeDefinition(2));
  $self->orientation($self->_parseBarcodeDefinition(3));
	$self->checkCharacter($self->_parseBarcodeDefinition(4));
	$self->secondBarcodeType($self->_parseBarcodeDefinition(5));
	$self->verticalStretch($self->_parseBarcodeDefinition(6));
	$self->processing(0,$self->_parseBarcodeDefinition(21));
	$self->processing(1,$self->_parseBarcodeDefinition(22));
	$self->processing(2,$self->_parseBarcodeDefinition(23));
	$self->processing(3,$self->_parseBarcodeDefinition(24));
	$self->processing(4,$self->_parseBarcodeDefinition(25));
	$self->processing(5,$self->_parseBarcodeDefinition(26));
	$self->processing(6,$self->_parseBarcodeDefinition(27));
	$self->processing(7,$self->_parseBarcodeDefinition(28));
}

# -----------------------------------------------

sub _parseBarcodeDefinition
{
  my $self = shift;
	my $keyId = shift; # Position inside the definition (0;1;2;3...)
  my $barcodeDefinitionValue = shift;
	
  my ($definition,@definition);
	
  foreach my $def (split /\r\n/, $self->{'definition'}) {
		my @values = split /;/, $def;
		if ($values[0] eq $self->name) {
			if (defined $barcodeDefinitionValue) {
				# Setter method
				$values[$keyId] = $barcodeDefinitionValue;
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

sub _parseCSV
{
	my $keyId = shift;
	my $barcodeDefinitionValue = shift;

	my @values = split /,/, $barcodeDefinitionValue;

	return $values[$keyId];
}

# -----------------------------------------------

sub _createBarcodeDefinition
{
  my $self = shift;
  
	my $definition;
	
  $definition = $self->name.";";
  $definition .= $self->{'left'}.",";
	$definition .= $self->{'top'}.",";
	$definition .= $self->{'width'}.",";
	$definition .= $self->{'height'}.",";
	$definition .= $self->{'tolerance'}.",";
	$definition .= $self->trials.",";
	$definition .= $self->manual.";";
	$definition .= $self->firstBarcodeType.";";
	$definition .= $self->orientation.";";
	$definition .= $self->checkCharacter.";";
	$definition .= $self->secondBarcodeType.";";
	$definition .= $self->verticalStretch.";";
	
	# Empty values
	for (my $i = 0; $i < 14; $i++) {
		$definition .= "-1;";
	}

  for (my $i = 0; $i <= 7; $i++) {
		$definition .= $self->processing($i).";";
	}
	
	return $definition;
}

# -----------------------------------------------

sub _allBarcodeDefinitions
{
  my $self = shift;
	my $attribute = shift;
	my @barcodeDefinitions;

	foreach my $definition (split /\r\n/, $attribute->value) {
		my @values = split /;/, $definition;
		push @barcodeDefinitions, $values[0];
	}

	return \@barcodeDefinitions;
}

# -----------------------------------------------

sub _parseToTwain
{
  my $value = shift;

  return int (($value * 56.692) + 0.499);
}

# -----------------------------------------------

sub _parseToMM
{
  my $value = shift;
	
	return int (($value / 56.692) + 0.499);
}

# -----------------------------------------------
# PUBLIC METHODS

sub definition
{
  my $cls = shift;
	my $attribute = shift; # Object of Archivisita::BL::Attribute
	my $barcodeDefinition = shift;
	my $parent = $attribute->parent;
  my $self = {};

	bless $self, $cls;

  $self->{'attribute'} = $attribute;
	$self->{'parentO'} = $parent;
	$self->{'definition'} = $attribute->value;
	$self->{'barcode_definition'} = $barcodeDefinition;
  $self->{'barcode_definition_id'} = $barcodeDefinition;
	$self->_initBarcodeDefinition;
  $self->_init;

	return $self;
}

# -----------------------------------------------

sub definitions
{
  # Return an array or hash representation of all barcode definitions
	# Pointer to Array(DefName)
	# Pointer to Hash(DefName, Object of Archivista::BL::Barcode)
	#            Hash(DefName, 'delete') -> 0/1
	#            Hash(DefName, 'update') -> 1
	my $cls = shift;
	my $attribute = shift;
  my $retDS = shift;

	$retDS = "ARRAY" if (! defined $retDS);
	
	my $padefinitions = $cls->_allBarcodeDefinitions($attribute);

  if (uc($retDS) eq "ARRAY") {
		return $padefinitions;
	} elsif (uc($retDS) eq "HASH") {
	  my $count = 0;
		my %barcodeDefinitions;
		foreach my $definition (@$padefinitions) {
			$barcodeDefinitions{$definition} = $cls->definition($attribute,$definition);
			# First definition can't be deleted
			if ($count == 0) {
		  	$barcodeDefinitions{$definition}{'delete'} = 0;
			} else {
				$barcodeDefinitions{$definition}{'delete'} = 1;
			}
			$barcodeDefinitions{$definition}{'update'} = 1;
			$count++;
		}
		return \%barcodeDefinitions;
	}	
}

# -----------------------------------------------

sub add
{
  my $self = shift;

  $self->{'definition'} .= "\r\n" if (length($self->{'definition'}) > 0);
	$self->{'definition'} .= $self->_createBarcodeDefinition;
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
		if ($values[0] ne $self->id) {
			push @newDefinitions, $definition;
		}
	}

	$self->{'definition'} = join "\r\n", @newDefinitions;
	$self->{'attribute'}->value($self->{'definition'});
	$self->{'parentO'}->update;
}

# -----------------------------------------------

sub resetProcessingBarcode
{
  my $self = shift;
	my $idx = shift;
 
  # Processing barcode definitions are stored 
	# in fields with index from 21 to 28
	# We have idx between 0 .. 7 
	$idx = $idx + 21;
	
  my @newDefinitions;
	my @oldDefinitions = split /\r\n/, $self->{'definition'};
	foreach my $definition (@oldDefinitions) {
		my @values = split /;/, $definition;
		if ($values[0] eq $self->id) {
			$values[$idx] = "-1,-1,-1,-1,-1";
			$definition = join ";", @values;
		  $definition = $definition . ";";
		}
		push @newDefinitions, $definition;
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
		if ($values[0] eq $self->id) {
			$definition = $self->_createBarcodeDefinition;
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
		$self->{'barcode_definition'} = $value;
		$self->_parseBarcodeDefinition(0,$value);
	} else {
		if (length($self->{'barcode_definition'}) > 1) {
			return $self->{'barcode_definition'};
		} else {
			return "";
		}
	}
}

# -----------------------------------------------

sub id
{
  my $self = shift;

	return $self->{'barcode_definition_id'};
}

# -----------------------------------------------

sub position
{
  my $self = shift;
  my $value = shift;

	if (defined $value) {
		$self->{'position'} = $value;
		$self->_parseBarcodeDefinition(1,$value);
	  $self->{'left'} = _parseCSV(0,$value);
		$self->{'top'} = _parseCSV(1,$value);
		$self->{'width'} = _parseCSV(2,$value);
		$self->{'height'} = _parseCSV(3,$value);
		$self->{'tolerance'} = _parseCSV(4,$value);
		$self->{'trials'} = _parseCSV(5,$value);
		$self->{'manual'} = _parseCSV(6,$value);
	} elsif (length($self->{'position'}) > 0) {
		my @position;
		push @position, $self->{'left'};
		push @position, $self->{'top'};
		push @position, $self->{'width'};
		push @position, $self->{'height'};
		push @position, $self->{'tolerance'};
		push @position, $self->{'trials'};
		push @position, $self->{'manual'};
		$self->{'position'} = join ",", @position;
		return $self->{'position'};
	} else {
		return 0;
	}
}

# -----------------------------------------------

sub left
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'left'} = _parseToTwain($value);
	} elsif (length($self->{'left'}) > 0) {
		return _parseToMM($self->{'left'});
	} else {
		return 0;
	}
}

# -----------------------------------------------

sub top
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'top'} = _parseToTwain($value);
	} elsif (length($self->{'top'}) > 0) {
		return _parseToMM($self->{'top'});
	} else {
		return 0;
	}
}

# -----------------------------------------------

sub width
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'width'} = _parseToTwain($value);
	} elsif (length($self->{'width'}) > 0) {
		return _parseToMM($self->{'width'});
	} else {
		return 0;
	}
}

# -----------------------------------------------

sub height
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'height'} = _parseToTwain($value);
	} elsif (length($self->{'height'}) > 0) {
		return _parseToMM($self->{'height'});
	} else {
		return 0;
	}
}

# -----------------------------------------------

sub tolerance
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'tolerance'} = _parseToTwain($value);
	} elsif (length($self->{'tolerance'}) > 0) {
		return _parseToMM($self->{'tolerance'});
	} else {
		return 0;
	}
}

# -----------------------------------------------

sub trials
{
  my $self = shift;
	my $value = shift;
	
	if (defined $value) {
		$self->{'trials'} = $value;
	} else {
		if (length($self->{'trials'}) > 0) {
			return $self->{'trials'};
		} else {
			return 1;
		}
	}
}

# -----------------------------------------------

sub manual
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'manual'} = $value;
	} elsif (length($self->{'manual'}) > 0) {
		return $self->{'manual'};
	} else {
		return 0;
	}
}

# -----------------------------------------------

sub firstBarcodeType
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'first_barcode_type'} = $value;
		$self->_parseBarcodeDefinition(2,$value);
	} else {
		return $self->{'first_barcode_type'};
	}
}

# -----------------------------------------------

sub orientation
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'orientation'} = $value;
	  $self->_parseBarcodeDefinition(3,$value);	
	} else {
		return $self->{'orientation'};
	}
}

# -----------------------------------------------

sub checkCharacter
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'check_character'} = $value;
		$self->_parseBarcodeDefinition(4,$value);
	} else {
		return $self->{'check_character'};
	}
}

# -----------------------------------------------

sub secondBarcodeType
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'second_barcode_type'} = $value;
		$self->_parseBarcodeDefinition(5,$value);
	} else {
		return $self->{'second_barcode_type'};
	}
}

# -----------------------------------------------

sub verticalStretch
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'vertical_stretch'} = $value;
		$self->_parseBarcodeDefinition(6,$value);
	} elsif (length($self->{'vertical_stretch'}) > 0) {
		return $self->{'vertical_stretch'};
	} else {
		return 0;
	}
}

# -----------------------------------------------

sub processing 
{
  my $self = shift;
  my $idx = shift;
	my $value = shift;
	
	if (defined $value)  {
		$self->{'processing_'.$idx} = $value;
		$self->processingBarcodeNumber($idx,_parseCSV(0,$value));
		$self->processingBarcodeLength($idx,_parseCSV(1,$value));
		$self->processingBarcodeAttribute($idx,_parseCSV(2,$value));
		$self->processingBarcodeStart($idx,_parseCSV(3,$value));
		$self->processingBarcodeCharacter($idx,_parseCSV(4,$value));
	} else {
	  my @processing;
		push @processing, $self->processingBarcodeNumber($idx);
		push @processing, $self->processingBarcodeLength($idx);
		push @processing, $self->processingBarcodeAttribute($idx);
		push @processing, $self->processingBarcodeStart($idx);
		push @processing, $self->processingBarcodeCharacter($idx);
		$self->{'processing_'.$idx} = join ",", @processing;
    undef @processing;
		return $self->{'processing_'.$idx};
	}
}

# -----------------------------------------------

sub processingBarcodeNumber
{
  my $self = shift;
	my $idx = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'processing_'.$idx.'_number'} = $value; 
	} else {
	  if (length($self->{'processing_'.$idx.'_number'}) > 0) {
			return $self->{'processing_'.$idx.'_number'};
		} else {
			return -1;
		}
	}
}

# -----------------------------------------------

sub processingBarcodeLength
{
  my $self = shift;
	my $idx = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'processing_'.$idx.'_length'} = $value;
	} else {
	  if (length($self->{'processing_'.$idx.'_length'}) > 0) {
			return $self->{'processing_'.$idx.'_length'};
		} else {
			return -1;
		}
	}
}

# -----------------------------------------------

sub processingBarcodeAttribute
{
  my $self = shift;
	my $idx = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'processing_'.$idx.'_attribute'} = $value;
	} else {
		if (length($self->{'processing_'.$idx.'_attribute'}) > 0) {
			return $self->{'processing_'.$idx.'_attribute'};
		} else {
			return -1;
		}
	}
}

# -----------------------------------------------

sub processingBarcodeStart
{
	my $self = shift;
	my $idx = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'processing_'.$idx.'_start'} = $value;
	} else {
	  if (length($self->{'processing_'.$idx.'_start'}) > 0) {
			return $self->{'processing_'.$idx.'_start'};
		} else {
			return -1;
		}
	}
}

# -----------------------------------------------

sub processingBarcodeCharacter
{
	my $self = shift;
	my $idx = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'processing_'.$idx.'_character'} = $value;
	} else {
	  if (length($self->{'processing_'.$idx.'_character'}) > 0) {
			return $self->{'processing_'.$idx.'_character'};
		} else {
			return -1;
		}
	}
}
1;

__END__

=head1 NAME

  Archivista::BL::Barcode;

=head1 SYNOPSYS


=head1 DESCRIPTION


=head1 DEPENDENCIES


=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: Barcode.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:20  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.4  2005/07/18 10:38:58  ms
# Anpassungen Barcode (nicht benötigte Felder wurden rausgenommen)
#
# Revision 1.3  2005/07/13 13:56:14  ms
# Bugfix Barcodes
#
# Revision 1.2  2005/07/12 17:12:35  ms
# Anpassungen für Barcode
#
# Revision 1.1  2005/07/11 16:46:29  ms
# Files added to project
#
