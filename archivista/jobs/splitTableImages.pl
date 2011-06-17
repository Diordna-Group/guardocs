#!/usr/bin/perl

=head1 splitTableImages.pl -> split archivbilder in archivexxxxx

(c) v1.0 - 2.8.2008 by Archivista GmbH, Urs Pfister

=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use DBI;
use AVJobs;

my $cmd = "perl /home/cvs/archivista/jobs/adjustRights.pl"; # rights for tables

my $db1 = shift; # check database/folder stucture (0=one table,1-100=x tables)
stopit($db1,"") if $db1 eq "";
my $frame = shift;
my $framestart = shift;
stopit($db1,$frame) if $frame eq "";
stopit($db1,$frame) if $frame <0 || $frame>100;
my $error = 0;

my $dbh;
logit("program started with: $db1 and frame $frame");
if ($dbh=MySQLOpen()) { # open database and check for slave
  die if HostIsSlave($dbh);
	my $tb = "";
	my $sql = "select Inhalt from $db1.parameter where Name='ArchivExtended'";
	my @row = $dbh->selectrow_array($sql);
	if (($row[0] == $frame || ($row[0]>0 && $frame>0)) && $framestart==0) {
	  stopit($db1,$frame,$row[0]);
	}
	if ($frame>0) {
    # coonection is ok
		my $ordstart = 0;
		$ordstart = $framestart if $framestart>0;
    my $ordend = 0;
	  $sql = "select max(Ordner) from $db1.archiv";
	  my @row = $dbh->selectrow_array($sql);
	  my $max = $row[0];
    my $max2 = getParameterRead($dbh,$db1,"ArchivOrdner");
		if ($max != $max2) {
		  logit("Folder in archive is $max, but shoud be $max2");
			die;
		}
	  while (checkNewTable($dbh,$db1,$frame,$max,
		                     \$tb,\$ordstart,\$ordend,$framestart)) {
	    my $sql = "select Laufnummer,Seiten from $db1.archiv " .
		            "where Ordner between $ordstart and $ordend ".
				  			"and Archiviert=1";
		  createNewTable($dbh,$db1,$tb,$sql);
	  }
	  $sql = "select Laufnummer,Seiten from $db1.archiv where Archiviert=0";
	  createNewTable($dbh,$db1,$tb,$sql);
		$sql = "drop table $db1.archivbilder";
		actionSQL($dbh,$sql);
	  actionSQL($dbh,"unlock tables");
		$sql = "rename table $db1.archinput to $db1.archivbilder";
		actionSQL($dbh,$sql);
		system("$cmd $db1 grant");
		updateFrame($dbh,$db1,$frame);
  } else {
		system("$cmd $db1 revoke");
    if (createOldTableStructure($dbh,$db1)) {
		  lockTables($dbh,$db1);
		  my @tables = ();
      $sql = "show tables from $db1 like 'archimg%'";
	    my $res = $dbh->selectall_arrayref($sql);
	    foreach my $res1 (@$res) { # get all tables
	      push @tables,$$res1[0];
	    }
			my $addfield = "";
			foreach (@tables) {
			  my $table = $_;
			  if ($addfield eq "") {
				  $sql = "show columns from $table like 'BildA'";
				  my @row = $dbh->selectrow_array($sql);
					$addfield = ",BildA" if $row[0] eq "BildA";
				}
	      logit("table $table merging with archivbilder2");
        $sql = "insert into $db1.archivbilder2 ".
				       "(Seite,Bild,BildInput,Quelle".$addfield.") ".
				       "select Seite,Bild,BildInput,Quelle".$addfield." ".
			         "from $db1.$table";
				actionSQL($dbh,$sql);
			}
	    logit("table archivbilder merging with archivbilder2");
      $sql = "insert into $db1.archivbilder2 ".
				     "(Seite,Bild,BildInput,Quelle".$addfield.") ".
			       "select Seite,Bild,BildInput,Quelle".$addfield." ".
		         "from $db1.archivbilder";
			actionSQL($dbh,$sql);
			foreach (@tables) {
        $sql = "drop table $db1.$_";
				actionSQL($dbh,$sql);
			}
			$sql = "drop table $db1.archivbilder";
			actionSQL($dbh,$sql);
	    actionSQL($dbh,"unlock tables");
		  $sql = "rename table $db1.archivbilder2 to $db1.archivbilder";
			actionSQL($dbh,$sql);
		  updateFrame($dbh,$db1,$frame);
		}
	}
}





