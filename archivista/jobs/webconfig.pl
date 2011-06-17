#!/usr/bin/perl

=head1 webconfig.pl (c) 21.04.2008 by Archivista GmbH, Rijad Nuridini

This script reads the parameter from database and starts depending on the
parameter the right bash script.

=cut

use strict;

# DBI data for jobs table
my (%val,%jobs);
$val{jobid} = shift; # the id from the jobs table
logit("startet $0 with $val{jobid}\n");
$val{ds} = '/'; # directory separator (/ or \\)
$val{log} = '/home/data/archivista/av.log';

use constant BASH_DIR => '/home/archivista';

use constant KEYBOARD => 'KEYBOARD';
use constant BASH_KBD => BASH_DIR.'/kbd.sh';
$jobs{KEYBOARD} = BASH_KBD;

use constant LANG => 'LANG';
use constant BASH_LANG => BASH_DIR.'/lang.sh';
$jobs{LANG} = BASH_LANG;

use constant TIME => 'TIME';
use constant BASH_TIME => BASH_DIR.'/time.sh';
$jobs{TIME} = BASH_TIME;

use constant NETWORK => 'NETWORK';
use constant BASH_NET => BASH_DIR.'/network.sh';
$jobs{NETWORK} = BASH_NET;

use constant CUPS_EN => 'CUPS_EN';
use constant BASH_CUPS_EN => BASH_DIR.'/cups-setup.sh';
$jobs{CUPS_EN} = BASH_CUPS_EN;

use constant CUPS_DIS => 'CUPS_DIS';
use constant BASH_CUPS_DIS => BASH_DIR.'/cups-disable.sh';
$jobs{CUPS_DIS} = BASH_CUPS_DIS;

use constant FTP_EN => 'FTP_EN';
use constant BASH_FTP_EN => BASH_DIR.'/ftp-enable.sh';
$jobs{FTP_EN} = BASH_FTP_EN;

use constant FTP_DIS => 'FTP_DIS';
use constant BASH_FTP_DIS => BASH_DIR.'/ftp-disable.sh';
$jobs{FTP_DIS} = BASH_FTP_DIS;

use constant MAILS_EN => 'MAILS_EN';
use constant BASH_MAILS_EN => BASH_DIR.'/mail-enable.sh';
$jobs{MAILS_EN} = BASH_MAILS_EN;

use constant MAILS_DIS => 'MAILS_DIS';
use constant BASH_MAILS_DIS => BASH_DIR.'/mail-disable.sh';
$jobs{MAILS_DIS} = BASH_MAILS_DIS;

use constant MAILS_DO => 'MAILS_DO';
use constant BASH_MAILS_DO => BASH_DIR.'/mail-do.sh';
$jobs{MAILS_DO} = BASH_MAILS_DO;

use constant OCR => 'OCR';
use constant BASH_OCR => BASH_DIR.'/avocr.sh';
$jobs{OCR} = BASH_OCR;

use constant SSH_EN => 'SSH_EN';
use constant BASH_SSH_EN => BASH_DIR.'/ssh-enable.sh';
$jobs{SSH_EN} = BASH_SSH_EN;

use constant SSH_DIS => 'SSH_DIS';
use constant BASH_SSH_DIS => BASH_DIR.'/ssh-disable.sh';
$jobs{SSH_DIS} = BASH_SSH_DIS;

use constant VNC_EN => 'VNC_EN';
use constant BASH_VNC_EN => BASH_DIR.'/vnc-enable.sh';
$jobs{VNC_EN} = BASH_VNC_EN;

use constant VNC_DIS => 'VNC_DIS';
use constant BASH_VNC_DIS => BASH_DIR.'/vnc-disable.sh';
$jobs{VNC_DIS} = BASH_VNC_DIS;

use constant CHPASSWD => 'CHPASSWD';
use constant BASH_CHPASSWD => BASH_DIR.'/chpasswd.sh';
$jobs{CHPASSWD} = BASH_CHPASSWD;

use constant PWDRESET => 'PWDRESET';
use constant BASH_PWDRESET => BASH_DIR.'/passwordreset.sh';
$jobs{PWDRESET} = BASH_PWDRESET;

use constant BACKUP_SET => 'BACKUP_SET';
use constant BASH_BACKUP_SET => BASH_DIR.'/backup-setup.sh';
$jobs{BACKUP_SET} = BASH_BACKUP_SET;

use constant NET_BACKUP_SET => 'NET_BACKUP_SET';
use constant BASH_NET_BACKUP_SET => BASH_DIR.'/net-backup-setup.sh';
$jobs{NET_BACKUP_SET} = BASH_NET_BACKUP_SET;

