package Archivista::Config; #Don't edit!
use strict;
sub new { my $c=shift;
  my $s={}; bless $s,$c; $s->_init(); return $s; }
sub get { my $s=shift; 
  my $k=shift; return $s->{$k}; }

sub _init {
  my $self = shift;
	$self->{'MYSQL_HOST'} = "localhost";
	$self->{'MYSQL_DB'} = "archivista";
	$self->{'MYSQL_UID'} = "root";
  $self->{'MYSQL_PWD'} = "archivista";
  $self->{'MYSQL_BIN'} = "/opt/mysql/bin/mysql";
	$self->{'MYSQL_DUMP'} = "/opt/mysql/bin/mysqldump --add-drop-table";
	$self->{'BASE_IMAGE_PATH'} = "/home/data/archivista/images";
	$self->{'LOG_FILE'} = "/home/data/archivista/apcl.log";
	$self->{'DIR_SEP'} = "/";
	$self->{'TEMP_DIR'} = "/home/data/archivista/tmp";
  $self->{'CONFIG_DIR'} = "/home/cvs/archivista/apcl/etc";
  $self->{'AV_VERSION'} = 520;
	$self->{'AV_GLOBAL_DB'} = "archivista";
  $self->{'AV_GLOBAL_SESSION_TABLE'} = "sessionweb";
	$self->{'RM_RF'} = "/bin/rm -Rf";
  $self->{'SCAN_ADF_BIN'} = "/usr/bin/scanadf --pipe --scan-script /home/cvs/archivista/jobs/sane-client.pl";
}
1;

