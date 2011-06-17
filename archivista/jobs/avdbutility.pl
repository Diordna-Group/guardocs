#!/usr/bin/perl

=head1 avdbutility.pl, (c) 5.9.2005 by Archivista GmbH, Urs Pfister

Skript does set a new password or unlock documents in a archivista database.
The script expects mode and val from command line (val2 is optional)

mode = setpw: set a new password, 
mode = unlock: unlock document(s)
check = check db for updates

val = new password (setpw) or doc range (unlock)

=cut

use strict;
use DBI;
use Archivista::Config; # only needed for connection


# static variables 
my $log = '/home/data/archivista/av.log';
my $path = "/home/data/archivista/expo/";
my $file = "export.av5";

# get everything from the command line
my ($mode,$val,$val2,$val3,$val4,$val5) = @ARGV;

# error handling
my $error = 1;

my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pw = $config->get("MYSQL_PWD");
undef $config;
if ($val3 ne "") { 
  # Unlock documents on any ArchivistaBox (not only localhost)
  $host = $val2;
	$db = $val3;
	$user = $val4;
	$pw = $val5;
}

die if $mode eq "";

# even if we have no password to connect, we need a value
$pw = "" if $pw eq "''";
my $dbh=dbconnect($host,$db,$user,$pw);
if ($dbh) {
	if (HostIsSlave($dbh)==0) {
    if ($mode eq "unlock") {
      unlock($dbh,$val) if $mode eq "unlock";
		} else {
      if (checkdb($dbh)) {
			  if ($mode eq "setpw") {
          $val = "SYSOP" if $val eq "archivista";
          newpw($dbh,$host,$val,$val2);
				} else {
		      check($dbh,$host,$db,$user,$pw);
				}
			}
		}
  } else {
	  backuplog();
	}
  dbclose($dbh);
	exit 0;
} else {
  exit $error;
}






=head1 backuplog

Create a symlink if we are in slave mode or update it

=cut

sub backuplog {
  my $logfile = "/home/data/archivista/backup.log";
	my $path = "/var/opt/apache/lib/htdocs";
	my $link = "$path/backup.txt";
	if (-e $logfile) {
	  if (-e $path) {
		  system("ln -s $logfile $link") if !-e $link;
		} else {
		  $path = "/usr/share/pve-manager/root";
	    $link = "$path/backup.txt";
			if (-e $path) {
		    system("ln -s $logfile $link") if !-e $link;
			}
		}
	}
}






=head1 $string=timestamp()
  
gives back an actual date/time stamp (20040323130556)

=cut

sub timestamp {
  my @t=localtime(time());
  my ($stamp,$y,$m,$d,$h,$mi,$s);
  $y=$t[5]+1900;
  $m=$t[4]+1;
  $m=sprintf("%02d",$m);
  $d=sprintf("%02d",$t[3]);
  $h=sprintf("%02d",$t[2]);
  $mi=sprintf("%02d",$t[1]);
  $s=sprintf("%02d",$t[0]);
  $stamp=$y.$m.$d.$h.$mi.$s;
  return $stamp;
}






=head1 logmessage($message)
  
writes a message to a log file

=cut

sub logmessage {
  my $stamp = timestamp();
  my $message = shift;
  # $log file name comes from outside
  open(FOUT,">>$log");
  binmode(FOUT);
  my $logtext = $0 ." " . $stamp . " " . $message . "\n";
  print FOUT $logtext;
  close(FOUT);
}






=head1 $dbh=dbconnect($host,$db,$user,$pw)
  
connect to a database

=cut

sub dbconnect {
  my $host = shift;
  my $db = shift;
  my $user = shift;
  my $pw = shift;
  my $message;
  my $dsn="DBI:mysql:database=$db;host=$host";
  my $dbh = DBI->connect($dsn,$user,$pw,{PrintError=>1,RaiseError=>0});
  if ($dbh) {
    $message = "Connection ok: $host, $db, $user";
    logmessage($message);
  } else {
    $message = "No connection: $host, $db, $user";
    logmessage($message);
		exit $error;
  }
  return $dbh;
}






=head1 $slave=HostIsSlave($dbh)

gives back a 1 if we are in slave mode (user session)

=cut

sub HostIsSlave {
  my $dbh = shift;
  my $hostIsSlave = 0;
  my @row = $dbh->selectrow_array("SHOW VARIABLES LIKE 'server%'");
  $hostIsSlave=1 if $row[1]>1;
  return $hostIsSlave;
}






=head1 dbclose($dbh)

close a database handle

=cut

