# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:21 $

package Archivista::BL::Document;

use strict;

use vars qw ( $VERSION );

use Archivista::BL::Page;
use Archivista::BL::Attribute;
use Archivista::DL::Archive;
use Archivista::DL::ArchivePages;
use Archivista::Util::Collection;

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _init
{
  my $self = shift;
  my $archive = shift;
  my $documentId = shift;

  my $db = $archive->db;
	$self->{'attribute'} = Archivista::BL::Attribute->new();
  $self->{'page_collection'} = Archivista::Util::Collection->new();
  $self->{'archiveT'} = Archivista::DL::Archive->new($db);
  $self->{'archivePagesT'} = Archivista::DL::ArchivePages->new($db);
	
  my $archiveT = $self->{'archiveT'};

  # Check if getter or setter method
  if (defined $documentId) {
    # Setter: load document from data layer
    $archiveT->select($self,$documentId);
  } else {
    # Getter: insert a new document to data layer
    $self->attribute("Seiten")->value(0);
		$documentId = $archiveT->insert();
  }

  $self->archive($archive);
  $self->id($documentId);
}

# -----------------------------------------------

sub _pageCollection
{
  my $self = shift;
  my $pageId = shift;
  my $page = shift;

  if (defined $page) {
    $self->collection("page")->element($pageId,$page);	
  } else {
    return $self->collection("page")->element($pageId);
  }
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
  # If documentId is set, then create an empty document
  # else load the selected document from data layer
	
  my $cls = shift;
  my $archive = shift;
  my $documentId = shift;
  my $self = {};

  bless $self, $cls;

  $self->_init($archive,$documentId);
	
  return $self;
}

# -----------------------------------------------

sub id
{
  my $self = shift;
  my $documentId = shift;

	if (defined $documentId) {
		$self->{'doc_id'} = $documentId;
	} else {
  	return $self->{'doc_id'};
	}
}

# -----------------------------------------------

sub curPageId
{
  my $self = shift;
  my $pageId = shift;

  if (defined $pageId) {
    $self->{'cur_page_id'} = $pageId;
  } else {
    return $self->{'cur_page_id'};
  }
}

# -----------------------------------------------

sub archive
{
  my $self = shift;
  my $archive = shift;

	if (defined $archive) {
		$self->{'archive'} = $archive;
	} else {
		return $self->{'archive'};
	}
}

# -----------------------------------------------

sub attribute
{
  my $self = shift;
  my $attributeId = shift;

  $self->{'attribute'}->id($attributeId) if (defined $attributeId);

  return $self->{'attribute'};
}

# -----------------------------------------------

sub collection
{
  my $self = shift;
  my $collectionType = shift;

	return $self->{$collectionType.'_collection'};
}

# -----------------------------------------------

sub page
{
  my $self = shift;
  my $pageId = shift;

  my $page;

  if (defined $pageId) {
    # Check for pageId or pageNumber
		if (length($pageId) <= 3) {
			$pageId = $self->pageIdByDocAndPageNr($self->id,$pageId);
		}
		$page = Archivista::BL::Page->new($self,$pageId);
		$self->_pageCollection($pageId,$page);
    $self->curPageId($pageId);
	} else {
    my $curPageId = $self->curPageId();
    if (defined $curPageId) {
      $page = $self->_pageCollection($curPageId);
    } else {
			$page = Archivista::BL::Page->new($self);
			$pageId = $page->id;
			$self->_pageCollection($pageId,$page);
		}
  }

  # Check for exception
	$self->_exception;
	
  return $page;
}

# -----------------------------------------------

sub pageIdByDocAndPageNr
{
  my $self = shift;
	my $documentId = shift;
	my $pageNumber = shift;

	return $documentId * 1000 + $pageNumber;
}

# -----------------------------------------------

sub update
{
  my $self = shift;

  my $archiveT = $self->{'archiveT'};
  my $attribute = $self->{'attribute'};
  my $documentId = $self->id;

  $archiveT->update($documentId,$attribute);

  # Check for exception
	$self->_exception;
}

# -----------------------------------------------

sub delete
{
  my $self = shift;

  my $archiveT = $self->{'archiveT'};
  my $archivePagesT = $self->{'archivePagesT'};
	my $documentId = $self->id;

  # Clear document from collection
  $self->archive->clearDocument($documentId);
	# Delete document from archive table
  $archiveT->delete($documentId);
	# Delete related pages from archive pages table
	$archivePagesT->deleteByDocumentId($documentId);

  # Check for exception
	$self->_exception;
}

# -----------------------------------------------

sub clearPage
{
  my $self = shift;
	my $pageId = shift;

  undef $self->{'cur_page_id'};

	if (defined $pageId) {
		$self->collection("page")->remove($pageId);
	} else {
		$self->collection("page")->clear;
	}
}

1;

__END__

=head1 NAME

  Archivista::BL::Document

=head1 SYNOPSYS

  # Create a document without returning the id
  $archive->document;

  # Create a new document and return the id 
  my $documentId = $archive->document->id;
  
  # Preselect a document given a document id
  $archive->document($documentId);

  # Set a current page id for a document
  $archive->document->curPageId($pageId);
	
  # Create a new page for a preselected document
  $archive->document->page;
	
  # Create a new page without preselected document
  $archive->document($documentId)->page;

  # Create a page for a preselected document and return the id
  my $pageId = $archive->document->page->id;
	
  # Preselect a page of a document given a pageNumber (1..640)
  $archive->document->page($pageNumber);

  # Preselect a page of a document give a pageId (75001)
  $archive->document->page($pageId);
	
  # Return the current selected page id
  my $curPageId = $archive->document->curPageId;
	
	# Update the document attribute values (write the changes to the database)
	# This syntax requires a preselected document
  $archive->document->update;

  # The same as above without preselecting a document
  $archive->document($documentId)->update;
	
  # Delete the preselected document
  # NOTE: all related pages will also be lost
  $archive->document->delete;

  # The same as above withour preselecting a document
  $archive->document($documentId)->delete;
	
=head1 DESCRIPTION

  This package provides methods to deal with documents

=head1 DEPENDENCIES

  Archivista::BL::Page
  Archivista::BL::Attribute
  Archivista::DL::Archive
  Archivista::DL::ArchivePages
  Archivista::Util::Collection
	
=head1 EXAMPLE

  use Archivista;

  my $archive = Archivista->archive("averl");
  
  my $documentId = $archive->document->id;
  $archive->document($documentId);

  $archive->document->page;
	my $pageId = $archive->document->page->id;

  $archive->document->curPageId($pageId);
	
=head1 TODO


=head1 AUTHOR

  Markus Stocker, Archivista GmbH Zurich
	
=cut

# Log record
# $Log: Document.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:21  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.9  2005/06/08 16:56:01  ms
# Anpassungen an _exception
#
# Revision 1.8  2005/04/21 14:57:01  ms
# Diverse Anpassungen
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
# Revision 1.3  2005/03/11 18:58:47  ms
# Weiterentwicklung an Archivista Perl Class Library
#
# Revision 1.2  2005/03/11 15:01:07  ms
# Anpassungen
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
# Revision 1.2  2005/03/08 15:49:35  ms
# currentDocument / currentPage
#
# Revision 1.1  2005/03/08 15:19:28  ms
# Files added
#
