# Current revision $Revision: 1.3 $
# Latest change by $Author: upfister $ on $Date: 2010/03/04 15:02:52 $

package Archivista::BL::Scan;

use strict;
use Archivista::Config;
use Archivista::Util::FS;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.3 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init {
  my $self = shift;
  $self->{'attribute'}->id("Art");
  $self->{'attribute'}->value("parameter");
  $self->{'attribute'}->id("Tabelle");
  $self->{'attribute'}->value("parameter");
  $self->{'attribute'}->id("Inhalt");
}






sub _initScanDefinition {
  my $self = shift;
	my $aktdef = shift;
  my @scanval = split(/;/,$aktdef);
  $self->name($scanval[0]);
  $self->scanType($scanval[1]);
  $self->dpi($scanval[2]);
  $self->_x($scanval[3]);
  $self->_y($scanval[4]);
  $self->_left($scanval[5]);
  $self->_top($scanval[6]);
  $self->rotation($scanval[7]);
  $self->postProcessing($scanval[8]);
  $self->splitPage($scanval[9]);
  $self->ocr($scanval[10]);
  $self->adf($scanval[11]);
  # If field 11 contains a value >= 2 then we have seconds for auto-pilot
  $self->waitSeconds($scanval[11]);
  $self->numberOfPages($scanval[12]);
  $self->brightness($scanval[13]);
  $self->contrast($scanval[14]);
  $self->gamma($scanval[15]);
  $self->newDocument($scanval[16]);
  $self->adjust($scanval[17]);
  $self->notactive($scanval[18]);
  $self->truncate($scanval[19]);
  $self->newDocAfterPages($scanval[20]);
  $self->sleep($scanval[21]);
  $self->key($scanval[22]);
  $self->emptyPages($scanval[23]);
  $self->optimizeOn($scanval[24]);
  $self->optimizeRadius($scanval[25]);
  $self->optimizeOutputDPI($scanval[26]);
  $self->autoFields($scanval[27]);
  $self->boxBarcodeDef($scanval[28]);
	$self->optimizeThreshold($scanval[29]);
	$self->formRecognition($scanval[30]);
	$self->jpegCompression($scanval[31]);
	$self->detectDoubleFeed($scanval[32]);
}






sub _createScanDefinition {
  my $self = shift;
  my $definition;
  $definition = $self->name.";";
  $definition .= $self->scanType.";";
  $definition .= $self->dpi.";";
  $definition .= $self->_x.";";
  $definition .= $self->_y.";";
  $definition .= $self->_left.";";
  $definition .= $self->_top.";";
  $definition .= $self->rotation.";";
  $definition .= $self->postProcessing.";";
  $definition .= $self->splitPage.";";
  $definition .= $self->ocr.";";
  if ($self->adf >= 2) {
    $definition .= $self->waitSeconds.";";
  } else {
    $definition .= $self->adf.";";
  }
  $definition .= $self->numberOfPages.";";
  $definition .= $self->brightness.";";
  $definition .= $self->contrast.";";
  $definition .= $self->gamma.";";
  $definition .= $self->newDocument.";";
  $definition .= $self->adjust.";";
  $definition .= $self->notactive.";";
  $definition .= $self->truncate.";";
  $definition .= $self->newDocAfterPages.";";
  $definition .= $self->sleep.";";
  $definition .= $self->key.";";
  $definition .= $self->emptyPages.";";
  $definition .= $self->optimizeOn.";";
  $definition .= $self->optimizeRadius.";";
  $definition .= $self->optimizeOutputDPI.";";
  $definition .= $self->autoFields.";";
  $definition .= $self->boxBarcodeDef.";";
	$definition .= $self->optimizeThreshold.";";
	$definition .= $self->formRecognition.";";
	$definition .= $self->jpegCompression.";";
	$definition .= $self->detectDoubleFeed.";";
  return $definition;
}






