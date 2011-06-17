# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:22 $

package Archivista::DL::AvUser;

use strict;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

sub avGetAllUsers
{
  my $self = shift;

	my @users;
	my $inc = 0;
	
	my $dbh = $self->db->dbh;
	my $user1 = $self->db->uid;
	my $host1 = $self->db->host;
	$self->selectdb($self->db->database);
	my $query = "SELECT Host,User,Level,Laufnummer FROM user ORDER BY user,host";
	my $sth = $dbh->prepare($query);
	$sth->execute();

  if ($sth->rows) {
		while (my @row = $sth->fetchrow_array()) {
			$users[$inc][0] = $row[0];
			$users[$inc][1] = $row[1];
			$users[$inc][2] = $row[2];
			$users[$inc][3] = $row[3];
			if (($row[0] eq "localhost" && $row[1] eq "SYSOP") || ($host1 eq $row[0] && $user1 eq $row[1])) {
				# First user (SYSOP) can't be deleted
				$users[$inc][4] = 0;
				$users[$inc][5] = 0;
			} else {
				$users[$inc][4] = 1; # Delete flag
				$users[$inc][5] = 1; # Update flag
			}
			$inc++;
		}
  }

	$sth->finish();

  return \@users;
}

# -----------------------------------------------

sub documentOwners
{
  my $self = shift;
	my $db = shift;
	my $retDS = shift;
	my $dbh = $db->dbh;

	my (@documentOwners,%documentOwners);
	my $query = "SELECT User FROM user WHERE Level < 255 GROUP BY User";
	my $sth = $dbh->prepare($query);
	$sth->execute();

  while (my @row = $sth->fetchrow_array()) {
	  if ($retDS eq "ARRAY") {
			push @documentOwners, $row[0];
		} elsif ($retDS eq "HASH") {
			$documentOwners{$row[0]} = $row[0];
		}
	}
	
	$sth->finish();
	
	if ($retDS eq "ARRAY") {
		return \@documentOwners;
  } elsif ($retDS eq "HASH") {
		return \%documentOwners;
	}
}

# -----------------------------------------------

sub avSelect 
{
  my $self = shift;
  my $user = shift;
	my $userId = shift;

  my $dbh = $self->db->dbh;	
	$self->selectdb($self->db->database);
	my $query = "SELECT * FROM user WHERE Laufnummer = ".$dbh->quote($userId);

	my $sth = $dbh->prepare($query);
	$sth->execute();

  if ($sth->rows) {
		while (my $hash_ref = $sth->fetchrow_hashref()) {
			foreach my $key (keys %$hash_ref) {
				my $value = $$hash_ref{$key};
				$user->attribute($key)->value($value,0);
			}
		}
	} else {
		my $exception = "User $userId not found ($query)";
		$self->exception($exception,__FILE__,__LINE__);		
	}

	$sth->finish();
}

# ---------------------------------------------------------

sub avInsert
{
  my $self = shift;
  my $host = shift;
	my $uid = shift;
  my $level = shift;
	
  my ($query,$sth,$lastInsertId);
	$level = 0 if (! defined $level);

  my $dbh = $self->db->dbh;
	$self->selectdb($self->db->database);
	$query = "INSERT INTO user (Host,User,Level) VALUES (";
	$query .= $dbh->quote($host).",";
	$query .= $dbh->quote($uid).",";
	$query .= $level.")";
	my $do = $dbh->do($query);

  my $exception = "Failed to insert new user ($query)";
	$self->exception($exception,__FILE__,__LINE__) if (! $do);
 
	$query = "SELECT LAST_INSERT_ID()";
	$sth = $dbh->prepare($query);
	$sth->execute();

	while (my @row = $sth->fetchrow_array()) {
		$lastInsertId = $row[0];
	}

  $sth->finish();

	return $lastInsertId;
}

# -----------------------------------------------

sub avUpdate
{
  my $self = shift;
	my $userId = shift;
  my $attribute = shift; # Object of Archivista::BL::Attribute
	
	my $dbh = $self->db->dbh;
	my $database = $self->db->database;
  $attribute = $self->shiftObsoleteAttributes($database,"user",$attribute);
  
  # String of attributes to update
	my $attributesToUpdate = $self->attributesToString($attribute);
	if (length($attributesToUpdate) > 0) {
		$self->selectdb($self->db->database);
	  my $query = "UPDATE user SET $attributesToUpdate ";
	  $query .= "WHERE Laufnummer = $userId";
	  my $do = $dbh->do($query);

	  my $exception = "Failed to update user $userId ($query)";
	  $self->exception($exception,__FILE__,__LINE__) if (! $do);
  }
}

# -----------------------------------------------

sub avDelete
{
  my $self = shift;
	my $userId = shift;

  if (defined $userId) {
	  my $dbh = $self->db->dbh;
		$self->selectdb($self->db->database);
	  my $query = "DELETE FROM user WHERE Laufnummer = $userId";
	  my $do = $dbh->do($query);

	  my $exception = "Failed to delete user $userId ($query)";
	  $self->exception($exception,__FILE__,__LINE__) if (! $do);
  } else {
		my $exception = "Missing user id!";
		$self->exception($exception,__FILE__,__LINE__);
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
# $Log: AvUser.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:22  upfister
# Copy to sourceforge
#
# Revision 1.2  2007/09/27 06:15:15  up
# Correct problems when creating a user
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.4  2006/08/21 15:23:23  up
# Updating of users not any longer possible for own record
#
# Revision 1.3  2006/08/21 14:04:15  up
# The SYSOP user can't be changed any longer
#
# Revision 1.2  2005/11/14 12:45:35  ms
# Bugfix: Host check not only for localhost and % but also for 192.168.% or
# 192.% or the exact client IP address
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.13  2005/05/12 13:01:43  ms
# Last changes for archive server (v.1.0)
#
# Revision 1.12  2005/04/27 16:18:52  ms
# Anpassungen an GRANT/REVOKE
#
# Revision 1.11  2005/04/22 17:27:48  ms
# Anpassungen für Archivverwaltung
#
# Revision 1.10  2005/04/21 15:30:09  ms
# ZugriffWeb not needed
#
# Revision 1.9  2005/04/21 14:57:01  ms
# Diverse Anpassungen
#
# Revision 1.8  2005/04/21 14:32:02  ms
# Extract ZugriffWeb
#
# Revision 1.7  2005/04/21 10:49:50  ms
# Retrieve also user id at avGetAllUsers
#
# Revision 1.6  2005/03/31 18:18:14  ms
# Weiterentwicklung an formular elemente (hinzufügen neuer elemente)
#
# Revision 1.5  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.4  2005/03/23 12:01:44  ms
# Anpassungen an GRANT / REVOKE
#
# Revision 1.3  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.2  2005/03/18 15:38:42  ms
# Stabile version um User hinzuzufügen
#
# Revision 1.1  2005/03/15 18:40:04  ms
# File added to project
#
