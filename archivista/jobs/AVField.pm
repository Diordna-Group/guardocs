
package AVField;
use strict;
use Wrapper;


sub name {wrap(@_)}
sub type {wrap(@_)}
sub size {wrap(@_)}
sub quote {wrap(@_)}
sub pos {wrap(@_)}

sub new {
  my $class = shift;
  my $self = {};
	bless $self,$class;
  my ($name,$type,$size,$quote)  = @_;
  $self->name($name);
	$self->type($type);
	$self->size($size);
	$self->quote($quote);
	return $self;
}

1;
