# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::Util::Exception;

use strict;

use vars qw ( $VERSION );

use Archivista::Util::Date;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

sub add
{
	my $self = shift;
  my $msg = shift;
	my $file = shift;
	my $line = shift;

  my $date = Archivista::Util::Date->new;
	my $logDateTime = $date->logDateTime;
	
  $@ = "$logDateTime $msg on $file at line $line\n";
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
# $Log: Exception.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.2  2005/03/21 18:33:20  ms
# Erzeugung neuer archivista datenbanken
#
# Revision 1.1  2005/03/14 17:29:42  ms
# File added
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
