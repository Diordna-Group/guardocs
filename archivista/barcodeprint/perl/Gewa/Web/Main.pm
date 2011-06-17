# Current revision $Revision: 1.1.1.1 $
# Latest change on $Date: 2008/11/09 09:19:25 $ by $Author: upfister $

package Gewa::Web::Main;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);

use Gewa::Web::HTML;
use Gewa::lib::Config;

BEGIN {
use Exporter();
use DynaLoader();

@ISA    = qw(Exporter DynaLoader);
@EXPORT = qw(new print);
}

# -----------------------------------------------
# PRIVATE METHODS

=head1 _init($self,$request,$session,$dbm,$dbc)

	IN: object
	    object of GET/POST vars
	    object of session data
	    master database handler
	    client database handler
	OUT: -

	Main control of the application
	Handler all events and assemble the different parts to display

=cut

sub _init 
{
my $self = shift;
my $request = shift;
my $session = shift;
my $dbm = shift;
my $dbc = shift;

my $html = new Gewa::Web::HTML();
my $sid = $session->getSessionId();

# Check for printing barcode
if (length($request->value("bcPrint")) > 0) {
  my $matchFieldName = $session->get("session_match_field_name");
  my $keyFieldName = $session->get("session_key_field_name");
  my $panormalFields = $session->get("session_pa_normal_fields_ordered");
  if (length($request->value($matchFieldName)) > 0) {
    _printBarcode($session,$request,$html,$dbc);
    # Delete all input fields
    undef $request->{$keyFieldName};
    foreach (@$panormalFields) {
      undef $request->{$_};
    }
  } else {
    $session->set("error","Mitgliedernummer fehlt!");   
  }
} elsif (length($request->value("bcRePrint")) > 0) {
  _reprintBarcode($session,$request,$dbc);
} elsif (length($request->value("bcStorno")) > 0) {
  _cancelBarcode($session,$request,$dbc);
}

$self->{'data_header'} = $html->getHeader($session);
$self->{'data_left_side'} = $html->getLeftSide($request,$session,$dbc);

if (length($sid) > 0) {
  # User is logged, display the whole page
  $self->{'data_center'} = $html->getCenter($request,$session,$dbm);
  $self->{'data_right_side'} = $html->getRightSide($request,$session,$dbc);
}

$self->{'data_footer'} = $html->getFooter();
}

# -----------------------------------------------

=head1 _reprintBarcode($session,$request,$dbc)

	IN: object of session data
	    object of GET/POST vars
	    client database handler
	OUT: -

	Method to resend the barcode to the printer

=cut

sub _reprintBarcode
{
	my $session = shift;
	my $request = shift;
	my $dbc = shift;

	my ($barcodePrinterName,$barcodeString);
	my $id = $request->value("id");
	my $barcodeNumber = sprintf "%08d", $id;
	my $pabarcodePrintText = $session->get("session_pa_barcode_print_text");
  my $phbarcodePrintText = $session->get("session_ph_barcode_print_text");
 
  my $selectBarcodePrintText = join ",", @$pabarcodePrintText;
 
  my $query = "SELECT BarcodePrinter,$selectBarcodePrintText ";
  $query .= "FROM archiv WHERE Akte=$id";
  my $sth = $dbc->query($query);
  $sth->execute();

  while (my $hash_ref = $sth->fetchrow_hashref()) {
    $barcodePrinterName = $hash_ref->{'BarcodePrinter'};
    foreach my $fieldName (@$pabarcodePrintText) {
      my $strLength = $$phbarcodePrintText{$fieldName};
      my $fieldValue = $hash_ref->{$fieldName};
      $barcodeString .= _addToBarcodeString($fieldValue,$strLength);
    }
  }
  
  $sth->finish();
  
  _sendBarcodeToPrinter($barcodePrinterName,$barcodeNumber,$barcodeString);
}

# -----------------------------------------------

=head1 _cancelBarcode($session,$request,$dbc)

	IN: object of session data
	    object of GET/POST vars
	    client database handler
	OUT: -

	Remove a barcode for a specific document. The user id who wants to remove the
	barcode is placed to the mysql table (archiv) attribute 'BarcodeStorno'.

	Please note: there will be an error, if the attribute 'BarcodeStorno' is
	missing on table 'archiv'