sub dbclose {
  my $dbh = shift;
  $dbh->disconnect;
  my $message = "Connection closed";
  logmessage($message);
}






=head1 $ver=checkdb($dbh,$sql)

does a check if it is an archivista database 
(gives back the version)

=cut

sub checkdb {
  my $dbh = shift;
  my $message;
  my $sql = "select Inhalt from parameter where Name like 'AVVersion%'";
  my @res = $dbh->selectrow_array($sql);
  if ($res[0]>= 520) {
    $message = "Archivista database found";
  } else {
    $message = "Sorry, no archivista database";
		exit $error;
  }
  logmessage($message);
  AVSyncTableFields($dbh);
	MySQL5Check($dbh);
	backuplog();
	my $tmp = '/home/data/archivista/tmp';
	if (!-e $tmp) {
	  mkdir $tmp;
	  my $cmd2 = "chmod a+rwx $tmp";
		system($cmd2);
  }
	system("/usr/bin/perl /home/archivista/access_menu.pl");
	eval {
	  my $log = "/home/data/archivista/apcl.log";
		if (!-e $log) {
	    system("touch $log");
	    if (-e "/usr/bin/soffice") {
			  system("chown root.www-data $log");
			} else {
			  system("chown root.http $log");
			}
			system("chmod g+w $log");
		}
	};
  return $res[0];
}



=head1 MySQLCheck($dbh)

Adjust the Create_user_priv for mysql5 users

=cut

sub MySQL5Check {
  my ($dbh) = @_;
	my $sql = "select version()";
	my @row = $dbh->selectrow_array($sql);
	my $vers = $row[0];
	my $vers1 = int $vers;
	if ($vers1>=5) {
	  $sql = "select Create_user_priv from mysql.user ".
		       "where User='SYSOP' and Host='localhost'";
		@row = $dbh->selectrow_array($sql);
		my $rights = uc($row[0]);
		if ($rights ne "Y") {
		  print "upgrade for mysql5 is needed\n";
			my @dbs = ("archivista");
      $sql = "select name from archivista.archives";
			my $prow = $dbh->selectall_arrayref($sql);
			foreach (@$prow) {
			  my $db = $$_[0];
        push @dbs,$db;
			}
      foreach my $db1 (@dbs) {
			  print "checking $db1 for upgrade to mysql5\n";
			  $sql = "select User,Host from $db1.user where Level=255";
			  $prow = $dbh->selectall_arrayref($sql);
			  foreach (@$prow) {
					my $user = $$_[0];
					my $host = $$_[1];
					print "upgrading $user\@$host for mysql5 create_user_priv\n";
          $sql = "update mysql.user set Create_user_priv='Y' where ".
						  "user=".$dbh->quote($user)." and host=".$dbh->quote($host);
					$dbh->do($sql);
				}
				$sql = "flush privileges";
				$dbh->do($sql);
			}
		}
	}
}



=head1 AVSyncTableFields

This method syncronizes attributes of tables in order to run the application
correctly. The method is executed from Session.pm on each login to make sure
that the tables are ok.
	
=cut

sub AVSyncTableFields {
	# Check, add/delete attributes to run this application properly
	my $dbh = shift;
	# Required attributes for job table
	my @jobs = qw(id job host db user pwd timemod timeadd status error);
  my %jobs = ("pwd" => "varchar(16)");	
	# Retrieve jobs attributes
	my $pajobsAttributes = _getTableAttributes($dbh,"jobs");
 	_syncTables($dbh,"jobs",\@jobs,\%jobs,$pajobsAttributes);

	# Required attributes for logs table (here we need all (also the
	# new fields)
	my @logs = qw (file path type date host db user pwd );
	push @logs, qw (idstart formrec owner);
	push @logs, qw (papersize pages width height resx resy bits format);
	push @logs, qw (Laufnummer TIME DONE ERROR ID);

	# here we say what fields we will add if they are not yet here
	my %logs = ("host"=>"varchar(64)", 
	            "user"=>"varchar(16)",
							"pwd"=>"varchar(64)",
							"idstart"=>"int",
							"formrec"=>"int");

	# Retrieve logs attributes
	$pajobsAttributes = _getTableAttributes($dbh,"logs");
 	_syncTables($dbh,"logs",\@logs,\%logs,$pajobsAttributes);

  addIndexes($dbh,"logs"); # add indexes for logs table
  # create session table for new archivista web applications
	system("/usr/bin/perl /home/cvs/archivista/jobs/sessionsinit.pl recreate");
  checkAccessTable($dbh); # add table access	
  addIndexes($dbh,"access"); # add indexes for access table

	# check for text field in jobs_data table
  my $sql = "describe jobs_data value";
	my @row = $dbh->selectrow_array($sql);
	if ($row[1] ne "text") {
	   logmessage("jobs_data modified");
     $sql = "alter table jobs_data modify value text";
		 $dbh->do($sql);
	}
	checkSessionweb($dbh); # check if sessionweb table is up to date
	checkLanguages($dbh,"fr","en"); # check if languages table is up to date
	checkLanguages($dbh,"it","fr"); # check if languages table is up to date
}






