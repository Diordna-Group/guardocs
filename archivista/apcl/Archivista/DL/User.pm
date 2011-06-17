# Current revision $Revision: 1.2 $
# Latest change by $Author: upfister $ on $Date: 2009/08/16 23:34:13 $

package Archivista::DL::User;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::DL::DB;
use Archivista::DL::AvUser;
use Archivista::DL::MyUser;

@ISA = qw ( 
						Archivista::DL::DB 
						Archivista::DL::AvUser 
						Archivista::DL::MyUser 
					);

$VERSION = '$Revision: 1.2 $';

# -----------------------------------------------
# PUBLIC METHODS

sub new
{
	my $cls = shift;
	my $db = shift; # Object of Archivista::DL::DB
  my $self = {};

	bless $self, $cls;

  $self->db($db);

	return $self;
}

# -----------------------------------------------

sub all
{
  my $cls = shift;
	my $db = shift;
  my $self = {};

	bless $self, $cls;

	$self->db($db);
	
	return $self->avGetAllUsers;
}

# -----------------------------------------------

sub grant
{
  my $cls = shift;
	my $db = shift;
	my $pausers = shift; # 2-dim array[n][3] host,user,level
  my $self = {};

	bless $self, $cls;

	$self->db($db);
  $self->myGrant($pausers);
}

# -----------------------------------------------

sub revoke
{
  my $cls = shift;
	my $db = shift;
	my $pausers = shift;
	my $self = {};

	bless $self, $cls;

	$self->db($db);
	$self->myRevoke($pausers);
}

# -----------------------------------------------

sub select 
{
	my $self = shift;
  my $user = shift;
	my $userId = shift;
	
  $self->avSelect($user,$userId);	
}

# -----------------------------------------------

sub insert
{
  my $self = shift;
  my $user = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
  my $level = shift;

  my $lastInsertId = $self->avInsert($host,$uid,$level);
	$self->myInsert($host,$uid,$pwd,$level);
	
	return $lastInsertId;
}

# -----------------------------------------------

sub update
{
  my $self = shift;
	my $userId = shift;
  my $attribute = shift;
	
	$self->avUpdate($userId,$attribute);
	$self->myUpdate($attribute);
}

# -----------------------------------------------

sub delete
{
  my $self = shift;
  my $user = shift;

	my $userId = $user->id;
	
	$self->avDelete($userId);
	$self->myDelete($user);
}

# -----------------------------------------------

sub idByHostAndUser
{
  my $self = shift;
	my $host = shift;
	my $uid = shift;

  my ($userId, $clientIP, $clientPort);
	my $dbh = $self->db->dbh;

	# Retrieve the client IP
	my $query = "SHOW PROCESSLIST";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	while (my @row = $sth->fetchrow_array()) {
		if ($row[1] eq $uid) {
			($clientIP,$clientPort) = split /:/, $row[2];
		}
	}

	# Get the IP octects (zzz.zzz.zzz.zzz)
	my @ipo = split /\./, $clientIP;
	
	$sth->finish();

	$query = "SELECT Laufnummer FROM user WHERE ";
	if (lc($host) eq "localhost") {
		$query .= "Host = ".$dbh->quote($host);
	} else {
		$query .= "(" .
							"Host = '$clientIP' OR " .
							"Host = '$ipo[0].%' OR " .
							"Host = '$ipo[0].$ipo[1].%' OR " .
							"Host = '$ipo[0].$ipo[1].$ipo[2].%' OR " .
							"Host = '%'" .
							")";
	}
	$query .= " AND User = ".$dbh->quote($uid)." LIMIT 1";
	$sth = $dbh->prepare($query);
	$sth->execute();

  if ($sth->rows) {
	  while (my @row = $sth->fetchrow_array()) {
	    $userId = $row[0];
	  }
  } else {
    my $exception = "User $uid @ $host not found ($query)";
		$self->exception($exception,__FILE__,__LINE__);
	}
  
	$sth->finish();

	return $userId;
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
# $Log: User.pm,v $
# Revision 1.2  2009/08/16 23:34:13  upfister
# Small update in old class
#
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.3  2005/11/15 12:28:03  ms
# Updates Herr Wolff
#
# Revision 1.2  2005/11/14 12:45:35  ms
# Bugfix: Host check not only for localhost and % but also for 192.168.% or
# 192.% or the exact client IP address
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.7  2005/04/22 17:27:48  ms
# Anpassungen für Archivverwaltung
#
# Revision 1.6  2005/03/31 18:18:14  ms
# Weiterentwicklung an formular elemente (hinzufügen neuer elemente)
#
# Revision 1.5  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.4  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.3  2005/03/18 18:58:45  ms
# Enwicklung an der Benutzerfunktionalität
#
# Revision 1.2  2005/03/15 18:39:23  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.1  2005/03/14 17:30:22  ms
# File added
#
