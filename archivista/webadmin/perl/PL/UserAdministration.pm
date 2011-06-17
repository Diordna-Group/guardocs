# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:03 $

# -----------------------------------------------

=head1 NAME


=head1 SYNOPSYS


=head1 DESCRIPTION


=cut

# -----------------------------------------------

package PL::UserAdministration;

use strict;

# -----------------------------------------------
# PRIVATE METHODS

# -----------------------------------------------
# PUBLIC METHODS

=head1 new($cls,$archiveO)

	IN: class name
	    object (Archivista::BL::Archive APCL)
	OUT: object

	Constructor

=cut

sub new
{
  my $cls = shift;
  my $archiveO = shift; # Object of Archivista::BL::Archive (APCL)
	my $self = {};

  bless $self, $cls;

  my @fields = ("host","username","password","level","new_documents",
								"new_documents_owner","group","internal_pages","web",
								"workflow","numberof","avform","avstart","email","annex","notes");
	
  $self->{'archiveO'} = $archiveO;
	$self->{'field_list'} = \@fields;
	
  return $self;
}

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of fields information required to insert and update
	new definitions

=cut


sub fields
{
  my $self = shift;
  my $cgiO = shift;
	my $archiveO = $self->archive;
  my $langO = $self->archive->lang;
  	
  my $papasswordTypes = $archiveO->passwordTypes("ARRAY");
	my $phpasswordTypes = $archiveO->passwordTypes("HASH");
  my $phuserLevels = $archiveO->userLevelsByHash;
	my $pauserLevels = $archiveO->userLevelsByArray;
	my $panewDocumentOwners = $archiveO->documentOwners;
	my $phnewDocumentOwners = $archiveO->documentOwners("HASH");
	my $phmaskDefinitions = $archiveO->maskDefinitions;
	my @maskDefinitions = sort keys %$phmaskDefinitions;
  my $phuserSqlDefinitions = $archiveO->userSqlDefinitions;
	my @userSqlDefinitions = sort keys %$phuserSqlDefinitions;
  # Add an empty item to sql definitions
	unshift @userSqlDefinitions, "";
  # Drop 0 value!
	shift @$papasswordTypes;

	my (%fields);	
  $fields{'list'} = $self->{'field_list'};
  $fields{'host'}{'label'} = $langO->string("HOST");
	$fields{'host'}{'name'} = "user_host";
	$fields{'host'}{'type'} = "textfield";
	$fields{'host'}{'update'} = 0;
	$fields{'username'}{'label'} = $langO->string("USERNAME");
	$fields{'username'}{'name'} = "user_name";
	$fields{'username'}{'type'} = "textfield";
	$fields{'username'}{'update'} = 0;
#	$fields{'password'}{'label'} = $langO->string("PASSWORD");
#	$fields{'password'}{'name'} = "user_password";
#	$fields{'password'}{'type'} = "password";
#	$fields{'password'}{'update'} = 1;
#	$fields{'new_password'}{'label'} = $langO->string("NEW_PASSWORD_ON_LOGIN");
#	$fields{'new_password'}{'name'} = "user_new_password";
#	$fields{'new_password'}{'type'} = "checkbox";
#	$fields{'new_password'}{'update'} = 1;
#	$fields{'clear_password'}{'label'} = $langO->string("CLEAR_PASSWORD");
#	$fields{'clear_password'}{'name'} = "user_clear_password";
#	$fields{'clear_password'}{'type'} = "checkbox";
#	$fields{'clear_password'}{'update'} = 1;
	$fields{'password'}{'label'} = $langO->string("PASSWORD");
	$fields{'password'}{'name'} = "user_password";
	$fields{'password'}{'type'} = "select";
	$fields{'password'}{'array_values'} = $papasswordTypes;
	$fields{'password'}{'hash_values'} = $phpasswordTypes;
	$fields{'password'}{'update'} = 1;
	$fields{'level'}{'label'} = $langO->string("LEVEL");
	$fields{'level'}{'name'} = "user_level";
	$fields{'level'}{'type'} = "select";
	$fields{'level'}{'array_values'} = $pauserLevels;
	$fields{'level'}{'hash_values'} = $phuserLevels;
	$fields{'level'}{'update'} = 1;
	$fields{'new_documents'}{'label'} = $langO->string("OPEN_NEW_DOCUMENTS");
	$fields{'new_documents'}{'name'} = "user_new_documents";
	$fields{'new_documents'}{'type'} = "checkbox";
	$fields{'new_documents'}{'update'} = 1;
	$fields{'new_documents_owner'}{'label'} = $langO->string("NEW_DOCUMENTS_OWNER");
	$fields{'new_documents_owner'}{'name'} = "new_documents_owner";
	$fields{'new_documents_owner'}{'type'} = "select";
	$fields{'new_documents_owner'}{'array_values'} = $panewDocumentOwners;
	$fields{'new_documents_owner'}{'hash_values'} = $phnewDocumentOwners;
	$fields{'new_documents_owner'}{'update'} = 1;
	$fields{'group'}{'label'} = $langO->string("GROUPS");
	$fields{'group'}{'name'} = "user_group";
	$fields{'group'}{'type'} = "textfield";
	$fields{'group'}{'update'} = 1;
	$fields{'internal_pages'}{'label'} = $langO->string("INTERNAL_PAGES");
	$fields{'internal_pages'}{'name'} = "user_internal_pages";
	$fields{'internal_pages'}{'type'} = "checkbox";
	$fields{'internal_pages'}{'update'} = 1; 
	$fields{'web'}{'label'} = $langO->string("WEB");
	$fields{'web'}{'name'} = "user_web";
	$fields{'web'}{'type'} = "checkbox";
	$fields{'web'}{'update'} = 1; 
  $fields{'workflow'}{'label'} = $langO->string("WORKFLOW");
	$fields{'workflow'}{'name'} = "user_workflow";
	$fields{'workflow'}{'type'} = "checkbox";
	$fields{'workflow'}{'update'} = 1; 
	$fields{'numberof'}{'label'} = $langO->string("NUMBEROF");
	$fields{'numberof'}{'name'} = "user_numberof";
	$fields{'numberof'}{'type'} = "textfield";
	$fields{'numberof'}{'update'} = 1;
	$fields{'avform'}{'label'} = $langO->string("FORM_DEFINITION");
	$fields{'avform'}{'name'} = "user_avform";
	$fields{'avform'}{'type'} = "select";
  $fields{'avform'}{'array_values'} = \@maskDefinitions;
	$fields{'avform'}{'hash_values'} = $phmaskDefinitions;
	$fields{'avform'}{'update'} = 1;
	$fields{'avstart'}{'label'} = $langO->string("SQL_DEFINITION");
	$fields{'avstart'}{'name'} = "user_avstart";
	$fields{'avstart'}{'type'} = "select";
	$fields{'avstart'}{'array_values'} = \@userSqlDefinitions;
	$fields{'avstart'}{'hash_values'} = $phuserSqlDefinitions;
	$fields{'avstart'}{'update'} = 1;
	$fields{'email'}{'label'} = $langO->string("EMAIL_ACCOUNT");
	$fields{'email'}{'name'} = "user_email";
	$fields{'email'}{'type'} = "textfield";
	$fields{'email'}{'update'} = 1;
	$fields{'annex'}{'label'} = $langO->string("ANNEX");
	$fields{'annex'}{'name'} = "user_annex";
  $fields{'annex'}{'type'} = "textfield";
	$fields{'annex'}{'update'} = 1;
	$fields{'notes'}{'label'} = $langO->string("NOTES");
	$fields{'notes'}{'name'} = "user_notes";
	$fields{'notes'}{'type'} = "textarea";
	$fields{'notes'}{'update'} = 1;
	
  if ($cgiO->param("adm") eq "edit") {
		my $id = $cgiO->param("id");
		if (defined $id) {
			my $user = $archiveO->user($id);
			my $newPwdOnLogin = 0;
			$newPwdOnLogin = 1 if ($user->attribute("PWArt")->value == 2);
			$fields{'host'}{'value'} = $user->attribute("Host")->value;
			$fields{'username'}{'value'} = $user->attribute("User")->value;
			$fields{'password'}{'value'} = $user->attribute("PWArt")->value;
			$fields{'level'}{'value'} = $user->attribute("Level")->value;
			$fields{'new_documents'}{'value'} = $user->attribute("AddOn")->value;
			$fields{'new_documents_owner'}{'value'} = $user->attribute("AddNew")->value;
			$fields{'internal_pages'}{'value'} = $user->attribute("ZugriffIntern")->value;
			$fields{'web'}{'value'} = $user->attribute("ZugriffWeb")->value;
			$fields{'workflow'}{'value'} = $user->attribute("Workflow")->value;
			$fields{'numberof'}{'value'} = $user->attribute("Anzahl")->value;
			$fields{'avform'}{'value'} = sprintf "%02d", $user->attribute("AVForm")->value; # Display 01,02,03 not 1,2,3
			$fields{'avstart'}{'value'} = $user->attribute("AVStart")->value;
			$fields{'group'}{'value'} = $user->attribute("Alias")->value;
		  $fields{'email'}{'value'} = $user->attribute("EMail")->value;
			$fields{'annex'}{'value'} = $user->attribute("Zusatz")->value;
			$fields{'notes'}{'value'} = $user->attribute("Bemerkungen")->value;
			# For level 255 and 0 new_documents* are not editable
			#if ($fields{'level'}{'value'} == 255 or $fields{'level'}{'value'} == 0) {
			#	my $newDocumentsValue = $langO->string("YES");
			#	$newDocumentsValue = $langO->string("NO") if ($fields{'new_documents'}{'value'} == 0);
			#	$fields{'new_documents'}{'value'} = $newDocumentsValue;
			#	$fields{'new_documents'}{'update'} = 0;
			#	$fields{'new_documents_owner'}{'update'} = 0;
			#}
		}
	} else {
		$fields{'host'}{'value'} = "localhost";
		$fields{'password'}{'value'} = "3";
		$fields{'numberof'}{'value'} = 1000;
		$fields{'internal_pages'}{'value'} = 1;
		$fields{'web'}{'value'} = 1;
		$fields{'new_documents'}{'value'} = 1;
		$fields{'level'}{'value'} = 1;
	}

  $fields{'displayBackFormButton'} = 1;

  return \%fields;
}

