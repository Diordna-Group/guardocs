#!/usr/bin/perl

use strict;
use File::Copy;
my %val;
$val{cups} = "/var/spool/cups-pdf/ANONYMOUS";
$val{ftp} = "/home/data/archivista/ftp";
$val{log} = "/home/data/archivista/av.log";
$val{webconfig} = "/etc/webconfig";
$val{dirsep} = "/";
initFolders(); # add all needed folders
my $watch=`find $val{cups} $val{webconfig} $val{ftp} -type d -printf '%p '`;
print "Watching: $watch \n";
open(INOTIFY, "inotifywait -m -e create -e close_write -e moved_to $watch |");
my $quit_loop=1;
while (<INOTIFY>) {
  # parse the inotify event output, that is in the style:
  # /tmp/, CLOSE_WRITE CLOSE a
  # we remove the middle part and insert a / separator
  my $name = $_;
  chomp $name; 
	#logit($name);
	$name =~ s/ [^ ]*,[^ ]* //;
	$name =~ s/( MOVED\_TO )//;
  # during testing removed directories generate some IGNORED line
  next if /IGNORED/;
  if (/CREATE/) {
    print "CREATE\n";
    if (/CREATE ISDIR/) {
      # is it a new sub-directory to watch?
      print "ISDIR\n";
      $watch="$watch $name";
      last;
    } else {
      next;
    }
  } else {
    # what kind of file?
    my $job = "";
    if ($name =~ /\/ftp\/office\//) {
      $job="OFFICE";
    } elsif ($name =~ /\/ftp\/enventa\//) {
      $job="ENVENTA";
    } elsif ($name =~ /\/cups-pdf\//) {
      $job="CUPS";
    } elsif ($name =~ /\/tiff\//) {
      $job="TIFF";
    } elsif ($name =~ /\/pdf\//) {
      $job="PDF";
    } elsif ($name =~ /\/xerox\//) {
      if ($name =~ /\.XST/) {
        $job="XEROX";
      } else {
        next;
  		}
    } elsif ($name =~ /\/tosca\//) {
      if ($name =~ /\.txt/) {
        $job="TOSCA";
      } else {
        next;
	  	}
    } elsif ($name =~ /\/axapta\//) {
      if ($name =~ /\.TXT/) {
        $job="AXAPTA";
      } else {
        next;
			}
    } elsif ($name =~ /\/scanbox\//) {
      if ($name =~ /(\-1\-0\.pnm)$/ ||
		      $name =~ /(\-1\-0\.jpg)$/) {
          $job="SCANBOX";
			}
	  } elsif ($name =~ /\/webconfig\//) {
		  $job="WEBCONFIG";
    } elsif ($name =~ /\/ftp\//) {
      if ($name =~ /\.txt/) {
        $job="FTP";
      } elsif ($name =~ /\.ftp/) {
        $job="FTPSLOW";
      } else {
        next;
      }
    }
		if ($job ne "WEBCONFIG") {
		  my $name1 = $name;
		  $name1 =~ s/\,/ /g;
		  $name1 =~ s/\"/ /g;
		  $name1 =~ s/\'/ /g;
		  if ($name ne $name1) {
		    if (!-e $name1) {
			    logit("move $name to $name1");
			    move("$name","$name1");
			  } else {
          saveJob($job,$name,\%val); # save to job for later processing
			  }
      } else {
        saveJob($job,$name,\%val); # save to job for later processing
		  }
		} else {
		  system("perl /home/cvs/archivista/jobs/webconfig.pl $name");
		}
  }
  print "EOL\n";
}
# TODO: find out how to do in perl, or not use open (" |")
system ("killall inotifywait");
close INOTIFY;
if ($val{dbh} ne "") {
  $val{dbh}->disconnect();
}






=head1 saveJob

Save the file name and all informations to the job table

=cut

