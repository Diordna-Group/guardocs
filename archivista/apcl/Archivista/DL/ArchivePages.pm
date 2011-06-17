# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:22 $

package Archivista::DL::ArchivePages;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::DL::DB;

@ISA = qw ( Archivista::DL::DB );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------

sub new
{
	my $cls = shift;
	my $db = shift;
  my $self = {};

	bless $self, $cls;

  $self->db($db);

	return $self;
}

# -----------------------------------------------

sub select 
{
  my $self = shift;
  my $page = shift;
  my $pageId = shift;
	
	my $dbh = $self->db->dbh;
	my $query = "SELECT * FROM archivseiten WHERE Seite = $pageId";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	if ($sth->rows) {
	  while (my $hash_ref = $sth->fetchrow_hashref()) {
		  foreach my $key (keys %$hash_ref) {
			  my $value = $$hash_ref{$key};
			  $page->attribute($key)->value($value,0);
		  }
	  }
  } else {
		my $exception = "Page $pageId not found ($query)";
		$self->exception($exception,__FILE__,__LINE__);
	}

	$sth->finish();
}

# ---------------------------------------------------------

sub insert
{
  my $self = shift;
  my $pageId = shift;
	
  my $dbh = $self->db->dbh;
	my $query = "INSERT INTO archivseiten (Seite) VALUES ($pageId)";
	my $do = $dbh->do($query);

	my $exception = "Failed to insert page $pageId ($query)";
	$self->exception($exception,__FILE__,__LINE__) if ($do != 1);
}

# -----------------------------------------------

sub update
{
  my $self = shift;
	my $pageId = shift;
	my $attribute = shift;

  my $dbh = $self->db->dbh;
	my $attributesToUpdate = $self->attributesToString($attribute);
	if (length($attributesToUpdate) > 0) {
	  my $query = "UPDATE archivseiten SET $attributesToUpdate ";
	  $query .= "WHERE Seite = $pageId";
	  my $do = $dbh->do($query);
	
	  my $exception = "Failed to update page $pageId ($query)";
	  $self->exception($exception,__FILE__,__LINE__) if ($do != 1);
  }
}

# -----------------------------------------------

sub delete
{
  my $self = shift;
	my $pageId = shift;

	my $dbh = $self->db->dbh;
  my $query = "DELETE FROM archivseiten WHERE Seite = $pageId";
	my $do = $dbh->do($query);

	my $exception = "Failed to delete page $pageId ($query)";
	$self->exception($exception,__FILE__,__LINE__) if ($do != 1);
}

# -----------------------------------------------

sub deleteByDocumentId
{
  my $self = shift;
	my $documentId = shift;

	my $dbh = $self->db->dbh;
	my $query = "DELETE FROM archivseiten WHERE Seite LIKE '$documentId%'";
	my $do = $dbh->do($query);

	my $exception = "No pages deleted for document $documentId ($query)";
	$self->exception($exception,__FILE__,__LINE__) if ($do < 1);
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
# $Log: ArchivePages.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:22  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.8  2005/03/31 13:44:26  ms
# Implementierung der copy data from database Funktionalität
#
# Revision 1.7  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.6  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.5  2005/03/18 15:38:42  ms
# Stabile version um User hinzuzufügen
#
# Revision 1.4  2005/03/15 18:39:22  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.3  2005/03/14 17:29:11  ms
# Weiterentwicklung an APCL: einfuehrung der klassen BL/User sowie Util/Exception
#
# Revision 1.2  2005/03/14 11:46:44  ms
# Erweiterungen auf archivseiten
#
# Revision 1.1  2005/03/11 18:59:21  ms
# Files added
#
