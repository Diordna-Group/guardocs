# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:23 $

package Archivista::DL::DB;

use strict;
use DBI;

use Archivista::Config;
use Archivista::BL::Attribute;
use Archivista::Util::Exception;

use vars qw ( $VERSION );

$VERSION = '$Revision: 1.1.1.1 $';

# -----------------------------------------------
# PRIVATE METHODS

sub _dumpTable
{
  my $config = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
	my $database = shift;
	my $table = shift;
	my $nodata = shift;
	
	my $mysqldump = $config->get("MYSQL_DUMP");
	$mysqldump = "/usr/bin/mysqldump" if !-e $mysqldump; # 64 bit
	my $dirsep = $config->get("DIR_SEP");
  my $tmpdir = $config->get("TEMP_DIR");

  my $dump = $tmpdir.$dirsep.time()."_".$database."_".$table.".sql";
	my $cmd = "$mysqldump $nodata -h $host -u $uid --password=$pwd $database $table > $dump";
	my $system = system($cmd);
	my $exception = "Failed to dump data from $database ($cmd)";
	exception(undef,$exception,__FILE__,__LINE__) if ($system != 0);

  return $dump;
}

# -----------------------------------------------

sub _loadDump
{
  my $config = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
	my $dump = shift;
	my $database = shift;
  my $unlink = shift;
	
  my $mysql = $config->get("MYSQL_BIN");
	$mysql = "/usr/bin/mysql" if !-e $mysql; # 64 bit
	$unlink = 0 if (! defined $unlink);
	
  if (-f $dump) {
    my $cmd = "$mysql -h $host -u $uid --password=$pwd $database < $dump";
    my $exception = "Failed to insert data to database $database ($cmd)"; 
		my $system = system($cmd);
		exception(undef,$exception,__FILE__,__LINE__) if ($system != 0);
  } else {
	  my $exception = "File $dump not found";
	  exception(undef,$exception,__FILE__,__LINE__);
	}

	unlink $dump if ($unlink);
}

# -----------------------------------------------

sub _connect
{
  my $host = shift;
	my $database = shift;
	my $uid = shift;
	my $pwd = shift;

  eval {
    my $dbh = DBI->connect("DBI:mysql:host=$host;database=$database",
	                         $uid,$pwd,{PrintError=>0,RaiseError=>0});
		return $dbh;
	}
}

# -----------------------------------------------

sub _archivistaArchive
{
  my $self = shift;
	my $dbh = shift;
	my $database = shift;
	my $loginDb = shift;
	
  my $config = Archivista::Config->new();
	my $avVersion = $config->get("AV_VERSION");
	
	my $archivistaArchive = 0;
	my ($query,$sth,@tables);

	$dbh->do("USE $database");
	$sth = $dbh->prepare("SHOW TABLES");
	$sth->execute(); 

	while (my @row = $sth->fetchrow_array()) {
		push @tables, $row[0];
	}
		
	foreach my $table (@tables) {
		if ($table eq "parameter") {
			$query = "SELECT Inhalt FROM parameter WHERE Name = 'AVVersion'";
			$sth = $dbh->prepare($query);
			$sth->execute(); 
		
			while (my @row = $sth->fetchrow_array()) {
				if ($avVersion eq $row[0]) {
					$archivistaArchive = 1;
				}
			}
			$sth->finish();
		}
	}

	# Use again the login database
	$dbh->do("USE $loginDb");

	return $archivistaArchive;
}

# -----------------------------------------------
# PUBLIC METHODS

sub new 
{
  my $cls = shift;
	my $database = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;
  my $self = {};
  my $config = Archivista::Config->new();

  my $suHost = $config->get("MYSQL_HOST");
	my $suDb = $config->get("AV_GLOBAL_DB");
	my $suUid = $config->get("MYSQL_UID");
	my $suPwd = $config->get("MYSQL_PWD");
	
	if (! defined $database) {
		$database = $suDb;
	}
	
	if (! defined $host) {
  	$host = $suHost;
		$uid = $suUid;
		$pwd = $suPwd;
	}

  bless $self, $cls;
 
  $self->{'sudbh'} = _connect($suHost,$suDb,$suUid,$suPwd);
	$self->{'dbh'} = _connect($host,$database,$uid,$pwd);
	$self->{'host'} = $host;
	$self->{'database'} = $database;
  $self->{'uid'} = $uid;
	
	if (! defined $self->{'dbh'}) {
		my $exception = "Error on login ($host, $database, $uid, ...)";
		$self->exception($exception,__FILE__,__LINE__);		
	} elsif ($database ne $config->get("AV_GLOBAL_DB")) {
		my $checkIfArchivistaDb = $self->_archivistaArchive($self->dbh,
		                              $self->database,$self->database);
		if ($checkIfArchivistaDb == 0) {
			my $exception = "Not an archivista archive ($database)";
			$self->exception($exception,__FILE__,__LINE__);
		}
	}

	return $self;
}