=cut

sub _cancelBarcode
{
  my $session = shift;
  my $request = shift;
  my $dbc = shift;
  
  my $id = $request->value("id");
  my $uid = $session->get("session_uid");
  my $query = "UPDATE archiv SET BarcodeStorno=".$dbc->quote($uid)." ";
  $query .= "WHERE Akte=$id";
  $dbc->do($query);
}

# -----------------------------------------------

=head1 _printBarcode($session,$request,$html,$dbc)

	IN: object for session data
	    object for GET/POST vars
	    object which holds the html code
	    client database handler
	OUT: -

	Assemble a barcode and print it on the selected printer

=cut

sub _printBarcode
{
  my $session = shift;
  my $request = shift;
  my $html = shift;
  my $dbc = shift;
 
  my ($lastInsertId,$query,@query);
  my $keyFieldName = $session->get("session_key_field_name");
  my $phnormalFields = $session->get("session_ph_normal_fields");
  my $uid = $session->get("session_uid");
  my $barcodePrinter = $request->value("bcprinter");
  
  # Add new row to archiv table
  foreach (keys %$phnormalFields) {
    my $value = $request->value($_);
    $value = $html->langDateToSqlDatetime($value);
    push @query, "$_ = ".$dbc->quote($value);
  }

  my (undef,undef,undef,$day,$mon,$year) = localtime();
  $year += 1900;
  $mon = sprintf "%02d", $mon + 1;
  $day = sprintf "%02d", $day;
  my $barcodeDatum = "$year-$mon-$day";
  
  $query = "INSERT INTO archiv SET ";
  $query .= "$keyFieldName=".$dbc->quote($request->value($keyFieldName)).",";
  $query .= "BarcodeUser=".$dbc->quote($uid).",";
  $query .= "BarcodePrinter=".$dbc->quote($barcodePrinter).",";
  $query .= "BarcodeDatum=".$dbc->quote($barcodeDatum).",";
  $query .= "ArchivArt=3,";
  # Datum wird aus dem default Wert ausgelesen
  #$query .= "Datum=now(),";
  $query .= join ",", @query;
  $dbc->do($query);

  # Retrieve the last insert id
  $query = "SELECT LAST_INSERT_ID()";
  my $sth = $dbc->query($query);
  $sth->execute();

  while (my @row = $sth->fetchrow_array()) {
    $lastInsertId = $row[0];
  }
  
  $sth->finish();

  # Update akte for the new inserted row
  $query = "UPDATE archiv SET Akte=$lastInsertId WHERE Laufnummer=$lastInsertId";
  $dbc->do($query);

  _formatBarcodeForPrinting($session,$request,$lastInsertId)
}

# -----------------------------------------------

=head1 _formatBarcodeForPrinting($session,$request,$barcodeNumber)

	IN: object for session data
	    object for GET/POST vars
	    barcode number
	OUT: -

	Convert the barcode number to a well formatted barcode to print

=cut

sub _formatBarcodeForPrinting
{
  my $session = shift;
  my $request = shift;
  my $barcodeNumber = shift;

  my $barcodeString;
  my $pabarcodePrintText = $session->get("session_pa_barcode_print_text");
  my $phbarcodePrintText = $session->get("session_ph_barcode_print_text");
  my $barcodePrinterName = $request->value("bcprinter");
 
  $barcodeNumber = sprintf "%08d", $barcodeNumber;

  foreach my $fieldName (@$pabarcodePrintText) {
    my $strLength = $$phbarcodePrintText{$fieldName};
    my $fieldValue = $request->value($fieldName);
    $barcodeString .= _addToBarcodeString($fieldValue,$strLength);
  }

  _sendBarcodeToPrinter($barcodePrinterName,$barcodeNumber,$barcodeString);
}

# -----------------------------------------------

=head _sendBarcodeToPrinter($barcodePrinterName,$barcodeNumber,$barcodeString)

	IN: printer name
	    barcode number
	    barcode string
	OUT: -

	Write a temp file which includes the print instructions for the barcode and
	send the print command for the temp file with a system command

