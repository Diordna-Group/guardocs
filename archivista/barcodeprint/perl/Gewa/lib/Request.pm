# Current revision $Revision: 1.1.1.1 $
# Latest change on $Date: 2008/11/09 09:19:25 $ by $Author: upfister $

package Gewa::lib::Request;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);

BEGIN {
  use Exporter();
  use DynaLoader();

  @ISA    = qw(Exporter DynaLoader);
  @EXPORT = qw(new value);
}

# -----------------------------------------------
# PRIVATE METHODS

=head1 _init($self)

	IN: object
	OUT: -

	Parse GET / POST vars and save the values to the object

=cut

sub _init 
{
  my $self = shift;
  my ($param,%param);

  if (length($ENV{'QUERY_STRING'}) > 0) {
    $param = $ENV{'QUERY_STRING'};
  } else {
    read STDIN, $param, $ENV{'CONTENT_LENGTH'};
  }
    
  foreach (split /&/, $param) {
    my ($key,$value) = split /=/, $_;
    $param{$key.'_raw'} = $value;
    $value =~ tr/+/ /;
    $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack "C", hex ($1)/eg;
    $param{$key} = $value;
  }
    
  %{ $self } = %param;
}
# -----------------------------------------------
# PUBLIC METHODS

=head1 $request = new Request()

  Init a new request object

  PRE: PackageName
  POST: Object(lib::Request)

=cut

sub new 
{
  my $cls = shift;
  my $self = {};
    
  bless $self, $cls;
   
  $self->_init();
   
  return $self;
}

# -----------------------------------------------

=head1 $request->value($key)

  Return the value for a GET/POST key

  PRE: Object(lib::Request), String(key)
  POST: String(value)

=cut

sub value 
{
  my $self = shift;
  my $key = shift;
    
  return $self->{$key};
}

1;

__END__

# Log record
# $Log: Request.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:25  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:23  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/24 12:52:49  ms
# Added POD
#
# Revision 1.1  2005/11/21 10:40:43  ms
# Added to project
#
# Revision 1.1  2005/01/21 15:58:07  ms
# Added files, new namespace Gewa
#
# Revision 1.2  2005/01/07 18:10:03  ms
# Entwicklung
#
# Revision 1.1  2005/01/03 15:55:02  ms
# File added
#