sub saveJob {
  my $job = shift;
  my $name = shift;
	my $pval = shift;
  return if $job eq "";
	logit($name);
  if ($$pval{host} eq "") {
	  eval {
      require DBI;
      require Archivista::Config; # needed for the passwords
      my $config = Archivista::Config->new;
      $$pval{host} = $config->get("MYSQL_HOST");
      $$pval{db} = $config->get("MYSQL_DB");
      $$pval{user} = $config->get("MYSQL_UID");
      $$pval{pw} = $config->get("MYSQL_PWD");
      undef $config;
      if (MySQLOpen($pval)) {
        updateJobsTable($$pval{dbh}); # update the job table
			}
		}
	}
  $$pval{dbh}->disconnect();
	if (MySQLOpen($pval)) {
    my $sql = "insert into jobs set " .
            "job = '$job', status = 110"."," .
            "host = ".$val{dbh}->quote($val{host})."," .
            "db = ".$val{dbh}->quote($val{db})."," .
      	    "user = ".$val{dbh}->quote($val{user})."," .
    	      "pwd = ".$val{dbh}->quote($val{pw}).";";
    $val{dbh}->do($sql);
    # now get back the last row number
    $sql="select last_insert_id()";
    my @row=$val{dbh}->selectrow_array($sql);
    my $id=$row[0];
    if ($id>0) {
      $sql = "insert into jobs_data set " .
           "jid = '$id'," .
           "param = 'FILENAME'," .
           "value = '$name';";
      $val{dbh}->do($sql);
			$sql = "update jobs set status=100 where id=$id";
			$val{dbh}->do($sql);
    }
	}
}
	





=head2 initFolders

Init all needed folders

=cut

sub initFolders {
  # for now, the directories must exist, thus create them if necessary
	my $webconfig = "/etc/webconfig";
  system("mkdir $webconfig") if !-e $webconfig;
  system ("mkdir -p /var/spool/cups-pdf/ANONYMOUS");
  system ("chmod 777 /var/spool/cups-pdf/ANONYMOUS");
  system ("chown nobody:nogroup /var/spool/cups-pdf/ANONYMOUS");
}






=head2 updateJobsTable($dbh);

Update the jobs table for all types of imports

=cut

sub updateJobsTable {
  my $dbh = shift;
  # update jobs table!
  my $sql = "alter table jobs change job job " .
    "enum('OCRRECPAGE','SANE','SCANBOX','WEB','WEBCONF','OFFICE','CUPS',".
		"'TEMPPDF','FTP','MAIL','JOBS',".
		"'PDF','TIFF','ENVENTA','TOSCA','AXAPTA','XEROX','FTPSLOW','EXPORT') " .
    "NOT NULL default 'SANE'";
  $dbh->do($sql);
}






=head2 $dbh=MySQLOpen(%$val)

Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen {
  my $pval = shift;
  my ($ds);
  $ds = "DBI:mysql:host=$$pval{host};database=$$pval{db}";
  $$pval{dbh}=DBI->connect($ds,$$pval{user},$$pval{pw});
  return $$pval{dbh};
}





=head1 logit($message)

Writes a message to a log file

=cut

sub logit {
  my $stamp   = TimeStamp();
  my $message = shift;
  # $log file name comes from outside
  my @parts = split($val{dirsep},$0);
  my $prg = pop @parts;
  open( FOUT, ">>$val{log}" );
  binmode(FOUT);
  my $logtext = $prg . " " . $stamp . " " . $message . "\n";
  print FOUT $logtext;
  close(FOUT);
}






=head2 $stamp=TimeStamp 

Actual date/time stamp (20040323130556)

=cut

sub TimeStamp {
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y     = $t[5] + 1900;
  $m     = $t[4] + 1;
  $m     = sprintf( "%02d", $m );
  $d     = sprintf( "%02d", $t[3] );
  $h     = sprintf( "%02d", $t[2] );
  $mi    = sprintf( "%02d", $t[1] );
  $s     = sprintf( "%02d", $t[0] );
  $stamp = $y . $m . $d . $h . $mi . $s;
  return $stamp;
}




