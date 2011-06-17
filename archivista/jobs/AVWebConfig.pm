
=head1 AVWebConfig (c) 2008 by Archivista GmbH, Urs Pfister

Class for showing settings of ArchivistaBox

=cut

use strict;

package AVWebConfig;

use lib qw(/home/cvs/archivista/jobs);
use Wrapper;
use AVSession;
use AVWebElements;
use HTML::Table;
use AVStrings;
use Date::Calc qw(check_date check_time);

# Constants

use constant APP_TITLE => 'Archivista';
use constant APP_VERSION => '2010/IV';
use constant WWW_LINK => 'http://www.archivista.ch';
use constant POWEREDBY => '<br><font class="powered">Version ' .
                           APP_VERSION.' - Powered by ' .
                           '<a href="'.WWW_LINK.'">' .
                           'Archivista GmbH</a></font><br><br>';
use constant VALUE_SPLIT => "\t";
use constant ROW_SPLIT => "\n";
use constant AVFORM => 'avform';
use constant ACT_INDI => 'go_';
use constant LBL_LOGIN => 'Login';
use constant GO_LOGIN => ACT_INDI.'login';
use constant PRJ_FOLDER => '/languages/';
use constant IMG_FOLDER => PRJ_FOLDER.'pics/';
use constant IMG_LOGIN_HEADER => IMG_FOLDER.'login_header1.png';
use constant IMG_LOGIN_LEFT => IMG_FOLDER.'login_left.png';
use constant CSS_FILE => '/webconfig/css/webconfig.css';
use constant JS_FILE => '/webconfig/js/functions.js';

use constant PREFIX => 'WEBC_'; # all menu and form constants
use constant STATUS => PREFIX.'STATUS';
use constant SETTINGS => PREFIX.'SETTINGS';
use constant LOGINMASK => PREFIX.'LOGINMASK';
use constant SCANBUTTON => PREFIX.'SCANBUTTON';
use constant BACKUP => PREFIX.'BACKUP';
use constant BACKUPLOG => PREFIX.'BACKUPLOG';
use constant BACKUPNOW => PREFIX.'BACKUPNOW';
use constant DAEMON => PREFIX.'DAEMON';
use constant UNLOCK => PREFIX.'UNLOCK';
use constant PASSWORD => PREFIX.'PASSWORD';
use constant PASSWORDS => PREFIX.'PASSWORDS';
use constant LOGS => PREFIX.'LOGS';
use constant OCR => PREFIX.'OCR';
use constant DOWNLOAD => PREFIX.'DOWNLOAD';
use constant OCRREGISTER => PREFIX.'OCRREGISTER';
use constant LOGOUT => PREFIX.'LOGOUT';

use constant EXIT_MSG => PREFIX.'EXIT_MSG';
use constant EXIT_SHUTDOWN => PREFIX.'EXIT_SHUTDOWN';
use constant EXIT_RESTART => PREFIX.'EXIT_RESTART';
use constant EXIT_ASK => PREFIX.'EXIT_ASK';
use constant SHUTDOWN => PREFIX.'SHUTDOWN';
use constant RESTART => PREFIX.'RESTART';
use constant SHUTDOWNMODE => PREFIX.'SHUTDOWNMODE';

use constant SUBMIT => PREFIX.'SUBMIT';
use constant AVLOG => PREFIX.'AVLOG';
use constant OCRLOG => PREFIX.'OCRLOG';

use constant USB => PREFIX.'USB';
use constant KEEP => PREFIX.'KEEP';
use constant NETBACKUP => PREFIX.'NETBACKUP';
use constant MAILS => PREFIX.'MAILS';
use constant MAILS_EN => PREFIX.'MAILS_EN';
use constant MAIL_EN_DAY => PREFIX.'MAIL_EN_DAY';
use constant MAIL_EN_TIME => PREFIX.'MAIL_EN_TIME';
use constant MAILS_DO => PREFIX.'MAILS_DO';
use constant MAILS_DO_MESSAGE => PREFIX.'MAILS_DO_MESSAGE';

use constant RSYNC => PREFIX.'RSYNC';
use constant TAPEBACKUP => PREFIX.'TAPEBACKUP';
use constant BACKUP_TYPE => PREFIX.'BACKUP_TYPE';
use constant F_USB => "/etc/usb-backup-webconfig.conf";
use constant F_NET => "/etc/net-backup-webconfig.conf";
use constant F_RSYNC => "/etc/rsync-backup-webconfig.conf";
use constant F_TAPE => "/etc/backup-webconfig.conf";
use constant LAYOUT => PREFIX.'LAYOUT';
use constant KBDLAYOUT => PREFIX.'KBDLAYOUT';
use constant LANG => PREFIX.'LANG';
use constant LANGEXIT => PREFIX.'LANGEXIT';
use constant NETWORK => PREFIX.'NETWORK';
use constant DHCP => PREFIX.'DHCP';
use constant IP => PREFIX.'IP';
use constant GW => PREFIX.'GW';
use constant GWON => PREFIX.'GWON';
use constant NS => PREFIX.'NS';
use constant NSON => PREFIX.'NSON';
use constant NETWORK_MESSAGE => PREFIX.'NETWORK_MESSAGE';
use constant DATETIME => PREFIX.'DATETIME';
use constant TIMEAREA => PREFIX.'TIMEAREA';
use constant TIMEZONE => PREFIX.'TIMEZONE';
use constant ONLYLOCAL => PREFIX.'ONLYLOCAL';
use constant ONLYDEFDB => PREFIX.'ONLYDEFDB';
use constant LOGINHOST => PREFIX.'LOGINHOST';
use constant LOGINDB => PREFIX.'LOGINDB';
use constant LOGINUSER => PREFIX.'LOGINUSER';
use constant HOST => PREFIX.'HOST';
use constant DB => PREFIX.'DB';
use constant USER => PREFIX.'USER';
use constant PASSWD => PREFIX.'PASSWD';
use constant NEWPASSWD => PREFIX.'NEWPASSWD';
use constant PASSWD_FIRST => PREFIX.'PASSWD_FIRST';
use constant PASSWD_SECOND => PREFIX.'PASSWD_SECOND';
use constant AVB_EN => PREFIX.'AVB_EN';
use constant LOGINMASK_MESSAGE => PREFIX.'LOGINMASK_MESSAGE';
use constant DAYS => PREFIX.'DAYS';
use constant TIME => PREFIX.'TIME';
use constant SERVER => PREFIX.'SERVER';
use constant SHARE => PREFIX.'SHARE';
use constant DOMAIN => PREFIX.'DOMAIN';
use constant TYPE => PREFIX.'TYPE';
use constant CUPS => PREFIX.'CUPS';
use constant CUPS_EN => PREFIX.'CUPS_EN';
use constant CUPS_RANGE => PREFIX.'CUPS_RANGE';
use constant FTP => PREFIX.'FTP';
use constant FTP_EN => PREFIX.'FTP_EN';
use constant SSH => PREFIX.'SSH';
use constant SSH_EN => PREFIX.'SSH_EN';
use constant VNC => PREFIX.'VNC';
use constant VNC_EN => PREFIX.'VNC_EN';
use constant RANGE => PREFIX.'RANGE'; 
use constant RANGE_DOC => PREFIX.'RANGE_DOC'; 
use constant UNLOCK_MESSAGE => PREFIX.'UNLOCK_MESSAGE';
use constant PERMANENT => PREFIX.'PERMANENT';
use constant PWSET_MESSAGE => PREFIX.'PWSET_MESSAGE';
use constant ROOTPW => PREFIX.'ROOTPW';
use constant CHPASSWD => PREFIX.'CHPASSWD';
use constant RESETPW => PREFIX.'RESETPW';
use constant MODE => PREFIX.'MODE';
use constant JOB => 'WEBCONF';

