#!/usr/bin/perl

=head1 General

 This Programm is called from sane-daemon.pl
 It creates a new database from the given SQL-String (jobs_data)
 with one User (also given).

=cut


use strict;
use DBI;
use Archivista::Config; # is needed for the passwords and other settings
use Archivista;

my $jid = shift;

my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pwd = $config->get("MYSQL_PWD");
undef $config;

my $dns = "DBI:mysql:host=$host;database=$db;";
my $dbh = DBI->connect($dns,$user,$pwd);

my $pinfos = getInfosFromJobs($dbh,$jid);
my $pinfosdata = getInfosFromJobsData($dbh,$jid);

if ( checkInfos($jid,$pinfos,$pinfosdata) ) {
  # We have all data that we need.
	my $database = $pinfosdata->{'EXPORT_DB'}->{'value'};
	my $sqlquery = $pinfosdata->{'EXPORT_SQL'}->{'value'};
	my $maxexport = $pinfosdata->{'EXPORT_MAX'}->{'value'};
	my $exportuser = $pinfosdata->{'EXPORT_USER'}->{'value'};
	my $dbshape = $pinfos->{$jid}->{'db'};
	# Host is allways localhost. Because sane-daemon.pl check only the localhost
	# Jobs. So it is not possible for anything else.
  createNewDatabase($dbh,$database,$dbshape,$host,$user,$pwd);
  insertDataFromSQL($dbh,$database,$dbshape,$sqlquery,$maxexport);
  deleteAllUser($dbh,$database,$exportuser);
	my $sql = "update archivista.jobs set status=120 where id=$jid";
	$dbh->do($sql);
} else {
  # Bash uses != 0 for errors.
  # 1=> Missing Data
  return 1;
}






=head2 deleteAllUser

Delete all User from database except from the given User.

=cut

sub deleteAllUser {
  my $dbh = shift;
	my $database = shift;
	my $user = shift;
	my $sql = "delete from $database.user where " .
	          "User !=".$dbh->quote($user). " and ".
						"User !=".$dbh->quote("SYSOP");
	$dbh->do($sql);
}






=head2 createNewDatabase

Create a new Database.

=cut

sub createNewDatabase {
  my $dbh = shift;
  my $database = shift;
  my $dbshape = shift;
  my $host = shift;
  my $user = shift;
  my $password = shift;

	# Use Archivista.pm to create the new Database
  Archivista->create($database,$dbshape,$host,$user,$password);
}






=head2 insertDataFromSQL

Insert the archive-data from the old table to the new one.

=cut

