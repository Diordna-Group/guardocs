package AVStrings;

use 5.008007;
use strict;
use warnings;
use lib qw(/home/cvs/archivista/jobs/);
use Wrapper;
use DBI;

use constant DB_DEFAULT => 'archivista';
use constant TABLE_LANGUAGES => 'languages';

use constant LANG_EN => 'en';
use constant LANG_DE => 'de';
use constant LANG_FR => 'fr';
use constant LANG_IT => 'it';

use constant SOURCE_DB => 'database';
use constant SOURCE_FILE => 'file';

use constant STRINGS_FOLDER => '/usr/lib/perl5/site_perl/';
use constant STRINGS_FILE => STRINGS_FOLDER.'languages.txt';

use constant KEY_FIELD => 'id';

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration  use AVStrings ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
  
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  
);

our $VERSION = '0.01';


# Preloaded methods go here.


sub lang { wrap(@_) } # Language 'de' or 'en'
sub source { wrap(@_) } # Where to get Strings from
sub dbh { wrap(@_) } # AVDocs Object for Connection to the Database
sub strings { wrap(@_) } # Pointer with all Strings of the file we parsed.






=head1 $self = AVStrings::new($lang,$source)

Creates a New AVStrings Object.

=cut

sub new {
  my $class = shift;
  my $self = {};
  my $lang = shift;
  my $source = shift;
  bless $self,$class;

  $self->setSource($source);
  $self->setLanguages($lang);

  return $self;
}






=head1 setLanguage($lang)

=cut

sub setLanguages {
  my $self = shift;
  my $lang = shift;
  $self->lang($self->LANG_EN);
  $self->lang($lang) if $lang eq $self->LANG_FR;
  $self->lang($lang) if $lang eq $self->LANG_DE;
  $self->lang($lang) if $lang eq $self->LANG_IT;
}






=head1 setSource($source,[$dbh])

Sets the source. Possible Values are $self->SOURCE_DB or $self->SOURCE_FILE.

=cut

sub setSource {
  my $self = shift;
  my $source = shift;
  if($source eq $self->SOURCE_DB) {
    if (eval("require AVConfig; 1") ) {
		  # We are root Default settings can be loaded
      my $conf = AVConfig->new();
      my $host = $conf->def_host;
      my $db = $conf->def_db;
      my $user = $conf->def_user;
      my $pw = $conf->def_pw;
      my $dsn = "DBI:mysql:host=$host;database=$db;";
      my $dbh = DBI->connect($dsn,$user,$pw, {PrintError => 0});
      if ($dbh) {
        $self->dbh($dbh); # Set Database Handler
        $self->source($source);
      } else {
        # We have no Connection set Source to File
        $self->setSource($self->SOURCE_FILE);
      }
    } else {
		  # We can not load AVConfig so we are not root
			# Set Source to file
      $self->setSource($self->SOURCE_FILE);
    }
  } else {
    $self->source($self->SOURCE_FILE); # set default
    $self->_parseFile();
  }
}






=head1 $phash=string($application_number||$lang_id,[$language])

Look at getStrings. Diffrence it returns only one string.

=cut

sub string {
  my $self = shift;
	my $id = shift;
	my $phash = $self->getStrings($id);
	return ($phash->{$id}->{$self->lang()});
}


=head1 $phash=getStrings($application_number||$lang_id,[$language])

Returns pointer to hash with whole strings with the application or one single
string in the hash.

=cut

sub getStrings {
  my $self = shift;
  my $id = shift;
  my $lang = shift;

  my ($phstrings);

# if someone gives 'en' to us  we only want this String to be in english. So we
# have to backup first the default value. Then set the new one temporary to the
# one that was given to us, test if it is possible. And in the end Reset the
# Object Default language
##
  my $old_lang = $self->lang(); # Backup object default language
  # Set language and check if it is possible else take Class default
  # Get new Value
  $lang = $self->lang($lang);
  # Reset object default
  $self->lang($old_lang);

  # Check if we want the strings from the database
  if ($self->source eq $self->SOURCE_DB) {
    $phstrings = $self->_getStringsFromDB($id,$lang);
  } else {
    $phstrings = $self->_getStringsFromFile($id,$lang);
  }
  return $phstrings;
}






=head1 _getStringsFromDB

Composes SQL String and returns a hash Reference with the Result.

=cut

sub _getStringsFromDB {
  my $self = shift;
  my $id   = shift;
  my $lang = shift;

  my $sql = $self->_composeSQL($id,$lang);
  my $phstrings = $self->dbh->selectall_hashref($sql,$self->KEY_FIELD);

  return $phstrings;
}






=head1 _getStringsFromFile

Check if the wanted string is in our parsed file.

=cut

sub _getStringsFromFile {
  my $self = shift;
  my $id = shift;
  my $lang = shift;
  my $phstrings = {};

  if ($id =~ /\d+\.\d+/) {
    foreach my $key (keys %{$self->strings}) {
      # ID and Application are numeric so take == instead of eq
      if ($self->strings->{$key}->{Application} == $id) {
        # Add String to Output if it has the right Application number
        $phstrings->{$key} = $self->strings->{$key};
      }
    }
  } else {
    $phstrings->{$id} = $self->strings->{$id};
  }
  return $phstrings;
}






=head1 $sql=$self->_composeSQL($id,$lang)

Composes SQL String and returns it.

=cut

sub _composeSQL {
  my $self = shift;
  my $id   = shift;
  my $lang = shift;
  my $sql;

  $sql  = "select ".$self->KEY_FIELD.",$lang from ".$self->TABLE_LANGUAGES." ";

  # Do we want all Strings from an Application or just one id
  my $check = "id";
  $check = "Application" if ($id =~ /\d+\.\d+/);

  $sql .= " where $check = ".$self->dbh->quote($id);

  return $sql;
}






=head1 _parseFile

Parses the default language File to an intern variable.

=cut

sub _parseFile {
  my $self = shift;
  my $file = $self->STRINGS_FILE;

  my %hash;
  my @lang_table = ('id','comment','de','en','fr','it');

  my $strings = $self->_getFile($file);
  my @lines = split("\r\n",$strings);
  foreach my $line (@lines) {
    my %temp;
    my @values = split("\t",$line);
    my $c = 0;
    foreach my $attribute (@lang_table) {
      $temp{$attribute} = $values[$c];
      $c++;
    }
    $hash{$values[0]} = \%temp;
  }
  $self->strings(\%hash);
}






=head1 _getFile

Reads a file and returns it.

=cut

sub _getFile {
  my $self = shift;
  my $file = shift;
  my $txt;

  open(FIN,"<",$file);
  binmode(FIN);
  while(<FIN>) { $txt .= $_; }
  close(FIN);

  return $txt;
}








1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

AVStrings - Perl extension for Strings.

=head1 SYNOPSIS

  use AVStrings;

=head1 DESCRIPTION

=head2 EXPORT

=head1 SEE ALSO
=head1 AUTHOR

Rijad Nuridini, E<lt>rnuridini@archivista.chE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

