# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:19 $

package Archivista::BL::Application;

use strict;

use vars qw ( $VERSION );

use Archivista::DL::ApplicationMenu;
use Archivista::Application::Menu;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

sub new
{
  my $cls = shift;
	my $db = shift; # Object of Archivista::DL::DB
	my $self = {};

  bless $self, $cls;

  $self->{'db'} = $db;
  $self->{'menu'} = Archivista::Application::Menu->new;
  	
  return $self;
}

# -----------------------------------------------

sub id
{
  my $self = shift;
	my $applicationId = shift;

	if (defined $applicationId) {
		$self->{'application_id'} = $applicationId;
	} else {
		return $self->{'application_id'};
	}
}

# -----------------------------------------------

sub lang
{
  my $self = shift;
	my $lang = shift; # Object of Archivista::BL::Languages

  if (defined $lang) {
		$self->{'lang'} = $lang;
	} else {
		return $self->{'lang'};
	}
}

# -----------------------------------------------

sub menu
{
  my $self = shift;
  my $selectedMenuItem = shift; # Absolute level for the menu item

	my $applicationId = $self->id;
	my $lang = $self->lang;
	my $db = $self->{'db'};
	# Create the link to the data logic
	my $menuO = Archivista::DL::ApplicationMenu->new($db,$applicationId,$lang);
  # Get all menu items from the database for the selected application
	my $pamenuItems = $menuO->items($selectedMenuItem);

  $self->{'menu'}->items($pamenuItems);

	return $self->{'menu'};
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

  Markus Stocker, Archivista GmbH Zurich

=cut

# Log record
# $Log: Application.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:19  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.1  2005/07/08 16:56:25  ms
# Files added to project
#