use constant OCR_SERVER => PREFIX.'OCR_SERVER'; 
use constant OCR_REGISTERED => PREFIX.'OCR_REGISTERED';
use constant OCR_MESSAGE => PREFIX.'OCR_MESSAGE';
use constant FILE => PREFIX.'FILE';
use constant OCR_RESTART => PREFIX.'OCR_RESTART';
use constant OCR_DOCRESTART => PREFIX.'OCR_DOCRESTART';
use constant OCRSERVERRESTART_MESSAGE => PREFIX.'OCRSERVERRESTART_MESSAGE';
use constant OCRDOCRESTART_MESSAGE => PREFIX.'OCRDOCRESTART_MESSAGE';

use constant ERR_NOFILEDATA => 'ERR_NOFILEDATA';
use constant ERR_RANGE => 'ERR_RANGE';
use constant GERMAN => 'Deutsch';
use constant ENGLISH => 'English';
use constant FRENCH => 'Français';
use constant ITALIAN => 'Italiano';


use constant BACKUPSTART => PREFIX.'BACKUPSTART';
use constant WARN => PREFIX.'WARN';
use constant CHANGES_OK => PREFIX.'CHANGES_OK';
use constant JOBERROR => PREFIX.'JOBERROR';
use constant NODB => PREFIX.'NODB';
use constant NOACCESS => PREFIX.'NOACCESS';
use constant UNLOCK_OK => PREFIX.'UNLOCK_OK';

use constant CHECK_OK => 4; # check if action was sucessfully (seconds)
use constant CHECK_NO => 0; # don't check it
use constant CHECK_EXIT => -1; # exit after starting job


sub session {wrap(@_)} # session object
sub action {wrap(@_)} # menu or action (submit button)
sub form {wrap(@_)} # the form to go according menu/action
sub cgi { wrap(@_) } # WebElements for generating HTML
sub title {wrap(@_)} # title of application
sub lang {wrap(@_)} # language of application

# Define all main Menus (if + at the end, it will be showed as a submenu)
my @menu = qw(WEBC_STATUS WEBC_SETTINGS WEBC_LOGINMASK+
              WEBC_SCANBUTTON+ WEBC_BACKUP WEBC_BACKUPNOW+
					    WEBC_BACKUPLOG+ WEBC_DAEMON WEBC_UNLOCK
							WEBC_PASSWORDS WEBC_LOGS WEBC_OCR WEBC_EXIT_MSG WEBC_LOGOUT);






=head2 $object=AVWebConfig->new($title)

Create the WebConfig object given a title

=cut

sub new {
  my $class = shift;
  my ($title) = @_;
  my $self = {};
	bless $self,$class;
  $self->session(AVSession->new("webconfig"));
  my $lang = $self->session->param('lang');
	my $code = "en";
	$code = "de" if $lang eq GERMAN;
	$code = "fr" if $lang eq FRENCH;
	$code = "it" if $lang eq ITALIAN;
	$self->lang($lang);
	$self->title($self->APP_TITLE);
	$self->title($self->title()." ".$title) if $title ne "";
	if ($self->session) {
	  $self->cgi(AVWebElements->new(AVStrings->new("$code",'database')));
	}
  $self->getAction() if $self->session->cookie;
	return $self;
}






=head2 doAction

Check if we are logged in and if yes, call the action (if there is one)

=cut

sub doAction {
  my $self = shift;
	my $loggedin = 0;
	if (-e '/etc/nowebconfig.conf') {
		$self->session->message(NOACCESS);
	} else {
    if ($self->session->cookie && $self->cgi && $self->session->ses) {
      if ($self->session->ses->isArchivistaMain) {
			  my $pfields = ["sid"];
			  my $pvals = [$self->session->cookie];
		    my @vals = $self->session->ses->search($pfields,$pvals,"sessions");
			  if ($vals[0] eq $self->session->cookie && 
			      $self->session->ses->def_pw eq $self->session->pw) {
		      $loggedin = 1;
		      if ($self->doActionMain()==0) { # job error
				    if ($self->session->message eq "") { # so far we have no error msg
					    $self->session->message(JOBERROR);
					  }
				  }
			  } else {
				  if ($self->session->pw ne "") {
				    $self->session->message('MSG_IMG_NOCONNECT');
				  }
        }
		  } else {
		    $self->session->message(NODB);
		  }
    } else {
		  $self->session->message(NODB);
	  }
	}
  return $loggedin;
}






=head2 doActionMain

Check for a job and if found, call it in jobs table

=cut

sub doActionMain {
  my $self = shift;
	my $ok = 1;
	if ($self->action eq 'action') {
    if ($self->form eq UNLOCK) {
      $ok=$self->doActionUnlock; 
		} elsif ($self->form eq KBDLAYOUT) {
		  $ok=$self->doActionStart('KEYBOARD',CHECK_OK,{kbd_layout=>LAYOUT});
			$self->form(SETTINGS);
		} elsif ($self->form eq LANG) {
		  $ok=$self->doActionStart('LANG',CHECK_EXIT,{language=>LANG});
			$self->form(SETTINGS);
    } elsif ($self->form eq NETWORK) {
		  $ok=$self->doActionNetwork();
	  } elsif ($self->form eq DATETIME) {
		  $ok=$self->doActionDateTimeZone();
		} elsif ($self->form eq LOGINMASK) {
		  $ok=$self->doActionLoginmask();
		} elsif ($self->form eq SCANBUTTON) {
		  $ok=$self->doActionScanButton();
		} elsif ($self->form eq SHUTDOWN) {
	    $self->session->param_set("mode",1);
		  $ok=$self->doActionStart('SHUTDOWN',CHECK_EXIT,{mode=>SHUTDOWNMODE});
		} elsif ($self->form eq RESTART) {
	    $self->session->param_set("mode",2);
		  $ok=$self->doActionStart('SHUTDOWN',CHECK_EXIT,{mode=>SHUTDOWNMODE});
		} elsif ($self->form eq USB) {
		  $ok=$self->doActionBackupUSB;
		} elsif ($self->form eq NETBACKUP) {
	    $ok=$self->doActionBackupNetwork;	
		} elsif ($self->form eq RSYNC) {
	    $ok=$self->doActionBackupRsync;
		} elsif ($self->form eq TAPEBACKUP) {
		  $ok=$self->doActionBackupTape;
		} elsif ($self->form eq BACKUPNOW) {
	    $ok=$self->doActionBackupNow;	
		} elsif ($self->form eq CUPS) {
		  $ok=$self->doActionCups;
		} elsif ($self->form eq FTP) {
		  $ok=$self->doActionFTP;
		} elsif ($self->form eq SSH) {
      $ok=$self->doActionSSH;		
		} elsif ($self->form eq VNC) {
      $ok=$self->doActionVNC;		
		} elsif ($self->form eq OCRREGISTER) {
      my $ppar = {server=>DOWNLOAD,file=>FILE,password=>PASSWD};
	    $ok = $self->doActionStart('OCR',CHECK_OK,$ppar);
	    $self->form(OCR);
		} elsif ($self->form eq MAILS_DO) {
		  $ok=$self->doActionStart('MAILS_DO',CHECK_OK,{});
			$self->form(DAEMON);
		} elsif ($self->form eq OCR_RESTART) {
		  $ok=$self->doActionStart('OCR_SERVER_RESTART',CHECK_OK,{});
			$self->form(OCR);
		} elsif ($self->form eq OCR_DOCRESTART) {
		  $ok=$self->doActionRestartOCR;
		} elsif ($self->form eq CHPASSWD) {
		  $ok=$self->doActionChpasswd;
		} elsif ($self->form eq RESETPW) {
		  $ok=$self->doActionStart('RESETPW',CHECK_OK,{user1=>USER});
			$self->form(PASSWORDS);
		} elsif ($self->form eq MAILS) {
	    $ok=$self->doActionMails;	
    }
	}
	return $ok;
}






