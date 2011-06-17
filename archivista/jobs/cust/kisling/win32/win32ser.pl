#!perl

###
# Description
# Script to add/remove a windows service
#
# Author: Markus Stocker
# Version: 0.1
# Date: 04.02.2004
### 

use Win32::Daemon;
use strict;

###
# Configuration
# Path to Perl.exe
my $perlpath = "c:\\Perl\\Perl\\bin\\perl.exe";
###

my $mode = shift;
my $servname = shift;
my $servscript = shift;
my $argperlpath = shift;
my $machine = "";

# Setting perlpath to the ARGV perlpath set by user
if (length($argperlpath) > 0) {
	$perlpath = $argperlpath;
}

if ($mode eq "install") {
	if (length($servname) == 0 || length($servscript) == 0) {
		print Usage();
		exit 0;
	} elsif (!(-f $servscript)) {
		print "File not found error: $servscript\n";
		exit 0;
	} elsif (!(-f $perlpath)) {
		print "Perl.exe not found\n";
		print Usage();
		exit 0;
	}
} elsif ($mode eq "remove") {
	if (length($servname) == 0) {
		print Usage();
		exit 0;
	}
} else {
	print Usage();
	exit 0;
}

my %Hash = (
		name => $servname,
		display => $servname,
		path => $perlpath,
		user => '',
		pwd => '',
		parameters => $servscript);


if ($mode eq "install") {
	if (Win32::Daemon::CreateService(\%Hash)) {
		print "Successfully added $servname.\n";
	} else {
		my $error = Win32::FormatMessage(Win32::Daemon::GetLastError());
		print 	"Failed to add service: $error\n";
	}
} elsif ($mode eq "remove") {
	if (Win32::Daemon::DeleteService($machine,$servname)) {
		print "Successfully removed $servname.\n";
	} else {
		my $error = Win32::FormatMessage(Win32::Daemon::GetLastError());
		print 	"Failed to remove service: $error\n";
	}
}



###
# Functions

sub Usage
{	
	my $return = "\n\nINSTALL Service\n";
	$return .= "perl win32serv.pl install [service name] [service script] [perl.exe path]\n\n";
	$return .= "REMOVE Service\n";
	$return .= "perl win32serv.pl remove [service name]\n\n";
	$return .= "The perl.exe path on install can be configured also in the script\n";
	$return .= "with the variable \$perlpath\n";
}

__END__






#########################
# DOCUMENTATION		#
#########################




Win32::Daemon INSTALLATION
--------------------------

Unter Indigoperl 5.8 mit dem Tool IPM den Command
install http://www.roth.net/perl/packages/Win32-Daemon.ppd



Win32::Daemon BEISPIEL
----------------------

#!perl

use Win32::Daemon;

Win32::Daemon::StartService();

while (SERVICE_START_PENDING != Win32::Daemon::State()) {
	sleep(1);
}

Win32::Daemon::State(SERVICE_RUNNING);

while (1) {
  open FOUT, ">>c:\\win32testserv.log";
  print FOUT localtime() . "\n";
  close FOUT;
  sleep 3;
  if (Win32::Daemon::State() == SERVICE_STOP_PENDING) {
    open FOUT, ">>c:\\win32testserv.log";
    print FOUT "Jetzt ist aber schluss\n";
    close FOUT;
    exit 0;
  }	
}

Win32::Daemon::StopService();
Win32::Daemon::State(SERVICE_STOPPED);
