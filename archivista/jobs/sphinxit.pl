#!/usr/bin/perl

=head1 sphinxit.pl --- (c) by Archivista GmbH, 2009

Create config files for sphinx index
        
=cut

use lib qw(/home/cvs/archivista/jobs);
use strict;
use AVJobs;

my $mode = shift; # currently only searchd
my $dbgo = shift; # the desired database

if ($mode eq "start") {
  system("killall searchd");
  system("searchd");
	exit;
}

my $config = Archivista::Config->new;
my $host = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pw = $config->get("MYSQL_PWD");
undef $config;


die if -e "/tmp/sphinx.wrk";

my $dbh = MySQLOpen($host,$db,$user,$pw);
if ($dbh) {
  my $pdbs = getValidDatabases($dbh);
  my @lines = <DATA>;
  my $conf = join("",@lines);
	if (!-e "/home/data/archivista/fulltext") {
    mkdir("/home/data/archivista/fulltext")
	}
  my $found = 0;
  foreach (@$pdbs) {
    my $db1 = $_;
    my $index = getParameterRead($dbh,$db1,"SEARCH_FULLTEXT");
	  if ($index==2) {
		  if ($mode eq "searchd") {
			  if (-e "/etc/sphinx.conf") {
	        checkSearchd();
				  last;
				}
			} elsif ($mode eq "indexall") {
		    if (!-e "/home/data/archivista/fulltxt/$db1") {
          mkdir("/home/data/archivista/fulltext/$db1");
		    }
		    if (-d "/home/data/archivista/fulltext/$db1") {
			    my $sql = "select max(Seite) from $db1.archivseiten";
				  my @res = $dbh->selectrow_array($sql);
				  my $nr = $res[0];
					$nr = 0 if $nr eq "";
		      checkOldTableStructure($dbh,$db1);
	        $conf .= getSourcePart($host,$db1,$user,$pw,$nr);
	        $conf .= getIndexPart($db1);
			    $found++;
		    }
			} elsif ($mode eq "indexone") {
			  if ($dbgo eq $db1) {
				  my $cmd = "indexer --rotate b$db1";
					system($cmd);
					last;
				}
			} elsif ($mode eq "startit") {

			}
	  }
    #print "$db1--$index\n";
  }
	if ($found>0) {
    open(FLOG,"/tmp/sphinx.wrk");
	  print FLOG "Now write new conf file\n";
    writeFile("/etc/sphinx.conf",\$conf,1);
	  checkSearchd();
    my $cmd = "indexer --all --rotate >>/home/data/archivista/av.log";
	  system($cmd);
    close(FLOG);
    system("cat /tmp/sphinx.wrk >>/home/data/archivista/av.log");
    unlink "/tmp/sphinx.wrk" if -e "/tmp/sphinx.wrk";
  }
}



sub checkSearchd {
  my $cmd = "searchd --stop";
	system($cmd);
	$cmd = "searchd";
	system($cmd);
}



sub checkOldTableStructure {
  my ($dbh,$db1) = @_;
	my $sql = "show create table $db1.archivseiten";
	my @res = $dbh->selectrow_array($sql);
	if ($res[1] ne "") {
	  my $struct = $res[1];
		my $res2 = $struct =~ /MAX_ROWS/;
		if ($res2==0) {
		  print "we need to change $db1 structure\n";
			my $sql = "alter table $db1.archivseiten drop index TextI";
			$dbh->do($sql);
			$sql = "alter table $db1.archivseiten ".
			       "max_rows=100000000, avg_row_length=100000";
			$dbh->do($sql);
		}
	}
}




sub getIndexPart {
  my ($db1) = @_;
  my $part = <<EOF;
index a$db1 {
  source      = srca$db1
  path      = /home/data/archivista/fulltext/a$db1
  docinfo     = extern
  mlock     = 0
  morphology    = none
  min_word_len    = 1
  charset_type    = sbcs
  html_strip        = 0
}

index b$db1 {
  source      = srcb$db1
  path      = /home/data/archivista/fulltext/b$db1
  docinfo     = extern
  mlock     = 0
  morphology    = none
  min_word_len    = 1
  charset_type    = sbcs
  html_strip        = 0
}

index $db1 {
  type = distributed
	local = a$db1
	local = b$db1
}

EOF

  return $part;
}


sub getSourcePart {
  my ($host,$db1,$user,$pw,$nr) = @_;
  my $part = <<EOF;
source srca$db1 {
  type            = mysql
  sql_host        = $host
  sql_user        = $user
  sql_pass        = $pw
  sql_db          = $db1
  sql_port        = 3306  # optional, default is 3306
  sql_query       = \\
	  SELECT Seite,Text,truncate(Seite/1000,0) as laufnummer from archivseiten
  sql_attr_uint     = laufnummer
  sql_ranged_throttle = 0
  sql_query_info    = SELECT Seite FROM archivseiten where Seite=\$id
}

source srcb$db1 {
  type            = mysql
  sql_host        = $host
  sql_user        = $user
  sql_pass        = $pw
  sql_db          = $db1
  sql_port        = 3306  # optional, default is 3306
  sql_query       = \\
	  SELECT Seite,Text,truncate(Seite/1000,0) as laufnummer from archivseiten \\
		where Seite>$nr
  sql_attr_uint     = laufnummer
  sql_ranged_throttle = 0
  sql_query_info    = SELECT Seite FROM archivseiten where Seite=\$id
}

EOF
 
 return $part;
}




__DATA__

indexer {
  mem_limit     = 128M
}

searchd {
  listen        = /var/run/searchd.sock
  listen        = localhost:3307:mysql41
  log         = /var/log/searchd.log
  query_log     = /var/log/query.log
  read_timeout    = 5
  client_timeout    = 300
  max_children    = 30
  pid_file      = /var/log/searchd.pid
  max_matches     = 10000
  seamless_rotate   = 1
	preopen_indexes   = 0
	unlink_old      = 1
	mva_updates_pool  = 1M
	max_packet_size   = 8M
	max_filters     = 256
	max_filter_values = 4096
}
																
