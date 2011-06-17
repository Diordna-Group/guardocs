# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::DL::Parameter;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::Config;
use Archivista::DL::DB;
use Archivista::Util::IO;

@ISA = qw ( Archivista::DL::DB );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _refreshParam
  {
    my $dbh = shift;
    my $name = shift;
    my $table = shift;
    my $value = shift;

    my $update = 0;
    my ($query);
 
    $query = "SELECT Name FROM parameter WHERE ";
    $query .= "Name = '$name' AND Tabelle = '$table' AND Inhalt = '$value'";
    my $sth = $dbh->prepare($query);
    $sth->execute;

    while (my @row = $sth->fetchrow_array()) {
      $update = 1;
    }
	
    $sth->finish;
	
    if ($update == 1) {
      $query = "UPDATE ";
    } else {
      $query = "INSERT INTO ";
    }
    $query .= "parameter SET ";
    $query .= "Name = '$name', Tabelle = '$table', Inhalt = '$value'";
    $dbh->do($query);
  }

# -----------------------------------------------
# PUBLIC METHODS

sub new
  {
    my $cls = shift;
    my $db = shift;
    my $type = shift;

    my $self = {};

    bless $self, $cls;

    $self->db($db);
    $self->type($type);

    return $self;
  }

# -----------------------------------------------

sub load
  {
    my $cls = shift;
    my $db = shift;
    my $archiveName = shift;
    my $self = {};

    bless $self, $cls;

    my ($do,$exception,$query);
    my $dbh = $db->dbh;

    my $io = Archivista::Util::IO->new;
    my $config = Archivista::Config->new;
    my $cfgdir = $config->get("CONFIG_DIR");
    my $dirsep = $config->get("DIR_SEP");
    my $baseImagePath = $config->get("BASE_IMAGE_PATH");
    my $avversion = $config->get("AV_VERSION");
    my $av5par = $cfgdir.$dirsep."AV5.PAR";

    # Parse the AV5.PAR file (from av5.zzz)
    my $pfileData = $io->read($av5par);
    foreach (split /\r\n/, $$pfileData) {
      # Values are tab separated 
      my ($type,$table,$name,@content) = split /\t/, $_;
      my $content = join "\r\n", @content;
      $query = "INSERT INTO parameter SET ";
      $query .= "Art = ".$dbh->quote($type).",";
      $query .= "Tabelle = ".$dbh->quote($table).",";
      $query .= "Name = ".$dbh->quote($name).",";
      $query .= "Inhalt = ".$dbh->quote($content);
      $do = $dbh->do($query);
      $exception = "Failed to insert parameter ($query)";
      $self->exception($exception,__FILE__,__LINE__) if ($do != 1);
    }

    # Now update the AVVersion value
    $query = "UPDATE parameter SET ";
    $query .= "Inhalt = ".$dbh->quote($avversion)." ";
    $query .= "WHERE Name = ".$dbh->quote("AVVersion");
    $do = $dbh->do($query);
    $exception = "Failed to update parameter AVVersion ($query)";
    $self->exception($exception,__FILE__,__LINE__) if ($do != 1);

    # Insert the input, output screen path
    my $input = $baseImagePath.$dirsep.$archiveName.$dirsep."input";
    _refreshParam($dbh,'PfadGrafikBatchInput','archiv',$input);
    my $output = $baseImagePath.$dirsep.$archiveName.$dirsep."output";
    _refreshParam($dbh,'PfadGrafikBatchOutput','archiv',$output);
    my $screen = $baseImagePath.$dirsep.$archiveName.$dirsep."screen";
    _refreshParam($dbh,'PfadGrafikBatchScreen','archiv',$screen);
  }

# -----------------------------------------------

sub select 
  {
    my $self = shift;
    my $parameter = shift;	# Object of Archivista::BL::Parameter
    my $parameterId = shift;

    my $type = $self->type;

    my $dbh = $self->db->dbh;
    my $query = "SELECT * FROM parameter ";
    $query .= "WHERE Art = '$type' AND Name = ".$dbh->quote($parameterId);
    my $sth = $dbh->prepare($query);
    $sth->execute();

    if ($sth->rows) {
      while (my $hash_ref = $sth->fetchrow_hashref()) {
	foreach my $key (keys %$hash_ref) {
	  my $value = $$hash_ref{$key};
	  $parameter->attribute($key)->value($value,0);
	}
      }
    } else {
      my $exception = "Parameter $parameterId not found ($query)";
      #		$self->exception($exception,__FILE__,__LINE__);
    }

    $sth->finish();
  }

# ---------------------------------------------------------

sub insert
  {
    my $self = shift;
    my $parameter = shift;
    my $attribute = shift;
    my $parameterId = $parameter->id;
    my $dbh = $self->db->dbh;

    my $qArt=$dbh->quote($self->type);
    my $qName=$dbh->quote($parameterId);
    my $qVal=$dbh->quote($parameter->attribute("Inhalt")->value);

    my $query = "INSERT INTO parameter (Art,Tabelle,Name,Inhalt) "; 
    $query.="values ( $qArt, 'parameter', $qName, $qVal)";
    my $do = $dbh->do($query);

    my $exception = "Failed to insert parameter $parameterId ($query)";
    $self->exception($exception,__FILE__,__LINE__) if (! $do);
  }