=head2 doActionRestartOCR

Does start the ocr job again

=cut

sub doActionRestartOCR {
  my $self = shift;
	my $ok = 0;
	my $range = $self->session->param('range');
	if ($self->_checkRange($range)) {
   	my $ppar = {host1=>HOST,db1=>DB,user1=>USER,
		            pw1=>PASSWD_FIRST,range=>RANGE};
		$ok = $self->doActionStart('OCR_DOC_RESTART',CHECK_OK,$ppar);
	} else {
    $self->session->message(ERR_RANGE);
	}
	$self->form(OCR);
	return $ok;
}






=head2 doActionChpasswd

Change password (root/archivista)

=cut

sub doActionChpasswd {
  my $self = shift;
  my $ok = 0;
  my $pwold = $self->session->param('oldpw');
	my $pw1 = $self->session->param('newpw1');
	my $pw2 = $self->session->param('newpw2');
	my $user = $self->session->param('user');
	my $mode = CHECK_OK;
	$mode = CHECK_EXIT if $user eq 'root';
	if ($pwold eq $self->session->ses->def_pw) { # root password is ok
	  if ($pw1 eq $pw2 && $pw1 ne "") { # new pw is ok
      my $pd = {user=>USER,oldpw=>PASSWD,newpw1=>NEWPASSWD};
      $ok=$self->doActionStart('CHPASSWD',$mode,$pd);
    }
	}	
	$self->form(PASSWORDS);
}






=head2 doActionBackupTape

Setup tape backup

=cut

sub doActionBackupTape {
  my $self = shift;
	my $pd = {tape_days=>DAYS,tape_time=>TIME};
	my $ok=$self->doActionStart('BACKUP_SET',CHECK_OK,$pd);
	$self->form(BACKUP);
	return $ok;
}






=head2 doActionBackupUSB

Setup USB backup

=cut

sub doActionBackupUSB {
  my $self = shift;
	my $pd = {usb_days=>DAYS,usb_time=>TIME,usb_keep=>KEEP};
	my $ok=$self->doActionStart('USB_BACKUP_SET',CHECK_OK,$pd);
	$self->form(BACKUP);
	return $ok;
}






=head2 doActionMails

Setup mail archiving

=cut

sub doActionMails {
  my $self = shift;
	my $ok = 0;
	$self->session->checkParam('mails_enabled','0',['0','1']);
	if ($self->session->param('mails_enabled') eq '1') {
	  my $pd = {mails_days=>DAYS,mails_time=>TIME};
	  $ok=$self->doActionStart('MAILS_EN',CHECK_OK,$pd);
	} else {
    $ok=$self->doActionStart('MAILS_DIS',CHECK_OK,{});
	}
	$self->form(DAEMON);
	return $ok;
}






=head2 doActionFTP 

Enable/Disable ftp server

=cut

sub doActionFTP {
  my $self = shift;
	my $ok = 0;
	$self->session->checkParam('ftp_daemon','0',['0','1']);
	if ($self->session->param('ftp_daemon') eq '1') {
	  my $pw1 = $self->session->param('ftp_passwd1');
	  my $pw2 = $self->session->param('ftp_passwd2');
		if ($pw1 eq $pw2 && $pw1 ne "") {
		  $self->session->param_set('passwd',$pw1);
			my $pd = {passwd=>PASSWD};
	    $ok = $self->doActionStart('FTP_EN',CHECK_OK,$pd);
		}
	} else {
    $ok = $self->doActionStart('FTP_DIS',CHECK_OK,{});
	}
	$self->form(DAEMON);
	return $ok;
}






=head2 doActionVNC

Enable/Disable vnc

=cut

sub doActionVNC {
  my $self = shift;
	my $ok = 0;
	$self->session->checkParam('vnc_daemon','0',['0','1']);
	$self->session->checkParam('vnc_permanent','0',['0','1']);
	if ($self->session->param('vnc_daemon') eq '1' ) {
	  my $pw1 = $self->session->param('vnc_passwd1');
	  my $pw2 = $self->session->param('vnc_passwd2');
		if ($pw1 eq $pw2 && $pw1 ne "") {
		  $self->session->param_set('passwd',$pw1);
			my $pd = {passwd=>PASSWD,vnc_permanent=>PERMANENT};
	    $ok = $self->doActionStart('VNC_EN',CHECK_OK,$pd);
		}
	} else {
    $ok = $self->doActionStart('VNC_DIS',CHECK_OK,{});
	}
	$self->form(DAEMON);
	return $ok;
}






=head2 doActionSSH

Enable/Disable ssh

=cut

sub doActionSSH {
  my $self = shift;
	my $ok = 0;
	$self->session->checkParam('ssh_daemon','0',['0','1']);
	$self->session->checkParam('ssh_permanent','0',['0','1']);
	if ($self->session->param('ssh_daemon') eq '1' ) {
	  my $pd = {ssh_permanent=>PERMANENT};
	  $ok = $self->doActionStart('SSH_EN',CHECK_OK,$pd);
	} else {
    $ok = $self->doActionStart('SSH_DIS',CHECK_OK,{});
	}
	$self->form(DAEMON);
	return $ok;
}






=head2 doActionCups

Enable/Disable Cups

=cut

sub doActionCups {
  my $self = shift;
	my $ok = 0;
	$self->session->checkParam('cups_daemon','0',['0','1']);
	if ($self->session->param('cups_daemon') eq '1' ) {
	  my $pd = {cups_range=>'WEBC_RANGE'};
    my $ci = $self->session->param("cups_range_ip_cidr");
	  my $name = "cups_range_ip_oct_";
	  $self->session->param_set("cups_range",$self->session->checkIP($name,$ci));
	  $ok = $self->doActionStart('CUPS_EN',CHECK_OK,$pd);
	} else {
	  $ok = $self->doActionStart('CUPS_DIS',CHECK_OK,{});
	}
	$self->form(DAEMON);
	return $ok;
}






=head2 doActionBackupNow 

Start the backup now

=cut

sub doActionBackupNow {
  my $self = shift;
	my $doit = $self->session->param('backup_type');
  my $ok = 0;
	my $mode = "";
	$mode = 'USB_BACKUP' if $doit eq 'usb';
	$mode = 'RSYNC_BACKUP' if $doit eq 'rsync';
	$mode = 'BACKUP' if $doit eq 'tape';
	$mode = 'NET_BACKUP' if $doit eq 'network';
	$ok = $self->doActionStart($mode,CHECK_EXIT,{}) if $mode ne "";
	return $ok;
}






