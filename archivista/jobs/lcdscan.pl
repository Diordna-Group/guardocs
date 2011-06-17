#!/usr/bin/perl -w

use strict;
use IO::Socket;
use Fcntl;
use Time::HiRes qw ( time alarm sleep );

use lib qw(/home/cvs/archivista/jobs);
use DBI;

use constant MSGSCAN => 'Scanning started...'; # message when scan job starts
use constant SCAN => '/usr/bin/perl /home/cvs/archivista/jobs/sane-button.pl';
use constant CHECKON => '/etc/av-button.conf'; # check if sane-button is on

# 0 : None (only fatal errors), # 1 : Warnings, # 5 : Explain every step.
my $verbosity = 0;
my $SERVER = "localhost";
my $PORT = "13666";
$SIG{INT} = \&grace;
$SIG{TERM} = \&grace;
my $progname = $0;
$progname =~ s#.*/(.*?)$#$1#;
my $remote = IO::Socket::INET->new( Proto => 'tcp', PeerAddr => $SERVER,
		PeerPort  => $PORT, ) || die "Cannot connect to LCDproc port\n";
$remote->autoflush(1); # Make sure our messages get there right away
sleep 1;	# Give server plenty of time to notice us...
print $remote "hello\n";
my $lcdresponse = <$remote>;
print $lcdresponse if $verbosity >= 5;
# determine LCD size (not needed here, but useful for other clients)
($lcdresponse =~ /lcd.+wid\s+(\d+)\s+hgt\s+(\d+)/);
my $lcdwidth = $1; my $lcdheight= $2;
print "Detected LCD size of $lcdwidth x $lcdheight\n" if ($verbosity >= 5);
# Turn off blocking mode...
fcntl($remote, F_SETFL, O_NONBLOCK);

my $prg = "/home/cvs/archivista/jobs/sane-button.pl";
my $host = `sed -n "s/\\\$val{host1} *= *\\"\\(.*\\)\\"; */\\1/p\" $prg`;
my $db1 = `sed -n "s/\\\$val{db1} *= *\\"\\(.*\\)\\"; */\\1/p\" $prg`;
my $user = `sed -n "s/\\\$val{user1} *= *\\"\\(.*\\)\\"; */\\1/p\" $prg`;
my $pw =  `sed -n "s/\\\$val{pw1} *= *\\"\\(.*\\)\\"; */\\1/p\" $prg`;
chomp $host;
chomp $db1;
chomp $user;
chomp $pw;
my @dbs = split(",",$db1);
my $c=0;
foreach (@dbs) { # remove scan definitions (scan box values)
  my $name = $_;
  my ($dbname,$id) = split(':',$name);
	$dbs[$c]=$dbname;
	$c++;
}
my $db = $dbs[0];
my $pos = 0; # default scan def (first one)
my $dbpos = 0; # default database (first one)
my $dbh = MySQLOpen($host,$db,$user,$pw);
if ($dbh && checkButton()) { # dbh is ok and sane-button is on
  logit("dbh ok"); # logit
  addKeys($lcdresponse);
	initScreen($remote,$db);
	my ($pmsg,$poslast) = scanNames($dbh,$db);
	showScreen($remote,$pmsg,$pos,$poslast);
	my $scanmode=1;
  while(1) {
	  # Handle input...
	  while (defined(my $line = <$remote>)) {
      chomp $line;
      print "Received '$line'\n" if ($verbosity >= 5);
      my @items = split(/ /, $line);
      my $command = shift @items;
	    # Use input to change songs...
	    if ($command eq 'key') {
		    my $key = shift @items;
				if ($scanmode==1) {
		      if ($key eq 'Up') {
			      $pos--;
			      $pos=0 if $pos<0;
	          ($pmsg,$poslast) = scanNames($dbh,$db);
	          showScreen($remote,$pmsg,$pos,$poslast);
		      } elsif ($key eq 'Down') {
	          ($pmsg,$poslast) = scanNames($dbh,$db);
					  $pos++;
					  $pos=$poslast-1 if $pos>=$poslast;
	          showScreen($remote,$pmsg,$pos,$poslast);
		      } elsif ($key eq 'Enter') {
			      scanButton($remote,$pmsg,$pos,$poslast,$db);
					} elsif ($key eq "Home") {
	          initScreen($remote);
            $scanmode=0;
						$pos=0;
					} elsif ($key eq "F1") {
					  $dbpos++;
						$dbpos=0 if $dbs[$dbpos] eq "";
						$db = $dbs[$dbpos];
	          initScreen($remote,$db);
	          ($pmsg,$poslast) = scanNames($dbh,$db);
	          showScreen($remote,$pmsg,$pos,$poslast);
					}
				}
				if ($scanmode==0) {
				  if ($key eq 'Escape') {
					  $scanmode=1;
						$pos=0;
	          initScreen($remote,$db);
	          ($pmsg,$poslast) = scanNames($dbh,$db);
	          showScreen($remote,$pmsg,$pos,$poslast);
		      } elsif ($key eq 'Up') {
			      $pos--;
			      $pos=0 if $pos<0;
						($pmsg,$poslast) = getIPInfos();
	          showScreen($remote,$pmsg,$pos,$poslast);
		      } elsif ($key eq 'Down') {
					  $pos++;
					  $pos=$poslast-1 if $pos>=$poslast;
						($pmsg,$poslast) = getIPInfos();
	          showScreen($remote,$pmsg,$pos,$poslast);
					} else {
						($pmsg,$poslast) = getIPInfos();
						$pos=0;
	          showScreen($remote,$pmsg,$pos,$poslast);
					}
				}
	    } elsif ($command eq 'connect') {
		    # And ignore everything else
	    } elsif ($command eq 'listen') {
	    } elsif ($command eq 'ignore') {
	    } elsif ($command eq 'success') {
	    } else {
		    logit("Huh? $line") if $line !~ /^\s*$/o;
	    }
	  }
	  # wait a bit
	  sleep 0.25;
	}
}