=head1 checkSessionweb 

Check if sessionweb is up to date

=cut

sub checkSessionweb {
  my ($dbh) = @_;
  # we need about 128 chars
	my $sql = "describe sessionweb pwd";
	my @row = $dbh->selectrow_array($sql);
	my $lang = $row[1];
	$lang =~ /([0-9])/;
	my $lang1 = $1;
	if ($lang1 < 128) {
	  $sql = "alter table sessionweb modify pwd char(128)";
	  $dbh->do($sql);
	  $sql = "alter table sessionweb modify host char(64)";
	  $dbh->do($sql);
	  $sql = "alter table sessionweb modify db char(64)";
	  $dbh->do($sql);
	}
}






=head1 checkLanguages 

Check if language table is up to date

=cut

sub checkLanguages {
  my ($dbh,$lang,$langpre) = @_;
  # we need about 128 chars
	my $sql = "describe languages $lang";
	my @row = $dbh->selectrow_array($sql);
	if ($row[0] eq "") {
	  $sql = "alter table languages add $lang varchar(255) after $langpre";
	  $dbh->do($sql);
	}
}






=head1 addIndexs($dbh,$table)

Add for a table index keys (all fields, if not yet available)

=cut

sub addIndexes {
  my $dbh = shift;
  my $table = shift;
  my $sql="";
	my $prows = $dbh->selectall_arrayref("describe $table");
	foreach(@$prows) {
	  my $prow = $_;
		my $field = $$prow[0];
		my $type = $$prow[1];
		my $pos = index($type,"blob");
		$pos = index($type,"text") if $pos==-1;
		my $index1 = $$prow[3];
		if ($index1 eq "" && $pos==-1) {
			my $index = "i".$field;
		  $sql .= "," if $sql ne "";
		  $sql .= "add index $index ($field)";
		}
	}
	if ($sql ne "") {
	  $sql = "alter table $table $sql";
		$dbh->do($sql);
	}
}
 





=head checkAccessTable($dbh)

Check if the access table does already exist (if not, add it)

=cut

sub checkAccessTable {
  my $dbh = shift;
  my $sql = "create table if not exists access (" .
	          "host varchar(60), db varchar(64), user varchar(16), " .
						"document int not null default 0," .
						"action varchar(120), additional blob," .
						"hash varchar(255), checkstate int not null default 0," .
						"checkdate datetime, moddate timestamp, " .
						"id int not null primary key auto_increment" .
						")";
  $dbh->do($sql);
}






=head1 _syncTables($dbh,$table,$masterAttributes,$masterTypes,$slaveAttributes)

IN: root database handler
		table name to syncronize
		point
		er to array of required attributes
		pointer to hash(attribute_name,attribute_type)
		pointer to array of existing attributes 
	
=cut

sub _syncTables
{
	# Syncronize a table given an array of master attributes / types
	# This method is designed only to add attributes to a table
	my $dbh = shift;
	my $table = shift;
	my $pamasterAttributes = shift;
	my $phmasterTypes = shift;
	my $paslaveAttributes = shift;

	for (my $i = 0; $i < $#$pamasterAttributes; $i++) {
		my ($afterAttribute);
		my $masterAttribute = $$pamasterAttributes[$i];
		my $masterAttributeType = $$phmasterTypes{$masterAttribute};

		my $slaveAttribute = $$paslaveAttributes[$i];
		if ($i == 0) {
			$afterAttribute = $$paslaveAttributes[0];
		} else {
			$afterAttribute = $$paslaveAttributes[$i - 1];
		}
		if ($masterAttribute ne $slaveAttribute && $masterAttributeType ne "") {
			my $query = "ALTER TABLE $table ADD COLUMN $masterAttribute " .
			            "$masterAttributeType AFTER $afterAttribute";
			$dbh->do($query);
			$paslaveAttributes = _getTableAttributes($dbh,$table);
		}
	}
}






=head1 _getTableAttributes($dbh,$table)