use constant RSYNC_BACKUP_SET => 'RSYNC_BACKUP_SET';
use constant BASH_RSYNC_BACKUP_SET => BASH_DIR.'/rsync-backup-setup.sh';
$jobs{RSYNC_BACKUP_SET} = BASH_RSYNC_BACKUP_SET;

use constant USB_BACKUP_SET => 'USB_BACKUP_SET';
use constant BASH_USB_BACKUP_SET => BASH_DIR.'/usb-backup-setup.sh';
$jobs{USB_BACKUP_SET} = BASH_USB_BACKUP_SET;

use constant BACKUP => 'BACKUP';
use constant BASH_BACKUP => BASH_DIR.'/backup.sh';
$jobs{BACKUP} = BASH_BACKUP;

use constant NET_BACKUP => 'NET_BACKUP';
use constant BASH_NET_BACKUP => BASH_DIR.'/net-backup.sh';
$jobs{NET_BACKUP} = BASH_NET_BACKUP;

use constant RSYNC_BACKUP => 'RSYNC_BACKUP';
use constant BASH_RSYNC_BACKUP => BASH_DIR.'/rsync-backup.sh';
$jobs{RSYNC_BACKUP} = BASH_RSYNC_BACKUP;

use constant USB_BACKUP => 'USB_BACKUP';
use constant BASH_USB_BACKUP => BASH_DIR.'/usb-backup.sh';
$jobs{USB_BACKUP} = BASH_USB_BACKUP;

use constant LOGIN_SET => 'LOGIN_SET';
use constant BASH_LOGIN_SET => BASH_DIR.'/login-setup.sh';
$jobs{LOGIN_SET} = BASH_LOGIN_SET;

use constant BUTTON_SET => 'BUTTON_SET';
use constant BASH_BUTTON_SET => BASH_DIR.'/button-setup.sh';
$jobs{BUTTON_SET} = BASH_BUTTON_SET;

use constant DOC_UNLOCK => 'DOC_UNLOCK';
use constant BASH_DOC_UNLOCK => BASH_DIR.'/doc-unlock.sh';
$jobs{DOC_UNLOCK} = BASH_DOC_UNLOCK;

use constant OCR_SERVER_RESTART => 'OCR_SERVER_RESTART';
use constant BASH_OCR_SERVER_RESTART => BASH_DIR.'/avocr-restart.sh';
$jobs{OCR_SERVER_RESTART} = BASH_OCR_SERVER_RESTART;

use constant OCR_DOC_RESTART => 'OCR_DOC_RESTART';
use constant BASH_OCR_DOC_RESTART => BASH_DIR.'/ocrNow.sh';
$jobs{OCR_DOC_RESTART} = BASH_OCR_DOC_RESTART;

use constant SPHINX_INDEX => 'SPHINX_INDEX';
use constant SPHINX_CALL=>'/usr/bin/perl '.
                          '/home/cvs/archivista/jobs/sphinxit.pl indexall';
$jobs{SPHINX_INDEX} = SPHINX_CALL;

use constant SPHINX_START => 'SPHINX_START';
use constant SPHINX_CALL2=>'/usr/bin/perl '.
                          '/home/cvs/archivista/jobs/sphinxit.pl start';
$jobs{SPHINX_START} = SPHINX_CALL2;

use constant SHUTDOWN => 'SHUTDOWN'; 
$jobs{SHUTDOWN} = BASH_DIR.'/exit.sh';

use constant NETWORKRESET => "NETWORKRESET";
$jobs{NETWORKRESET} = "/etc/init.d/networking restart";

use constant SECONDARYBACKUP => "SECONDARYBACKUP";
$jobs{SECONDARYBACKUP} = "perl /home/cvs/archivista/jobs/clusterbackup.pl";

use constant CLUSTERVMUP => "CLUSTERVMUP";
$jobs{CLUSTERVMUP} = "perl /home/cvs/archivista/jobs/clustervmup.pl";