# To be called on exit and on SIGINT or SIGTERM.
sub grace() {
  print "Exiting...\n" if ($verbosity >= 5);
  # release keys
	print $remote "client_del_key Up\n";
	$lcdresponse = <$remote>;
	print $remote "client_del_key Down\n";
	$lcdresponse = <$remote>;
	print $remote "client_del_key Enter\n";
	$lcdresponse = <$remote>;
	print $remote "client_del_key Escape\n";
	$lcdresponse = <$remote>;
	print $remote "client_del_key F1\n";
	$lcdresponse = <$remote>;
	print $remote "client_del_key F2\n";
	$lcdresponse = <$remote>;
	print $remote "client_del_key F3\n";
	$lcdresponse = <$remote>;
	print $remote "client_del_key Home\n";
	$lcdresponse = <$remote>;
  # close socket
  close($remote);
  exit;
}






=head1 scanButton($pos)

Start the scan process with definition $pos

=cut

sub scanButton {
  my ($remote,$pmsg,$pos,$poslast,$db) = @_;
	my @msg1 = (MSGSCAN," "," ");
	showScreen($remote,\@msg1,-1,$poslast);
	my $pos1 = $pos+1;
	my $cmd = SCAN." -2 $pos1 $db";
	system($cmd);
	sleep 3;
	showScreen($remote,$pmsg,$pos,$poslast);
}






=head1 checkButton

Check if the sane-button is switched on, if so, give back 1

=cut

sub checkButton {
  my $on = 0;
  if (-e CHECKON) {
		open(FIN,CHECKON);
		my @f = <FIN>;
		close(FIN);
		my $f = $f[0];
	  chomp $f; 
	  my ($name,$val)=split("=",$f); # check for av_button value in first line
	  $on = 1 if $name eq "av_button" && $val==1;
	}
	return $on;
}






=head1 initScreen

Open a screen on the lcd display

=cut

sub initScreen {
  my ($remote,$db) = @_;
	$db = "ArchivistaBox" if $db eq "";
  # Set up some screen widgets...
  print $remote "client_set name avbox\n";
  $lcdresponse = <$remote>;
  print $remote "screen_add avbox\n";
  $lcdresponse = <$remote>;
  print $remote "screen_set avbox name ArchivistaBox ".
	              "heartbeat off duration 50000\n";
  $lcdresponse = <$remote>;
  print $remote "widget_add avbox one title\n";
  $lcdresponse = <$remote>;
  print $remote "widget_set avbox one $db\n";
  $lcdresponse = <$remote>;
}






=head1 showScreen($remote,$pmesg,$pos,$poslast)

Show messages on display

=cut

