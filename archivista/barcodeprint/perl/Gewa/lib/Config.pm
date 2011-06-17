# Current revision $Revision: 1.1.1.1 $
# Latest change on $Date: 2008/11/09 09:19:25 $ by $Author: upfister $

package Gewa::lib::Config;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);

BEGIN {
  use Exporter();
  use DynaLoader();

  @ISA    = qw(Exporter DynaLoader);
  @EXPORT = qw(new getMyHost
               getMyUser getMyPassword 
	       getMyMasterDbName getWWWDir
	       getCGIDir getMySessionDbName
	       getPrintCommand getTempDir);
}

# -----------------------------------------------
# PRIVATE METHODS

=head1 _init($self)

	IN: object
	OUT: -

	Fill the config object with config params

=cut

sub _init 
{
  my $self = shift;

  $self->{'my_host'} = "localhost";
  $self->{'my_master_database'} = "archivista";
  $self->{'my_session_database'} = "archivista";
  $self->{'my_session_table'} = "sessionweb";
	$self->{'my_user'} = "root";
  $self->{'my_password'} = "archivista";
  $self->{'www_dir'} = "/barcodeprint";
  $self->{'cgi_dir'} = "/cgi-bin/barcodeprint";
  $self->{'print_command'} = "/usr/bin/lp -d";
  $self->{'temp_dir'} = "/tmp";
}

# -----------------------------------------------
# PUBLIC METHODS

=head1 $config = new Config()

  Init a new config object

  PRE: PackageName
  POST: Object(lib::Config) 

=cut

sub new 
{
  my $cls = shift;
  my $self = {};
    
  bless $self, $cls;
   
  $self->_init();
   
  return $self;
}

# -----------------------------------------------

=head1 $config->getMySessionTableName()

	Return the session table name

	PRE: Object(lib::Config)
	POST: String(sessionTableName)

=cut

sub getMySessionTableName
{
	my $self = shift;

	return $self->{'my_session_table'};
}

# -----------------------------------------------

=head1 $config->getMyHost()

  Return host name of mysql server

  PRE: Object(lib::Config)
  POST: String(hostname)

=cut

sub getMyHost
{
  my $self = shift;

  return $self->{'my_host'};
}

# -----------------------------------------------

=head1 $config->getMyMasterDbName()

  Return the mysql database name
  for the master database
  
  PRE: Object(lib::Config)
  POST: String(databaseName)
  
=cut

sub getMyMasterDbName
{
  my $self = shift;

  return $self->{'my_master_database'};
}

# -----------------------------------------------

=head1 $config->getMySessionDbName()

  Return the mysql database name
  for the session database

  PRE: Object(lib::Config)
  POST: String(databaseName)

=cut

sub getMySessionDbName
{
  my $self = shift;

  return $self->{'my_session_database'};
}

# -----------------------------------------------

=head1 $config->getMyUser()

  Return the user for mysql account

  PRE: Object(lib::Config)
  POST: String(username)

=cut

sub getMyUser
{
  my $self = shift;

  return $self->{'my_user'};
}

# -----------------------------------------------

=head1 $config->getMyPassword()

  Return the password for mysql account

  PRE: Object(lib::Config)
  POST: String(password)

=cut

sub getMyPassword
{
  my $self = shift;

  return $self->{'my_password'};
}

# -----------------------------------------------

=head1 $config->getWWWDir()
 
  Return the relative web root path
  to the application

  PRE: Object(lib::Config)
  POST: String(wwwPath)

=cut

sub getWWWDir
{
  my $self = shift;

  return $self->{'www_dir'};
}

# -----------------------------------------------

=head1 $config->getCGIDir()

  Return the relative cgi root path
  to the application

  PRE: Object(lib::Config)
  POST: String(cgiPath)

=cut

sub getCGIDir
{
  my $self = shift;

  return $self->{'cgi_dir'};
}

# -----------------------------------------------

=head1 $config->getPrintCommand();

  Return the print command
  (for example /usr/bin/lp -d)

  PRE: Object(lib::Config)
  POST: String(printCommand)

=cut

sub getPrintCommand
{
  my $self = shift;

  return $self->{'print_command'};
}

# -----------------------------------------------

=head1 $config->getTempDir();

  Return the system temp directory

  PRE: Object(lib::Config)
  POST: String(tempDir)

=cut

sub getTempDir
{
  my $self = shift;

  return $self->{'temp_dir'};
}

1;

__END__

# Log record
# $Log: Config.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:25  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:23  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.3  2005/11/24 12:52:48  ms
# Added POD
#
# Revision 1.2  2005/11/22 17:06:49  ms
# Barcodeprint and Workflow adaption to CI
#
# Revision 1.1  2005/11/21 10:40:43  ms
# Added to project
#
# Revision 1.3  2005/02/17 12:16:34  ms
# Anpassungen: Styles, Mitglieder zwingend
#
# Revision 1.2  2005/02/17 11:49:37  ms
# Import der Aenderungen auf dem gewa archivserver
#
# Revision 1.1  2005/01/21 15:58:07  ms
# Added files, new namespace Gewa
#
# Revision 1.2  2005/01/14 17:13:30  ms
# Version mit funktionierendem barcode print
#
# Revision 1.1  2005/01/07 18:10:03  ms
# Entwicklung
#