# -----------------------------------------------

sub create
{
  my $cls = shift;
	my $database = shift;
	my $cpDataFromDb = shift;
	my $host = shift;
	my $uid = shift;
	my $pwd = shift;

  my ($query,$dump,$cmd,$system,$exception);
  my $config = Archivista::Config->new();
  my $avGlobalDb = $config->get("AV_GLOBAL_DB");
	
	if (! defined $host) {
		$host = $config->get("MYSQL_HOST");
		$uid = $config->get("MYSQL_UID");
		$pwd = $config->get("MYSQL_PWD");
	}

  my $mysql = $config->get("MYSQL_BIN");
	$mysql = "/usr/bin/mysql" if !-e $mysql; # 64 bit
	my $dirsep = $config->get("DIR_SEP");
  my $cfgdir = $config->get("CONFIG_DIR");
  my $tmpdir = $config->get("TEMP_DIR");

  my $dbh = _connect($host,$avGlobalDb,$uid,$pwd);
	$query = "CREATE DATABASE $database";

	if ($dbh->do($query)) {
		$dump = $cfgdir.$dirsep."dump".$dirsep."archive.sql";
		_loadDump($config,$host,$uid,$pwd,$dump,$database);
  
		# We must copy users and parameters from another database
		if (defined $cpDataFromDb) {
	  	my $archiveDump = _dumpTable($config,$host,$uid,$pwd,$cpDataFromDb,"archiv","--no-data");
			my $parameterDump = _dumpTable($config,$host,$uid,$pwd,$cpDataFromDb,"parameter",undef);
			my $userDump = _dumpTable($config,$host,$uid,$pwd,$cpDataFromDb,"user",undef);
			_loadDump($config,$host,$uid,$pwd,$archiveDump,$database,1);
	  	_loadDump($config,$host,$uid,$pwd,$parameterDump,$database,1);
			_loadDump($config,$host,$uid,$pwd,$userDump,$database,1);
  	}

		$query = "INSERT INTO archives SET name=".$dbh->quote($database);
		$dbh->do($query);
	} else {
		$exception = "Failed to create database $database ($query)";
		exception(undef,$exception,__FILE__,__LINE__);
	}

	$dbh->disconnect;
}

# -----------------------------------------------

sub drop
{
  my $self = shift;
	my $database = shift;

  my $config = Archivista::Config->new;
  my $dbmaster = $config->get("MYSQL_DB");
  
	if ($database ne $dbmaster) {
  	my $dbh = $self->dbh;
		my $config = Archivista::Config->new;
		my $avGlobalDb = $config->get("AV_GLOBAL_DB");
		my ($query);

  	# Now drop the database
		$query = "USE $avGlobalDb";
		$dbh->do($query);

		$query = "DROP DATABASE $database";

  	if ($dbh->do($query)) {
			$query = "DELETE FROM archives WHERE ";
			$query .= "name = ".$dbh->quote($database);
			$dbh->do($query);
		} else {
			my $exception = "Failed to drop database $database ($query)";
			exception(undef,$exception,__FILE__,__LINE__)
		}
  } else {
		my $exception = "Failed to drop database $dbmaster";
		exception(undef,$exception,__FILE__,__LINE__)
  }
}

# -----------------------------------------------

sub db
{
  my $self = shift;
	my $db = shift; # Object of Archivista::DL::DB

	if (defined $db) {
		$self->{'db'} = $db;
	} else {
		return $self->{'db'};
	}
}

# -----------------------------------------------

sub dbh
{
	my $self = shift;
  my $dbh = shift;

	if (defined $dbh) {
		$self->{'dbh'} = $dbh;
	} else {
		return $self->{'dbh'};
	}
}

# -----------------------------------------------

sub sudbh
{
  my $self = shift;
	
	return $self->{'sudbh'};
}

# -----------------------------------------------

sub host
{
  my $self = shift;

	return $self->{'host'};
}

# -----------------------------------------------

sub database
{
  my $self = shift;

	return $self->{'database'};
}

# -----------------------------------------------

sub uid
{
  my $self = shift;

	return $self->{'uid'};
}

# -----------------------------------------------

