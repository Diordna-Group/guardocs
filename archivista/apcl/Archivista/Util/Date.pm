# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::Util::Date;

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

sub logDateTime
{
  my $self = shift;

	my ($sec,$min,$hour,$day,$mon,$year) = localtime();
	$sec = sprintf "%02d", $sec;
	$min = sprintf "%02d", $min;
	$hour = sprintf "%02d", $hour;
	$day = sprintf "%02d", $day;
	$mon = sprintf "%02d", $mon + 1;
	$year += 1900;

	return "$year-$mon-$day $hour:$min:$sec";
}

# -----------------------------------------------

sub actualDate 
{
  my $self = shift;

	my (undef,undef,undef,$day,$mon,$year) = localtime();
	$day = sprintf "%02d", $day;
	$mon = sprintf "%02d", $mon + 1;
	$year += 1900;

	return "$year-$mon-$day 00:00:00";
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
# $Log: Date.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.2  2005/07/13 13:33:51  ms
# Added method actualDate
#
# Revision 1.1  2005/03/21 18:36:57  ms
# Files added to project
#