sub _allScanDefinitions {
  my $self = shift;
  my $attribute = shift;
  my @scanDefinitions;
  foreach my $definition (split /\r\n/, $attribute->value) {
    my @values = split /;/, $definition;
    push @scanDefinitions, $values[0];
  }
  return \@scanDefinitions;
}






sub _x {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'x'} = $value;
  } else {
    return $self->{'x'};
  }
}





sub _y {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'y'} = $value;
  } else {
    return $self->{'y'};
  }
}






sub _left {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'left'} = $value;
  } else {
    return $self->{'left'};
  }
}






sub _top {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'top'} = $value;
  } else {
    return $self->{'top'};
  }
}






sub _parseToTwain {
  my $value = shift;
  return int (($value * 56.692) + 0.499);
}






sub _parseToMM {
  my $value = shift;
  return int (($value / 56.692) + 0.499);
}






sub _parseContrast {
  my $value = shift;
  return int ($value / 10);
}






sub _parseBrightness {
  my $value = shift;
  return int ($value / 10);
}






# PUBLIC METHODS

sub definition {
  my $cls = shift;
  my $attribute = shift;	# Object of Archivisita::BL::Attribute
  my $scanDefinition = shift;
  my $parent = $attribute->parent;
  my $self = {};
  bless $self, $cls;
  $self->{'attribute'} = $attribute;
  $self->{'parentO'} = $parent;
  $self->{'definition'} = $attribute->value;
  $self->{'scan_definition'} = $scanDefinition;
  $self->{'scan_definition_id'} = $scanDefinition;
	
  my @defs=split(/\r\n/,$self->{definition}); # get the current scan def
	my $aktdef = $defs[0];
	foreach(@defs) {
	  my $tempdef = $_;
    my @vals=split(/;/,$tempdef);
		if ($vals[0] eq $scanDefinition) {
      $aktdef=$tempdef;
			last;
		}
	}
  $self->_initScanDefinition($aktdef);
  $self->_init;
  return $self;
}






sub definitions {
  # Return an array or hash representation of all scan definitions
  # Pointer to Array(DefName)
  # Pointer to Hash(DefName, Object of Archivista::BL::Scan)
  #            Hash(DefName, 'delete') -> 0/1
  #            Hash(DefName, 'update') -> 1

  my $cls = shift;
  my $attribute = shift;
  my $retDS = shift;
  $retDS = "ARRAY" if (! defined $retDS);
  
  my $padefinitions = $cls->_allScanDefinitions($attribute);

  if (uc($retDS) eq "ARRAY") {
    return $padefinitions;
  } elsif (uc($retDS) eq "HASH") {
    my $count = 0;
    my %scanDefinitions;
    foreach my $definition (@$padefinitions) {
	    $scanDefinitions{$definition} = $cls->definition($attribute,$definition);
	    # First definition can't be deleted
	    if ($count == 0) {
	      $scanDefinitions{$definition}{'delete'} = 0;
	    } else {
	      $scanDefinitions{$definition}{'delete'} = 1;
	    }
	    $scanDefinitions{$definition}{'update'} = 1;
	    $count++;
    }
    return \%scanDefinitions;
  }  
}







sub add {
  my $self = shift;
	my @oldDefinitions = split /\r\n/, $self->{'definition'};
	my $ok=1;
	$self->name="New scan def" if $self->name eq "";
  foreach my $definition (@oldDefinitions) {
    my @values = split /;/, $definition;
	  if ($values[0] eq $self->name) {
		  $ok=0;
			last;
	  }
	}
  return if $ok==0;	
  $self->{'definition'} .= "\r\n" if (length($self->{'definition'}) > 0);
  $self->{'definition'} .= $self->_createScanDefinition;
  # Set the new definition as attribute value of the object (parameter)
  $self->{'attribute'}->value($self->{'definition'});
  # Execute the update method of the parameter object
  # So we save the attribute values to the parameter table
  if ($self->{'parentO'}->exists == 0) {
    $self->{'parentO'}->insert;
  }
  $self->{'parentO'}->update;
}






