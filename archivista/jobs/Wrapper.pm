package Wrapper;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration  use Wrapper ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
  
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  wrap  
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub wrap {
  # gives back the calling method (whole name)
  my $name = (caller(1))[3];
  # check if we have a value (setter method)
  $_[0]->{$name} = $_[1] if defined($_[1]);
  # always give back the value (getter method)
  return $_[0]->{$name};
}



1;
__END__

=head1 NAME

Wrapper - Perl extension for store and retrieve class attributes

=head1 SYNOPSIS

  use Wrapper;
  sub name { wrap(@_); }

=head1 DESCRIPTION

Store and retrieve attributes in a class with a simple interface

Declaration:

  sub name { wrap(@_); }
  sub fields { @{wrap(@_)}; }

Setter method (must be a scalar):

  $self->name("Meier");
  $self->fields(\@fields);

Getter method (gives back scalar or what was defined in declaration)

  my $name = $self->name;
  my @fields = $self->fields;

The first example creates a setter/getter method for the currenct class.
The second example does the same, but stores a LIST and gets back a list

=head2 EXPORT

wrap by default.

=head1 SEE ALSO

Unfortunately use field in perl 5.8.x does not create setter/getter methods;
it does create simple hashes. The wrapper packages is a temp. solution 
for using something similar to use fields in perl 5.9.x 

=head1 AUTHOR

Archivista GmbH, E<lt>webmaster@archivista.chE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Archivista GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

