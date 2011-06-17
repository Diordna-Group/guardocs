# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:22 $

package Archivista::DL::Archive;

use strict;

use vars qw ( $VERSION @ISA );

use Archivista::DL::DB;
use Archivista::Util::Date;

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

sub all
{
  my $cls = shift;
	my $db = shift;
  my $self = {};
  my $config = Archivista::Config->new;
  my $globalDb = $config->get("AV_GLOBAL_DB");
  my $dbh = $db->dbh;	
	my (@archives);
	
	bless $self, $cls;
 
	$self->db($db);

	my $padatabases = $self->showDatabases();

	foreach my $database (@$padatabases) {
		if ($self->isArchivistaArchive($database) == 1) {
			push @archives, $database;
		}
	}
	
	return \@archives;
}

# -----------------------------------------------

sub select 
{
  my $self = shift;
  my $document = shift;
  my $documentId = shift;
	
	my $dbh = $self->db->dbh;	
	my $query = "SELECT * FROM archiv WHERE Akte = $documentId";
	my $sth = $dbh->prepare($query);
	$sth->execute();

  if ($sth->rows) {
	  while (my $hash_ref = $sth->fetchrow_hashref()) {
		  foreach my $key (keys %$hash_ref) {
		    my $value = $$hash_ref{$key};
			  $document->attribute($key)->value($value,0);
		  }
	  }
  } else {
	  my $exception = "Document $documentId not found ($query)";
		$self->exception($exception,__FILE__,__LINE__);
	}
	
	$sth->finish();
}

# ---------------------------------------------------------

sub insert
{
  my $self = shift;

  my $date = Archivista::Util::Date->new;
  my ($query,$exception,$lastInsertId);
	
  my $dbh = $self->db->dbh;
	$query = "INSERT INTO archiv () VALUES ()";
	my $do = $dbh->do($query);

  $exception = "Failed to insert record ($query)";
	$self->exception($exception,__FILE__,__LINE__) if ($do != 1);

	$query = "SELECT LAST_INSERT_ID()";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	while (my @row = $sth->fetchrow_array()) {
		$lastInsertId = $row[0];
	}

  $sth->finish();
	
  $query = "UPDATE archiv ";
	$query .= "SET Akte = $lastInsertId, ";
	$query .= "Datum = '".$date->actualDate."', ";
	$query .= "Seiten = 0 ";
	$query .= "WHERE Laufnummer = $lastInsertId";
	$do = $dbh->do($query);
  
	$exception = "Failed to update document $lastInsertId ($query)";
	$self->exception($exception,__FILE__,__LINE__) if ($do != 1);
  
	return $lastInsertId;
}

# -----------------------------------------------

sub update
{
  my $self = shift;
	my $documentId = shift;
	my $attribute = shift;
 
	my $dbh = $self->db->dbh;
	my $attributesToUpdate = $self->attributesToString($attribute);	
	if (length($attributesToUpdate) > 0) {
	  my $query = "UPDATE archiv SET $attributesToUpdate ";
	  $query .= "WHERE Akte = $documentId";
	  my $do = $dbh->do($query);

    my $exception = "Failed to update document $documentId ($query)";
	  $self->exception($exception,__FILE__,__LINE__) if ($do != 1);
  }
}

# -----------------------------------------------

sub alter
{
  my $self = shift;
	my $db = shift;
	# Pointer to array of fields
	# $i (array index) -> number of alter queries to execute
	# $$palter[$i]{'attribute_name'}
	# $$palter[$i]{'attribute_type'} -> mysql data type: varchar, int, etc
	# $$palter[$i]{'attribute_length'} -> ie 255: varchar(255)
	# $$palter[$i]{'attribute_length'} -> for varchar, int
	# $$palter[$i]{'alter_type'} -> ADD or DROP
	# $$palter[$i]{'after_attribute'} -> add new attribute after this
	my $palter = shift;
	my $dbh = $db->dbh;
	my ($query);

  for (my $idx = 0; $idx <= $#$palter; $idx++) {
		my $alterType = $$palter[$idx]{'alter_type'};
		my $attributeName = $$palter[$idx]{'attribute_name'};
		my $afterAttribute = $$palter[$idx]{'after_attribute'};
		my $oldAttributeName = $$palter[$idx]{'attribute_old_name'};
		my $attributeType = $self->attributeDbType(
		  $$palter[$idx]{'attribute_type'},
			$$palter[$idx]{'attribute_length'});

		if (uc($alterType) eq "ADD") {
			# ADD new attribute
			$query = "ALTER TABLE archiv ";
			$query .= "ADD COLUMN $attributeName $attributeType ";
			$query .= "AFTER $afterAttribute";
		} elsif (uc($alterType) eq "DROP") {
			
			# DROP existing attribute
			$query = "ALTER TABLE archiv DROP COLUMN $attributeName";
		} elsif (uc($alterType) eq "CHANGE") {
			# CHANGE existing attribute
			$query = "ALTER TABLE archiv ";
			$query .= "CHANGE $oldAttributeName $attributeName $attributeType ";
			$query .= "AFTER $afterAttribute";
		}
		my $do = $dbh->do($query);
		my $exception = "Error on alter table ($query)";

		if (! $do) {
		  $self->exception($exception,__FILE__,__LINE__);
    } else {
			# adjust table entries (comp. RichClient)
		  _alterFix($self,$db,$palter,$idx); 
		}
	}
}