=head2 doActionBackupRsync 

Reconfigure the rsync backup

=cut

sub doActionBackupRsync {
  my $self = shift;
	my $pd = {rsync_days=>DAYS, rsync_time=>TIME, rsync_server=>SERVER,
	          rsync_user=>USER, rsync_passwd=>PASSWD};
	my $ok = $self->doActionStart('RSYNC_BACKUP_SET',CHECK_OK,$pd);
	$self->form(BACKUP);
	return $ok;
}






=head2 doActionBackupNetwork 

Reconfigure the network backup

=cut

sub doActionBackupNetwork {
  my $self = shift;
	my $pd = {net_days=>DAYS, net_time=>TIME, net_type=>TYPE, net_server=>SERVER,
	          net_share=>SHARE, net_user=>USER, net_passwd=>PASSWD};
	my $pe = {net_domain=>DOMAIN};
	my $ok = $self->doActionStart('NET_BACKUP_SET',CHECK_OK,$pd,$pe);
	$self->form(BACKUP);
	return $ok;
}






=head2 doActionNetwork

Change the ip address of the box

=cut

sub doActionNetwork {
  my $self = shift;
	my $ok = 0;
  my $ppar = {ip=>IP}; # needed vars for no dhcp
	if ($self->session->param('net_dhcp')==1) {
	  $ppar = {net_dhcp=>DHCP}; # if dhcp on, give only dhcp
	} else { # no dhcp, check ip/gw/ns
	  my $ci = $self->session->param("ip_ip_cidr");
	  $self->session->param_set("ip",$self->session->checkIP("ip_ip_oct_",$ci));
		my $gwon = $self->session->param("gwon");
		if ($gwon==1) {
		  $$ppar{gw}=GW;
	    $self->session->param_set("gw",$self->session->checkIP("gw_ip_oct_"));
		}
		my $nson = $self->session->param("nson");
		if ($nson==1) {
		  $$ppar{ns}=NS;
	    $self->session->param_set("ns",$self->session->checkIP("ns_ip_oct_"));
		}
  }	
	$ok = $self->doActionStart('NETWORK',CHECK_EXIT,$ppar);
	$self->form(SETTINGS);
	return $ok;
}






=head2 doActionScanButton 

Reconfigure the ScanButton

=cut

sub doActionScanButton {
  my $self = shift;
	my $ok = 0;
  $self->session->checkParam('avbutton','0',['0','1']);
	if ($self->session->param('avbutton') eq '1') {
	  my $pn = {avbutton=>'WEBC_AVBACTIVE', avb_host=>'WEBC_AVBHOST', 
	    avb_db=>'WEBC_AVBDB',avb_user=>'WEBC_AVBUSER',avb_pw=>'WEBC_AVBPW'};
	  $ok=$self->doActionStart('BUTTON_SET',CHECK_OK,$pn);
	} elsif ($self->session->param('avbutton') eq '0') {
	  my $pn = {avbutton=>'WEBC_AVBACTIVE'};
	  $ok=$self->doActionStart('BUTTON_SET',CHECK_OK,$pn);
	}
	return $ok;
}






=head2 doActionLoginMask

Reconfigure the Loginmask (exit after it)

=cut

sub doActionLoginmask {
  my $self = shift;
  $self->session->checkParam('onlylocal',0,[0,1]);
	$self->session->checkParam('onlydefdb',0,[0,1]);
	my $pd = {login_host=>LOGINHOST};
	my $pe = {onlylocal=>ONLYLOCAL,onlydefdb=>ONLYDEFDB,
	          login_db=>LOGINDB,login_user=>LOGINUSER};
	my $ok=$self->doActionStart('LOGIN_SET',CHECK_EXIT,$pd,$pe);
	return $ok;
}






=head2 doActionDateTimeZone

Check time/area/zone and set it

=cut

sub doActionDateTimeZone {
  my $self = shift;
	my $y = $self->session->param('time_year');
	my $m = $self->session->param('time_month');
  my $d= $self->session->param('time_day');
	my $h = $self->session->param('time_hour');
	my $min = $self->session->param('time_min');
	my $ok = check_date($y,$m,$d);
	$ok = check_time($h,$min,0) if $ok==1;
	my $area = $self->session->param('area');
	my $fzone = "zone_$area";
	my $zone = $self->session->param($fzone);
  $ok = 0 if !-e "/usr/share/zoneinfo/$area/$zone" && $ok==1;;
	if ($ok==1) {
	  my $tim = sprintf("%02d-%02d %02d:%02d %04d",($m,$d,$h,$min,$y));
		$self->session->param_set('time',$tim);
		my $ppar = {area=>'WEBC_AREA', $fzone=>'WEBC_ZONE', time=>'WEBC_DTIME'};
		$ok = $self->doActionStart('TIME',CHECK_EXIT,$ppar);
	}
	$self->form(SETTINGS);
	return $ok;
}






=head2 doActionUnlock

Does start the job for unlocking documents

=cut

sub doActionUnlock {
  my $self = shift;
	my $ok = 0;
	my $range = $self->session->param('range');
	if ($self->_checkRange($range)) {
   	my $ppar = {host1=>HOST,db1=>DB,user1=>USER,
		            pw1=>PASSWD_FIRST,range=>RANGE};
		$ok = $self->doActionStart('DOC_UNLOCK',CHECK_NO,$ppar);
		$self->session->message(UNLOCK_OK) if $ok==1;
	} else {
    $self->session->message(ERR_RANGE);
	}
	return $ok;
}






# _checkRange -> check for x-y or x
#
sub _checkRange {
  my ($self,$val) = @_;
	$val =~ s/\s//g;
	$val=~/^(\d+)(-*)(\d*)/;
  my $x=$1;
  my $y=$3;
	my $ok=1;
	$ok=0 if $x<=0;
	$ok=0 if $x>$y && $y>0;
	return $ok;
}





=head2 $jobid=doActionStart($mode,\%params,\%pempty);

Start the desired job (if there is an error, give back 0)

=cut