sub remove {
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






sub update {
  my $self = shift;
  my @newDefinitions;
  my @oldDefinitions = split /\r\n/, $self->{'definition'};
	my $ok=1;
	$self->name=$self->id if $self->name eq "";
	if ($self->id ne $self->name) {
    foreach my $definition (@oldDefinitions) {
      my @values = split /;/, $definition;
			if ($values[0] eq $self->name) {
			  $ok=0;
				last;
			}
	  }
	}
	return if $ok==0;
  foreach my $definition (@oldDefinitions) {
    my @values = split /;/, $definition;
    if ($values[0] eq $self->id) {
    	$definition = $self->_createScanDefinition;
    }
    push @newDefinitions, $definition;
  }
	my $outdef = "";
	my $nokey = 10000;
	my %defs = ();
	my @pos = ();
  for (my $nr=0;$nr<=@newDefinitions-1;$nr++) {
    my @vals = split(";",$newDefinitions[$nr]);
		my $key = $vals[22];
		$key = $nokey if $key==0;
		if ($defs{$key} ne "") {
		  for (my $c=10000;$c<19000;$c++) {
			  if ($defs{$c} eq "") {
				  $key = $c;
					last;
				}
			}
		}
		$defs{$key} = $newDefinitions[$nr];
		$pos[$nr] = $key;
	}
	@pos = sort { $a <=> $b } @pos;
	my $checknew = abs($pos[0]);
	if ($defs{$checknew} ne "") {
	  my $key = 0;
    for (my $c=10000;$c<19000;$c++) {
		  if ($defs{$c} eq "") {
			  $key = $c;
				last;
			}
		}
		if ($key>0) {
		  $defs{$key} = $defs{$pos[0]};
		  $pos[0] = $key;
		}
	} else {
		$defs{$checknew} = $defs{$pos[0]};
		$pos[0] = $checknew;
	}
	@pos = sort { $a <=> $b } @pos;
	if ($pos[0]==10001) { # we don't have any number, so give it 1 to x
	  for(my $nr=0;$nr<=@pos-1;$nr++) {
		  my $nr1 = $nr+1;
		  $defs{$nr1} = $defs{$pos[$nr]};
		  $pos[$nr]=$nr1;
		}
	}
	my $out = ""; 
	for (my $nr=0;$nr<=@pos-1;$nr++) {
	  my $def = $defs{$pos[$nr]};
		my @vals = split(";",$def);
		$vals[22] = $pos[$nr];
		$def = join(";",@vals);
		$out .= $def ."\r\n";
	}
  #$self->{'definition'} = join "\r\n", @newDefinitions; # old (not sorted)
  $self->{'definition'} = $out;
  $self->{'attribute'}->value($self->{'definition'});
  $self->{'parentO'}->update;
}






sub name {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
	  $value =~ s/\;/ /g;
    $self->{'scan_definition'} = $value;
  } else {
    return $self->{'scan_definition'};
  }
}






sub id {
  my $self = shift;
  return $self->{'scan_definition_id'};
}






sub scanType {
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'scan_type'} = $value;
    # We save the new value to the attribute
  } else {
    my $scanType = $self->{'scan_type'};
    if ($scanType >= 0 && $scanType <= 2) {
      return $scanType;
    } else {
	    return 1;
    }
  }
}






sub dpi {
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'dpi'} = $value;
  } else {
    if (defined $self->{'dpi'}) {
      return $self->{'dpi'}; 
    } else {
	    return 300;
    }
  }
}






sub x {
  # Setter: we have mm and must convert to twain
  # Getter: we have twain and must convert to mm
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $value = _parseToTwain($value);
    $self->{'x'} = $value;
  } else {
    return _parseToMM($self->{'x'});
  }  
}






sub y {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $value = _parseToTwain($value);
    $self->{'y'} = $value;
  } else {
    return _parseToMM($self->{'y'});
  }
}






