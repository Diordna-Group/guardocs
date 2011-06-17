# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:22 $

package Archivista::BL::User;

use strict;

use vars qw ( $VERSION );

use Archivista::BL::Attribute;
use Archivista::DL::User;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init
{
	my $self = shift;
  my $userId = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
	my $level = shift;
 
	my $userT = $self->{'userT'};
	$self->{'attribute'} = Archivista::BL::Attribute->new();

	# Check if getter or setter method
	if (defined $userId) {
		# Getter: insert a new user to data layer
		$userT->select($self,$userId);
	} else {
		# Setter: user from data layer
		$userId = $userT->insert($self,$host,$uid,$pwd,$level);
	}
	
	$self->{'user_id'} = $userId;
}

# -----------------------------------------------
# PUBLIC METHODS

sub new
{
  my $cls = shift;
  my $archive = shift;
	my $userId = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
	my $level = shift;
	my $self = {};

  bless $self, $cls;

  # Set the archive object
	$self->archive($archive);
	my $db = $archive->db;
	$self->{'userT'} = Archivista::DL::User->new($db);
  	
	if (defined $userId or defined $host) {
		$self->_init($userId,$host,$uid,$pwd,$level);
	}
	
  return $self;
}

# -----------------------------------------------

sub all
{
  my $cls = shift;
  my $archive = shift;

	my $db = $archive->db;

	return Archivista::DL::User->all($db);
}

# -----------------------------------------------

sub grant
{
  my $cls = shift;
  my $archive = shift;
	my $pausers = shift; # 2-dim array[n][3] host,user,level

  my $db = $archive->db;
	
	Archivista::DL::User->grant($db,$pausers);
}

# -----------------------------------------------

sub revoke
{
  my $cls = shift;
	my $archive = shift;
	my $pausers = shift;

	my $db = $archive->db;

	Archivista::DL::User->revoke($db,$pausers);
}

# -----------------------------------------------

sub id
{
	my $self = shift;

	return $self->{'user_id'};
}

# -----------------------------------------------

sub attribute
{
	my $self = shift;
	my $attributeId = shift;

  # Set the attribute id for the setter method
	$self->{'attribute'}->id($attributeId) if (defined $attributeId);

	return $self->{'attribute'};
}

# -----------------------------------------------

sub archive
{
  my $self = shift;
	my $archive = shift;

	if (defined $archive) {
		$self->{'archive'} = $archive;
	} else {
		return $self->{'archive'};
	}
}

# -----------------------------------------------

sub update
{
  my $self = shift;
	
	my $userT = $self->{'userT'};
	my $attribute = $self->{'attribute'};
	my $userId = $self->id;

	$userT->update($userId,$attribute);
}

# -----------------------------------------------

sub delete
{
  my $self = shift;

	my $userT = $self->{'userT'};
	my $userId = $self->id;

	$self->archive->clearUser($userId);
	$userT->delete($self);
}

# -----------------------------------------------

sub idByHostAndUser
{
  my $self = shift;
  my $host = shift;
	my $uid = shift;
	
  my $userT = $self->{'userT'};
	
	return $userT->idByHostAndUser($host,$uid);
}

1;

__END__

=head1 NAME
  
  Archivista::BL::User

=head1 SYNOPSYS

  # Select a user given a user id
  # The user id corresponds to the auto_increment attribute "Laufnummer" from
	# archivista.user table
  $archive->user(1);

  # Set some attribute for the preselected user
  $archive->user->attribute("Alias")->value("ms");
  $archive->user->attribute("level")->value(3);

  # Save attributes to the database
  $archive->user->update;
  $archive->clearUser(1);
	
  # Retrieve some attribute
  # Please note: we can also retrieve attributes from mysql.user table
	$archive->user(1);
  my $pwd = $archive->user->attribute("Password")->value;

  # Delete a preselected user
	$archive->user->delete;

	# Delete a user without preselection
  $archive->user($userId)->delete;
	
=head1 DESCRIPTION

  This package provides methods to deal with users

=head1 DEPENDENCIES

  Archivista::BL::Attribute
  Archivista::DL::User

=head1 EXAMPLE

  use Archivista;

  my $archive = Archivista->archive("averl");

  $archive->user(1);
  
	print $archive->user->attribute("Password")->value;

=head1 TODO


=head1 AUTHOR

  Markus Stocker, Archivista GmbH Zurich

=cut

# Log record
# $Log: User.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:22  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/14 12:45:35  ms
# Bugfix: Host check not only for localhost and % but also for 192.168.% or
# 192.% or the exact client IP address
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.5  2005/03/31 18:18:14  ms
# Weiterentwicklung an formular elemente (hinzufügen neuer elemente)
#
# Revision 1.4  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.3  2005/03/18 18:58:45  ms
# Enwicklung an der Benutzerfunktionalität
#
# Revision 1.2  2005/03/15 18:39:22  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.1  2005/03/14 17:30:40  ms
# File added
#
# Revision 1.4  2005/03/14 12:02:46  ms
# An die methode archive->document->page() kann sowohl die eindeutige page id als
# auch die relative seiten nummer angegeben werden
#
# Revision 1.3  2005/03/14 11:46:44  ms
# Erweiterungen auf archivseiten
#
# Revision 1.2  2005/03/11 18:58:47  ms
# Weiterentwicklung an Archivista Perl Class Library
#
# Revision 1.1.1.1  2005/03/11 14:01:22  ms
# Archivista Perl Class Library Projekt imported
#
# Revision 1.2  2005/03/10 17:57:55  ms
# Weiterentwicklung an der Klassenbibliothek
#
# Revision 1.1  2005/03/10 11:44:47  ms
# Files moved to BL (business logic) directory
#
# Revision 1.1  2005/03/08 15:19:28  ms
# Files added
#
