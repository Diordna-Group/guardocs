# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::DL::Languages;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::Config;
use Archivista::DL::DB;

@ISA = qw ( Archivista::DL::DB );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PUBLIC METHODS

sub new
{
	my $cls = shift;
	my $languages = shift; # Object of Archivista::BL::Languages
	my $db = shift; # Object of Archivista::DL::DB
  my $lang = shift;
	my $config = Archivista::Config->new;
	my $self = {};
  
	bless $self, $cls;

  $self->db($db);

	my $database = $config->get("AV_GLOBAL_DB");
  my $dbh = $db->sudbh;
	
	$self->selectdb($database);

  my $query = "SELECT id, $lang FROM languages";
	my $sth = $dbh->prepare($query);
	$sth->execute;

	while (my @row = $sth->fetchrow_array()) {
		$languages->string($row[0],$row[1]);
	}

  $self->selectdb($db->database);
	
	return $self;
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
# $Log: Languages.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/07 12:26:12  ms
# Update for administration of remote databases
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.2  2005/04/22 17:27:48  ms
# Anpassungen für Archivverwaltung
#
# Revision 1.1  2005/04/20 16:16:14  ms
# Import new languages modules
#
