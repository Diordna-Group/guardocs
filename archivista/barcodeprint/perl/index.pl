#!/usr/bin/perl

# Current revision $Revision: 1.1.1.1 $
# Latest change by $Author: upfister $ on $Date: 2008/11/09 09:19:24 $

use strict;

use lib qw (/home/cvs/archivista/barcodeprint/perl);

use CGI::Carp qw(fatalsToBrowser);

use Gewa::lib::DB;
use Gewa::lib::Config;
use Gewa::lib::Session;
use Gewa::lib::Request;
use Gewa::Web::Main;

my ($dbm,$dbc);

my $session = new Gewa::lib::Session();
my $config = new Gewa::lib::Config();
my $request = new Gewa::lib::Request();

# Request param
my $sid = $request->value("sid");
my $host = $request->value("host");
my $db = $request->value("db");
my $uid = $request->value("uid");
my $pwd = $request->value("pwd");
my $mode = $request->value("mode");

# Master database connection data 
my $hostM = $config->getMyHost();
my $dbM = $config->getMyMasterDbName();
my $uidM = $config->getMyUser();
my $pwdM = $config->getMyPassword();
$dbm = new Gewa::lib::DB($hostM,$dbM,$uidM,$pwdM);

if ($mode eq "logout") {
  # Logout request
  $session->delete();
} elsif (length($host) > 0 && length($db) > 0 && length($uid) > 0) {
  # New login request, check authentification
  $dbc = $session->checkAuth($request);
  if (defined $dbc) {
    my $checkUserAccess = _checkUserAccess($dbc,$uid,$db);
    if ($checkUserAccess == 1) {
      # Open a connection to the master database
      # Authentification ok
      $session->open($request);
      $session->addUserSessionData($dbc);
    } elsif ($checkUserAccess == 0) {
      $session->set("error","Check user access");
    }
  } else {
    # Authentification not ok
    $session->set("error","Authentification error");
  }
} elsif ($session->checkIfExists($request) == 1) {
  my $dbC;
  # Check an existing session
  # Open the session
  $session->open($request);
  # Open a connection to the master and client database
  $host = $session->get("session_host");
  $dbC = $session->get("session_db");
  $uid = $session->get("session_uid");
  $pwd = $session->get("session_pwd");
  $dbc = new Gewa::lib::DB($host,$dbC,$uid,$pwd);
  $session->addUserSessionData($dbc);
} elsif (defined $host || defined $db || defined $uid || defined $pwd) {
  # Check params on login request
  $session->set("error","Error on login");
}

my $main = new Gewa::Web::Main($request,$config,$session,$dbm,$dbc);

$session->close();

$main->print();

# -----------------------------------------------
# LOCAL METHODS

sub _checkUserAccess
{
  my $dbc = shift;
  my $uid = shift;
  # Mod 2.2.2005 -> Test auf Default-Datum nur bei kk57
  my $db = shift;

  my $checkUserAccess = 1;
  my ($query,$sth,$zusatz);

  # Check user level and zusatz
  # Level must be 1 and length of zusatz > 0 
  # (contains the barcode printer IP)
  $query = "SELECT Level, Zusatz FROM user WHERE User=".$dbm->quote($uid);
  $sth = $dbc->query($query);
  $sth->execute();
  
  if ($sth->rows()) {
    while (my @row = $sth->fetchrow_array()) {
      $zusatz = $row[1];
      $checkUserAccess = 0 if ($row[0] != 1);
      $checkUserAccess = 0 if (length($zusatz) == 0);
    }
  } else {
    $checkUserAccess = 0;
  }
  
  $sth->finish();

  # Check if the barcode printer of the user
  # is configured on parameter table
  $query = "SELECT Inhalt FROM parameter WHERE Name='BarcodePrint'";
  $sth = $dbc->query($query);
  $sth->execute();

  if ($sth->rows()) {
    while (my @row = $sth->fetchrow_array()) {
      $checkUserAccess = 0 if (!($row[0] =~ /$zusatz/));
    }
  } else {
    $checkUserAccess = 0;
  }
  
  $sth->finish();

  # Check if a default value for datum ist set
  $query = "DESCRIBE archiv";
  $sth = $dbc->query($query);
  $sth->execute();

  while (my @row = $sth->fetchrow_array()) {
  
    my $defaultDatum = $row[4] if ($row[0] eq "Datum");
    if ($db eq "kk57") {
      if ($defaultDatum =~ /0000-00-00/) {
        # Mod 2.2.2005 -> nur kk57 testen
        $checkUserAccess = 0;
      }
    }
  }
  
  return $checkUserAccess;
}

# Log record
# $Log: index.pl,v $
# Revision 1.1.1.1  2008/11/09 09:19:24  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:23  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2006/03/06 09:35:55  up
# Archiving job and mask corrections (comp. RichClient)
#
# Revision 1.1  2005/11/21 10:40:43  ms
# Added to project
#
# Revision 1.6  2005/02/17 11:49:37  ms
# Import der Aenderungen auf dem gewa archivserver
#
# Revision 1.5  2005/01/21 15:59:16  ms
# New namespace Gewa
#
# Revision 1.4  2005/01/14 17:13:30  ms
# Version mit funktionierendem barcode print
#
# Revision 1.3  2005/01/10 15:34:36  ms
# Entwicklung (mittlerer Teil mit such formular)
#
# Revision 1.2  2005/01/07 18:10:03  ms
# Entwicklung
#
# Revision 1.1.1.1  2005/01/03 13:52:29  ms
# Import project
#
