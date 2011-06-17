# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::Util::Session;

use strict;

use vars qw ( $VERSION );
use Digest::MD5 qw(md5_hex);

use Archivista::Config;
use Archivista::DL::Session;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

sub open
{
  my $cls = shift;
	my $database = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
	my $lang = shift;
	my $self = {};

  bless $self, $cls;

  if (! defined $host) {
		my $config = Archivista::Config->new;
		$host = $config->get("MYSQL_HOST");
		$uid = $config->get("MYSQL_UID");
		$pwd = $config->get("MYSQL_PWD");
	}
	
  $self->host($host);
	$self->db($database);
	$self->user($uid);
	$self->password($pwd);
	$self->language($lang);
	$self->{'params'} = {};
	$self->{'session_id'} = md5_hex rand().time().$host.$database.$uid;
  $self->{'sessionT'} = Archivista::DL::Session->open($self);
  
	return $self;
}

# -----------------------------------------------

sub check
{
  my $cls = shift;
	my $sid = shift;
	my $self = {};

	bless $self, $cls;

  $self->{'session_id'} = $sid;
	$self->{'params'} = {};
	$self->{'sessionT'} = Archivista::DL::Session->check($sid);
	
	if (! defined $self->{'sessionT'}) {
		undef $self;
	}

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

sub read
{
  my $self = shift;
	
	# Read an existing session
	$self->{'sessionT'}->read($self);
}

# -----------------------------------------------

sub close
{
  my $self = shift;

	$self->{'sessionT'}->close;
}

# -----------------------------------------------

sub save
{
  my $self = shift;

	$self->{'sessionT'}->save($self);
}

# -----------------------------------------------

sub delete
{
  my $self = shift;
	
	$self->{'sessionT'}->delete;

  undef $self->{'sessionT'};
}

# -----------------------------------------------

sub id
{
  my $self = shift;

	return $self->{'session_id'};
}

# -----------------------------------------------

sub host
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'host'} = $value;
	} else {
		return $self->{'host'};
	}
}

# -----------------------------------------------

sub db
{
  my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'db'} = $value;
	} else {
		return $self->{'db'};
	}
}

# -----------------------------------------------

sub user
{
	my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'user'} = $value;
	} else {
		return $self->{'user'};	
	}
}

# -----------------------------------------------

sub password
{
	my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'password'} = $value;
	} else {
		return $self->{'password'};
	}
}

# -----------------------------------------------

sub language
{
	my $self = shift;
	my $value = shift;

	if (defined $value) {
		$self->{'language'} = $value;
	} else {
		return $self->{'language'};
	}
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
# $Log: Session.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.5  2005/06/17 18:22:19  ms
# Implementation scan from webclient
#
# Revision 1.4  2005/04/20 17:09:11  ms
# Add language functionality to session management
#
# Revision 1.3  2005/04/07 17:42:49  ms
# Entwicklung von alter table fuer das hinzufuegen und loeschen von feldern in der
# datenbank
#
# Revision 1.2  2005/04/06 18:19:16  ms
# Entwicklung an der session datenbank
#
# Revision 1.1  2005/04/06 11:36:28  ms
# File added to project
#