sub exception
{
  my $self = shift;
  my $msg = shift;
	my $file = shift;
	my $line = shift;
	
  Archivista::Util::Exception->add($msg,$file,$line);
}

# -----------------------------------------------

sub attributesToString
{
  my $self = shift;
  my $attribute = shift;

  my @attributes;
	my $dbh = $self->db->dbh;

	foreach my $attributeId (keys %{$attribute->all}) {
		$attribute->id($attributeId);
	  my $attributeValue = $attribute->value;
		# If attribute id is password (password cipher for mysql.user table)
		if (lc($attributeId) eq "password") {
			push @attributes, $attributeId." = Password(".$dbh->quote($attributeValue).")";
		} else {
		  push @attributes, $attributeId." = ".$dbh->quote($attributeValue);
		}
	}

	return join ", ", @attributes;
}

# -----------------------------------------------

sub shiftObsoleteAttributes
{
  my $self = shift;
	my $database = shift;
	my $table = shift;
	my $attribute = shift;

  my ($query,$sth);
  my $dbh = $self->db->dbh;
	my $attributeToUpdate = Archivista::BL::Attribute->new;
	
	$self->selectdb($database);

  my $phattributes = $self->db->describe($table);

  foreach my $key (keys %$phattributes) {
	  $attribute->id($key);
		if ($attribute->modified == 1) {
		  $attributeToUpdate->id($key);
		  $attributeToUpdate->value($attribute->value,0);
	  }
	}

  $self->selectdb($self->db->database);

  return $attributeToUpdate;
}

# -----------------------------------------------

sub describe
{
  my $self = shift;
  my $table = shift;
	my $retDS = shift;
	
  my (%attributes,@attributes);
  my $dbh = $self->dbh;
	$retDS = "HASH" if (! defined $retDS);

  my $query = "DESCRIBE $table";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	while (my @row = $sth->fetchrow_array()) {
		if ($retDS eq "HASH") {
			$attributes{$row[0]} = $row[1]; 
		} elsif ($retDS eq "ARRAY") {
			push @attributes, $row[0];
		}
	}

  $sth->finish();
	
	if ($retDS eq "HASH") {
		return \%attributes;
	} elsif ($retDS eq "ARRAY") {
		return \@attributes;
	}
}

# -----------------------------------------------

sub userDefinedAttributes
{
  # PRE: /ARRAY/HASH
  # POST: pointer to array(attributeName) or
	# 			pointer to hash(attributeName,attributeType)
  my $self = shift;
  my $retDS = shift;
	
	$retDS = "ARRAY" if (! defined $retDS);
	
  my $idx = 0;
	my $paattributes = $self->describe("archiv","ARRAY");
  
  # Get the index of the field 'Notiz'
	for (my $i = 0; $i < $#$paattributes; $i++) {
		$idx = $i - 1 if ($$paattributes[$i] eq "Notiz");
	}

 	my @userDefinedAttributes = @$paattributes[4 .. $idx];
 
  if (uc($retDS) eq "ARRAY") {
		return \@userDefinedAttributes;
	} else {
		my %userDefinedAttributes;
		my $phattributes = $self->describe("archiv","HASH");
	  foreach my $udAttribute (@userDefinedAttributes) {
			$userDefinedAttributes{$udAttribute} = $$phattributes{$udAttribute};
		}
		return \%userDefinedAttributes;
	}
}

# -----------------------------------------------

sub showDatabases
{
	my $self = shift;
	
	my @databases;
	my $dbh = $self->db->dbh;

	my $query = "SHOW DATABASES";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	while (my @row = $sth->fetchrow_array()) {
		push @databases, $row[0];
	}

	$sth->finish();

	return \@databases;
}

# -----------------------------------------------

sub showTables
{
  my $self = shift;
  my $database = shift;

	my @tables;
	my $dbh = $self->db->dbh;
	
	$self->selectdb($database) if (defined $database);
	
	my $query = "SHOW TABLES";
  my $sth = $dbh->prepare($query);
  $sth->execute();

	while (my @row = $sth->fetchrow_array()) {
		push @tables, $row[0];
	}

  $sth->finish();
	
	return \@tables;
}

# -----------------------------------------------

sub selectdb
{
  my $self = shift;
	my $database = shift;
	my $config = Archivista::Config->new();
	my $globalDb = $config->get("AV_GLOBAL_DB");

	if ($database ne $globalDb) {
		my $query = "USE $database";
		my $do = $self->db->dbh->do($query);
		my $exception = "Failed to change database to $database ($query)";
		exception($exception,__FILE__,__LINE__) if (! defined $do);
	}
}