# -----------------------------------------------

sub update
  {
    my $self = shift;
    my $parameter = shift;	# Object of Archivista::BL::Parameter
    my $attribute = shift;

    if (!$self->exists($parameter)) {

      $self->insert($parameter,$attribute);

    } else {

      my $parameterId = $parameter->id;
      my $archive = $parameter->archive;

      my $type=$self->type;

      my $dbh = $self->db->dbh;
      my $attributesToUpdate = $self->attributesToString($attribute);
      if (length($attributesToUpdate) > 0) {
	my $query = "UPDATE parameter SET $attributesToUpdate ";
	$query .= "WHERE Art = '$type' AND Name = ".$dbh->quote($parameterId);
	my $do = $dbh->do($query);

	my $exception = "Failed to update parameter $parameterId ($query)";
	$self->exception($exception,__FILE__,__LINE__) if (! $do);
      }
    }
  }

# -----------------------------------------------

sub exists 
  {
    my $self = shift;
    my $parameter = shift;
    my $dbh = $self->db->dbh;
    my $parameterId = $parameter->id;

    my $type=$self->type;

    my $exists = 0;
    my $query = "SELECT Name FROM parameter WHERE Art = '$type' AND Name = ".$dbh->quote($parameterId);
    my $sth = $dbh->prepare($query);
    $sth->execute;

    $exists = 1 if ($sth->rows);
	
    $sth->finish;

    return $exists;
  }

# -----------------------------------------------

sub maskDefinitions {
  my $self = shift;
  my $db = shift;
   
  my %definitions;
  my $dbh = $db->dbh;

  $self->maskDefinitionsCheck($db);
  my $query = "SELECT Name,Inhalt FROM parameter WHERE ";
  $query .= "Name LIKE 'FelderObj__'";
  my $sth = $dbh->prepare($query);
  $sth->execute;
  while (my @row = $sth->fetchrow_array()) {
    my ($key,$value) = ($row[0],$row[1]);
    my @fields = split /\r\n/, $value;
    my @values = split /;/, $fields[0];
    $key =~ s/FelderObj//;
    $value = $values[25];	# Felddefinition
    $definitions{$key} = $value;
  }
  $sth->finish;
  return \%definitions;
}






sub maskDefinitionsCheck {
  my $self = shift;
	my $db = shift;
  my $dbh = $db->dbh;
	
	my ($sql,@row,$val);
	# check first, if the first definition is there 
	$sql = "SELECT Name from parameter WHERE Name='FelderObj00' AND " .
	       "Art='FelderObj00' AND Tabelle='archiv'";
  @row = $dbh->selectrow_array($sql);
	if ($row[0] eq "") {
	  # first definition is not there
    $val = "0;0;1200;300;1;0;0;0;0;0;0;8;0;0;0;0;0;" .
	         "MS Sans Serif;;;0;;;;;Input mask1;";
	  $val=$dbh->quote($val);
		$sql = "insert into parameter set Art='FelderObj00'," .
		       "Name='FelderObj00',Tabelle='archiv',Inhalt=$val";
		$dbh->do($sql);
	}
	$sql = "SELECT Name from parameter WHERE Name='FelderTab00' AND " .
	       "Art='FelderTab00' AND Tabelle='archiv'";
  @row = $dbh->selectrow_array($sql);
	if ($row[0] eq "") {
  	my $pfields = $db->userDefinedAttributes();
		$val = "";
		foreach (@$pfields) {
      $val .= "$_;;;;\r\n";
		}
		$val = $dbh->quote($val);
		$sql = "insert into parameter set Art='FelderTab00'," .
		       "Name='FelderTab00',Tabelle='archiv',Inhalt=$val";
		$dbh->do($sql);
	}
}






# -----------------------------------------------

sub maskDefinitionName
  {
    # Getter/Setter method for a mask definition name (ex. Felddefinition 1)
    my $self = shift;
    my $parameter = shift;
    my $maskDefinitionName = shift;
    my $dbh = $self->db->dbh;
    my $parameterId = $parameter->id;

    my ($query,$definition,$sth);
    $query = "SELECT Inhalt FROM parameter WHERE Name = ".
		         $dbh->quote($parameterId);
    $sth = $dbh->prepare($query);
    $sth->execute;

    while (my @row = $sth->fetchrow_array()) {
      $definition = $row[0];
    }

    $sth->finish;
	
    my @definitions = split /\r\n/, $definition;
    my $firstDefinition = shift @definitions;
    my @values = split /;/, $firstDefinition;
	
    if (defined $maskDefinitionName) {
      # Setter method
      $values[25] = $maskDefinitionName.";";
      $firstDefinition = join ";", @values;
      unshift @definitions, $firstDefinition;
      $definition = join "\r\n", @definitions;
      $query = "UPDATE parameter SET Inhalt = ".$dbh->quote($definition)." ";
      $query .= "WHERE Name = ".$dbh->quote($parameterId);
      $dbh->do($query);
    } else {
      # Getter method
      return $values[25];
    }
  }