sub updateFrame {
  my ($dbh,$db1,$frame) = @_;
  my $sql = "select Laufnummer from $db1.parameter ".
	          "where Name='ArchivExtended'";
  my @row = $dbh->selectrow_array($sql);
	if ($row[0] == 0 ) {
		$sql = "insert into $db1.parameter set Art='parameter',".
		       "Tabelle='parameter',Name='ArchivExtended',Inhalt='$frame'";
  } else {
		$sql = "update $db1.parameter set Inhalt='$frame' ".
		       "where Laufnummer=".$row[0];
	}
	logit($sql);
	$dbh->do($sql);
}






sub createNewTable {
  my ($dbh,$db1,$tb,$sql) = @_;
	my $res1 = $dbh->selectall_arrayref($sql);
	die if $dbh->err; # stop if selection was not ok
	foreach my $res2 (@$res1) {
    my $aktnr = $$res2[0];
		my $seiten = $$res2[1]; 
	  for (my $c=1;$c<=$seiten;$c++) {
	    my $nr = ($aktnr*1000)+$c;
      $sql = "insert into $db1.$tb (Seite,Bild,BildA,BildInput,Quelle) ".
			       " select Seite,Bild,BildA,BildInput,Quelle ".
			       "from $db1.archivbilder where Seite=$nr";
			actionSQL($dbh,$sql);
	  }
	}
}






sub checkNewTable {
  my ($dbh,$db1,$frame,$max,$ptb,$pordstart,$pordend,$framestart) = @_;
	my $res = 1; # everything is ok as long we have enough folders
	if ($$pordend<$max) {
    $$ptb = "archimg".sprintf("%05d",$$pordend);
		$$pordstart = $$pordend+1;
	  $$pordend += $frame;
		$$pordend = $max if $$pordend>$max;
	} else {
	  $$ptb = "archinput";
	  $res=0;
	}
	my $sql = "show tables from $db1 like '$$ptb'";
	my @row = $dbh->selectrow_array($sql);
	if ($row[0] eq "") {
    my $sql = "create table $db1.$$ptb (".
              "Seite bigint not null default 0 primary key,".
			  	    "Bild longblob, BildA longblob, ".
							"BildInput longblob, Quelle longblob";
		if ($$ptb eq "archinput") {
	    $sql .= ",BildX int not null default 0, BildY int not null default 0".
			        ",BildAX int not null default 0, BildAY int not null default 0";
							",DatumA datetime";
		}
		$sql .= ") TYPE=MyISAM MAX_ROWS=10000000 AVG_ROW_LENGTH=200000";
	  logit("folders till: $$pordend");
	  actionSQL($dbh,$sql);
	}
	my $sql1 = "lock tables $db1.$$ptb write,$db1.archivbilder write,".
	           "$db1.archiv write,$db1.archivseiten write";
	actionSQL($dbh,$sql1);
	return $res;
}






sub createOldTableStructure {
  my ($dbh,$db1) = @_;
	my $res = 1; # everything is ok as long we have enough folders
  my $sql = "create table $db1.archivbilder2 (".
            "Seite bigint not null default 0 primary key, ".
				    "Bild mediumblob, BildA longblob, ".
						"BildInput longblob, Quelle longblob, ".
						"BildX int not null default 0, ".
						"BildY int not null default 0, ".
						"BildAX int not null default 0, ".
						"BildAY int not null default 0, ".
						"DatumA datetime) ".
					  "TYPE=MyISAM MAX_ROWS=10000000 AVG_ROW_LENGTH=200000";
	actionSQL($dbh,$sql);
	return $res;
}






=head1 stopit

Command line parameters not ok

=cut

sub stopit {
  my ($db,$frame,$current) = @_;
  my $msg = "$0: database folderframe(0-100).\n".
	          "Current values:$db $frame $current.\n";
	print STDERR $msg;
	logit($msg);
	die;
}






=head actionSQL($dbh,$sql)

Process a sql command and check it for errors. If errors, stop it

=cut

sub actionSQL {
  my ($dbh,$sql) = @_;
	logit($sql);
	$dbh->do($sql);
	if ($dbh->err) {
	  logit($dbh->errstr);
		die;
	}
}





sub lockTables {
  my ($dbh,$db1) = @_;
  my $sql = "show tables from $db1 like 'arch%'";
	my $sql1 = "";
	my $res1 = $dbh->selectall_arrayref($sql);
	foreach my $res2 (@$res1) {
	  my $table = $$res2[0];
		$sql1 .= "," if $sql1 ne "";
		$sql1 .= "$db1.$table write";
	}
	if ($sql1 ne "") {
	 $sql1 = "lock tables $sql1";
	 actionSQL($dbh,$sql1);
	}
}