IN: root database handler
		table name
OUT: pointer to array of existing attributes for the given table

This method executes a DESCRIBE - SQL command on the given table and returns
a pointer to an array of this attributes

=cut

sub _getTableAttributes {
	# Retrieve the attributes name of a given table
	my $dbh = shift;
	my $table = shift;
	my @attributes;
	my $sth = $dbh->prepare("DESCRIBE $table");
	$sth->execute();
	while (my @row = $sth->fetchrow_array()) {
		push @attributes, $row[0];
	}
	$sth->finish();

	return \@attributes;
}






=head1 unlock($dbh,$val)

unlock document(s)

=cut

sub unlock{
  my $dbh = shift;
  my $val = shift;
  my ($sql,$message,$x,$y);
  my $sql1=sqlrange($val);
  $sql = "update archiv set Gesperrt='' where Laufnummer > 0 $sql1";
  $dbh->do($sql) || exit $error;
  $message = "Document(s) $val unlocked";
  logmessage($message);
}






=head1 newpw($dbh,$host,$user,$newpasswd)

set a new password

=cut

sub newpw {
  my $dbh = shift;
  my $host = shift;
  my $user = shift;
  my $newpasswd = shift;
  my ($sql,$message,$qhost,$quser,$qnewpasswd);
  # we have to quote the strings
  $qhost=$dbh->quote($host);
  $quser=$dbh->quote($user);
  $qnewpasswd=$dbh->quote($newpasswd);
  # send it to db
	if ($user eq 'root') {
	  $sql = "delete from archivista.sessionweb";
		$dbh->do($sql);
		$sql = "delete from archivista.sessions";
		$dbh->do($sql);
		$sql = "delete from archivista.session";
		$dbh->do($sql);
		$sql = "delete from archivista.session_data";
		$dbh->do($sql);
	}
  $sql="set password for $quser"."@"."$qhost=Password($qnewpasswd)";
  my $res=$dbh->do($sql) || exit $error;
  $message = "New password for $host,$db,$user";
  logmessage($message);
  return $res;
}






=head1 sqlrange($range)

  gives back an sql fragment either 'and Laufnummer=x' or
                                    'and Laufnummer between x and y'

=cut

sub sqlrange {
  my $val = shift;
  my ($sql,$x,$y);

  # check if we only have one document or several documents
  $val=~/^(\d+)(-*)(\d*)/;
  $x=$1;
  $y=$3;
 
  if ($y != ''){
    $sql = "and Laufnummer between $x and $y" if ($y>0 && $y>$x);
  } else {
    $sql = "and Laufnummer=$x" if ($x>0);
  }
  return $sql; 
}






=head1 check($dbh,$host,$db,$user,$pw)

Check if the actuall lang/application_menu strings are ok

=cut

sub check {
  my $dbh = shift;
	my $host = shift;
	my $db = shift;
	my $user = shift;
	my $pw = shift;
	my $sql="select sum(length(en)) from languages";
  my @res = $dbh->selectrow_array($sql);
	my $nr=$res[0];
	logmessage("We have $nr chars of language strings");
	my $file = "/home/cvs/archivista/languages/perl/languages.";
	my $fchk = $file."chk";
	my $fsql = $file."sql";
	my $ptxt = getFileContent($fchk);
	if ($$ptxt>0 && $$ptxt != $nr) {
	  logmessage("Update at $host in $db is needed");
		my $path="/home/cvs/archivista/initdb/";
		my $f1="$path"."menu.sql";
		my $f2="$fsql";
		my $login="mysql -h$host -u$user -D$db ";
		$login.="-p$pw " if $pw ne "";
		if (-e $f1 && -e $f2) {
		  logmessage('Update files are ok, we update languages/menu strings');
			system("$login <$f1");
			system("$login <$f2");
		}
  }
	if (!-d "/home/data/archivista/data") {
	  mkdir "/home/data/archivista/data";
		system("chown -R archivista.users /home/data/archivista/data");
	}
	if (!-d "/var/lib/vz/dump") {
	  mkdir "/var/lib/vz/dump";
	}
	my $prg = "/home/data/archivista/cust/desktop/desktop.sh"; 
	system($prg) if -e $prg; # check for a user script after start
}






=head1 $ptxt=getFileContent($file)

Give back the content of a file in a pointer

=cut

sub getFileContent {
  my $file = shift;
	my $f = "";
	if (-e $file) {
    open(FIN,$file);
		binmode(FIN);
		my @f = <FIN>;
		close(FIN);
		$f = join("",@f);
	}
	return \$f;
}