sub _alterFix {
  my $self = shift;
	my $db = shift;
	my $palter = shift;
	my $idx = shift;
	my $dbh = $db->dbh;

	my $fname = $$palter[$idx]{'attribute_name'};
	my $fnew = $$palter[$idx]{'attribute_old_name'};
	my $fact = uc($$palter[$idx]{'alter_type'}); # ADD,DROP,CHANGE
	
  # read all FelderTabXX definitions in a hash
  my %tab = _alterFixGetDefinitions($dbh,"Tab");
	
	# get all fields that are available
  my @fldsok = _alterFixGetFields($dbh);
  my ($nr);
		
	# go through every FelderTabXX deinition
	foreach (keys %tab) {
	  $nr = $_;
    _alterFixCheckFields($self,$dbh,$fact,$nr,$fname,$fnew,\%tab,\@fldsok);
	}

  # create at least one def if there was no FelderTabXX entry
	_alterFixFirstTab($self,$dbh,$fact,$fname,$fnew) if $nr==0;

  # read all FelderObjXX definitions in a hash
  %tab = _alterFixGetDefinitions($dbh,"Obj");
	
	foreach (keys %tab) {
	  # check in every object if the fields still do exist
	  _alterFixCheckObjects($self,$dbh,$_,\%tab,\@fldsok);
  }
}






sub _alterFixCheckObjects {
  my $self = shift;
	my $dbh = shift;
	my $nr = shift;
  my $ptab = shift;
	my $pfldsok = shift;

	my ($l1,$gef,@atr,$count,$tout,$mname);
	my $val = $$ptab{$nr};
  $mname = "Input mask1";
	
	my @v1 = split("\r\n",$val);
	foreach (@v1) {
	  $l1 = $_;
		$gef = 0;
		@atr = split(";",$l1);
		my $mname = $atr[25] if $atr[25] ne "";
		if ($atr[4]==0) {
		  # we have a field
			foreach (@$pfldsok) {
        $gef=1 if $_ eq $atr[18];
			}
		} else {
		  $gef=1;
		}
	  if ($gef==1) {
	    $atr[25]=$mname if ($count==0);
	    $l1 = join(";",@atr);
	    $tout .= $l1.";\r\n";
			$count++;
	  }
	}
	if ($tout eq "") {
    $tout = "0;0;1200;300;1;0;0;0;0;0;0;8;0;0;0;0;0;" .
	          "MS Sans Serif;;;0;;;;;$mname;";
	}
  _alterFixUpdate($self,$dbh,$tout,$nr);
}






sub _alterFixGetDefinitions {
  my $dbh = shift;
	my $typ = shift;
	
	my (@row,%tab,$sql,$st);
	$sql = "select Laufnummer,Inhalt from parameter " .
	       "where Name like 'Felder$typ%' AND " .
				 "Art like 'Felder$typ%' order by Name";
	$st = $dbh->prepare($sql);
	$st->execute;
	while (@row=$st->fetchrow_array) {
	  $tab{$row[0]}=$row[1];
	}
	return %tab;
}






sub _alterFixFirstTab {
  my $self = shift; 
  my $dbh = shift;
	my $fact = shift;
	my $fname = shift;
	my $fnew = shift;

  my $sql;
	if ($fact eq "ADD") {
    $sql="$fname;;;;";
	} elsif ($fact eq "DROP") {
    $sql="";
	} elsif ($fact eq "CHANGE") {
    $sql="$fnew;;;;";
	}
	$sql = "insert into parameter set Art='FelderTab00'," .
	       "Tabelle='archiv',Name='FelderTab00'," .
				 "Inhalt=".$dbh->quote($sql);
	my $do = $dbh->do($sql);
	my $exception = "Error on alter table ($sql)";
	$self->exception($exception,__FILE__,__LINE__) if (! $do);
}






sub _alterFixGetFields {
  my $dbh = shift;
  # MOD 25.03.2006 -> up -> better check for fields
  # additional check about fields (all fields need an entry)
  my $sql = "describe archiv";
	my $sth = $dbh->prepare($sql);
	my (@fldsok);
	$sth->execute();
	while (my @row=$sth->fetchrow_array()) {
	  push @fldsok,$row[0];
	}
	return @fldsok;
}






