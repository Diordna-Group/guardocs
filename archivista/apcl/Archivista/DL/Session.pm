# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::DL::Session;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::Config;
use Archivista::DL::DB;

@ISA = qw ( Archivista::DL::DB );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init
{
  my $self = shift;

	my $config = Archivista::Config->new;
	my $database = $config->get("AV_GLOBAL_DB");
	my $host = $config->get("MYSQL_HOST");
	my $uid = $config->get("MYSQL_UID");
	my $pwd = $config->get("MYSQL_PWD");
	
	my $db = Archivista::DL::DB->new($database,$host,$uid,$pwd);
	$self->{'session_db'} = $database;
	$self->db($db);
}

# -----------------------------------------------

sub _read
{
  my $self = shift;
	
	my $dbh = $self->db->dbh;
	my $sid = $self->session->id;
	my ($query,$sth);

	$query = "SELECT host,db,user,password,language FROM session WHERE ";
	$query .= "sid = ".$dbh->quote($sid);
  $sth = $dbh->prepare($query);
  $sth->execute;
	
	while (my @row = $sth->fetchrow_array()) {
		$self->session->host($row[0]);
		$self->session->db($row[1]);
		$self->session->user($row[2]);
		$self->session->password($row[3]);
		$self->session->language($row[4]);
	}
	
	$sth->finish;
}

# -----------------------------------------------

sub _open
{
  my $self = shift;
	
	my $dbh = $self->db->dbh;
	my $sid = $self->session->id;
	my ($exception,$query,$do,$sth);

  my $lang = $self->session->language;
	
	$query = "INSERT INTO session SET ";
	$query .= "sid = ".$dbh->quote($sid).",";
	$query .= "host = ".$dbh->quote($self->session->host).",";
	$query .= "db = ".$dbh->quote($self->session->db).",";
	$query .= "user = ".$dbh->quote($self->session->user).",";
	$query .= "password = ".$dbh->quote($self->session->password);
	if (defined $lang) {
		$query .= ",language = ".$dbh->quote($lang);
	}
	$do = $dbh->do($query);
	
	$exception = "Failed to open session ($query)";
	$self->exception($exception,__FILE__,__LINE__) if ($do != 1);
}

# -----------------------------------------------

sub _deleteSessionData
{
  my $self = shift;

	my $dbh = $self->db->dbh;
  my $sid = $self->session->id;	

  my $query = "DELETE FROM session_data WHERE ";
	$query .= "sid = ".$dbh->quote($sid);
	my $do = $dbh->do($query);
}

# -----------------------------------------------
# PUBLIC METHODS

sub read
{
	my $self = shift;
  my $session = shift; # Object of Archivista::Util::Session

	$self->{'session'} = $session;
  $self->_read;
}

# -----------------------------------------------

sub open
{
  my $cls = shift;
	my $session = shift; # Object of Archivista::Util::Session
	my $self = {};

	bless $self, $cls;

  $self->{'session'} = $session;
  $self->_init;
	$self->_open;

	return $self;
}

# -----------------------------------------------

sub check
{
  my $cls = shift;
	my $sid = shift;
  my $self = {};

	bless $self, $cls;
	
	$self->_init;

  my $dbh = $self->db->dbh;
	my $query = "SELECT sid FROM session WHERE ";
	$query .= "sid = ".$dbh->quote($sid)." LIMIT 1";
	my $sth = $dbh->prepare($query);
	$sth->execute;

  if ($sth->rows) {
		$self->{'session_id'} = $sid;
	} else {
		undef $self;
	}
	
	$sth->finish;

	return $self;
}

# -----------------------------------------------

sub close
{
  my $self = shift;

  $self->db->dbh->disconnect;
}

# -----------------------------------------------

sub delete
{
  my $self = shift;

	my $dbh = $self->db->dbh;
	my $sid = $self->session->id;
	
	my $query = "DELETE FROM session WHERE ";
	$query .= "sid = ".$dbh->quote($sid);
	my $do = $dbh->do($query);

  $self->_deleteSessionData;
	
	my $exception = "Failed to delete session ($query)";
	$self->exception($exception,__FILE__,__LINE__) if ($do <= 1);
}

# -----------------------------------------------

sub save
{
  my $self = shift;
	my $session = shift;
  
	my $sid = $self->session->id;
  my $dbh = $self->db->dbh;
  
	# First we delete the session data
	$self->_deleteSessionData;

	# Now we save the data from the hash
	foreach my $param (keys %{$session->params}) {
		my $query = "INSERT INTO session_data SET ";
	  $query .= "sid = ".$dbh->quote($sid).",";
		$query .= "param = ".$dbh->quote($param).",";
		$query .= "value = ".$dbh->quote($session->param($param));
		my $do = $dbh->do($query);
	
	  my $exception = "Failed to add session param ($query)";
		$self->exception($exception,__FILE__,__LINE__) if ($do != 1);
	}
}

# -----------------------------------------------

sub session
{
  my $self = shift;
 
  return $self->{'session'};
}

# -----------------------------------------------

sub sessiondb
{
  my $self = shift;

	return $self->{'session_db'};
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
# Revision 1.5  2005/04/20 17:41:54  ms
# Adding language functionality
#
# Revision 1.4  2005/04/20 17:09:11  ms
# Add language functionality to session management
#
# Revision 1.3  2005/04/20 16:16:14  ms
# Import new languages modules
#
# Revision 1.2  2005/04/07 17:42:49  ms
# Entwicklung von alter table fuer das hinzufuegen und loeschen von feldern in der
# datenbank
#
# Revision 1.1  2005/04/06 18:19:49  ms
# Files added to project
#
