# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:19 $

package Archivista;

use strict;

use Archivista::BL::Archive;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------

=head1 archive($cls,$access,$host,$uid,$pwd,$lang)

	IN: class name
	    access mode (over database name or session id, for already logged users)
	    host name
	    user name
	    password
	    language code
	OUT: object

	Constructor for archivista class library. This method gets a connection to a
	specific archivista archive. You must provide either a session id or a
	database name. In case of database name, provide the host name, user name and
	password too.

	Please note: to set a language code giving a session id invoque the method
	with Archivista->archive($sid,undef,undef,undef,$lang)
	
=cut

sub archive
{
  my $cls = shift;
	my $access = shift; # Can be a session id or an archive name
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
  my $lang = shift;
	
  return Archivista::BL::Archive->load($access,$host,$uid,$pwd,$lang); 
}

# -----------------------------------------------

=head1 create($cls,$archiveName,$cpDataFromArchive,$host,$uid,$pwd)

	IN: class name
	    archive name
	    existing archive name
	    host name
	    user name
	    password
	OUT: object

	This method creates a new archivista archive. Provide a name of an existing
	archive to copy the parameter settings to the new archive or undef the second
	method parameter to create an empty archive.

=cut

sub create
{
  my $cls = shift;
	my $archiveName = shift;
	my $cpDataFromArchive = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;

	return Archivista::BL::Archive->create($archiveName,$cpDataFromArchive,$host,$uid,$pwd);
}

# -----------------------------------------------

=head1 drop($cls,$archiveName,$host,$uid,$pwd)

	IN: class name
	    archive name
	    host name
	    user name
	    password
	OUT: -

	This method drops an existing archive

=cut

sub drop
{
  my $cls = shift;
	my $archiveName = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
	
  my $archive = Archivista::BL::Archive->load($archiveName,$host,$uid,$pwd);
  $archive->drop($archiveName);
  $archive->session->delete;
	$archive->disconnect;
}

1;

__END__

=head1 NAME

  Archivista.pm

=head1 SYNOPSYS

  use Archivista;

  ################################################
  # Create a new archivista archive
  ################################################

  # Syntax only with the (required) archive name
  my $archive = Archivista->create($archiveName);
  
  # Syntax with hostname, username and password for database access
  my $archive = Archivista->create($archiveName,$host,$uid,$pwd);
  

  ################################################
  # Create a connection to an archivista archive
  ################################################
	
  # Syntax only with the (required) archive name
  my $archive = Archivista->archive($archiveName);

  # Syntax with hostname, username and password for database access
  my $archive = Archivista->archive($archiveName,$host,$uid,$pwd);

 
  ###############################################
  # Managing documents and pages
  ###############################################

  # Create a new document
  $archive->document;

  # Create a new document and return the id
  my $documentId = $archive->document->id;

  # Select the document given an id
  $archive->document($documentId);

  # Create and select a document
  $archive->document($archive->document->id);

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
	
  # Return the current selected document id
  my $curDocumentId = $archive->curDocId;
	
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

  # Save page attributes to database with preselected document and page
  $archive->document->page->update;

  # Same as above without preselected document and page
  $archive->document($documentId)->page($pageId)->update;
	
  # Delete a single page from database with preselected document and page
  $archive->document->page->delete;
	
  # Same as above without preselected document and page
  $archive->document($documentId)->page($pageId)->delete;

  # Retrieve document attributes with preselected document
  my $pages = $archive->document->attribute("Seiten")->value;

  # Retrieve document attributes without preselected document
  my $pages = $archive->document($documentId)->attribute("Seiten")->value;
  
	# Retrieve page attributes with preselected document and page
  my $ocr = $archive->document->page->attribute("Text")->value;
	
  # Set document attributes with preselected document
  $archive->document->attribute("Titel")->value("First document");

  # Set page attributes with preselected document and page
  $archive->document->page->attribute("Text")->value("A simple OCR");
	
  # Clear the document collection
  $archive->clearDocument;

  # Remove a document from the document collection
  $archive->clearDocument($documentId);


  ###############################################
  # Managing users
  ###############################################
	
  # Select a user given a user id 
  $archive->user($userId);

  # Create a new user
  $archive->user(undef,"localhost","root","admin");

  # Create a new user and return the id
  my $userId = $archive->user(undef,"localhost","root","admin")->id;
	
  # Select a user
  $archive->user($userId);
	
	# Retrieve user attributes with preselected user
  my $password = $archive->user->attributes("Password")->value;

	# Retrieve user attributes without preselected user
  my $password = $archive->user($userId)->attribute("Password")->value;

  # Set a user attribute with preselected user
  $archive->user->attribute("Password")->value("admin");

  # Clear the user collection
  $archive->clearUser;

  # Remove a user from the user collection
  $archive->clearUser($userId);


=head1 DESCRIPTION

  Main entry point for Archivista Perl Class Library (APCL)

  Please note:
	
  - if we make a connection to an archivista archive without the
  optional parameters hostname, username and password for the database, the
  library takes the informations form the Archivista::Config module. Rememeber
  that the user on Archivista::Config must be an admin of the DBMS.
	
	- Archivista::Config must allways define host, username and password for a
  root user of the DBMS.
		
=head1 DEPENDENCIES

  Archivista::BL::Archive

=head1 EXAMPLE

  use Archivista;

  my $archive = Archivista->archive("averl");
  my $archive = Archivista->archive("averl","localhost","root","admin");

=head1 TODO

  -

=head1 AUTHOR

  Markus Stocker, Archivista GmbH Zurich

=cut

# Log record
# $Log: Archivista.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:19  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/21 13:23:54  ms
# Added POD
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.8  2005/04/22 17:27:48  ms
# Anpassungen für Archivverwaltung
#
# Revision 1.7  2005/04/20 17:56:51  ms
# Set language as parameter on connecting (Archivista::archive) to an archive
#
# Revision 1.6  2005/04/06 18:19:16  ms
# Entwicklung an der session datenbank
#
# Revision 1.5  2005/03/31 13:44:26  ms
# Implementierung der copy data from database Funktionalität
#
# Revision 1.4  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.3  2005/03/21 18:33:20  ms
# Erzeugung neuer archivista datenbanken
#
# Revision 1.2  2005/03/15 18:39:22  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.1.1.1  2005/03/11 14:01:22  ms
# Archivista Perl Class Library Projekt imported
#