=cut

sub _sendBarcodeToPrinter
{
  my $barcodePrinterName = shift;
  my $barcodeNumber = shift;
  my $barcodeString = shift;

  my $config = new Gewa::lib::Config();
  my $printCommand = $config->getPrintCommand();
  my $temp = $config->getTempDir();
  my $file = "$temp/$barcodeNumber";
 
  open FOUT, ">$file" or die "Can't write to $file\n";
  print FOUT "\r\n"; #Neue Zeile, zwingend! Siehe Dok C4
  print FOUT "N\r\n"; #Speicher leeren 
  print FOUT "q832\r\n"; #Qualität: 1208 für 300dpi
  # 100 = mehr links
  # 200 = mitte
  # 300 = mehr rechts
  # 2.2.2005 -> add gewa code to barcode
  my $bcheck="gw";
  print FOUT "B250,50,0,1,3,5,100,N,\"$bcheck$barcodeNumber\"\r\n"; #Barcode definieren 
  print FOUT "A250,170,0,4,1,1,N,\"$barcodeNumber, $barcodeString\"\r\n"; #Text definieren
  print FOUT "P1\r\n"; #Drucken
  close FOUT;
  
  system("$printCommand $barcodePrinterName $file"); 

  # Remove file
  unlink $file;
}

# -----------------------------------------------

=head _addToBarcodeString($fieldValue,$strLength)

	IN: field value
	    string length
	OUT: string

=cut

sub _addToBarcodeString
{
  my $fieldValue = shift;
  my $strLength = shift;
  
  $fieldValue = substr $fieldValue, 0, $strLength;
  
  return "$fieldValue ";
}

# -----------------------------------------------
# PUBLIC METHODS

=head1 $main = new Main($request,$config,$session,$dbm,$dbc)

  Init a new main object
  
  PRE: PackageName
       Object(lib::Request)
       Object(lib::Config)
       Object(lib::Session)
       Object(lib::DB)
       Object(lib::DB)
  POST: -

=cut

sub new 
{
  my $cls = shift;
  my $request = shift;
  my $config = shift;
  my $session = shift;
  my $dbm = shift;
  my $dbc = shift;
  
  my $self = {};

  bless $self, $cls;
   
  $self->_init($request,$session,$dbm,$dbc);
   
  return $self;
}

# -----------------------------------------------

=head1 $main->print()

  Print the content of a page

  PRE: Object(Web::Main)
  POST: -

=cut

sub print
{
  my $self = shift;

  my $data = $self->{'data_header'};
  $data .= $self->{'data_left_side'};
  $data .= $self->{'data_center'};
  $data .= $self->{'data_right_side'};
  $data .= $self->{'data_footer'};
  
  print $data;
}

1;

__END__

# Log record
# $Log: Main.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:25  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:23  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.2  2005/11/24 12:52:48  ms
# Added POD
#
# Revision 1.1  2005/11/21 10:40:43  ms
# Added to project
#
# Revision 1.5  2005/03/30 16:18:42  ms
# Setzen der ArchivArt
#
# Revision 1.3  2005/02/17 12:16:34  ms
# Anpassungen: Styles, Mitglieder zwingend
#
# Revision 1.2  2005/02/17 11:49:37  ms
# Import der Aenderungen auf dem gewa archivserver
#
# Revision 1.1  2005/01/21 15:58:38  ms
# Added files, new namespace Gewa
#
# Revision 1.6  2005/01/21 14:28:06  ms
# Datum = now() bei erfoeffung akte in gewaclient
#
# Revision 1.5  2005/01/21 14:21:36  ms
# Remove file after printing
#
# Revision 1.4  2005/01/14 18:36:25  ms
# Erste endversion
#
# Revision 1.3  2005/01/14 17:13:30  ms
# Version mit funktionierendem barcode print
#
# Revision 1.2  2005/01/10 15:34:36  ms
# Entwicklung (mittlerer Teil mit such formular)
#
# Revision 1.1  2005/01/07 18:10:03  ms
# Entwicklung
#
