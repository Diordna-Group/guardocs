#!perl

# Service for Weita - v1.1 - (c) 3.6.2004 by Archivista GmbH, Urs Pfister
# Anpassungen by Archivista GmbH, Markus Stocker

use strict;
use Win32::Daemon;
Win32::Daemon::StartService();



# ---------- Allgemeine Variablen 
my $perl = "perl"; #Perl
# -----------------------------------------------
# Werden hier nicht gebraucht
my $av5 = "Av5.exe";  #Archvista
my $host = "localhost";
my $db = "root";
my $user = "SYSOP";
my $pw = "*****";
my $log = ">>d:\\archiv\\code\\doit.log"; # Datei für Logs
my $warten = 1; # Warte-Zeit in Sekunden zwischen den Jobs
my $mailprg = "c:\\blat\\blat.exe"; #Mailprogramm
my $mailto = "-t abrunner\@kisling.com,webmaster\@archivista.ch -s Archivista";
my $servstart = "c:\\blat\\start.txt"; #Nachricht Dienst gestartet
my $servstop =  "c:\\blat\\stop.txt"; #Nachricht Dienst beendet

# ---------- Pfade, die wir verwenden
my $pfad_avprg = "C:\\Programme\\Av5d\\";

# ---------- Jobs, die wir aus dem Dienst heraus aufrufen wollen
my %jobs;

# Definition der Skripten fuer Jobs
$jobs{etik} = "perl d:\\archiv\\code\\etik.pl";
$jobs{update} = "perl d:\\archiv\\code\\update.pl";


# Dienst wird gestartet
while (SERVICE_START_PENDING != Win32::Daemon::State()) {
  sleep(1);
}

Win32::Daemon::State(SERVICE_RUNNING);

my $status_autofill = 1; 
my $mess = "Service was started";
my $res = 1;
do_log($log,$mess);
do_mail($mailprg,$mailto,$servstart);


# falls Archivista-Verzeichnis-Sprung ok war, dann Jobs abarbeiten
while ($res==1) {
  # Dienst ist ok, jetzt arbeiten wir

  # Stunde bestimmen
  my (undef,undef,$hour) = localtime();
  
  # HAUPTSCHLEIFE
  # do_jobs(\%jobs,$hour,\$status,$log,\$status_autofill);

  # Warten, bis zm nächsten Aufruf
  my $c2=0;
  for(my $c=0;$c<$warten;$c++) {

    my $res=do_jobs_doit($jobs{etik},"Print labels",$log);
    sleep 1;
    $c2++;
    if ((($c2 % 450) == 0) || (($c2 % 450) == 1)) {
      my $res=do_jobs_doit($jobs{update},"Add field information",$log);
      $c2=0;;
    }

    if (Win32::Daemon::State() == SERVICE_STOP_PENDING) {
      $mess = "Service was stopped";
      do_log($log,$mess);
      do_mail($mailprg,$mailto,$servstop);
      exit 0;
    }
  }	
}

# Dienst wurde gestoppt, Aufräumen
Win32::Daemon::StopService();
Win32::Daemon::State(SERVICE_STOPPED);






# wir führen den Job aus und schreiben eine Log-Datei
sub do_jobs_doit {
  my $job = shift;
  my $mess = shift;
  my $log = shift;
  my $res=system($job);
  $mess = "$res -- " . localtime() . " -- $mess";
  do_log($log,$mess);
  return $res;
}






# Mail versenden wenn Dienst gestartet bzw. beendet wird
sub do_mail {
  my $mailprg = shift;
  my $mailto = shift;
  my $mailmsg = shift;
  system("$mailprg $mailmsg $mailto");
  return 1;
}







# Meldung in Logdatei speichern
sub do_log {
  my $datei = shift;
  my $mess = shift;
  open(FOUT,$datei);
  print FOUT "$mess\n";
  close(FOUT);
}


