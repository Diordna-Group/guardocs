#!/usr/bin/perl

=head1 20050919 Testing V1.1 Nuridini Rijad, Archivista GmbH

  Diese Programm ist zum testen ob Die Archivistabox einen Dauertest übersteht.
	Es wird automtaisch ein ssh Key generiert, falls keiner vorhanden ist.
	Der Archivistabox wird eine IP zugeteilt im Bereich 192.168.0.211-254.
	Die Datenbank wird für Den OCR-Prozess vorbereitet.
	Führt die OCR durch.
	Pingt Alle Rechner im Bereich 192.168.0.211-254 und schreibt das Ergebniss in
	das Logfile

=cut

use strict;
use DBI;

my $nokeys = shift;
my $log="/home/data/archivista/testing.log";
my $sysdir="/etc/ssh";

if ($nokeys eq '') {
  # Generiere Keys und starte ssh
  ssh_key();
  # Holt sich seine Eigene IP-Adresse
  get_ip();
}

# Setzt JobsRecognition auf 1
prepare_db();
while (1) {
  # Setzt bei allen Archivseiten Erfasst auf 0
  # Setzt bei allen Akten Gesperrt auf "createocr"
  # Fuehrt avocr-do.pl aus
  ocr_loop();

  # Ping alle IP's von 192.168.0.211 bi 254
  # Schreibt das Ergebniss ins Log-File
  ping_range(211,254);
}

#------------------------------------------------------------------------------

=head2 ssh_key

  Überprüft ob im $sysdir die Files ssh_host_key,ssh_host_dsa_key und
	ssh_host_rsa_key existieren. Falls nicht werden diese Files erstellt.
	Dannach wird für alle Files Leseberechtigung gegeben.
	Und als letztes wird der Daemon gestartet.

=cut

sub ssh_key{
  # Fals ssh_host_key nicht existiert wird dieser erstellt
  if(! -e "$sysdir/ssh_host_key"){
    system("ssh-keygen -t rsa1 -f $sysdir/ssh_host_key -C '' -N ''");
	}
  # Fals ssh_host_dsa_key nicht existiert wird dieser erstellt
  if(! -e "$sysdir/ssh_host_dsa_key"){
    system("ssh-keygen -t dsa -f $sysdir/ssh_host_dsa_key -C '' -N ''");
	}
  # Fals ssh_host_rsa_key nicht existiert wird dieser erstellt
  if(! -e "$sysdir/ssh_host_rsa_key"){
    system("ssh-keygen -t rsa -f $sysdir/ssh_host_rsa_key -C '' -N ''");
	}
	# Verteilt die Rechte für die Files
  system("chmod 600 $sysdir/ssh_host*_key");
  system("chmod 644 $sysdir/ssh_host*_key.pub");
	# Startet den ssh daemon
  system("rc sshd start");
}

#------------------------------------------------------------------------------

=head2 get_ip

  Nimmt als Standard IP 192.168.0.210. Mit dieser IP überprüft er welche der
	Nachfolgenden noch frei sind. Die erste frei IP wird für diese Archivstabox 
	genommen.

=cut

sub get_ip{
  my $base="192.168.0.";
  my $tip="210";
	my $ip;
	# Eventuelle vorherige Konfiguration wird heruntergefahren
  eval(system("ifconfig eth0 down"));
	# Gibt das Ergebniss von ifconfig aus
  print `ifconfig`;
	# Meldung Das die Standard IP genommen wird. (192.168.0.210)
  print "give the system ip $base$tip\n";
  eval(system("ifconfig eth0 $base$tip up"));
  do {
	  $tip++;
    my $temp="$base$tip";
		print "try $temp as next free ip\n";
		# Pingt die Temporäre IP
    my $res=system("ping -c 2 $temp");
		if ($res!=0) {
      $ip=$temp;
    }
  } until ($ip ne '');
	# Standardt IP "herunterfahren"
	system("ifconfig eth0 down");
	# Neue IP annehmen
  system("ifconfig eth0 $ip up");
}