sub _alterFixCheckFields {
  my $self = shift;
	my $dbh = shift;
	my $fact = shift;
	my $nr = shift;
	my $fname = shift;
	my $fnew = shift;
	my $ptab = shift;
  my $pfldsok = shift;

  # first adjust the FelderTabXX definition (add,drop,change line)
  my ($t,$tres,$tout,$field,$cstart,$cend,$c);

  # get start and end positions of fields
	foreach (@$pfldsok) {
	  $field = $_;
		$cstart = $c+1 if ($field eq "Seiten");
		$cend = $c-1 if ($field eq "Notiz");
		$c++;
	}

	$t = $$ptab{$nr};
	for ($c=$cstart;$c<=$cend;$c++) {
	  $field = $$pfldsok[$c];
    # now check all fields, if it is ok
	  $tres = "";
    my @t1 = split("\r\n",$t);
	  foreach (@t1) {
      my $t2 = $_;
	    my $t3 = $t2;
	    $t3 =~ s/^(.*?)(;)(.*)$/$1/;
	    $tres = $t2 if $field eq $t3;
	  }
	  $tres="$field;;;;" if $tres eq "";
    $tout.=$tres."\r\n";
	}
  _alterFixUpdate($self,$dbh,$tout,$nr);
}






sub _alterFixUpdate {
  my $self = shift;
	my $dbh = shift;
	my $tout = shift;
	my $nr = shift;
	$tout = "$tout"; # fix if we have an empty value
	my $sql = "update parameter set Inhalt=".$dbh->quote($tout)." ".
	          "where Laufnummer=$nr";
	my $do = $dbh->do($sql);
	my $exception = "Error on alter table ($sql)";
	$self->exception($exception,__FILE__,__LINE__) if (! $do);
}






# -----------------------------------------------

sub attributeDbType
{
  my $self = shift;
	my $attributeType = shift;
	my $attributeLength = shift;
	
	my $attributeDbType;

	if (lc($attributeType) eq "varchar") {
	  if ($attributeLength > 0) {
			$attributeDbType = "VARCHAR($attributeLength)";
		} else {
			$attributeDbType = "VARCHAR(255)";
		}
	} elsif (lc($attributeType) eq "int") {
	  if ($attributeLength > 0) {
			$attributeDbType = "INT($attributeLength)";
		} else {
			$attributeDbType = "INT(11)";
		}
	} elsif (lc($attributeType) eq "double") {
		$attributeDbType = "DOUBLE";
	} elsif (lc($attributeType) eq "datetime") {
		$attributeDbType = "DATETIME";
	} elsif (lc($attributeType) eq "tinyint") {
		$attributeDbType = "TINYINT(1)";
	}

	return $attributeDbType;
}






# -----------------------------------------------

sub delete
{
  my $self = shift;
	my $documentId = shift;

	my $dbh = $self->db->dbh;
	my $query = "DELETE FROM archiv WHERE Akte = $documentId";
	my $do = $dbh->do($query);

  my $exception = "Failed to delete document $documentId ($query)";
	$self->exception($exception,__FILE__,__LINE__) if ($do != 1);
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
# $Log: Archive.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:22  upfister
# Copy to sourceforge
#
# Revision 1.2  2007/04/07 01:51:07  up
# Don't loose the labes in table definitions after killing a field
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.5  2006/03/27 10:26:18  up
# Mask definition again, rotation b/w images, barcode recognition (multiple
# barcodes)
#
# Revision 1.4  2006/03/14 06:42:52  up
# Bug mask definition (if fields can't be added)
#
# Revision 1.3  2006/03/06 09:35:55  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.2  2005/11/07 12:26:12  ms
# Update for administration of remote databases
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.13  2005/07/13 14:03:53  ms
# Bugfix: add datum attribute when adding a new document
#
# Revision 1.12  2005/04/29 16:25:26  ms
# Mask definition development
#
# Revision 1.11  2005/04/28 16:40:20  ms
# Anpassungen fuer die felder definition (alter table)
#
# Revision 1.10  2005/04/28 13:15:30  ms
# Implementing alter table module
#
# Revision 1.9  2005/04/22 17:27:48  ms
# Anpassungen für Archivverwaltung
#
# Revision 1.8  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.7  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.6  2005/03/18 15:38:42  ms
# Stabile version um User hinzuzufügen
#
# Revision 1.5  2005/03/15 18:39:22  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.4  2005/03/14 17:29:11  ms
# Weiterentwicklung an APCL: einfuehrung der klassen BL/User sowie Util/Exception
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
# Revision 1.2  2005/03/11 11:05:40  ms
# Added delete method to DL/Archive.pm
#
# Revision 1.1  2005/03/10 17:59:22  ms
# Files added
#