sub showScreen {
  my ($remote,$pmsg,$pos,$poslast) = @_;
	my $pos1 = $pos;
	$pos1=0 if $pos1<0;
	my $last = @$pmsg;
	for (my $line=2;$line<=4;$line++) { 
	  my $current = 0;
	  $current = 1 if $pos1==$pos;
		$current = 2 if $pos<0;
		my $mess1 = "";
		$mess1 = $$pmsg[$pos1] if $pos1<$poslast;
	  showScreenLine($remote,$line,$mess1,$current);
		$pos1++; 
	}
}






=head1 showScreenLine($remote,$line,$mess,$current)

Show one line on the display

=cut

sub showScreenLine {
  my ($remote,$line,$mess,$current) = @_;
	my $name = "el$line";
	my $cur = " ";
	$cur = ">" if $current==1;
	$cur = "" if $current==2;
	my $mess1 = "$cur$mess";
  print $remote "widget_add avbox {$name} string\n";
  $lcdresponse = <$remote>;
  print $remote "widget_set avbox {$name} 1 $line {$mess1}\n";
  $lcdresponse = <$remote>;
}






=head1 ($pmsg,$max) = scanNames($dbh,$db)

Give back the scan def names

=cut

sub scanNames {
  my ($dbh,$db) = @_;
  # we need to have a look in the scan definitions
  my $sql = "select Inhalt from $db.parameter where Art = 'parameter' " .
            "AND Name='ScannenDefinitionen'";
  my @row = $dbh->selectrow_array($sql);
  my $scandefs = $row[0];
	my @lines = split("\r\n",$scandefs);
	my @msg = ();
	my $max = 0;
	foreach my $line (@lines) {
	  my @vals = split(";",$line);
		push @msg,$vals[0];
		$max++;
	}
	return (\@msg,$max);
}






=head1 addKeys($lcdresponse)

Add the keys to the lcd panel

=cut

sub addKeys {
  my ($lcdresponse) = @_;
  # NOTE: You have to ask LCDd to send you keys you want to handle
  print $remote "client_add_key Up\n";
  $lcdresponse = <$remote>;
  print $remote "client_add_key Down\n";
  $lcdresponse = <$remote>;
  print $remote "client_add_key Enter\n";
  $lcdresponse = <$remote>;
  print $remote "client_add_key Escape\n";
  $lcdresponse = <$remote>;
  print $remote "client_add_key F1\n";
  $lcdresponse = <$remote>;
  print $remote "client_add_key F2\n";
  $lcdresponse = <$remote>;
  print $remote "client_add_key F3\n";
  $lcdresponse = <$remote>;
  print $remote "client_add_key Home\n";
  $lcdresponse = <$remote>;
}






sub getIPInfos {
	my $data = `/home/archivista/status.sh -webconfig 2>/dev/null`;
	$data =~ s/(server )//gs;
	$data =~ s/(Inet addr: )/IP:/gs;
	$data =~ s/(Bcast: )/BC:/gs;
	$data =~ s/(Mask: )/MC:/gs;
	$data =~ s/(Remote access )/Remote /gs;
	$data =~ s/(Graphical remote access )/Remote /gs;
	$data =~ s/(Rsync network backup )/Rsync backup /gs;
	$data =~ s/(USB hard-disk backup )/USB backup /gs;
	$data =~ s/(https )//gs;
	$data =~ s/(HWaddr: )//gs;
	$data =~ s/(T2 SDE 2\.2\.0 \(2005\/12\/01\) - )/Version: /gs;
	$data =~ s/(\n\n)/\n/gs;
	$data =~ s/(\n\n)/\n/gs;
	$data =~ s/(\n\n)/\n/gs;
	my @msg = split("\n",$data);
	my $poslast = @msg;
	return (\@msg,$poslast);
}



=head2 $dbh=MySQLOpen($host,$db,$user,$pw)

Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen {
  my ($host,$db,$user,$pwd) = @_;
  my $ds = "DBI:mysql:host=$host;database=$db";
  my $dbh = DBI->connect( $ds, $user, $pwd,
                            { RaiseError => 0, PrintError => 0 } );
  logit("DBConnection-0 failed") if !defined $dbh;
  return $dbh;
}




=head1 logit($message)

Writes a message to a log file

=cut

sub logit {
  my $message = shift;
  # $log file name comes from outside
  my @parts = split("/",$0);
  my $prg = pop @parts;
  open(FOUT, ">>/home/data/archivista/av.log");
  binmode(FOUT);
  my $logtext = $prg . " " . $message . "\n";
  print FOUT $logtext;
  close(FOUT);
}





