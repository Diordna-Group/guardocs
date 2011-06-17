# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:21 $

package Archivista::BL::Languages;

use strict;

use vars qw ( $VERSION );

use Archivista::DL::Languages;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

sub new
{
  my $cls = shift;
  my $archive = shift; # Object of Archivista::BL::Archive
	my $lang = shift;
	my $self = {};

  bless $self, $cls;

  my $db = $archive->db;
  $self->code($lang);
	
	Archivista::DL::Languages->new($self,$db,$lang);

  return $self;
}

# -----------------------------------------------

sub string
{
  my $self = shift;
	my $key = shift;
  my $value = shift;

	if (defined $value) {
		$self->{$key} = $value;
	} else {
		return $self->{$key};
	}
}

# -----------------------------------------------

sub code
{
  my $self = shift;
	my $code = shift;

	if (defined $code) {
		$self->{'code'} = $code;
	} else {
		return $self->{'code'};
	}
}

1;

__END__

=head1 NAME
  
  Archivista::BL::Languages

=head1 SYNOPSYS

=head1 DESCRIPTION

=head1 DEPENDENCIES

=head1 EXAMPLE

=head1 TODO

=head1 AUTHOR

  Markus Stocker, Archivista GmbH Zurich

=cut

# Log record
# $Log: Languages.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:21  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.2  2005/05/27 15:45:17  ms
# Erweiterungen/Anpassungen LinuxTag WebClient/ArchivistaBox
#
# Revision 1.1  2005/04/20 16:16:14  ms
# Import new languages modules
#
