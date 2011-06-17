# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:20 $

package Archivista::BL::Attribute;

use strict;

use vars qw ( $VERSION );

use Archivista::BL::Form;
use Archivista::BL::Scan;
use Archivista::BL::OCR;
use Archivista::BL::Barcode;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init
  {
    my $self = shift;

    $self->{'attributes'} = {};
    $self->{'modified'} = {};
  }

# -----------------------------------------------
# PUBLIC METHODS

sub new
  {
    my $cls = shift;
    my $self = {};

    bless $self, $cls;
	
    $self->_init;
	
    return $self;
  }

# -----------------------------------------------

sub id
  {
    my $self = shift;
    my $attributeId = shift;

    if (defined $attributeId) {
      $self->{'attribute_id'} = $attributeId;
    } else {
      return $self->{'attribute_id'};
    }
  }

# -----------------------------------------------

sub parentId
  {
    # Hold the id of the parent. 
    # Parents are parameters, users, documents, pages ...
    # $archive->document->attribute => documentId is parentId
    my $self = shift;
    my $parentId = shift;

    if (defined $parentId) {
      $self->{'parent_id'} = $parentId;
    } else {
      return $self->{'parent_id'};
    }
  }

# -----------------------------------------------

sub archive
  {
    # Hold the archive object
    my $self = shift;
    my $archive = shift;

    if (defined $archive) {
      $self->{'archiveO'} = $archive;
    } else {
      return $self->{'archiveO'};
    }
  }

# -----------------------------------------------

sub parent
  {
    # Hold the parent object, the object who invoque the attribute package
    # (parameter, user, document, page ... )
    # $archive->document->attribute => document object
    my $self = shift;
    my $parent = shift;

    if (defined $parent) {
      $self->{'parentO'} = $parent;
    } else {
      return $self->{'parentO'};
    }
  }

# -----------------------------------------------

sub all
  {
    my $self = shift;

    return $self->{'attributes'};
  }

# -----------------------------------------------

sub value
  {
    my $self = shift;
    my $value = shift;
    my $modified = shift;

    my $parentId = $self->parentId;
    my $key = $self->id;

    if (defined $value) {
      # Check for standard modifications
			
      if ($parentId eq "FeldBreite" && $key eq "Inhalt") {
	      # Parameter FeldBreite must be between 300 and 9000
	      if ($value != -1) {
	        $value = "3000" if ($value < 300 or $value > 9000);
				}
      }
      $self->{'attributes'}->{$key} = $value;
    } else {
      return $self->{'attributes'}->{$key};
    }

    if (defined $modified) {
      $self->{'modified'}->{$key} = $modified;
    } else {
      $self->{'modified'}->{$key} = 1;
    }
  }

# -----------------------------------------------

sub remove
  {
    my $self = shift;

    my $key = $self->id;

    delete $self->{'attributes'}->{$key};
    delete $self->{'modified'}->{$key};
  }

# -----------------------------------------------

sub modified
  {
    my $self = shift;

    my $key = $self->id;

    return $self->{'modified'}->{$key};
  }

# -----------------------------------------------

sub field
  {
    my $self = shift;
    my $field = shift;
    my $parentId = $self->parentId;
    if ($parentId =~ /^FelderObj/) {
      return Archivista::BL::Form->fieldObj($self,$field);
    } elsif ($parentId =~ /^FelderTab/) {
      return Archivista::BL::Form->fieldTab($self,$field);
    }
  }

# -----------------------------------------------

sub fields
  {
    # POST: pointer to Hash(fieldName,fieldObject)
    # fieldObject is the same object returned by Archivista::BL::Attribute::field
    my $self = shift;
    my $retDS = shift;		# Return data structur (ARRAY or HASH)
    my $parentId = $self->parentId;
    if ($parentId =~ /^FelderObj/) {
      return Archivista::BL::Form->fieldObjs($self);
    } elsif ($parentId =~ /^FelderTab/) {
      return Archivista::BL::Form->fieldTabs($self,$retDS);
    }
  }

# -----------------------------------------------

sub label
  {
    my $self = shift;
    my $label = shift;
    return Archivista::BL::Form->labelObj($self,$label);
  }

# -----------------------------------------------

sub form
  {
    my $self = shift;

    return Archivista::BL::Form->self($self);
  }

# -----------------------------------------------

sub scan
  {
    # Create a link from 
    # $archive->parameter('ScannenDefinitionen')->attribute('Inhalt')
    # to the scan field parser module
    my $self = shift;
    my $definition = shift;
    return Archivista::BL::Scan->definition($self,$definition);
  }

# -----------------------------------------------

sub scans 
{
  # Return all scan definitions
  my $self = shift;
  my $retDS = shift;

  return Archivista::BL::Scan->definitions($self,$retDS);
}

# -----------------------------------------------

sub ocr
  {
    # Create a link from 
    # $archive->parameter('OCRSets')->attribute('Inhalt')
    # to the ocr field parser module
    my $self = shift;
    my $definition = shift;
	
    return Archivista::BL::OCR->definition($self,$definition);
  }

