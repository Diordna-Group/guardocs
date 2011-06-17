# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:02 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::LoginForm;

use Archivista;
use strict;

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls)

	IN: class name
	OUT: object 

	Constructor

=cut

sub new
{
  my $cls = shift;
	my $self = {};

  bless $self, $cls;

  my $archive = Archivista->archive;
  $self->{'archiveO'} = $archive;
	
  return $self;
}

# -----------------------------------------------

=head1 archives($self)

	IN: object (self)
	OUT: pointer to array

	Return a pointer to array of all available archivista archives

=cut

sub archives
{
  my $self = shift;

	return $self->archive->archives;
}

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive APCL)

	Return the APCL object

=cut

sub archive
{
  my $self = shift;

	return $self->{'archiveO'};
}

1;

__END__

=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: LoginForm.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:02  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.1  2005/04/22 17:28:49  ms
# File added to project
#
