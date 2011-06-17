# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::Util::Collection;

use strict;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

sub new
{
  my $cls = shift;
	my $self = {};

  bless $self, $cls;
	
  return $self;
}

# -----------------------------------------------

sub element 
{
	my $self = shift;
	my $elementId = shift;
  my $element = shift;
	
	if (defined $element) {
		$self->{$elementId} = $element;
	} else {
		return $self->{$elementId};
	}
}

# -----------------------------------------------

sub remove
{
  my $self = shift;
	my $elementId = shift;

	delete $self->{$elementId};
}

# -----------------------------------------------

sub clear 
{
  my $self = shift;

  foreach my $key (keys %$self) {
		delete $self->{$key};
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
# $Log: Collection.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.4  2005/03/15 18:39:23  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.3  2005/03/14 17:29:11  ms
# Weiterentwicklung an APCL: einfuehrung der klassen BL/User sowie Util/Exception
#
# Revision 1.2  2005/03/11 18:58:47  ms
# Weiterentwicklung an Archivista Perl Class Library
#
# Revision 1.1.1.1  2005/03/11 14:01:22  ms
# Archivista Perl Class Library Projekt imported
#
# Revision 1.2  2005/03/10 17:57:55  ms
# Weiterentwicklung an der Klassenbibliothek
#
# Revision 1.1  2005/03/10 11:45:20  ms
# File moved to directory Util
#
# Revision 1.1  2005/03/08 15:19:28  ms
# Files added
#
