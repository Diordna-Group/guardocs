# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:19 $

package Archivista::Application::Menu::MenuItem;

use strict;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls)

	IN: class name
	OUT: object

	Constructor for Archivista::Application::Menu::MenuItem

=cut

sub new 
{
  my $cls = shift;
	my $self = {};

  bless $self, $cls;

	return $self;
}

# -----------------------------------------------

=head1 id($self,$id)

	IN: object
	    menu id (optional)
	OUT: integer (for getter method)

	Setter or getter method for menu id. To set the id, give it as second
	parameter of this method. Leave it empty if you want to retrieve the menu id.

=cut

sub id
{
  my $self = shift;
	my $id = shift;

	if (defined $id) {
		$self->{'id'} = $id;
	} else {
		return $self->{'id'};
	}
}

# -----------------------------------------------

=head1 label($self,$label)

	IN: object
	    label string (optional)
	OUT: string (for getter method)

	Setter or getter method for the menu label string. To set the label, give it
	as second parameter of this method. Leave it empty if you want to retrieve the
	menu label string.

=cut

sub label
{
	my $self = shift;
	my $label = shift;

	if (defined $label) {
		$self->{'label'} = $label
	} else {
		return $self->{'label'};
	}
}

# -----------------------------------------------

=head1 absoluteLevel($self,$absoluteLevel)

	IN: object
	    menu absolute level (optional)
	OUT: string (for getter method)

	Setter or getter method for the menu absolute level information

=cut

sub absoluteLevel
{
  my $self = shift;
	my $absoluteLevel = shift;

	if (defined $absoluteLevel) {
		$self->{'absolute_level'} = $absoluteLevel;
	} else {
		return $self->{'absolute_level'};
	}
}

# -----------------------------------------------

=head1 relativeLevel($self,$relativeLevel)

	IN: object
	    menu relative level (optional)
	OUT: string (for getter method)

	Setter or getter method for the menu relative level information
	
=cut

sub relativeLevel
{
  my $self = shift;
	my $relativeLevel = shift;

	if (defined $relativeLevel) {
		$self->{'relative_level'} = $relativeLevel;
	} else {
		return $self->{'relative_level'};
	}
}

# -----------------------------------------------

=head1 relativeLevelOrder($self,$relativeLevelOrder)

	IN: object
	    menu relative level ordering (optional)
	OUT: string (for getter method)

	Setter or getter method for the menu relative ordering information

=cut

sub relativeLevelOrder
{
  my $self = shift;
	my $relativeLevelOrder = shift;

	if (defined $relativeLevelOrder) {
		$self->{'relative_level_order'} = $relativeLevelOrder;
	} else {
		return $self->{'relative_level_order'};
	}
}

# -----------------------------------------------

=head1 relativeParentLevel($self,$relativeParentLevel)

	IN: object
	    relative parent level (optional)
	OUT: string (for getter method)

	Setter or getter method for the relative parent level information

=cut

sub relativeParentLevel
{
	my $self = shift;
	my $relativeParentLevel = shift;

	if (defined $relativeParentLevel) {
		$self->{'relative_parent_level'} = $relativeParentLevel;
	} else {
	  return $self->{'relative_parent_level'};
	}
}

# -----------------------------------------------

=head1 param($self,$param)

	IN: object
	    parameter value (optional)
	OUT: string

	Setter or getter method for parameter

=cut

sub param
{
  my $self = shift;
	my $param = shift;

	if (defined $param) {
		$self->{'param'} = $param;
	} else {
		return $self->{'param'};
	}
}

1;

__END__

=head1 NAME

	Archivista::Application::Menu::MenuItem


=head1 SYNOPSYS


=head1 DESCRIPTION


=head1 DEPENDENCIES


=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR

	Markus Stocker, Archivista GmbH, Zurich Switzerland

=cut

# Log record
# $Log: MenuItem.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:19  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/21 13:23:54  ms
# Added POD
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.1  2005/07/08 16:56:25  ms
# Files added to project
#