# -----------------------------------------------

=head1 save($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Save a specific definition (insert and update)

=cut

sub save
{
  my $self = shift;
	my $cgiO = shift; # Object of CGI.pm
	my $archiveO = $self->archive;
  my $id = $cgiO->param("id");

  my ($user);
  my $host = $cgiO->param("user_host");
  my $uid = $cgiO->param("user_name");
	my $pwd = $cgiO->param("user_password");
	my $clearPwd = $cgiO->param("user_clear_password");
	my $passwordType = $cgiO->param("user_password");
	my $level = $cgiO->param("user_level");
	my $newDocuments = $cgiO->param("user_new_documents");
	# MOD 29.4.2006 -> changed, so we can save this value (up)
	my $newDocumentsOwner = $cgiO->param("new_documents_owner");
	my $group = $cgiO->param("user_group");
	my $internalPages = $cgiO->param("user_internal_pages");
	my $web = $cgiO->param("user_web");
	my $workflow = $cgiO->param("user_workflow");
	my $numberof = $cgiO->param("user_numberof");
  my $avform = int $cgiO->param("user_avform"); # Saving 1,2,3 not 01,02,03
	my $avstart = $cgiO->param("user_avstart");
	my $email = $cgiO->param("user_email");
	my $annex = $cgiO->param("user_annex");
	my $notes = $cgiO->param("user_notes");
	$web = 0 if (! defined $web);
	$internalPages = 0 if (! defined $internalPages);
	$workflow = 0 if (! defined $workflow);
	$newDocuments = 0 if (! defined $newDocuments);
	$numberof = 1000 if (! defined $numberof);

  if (length($uid) > 0 or $id > 0) {
		if (defined $id) {
			$user = $archiveO->user($id);
			#$user->attribute("Host")->value($host);
			#$user->attribute("User")->value($uid);
			if (length($pwd) > 0) {
				$user->attribute("Password")->value($pwd);
			} elsif ($clearPwd == 1) {
				$user->attribute("Password")->value("");
			}
			$user->attribute("Level")->value($level);
		} else {
			my $userId = $archiveO->user($host,$uid,$pwd,$level)->id;
			$user = $archiveO->user($userId);
		}

    $user->attribute("PWArt")->value($passwordType);
		$user->attribute("AddOn")->value($newDocuments);
		$user->attribute("AddNew")->value($newDocumentsOwner);
		$user->attribute("ZugriffIntern")->value($internalPages);
		$user->attribute("ZugriffWeb")->value($web);
		$user->attribute("Workflow")->value($workflow);
		$user->attribute("Anzahl")->value($numberof);
		$user->attribute("AVForm")->value($avform);
		$user->attribute("AVStart")->value($avstart);
		$user->attribute("Alias")->value($group);
		$user->attribute("EMail")->value($email);
		$user->attribute("Zusatz")->value($annex);
		$user->attribute("Bemerkungen")->value($notes);
		$user->update;
	}
}

# -----------------------------------------------

=head1 elements($self)

	IN: object(self)
	OUT: pointer to hash

	Get all definitions to display on the table

=cut

sub elements
{
  my $self = shift;
	my $archiveO = $self->archive;
  my $langO = $archiveO->lang;
	my $pusers = $archiveO->users;
	
	my (@list,%users);
	# Attributes to display on table
	my @attributes = ("host","username","level");
	
	foreach my $user (@$pusers) {
		my $id = $$user[3];
		push @list, $id;
		$users{$id}{'host'} = $$user[0];
		$users{$id}{'username'} = $$user[1];
		$users{$id}{'level'} = $langO->string("LEVEL_".$$user[2]);
	  $users{$id}{'delete'} = $$user[4];
		$users{$id}{'update'} = $$user[5];
	}

  $users{'new'} = 1;
  $users{'attributes'} = \@attributes;
  $users{'list'} = \@list;

	return \%users;
}

# -----------------------------------------------

=head1 delete($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Delete a definition thru the APCL

=cut

sub delete
{
  my $self = shift;
	my $cgiO = shift;
	my $archiveO = $self->archive;
	my $id = $cgiO->param("id");

	if (defined $id) {
		$archiveO->user($id)->delete;
	}
}

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive)

	Return the object of APCL

=cut

sub archive
{
  my $self = shift;

	return $self->{'archiveO'};
}

1;

__END__

=head1 EXAMPLE


=head1 TODO


=head1 AUTHOR


=cut

# Log record
# $Log: UserAdministration.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:03  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.4  2006/05/06 16:49:14  up
# Bugs: First document, scanning to another database
#
# Revision 1.3  2006/04/29 14:34:02  up
# Save 'new user with owner' correct
#
# Revision 1.2  2005/11/29 18:24:07  ms
# Added POD
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.13  2005/07/12 17:13:01  ms
# Entwicklung an BarcodeProcess
#
# Revision 1.12  2005/06/01 13:19:58  ms
# Implementierung der neuen passwort abfrage
#
# Revision 1.11  2005/05/27 16:41:23  ms
# Bugfix
#
# Revision 1.10  2005/05/27 15:43:38  ms
# Entwicklung an database administration
#
# Revision 1.9  2005/05/26 17:44:12  ms
# *** empty log message ***
#
# Revision 1.8  2005/05/26 15:53:48  ms
# Anpassungen für LinuxTag
#
# Revision 1.7  2005/05/12 13:02:28  ms
# Last changes vor v.1.0
#
# Revision 1.6  2005/05/11 18:23:49  ms
# Entwicklung masken definitionen
#
# Revision 1.5  2005/05/06 15:43:39  ms
# Edit mask name, sql definitions for user
#
# Revision 1.4  2005/05/04 16:59:29  ms
# Entwicklung an Masken Definition
#
# Revision 1.3  2005/04/27 17:02:43  ms
# *** empty log message ***
#
# Revision 1.2  2005/04/22 17:28:27  ms
# Entwicklung create/drop database
#
# Revision 1.1  2005/04/21 16:40:47  ms
# Files added to project
#