sub insertDataFromSQL {
  my $dbh = shift;
  my $databasename = shift;
	my $dbshape = shift;
  my $sqlquery = shift;
  my $maxexport = shift;

	my @tables = ('archiv','archivseiten','archivbilder',
	              'feldlisten','abkuerzungen');
								
  my $sql = "select Inhalt from $dbshape.parameter where Art = " .
            "'parameter' AND Tabelle='parameter' and Name='ArchivExtended'";
  my @row = $dbh->selectrow_array($sql);
  my $archivfolders = $row[0];
	
	if ($archivfolders>0) {
		$sql = "drop table $databasename.archivbilder";
		$dbh->do($sql);
		createTable($dbh,$databasename,"archivbilder");
		$sql = "alter table $databasename.archivbilder modify Bild longblob";
		$dbh->do($sql);
		$sql = "alter table $databasename.archivbilder modify BildA longblob";
		$dbh->do($sql);
	}
	
  foreach my $table (@tables) {
	  my $sqlstring;
	  if ( $table eq 'archiv') {
		  # SQLString = Query that is executed later in the code
			# SQLQuery = Query that we got from the User
      $sqlstring = $sqlquery;
      my $sql = createInsertSelectString($databasename,$dbshape,
			                                   $table,$table,
		                                     $sqlstring,$maxexport);
  		$dbh->do($sql);
		} elsif ($table eq 'feldlisten' || $table eq 'abkuerzungen') {
      $sqlstring = "select * from $dbshape.$table";
      my $sql = createInsertSelectString($databasename,$dbshape,
			                                   $table,$table,
		                                     $sqlstring);
  		$dbh->do($sql);
		} else {
		  # The default SQL-String does not match for this table.
			my $ids = getIDSFromTable($dbh,$databasename);
			foreach my $id (@$ids) {
			  my $table1 = $table;
			  my $x = $id*1000;
				my $y = ($id+1)*1000;
      	my $sql1 = "select Ordner,Archiviert from $dbshape.archiv ".
				           "where Laufnummer=$id";
	      my ($ordner,$archiviert) = $dbh->selectrow_array($sql1);
	      $table1 = getBlobTable($dbh,$ordner,$archiviert,
				                       $table1,$archivfolders,$dbshape);
			  my $sqlstring = "select * from $dbshape.$table1 "
				              . "where Seite between $x and $y";
				# No LIMIT when we want to copy Pages,Images
				my $only="";
				if ($table eq "archivbilder") {
				  my $only2 = "Seite,Bild,BildA,BildInput,Quelle";
				  $only = "($only2)";
			    $sqlstring = "select $only2 from $dbshape.$table1 "
				              ."where Seite between $x and $y";
				}
				# No LIMIT when we want to copy Pages,Images
			  my $sql = createInsertSelectString($databasename,$dbshape,
				                                   $table,$table1,
		                                       $sqlstring,$maxexport,$only);
				logit($sql);
				$dbh->do($sql);
			}
			my $sql1 = "update $databasename.parameter set Inhalt='0' where ".
			          "Name='ArchivExtended' and ".
								"Art='parameter' and Tabelle='parameter'";
			logit($sql1);
			$dbh->do($sql1);
		}
	}
}






=head2 createTable($dbh,$databasename,$table)

Create the extended tables

=cut

sub createTable {
  my ($dbh,$databasename,$table) = @_;
  my $sql = "create table $databasename.$table (".
         "Seite bigint not null default 0 primary key,".
		     "Bild longblob, BildA longblob, ".
			   "BildInput longblob, Quelle longblob, ".
				 "BildX int not null default 0, BildY int not null default 0, ".
				 "BildAX int not null default 0, BildAY int not null default 0, ".
				 "DatumA datetime) ".
		  	 "TYPE=MyISAM MAX_ROWS=10000000 AVG_ROW_LENGTH=200000";
	$dbh->do($sql);
}






=head2 getIDSFromTable

=cut

sub getIDSFromTable {
  my $dbh = shift;
	my $database = shift;
	my @result;
	my $sql = "select Laufnummer from $database.archiv";

	my $plist = $dbh->selectcol_arrayref($sql);

	return $plist;
}






=head2 createInsertSelectString

=cut

sub createInsertSelectString {
  my $databasename = shift;
	my $dbshape = shift;
  my $table = shift;
	my $table1 = shift;
  my $sqlstring = shift;
  my $maxexport = shift;
	my $only = shift;
	my $field="";

  if ( $sqlstring =~ /limit/ ) {
    # We have a limit in the SQL-String remove it.
    $sqlstring =~ s/^(.+)(limit\s\d+)$/$1/i;
  }

  # We have to modify the fieldlist 'cause we need all information
	# unless the String Starts wit "select *" than we have it allready
	if ($table ne "archivbilder") {
	  unless ( $sqlstring =~ /^select \*/) {
	    # ' from ' with space at the beginning and the end because it could happen
		  # that someone calls a field from not so plausible but just to be on the
		  # safe side.
	    $sqlstring =~ s/^select .+ from /select $dbshape.$table1.* from /;
	  }
	}

	my $sql = "insert into $databasename.$table $only $sqlstring ";
	$sql .= "limit $maxexport" if ($maxexport);
	logit($sql);

	return $sql;
}






=head2 checkInfos($jid,\%infos,\%infosdata)

Check if all required information are present

=cut

