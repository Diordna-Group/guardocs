# Current revision $Revision: 1.1.1.1 $
# Latest change on $Date: 2008/11/09 09:19:25 $ by $Author: upfister $

package Gewa::lib::Session;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);

use Digest::MD5 qw(md5_hex);

use Gewa::lib::DB;
use Gewa::lib::Config;

BEGIN {
  use Exporter();
  use DynaLoader();

  @ISA    = qw(Exporter DynaLoader);
  @EXPORT = qw(new setSessionId deleteSession
               checkIfExists checkAuth set get 
	       open close addUserSessionData);
}

# -----------------------------------------------
# PRIVATE METHODS

=head1 _init($self,$request)

	IN: object
	    object of GET/POST vars
	OUT: -

	Init the required state for the object

=cut

sub _init 
{
  my $self = shift;
  my $request = shift;
 
  # Initialize the database handler
  # to the session database
  my $config = new Gewa::lib::Config();
  my $host = $config->getMyHost();
  my $db = $config->getMySessionDbName();
  my $uid = $config->getMyUser();
  my $pwd = $config->getMyPassword();
  
  $self->{'dbs'} = new Gewa::lib::DB($host,$db,$uid,$pwd);
}

# -----------------------------------------------

=head1 _openSession($self,$request,$sid)

	IN: object
	    object of GET / POST vars
			session id
	OUT: -
	
	Open a new session for a logged user
	
=cut

sub _openSession
{
  my $self = shift;
  my $request = shift;
  my $sid = shift;
  
  my $config = new Gewa::lib::Config();
	my $sessionTable = $config->getMySessionTableName();
	my $dbs = $self->{'dbs'};
  my $host = $request->value("host");
  my $db = $request->value("db");
  my $uid = $request->value("uid");
  # Bug 1.2.2005 -> Passwort wurde nicht gesetzt
  my $pwd = $request->value("pwd");
  
  my $query = "INSERT INTO $sessionTable SET ";
  $query .= "sid=".$dbs->quote($sid).",";
  $query .= "host=".$dbs->quote($host).",";
  $query .= "db=".$dbs->quote($db).",";
  $query .= "uid=".$dbs->quote($uid).",";
  $query .= "pwd=".$dbs->quote($pwd);
  $dbs->do($query);
}

# -----------------------------------------------

=head1 _readSession($self,$sid)

	IN: object
	    session id
	OUT: -

	Get some session information related to the session id

=cut

sub _readSession
{
  my $self = shift;
  my $sid = shift;
  my $dbs = $self->{'dbs'};
  
	my $config = new Gewa::lib::Config();
	my $sessionTable = $config->getMySessionTableName();
	
  my $query = "SELECT host,db,uid,pwd FROM $sessionTable WHERE sid=".$dbs->quote($sid);
  my $sth = $dbs->query($query);
  $sth->execute();

  while (my @row = $sth->fetchrow_array()) {
    $self->set("session_host",$row[0]);
    $self->set("session_db",$row[1]);
    $self->set("session_uid",$row[2]);
    # Bug 1.2.2005 -> Passwort wurde nicht aus Session gelesen
    $self->set("session_pwd",$row[3]);
  }
}

# -----------------------------------------------

=head1 _setSessionId($self,$sid)

	IN: object
	    session id
	OUT: -

	Set the session id a value to the session object

=cut

sub _setSessionId
{
  my $self = shift;
  my $sid = shift;
  
  $self->{'session_id'} = $sid;
}

# -----------------------------------------------

=head1 _parseBarcodeFormData($self,$psdata)

	IN: object
	    pointer to string of data
	OUT: -

	Get the form data and parse it to an internal format

=cut

