# Current revision $Revision: 1.5 $
# Latest change by $Author: upfister $ on $Date: 2010/03/06 13:31:58 $

package ASConfig;

use strict;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.5 $';

# -----------------------------------------------

=head1 new($cls)

	IN: class name
	OUT: object

	Construtor for ASConfig

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

=head1 get($self,$key)

	IN: object
	    config key
	OUT: string

	Return the config value for a specific key
	The values must be defined in ASConfig::_init()

=cut

sub get
{
  my $self = shift;
  my $key = shift;

  return $self->{$key};
}

# -----------------------------------------------
# LOCAL METHODS

sub _init
{
  my $self = shift;

  # REQUIRED
	$self->{'WWW_DIR'} = "/webadmin";
  $self->{'PERL_DIR'} = "/cgi-bin/webadmin";
	$self->{'STYLES'} = "/css/styles.css";
  $self->{'LANGUAGES'} = "";
	$self->{'LOGIN_DISPLAY_HOST'} = 1;
	$self->{'DEFAULT_LOGIN_HOST'} = "localhost";
	$self->{'DEFAULT_LOGIN_DB'} = "archivista";
	$self->{'DEFAULT_LOGIN_USER'} = "Admin";
  $self->{'BASE_PATH'} = "/home/data";
	$self->{'VERSION'} = "2010/IV";
	$self->{'TITLE'} = "Archivista WebAdmin";
	# To identify the application for example for the application_menu
  $self->{'APPLICATION_ID'} = "WebAdmin";
}

1;

__END__

=head1 NAME 
 
=head1 SYNOPSYS

=head1 DESCRIPTION

=head1 EXAMPLE

=head1 TODO

=head1 AUTHOR

=cut

# Log record
# $Log: ASConfig.pm,v $
# Revision 1.5  2010/03/06 13:31:58  upfister
# New Version 2010/III
#
# Revision 1.4  2009/06/24 20:39:47  upfister
# Version goes to 2009/VII
#
# Revision 1.3  2009/03/05 23:57:26  upfister
# Version
#
# Revision 1.2  2008/12/30 02:50:39  upfister
# Version updated
#
# Revision 1.1.1.1  2008/11/09 09:21:00  upfister
# Copy to sourceforge
#
# Revision 1.6  2008/10/25 07:52:40  up
# Update version
#
# Revision 1.5  2008/05/28 16:27:34  up
# Updated version
#
# Revision 1.4  2007/07/15 18:15:29  up
# New version flag
#
# Revision 1.3  2007/04/07 01:13:37  up
# Correct version number
#
# Revision 1.2  2007/03/01 08:57:12  up
# New version number
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.4  2005/11/21 13:23:54  ms
# Added POD
#
# Revision 1.3  2005/11/07 12:24:16  ms
# Display localhost login input field based upon the configuration file
#
# Revision 1.2  2005/10/18 21:13:08  up
# Settings for ArchivistaBox
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.7  2005/07/08 17:26:10  ms
# Anpassungen menu
#
# Revision 1.6  2005/07/08 16:50:53  ms
# *** empty log message ***
#
# Revision 1.5  2005/06/21 11:31:02  ms
# Admin anstelle von Administrator
#
# Revision 1.4  2005/06/01 13:19:58  ms
# Implementierung der neuen passwort abfrage
#
# Revision 1.3  2005/05/26 15:53:48  ms
# Anpassungen für LinuxTag
#
# Revision 1.2  2005/04/20 18:43:17  ms
# Weiterentwicklung: Integration der Sprachenstrings
#
# Revision 1.1  2005/04/15 18:19:52  ms
# File added to project
#
