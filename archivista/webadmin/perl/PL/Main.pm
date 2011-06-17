# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:02 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::Main;

use strict;

use CGI;
use Archivista;

use ASConfig;
use PL::HTML;

# -----------------------------------------------
# PRIVATE METHODS

=head1 _init($self)

	IN: object (PL::Main)
	OUT: -

	Perform a login check and invoque the methods to generate the main logged page
	or the login form

=cut

sub _init
{
  my $self = shift;

  $self->{'configO'} = ASConfig->new;
  $self->{'cgiO'} = CGI->new;
 
  my $options = $self->cgi->param('options');
	my $archive = $self->cgi->param('archive');
	my $host = $self->cgi->param('host');
	my $db = $self->cgi->param('db');
	my $uid = $self->cgi->param('uid');
	my $pwd = $self->cgi->param('pwd');
  my $logout = $self->cgi->param('logout');
	my $lang = $self->cgi->param('lang');
	my $sessionid = $self->cgi->cookie('sessionid');
  my $logged = 0;
	my $loginParamCheck = 0;
	my ($cookie);
	
  if (length($host) > 0 && length($db) > 0 && length($uid) > 0) {
		$loginParamCheck = 1;
	}
	
	if (defined $options && $options ne "login" && $loginParamCheck == 1) {
		if ($options eq "create") {
	  	if (length($archive) > 0) {
				Archivista->create($db,$archive,$host,$uid,$pwd);
  		} else {
				Archivista->create($db,undef,$host,$uid,$pwd);
			}
		} elsif ($options eq "drop") {
			Archivista->drop($db,$host,$uid,$pwd);
		}	
	} elsif ($logout == 1 && length($self->cgi->cookie("sessionid")) > 0) {
		# Request for logout
		$self->{'archiveO'} = Archivista->archive($sessionid);
		$self->{'archiveO'}->session->delete;
		$cookie = $self->cgi->cookie(-name => 'sessionid',
																 -value => '');
	} elsif ($loginParamCheck == 1) {
		# Require to login
		$self->{'archiveO'} = Archivista->archive($db,$host,$uid,$pwd,$lang);
		if (defined $self->{'archiveO'}->db && $self->{'archiveO'}->hostIsSlave() == 0) {
			# Check if user has 255 level
			my $user = $self->{'archiveO'}->user($host,$uid);
			my $level = $user->attribute("Level")->value;

 			if ($level == 255) {
				$sessionid = $self->archive->session->id;
				$cookie = $self->cgi->cookie(-name => 'sessionid',
					  												 -value => $sessionid);
				$logged = 1;
			}
		} else {
			$self->{'error'} = "Error on login!";
		}
	} elsif (length($sessionid) > 0) {
	  # There is an active session id yet
		$self->{'archiveO'} = Archivista->archive($sessionid);
		if (defined $self->{'archiveO'}) {
			$logged = 1;
		}
	}

	$self->{'htmlO'} = PL::HTML->new($self);
	$self->{'html'} = $self->html->header($cookie);
	
	if ($logged == 1) {
		$self->{'html'} .= $self->html->main;
	} else {
		$self->{'html'} .= $self->html->login;
	}
}

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls)

	IN: class name
	OUT: object

	Construtor for PL::Main

=cut

sub new
{
  my $cls = shift;
  my $self = {};

  bless $self, $cls;

  $self->_init;
  
  return $self;
}

# -----------------------------------------------

=head1 print($self)

	IN: object
	OUT: html string

	Return the complete HTML code to print out

=cut

sub print
{
  my $self = shift;

  if (defined $self->archive) {
  	$self->archive->disconnect if (defined $self->archive->db);
  }
	$self->{'html'} .= $self->html->footer;

  print $self->{'html'};
}

# -----------------------------------------------

=head1 cgi($self)

	IN: object
	OUT: object

	Return the CGI.pm object

=cut

sub cgi
{
  my $self = shift;

  return $self->{'cgiO'};
}

# -----------------------------------------------

=head1 archive($self)

	IN: object
	OUT: object

	Return the Archivista::Archive object of APCL

=cut

sub archive
{
	my $self = shift;

	return $self->{'archiveO'};
}

# -----------------------------------------------

=head1 html($self)

	IN: object
	OUT: object

	Return the PL::HTML object

=cut

sub html
{
  my $self = shift;

	return $self->{'htmlO'};
}

# -----------------------------------------------

=head1 config($self)

	IN: object
	OUT: object

	Return the ASConfig object

=cut

sub config
{
  my $self = shift;

	return $self->{'configO'};
}

# -----------------------------------------------

=head1 error($self)

	IN: object
	OUT: string

	Return an error string

=cut

sub error
{
  my $self = shift;

	return $self->{'error'};
}

1;

__END__

=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: Main.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:02  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.4  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.3  2005/11/21 13:23:54  ms
# Added POD
#
# Revision 1.2  2005/10/26 16:43:15  ms
# Bugfixing of &
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.8  2005/06/08 16:57:01  ms
# Fertigstellung Archiv verwalten und Publizieren
#
# Revision 1.7  2005/05/04 16:59:29  ms
# Entwicklung an Masken Definition
#
# Revision 1.6  2005/04/28 16:40:45  ms
# Implementierung der felder definition (alter table)
#
# Revision 1.5  2005/04/27 17:02:43  ms
# *** empty log message ***
#
# Revision 1.4  2005/04/22 17:28:27  ms
# Entwicklung create/drop database
#
# Revision 1.3  2005/04/20 18:43:17  ms
# Weiterentwicklung: Integration der Sprachenstrings
#
# Revision 1.2  2005/04/15 18:19:31  ms
# Entwicklung login maske / session
#
# Revision 1.1.1.1  2005/04/14 17:44:19  ms
# Import project
#