sub _parseBarcodeFormData
{
  my $self = shift;
  my $psdata = shift;

  my (@normalFieldsOrdered,%normalFields,%hiddenFields);
 
  # Check each line
  foreach (split /\r\n/, $$psdata) {
    # Get singel fields of a line (..;..;..)
    my @fields = split /;/, $_;
    # Get the key-field
    if ($fields[2] eq "key") {
      $self->set("session_key_field_name",$fields[0]);
      $self->set("session_key_field_label",$fields[1]);
    } elsif ($fields[2] eq "combo") {
      $self->set("session_combo_fields",$fields[3]);
    } elsif ($fields[2] eq "normal") {
      push @normalFieldsOrdered, $fields[0];
      $normalFields{$fields[0]} = $fields[1];
    } elsif ($fields[2] eq "hidden") {
      $hiddenFields{$fields[0]} = $fields[1];
    } elsif ($fields[2] eq "match") {
      $self->set("session_match_field_name",$fields[0]);
      $self->set("session_match_field_label",$fields[1]);
    }
  }
 
  my $nrOfInputFields = $#normalFieldsOrdered + 2; # add the key field
  $self->set("session_nr_of_input_fields",$nrOfInputFields);
  $self->set("session_pa_normal_fields_ordered",\@normalFieldsOrdered);
  $self->set("session_ph_normal_fields",\%normalFields);
  $self->set("session_ph_hidden_fields",\%hiddenFields);
}

# -----------------------------------------------

=head1 _parseBarcodePrintText($self,$psdata)

	IN: object
	    pointer to string of data
	OUT: -

	Get the barcode text and parse it to an internal format

=cut

sub _parseBarcodePrintText
{
  my $self = shift;
  my $psdata = shift;

  my (@barcodePrintText,%barcodePrintText);
  
  foreach (split /\r\n/, $$psdata) {
    my ($field,$length) = split /,/, $_;
    push @barcodePrintText, $field;
    $barcodePrintText{$field} = $length;
  }

  $self->set("session_pa_barcode_print_text",\@barcodePrintText);
  $self->set("session_ph_barcode_print_text",\%barcodePrintText);
}

# -----------------------------------------------
# PUBLIC METHODS

=head1 $session = new Session($request)

  Init a new session object
  The method accepts an optional session id
  If a session id is given, no new session id will
  be created
  
  PRE: PackageName, Object(lib::Request)
  POST: Object(lib::Session)

=cut

sub new
{
  my $cls = shift;
  my $request = shift;
  my $self = {};
    
  bless $self, $cls;
   
  $self->_init($request);
   
  return $self;
}

# -----------------------------------------------

sub open
{
  my $self = shift;
  my $request = shift;
  my $dbc = shift;
  
  my $sid = $request->value("sid");
  
  if (length($sid) == 0) {
    # Create a new session id
    $sid = md5_hex localtime() . rand();
    $self->_openSession($request,$sid);
    $self->set("session_host",$request->value("host"));
    $self->set("session_db",$request->value("db"));
    $self->set("session_uid",$request->value("uid"));
    # set pw to session: 1.2.2005 up
    $self->set("session_pwd",$request->value("pwd"));
  } else {
    # User has a valid session
    # Read user data
    $self->_readSession($sid);
  }

  $self->_setSessionId($sid);
}

# -----------------------------------------------

=head1 $session->addUserSessionData($dbc)

  Read some user specific session data
  such as preconfigured barcode printer
  
  PRE: Object(lib::Session), Object(lib::DB)
  POST: -
  
=cut

sub addUserSessionData
{
  my $self = shift;
  my $dbc = shift;
  my $host = $self->get("session_host");
  my $uid = $self->get("session_uid");

  my ($query,$sth);
  
  $query = "SELECT Zusatz FROM user WHERE User='$uid'";
  $sth = $dbc->query($query);
  $sth->execute();

  while (my @row = $sth->fetchrow_array()) {
    $self->set("session_bc_printer",$row[0]);
  }
  
  $sth->finish();

  $query = "SELECT Inhalt FROM parameter WHERE Name='BarcodeForm'";
  $sth = $dbc->query($query);
  $sth->execute();

  while (my @row = $sth->fetchrow_array()) {
    $self->_parseBarcodeFormData(\$row[0]);
  }
 
  $sth->finish();
  
  $query = "SELECT Inhalt FROM parameter WHERE Name='BarcodePrintText'";
  $sth = $dbc->query($query);
  $sth->execute();
  
  while (my @row = $sth->fetchrow_array()) {
    $self->_parseBarcodePrintText(\$row[0]);
  }
  
  $sth->finish();
}

