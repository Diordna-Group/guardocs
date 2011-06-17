package Request;

use strict;
use Carp;

# -----------------------------------------------

=head1 new($obj)

	IN: class name
	OUT: object 

	Constructor

=cut

sub new
{
	my $obj = shift;
	my $ptr = {};
	bless ($ptr,$obj);
	$ptr->_init();
	return $ptr;
}

# -----------------------------------------------

=head1 _init($obj)

	IN: object (inc::Request)
	OUT: -

	Read all GET/POST vars and save the key/value pairs to the object

=cut

sub _init
{
	my $obj = shift;
	my ($form_input);

    if ($ENV{'REQUEST_METHOD'} eq "GET") {
    	$form_input = $ENV{'QUERY_STRING'};
    } else {
    	read STDIN, $form_input, $ENV{'CONTENT_LENGTH'};
    }

    foreach my $pairs (split /&/, "$form_input") {
    	my ($key,$value) = split /=/, $pairs;
    	$value =~ tr/+/ /;
    	$value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;
    	$obj->{$key} = $value;
    }
}

# -----------------------------------------------

=head1 get($obj,$key)

	IN: object (inc::Request)
	    key
	OUT: value

	Return the value for a specific GET/POST key

=cut

sub get
{
	my $obj = shift;
	my $key = shift;
	return $obj->{$key};	
}

1;

__END__
