# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:21 $

package Archivista::BL::Page;

use strict;

use vars qw ( $VERSION );

use Archivista::Config;
use Archivista::BL::Attribute;
use Archivista::DL::ArchivePages;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init
{
	my $self = shift;
	my $document = shift;
  my $pageId = shift;

	my $db = $document->archive->db;
	$self->{'attribute'} = Archivista::BL::Attribute->new();
	$self->{'archivePagesT'} = Archivista::DL::ArchivePages->new($db);

	my $archivePagesT = $self->{'archivePagesT'};

	# Check if getter or setter method
	if (defined $pageId) {
		# Setter: load page from data layer
		$archivePagesT->select($self,$pageId);
	} else {
		# Getter: insert a new page to data layer
		$pageId = _newPageId($document);
		$archivePagesT->insert($pageId);
	}
	
	$self->{'page_id'} = $pageId;
}

# -----------------------------------------------

sub _newPageId
{
	my $document = shift;

  my $documentId = $document->id;
	my $nrOfPages = $document->attribute("Seiten")->value + 1;
	$document->attribute("Seiten")->value($nrOfPages);
	$document->update;
	
	return $document->pageIdByDocAndPageNr($documentId,$nrOfPages);
}

# -----------------------------------------------

sub _exception
{
  my $self = shift;
	
	if (length($@) > 0) {
	  my $exception = $@;
		my $config = Archivista::Config->new;
		my $io = Archivista::Util::IO->new;
		$io->append($config->get("LOG_FILE"),$exception);
		undef $@;
		delete $self->{'db'};
	}
}

# -----------------------------------------------
# PUBLIC METHODS

sub new
{
  my $cls = shift;
  my $document = shift;
	my $pageId = shift;
	my $self = {};

  bless $self, $cls;

  $self->_init($document,$pageId);
	
  return $self;
}

# -----------------------------------------------

sub id
{
	my $self = shift;

	return $self->{'page_id'};
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

sub update
{
  my $self = shift;
	
	my $archivePagesT = $self->{'archivePagesT'};
	my $attribute = $self->{'attribute'};
	my $pageId = $self->id;

	$archivePagesT->update($pageId,$attribute);

  # Check for exception
	$self->_exception;
}

# -----------------------------------------------

sub delete
{
  my $self = shift;

	my $archivePagesT = $self->{'archivePagesT'};
	my $pageId = $self->id;

	$archivePagesT->delete($pageId);

	# Check for exception
	$self->_exception;
}

1;

__END__

=head1 NAME

  Archivista::BL::Page

=head1 SYNOPSYS

  # Set a page id as current page
  $archive->document->page($pageId);
	
  # Return the page id
  my $pageId = $archive->document->page->id;

	# Save page attributes to database
  $archive->document->page->update;

  # Delete a single page from database
  $archive->document->page->delete;


=head1 DESCRIPTION

  This package provides methods to deal with pages

=head1 DEPENDENCIES

  Archivista::BL::Attribute
  Archivista::DL::ArchivePages

=head1 EXAMPLE

  use Archivista;
	
  my $archive = Archivista->archive("averl","localhost","root","admin");

  $archive->document(1)->page(1001);
  $archive->document->page->attribute("Text")->value("A simple OCR recognition");
  $archive->document->page->update;
  $archive->document->page->delete;
	
=head1 TODO


=head1 AUTHOR

  Markus Stocker, Archivista GmbH Zurich

=cut

# Log record
# $Log: Page.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:21  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.10  2005/06/08 16:56:01  ms
# Anpassungen an _exception
#
# Revision 1.9  2005/04/21 14:57:01  ms
# Diverse Anpassungen
#
# Revision 1.8  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.7  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.6  2005/03/15 18:39:22  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.5  2005/03/14 17:29:11  ms
# Weiterentwicklung an APCL: einfuehrung der klassen BL/User sowie Util/Exception
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