# -----------------------------------------------

=head1 $sid = $session->getSessionId()

  Return the session id of a session object

  PRE: Object(lib::Session)
  POST: String(sessionId)

=cut

sub getSessionId
{
  my $self = shift;

  return $self->{'session_id'};
}

# -----------------------------------------------

=head1 $sessionExits = $session->checkIfExists($request)

  Check on mysql session table if a session is alive

  PRE: Object(lib::Session), Object(lib::Request)
  POST: Boolean(sessionExists)

=cut

sub checkIfExists
{
  my $self = shift;
  my $request = shift;
  my $dbs = $self->{'dbs'};
  my $sid = $request->value("sid");
  
  my $checkIfExists = 0;
  my $config = new Gewa::lib::Config();
	my $sessionTable = $config->getMySessionTableName();

  my $query = "SELECT sid FROM $sessionTable WHERE sid=".$dbs->quote($sid);
  my $sth = $dbs->query($query);
  $sth->execute();
  
  $checkIfExists = 1 if ($sth->rows());

  $sth->finish();

  return $checkIfExists;
}

# -----------------------------------------------

=head1 $db = $session->checkAuth($request)

  Check the authentification for a logged user

  PRE: Object(lib::Session),Object(lib::Request)
  POST: Object(lib::DB)

=cut

sub checkAuth
{
  my $self = shift;
  my $request = shift;
  
  my $host = $request->value("host");
  my $db = $request->value("db");
  my $uid = $request->value("uid");
  my $pwd = $request->value("pwd");
  
  return new Gewa::lib::DB($host,$db,$uid,$pwd);
}

# -----------------------------------------------

=head1 $session->set($key,$value)
 
  Set a new session variable

  PRE: Object(lib::Session), String(key), String(value)
  POST: -

=cut

sub set
{
  my $self = shift;
  my $key = shift;
  my $value = shift;

  $self->{$key} = $value;
}

# -----------------------------------------------

=head1 $value = $session->get($key)

  Get a value of a session variable

  PRE: Object(lib::Session), String(key)
  POST: String(value)
  
=cut

sub get
{
  my $self = shift;
  my $key = shift;

  return $self->{$key};
}

# -----------------------------------------------

=head1 $session->delete()

  Delete a session

  PRE: Object(lib::Session);
  POST: -

=cut

sub delete
{
  my $self = shift;
  my $sid = $self->getSessionId();
  my $dbs = $self->{'dbs'};
  
  my $query = "DELETE FROM avclient WHERE sid=".$dbs->quote($sid);
  $dbs->do();
}

# -----------------------------------------------

=head1 $session->close()

  Close a session

  PRE: Object(lib::Session)
  POST: -

=cut

sub close
{
  my $self = shift;

  $self->{'dbs'}->disconnect();
}

1;

__END__

# Log record
# $Log: Session.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:25  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:23  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.3  2005/11/24 12:52:49  ms
# Added POD
#
# Revision 1.2  2005/11/22 17:06:49  ms
# Barcodeprint and Workflow adaption to CI
#
# Revision 1.1  2005/11/21 10:40:43  ms
# Added to project
#
# Revision 1.2  2005/02/17 11:49:37  ms
# Import der Aenderungen auf dem gewa archivserver
#
# Revision 1.1  2005/01/21 15:58:07  ms
# Added files, new namespace Gewa
#
# Revision 1.4  2005/01/14 18:36:25  ms
# Erste endversion
#
# Revision 1.3  2005/01/14 17:13:30  ms
# Version mit funktionierendem barcode print
#
# Revision 1.2  2005/01/10 15:34:36  ms
# Entwicklung (mittlerer Teil mit such formular)
#
# Revision 1.1  2005/01/07 18:10:03  ms
# Entwicklung
#
