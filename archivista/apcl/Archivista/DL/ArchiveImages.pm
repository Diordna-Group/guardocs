# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:22 $

package Archivista::DL::ArchiveImages;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::DL::DB;

@ISA = qw ( Archivista::DL::DB );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------

sub new
{
	my $cls = shift;
	my $dbh = shift;
  my $self = {};

	bless $self, $cls;

  $self->dbh($dbh);

	return $self;
}

# -----------------------------------------------

sub select 
{
}

# ---------------------------------------------------------

sub insert
{
}

# -----------------------------------------------

sub update
{
}

# -----------------------------------------------

sub delete
{
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
# $Log: ArchiveImages.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:22  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.2  2005/03/15 18:39:22  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.1  2005/03/11 18:59:21  ms
# Files added
#