sub doActionStart {
  my ($self,$mode,$nextaction,$pparam,$ppempty) = @_;
	my $doit = 1;
	my $ok = 0;
	foreach my $key (keys %$pparam) { # check for needed values
	  $doit = 0 if $self->session->param($key) eq '';
	}
	if ($ppempty) {
	  foreach my $key (keys %$ppempty) { # copy values that may be empty
      $$pparam{$key} = $$ppempty{$key};
	  }
	}
	if ($doit==1) {
	  my $av = $self->session->ses;
	  my $job = $av->dbh->quote(JOB);
	  my $host = $av->dbh->quote($av->getHost());
	  my $db = $av->dbh->quote($av->getDatabase());
	  my $user = $av->dbh->quote($av->getUser());
	  my $password = $av->dbh->quote($av->getPassword());
	  my $sql = "insert into jobs set job=$job,status=110,".
	            "host=$host,db=$db,user=$user,pwd=$password";
	  $av->dbh->do($sql);
	  $sql = "SELECT LAST_INSERT_ID()";
	  my @res=$av->dbh->selectrow_array($sql);
	  if ($res[0]) {
		  my $jid = $av->dbh->quote($res[0]);
		  my $qvalue = $av->dbh->quote($mode);
			my $qkey = $av->dbh->quote(MODE);
      $sql = "insert into jobs_data set jid=$jid,param=$qkey,value=$qvalue";
			$av->dbh->do($sql);
      foreach my $key (keys %{$pparam}) {
			  $qvalue = $av->dbh->quote($self->session->param($key));
				$qkey = $av->dbh->quote($$pparam{$key});
        $sql = "insert into jobs_data set jid=$jid,param=$qkey,value=$qvalue";
			  $av->dbh->do($sql);
			}
			$sql = "update jobs set status=100 where id=$jid"; 
			$av->dbh->do($sql);
			if ($nextaction eq CHECK_EXIT) {
			  $ok = 1;
	      $self->getMainLogout;
			} elsif ($nextaction eq CHECK_OK) {
			  foreach (0..CHECK_OK) { # wait 4 seconds if the job was already done
          $sql = "select status from jobs where id=$jid";
			    @res = $av->dbh->selectrow_array($sql);
					if ($res[0]==120) {
					  $ok = 1;
						last;
					}
			    sleep 1;
			  }
				if ($ok==1) {
				  $self->session->message(CHANGES_OK);
				} else {
				  $self->session->message(WARN);
				}
			} else {
			  $ok=1; # no check, so say always it is ok
			}
    }
	}
	return $ok;
}






=head2 $self->getMain()

Construct all html part and print it out

=cut

sub getMain {
  my $self = shift;
  my $table = HTML::Table->new(-border => 0, -width => "100%");
	$table->setCellSpacing(0);
	$table->setCellPadding(0);
	my $space="&nbsp;";
	$table->addRow($space,$space,$space);
	$table->setCellColSpan(-1,1,3);
	$table->setCellAttr(-1,1,"background='".IMG_LOGIN_HEADER."'");
	$table->setRowHeight(-1,53);
  my $menubar = $self->cgi->menu(\@menu,$self->form);
	$table->addRow($menubar,$space,$self->getMainForm());
	$table->setCellWidth(-1,1,249);
	$table->setCellWidth(-1,2,30);
	$table->setCellHeight(-1,1,500);
	$table->setCellAttr(-1,1,"background='".IMG_LOGIN_LEFT."'");
  $table->setRowVAlign(-1,'TOP');
  $self->_printHtml($table->getTable()); # print it out
}






=head2 $self->getMainForm()

Construct the html part for the current form view according self->form

=cut

sub getMainForm {
  my ($self) = @_;
	$self->cgi->table(HTML::Table->new(-border=>0));
	if ($self->form eq LOGOUT) {
	  $self->getMainLogout();
	} elsif ($self->form eq STATUS) {
    $self->getMainLogFile();
	} elsif ($self->form eq SETTINGS) {
	  $self->getMainSettings();
  } elsif ($self->form eq LOGINMASK) {
	  $self->getMainLoginMask();
  } elsif ($self->form eq SCANBUTTON) {
    $self->getMainScanButton();
	} elsif ($self->form eq EXIT_MSG) {
  	$self->cgi->row_title(EXIT_MSG);
	  $self->cgi->row_submit(RESTART,EXIT_ASK,1,EXIT_RESTART); # left side
	  $self->cgi->row_submit(SHUTDOWN,EXIT_ASK,1,EXIT_SHUTDOWN); # left side
  } elsif ($self->form eq BACKUP) {
    $self->getMainBackup();
	} elsif ($self->form eq BACKUPLOG) {
    $self->getMainLogFile();
  } elsif ($self->form eq BACKUPNOW) {
    $self->getMainBackupNow();
  } elsif ($self->form eq DAEMON) {
    $self->getMainDaemon();
	} elsif ($self->form eq UNLOCK) {
    $self->getMainUnlock();
	} elsif ($self->form eq PASSWORDS) {
    $self->getMainPasswords();
	} elsif ($self->form eq LOGS) {
    $self->form(AVLOG); # we show normal log file
    $self->getMainLogFile();
    $self->form(OCRLOG);	# we show ocr log file
    $self->getMainLogFile();
	} elsif ($self->form eq OCR) {
    $self->getMainOCR();
	} else { # if the form is not available then print out status form
	  $self->form(STATUS);
    $self->getMainLogFile();
	}
	if ($self->session->message ne "") {
		my $msg = $self->session->message;
		$msg = $self->cgi->string($msg);
	  $self->cgi->table->addRow("&nbsp;");
	  $self->cgi->table->addRow("<i>".$msg."</i>");
		$self->cgi->table->setCellColSpan(-1,1,2);
	}
	return $self->cgi->table->getTable();
}






=head2 getMainLogut

Close the session and show the login form

=cut

sub getMainLogout {
  my $self = shift;
	$self->session->close(); # close session
	sleep 1;
	$self->getLogin; # print out login form
	exit; # say that we don't have any mor to do
}






=head2 $self->getMainLogFile()

Construct a table with a log file (used several times)

=cut

sub getMainLogFile {
  my ($self) = @_;
	$self->cgi->row_title($self->form);
	my $res = "";
	my $rows = 12;
	my $reverse = 1; # reverse sorting order
	my $mb = '-n 2000'; # maximun of bytes we read from a log file
	if ($self->form eq STATUS) {
	  $res = `/home/archivista/status.sh -webconfig`;
		$rows = 30;
		$reverse = 0;
	} elsif ($self->form eq AVLOG) {
    $res = `tail $mb /home/data/archivista/av.log`;
	} elsif ($self->form eq OCRLOG) {
    $res = `tail $mb /home/archivista/.wine/drive_c/Programs/Av5e/AV5AUTO.LOG`;
  } else {
	  $res = `tail $mb /home/data/archivista/backup.log`;
		$rows = 30;
	}
  if (length($res) == 0) {
    $self->cgi->table->addRow($self->cgi->string(ERR_NOFILEDATA));
	} else {
	  if ($reverse==1) {
      my @lines = split("\n",$res);
		  @lines = reverse @lines;
		  $res = join("\n", @lines);
		}
    $self->cgi->table->addRow($self->cgi->textarea({name=>'logs',
		        default=>$res,rows=>$rows,cols=>90,readonly=>1}));
  }
}






=head2 $self->getMainSettings()

Construct a table with keyboard, network settings and time/date

=cut

