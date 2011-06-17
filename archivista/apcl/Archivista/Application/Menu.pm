# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:19 $

package Archivista::Application::Menu;

use strict;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls)

	IN: class name
	OUT: object

	Constructor for Archivista::Application::Menu

=cut

sub new 
{
  my $cls = shift;
	my $self = {};

  bless $self, $cls;

	return $self;
}

# -----------------------------------------------

=head1 nextItem($self)

	IN: object
	OUT: object of Archivista::Application::Menu::MenuItems()

	This method returns the next menu item object in the list
	Use this method to top-down process all menu items. 
	You can use the list only once. Invoque the constructor again to have a new
	list of menu items to process.
	
=cut

sub nextItem
{
  my $self = shift;

	return shift @{$self->items};
}

# -----------------------------------------------

=head1 items($self,$pamenuItems)

	IN: object
	    pointer to array of menu items (optional)
	OUT: pointer to array of menu items (for getter method)

	Getter or Setter method depending whether the pointer to array of menu items
	($pamenuItems) is given or not.

=cut

sub items
{
  my $self = shift;
	# Pointer to array of menu items objects
	# Archivista::Application::Menu::MenuItems
  my $pamenuItems = shift;

	if (defined $pamenuItems) {
		$self->{'menu_items'} = $pamenuItems;
	} else {
		return $self->{'menu_items'};
	}
}

1;

__END__

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=head1 DEPENDENCIES


=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: Menu.pm,v $
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
