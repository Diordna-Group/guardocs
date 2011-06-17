
package AVLanguages;
use strict;

our @ISA = qw(AVWeb);

use lib qw(/home/cvs/archivista/jobs);
use Wrapper;
use AVWeb;

# Constants

use constant IMG_SAVE_PERMANENT => AVWeb::IMG_FOLDER.'pma50.gif';
use constant GO_IMG_SAVE_PERMANENT => AVWeb::ACT_INDI.'save_permanent';

use constant LANGUAGES_FOLDER => "/tmp/";
use constant LANGUAGES_FILE => LANGUAGES_FOLDER."languages.sql";
use constant LANGUAGES_CHK => LANGUAGES_FOLDER."languages.chk";

use constant STRINGS_FILE => LANGUAGES_FOLDER.'languages.txt';


=head1 new()

Create a av session, get cookie, if available, get and prepare values

=cut

sub new {
  my $class = shift;
	my ($title,$table,$minlevel) = @_;
	my $self = $class->SUPER::new($title,$table,$minlevel);
	return $self;
}






=head1 getButtons

Add the special buttons for AVLanguages

=cut

sub getButtons {
  my $self = shift;
  my @buttons = ({ 
    name=>$self->GO_IMG_SAVE_PERMANENT,
    src =>$self->IMG_SAVE_PERMANENT,
    css_class => 'Button',
  });
  $self->SUPER::getButtons(\@buttons);
}






=head1 doAction 

Check if we want to export the strings

=cut

sub doAction {
  my $self = shift;
  if ($self->action eq $self->GO_IMG_SAVE_PERMANENT) {
    $self->doActionExport();
	} else {
	  $self->SUPER::doAction();
	}
}







=head1 doActionExport

Export the languages strings to local files

=cut

sub doActionExport {
  my $self = shift;
  my $host = $self->session->av->getHost();
  my $database = $self->session->av->getDatabase();
  my $user = $self->session->av->getUser();
  my $pw = $self->session->av->getPassword();
  my $outfile = $self->LANGUAGES_FILE;
  my $file = $self->LANGUAGES_CHK;
  my $table = "languages";

  unlink $outfile if -e $outfile;
  unlink $file if -e $file;
	my $mysql = "mysqldump";
	if (-e "/usr/bin/soffice") {
	  $mysql = "$mysql --compatible=mysql40";
	} else {
	  $mysql = "/opt/mysql/bin/$mysql";
	}
  my $cmd = "$mysql -h$host -u$user -p$pw ";
  $cmd .= "--add-drop-table --extended-insert ";
  $cmd .= "$database $table > $outfile";
	system($cmd);

  my $strings = '';
  my $length = 0;
	$self->session->av->setTable($table);
  foreach my $key ($self->session->av->keys('!id','')) {
    $self->session->av->key($key);
    $length += $self->session->av->select('length(en)');
		$strings .= join("\t",$self->session->av->select())."\r\n";
  }
	$self->_saveToFile($file,$length);
	print STDERR "SAVING TO FILE :".$self->STRINGS_FILE."\n";
  $self->_saveToFile($self->STRINGS_FILE,$strings);
}



sub _saveToFile {
  my $self = shift;
	my $file = shift;
	my $txt = shift;

  open(FOUT,">$file");
  binmode(FOUT);
  print FOUT "$txt";
  close(FOUT);
}






1;

