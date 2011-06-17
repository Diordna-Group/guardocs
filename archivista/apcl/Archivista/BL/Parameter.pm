# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:21 $

package Archivista::BL::Parameter;

use strict;

use vars qw ( $VERSION );

use Archivista::BL::Attribute;
use Archivista::DL::Parameter;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init
  {
    my $self = shift;
    my $archive = shift;
    my $type = shift;
    my $parameterId = shift;

    my $db = $archive->db;
    $self->{'attribute'} = Archivista::BL::Attribute->new();
    $self->{'parameterT'} = Archivista::DL::Parameter->new($db,$type);

    my $parameterT = $self->{'parameterT'};

    # Check if getter or setter method
    if (defined $parameterId) {
      # Setter: parameter from data layer
      $parameterT->select($self,$parameterId);
    } else {
      # Getter: insert a new parameter to data layer
      $parameterId = $parameterT->insert();
    }
	
    $self->archive($archive);
    $self->{'parameter_id'} = $parameterId;
  }

# -----------------------------------------------
# PUBLIC METHODS

sub new
  {
    my $cls = shift;
    my $archive = shift;
    my $type = shift;
    my $parameterId = shift;

    my $self = {};

    bless $self, $cls;

    $self->_init($archive, $type, $parameterId);
	
    return $self;
  }

# -----------------------------------------------

sub load
  {
    my $cls = shift;
    my $archive = shift;
    my $archiveName = shift;
	
    my $db = $archive->db;
    Archivista::DL::Parameter->load($db,$archiveName);
  }
# -----------------------------------------------

sub id
  {
    my $self = shift;

    return $self->{'parameter_id'};
  }

# -----------------------------------------------

sub attribute
  {
    my $self = shift;
    my $attributeId = shift;

    if (defined $attributeId) {
      # Set the parameter id as parent id
      $self->{'attribute'}->parentId($self->id);
      # Set the attribute id for the setter method
      $self->{'attribute'}->id($attributeId);
      # Set the parameter object to the attribute
      $self->{'attribute'}->parent($self);
      # Set the archive object to the attribute
      $self->{'attribute'}->archive($self->archive);
    }

    return $self->{'attribute'};
  }

# -----------------------------------------------

sub archive
  {
    my $self = shift;
    my $archive = shift;

    if (defined $archive) {
      $self->{'archive'} = $archive;
    } else {
      return $self->{'archive'};
    }
  }

# -----------------------------------------------

sub insert
  {
    my $self = shift;

    my $parameterT = $self->{'parameterT'};
    my $attribute = $self->{'attribute'};

    $parameterT->insert($self,$attribute);
  }

# -----------------------------------------------

sub update
  {
    my $self = shift;
	
    my $parameterT = $self->{'parameterT'};
    my $attribute = $self->{'attribute'};
 
    $parameterT->update($self,$attribute);
  }

# -----------------------------------------------

sub maskDefinitionName
  {
    my $self = shift;
    my $maskDefinitionName = shift;

    my $parameterT = $self->{'parameterT'};

    return $parameterT->maskDefinitionName($self,$maskDefinitionName);
  }

# -----------------------------------------------

sub maskParentFields
  {
    my $self = shift;
    my $retDS = shift;	       # Return data structure (ARRAY or HASH)
    my $parameterT = $self->{'parameterT'};

    return $parameterT->maskParentFields($self,$retDS);
  }

# -----------------------------------------------

sub exists
  {
    my $self = shift;

    my $parameterT = $self->{'parameterT'};

    return $parameterT->exists($self);
  }

# -----------------------------------------------

sub delete
  {
    my $self = shift;

    my $parameterT = $self->{'parameterT'};
    my $parameterId = $self->id;

    $self->archive->clearParameter($parameterId);
    $parameterT->delete($self);
  }

1;

__END__

=head1 NAME
  
  Archivista::BL::Parameter

=head1 SYNOPSYS

=head1 DESCRIPTION

  This package provides methods to deal with parameters

=head1 DEPENDENCIES

  Archivista::BL::Attribute
  Archivista::DL::Parameter

=head1 EXAMPLE

  use Archivista;

  my $archive = Archivista->archive("averl");

=head1 TODO


=head1 AUTHOR

  Markus Stocker, Archivista GmbH Zurich

=cut

# Log record
# $Log: Parameter.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:21  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2006/01/17 10:17:39  mw
# Zugriff auf normale Parameter (Art=parameter) und Boxparameter
# (Art=Archivistabox) wurde eingefuehrt.
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.11  2005/05/11 18:22:43  ms
# Changes for mask definition (archive server)
#
# Revision 1.10  2005/05/06 15:43:03  ms
# Bugfix an FieldTab/FieldObj, edit mask definition name, sql definitions for user
#
# Revision 1.9  2005/05/04 16:59:56  ms
# Changes for archive server mask definitions
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
# Revision 1.4  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.3  2005/03/21 18:33:20  ms
# Erzeugung neuer archivista datenbanken
#
# Revision 1.2  2005/03/17 17:12:59  ms
# Weiterentwicklung Hinzufügen der Parameter-Tabelle
#
# Revision 1.1  2005/03/17 11:59:09  ms
# File added to project
#
