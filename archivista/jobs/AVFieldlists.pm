
package AVFieldlists;
use strict;

our @ISA = qw(AVWeb);

use lib qw(/home/cvs/archivista/jobs);
use Wrapper;
use AVWeb;


# Constants

=head1 new()

Create a av session, get cookie, if available, get and prepare values

=cut

sub new {
  my $class = shift;
	my ($title,$table,$minlevel,$sort) = @_;
	my $self = $class->SUPER::new($title,$table,$minlevel,$sort);
	return $self;
}



1;