#------------------------------------------------------------------------------

=head2 prepare_db

  Setzt JobsOCRREcognition auf 1

=cut

sub prepare_db{
 # Verbinde mit MySQL
 my $dbh=DBI->connect("DBI:mysql:archivista","root","archivista");
 # Setzte JobsOCRRecognition auf 1
 my $sql = q(update parameter set Inhalt=1 where Name like "JobsOCRREcognition");
 $dbh->do($sql);
 # Beende Verbindung mit MySQL
 $dbh->disconnect();
}

#------------------------------------------------------------------------------

=head2 ocr_loop

  Setzt bei allen Seiten Erfasst auf 0, damit bei dieser wieder die OCR
	durchläuft. Setzt Gesperrt auf createocr, dient dazu damit das Programm
	(avocr) weiss welche akten Erfasst werden sollen. Startet avocr.

=cut

sub ocr_loop{
  my $dbh=DBI->connect("DBI:mysql:archivista","root","archivista");
	# Setzte Erfasst auf 0 damit die OCR gestartet werden kann.
	$dbh->do("update archivseiten set Erfasst=0") 
	   or 
	print "Konnte Erfasst nicht auf 0 setzten";
	# Setzte Gesperrt auf createocr damit das Programm weiss welche Akten
	# für die OCR gedacht sind.
	$dbh->do("update archiv set BildInput=1,Gesperrt='createocr'")
	  or
	print "Konnte Gesperrt nicht auf creatocr setzten";
	$dbh->disconnect();
	# OCR Erkennung wird durchgeführt
  my $ocrdo = qq(/bin/su - archivista -c ". /etc/profile;export DISPLAY=:0;cd /home/archivista/.wine/drive_c/Programs/Av5e;wine avocr.exe -f 1 -o ocr -a");
	system($ocrdo);
  $ocrdo = qq(/bin/su - archivista -c ". /etc/profile;export DISPLAY=:0;cd /home/archivista/.wine/drive_c/Programs/Av5e;wine avocr.exe -f 2 -o ocr -a");
	system($ocrdo);
}

#------------------------------------------------------------------------------

=head2 timestamp

  Gibt einen Zeitstempel im Gewünschten Format aus.
	z.B. 20050919150005

=cut

sub timestamp{
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

#------------------------------------------------------------------------------

=head2 Log

  Speichert die Übergebene Message in das Logfile.

=cut

# Speichert die Message in das Logfile
sub Log{
  my $stamp = timestamp();
  my $message = shift;
  open(FOUT,">>$log");
  binmode(FOUT);
  my $logtext = $0 ." " . $stamp . " " . $message . "\n";
  print FOUT $logtext;
  close(FOUT);
}

#------------------------------------------------------------------------------

=head2 check_ip

  Überprüft ob das IP-Stück einen Wert von 0 bis 255 hat. Wenn nicht wird der
	Wert entweder auf 0 oder auf 255 gesetzt.

=cut

# Überprüft ob die IP im gültigen Wertebereich ist (0-255)
sub check_ip{
  my $in=shift;
  if($in <0){
    $in=0;
  } else {
    if($in >= 255){
		  $in=255;
    }
  }
	return($in);
}

#------------------------------------------------------------------------------

=head2 check_log



=cut

# Überprüft ob die IP im gültigen Wertebereich ist (0-255)
sub check_log{
  if(! -x $log){
    system("touch $log");
	}
}
#------------------------------------------------------------------------------

=head2 ping_range

  Pingt Alle IP's von $start bis $end und Schreibt das Ergebniss in das Logfile

=cut

sub ping_range{
  my $start = shift;
	my $end = shift;
	check_log();
	$start=check_ip($start);
	$end=check_ip($end);

  # Pingt alle IP's von $start bis $end

	while($start != $end){
    my $ip = '192.168.0.'.$start;
    if(system("ping -w 2 $ip 1>/dev/null")){
		  Log("$ip down");
    } else {
      Log("$ip up");
    }
	  $start++;
	}
}
