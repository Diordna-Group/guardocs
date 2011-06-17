# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:21:03 $

# -----------------------------------------------


# -----------------------------------------------

package PL::SQLDefinition;

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
    my $archiveO = shift;   # Object of Archivista::BL::Archive (APCL)
    my $self = {};

    bless $self, $cls;

    my @fields = ("def_id","def_name","def_desc","def_user","def_val");
  
    $self->{'archiveO'} = $archiveO;
    $self->{'field_list'} = \@fields;
  
    return $self;
  }

# -----------------------------------------------

=head1 fields($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: pointer to hash

	Return a pointer to hash of all fields and information about the fields which
	must be displayed in the form to add new definitions or update existing
	definitions.

=cut

sub fields {
    my $self = shift;
    my $cgiO = shift;
    my $archiveO = $self->archive;
    my $langO = $self->archive->lang;
	  my $dbh = $archiveO->db->dbh;

    my (%fields); 

    $fields{'list'} = $self->{'field_list'};
    $fields{'def_id'}{'label'} = $langO->string("SQLID");
    $fields{'def_id'}{'name'} = "def_id";
    $fields{'def_id'}{'type'} = "hidden";
    $fields{'def_id'}{'update'} = 0;
		
    $fields{'list'} = $self->{'field_list'};
    $fields{'def_name'}{'label'} = $langO->string("NAME");
    $fields{'def_name'}{'name'} = "def_name";
    $fields{'def_name'}{'type'} = "textfield";
    $fields{'def_name'}{'update'} = 1;

    $fields{'list'} = $self->{'field_list'};
    $fields{'def_desc'}{'label'} = $langO->string("COMMENT");
    $fields{'def_desc'}{'name'} = "def_desc";
    $fields{'def_desc'}{'type'} = "textfield";
    $fields{'def_desc'}{'update'} = 1;

    $fields{'list'} = $self->{'field_list'};
    $fields{'def_user'}{'label'} = $langO->string("USER");
    $fields{'def_user'}{'name'} = "def_user";
    $fields{'def_user'}{'type'} = "textfield";
    $fields{'def_user'}{'update'} = 1;

    $fields{'list'} = $self->{'field_list'};
    $fields{'def_val'}{'label'} = $langO->string("SQLDEF");
    $fields{'def_val'}{'name'} = "def_val";
    $fields{'def_val'}{'type'} = "textfield";
    $fields{'def_val'}{'update'} = 1;

    if ($cgiO->param("adm") eq "edit") {
      my $id = $cgiO->param("id");
      if (defined $id) {
			  my $sql = "select Name,Beschreibung,User,Inhalt " .
				          "from parameter where Laufnummer=$id";
				my @row = $dbh->selectrow_array($sql);
	      $fields{'def_id'}{'value'} = $id;
	      $fields{'def_name'}{'value'} = $row[0];
	      $fields{'def_desc'}{'value'} = $row[1];
	      $fields{'def_user'}{'value'} = $row[2];
	      $fields{'def_val'}{'value'} = $row[3];
			}
		} else {
      $fields{'def_name'}{'value'} = "New Selection";
      $fields{'def_desc'}{'value'} = "";
      $fields{'def_user'}{'value'} = "";
      $fields{'def_val'}{'value'} = "";
      $fields{'def_id'}{'value'} = 0;
    }
    $fields{'displayBackFormButton'} = 1;
    return \%fields;
}

# -----------------------------------------------

=head1 save($self,$cgiO)

	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Save the data of a definition to the database. This method performs updates
	and inserts of new definitions.

=cut

sub save
  {
    my $self = shift;
    my $cgiO = shift;		# Object of CGI.pm
    my $archiveO = $self->archive;
	  my $dbh = $archiveO->db->dbh;
    my $id = $cgiO->param("id");

    my $name = $cgiO->param("def_name");
		my $desc = $cgiO->param("def_desc");
		my $user = $cgiO->param("def_user");
		my $val = $cgiO->param("def_val");

    # Set Space because DB is not really designed.
		# you can't save NULL as description.
		# It was made in the default SQLDef -.-
    $desc = ' ' if ($desc eq '');
		# Same with user -.-
		$user = ' ' if ($user eq '');
    if ($cgiO->param("submit") eq $self->archive->lang->string("SAVE")) {
		  my $sql = "Art='SQL',Tabelle='archiv'";
		  $sql .= ",Name=".$dbh->quote($name);
			$sql .= ",Beschreibung=".$dbh->quote($desc);
			$sql .= ",User=".$dbh->quote($user);
			$sql .= ",Inhalt=".$dbh->quote($val);
      if (defined $id) {
			  $sql = "update parameter set ".$sql." where Laufnummer=$id";
			} else {
			  $sql = "insert into parameter set ".$sql;
			}
			print STDERR "SQLSQL:::".$sql.":::LQSLQS";
			$dbh->do($sql);
    }
  }






=head1 copy($cgi)

Gets SQL Infos and saves it to a File

=cut

sub copy {
  my $self = shift;
	my $cgi = shift;

  my $id = $cgi->param('id');
  my $search = "Name,Beschreibung,User,Inhalt";
  my $sql = "select $search from parameter where Laufnummer = $id";
	my @result = $self->archive->db->dbh->selectrow_array($sql);

  my $name = "Copy of ".$result[0];
	my $desc = $result[1];
	my $user = $result[2];
	my $val = $result[3];

  my $txt = "def_name=$name;\n";
    $txt .= "def_desc=$desc;\n";
    $txt .= "def_user=$user;\n";
    $txt .= "def_val=$val;\n";

	my $file = $self->_getFileName();

	open(FOUT,">",$file);
	binmode(FOUT);
	print FOUT $txt;
	close(FOUT);
}






=head1 paste($cgi)

=cut

sub paste {
  my $self = shift;
	my $cgi = shift;
	my ($file,$txt); 

  $file = $self->_getFileName();

	open(FIN,"<",$file);
	binmode(FIN);
	while(<FIN>) {
	  $txt .= $_;
	}
	close(FIN);

  # &id=value;&id2=value2;...
	my @lines = split(";\n",$txt);
	foreach my $line (@lines) {
		$line =~ /^(\w+)=(.+)?$/;
		print STDERR "$line\n";
		my $id = $1;
		my $value = $2;
		# Set CGI Param
		print STDERR "$id -> $value\n";
		$cgi->param(-name=>$id,-value=>$value);
	}
	# Save needs submit to be $lang->string("SAVE");
	# Else it does not do anything
	my $value = $self->archive->lang->string("SAVE");
	$cgi->param(-name=>'submit',-value=>$value);
	$self->save($cgi);
	# delete file after pasting
	unlink $file;

}






# _getFileName
#
# return /tmp/$user-$host.scandef for copy paste
##

sub _getFileName {
  my $self = shift;
  my $file;
	$file = "/tmp/".$self->archive->session->user();
	$file .= "-".$self->archive->session->host().".sqldef";
	return $file;
}







# -----------------------------------------------

=head1 elements($self)

	IN: object (self)
	OUT: pointer to hash

	Returns a pointer to a hash of all definitions to display

=cut

sub elements
  {
    my $self = shift;
    my $archiveO = $self->archive;
    my $langO = $archiveO->lang;
	  my $dbh = $archiveO->db->dbh;

    my (%scanDefs,@list,@attributes);
		@attributes = ("Name");
    my $query = "SELECT Laufnummer,Name FROM parameter ";
    $query .= "WHERE Art = 'SQL' AND Tabelle = 'archiv'";
    my $sth = $dbh->prepare($query);
    $sth->execute;
		my $first=1;
    while (my @row = $sth->fetchrow_array()) {
		  my $def = $row[0];
		  push @list, $def;
      $scanDefs{$def}{'Name'} = $row[1];
			if ($first==1) {
        $scanDefs{$def}{'delete'} = 0;
				$first=0;
			} else {
        $scanDefs{$def}{'delete'} = 1;
			}
			$scanDefs{$def}{'copy'} = 1;
      $scanDefs{$def}{'update'} = 1;
    }
    $scanDefs{'new'} = 1;
		$scanDefs{'paste'} = 1;
    $scanDefs{'attributes'} = \@attributes;
    $scanDefs{'list'} = \@list;
    return \%scanDefs;
  }

# -----------------------------------------------

=head1 delete($self,$cgiO)
	
	IN: object (self)
	    object (CGI.pm)
	OUT: -

	Delete a definition from the database thru APCL

=cut

sub delete
  {
    my $self = shift;
    my $cgiO = shift;
    my $archiveO = $self->archive;
	  my $dbh = $archiveO->db->dbh;
    my $id = $cgiO->param("id");

    if (defined $id) {
		  my $sql = "delete from parameter where Laufnummer=$id";
			$dbh->do($sql);
    }
  }

# -----------------------------------------------

=head1 archive($self)

	IN: object (self)
	OUT: object (Archivista::BL::Archive)

	Return the APCL object

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
# $Log: SQLDefinition.pm,v $
# Revision 1.1.1.1  2008/11/09 09:21:03  upfister
# Copy to sourceforge
#
# Revision 1.2  2007/05/31 14:44:42  rn
# Add copy&paste functionality to WebAdmin in
# ScanDefinition,OCRDefinition and SQLDefinition forms.
#
# Revision 1.1.1.1  2007/02/10 14:15:24  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2006/03/06 09:35:55  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.1  2006/02/24 09:48:09  up
# New form for SQL definitions
#
# Revision 1.3  2006/02/19 17:20:29  up
# No global barcode recognition (scan def. based)
#
# Revision 1.2  2006/01/23 10:36:38  mw
# Einbau einer Combobox für Barcode und für OCR-Definitionen
#
# Revision 1.1  2005/11/29 18:23:48  ms
# Added POD
#
# Revision 1.4  2005/11/24 17:39:30  up
# Bugs from implementation autofields and multiple barcode definitions
#
# Revision 1.3  2005/11/24 04:07:43  up
# Modifications for different barcode definitions
#
# Revision 1.1  2005/07/19 09:14:22  ms
# Initial import for new CVS structure
#
# Revision 1.7  2005/07/12 17:13:01  ms
# Entwicklung an BarcodeProcess
#
# Revision 1.6  2005/06/18 21:24:10  ms
# Bugfix 0.0.0.0 -> localhost
#
# Revision 1.5  2005/06/18 21:18:17  ms
# Bugfix auto-pilot
#
# Revision 1.4  2005/06/17 18:21:56  ms
# Implementation scan from webclient
#
# Revision 1.3  2005/06/15 17:37:56  ms
# Bugfix
#
# Revision 1.2  2005/06/15 15:48:31  ms
# *** empty log message ***
#
# Revision 1.1  2005/06/15 15:48:03  ms
# File added to project
