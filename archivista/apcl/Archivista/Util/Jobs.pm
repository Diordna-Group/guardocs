# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::Util::Jobs;

use strict;

use vars qw ( $VERSION );

use Archivista::Config;
use Archivista::DL::Jobs;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

sub new 
{
  my $cls = shift;
	my $db = shift; # Object of Archivista::DL::DB;
	my $self = {};

	bless $self, $cls;

	$self->{'params'} = {};
	# 20050919 - ms
	# WAS: $self->{'jobsT'} = Archivista::DL::Jobs->new($self,$db)
	# This caused a memory leak in perl, because of the $self object passed as
	# argument to the constructor. I assume that saving this object to the hash of
	# the new object (Archivista::DL::Jobs) which is also saved to this object
	# (Archivista::Util::Jobs) caused a circular chain, probabily the reason for
	# the memory leak.
	# It is enough to pass the params-hash to the constructor. Memory use is no
	# constant.
	$self->{'jobsT'} = Archivista::DL::Jobs->new($self->{'params'},$db);
	
	return $self;
}

# -----------------------------------------------

sub next
{
  my $self = shift;

  $self->{'jobsT'}->get;
  $self->{'jobsT'}->process;
  
	return $self;
}

# -----------------------------------------------

sub param
{
  my $self = shift;
	my $param = shift;
  my $value = shift;

	if (defined $value) {
		$self->{'params'}->{$param} = $value;
	} else {
		return $self->{'params'}->{$param};
	}
}

# -----------------------------------------------

sub params
{
  # POST: pointer to Hash(param,value)
  my $self = shift;

	return $self->{'params'};
}

# -----------------------------------------------

sub done
{
  my $self = shift;

  $self->{'jobsT'}->done;
	print "dingo\n";
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
# $Log: Jobs.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.1  2005/06/17 18:22:59  ms
# File added to project
#