sub left {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $value = _parseToTwain($value);
    $self->{'left'} = $value;
  } else {
    return _parseToMM($self->{'left'});
  }
}






sub top {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $value = _parseToTwain($value);
    $self->{'top'} = $value;
  } else {
    return _parseToMM($self->{'top'});
  }
}






sub rotation {
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'rotation'} = $value;
  } else {
    if (defined $self->{'rotation'}) {
      return $self->{'rotation'};
    } else {
      return 0;
    }
  }
}






sub postProcessing {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'post_processing'} = $value;
  } else {
    if (defined $self->{'post_processing'}) {
      return $self->{'post_processing'};
    } else {
      return -1;
    }
  }
}






sub splitPage {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'split_page'} = $value;
  } else {
    if (defined $self->{'split_page'}) {
      return $self->{'split_page'};
    } else {
      return 0;
    }
  }
}






sub ocr {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'ocr'} = $value;
  } else {
    if (defined $self->{'ocr'}) {
      return $self->{'ocr'};
    } else {
      return -1;
    }
  }
}






sub adf {
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'adf'} = $value;
  } else {
    if (defined $self->{'adf'}) {
      return $self->{'adf'};
    } else {
      return 0;
    }
  }
}







sub waitSeconds {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    if ($self->adf >= 2) {
      # We selected auto-pilot
      # Save the value as ADF to the definition
      # The value can't be <= 2
      $value = 2 if ($value < 2);
      $self->{'wait_seconds'} = $value;
      $self->{'adf'} = 2;
    }
  } else {
    if (defined $self->{'wait_seconds'}) {
      return $self->{'wait_seconds'};
    } else {
      return 2;
    }
  }
}






sub numberOfPages {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'number_of_pages'} = $value;
  } else {
    my $nrOfPages = $self->{'number_of_pages'};
    if ($nrOfPages < 1) {
      return 1;
    }  elsif ($nrOfPages > 640) {
      return 640;
    } else {
      return $nrOfPages;
    }
  }
}






sub brightness {
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'brightness'} = $value;
  } else {
    if (defined $self->{'brightness'}) {
      return $self->{'brightness'};  
    } else {
      return 0;
    }
  }
}






sub contrast {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'contrast'} = $value;
  } else {
    if (defined $self->{'contrast'}) {
      return $self->{'contrast'};
    } else {
      return 0;
    }
  }
}






sub emptyPages {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'emptyPages'} = $value;
  } else {
    if (defined $self->{'emptyPages'}) {
      return $self->{'emptyPages'};
    } else {
      return 0;
    }
  }
}



sub gamma {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'gamma'} = $value;
  } else {
    if (defined $self->{'gamma'}) {
      return $self->{'gamma'};
    } else {
      return 1800;
    }
  }
}






sub newDocument {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'new_document'} = $value;
  } else {
    return $self->{'new_document'};
  }
}






sub adjust {
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'adjust'} = $value;
  } else {
    return $self->{'adjust'};
  }
}






sub notactive {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'notactive'} = $value;
  } else {
    return $self->{'notactive'};
  }
}






sub truncate {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'truncate'} = $value;
  } else {
    return $self->{'truncate'};
  }
}






sub bwOptimisation {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'bw_optimisation'} = $value;
  } else {
    return $self->{'bw_optimisation'};
  }
}






sub sleep {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'sleep'} = $value;
  } else {
    return $self->{'sleep'};
  }
}






sub newDocAfterPages {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'newDocAfterPages'} = $value;
  } else {
    return $self->{'newDocAfterPages'};
  }
}






sub key {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'key'} = $value;
  } else {
    return $self->{'key'};
  }
}






# Schwarz/Weiss-Optimierung einschalten

sub optimizeOn {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'optimizeOn'} = $value;
  } else {
    if (defined $self->{'optimizeOn'}) {
      return $self->{'optimizeOn'};
    } else {
      return 0;
    }
  }
}






# radius for b/w optimization

