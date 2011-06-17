#!/usr/bin/perl

=head1 lcdpanel.pl (c) 0.1,6.11.2007 by Archivista GmbH, Urs Pfister

Programm checks if sane-button is on. If so, it tries to display
the curent scan definitions and scans if the ok button is pressed
Hint: After every action, it is needed to start the program again
      (probably best done with /etc/inittab)

if you want enable it, just add the following line to /etc/inittab
av4:5:respawn:/usr/bin/perl /home/cvs/archivista/jobs/lcdpanel.pl

=cut

# libraries
use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVJobs;

# constants
use constant FILE_POS => '/pos.txt'; # used to store the current scan def pos
use constant FILE_OUT => '/out.txt'; # gets back the last action
use constant USBLCD => '/home/cvs/archivista/jobs/usblcd'; # lcd panel program
use constant USBREAD => 'read'; # read from lcd panel
use constant USBTEXT => 'text'; # send text to lcd panel
use constant USBCLEAR => 'clear'; # clear screen
use constant USBBACK => 'backlight'; # switch on/off backlight
use constant MSGSCAN => ' Scanning started...'; # message when scan job starts
# Program that we use to scan (actually it is sane-button.pl
use constant SCAN => '/usr/bin/perl /home/cvs/archivista/jobs/sane-button.pl';
use constant USBKILL => 'killall usblcd'; # kill lcd panel after action
use constant CHECKON => '/etc/av-button.conf'; # check if sane-button is on



# read the database connection information
my $config = Archivista::Config->new;
my $host  = $config->get("MYSQL_HOST");
my $db = $config->get("MYSQL_DB");
my $user = $config->get("MYSQL_UID");
my $pwd = $config->get("MYSQL_PWD");
my $pos = 0; # default scan def (first one)
readFile(FILE_POS,\$pos); # write position to file
my $dbh = MySQLOpen($host,$db,$user,$pwd);
if ($dbh && checkButton()) { # dbh is ok and sane-button is on
  clearLCD(1); # clear lcd with backlight
  logit("dbh ok"); # logit
  my $scanfirst = scanName($dbh,$db,0); # retrieve the scan defs
  my $scandef1 = scanName($dbh,$db,$pos);
  my $scandef2 = scanName($dbh,$db,$pos+1);
	writeLCD("*$scandef1"); # send it to lcd panel (2nd only if available)
	writeLCD(" $scandef2",1) if $scandef2 ne $scanfirst;
	readLCD(FILE_OUT); # invoke read process (sends it to a file)
	while (-e FILE_OUT) { # there is a file, so check it
		my $f1=""; # read the content of the file
		readFile(FILE_OUT,\$f1);
		if ($f1 =~ /x0a/) { # go position up
		  $pos--;
			$pos=0 if $pos<0;
			last;
		} elsif ($f1 =~ /x0b/) { # go position down
		  $pos++;
      my $scanlast = scanName($dbh,$db,$pos);
			$pos-- if $scanfirst eq $scanlast;
			last;
		} elsif ($f1 =~ /x0c/) { # start scan process
			scanButton($pos);
			last;
		} else { # no action, wait a second
		  sleep 1;
		}
	}
	writeFile(FILE_POS,\$pos,1); # write the current position
	logit("$pos--end");
	system(USBKILL); # kill lcd panel programm
	unlink FILE_OUT if -e FILE_OUT;
	$dbh->disconnect();
} else { # sane button is off, so set backlight off
  clearLCD(0);
  sleep 10;
}






=head1 clearLCD($state)

Clear screen and set backlight on/off (1/0)

=cut

sub clearLCD {
  my $state = shift;
  my $cmd = USBLCD." ".USBCLEAR;
	system($cmd);
	$cmd = USBLCD." ".USBBACK." $state";
	system($cmd);
}






=head writeLCD($msg,[$posy,$posx])

Send out text to the lcd pannel (at posy,posy)

=cut

sub writeLCD {
  my $msg = shift;
	my $posy = shift;
	my $posx = shift;
  my $cmd = USBLCD." ".USBTEXT." ".$posy.$posx." '".$msg."'";
  system($cmd);
}





=head1 readLCD($file)

Wait for an user input in $file

=cut

sub readLCD {
  my $file = shift;
  my $cmd = USBLCD." ".USBREAD." 2&>/$file &"; 
	system($cmd);
}






=head1 scanName($dbh,$db1,$pos)

Get the name of the scan definition at pos

=cut

sub scanName {
  my $dbh = shift;
	my $db1 = shift;
	my $pos = shift;
  my @vals = split(";",getScanDefByNumber($dbh,$db,$pos));
	return $vals[0];
}





=head1 scanButton($pos)

Start the scan process with definition $pos

=cut

sub scanButton {
  my $pos = shift;
	my $msg = MSGSCAN;
  writeLCD($msg,1);
	sleep 3;
	my $cmd = SCAN." -2 $pos";
	system($cmd);
}






=head1 checkButton

Check if the sane-button is switched on, if so, give back 1

=cut

sub checkButton {
  my $on = 0;
  if (-e CHECKON) {
    my $f="";
	  readFile(CHECKON,\$f);
	  chomp $f; 
	  my ($name,$val)=split("=",$f); # check for av_button value in first line
	  $on = 1 if $name eq "av_button" && $val==1;
	}
	return $on;
}


	
