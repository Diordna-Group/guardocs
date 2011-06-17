package Global;

use strict;
use Archivista;

# -----------------------------------------------

=head1 new($obj)

	IN: class name
	OUT: pointer to object (inc::Global)

	Initialize a new inc::Global object

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

	IN: object (inc::Global)
	OUT: -

	Initialize the date for this object

=cut

sub _init
{
	my $obj = shift;
	my $config = Archivista::Config->new();
	
	$obj->{'host'} = $config->get("MYSQL_HOST");
	$obj->{'db'} = $config->get("MYSQL_DB");
	$obj->{'port'} = "3306";
	$obj->{'avdb'} = $config->get("AV_GLOBAL_DB");
	$obj->{'avtable'} = $config->get("AV_GLOBAL_SESSION_TABLE");
	$obj->{'avuid'} = $config->get("MYSQL_UID");
	$obj->{'avpwd'} = $config->get("MYSQL_PWD");
	$obj->{'cgi_dir'} = "/cgi-bin/workflow";
	$obj->{'www_dir'} = "/workflow";
	# Types: string, number
	# Format: Language:Database:Type
	$obj->{'fields'} = "Title:Titel:string,Notice:Notiz:number";
	$obj->{'number_comb'} = 4;
	$obj->{'login_title'} = "Archivista Workflow Module Login";
	$obj->{'dmt_hour'} = "120000";
	$obj->{'test_hour_factor'} = "1";
}

# -----------------------------------------------

=head1 set($obj,$key,$value)

	IN: object (inc::Global)
	    key
	    value
	OUT: -

	Set a key/value pair to the object

=cut

sub set
{
	my $obj = shift;
	my $key = shift;
	my $value = shift;
	$obj->{$key} = $value;
}

# -----------------------------------------------

=head1 get($obj,$key)

	IN: object (inc::Global)
	    key
	OUT: value

	Get the value for a specific key hold by this object

=cut

sub get
{
	my $obj = shift;
	my $key = shift;
	return $obj->{$key};
}

1;

__END__