if ($val{jobid}==0) {
  if (-e $val{jobid}) {
	  open(FIN,$val{jobid});
		my @lines = <FIN>;
		my $mode = shift @lines;
		chomp $mode;
    my $presult = {};
		foreach my $line (@lines) {
		  my @parts = split("=",$line);
			my $key = shift @parts;
			my $value = join("=",@parts);
			chomp $key;
			chomp $value;
			$presult->{$key} = $value;
    }
	  if (isKnownJob($mode)) {
	    # Get Programm from hash if job is known
	    my $programm = $jobs{$mode};
		  logit("starting programm: $programm");
	    exportVariable($presult);
			if ($mode eq SECONDARYBACKUP) {
			  system("$programm ".$presult->{resource}." ".
                                  $presult->{ip}." ".$presult->{options});
			} elsif ($mode eq CLUSTERVMUP) {
			  system("$programm ".$presult->{options});
			} else {
		    system("$programm -webconfig");
			}
	  } else {
	    logit("'$mode' is not a known job.");
	  }
	} else {
	  logit("file '$val{jobid}' not found.");
	}
} else {
  eval { 
	  require DBI;
    require Archivista::Config; # needed for the passwords
    my $config = Archivista::Config->new;
    $val{host} = $config->get("MYSQL_HOST");
    $val{db} = $config->get("MYSQL_DB");
    $val{user} = $config->get("MYSQL_UID");
    $val{pw} = $config->get("MYSQL_PWD");
    undef $config;
    if ( MySQLOpen( \%val ) ) {
      my $presult = selectValues(\%val);
	    my $mode = $presult->{WEBC_MODE};
	    if (isKnownJob($mode)) {
	      # Get Programm from hash if job is known
	      my $programm = $jobs{$mode};
		    logit("starting programm: $programm");
	      exportVariable($presult);
		    system("$programm -webconfig");
	    } else {
	      logit("'$mode' is not a known job.");
	    }
		}
	}
}






=head2 1/0=isKnownJob($mode)

Is the mode we have in the jobs list?

=cut

sub isKnownJob {
  my $mode = shift;
	# List of all Possible Jobs
	my @jobs = (KEYBOARD, LANG, TIME, NETWORK, CUPS_EN, CUPS_DIS, 
	            FTP_EN, FTP_DIS, OCR, MAILS_EN, MAILS_DIS, MAILS_DO,
	            SSH_EN, SSH_DIS, VNC_EN, VNC_DIS, OCR_DOC_RESTART,
							CHPASSWD, PWDRESET, BACKUP_SET, NET_BACKUP_SET, RSYNC_BACKUP_SET,
							USB_BACKUP_SET, BACKUP, NET_BACKUP, RSYNC_BACKUP, USB_BACKUP,
							LOGIN_SET, BUTTON_SET, DOC_UNLOCK, OCR_SERVER_RESTART, 
							SPHINX_INDEX, SPHINX_START, SHUTDOWN, NETWORKRESET,
							SECONDARYBACKUP, CLUSTERVMUP,
							);
	foreach my $job (@jobs) {
	  # if job in the list return 1.
		return 1 if ($job eq $mode);
	}
	# else return 0
	return 0;
}






=head2 exportVariable(\%variables)

Export every variable to the envoirement.

=cut

sub exportVariable {
  my $pvar = shift;
	foreach my $key (keys %$pvar) {
	  # Do not export mode we don't need it in bash
	  next if $key eq 'WEBC_MODE';
		$ENV{$key} = $pvar->{$key};
		#logit("exported $key ".$pvar->{$key});
	}
}






=head2 $dbh=MySQLOpen(%$val)

Open a MySQL connection and gives back a db handler

=cut

sub MySQLOpen {
  my $pval = shift;
  my ($ds);
  $ds = "DBI:mysql:host=$$pval{host};database=$$pval{db}";
  $$pval{dbh} = DBI->connect( $ds, $$pval{user}, $$pval{pw},
                            { RaiseError => 0, PrintError => 0 } );
  logit("DBConnection failed") if !defined $$pval{dbh};
  return $$pval{dbh};
}






=head2 logit($message)

Writes a message to a log file

=cut

sub logit {
  my $stamp  = TimeStamp();
  my $message = shift;
  # $log file name comes from above
  open( FOUT, ">>$val{log}" );
  binmode(FOUT);
  my $logtext = $0 . " " . $stamp . " " . $message . "\n";
  print FOUT $logtext;
  close(FOUT);
}






=head2 $stamp=TimeStamp 

Actual date/time stamp (20040323130556)

=cut

sub TimeStamp {
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y = $t[5] + 1900;
  $m = $t[4] + 1;
  $m = sprintf( "%02d", $m );
  $d = sprintf( "%02d", $t[3] );
  $h = sprintf( "%02d", $t[2] );
  $mi = sprintf( "%02d", $t[1] );
  $s = sprintf( "%02d", $t[0] );
  $stamp = $y . $m . $d . $h . $mi . $s;
  return $stamp;
}






=head1 \%vals=selectValues(\%val)

Return all parameter entries for jobid.

=cut

sub selectValues {
  my $pval = shift;
	my ($sql,$presult);
  $sql = "select param,value from jobs_data where jid=$$pval{jobid}";
  $presult = $$pval{dbh}->selectall_hashref($sql,'param');
	# Tidy up a bit for easyer access
	foreach my $key (keys %{$presult}) {
	  $presult->{$key} = $presult->{$key}{value};
	}
	return $presult;
}