sub optimizeRadius {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'optimizeRadius'} = $value;
  } else {
    if (defined $self->{'optimizeRadius'}) {
      return $self->{'optimizeRadius'};
    } else {
      return 0;
    }
  }
}






# Resolution of output tif file (dpi)

sub optimizeOutputDPI {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'optimizeOutputDPI'} = $value;
  } else {
    if (defined $self->{'optimizeOutputDPI'}) {
      return $self->{'optimizeOutputDPI'};
    } else {
      return 0;
    }
  }
}






# Threshold value

sub optimizeThreshold {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'optimizeThreshold'} = $value;
  } else {
    if (defined $self->{'optimizeThreshold'}) {
      return $self->{'optimizeThreshold'};
    } else {
      return 0;
    }
  }
}





# Form recognition

sub formRecognition {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'formRecognition'} = $value;
  } else {
    if (defined $self->{'formRecognition'}) {
      return $self->{'formRecognition'};
    } else {
      return 0;
    }
  }
}







# Fields we want to fill out automaticially

sub autoFields {
  my $self = shift;
  my $value = shift;

  if (defined $value) {
	  # as we can't use the , + ; we have to quote them
	  $value =~ s/,/\*44\*/g;
		$value =~ s/;/\*59\*/g;
    $self->{'autoFields'} = $value;
  } else {
    if (defined $self->{'autoFields'}) {		  
      return $self->{'autoFields'};
    } else {
      return '';
    }
  }
}






# The desired barcode definition (only BoxSystems)

sub boxBarcodeDef {
  my $self = shift;
  my $value = shift;

  if (defined $value) {
    $self->{'boxBarcodeDef'} = $value;
  } else {
    if (defined $self->{'boxBarcodeDef'}) {
      return $self->{'boxBarcodeDef'};
    } else {
      return 0;
    }
  }
}






# Fujitsu scanner

sub jpegCompression {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'jpegCompression'} = $value;
  } else {
    if (defined $self->{'jpegCompression'}) {
      return $self->{'jpegCompression'};
    } else {
      return '';
    }
  }
}

sub detectDoubleFeed {
  my $self = shift;
  my $value = shift;
  if (defined $value) {
    $self->{'detectDoubleFeed'} = $value;
  } else {
    if (defined $self->{'detectDoubleFeed'}) {
      return $self->{'detectDoubleFeed'};
    } else {
      return 0;
    }
  }
}






1;



__END__

=head1 NAME

  Archivista::BL::Scan;

=head1 SYNOPSYS


=head1 DESCRIPTION


=head1 DEPENDENCIES


=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: Scan.pm,v $
# Revision 1.3  2010/03/04 15:02:52  upfister
# Updated code (active for scan definitions is on, not active most be set)
#
# Revision 1.2  2010/03/04 11:08:24  upfister
# Update for flexible scan definitions
#
# Revision 1.1.1.1  2008/11/09 09:19:22  upfister
# Copy to sourceforge
#
# Revision 1.5  2007/07/25 16:54:40  up
# JPEG/detect doublefeed
#
# Revision 1.4  2007/07/25 02:09:30  up
# Add jpegcompression and doublefeed detection
#
# Revision 1.3  2007/04/15 22:20:04  up
# Added formRecognition parameter
#
# Revision 1.2  2007/02/19 15:56:14  up
# Threshold values
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.8  2006/11/20 22:46:15  up
# Check for existing scan definitions and ; delimeter
#
# Revision 1.7  2006/11/07 17:09:44  up
# Changes for scanning definitions
#
# Revision 1.6  2006/11/06 12:26:08  up
# Add fields for splitting documents
#
# Revision 1.5  2006/03/13 08:14:50  up
# OCR definitions now working correct, mask definition with language strings
#
# Revision 1.4  2006/01/23 10:52:36  mw
# Neues Attribut fuer OCR-Auswahl hinzugefuegt.
#
# Revision 1.3  2005/11/24 04:08:25  up
# Changes for different barcode definitions
#
# Revision 1.2  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
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