sub getMainSettings {
  my ($self) = @_;
	$self->cgi->row_title(LAYOUT);
	$self->cgi->row_keyboard(KBDLAYOUT,'kbd_layout');
	$self->cgi->row_submit(KBDLAYOUT);
	$self->cgi->row_language(LANG,'language');
	$self->cgi->row_submit(LANG,LANGEXIT);
	$self->cgi->row_title(NETWORK);
  my $gwon = 0;
	my $nson = 0;
  my $dhcp = `grep 'dhcp' /etc/conf/network`;
  my $ip = `grep 'ip' /etc/conf/network | cut -d ' ' -f 2`;
  my $gw = `grep 'gw' /etc/conf/network | cut -d ' ' -f 2`;
  my $ns = `grep 'nameserver' /etc/conf/network | cut -d ' ' -f 2`;
	chomp $dhcp;
	chomp $ip;
	chomp $gw;
	chomp $ns;
	$gwon=1 if $ip eq "";
	$gwon=1 if $ip ne "" && $gw ne "";
	$nson=1 if $ip eq "";
	$nson=1 if $ip ne "" && $gw ne "";
	my $css_class='';
	$css_class = 'hidden_ip' if $dhcp;
	$self->cgi->row_checkbox(DHCP,'net_dhcp','1',$dhcp,"HIDE_IP()");
	$self->cgi->row_ip(IP,'ip',$ip,1);
	$self->cgi->row_attributes($css_class,'id="ip_row"');
	$self->cgi->row_checkbox(GWON,'gwon','1',$gwon);
	$self->cgi->row_attributes($css_class,'id="gwon_row"');
	$self->cgi->row_ip(GW,'gw',$gw);
	$self->cgi->row_attributes($css_class,'id="gw_row"');
	$self->cgi->row_checkbox(NSON,'nson','1',$nson);
	$self->cgi->row_attributes($css_class,'id="nson_row"');
	$self->cgi->row_ip(NS,'ns',$ns);
	$self->cgi->row_attributes($css_class,'id="ns_row"');
	$self->cgi->row_submit(NETWORK,NETWORK_MESSAGE);
	$self->cgi->row_title(DATETIME);
	$self->cgi->row_timearea(TIMEAREA,'area');
	$self->cgi->row_timezones(TIMEZONE,'zone');
	$self->cgi->row_datetime(DATETIME,'time');
	$self->cgi->row_submit(DATETIME);
}






=head2 $self->getMainLoginMask($table)

Show the fields for the login mask (WebClient)

=cut

sub getMainLoginMask {
  my ($self) = @_;
  use lib qw(/home/cvs/archivista/webclient/perl/);
  use inc::Global;
	my $ohost = inc::Global::onlyLocalhost();
	$ohost = "" if $ohost == 0;
	my $odb = inc::Global::onlyDefaultDb();
	$odb = "" if $odb == 0;
	my $host = inc::Global::defaultLoginHost();
	my $db = inc::Global::defaultLoginDb();
	my $user = inc::Global::defaultLoginUser();
	$self->cgi->row_title($self->form);
	$self->cgi->row_textfield(LOGINHOST,'login_host',$host);
  $self->cgi->row_checkbox(ONLYLOCAL,'onlylocal','1',$ohost);
	$self->cgi->row_textfield(LOGINDB,'login_db',$db);
	$self->cgi->row_checkbox(ONLYDEFDB,'onlydefdb','1',$odb);
	$self->cgi->row_textfield(LOGINUSER,'login_user',$user);
	$self->cgi->row_submit($self->form,LOGINMASK_MESSAGE);
}






=head2 $self->getMainScanButton($table)

Show the fields for the scan button (ArchivistaBox)

=cut

sub getMainScanButton {
  my ($self) = @_;
	$self->cgi->row_title($self->form);
	my $enable = `grep 'av_button' /etc/av-button.conf | cut -d '=' -f 2`;
	chomp $enable;
	my ($host,$db,$user,$pw) = $self->_ScanButtonVars(1);
	$self->cgi->row_checkbox(AVB_EN,'avbutton','1',$enable);
	$self->cgi->row_textfield(HOST,'avb_host',$host);
	$self->cgi->row_textfield(DB,'avb_db',$db);
	$self->cgi->row_textfield(USER,'avb_user',$user);
	$self->cgi->row_password(PASSWD_FIRST,'avb_pw',$pw);
	$self->cgi->row_submit($self->form);
}






# give back the default values for scan/button (host/db/user/pw)
#
sub _ScanButtonVars {
  my $self = shift;
	my $everything = shift;
	my $file = "/home/cvs/archivista/jobs/sane-button.pl";
	my $host=`. /home/archivista/perl-var.in;get_perl_var '\$val{host1}' $file`;
	my $db=`. /home/archivista/perl-var.in;get_perl_var '\$val{db1}' $file`;
	if ($everything==0) {
	  my @dbs = split(',',$db);
		$db = $dbs[0];
	}
	my $user=`. /home/archivista/perl-var.in;get_perl_var '\$val{user1}' $file`;
	my $pw=`. /home/archivista/perl-var.in;get_perl_var '\$val{pw1}' $file`;
	chomp $host;
	chomp $db;
	chomp $user;
	chomp $pw;
	return ($host,$db,$user,$pw);
}






=head2 $self->getMainBackup($table)

Show the messages to setup the backup

=cut

sub getMainBackup {
  my ($self) = @_;
	$self->cgi->row_title(USB);
	my @vals = ('days','time',"keep");
	my %vals = $self->_getWebConfigVals("/etc/usb-backup-webconfig.conf",\@vals);
	$self->cgi->row_textfield(DAYS,'usb_days',$vals{days});
	$self->cgi->row_textfield(TIME,'usb_time',$vals{'time'});
	$self->cgi->row_textfield(KEEP,'usb_keep',$vals{'keep'});
	$self->cgi->row_submit(USB);
  $self->cgi->row_title(NETBACKUP);	
	@vals = ('days','time','type','server','share','user','domain');
	%vals = $self->_getWebConfigVals("/etc/net-backup-webconfig.conf",\@vals);
	$self->cgi->row_textfield(DAYS,'net_days',$vals{days});
	$self->cgi->row_textfield(TIME,'net_time',$vals{'time'});
	$self->cgi->row_dropdown(TYPE,'net_type',['cifs','nfs'],$vals{type});
  $self->cgi->row_textfield(SERVER,'net_server',$vals{server});
  $self->cgi->row_textfield(SHARE,'net_share',$vals{share});
  $self->cgi->row_textfield(USER,'net_user',$vals{user});
	$self->cgi->row_password(PASSWORD,'net_passwd');
  $self->cgi->row_textfield(DOMAIN,'net_domain',$vals{domain});
	$self->cgi->row_submit(NETBACKUP);
  if (!$self->cgi->check64bit()==64) {
	  $self->cgi->row_title(TAPEBACKUP);
	  @vals = ('days','time');
	  %vals = $self->_getWebConfigVals("/etc/backup-webconfig.conf",\@vals);
	  $self->cgi->row_textfield(DAYS,'tape_days',$vals{days});
	  $self->cgi->row_textfield(TIME,'tape_time',$vals{'time'});
	  $self->cgi->row_submit(TAPEBACKUP);
	}
  $self->cgi->row_title(RSYNC);	
	@vals = ('days','time','server','user','dir');
	%vals = $self->_getWebConfigVals("/etc/rsync-backup-webconfig.conf",\@vals);
	$self->cgi->row_textfield(DAYS,'rsync_days',$vals{days});
	$self->cgi->row_textfield(TIME,'rsync_time',$vals{'time'});
	$self->cgi->row_textfield(SERVER,'rsync_server',$vals{server});
	$self->cgi->row_textfield(USER,'rsync_user',$vals{user});
	$self->cgi->row_textfield(SHARE,'rsync_share',$vals{user});
	$self->cgi->row_submit(RSYNC);
}






# _getWebConfigVals -> give back the values from the webconfig file
#
sub _getWebConfigVals {
  my ($self,$file,$pvals) = @_;
	my %vals;
	foreach my $key (@$pvals) {
	  $vals{$key} = `grep '$key' $file`;
		$vals{$key} =~ s/$key=//;
		chomp($vals{$key});
	}
	return %vals;
}






