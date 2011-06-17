# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:22 $

package Archivista::DL::ApplicationMenu;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::DL::DB;
use Archivista::Application::Menu::MenuItem;

@ISA = qw ( Archivista::DL::DB );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

# -----------------------------------------------

sub new 
{
	my $cls = shift;
	my $db = shift; # Object of Archivista::DL::DB
	my $applicationId = shift;
	my $lang = shift; # Object of Archivista::BL::Languages
	my $selectedItem = shift;
	my $self = {};

	bless $self, $cls;

  $self->{'db'} = $db;
	$self->{'application_id'} = $applicationId;
	$self->{'lang'} = $lang;
  
	return $self;
}

# -----------------------------------------------

sub items
{
  my $self = shift;
  my $selectedItem = shift; # Absolute level of the menu item
	
  my ($level,@menuItems);
	my $applicationId = $self->{'application_id'};
	my $lang = $self->{'lang'};
	my $dbh = $self->{'db'}->sudbh;

  my $query = "SELECT id,languagesId,level,link ";
	$query .= "FROM application_menu ";
	$query .= "WHERE applicationId = " . $dbh->quote($applicationId) . " ";
  $query .= "AND (level LIKE '___' ";

  foreach (split /\./, $selectedItem) {
	  $level .= "$_."; 
		$query .= "OR level LIKE '".$level."___' "; 
	}
	
	$query .= ") ";
	$query .=	"ORDER BY level ASC";
	my $sth = $dbh->prepare($query);
  $sth->execute;

  while (my @row = $sth->fetchrow_array()) {
	  my @level = split /\./, $row[2];
		my $level = $#level; # Level (0 .. n-1)
		my $levelOrder = int pop @level; # Order within the level
		my $parentLevel = int pop @level; # Parent level
		my $menuItem = Archivista::Application::Menu::MenuItem->new;
		$menuItem->id($row[0]);
		$menuItem->label($lang->string($row[1]));
		$menuItem->absoluteLevel($row[2]);
		$menuItem->relativeLevel($level);
		$menuItem->relativeLevelOrder($levelOrder);
		$menuItem->relativeParentLevel($parentLevel);
	  $menuItem->param($row[3]);

		push @menuItems, $menuItem;
	}

	$sth->finish;

  return \@menuItems;
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
# $Log: ApplicationMenu.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:22  upfister
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