# -----------------------------------------------

sub maskParentFields
  {
    # Returns all fields by hash (index, field name) which have a type 4 or 5
    # The hash key is like the array index when 'FelderObjXY' is splitted by
    # '\r\n'
    my $self = shift;
    my $parameter = shift;
    my $retDS = shift;	       # Return data structure (ARRAY or HASH)
    my $dbh = $self->db->dbh;
    my $parameterId = $parameter->id;

    $retDS = "HASH" if (! defined $retDS);

    my ($parentFields,@parentFields,%parentFields);
    my $query = "SELECT Inhalt FROM parameter ";
    $query .= "WHERE Tabelle = 'archiv' AND Name = ".$dbh->quote($parameterId);
    my $sth = $dbh->prepare($query);
    $sth->execute;

    while (my @row = $sth->fetchrow_array()) {
      $parentFields = $row[0];
    }
	
    $sth->finish;

    my @definitions = split /\r\n/, $parentFields;
    for (my $idx = 0; $idx <= $#definitions; $idx++) {
      my @values = split /;/, $definitions[$idx];
      if ($values[4] == 0 && ($values[5] == 4 || $values[5] == 5)) {
        if (uc($retDS) eq "HASH") {
	        $parentFields{$idx} = $values[18];
	      } elsif (uc($retDS) eq "ARRAY") {
	        push @parentFields, $idx;
	      }
      }
    }

    if (uc($retDS) eq "HASH") {
      return \%parentFields;
    } elsif (uc($retDS) eq "ARRAY") {
      return \@parentFields;
    }
  }



# -----------------------------------------------

sub userSqlDefinitions
  {
    # POST: Pointer to hash(ID, Name)
    # Return all AVStart sql definitions 
    my $self = shift;
    my $db = shift;
    my $dbh = $db->dbh;

    my %sqlDefinitions;
    my $query = "SELECT Laufnummer, Name FROM parameter ";
    $query .= "WHERE Art = 'SQL' AND Tabelle = 'archiv' AND ";
    $query .= "Inhalt NOT LIKE '%[%'";
    my $sth = $dbh->prepare($query);
    $sth->execute;

    while (my @row = $sth->fetchrow_array()) {
      $sqlDefinitions{$row[0]} = $row[1];
    }
	
    $sth->finish;

    return \%sqlDefinitions;
  }

# -----------------------------------------------

sub delete
  {
    my $self = shift;
    my $parameter = shift;

    my $dbh = $self->db->dbh;
    my $parameterId = $parameter->id;
    my $query = "DELETE FROM parameter WHERE Name = ".$dbh->quote($parameterId);
    my $do = $dbh->do($query);

    my $exception = "Failed to delete parameter $parameterId ($query)";
    $self->exception($exception,__FILE__,__LINE__) if (! $do);
  }

sub type
  {
    my $self = shift;
    my $type = shift;		# Object of Archivista::DL::DB

    if (defined $type) {
      $self->{'type'} = $type;
    } else {
      return $self->{'type'};
    }
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
# $Log: Parameter.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.4  2006/03/06 09:35:55  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.3  2006/01/17 11:02:13  mw
# Verbesserung der Update-Logik
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.19  2005/07/13 15:43:05  ms
# Bugfix: remove print STDERR
#
# Revision 1.18  2005/07/13 13:56:14  ms
# Bugfix Barcodes
#
# Revision 1.17  2005/06/02 18:29:53  ms
# Implementing update for mask definition
#
# Revision 1.16  2005/05/27 16:04:00  ms
# Bugfix
#
# Revision 1.15  2005/05/11 18:22:43  ms
# Changes for mask definition (archive server)
#
# Revision 1.14  2005/05/06 15:43:04  ms
# Bugfix an FieldTab/FieldObj, edit mask definition name, sql definitions for user
#
# Revision 1.13  2005/05/04 16:59:56  ms
# Changes for archive server mask definitions
#
# Revision 1.12  2005/04/29 16:25:26  ms
# Mask definition development
#
# Revision 1.11  2005/04/28 13:15:30  ms
# Implementing alter table module
#
# Revision 1.10  2005/04/21 15:04:30  ms
# *** empty log message ***
#
# Revision 1.9  2005/04/20 16:16:14  ms
# Import new languages modules
#
# Revision 1.8  2005/04/07 17:42:49  ms
# Entwicklung von alter table fuer das hinzufuegen und loeschen von feldern in der
# datenbank
#
# Revision 1.7  2005/04/01 17:52:56  ms
# Weiterentwicklung an FelderTab/FelderObj
#
# Revision 1.6  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.5  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.4  2005/03/21 18:33:20  ms
# Erzeugung neuer archivista datenbanken
#
# Revision 1.3  2005/03/18 15:38:42  ms
# Stabile version um User hinzuzufügen
#
# Revision 1.2  2005/03/17 17:12:59  ms
# Weiterentwicklung Hinzufügen der Parameter-Tabelle
#
# Revision 1.1  2005/03/17 12:00:28  ms
# File added to project
#