=head2 $self->getMainBackupNow($table)

Show the messages to start a backup just now

=cut

sub getMainBackupNow {
  my ($self) = @_;
	$self->cgi->row_title(BACKUPNOW);
	my (%files,%labels);
	%files=(usb=>F_USB, network=>F_NET, rsync=>F_RSYNC, tape=>F_TAPE);
	%labels=(usb=>$self->cgi->string(USB),network=>$self->cgi->string(NETBACKUP),
	      rsync=>$self->cgi->string(RSYNC),tape=>$self->cgi->string(TAPEBACKUP));
	my $default = 'usb';
	my (@radios,%elements);
	foreach my $id ('usb', 'network', 'rsync', 'tape') {
	  my $res=`grep 'days=' $files{$id}`; # Check if days are set
		chomp $res;
		if ($res ne "" || $id eq 'usb' || $id eq 'tape') { # Backup possible?
		  $default=$id if $res ne ""; # Days are set! we have a active backup!
			push @radios, $id;
			$elements{$id} = $labels{$id};
		}
	}
	my $label = $self->cgi->string(BACKUP_TYPE);
	my $radio = $self->cgi->radiobutton(name=>'backup_type',elements=>\@radios,
                     labels=>\%elements,default=>$default,linebreak=>'true');
	$self->cgi->table->addRow($label,$radio);
	$self->cgi->row_submit(BACKUPNOW,BACKUPSTART);
}







=head2 $self->getMainDaemon($table)

Show the messages for the services (cups/ftp/ssh/vnc)

=cut

sub getMainDaemon {
  my ($self) = @_;
	my @vals = ('ip','autostart');
	my %vals = $self->_getWebConfigVals("/etc/cups-webconfig.conf",\@vals);
	if ( $vals{ip} eq '') {
    $vals{ip} = `grep 'ip' /etc/conf/network | cut -d ' ' -f 2`;
	  chomp($vals{ip});
		$vals{ip} =~ s/\.\d{1,3}\//\.0\//;
		$vals{ip} = "192.168.0.0/24" if $vals{ip} eq ''; # NO IP SET it to default
	}
	$self->cgi->row_title(CUPS);
	$self->cgi->row_checkbox(CUPS_EN,'cups_daemon','1',$vals{autostart});
	$self->cgi->row_ip(CUPS_RANGE,'cups_range',$vals{ip},1);
	$self->cgi->row_submit(CUPS);
	$self->cgi->row_title(FTP);
	my $chk=0;
  $chk=1 if `grep '^ftp' /etc/inetd.conf`;
	$self->cgi->row_checkbox(FTP_EN,'ftp_daemon','1',$chk);
	$self->cgi->row_password(PASSWD_FIRST,'ftp_passwd1');
	$self->cgi->row_password(PASSWD_SECOND,'ftp_passwd2');
	$self->cgi->row_submit(FTP);
	$self->cgi->row_title(MAILS);
	@vals = ('enabled','days','time');
	%vals = $self->_getWebConfigVals("/etc/mail-fetch-webconfig.conf",\@vals);
	$chk=0;
  $chk=1 if $vals{enabled} >0;
	$self->cgi->row_checkbox(MAILS_EN,'mails_enabled',1,$chk);
	$self->cgi->row_textfield(MAIL_EN_DAY,'mails_days',$vals{days});
	$self->cgi->row_textfield(MAIL_EN_TIME,'mails_time',$vals{'time'});
	$self->cgi->row_submit(MAILS);
	if ($vals{enabled}>0) {
	  $self->cgi->row_title(MAILS_DO);
	  $self->cgi->row_submit(MAILS_DO,MAILS_DO_MESSAGE,1); # left side
	}
	$self->cgi->row_title(SSH);
	my ($enable,$perm)=$self->_getActive('sshd','ssh_autostart','/etc/sshd.conf');
	$self->cgi->row_checkbox(SSH_EN,'ssh_daemon','1',$enable);
	$self->cgi->row_checkbox(PERMANENT,'ssh_permanent','1',$perm);
	$self->cgi->row_submit(SSH);
	$self->cgi->row_title(VNC);
	($enable,$perm) = $self->_getActive('x11vnc','autostart','/etc/vnc.conf');
	$self->cgi->row_checkbox(VNC,'vnc_daemon','1',$enable);
	$self->cgi->row_checkbox(PERMANENT,'vnc_permanent','1',$perm);
	$self->cgi->row_password(PASSWD_FIRST,'vnc_passwd1');
	$self->cgi->row_password(PASSWD_SECOND,'vnc_passwd2');
	$self->cgi->row_submit(VNC);
}






# ($enable,$perm) = $self->_getActive
# Helper function to check if ssh/vnc is enabled
#
sub _getActive {
  my ($self,$prg,$opt,$file) = @_;
	my $enable=1;
	$enable=0 if system("ps -C $prg 1>/dev/null"); # not active
	my $call = "grep '$opt' $file";
	my $perm=`$call`;
	$perm=~ s/$opt=//;
	chomp $perm;
	return ($enable,$perm);
}






=head2 $self->getMainUnlock($table)

Show the messages to unlock documents

=cut

sub getMainUnlock {
  my ($self) = @_;
	$self->cgi->row_title($self->form);
	my ($host,$db,$user) = $self->_ScanButtonVars;
	$self->cgi->row_textfield(HOST,'host1',$host);
	$self->cgi->row_textfield(DB,'db1',$db);
	$self->cgi->row_textfield(USER,'user1',$user);
	$self->cgi->row_password(PASSWD_FIRST,'pw1');
	$self->cgi->row_textfield(RANGE_DOC,'range');
	$self->cgi->row_submit($self->form,UNLOCK_MESSAGE);
}






=head2 $self->getMainPasswords($table)

Show the messages to setup passwords

=cut

sub getMainPasswords {
  my ($self) = @_;
	$self->cgi->row_title(CHPASSWD);
	$self->cgi->row_dropdown(USER,'user',['root','archivista']);
	$self->cgi->row_password(ROOTPW,'oldpw');
	$self->cgi->row_password(PASSWD_FIRST,'newpw1');
	$self->cgi->row_password(PASSWD_SECOND,'newpw2');
	$self->cgi->row_submit(CHPASSWD,PWSET_MESSAGE);
	$self->cgi->row_title(RESETPW);
	$self->cgi->row_textfield(USER,'user1');
	$self->cgi->row_submit(RESETPW);
}






=head2 $self->getMainOCR($table)

Show the messages to control OCR recognition

=cut

sub getMainOCR {
  my ($self) = @_;
	$self->cgi->row_title(OCRREGISTER);
	if ( -e "/home/archivista/.wine/drive_c/Programs/Av5e/av7.con") {
	  $self->cgi->table->addRow($self->cgi->string(OCR_REGISTERED)); # OCR registered
	} else {
    $self->cgi->row_textfield(SERVER,'server');
		$self->cgi->row_textfield(FILE,'file');
	  $self->cgi->row_password(PASSWD_FIRST,'password');
		$self->cgi->row_submit(OCRREGISTER,OCR_MESSAGE);
	}
	$self->cgi->row_title(OCR_RESTART);
	$self->cgi->row_submit(OCR_RESTART,OCRSERVERRESTART_MESSAGE,1); # left side
	$self->cgi->row_title(OCR_DOCRESTART);
	my ($host,$db,$user) = $self->_ScanButtonVars;
	$self->cgi->row_textfield(HOST,'host1',$host);
	$self->cgi->row_textfield(DB,'db1',$db);
	$self->cgi->row_textfield(USER,'user1',$user);
	$self->cgi->row_password(PASSWD_FIRST,'pw1');
	$self->cgi->row_textfield(RANGE_DOC,'range');
	$self->cgi->row_submit(OCR_DOCRESTART,OCRDOCRESTART_MESSAGE);
}






