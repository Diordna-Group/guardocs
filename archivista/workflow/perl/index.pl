#!/usr/bin/perl

use strict;
use DBI;

use inc::Request;
use inc::Session;
use inc::Global;
use inc::AVDBConnect;
use inc::DESModule;
use inc::DB;
use inc::HTML;
use inc::Main;

my $request = new Request();
my $global = new Global();

my $host = $global->get('host');
my $db = $global->get('db');
my $uid = $request->get('uid');
my $mode = $request->get('mode');

$global->set('sid',getCookie("sid"));
$global->set('avdbh',AVConnect($global));

my (@cookies);
my $check_login = 0;

# Calculation of test time and workflow time for SQL query
time_calc($global);

if ((length($host) > 0) && (length($db) > 0) && (length($uid) > 0)) {
 	my $pwd = $request->get('pwd');
 	$global->set('uid',$uid);
 	$global->set('pwd',$pwd);
	my $dbh = dbhOpen($global);
	if (defined $dbh) {
		$check_login = 1;
		my $session = openSession($global);
		$global->set('cookie',setCookie("sid",$session));
		$global->set('dbh',$dbh);
	} else { 
		$check_login = 0;
		$global->set('error','Login error<br>Check username and password');
	}
} elsif (checkSID($global) && ($mode ne "logout")) {
	getUserParam($global);
	my $dbh = dbhOpen($global);
	$global->set('dbh',$dbh);
	$check_login = 1;
} elsif ($mode eq "logout") {
	$check_login = 0;
	closeSession($global);
}

my $return = header($global);
if ($check_login == 1) {
	$return .= main($global,$request);
	dbhClose($global->get('dbh'));
	dbhClose($global->get('avdbh'));
} else {
	$return .= login_form($global,$request);
}
$return .= footer();

print $return;

# -------------------------------------------------
# Functions

=head1 time_calc($global)

	IN: object(inc::Global)
	OUT: -

	Calculate the test-time and the workflow-time and save the values to the
	global object
	
=cut

sub time_calc
{
	my $global = shift;
	my $time = time();
	my $sec = 3600; # 1 hour in seconds
	my $dmt_hour = $global->get('dmt_hour');
	my $test_hour_faktor = $global->get('test_hour_factor');
	my $test_hour = $dmt_hour * $test_hour_faktor;
	my $dmt_sec = $dmt_hour * $sec;
	my $test_sec = $test_hour * $sec;
	my (undef,undef,undef,$day,$mon,$year) = localtime($time-$dmt_sec);
	$day = sprintf "%02d", $day;
	$mon = sprintf "%02d", $mon+1;
	$year += 1900;
	$global->set('dmt_time',"$year-$mon-$day");
	my (undef,undef,undef,$day,$mon,$year) = localtime($time-$test_sec);
	$day = sprintf "%02d", $day;
	$mon = sprintf "%02d", $mon+1;
	$year += 1900;
	$global->set('test_time',"$year-$mon-$day");	
}