sub checkInfos {
  my $jid = shift;
  my $pinfos = shift;
  my $pinfosdata = shift;
  my @reqjobs = ('host','db','user');
  my @reqjobsdata = ('EXPORT_DB','EXPORT_MAX','EXPORT_USER','EXPORT_SQL');
  foreach my $req (@reqjobs) {
    if ( ! check($pinfos,$jid,$req) ) {
      return 0;
    }
  }
  foreach my $req (@reqjobsdata) {
    if ( ! check($pinfosdata,$req,'value') ) {
      return 0;
    }
  }
  return 1;
}






=head2 1/0=check($data,$key,$check)

Check if the Hash is not Empty.

=cut

sub check {
  my $data = shift;
  my $key = shift;
  my $check = shift;

  if ($data->{$key}->{$check} ne "") {
    return 1;
  } else {
    return 0;
  }
}






=head2 getInfosFromJobs($dbh,$jid)

Get All Infos From Jobs with the given job_id.

=cut

sub getInfosFromJobs {
  my $dbh = shift;
  my $jid = shift;

  my @fields = ('id','host','db','user','pwd');
  my $table = 'jobs';
  my $where = 'id='.$dbh->quote($jid);

  my $result = getSQLSelect($dbh,$table,\@fields,$where);

  return $result;
}






=head2 \%result = getInfosFromJobsData($dbh,$jid)

Get All Infos From jobs_data with the given job_id.

=cut

sub getInfosFromJobsData {
  my $dbh = shift;
  my $jid = shift;

  my @fields = ('param','value');
  my $table = 'jobs_data';
  my $where = 'jid='.$dbh->quote($jid);

  my $result = getSQLSelect($dbh,$table,\@fields,$where);

  return $result;
}






=head1 %result=getSQLSelect($dbh,$table,\@fields,$where);

Execute a SQL-String and return a POINTER to a HASH.

=cut

sub getSQLSelect  {
  my $dbh = shift;
  my $table = shift;
  my $pfields = shift;
  my $where = shift;
  my $key = $pfields->[0]; # First Element is allways the Key for the Hash

  my $sql = "select ".join(',',@$pfields)." "
          . "from $table "
          . "where $where";

  my $result = $dbh->selectall_hashref($sql,$key);

  return $result;
}






=head2 logit($message)

Writes a message to a log file

=cut

sub logit {
  my $stamp  = TimeStamp();
  my $message = shift;
  # $log file name comes from outside
  open( FOUT, ">>/home/data/archivista/av.log" );
  binmode(FOUT);
  my $logtext = $0 . " " . $stamp . " " . $message . "\n";
  print FOUT $logtext;
  close(FOUT);
}






=head2 $stamp=TimeStamp 

Actual date/time stamp (20040323130556)

=cut

sub TimeStamp {
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y = $t[5] + 1900;
  $m = $t[4] + 1;
  $m = sprintf( "%02d", $m );
  $d = sprintf( "%02d", $t[3] );
  $h = sprintf( "%02d", $t[2] );
  $mi = sprintf( "%02d", $t[1] );
  $s = sprintf( "%02d", $t[0] );
  $stamp = $y . $m . $d . $h . $mi . $s;
  return $stamp;
}






=head1 $pblob=getBlobTable($dbh,$ordner,$arch,$tbl,$archfolders)

Give back the correct table name for blob table archivbilder

=cut

sub getBlobTable {
  my $dbh = shift;
	my $ordner = shift;
	my $archiviert = shift;
	my $table = shift;
	my $archivfolders = shift;
	my $dbshape = shift;
	$table = "archivbilder" if $table ne "archivseiten";
	if ($archivfolders eq "") {
    my $sql = "select Inhalt from $dbshape.parameter where Art = " .
           "'parameter' AND Name='ArchivExtended'";
    my @row = $dbh->selectrow_array($sql);
		$archivfolders = $row[0];
	}
	if ($archiviert==1 && $archivfolders>0 && $table eq "archivbilder") {
	  my $nr = int(($ordner-1)/$archivfolders);
		$nr = $nr * $archivfolders;
		$table = "archimg".sprintf("%05d",$nr);
	}
	return $table;
}