# -----------------------------------------------

sub ocrs {
  # Return all ocr definitions
  my $self = shift;
  my $retDS = shift;

  return Archivista::BL::OCR->definitions($self,$retDS);
}

# -----------------------------------------------

sub barcode
  {
    # Create a link from
    # $archive->parameter('Barcodes')->attribute('Inhalt')
    # to the barcode parser module
    my $self = shift;
    my $definition = shift;

    return Archivista::BL::Barcode->definition($self,$definition);
  }

# -----------------------------------------------

sub barcodes
  {  
    # Return all barcode definitions
    my $self = shift;
    my $retDS = shift;

    return Archivista::BL::Barcode->definitions($self,$retDS);
  }

1;

__END__

=head1 NAME

  Archivista::BL::Attribute;

=head1 SYNOPSYS

  $archive->document->attribute($attributeId)->value($attributeValue);
  $archive->document->page->attribute($attributeId)->value($attributeValue);
  $archive->user->attribute($attributeId)->value($attributeValue);
  $archive->parameter($parameterId)->attribute($attributeId)->field($fieldId)->xCoord;
	$archive->parameter('ScannenDefinitionen')->attribute('Inhalt')->scan($definition)->name;
  $archive->parameter('Barcodes')->attribute('Inhalt')->barcode($definition)->name;

=head1 DESCRIPTION

  This package provides methods to deal with attributes of a database table

=head1 DEPENDENCIES

  -

=head1 EXAMPLE

  use Archivista;

	my $archive = Archivista->archive("averl","localhost","root","admin");

  $archive->document(1);
  $archive->document->attribute("Titel")->value("First document");
  $archive->document->update;
  $archive->clearDocument(1);

	$archive->document(2);
  $archive->document->page(1);
	$archive->document->attribute("Text")->value("A simple OCR recognition");
  $archive->document->page->update;
  $archive->document->clearPage(1);
  $archive->clearDocument(2);

  $archive->user(1);
  $archive->user->attribute("Alias")->value("ms");
  $archive->user->attribute("Level")->value(3);
  $archive->user->update;

  my $fieldObj = $archive->parameter("FelderObj00")->attribute("Inhalt");
	my $personObj = $fieldObj->field("Personen");
	my $xCoord = $personObj->xCoord;

	$personObj->xCoord(800);
	$archive->parameter->update;

	my $scanObj = $archive->parameter("ScannenDefinitionen")->attribute("Inhalt");
	my $a4Definition = $scanObj->scan("A4 (SW)");
	
=head1 TODO


=head1 AUTHOR

  Markus Stocker, Archivista GmbH Zurich

=cut

# Log record
# $Log: Attribute.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:20  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.6  2006/11/07 17:09:44  up
# Changes for scanning definitions
#
# Revision 1.5  2006/03/27 10:26:18  up
# Mask definition again, rotation b/w images, barcode recognition (multiple
# barcodes)
#
# Revision 1.4  2006/03/06 09:35:55  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.3  2005/11/15 12:27:45  ms
# Updates Herr Wolff
#
# Revision 1.2  2005/11/15 12:14:42  up
# Updates Mr. Wolff
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.15  2005/07/11 16:45:48  ms
# Implementing Barcode Module
#
# Revision 1.14  2005/06/15 15:47:09  ms
# Implementation scan definition parsing
#
# Revision 1.13  2005/06/10 17:35:52  ms
# Implement scan definition parsing module
#
# Revision 1.12  2005/06/02 18:29:53  ms
# Implementing update for mask definition
#
# Revision 1.11  2005/05/27 15:45:17  ms
# Erweiterungen/Anpassungen LinuxTag WebClient/ArchivistaBox
#
# Revision 1.10  2005/05/06 15:43:03  ms
# Bugfix an FieldTab/FieldObj, edit mask definition name, sql definitions for user
#
# Revision 1.9  2005/04/29 16:25:26  ms
# Mask definition development
#
# Revision 1.8  2005/04/07 17:42:49  ms
# Entwicklung von alter table fuer das hinzufuegen und loeschen von feldern in der
# datenbank
#
# Revision 1.7  2005/04/01 17:52:56  ms
# Weiterentwicklung an FelderTab/FelderObj
#
# Revision 1.6  2005/03/24 12:14:31  ms
# UML Dokumentation und Fertigstellung FelderTab / FelderObj
#
# Revision 1.5  2005/03/23 17:35:25  ms
# Entwicklung am parsing von FelderObj
#
# Revision 1.4  2005/03/18 15:38:42  ms
# Stabile version um User hinzuzufügen
#
# Revision 1.3  2005/03/15 18:39:22  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.2  2005/03/11 15:01:07  ms
# Anpassungen
#
# Revision 1.1.1.1  2005/03/11 14:01:22  ms
# Archivista Perl Class Library Projekt imported
#
# Revision 1.1  2005/03/10 17:59:33  ms
# File added
#
