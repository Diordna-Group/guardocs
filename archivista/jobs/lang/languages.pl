#!/usr/bin/perl

use strict;
use lib qw(/home/cvs/archivista/jobs);
use AVDocs;
use Prima qw(Application MsgBox);
use Prima::VB::VBLoader;

# Load the login form
my $form = Prima::VBLoad('login.fm');
$form->execute();






#  Create our Go package
package Go;

# Gloabls
my $av;
my $window;
my ($st,$stop,@sa);
my @data;





#------------------------------------------------------------------------------#
=head1 load_data($own)

  Loads data into the Grid.

=cut

sub load_data {
  my $own = shift;
  my $data = get_data_from_db($av);
  $own->cells($data);
  $own->columnWidth(0,200);
  $own->columnWidth(1,350);
  $own->columnWidth(2,350);
  $own->visible(1);
}





#------------------------------------------------------------------------------#
=head1 run($owner)

  Login and then start the Application.

=cut

sub run {
  my $owner = shift;
  $window = $owner;
  # Get the information for the Login
  my $host = $window->host_in->text;
  my $db = $window->db_in->text;
  my $user = $window->user_in->text;
  my $pw = $window->pw_in->text;
  # Connection to MySQL
  $av=AVDocs->new($host,$db,$user,$pw);
  if ($av->dbState) {
    $window->close();  
    # If Connection is OK load our Form
    my $form = Prima::VBLoad('languages.fm');
    $form->execute();
  } else {
    # If the Connection is NOT OK then we print out a message
    Prima::message("Error while connecting. Please try it again");
  }
}





#------------------------------------------------------------------------------#
=head1 \@pa = get_data_from_db($av)

  Gets the Languages-Strings from the language table

=cut

sub get_data_from_db {
  my $av = shift;
  my $part = shift;
  # Set our Database and our Table
  $av->setDatabase($av->DB_DEFAULT);
  $av->setTable($av->TABLE_LANGUAGES);

  my $c = 0;
  foreach my $key ($av->keys('!id','')){
    my @vals = ();
    $av->key($key);
    @vals = $av->select();
    # Prepare the data for the Grid
    $data[$c] = [' '.$vals[0],' '.$vals[2],' '.$vals[3]];
    $c++;
  }

  return \@data;
}






#------------------------------------------------------------------------------#
=head1 mydumb($host,$database,$user,$pw,$outfile)

  Dumbs the Language Tabel to a given File.

=cut

sub mydump {
  my $host = $av->getHost();
  my $database = $av->getDatabase();
  my $user = $av->getUser();
  my $pw = $av->getPassword();
  my $outfile = "/home/cvs/archivista/initdb/languages.sql";
  my $table = 'languages';

  # Create the String to dump our Table
  my $string = "/opt/mysql/bin/mysqldump -h$host -u$user -p$pw ";
  $string   .= "--add-drop-table --extended-insert ";
  $string   .= "$database $table > $outfile";

  system("$string");
  patchFile();
}






#------------------------------------------------------------------------------#
=head1 patchFile

=cut