# -----------------------------------------------

sub hostIsSlave
{
	my $self = shift;
	my $isSlaveHost = 0;
	my $dbh = $self->sudbh;
	if (defined $dbh) {
	  my $sth = $dbh->prepare("SHOW SLAVE STATUS");
	  $sth->execute();
	  if ($sth->rows) {
		  my @row = $sth->fetchrow_array();
		  $isSlaveHost = 1 if ($row[9] eq 'Yes');
	  }
	  $sth->finish();
    $dbh=$self->{dbh};
		if (defined $dbh) { 
	    my @row = $dbh->selectrow_array("SHOW VARIABLES LIKE 'server%'");
	    $isSlaveHost=1 if $row[1]>1;
		} else { # no connection, so we say it is a slave
      $isSlaveHost=1;
		}
	}
	return $isSlaveHost;
}

# -----------------------------------------------

sub isArchivistaArchive
{
	my $self = shift;
	my $database = shift;
	my $dbh = $self->db->dbh;
	my $loginDb = $self->db->database;
	
	return $self->_archivistaArchive($dbh,$database,$loginDb);
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
# $Log: DB.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:23  upfister
# Copy to sourceforge
#
# Revision 1.5  2008/08/16 20:21:23  up
# No error raising in db session
#
# Revision 1.4  2008/08/15 17:00:59  up
# Error when connection is not ok
#
# Revision 1.3  2007/04/17 22:04:43  up
# Old RichClient dbs did report slave mode (bugfix)
#
# Revision 1.2  2007/02/24 22:44:01  up
# Check for slave in user connection (not only session connection)
#
# Revision 1.1.1.1  2007/02/10 14:15:22  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.5  2005/11/14 12:45:35  ms
# Bugfix: Host check not only for localhost and % but also for 192.168.% or
# 192.% or the exact client IP address
#
# Revision 1.4  2005/11/07 12:26:12  ms
# Update for administration of remote databases
#
# Revision 1.3  2005/10/26 16:50:15  up
# *** empty log message ***
#
# Revision 1.2  2005/10/18 21:31:23  up
# Changes for ArchivistaBox
#
# Revision 1.1  2005/07/19 09:09:03  ms
# Initial import for new CVS structure
#
# Revision 1.19  2005/06/17 18:22:19  ms
# Implementation scan from webclient
#
# Revision 1.18  2005/06/08 16:56:01  ms
# Anpassungen an _exception
#
# Revision 1.17  2005/05/06 15:43:04  ms
# Bugfix an FieldTab/FieldObj, edit mask definition name, sql definitions for user
#
# Revision 1.16  2005/05/04 16:59:56  ms
# Changes for archive server mask definitions
#
# Revision 1.15  2005/04/29 16:25:26  ms
# Mask definition development
#
# Revision 1.14  2005/04/28 16:40:20  ms
# Anpassungen fuer die felder definition (alter table)
#
# Revision 1.13  2005/04/28 14:06:08  ms
# *** empty log message ***
#
# Revision 1.12  2005/04/28 13:15:30  ms
# Implementing alter table module
#
# Revision 1.11  2005/04/22 17:27:48  ms
# Anpassungen für Archivverwaltung
#
# Revision 1.10  2005/04/07 17:42:49  ms
# Entwicklung von alter table fuer das hinzufuegen und loeschen von feldern in der
# datenbank
#
# Revision 1.9  2005/03/31 13:44:26  ms
# Implementierung der copy data from database Funktionalität
#
# Revision 1.8  2005/03/24 14:41:11  ms
# Last version befor easter
#
# Revision 1.7  2005/03/22 18:35:21  ms
# Entwicklung an User mit GRANT auf Tabellen und Attribute
#
# Revision 1.6  2005/03/21 18:33:20  ms
# Erzeugung neuer archivista datenbanken
#
# Revision 1.5  2005/03/18 15:38:42  ms
# Stabile version um User hinzuzufügen
#
# Revision 1.4  2005/03/15 18:39:23  ms
# Entwicklung an mysql.user und archivista.user tabellen
#
# Revision 1.3  2005/03/14 17:29:11  ms
# Weiterentwicklung an APCL: einfuehrung der klassen BL/User sowie Util/Exception
#
# Revision 1.2  2005/03/14 11:46:44  ms
# Erweiterungen auf archivseiten
#
# Revision 1.1.1.1  2005/03/11 14:01:22  ms
# Archivista Perl Class Library Projekt imported
#
# Revision 1.1  2005/03/10 17:59:22  ms
# Files added
#