=head1 getLoginForm()

Returns the default login form.

=cut

sub getLoginForm {
  my $self = shift;
  my $table=HTML::Table->new(-border=>0,-padding=>0,
	                      -spacing=>0,-width=>'100%');
	my $hidden = $self->cgi->hidden(name=>'host', value=>"localhost");
	$hidden .= $self->cgi->hidden(name=>'db', value=>"archivista");
	$hidden .= $self->cgi->hidden(name=>'user', value=>"root");
  $table->addRow("&nbsp;",$self->title.$self->POWEREDBY,"&nbsp;","&nbsp;");
  $table->setCellWidth(-1,1,100);
  $table->setCellClass(-1,2,'Title');
  $table->setCellAlign(-1,2,'Right');
	$table->setCellColSpan(-1,2,2);
  $table->setCellWidth(-1,4,100);
	my $empty = "&nbsp;"x6;
  my $label = $self->cgi->string(PASSWORD);
  my $field = $self->cgi->password(name=>'pw', default=>'');
	$field .= $hidden;
  $table->addRow("&nbsp",$label."&nbsp;&nbsp;".$field.$empty,"&nbsp;","&nbsp;");
  $table->setCellWidth(-1,1,100);
  $table->setCellAlign(-1,2,'Right');
	$table->setCellColSpan(-1,2,2);
  $table->setCellWidth(-1,4,100);
  $table->setCellHeight(-1,1,20);

  open(FIN,'/etc/lang.conf');
	my @f = <FIN>;
	close(FIN);
	my $kb = join("",@f);
	if ($kb eq '') {
    open(FIN,'/home/archivista/.xkb-layout');
	  @f = <FIN>;
	  close(FIN);
	  $kb = join("",@f);
	}
	my $defLanguage = ENGLISH;
	$defLanguage = GERMAN if index($kb,"de")==0;
	$defLanguage = FRENCH if index($kb,"fr")==0;
	$defLanguage = ITALIAN if index($kb,"it")==0;
	
  $field = $self->cgi->dropdown(name=>'lang',default=>$defLanguage, 
		                            elements=>[GERMAN,ENGLISH,FRENCH,ITALIAN]);
  my %button;
  $button{name} = $self->GO_LOGIN;
  $button{value} = $self->LBL_LOGIN;
	
  $field .= "&nbsp;&nbsp;".$self->cgi->submit(\%button).$empty;;
  $table->addRow("&nbsp;",$field,"&nbsp;","&nbsp;");
  $table->setCellWidth(-1,1,100);
  $table->setCellHeight(-1,1,20);
  $table->setCellAlign(-1,2,'RIGHT');
	$table->setCellColSpan(-1,2,2);
  $table->setCellWidth(-1,4,100);

  if ($self->session->message ne "") {
    $table->addRow("&nbsp;","&nbsp;");
		my $lbl = $self->cgi->string($self->session->message);
    $table->addRow($lbl,"&nbsp;");
    $table->setCellColSpan(-1,1,2);
    $table->setCellAlign(-1,1,'RIGHT');
  }
  $table->setCellAlign(2,1,'CENTER');
  $table->setCellVAlign(2,1,'MIDDLE');
	return $table->getTable(); # print out form
}







=head1 getAction

Get the next action from CGI (image/submit button OR get/post)

=cut

sub getAction {
  my $self = shift;
  my $check = $self->ACT_INDI;
  foreach my $param (keys %{$self->session->cgivals}){
    my $action = $param;
    if(grep(/^$check/,$param)) {
      $action =~ s/^($check)(.*?)((\.)(.*))?$/$1$2/;
      my ($go,@selected) = split('_',$action);
      $self->action(shift(@selected));
			$self->form(join("_",@selected));
		}
  }
}






=head1 getLogin

Gives back the Login Form

=cut

sub getLogin {
  my $self = shift;
  my $style = "position:absolute; top:50%; left:50%;";
  $style .= "width:48em; height:22em;";
  $style .= "margin-left:-24em; margin-top:-11em;";
  $style .= "border:1px solid #000;background:#fff; padding:0em;";
  my $table = HTML::Table->new(-spacing => 0,-padding=>0,-border=>0);
  $table->setWidth('100%');
  $table->setStyle($style);
  $table->addRow('&nbsp;');
  $table->addRow('&nbsp;',$self->getLoginForm());
  $table->setRowHeight(1,53);
  $table->setCellAttr(1,1,"background='".$self->IMG_LOGIN_HEADER."'");
  $table->setCellColSpan(1,1,2);
  $table->setCellAttr(2,1,"background='".$self->IMG_LOGIN_LEFT."'");
  $table->setCellWidth(2,1,248);
  $table->setCellHeight(2,1,307);

  my $print = "";
	if (!-e '/etc/nologinext.conf') {
	  $print .= "<p>";
	  $print .= qq|<a href="/perl/avclient/index.pl">WebClient</a>\n|;
	  $print .= " - ";
		if (-e '/etc/erp.conf') {
	    $print .= qq|<a href="/erp">WebERP</a>\n|;
	    $print .= " - ";
		}
	  $print .= qq|<a href="/cgi-bin/webadmin/index.pl">WebAdmin</a>\n|;
	  $print .= " - ";
	  $print .= qq|<a href="/perl/webconfig/index.pl">WebConfig</a>\n|;
	  $print .= " - ";
	  $print .= qq|<a href="/manual.pdf">Manual</a>\n|;
	  $print .= " - ";
	  $print .= qq|<a href="/handbuch.pdf">Handbuch</a>\n|;
	  $print .= "<p>\n\n";
	}
	
  $self->_printHtml($print.$table->getTable(),1);
}






=head1 _printHtml

Prints out everything (without header, which is printet in AVSession)

=cut

sub _printHtml {
  my ($self,$html,$init) = @_;
  my $head = $self->session->header() .
	  qq|<DOCTYPE HTML PUBLIC "-//W3C//DTD |.
	  qq|HTML 4.01 Transitional//EN">\n|.
	  qq|<html>\n|.
		qq|<head>\n<title>|.$self->title.qq|</title>\n|.
    qq|<link rel="stylesheet" type="text/css"|.
		qq| href="|.CSS_FILE.qq|" />\n|.
		qq|<script src="|.JS_FILE.
		qq|" type="text/javascript"></script>\n|.
    qq|<meta http-equiv="Content-Type" content="text/html; |.
		qq|charset=iso-8859-1" />\n</head><body>\n|;
	my $script = $ENV{REQUEST_URI};
  my $form = qq|<form method="post" action="$script" |.
	           qq|name="|.AVFORM.qq|">\n|;
	my $hidden="";
  $hidden = $self->cgi->hidden(name=>'lang',value=>$self->lang) if !$init;
	my $end = qq|</form></body></html>\n|;
	print $head.$form.$hidden.$html.$end;
  $self->session->closeHandler();
}






1;