sub patchFile{
  # Get the length of all 'en' in the 'languages' Table
  my $length = getLength();
  my $file   = '/home/cvs/archivista/jobs/avdbutility.pl';

  # Read our file
  open(FIN,"<$file");
  binmode(FIN);
  my @data = <FIN>;
  my $m = 0;
  if($#data != -1){
    foreach my $line (@data){
      # Substitute our old length with the new one. if the Strings Matches
      # with ^\s{2}if\s\(\$nr\s!=\s\d+\) \{$
      # i.E. "  if ($nr != 1234) {"
      $line =~ s/\d+/$length/ if $line =~ /^\s{2}if\s\(\$nr\s!=\s\d+\) \{$/;
    }
    close(FIN);
  
    # Prints the file out
    open(FOUT,">$file");
    binmode(FOUT);
    if(print FOUT join('',@data)){
      Prima::message('Daten exportiert');
    } else {
      Prima::message('Fehler beim export aufgetreten');
    }
    close(FOUT);
  } else {
    Prima::message('Fehler beim lesen der Datei');
  }
}






#------------------------------------------------------------------------------#
=head1 $length=getLength()

  Returns the length of all english strings in the Languages Tabell.

=cut
#------------------------------------------------------------------------------#

sub getLength {
  my $length = 0;

  # Gets the lenght of 'en' for the whole languages Table
  foreach my $key ($av->keys('!id','')){
    $av->key($key);
    $length += $av->select('length(en)');
  }

  return($length);
}






#------------------------------------------------------------------------------#
=head1 sub_run($window,$file)

   Opens a new Window

=cut

sub sub_run {
  $window = shift;
  my $file = shift;
  # Loads a given Form file
  my $form = Prima::VBLoad($file);
  $form->execute();
}






#------------------------------------------------------------------------------#
=head1 search($searchterm)

  Searchs the Term in the Grid.

=cut

sub search {
  my $sw = shift;
  my $true = shift;

  if($true){
    my ($c1,$c2,$x,$y,$term,$row,$val,$found);
    my (@grid,@row);

    # Get our searchterm and the whole grid
    $term = $sw->search_in->text();
    @grid = $window->languages()->cells();

    # Search the term in the grid
    # save the results in the sa array
    for($x = 0;$x<=$#grid;$x++){
      @row = @{$grid[$x]};
      for($y = 0;$y<=$#row;$y++){
        $val = $row[$y];
        if($val =~ /$term/i){
          if($st eq $term){
          } else {
            $st = $term;
          }
          push(@sa,[$x,$y]);
        }
      }
    }

    # POPUP asks if we should continue showing results
    if($#sa){
      Prima::message(($#sa+1)." Einträge für $term gefunden!");
      $stop = 0;
      foreach my $val (@sa){
        $window->languages->focusedCell($val->[1],$val->[0]);
        Prima::MsgBox::message('Nächstes Ergebniss anzeigen?' ,
                               mb::YesNo, { 
                                 buttons => {
                                              mb::Yes ,{
                                                         text => 'Ja'
                                                       },
                                              mb::No ,{
                                                      text => 'Nein',
                                                      onClick => sub{$stop=1},
                                                      },
                                            }
                                          });
        last if $stop == 1;
      }
      # Clear our Result Array
      @sa = ();
    } else {
      Prima::message("Kein Eintrag für $term gefunden!");
    }
    
  } else {
    $sw->close();
  }
}








#------------------------------------------------------------------------------#
=head1 insert($window,$save)

  Insert a new Row in the Tabel 'languages'

=cut

sub insert {
  my $insert = shift;
  my $save = shift;
  if($save){
    my $id = $insert->id_in->text();
    my $de = $insert->de_in->text();
    my $en = $insert->en_in->text();
    my $li = $av->add(['id','de','en'],[$id,$de,$en]);
    if($av->isError){
      Prima::message("An Error accourred :".$av->isError);
    } else {
      Prima::message("Inserted $id succefully");
      $window->languages->add_rows([$id,$de,$en]);
    }
  }
  $insert->close();
}






#------------------------------------------------------------------------------#
=head1 delete_run

  Deletes a row from the grid and the db.

=cut

sub delete_run {
  $window = shift;
  my @focus = $window->languages->focusedCell();
	# Get the first value in the row
  $focus[0]=0;
  my $id = $window->languages->get_cell_text(@focus);
  $id=~s/\s{1,1}(.*)/$1/;
	# Ask if we want to delete row from languages
  Prima::MsgBox::message("'$id' DEFINITIV löschen?",
                           mb::YesNo,{
                             buttons => {
                               mb::No,{
                                 text => 'Nein',
                               },
                               mb::Yes,{
                                 text => 'Ja',
                                 onClick => sub{
                                              Go::delete($window,$focus[1],$id)
                                            }
                               },
                             }
                           }
                        );
}






#------------------------------------------------------------------------------#
=head1 delete

  Deletes the row from the grid and the database.

=cut

sub delete {
  my $window = shift;
  my $y = shift;
  my $id = shift;
	# Delete row from Grid
  $window->languages->delete_rows($y,1);
	# Delete row from Database
  $av->delete('id',$id);
}






#------------------------------------------------------------------------------#
=head1 edit

  Gets the Text from the Grid.

=cut

sub edit {
  my $own =shift;
  my @focus = $window->languages->focusedCell();
  $focus[0]=0;
  my @lang = ('id','de','en');
  foreach (@lang){
	   # Get text from Grid
     my $text = $window->languages->get_cell_text(@focus);
     $text=~s/\s{1,1}(.*)/$1/;
     $focus[0]++;
		 # Save text to the edit-window
     $own->$_->text($text);
  }
}






#------------------------------------------------------------------------------#
=head1 edit_save

  Updates the record in the database and in the Grid.

=cut

sub edit_save {
  my $own = shift;
  my $update = shift;
  if ($update==1) {
    my @fields = ('de','en');
    my @vals   = ($own->de->text(),$own->en->text());
    my @conF   = ('id');
    my @conV   = ($own->id->text());

    $av->setDatabase($av->DB_DEFAULT);
    $av->setTable($av->TABLE_LANGUAGES);
		# Update Fields in the Database
    $av->update(\@fields,\@vals,\@conF,\@conV);

    my ($x,$y) = $window->languages->focusedCell();
		# Delete row from grid
    $window->languages->delete_rows($y,1);
		# Insert row in the same position with the new values
    $window->languages->insert_row($y,(
                                     ' '.$own->id->text(),
                                     ' '.$own->de->text(),
                                     ' '.$own->en->text()
                                    ));
  }
  $own->close();
}







#------------------------------------------------------------------------------#
=head1 exit

  Closes the Programm.

=cut

sub exit {
  my $own = shift;
  $own->close();
  $av->close();
  exit 0;
}
