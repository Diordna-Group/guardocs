# Current revision $Revision: 1.1.1.1 $
# Latest change on $Date: 2008/11/09 09:19:24 $ by $Author: upfister $

package Gewa::Web::HTML;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);

use Gewa::lib::Config;

BEGIN {
  use Exporter();
  use DynaLoader();

  @ISA    = qw(Exporter DynaLoader);
  @EXPORT = qw(new print getHeader getFooter
               getLeftSide getCenter getRightSide
	       langDateToSqlDatetime);
}

# -----------------------------------------------
# PRIVATE METHODS

=head1 _getLogo($self)

	IN: object
	OUT: string

	Return a HTML string to display a logo (no longer used with the archivista CI)

=cut

sub _getLogo
{
  my $self = shift;

  my $config = new Gewa::lib::Config();
  my $www = $config->getWWWDir();
  
  my $string = qq{<img src="$www/img/logo.jpg" border="0">\n};
  $string .= qq{<br><br><br>\n};

  return $string;
}

# -----------------------------------------------

=head1 _getLogin($self,$request,$session,$dbc)

	IN: object
	    object for GET/POST vars
	    object for session data
	    client database handler
	OUT: string

	Return the login mask

=cut

sub _getLogin
{
  my $self = shift;
  my $request = shift;
  my $session = shift;
  my $dbc = shift;

  my ($mode,$submit,$host,$db,$uid,$readonly);
  my $style = qq{style="width: 150px"};

  my $config = new Gewa::lib::Config();
  my $cgi = $config->getCGIDir();
	my $www = $config->getWWWDir();
  my $sid = $session->getSessionId(); 
  
  if ($request->value("mode") eq "login") {
    $host = $request->value("host");
    $db = $request->value("db");
    $uid = $request->value("uid");
  } else {
    $host = $session->get("session_host");
    $db = $session->get("session_db");
    $uid = $session->get("session_uid");
  }
  
  my $error = $session->get("error");
    
  if (length($sid) == 0) {
    $mode = "login";
    $submit = "Anmelden";
  } else {
    $mode = "logout";
    $submit = "Abmelden";
    $readonly = "readonly";    
  }
 
  my $string = qq{<tr>\n};
	$string .= qq{<td valign="top" width="249" height="500" background="$www/img/menu_main.png">\n};
	$string .= qq{<table border="0" cellpadding="0" cellspacing="0">\n};
	$string .= qq{<form action="$cgi/index.pl" method="post">\n};
	$string .= qq{<input type="hidden" name="mode" value="$mode">\n};
  $string .= _printField("Host","host",$host,$style,$readonly);
  $string .= _printField("Datenbank","db",$db,$style,$readonly);
  $string .= _printField("Benutzername","uid",$uid,$style,$readonly);
  $string .= _printField("Passwort","pwd",undef,$style,$readonly,"password");
	$string .= qq{<tr><td>&nbsp;</td></tr>\n};
  $string .= qq{<tr><td class="login"><input type="submit" name="submit" value="$submit"></td></tr>\n};
  $string .= qq{<tr><td height="50" valign="bottom" class="Error">$error</td></tr>\n};
  $string .= qq{</form>\n};
	$string .= qq{</td></tr>\n};

  if ($mode eq "logout") {
    # The form for the center part
		$string .= qq{<form action="$cgi/index.pl" method="post" name="bcprint">\n};
		$string .= qq{<tr><td>\n};
		$string .= _getBarcodePrinters($session,$dbc,$style);
		$string .= qq{</td></tr>\n};
	}

	$string .= qq{</table>\n};
	$string .= qq{</td></tr>\n};

  return $string;
}

# -----------------------------------------------

=head1 _getBarcodePrinters($session,$dbc,$style)

	IN: object for session data
	    client database handler
	    stylesheet definition
	OUT: string

	Return the html string to display the available barcode printer dropdown

=cut

sub _getBarcodePrinters
{
  my $session = shift;
  my $dbc = shift;
  my $style = shift;
  
  my $barcodePrinters;
 

	my $query = "SELECT Inhalt FROM parameter WHERE Name='BarcodePrint' LIMIT 1";
	my $sth = $dbc->query($query);
	$sth->execute();

	while (my @row = $sth->fetchrow_array()) {
		$barcodePrinters = $row[0];
	}

	$sth->finish();

	my $string = qq{<tr><td class="label">Barcode Printers</td></tr>\n};
	$string .= qq{<tr><td class="login">\n};
	$string .= qq{<select name="bcprinter" $style>\n};

	foreach (split /\r\n/, $barcodePrinters) {
		my ($name,$ip) = split /=/, $_;
		$string .= qq{<option value="$ip"};
		$string .= " selected" if ($session->get("session_bc_printer") eq $ip);
		$string .= qq{>$name</option>\n};
	}

	$string .= qq{</select>\n};
	$string .= qq{</td></tr>\n};
	$string .= qq{<tr><td height="40">&nbsp;</td></tr>\n};

	return $string;
}

# -----------------------------------------------

=head1 _printField($label,$name,$value,$style,$readonly,$type)

	IN: input box label
	    input box name
	    input box value
	    input box style
	    readonly flag
	    input box type
	OUT: string

	Return the HTML string to display a input box like textfield or password
	
=cut

sub _printField
{
	my $label = shift;
	my $name = shift;
	my $value = shift;
	my $style = shift;
	my $readonly = shift;
# Bug 1.2.2005 -> wir benötigen zusätzlich ein Passwort-Feld
  my $type = shift;
  
  my $string .= qq{<tr><td class="label">$label</td></tr>\n};
  $type = "text" if (!$type);
  $string .= qq{<tr><td class="login"><input type="$type" name="$name" value="$value" $readonly></td></tr>\n}; 
  
	return $string;
}

# -----------------------------------------------

=head1 _fieldIsVarchar($dbm,$attribute)

	IN: master database handler
	    attribute name
	OUT: boolean value

	Return 1 if attribute is of type varchar, 0 else

=cut

sub _fieldIsVarchar
{
  my $dbm = shift;
  my $attribute = shift;

  my $isVarChar = 0;
  
  my $query = "DESCRIBE archiv";
  my $sth = $dbm->query($query);
  $sth->execute();

  while (my @row = $sth->fetchrow_array()) {
    if ($row[0] eq $attribute) {
      $isVarChar = 1 if ($row[1] =~ /varchar/);
    }
  }
  
  $sth->finish();

  return $isVarChar;
}

# -----------------------------------------------

=head1 _autoCompleteOptions($self,$request,$session,$dbm)

	IN: object
	    object of GET/POST vars
	    object of session data
	    master database handler
	OUT: string

	Return the textarea including all items matching with the requested field

=cut

sub _autoCompleteOptions
{
  my $self = shift;
  my $request = shift;
  my $session = shift;
  my $dbm = shift;
  my $keyFieldName = $session->get("session_key_field_name");
  my $acComboFields = $session->get("session_combo_fields");
  my $matchFieldName = $session->get("session_match_field_name");
  my $phnormalFields = $session->get("session_ph_normal_fields");
  my $keyFieldValue = $request->value($keyFieldName);
  
  my ($string,@option);
  
  # my $query = "SELECT $keyFieldName,$acComboFields FROM archiv ";
  my $query = "SELECT $acComboFields FROM archiv ";
  $query .= "WHERE $keyFieldName LIKE '$keyFieldValue%' ";
  # Check all input fields
  foreach my $key (keys %$phnormalFields) {
    my $fieldIsVarchar = _fieldIsVarchar($dbm,$key);
    my $value = $request->value($key);
    if (length($value) > 0) {
      $value = $self->langDateToSqlDatetime($value);
      $query .= "AND $key ";
      if ($fieldIsVarchar == 1) {
        $query .= "LIKE ";
        $value .= "%";
      } else {
        $query .= "= ";
      }
      $query .= $dbm->quote($value)." ";
    }
  }
  my $sth = $dbm->query($query);
  $sth->execute();

  if ($sth->rows()) {
    while (my @row = $sth->fetchrow_array()) {
      foreach (@row) {
        push @option, _sqlDatetimeToLangDate($_);
      }
      my $value = join "%20", @option;
      my $option = join ", ", @option;
      $string .= qq{<option value="};
      $string .= $value;
      $string .= qq{">};
      $string .= $option;
      $string .= qq{</option>\n};
      undef @option;
    }
  } else {
    $string .= qq{<option value="">No match found</option>\n};
  }

  $sth->finish();
  
  return $string;
}

# -----------------------------------------------

=head1 _sqlDatetimeToLangDate($field)

	IN: string
	OUT: string

	Convert a date format of type yyyy-mm-dd to dd.mm.yyyy 

=cut

sub _sqlDatetimeToLangDate
{
  my $field = shift;

  $field =~ s/(\d{4})(-)(\d{2})(-)(\d{2})(.*)/$5.$3.$1/;

  return $field;
}

# -----------------------------------------------

=head1 _normalFields($request,$session,$td)

	IN: object of GET/POST vars
	    object of session data
	    table cell options
	OUT: string

	Return the input fields for normal fields search

=cut

sub _normalFields
{
  my $request = shift;
  my $session = shift;
  my $td = shift;
  my $phnormalFields = $session->get("session_ph_normal_fields");
  my $panormalFieldsOrdered = $session->get("session_pa_normal_fields_ordered");
  
  my $string;
  my $inc = 1;
  
  foreach my $key (@$panormalFieldsOrdered) {
    my $value = $$phnormalFields{$key};
    $string .= qq{<tr>\n};
    $string .= qq{<td valign="bottom" $td>$value</td>};
    $string .= qq{<td valign="bottom"><input id="bcFormField$inc" type="text" value="};
    $string .= $request->value($key);
    $string .= qq{" name="$key"></td>};
    $string .= qq{</tr>\n};
    $inc++;
  }
  
  return $string;
}

# -----------------------------------------------

=head1 _keyField($keyLabel,$keyName,$keyValue,$td)

	IN: label
	    name
	    value
	    table cell options
	OUT: string

	Return the input text for the single key search 

=cut

sub _keyField
{
  my $keyLabel = shift;
  my $keyName = shift;
  my $keyValue = shift;
  my $td = shift;
  
  my $string = qq{<tr>\n};
  $string .= qq{<td $td>$keyLabel</td>\n};
  $string .= qq{<td>\n};
  $string .= qq{<input id="bcFormField0" type="text" autocomplete="off" name="$keyName" value="$keyValue" };
  $string .= qq{onKeyUp="ac()" onFocus="setClear()" style="width: 150px">&nbsp;};
  $string .= qq{<input type="submit" value="Suchen">&nbsp;};
  $string .= qq{<input type="reset" value="Löschen" onClick="resetFields()"></td>\n};
  $string .= qq{</tr>\n};

  return $string;
}

# -----------------------------------------------
# PUBLIC METHODS

=head1 $html = new HTML()

  Init a new main object
  
  PRE: PackageName
  POST: Object(Web::HTML)

=cut

sub new 
{
  my $cls = shift;
  my $self = {};

  bless $self, $cls;
   
  return $self;
}

# -----------------------------------------------

=head1 $html->getHeader()

  Return the header for the document

  PRE: Object(Web::HTML)
  POST: String(header)

=cut

sub getHeader
{
  my $self = shift;
  my $session = shift;
  
  my $onLoad;
  my $config = new Gewa::lib::Config();
  my $www = $config->getWWWDir();
  my $sid = $session->getSessionId();
  
  if (length($sid) > 0) {
    # User ist logged in
    $onLoad = qq{onLoad="setFocus()"};
  }
  
  my $string = qq{Content-type: text/html\n\n};
  $string .= qq{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">\n};
  $string .= qq{<html>\n};
  $string .= qq{<head>\n};
  $string .= qq{<script language="JavaScript" type="text/JavaScript" src="$www/js/functions.js"></script>\n};
  $string .= qq{<link rel="stylesheet" type="text/css" href="$www/css/styles.css">\n};
  $string .= qq{</head>\n};
  $string .= qq{<body $onLoad>\n};
  $string .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
 	$string .= qq{<tr>};
	$string .= qq{<td height="53" width="249" background="$www/img/header1.png">};
	$string .= qq{&nbsp;};
	$string .= qq{</td>};
	$string .= qq{<td height="53" colspan="2" background="$www/img/header2.png">};
	$string .= qq{&nbsp;};
	$string .= qq{</td>};
	$string .= qq{</tr>};

  return $string;
}

# -----------------------------------------------

=head1 $html->getLeftSide($session,$dbm)

  Return the left side (logo and login mask)
  of the document

  PRE: Object(lib::HTML)
       Object(lib::Session)
       Object(lib::DB)
  POST: String(data)

=cut

sub getLeftSide
{
  my $self = shift;
  my $request = shift;
  my $session = shift;
  my $dbc = shift;
  
	my $config = new Gewa::lib::Config();
	my $www = $config->getWWWDir();

  my $string = qq{<td valign="top">\n};
  $string .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
  #$string .= qq{<tr><td>\n};
  #$string .= $self->_getLogo();
  #$string .= qq{</td></tr>\n};
  $string .= $self->_getLogin($request,$session,$dbc);
  $string .= qq{</table>\n};
  $string .= qq{</td>\n};

  return $string;
}

# -----------------------------------------------

=head1 $html->getCenter($request,$session,$dbm)

  Return the center part of the document

  PRE: Object(lib::HTML)
       Object(lib::Request)
       Object(lib::Session)
       Object(lib::DB)
  POST: String(data)

=cut

sub getCenter
{
  my $self = shift;
  my $request = shift;
  my $session = shift;
  my $dbm = shift;

  my $config = new Gewa::lib::Config();
  my $cgi = $config->getCGIDir();
  my $sid = $session->getSessionId();
  my $keyLabel = $session->get("session_key_field_label");
  my $keyName = $session->get("session_key_field_name");
  my $nrOfInputFields = $session->get("session_nr_of_input_fields");
  my $keyValue = $request->value($keyName);
  my $td = qq{height="30"};

  # The form starts on method _getLogin()
  my $string = qq{<td valign="top">\n};
  $string .= qq{<input type="hidden" name="nrOfInputFields" value="$nrOfInputFields">\n};
  $string .= qq{<table border="0" cellpadding="10" cellspacing="0" width="100%">\n};
  $string .= qq{<tr><td class="title" height="40" valign="top">Barcodes erfassen</td></tr>\n};
  $string .= qq{<tr><td>\n};
  $string .= qq{<input type="hidden" name="sid" value="$sid">\n};
  $string .= qq{<table border="0" cellpadding="0" cellspacing="0" width="100%">\n};
  $string .= _keyField($keyLabel,$keyName,$keyValue,$td);
  $string .= qq{<tr><td>&nbsp;</td>};
  $string .= qq{<td><div id="ac" };
  if (length($keyValue) == 0) {
    $string .= qq{style="visibility: hidden"};
  } else {
    $string .= qq{style="visibility: visible"};
  }
  $string .= qq{>\n};
  $string .= qq{<select name="aclist" size="10" style="width: 450px" onchange="selectItem()">\n};
  if (length($keyValue) > 0) {
    $string .= $self->_autoCompleteOptions($request,$session,$dbm);
  }
  $string .= qq{</select>\n};
  $string .= qq{</td>\n};
  $string .= qq{</tr>\n};
  $string .= _normalFields($request,$session,$td);
  $string .= qq{<tr><td height="40">&nbsp;</td></tr>\n};
  $string .= qq{<tr>\n};
  $string .= qq{<td $td><input type="submit" name="bcPrint" value="Drucken"></td>\n};
  $string .= qq{</tr>\n};
  $string .= qq{</table>\n};
  $string .= qq{</form>\n};
  $string .= qq{</td></tr>\n};
  $string .= qq{</table>\n};
  $string .= qq{</td>\n};

  return $string;
}

# -----------------------------------------------

=head1 $html->getRightSide($request,$session,$dbc)

  Return the right side (latest printed barcodes)
  of the document

  PRE: Object(lib::HTML)
       Object(lib::Request)
       Object(lib::Session)
       Object(lib::DB)
  POST: String(data)

=cut

sub getRightSide
{
  my $self = shift;
  my $request = shift;
  my $session = shift;
  my $dbc = shift;

  my $config = new Gewa::lib::Config();
  my $cgi = $config->getCGIDir();
  my $uid = $session->get("session_uid");
  my $sid = $session->get("session_id");
  my $url = "$cgi/index.pl?sid=$sid";

  my $query = "SELECT Akte,Name,Vorname,MitgliedNr FROM archiv ";
  $query .= "WHERE BarcodeUser=".$dbc->quote($uid)." ";
  $query .= "AND isnull(BarcodeStorno) ";
  $query .= "ORDER BY BarcodeDatum DESC LIMIT 200";
  my $sth = $dbc->query($query);
  $sth->execute();
  
  my $string = qq{<td valign="top">\n};
  $string .= qq{<table border="0" cellpadding="10" cellspacing="0" width="100%">\n};
  $string .= qq{<tr><td class="title" height="40" valign="top" nowrap>Zuletzt gedruckt</td></tr>\n};
  $string .= qq{<form action="$cgi/index.pl" method="post">\n};
  $string .= qq{<input type="hidden" name="sid" value="$sid">\n};
  $string .= qq{<tr><td valign="top">\n};
  $string .= qq{<select name="id">\n};
  
  while (my @row = $sth->fetchrow_array()) {
    $string .= qq{<option value="$row[0]">$row[1] $row[2]</option>\n};
  }
 
  $sth->finish();
 
  $string .= qq{</select>\n};
  $string .= qq{</td></tr>};
  $string .= qq{<tr><td>&nbsp;</td></tr>\n};
  $string .= qq{<tr><td>\n};
  $string .= qq{<input type="submit" name="bcRePrint" value="Drucken">&nbsp;};
  $string .= qq{<input type="submit" name="bcStorno" value="Storno">};
  $string .= qq{</td></tr>\n};
  $string .= qq{</form>\n};
  $string .= qq{</td></tr>\n};
  $string .= qq{</table>\n};
  $string .= qq{</td>\n};

  return $string;
}

# -----------------------------------------------

=head1 $html->getFooter()

  Return the footer for the document

  PRE: Object(Web::HTML)
  POST: String(footer)

=cut

sub getFooter
{
  my $self = shift;

  my $string = qq{</table>\n};
  $string .= qq{</body>\n};
  $string .= qq{</html>\n};

  return $string;
}

# -----------------------------------------------

=head1 $html->langDateToSqlDatetime($date)

  Return an sql formatted datetime string
  given a language formatted date string

  PRE: Object(Web::HTML), String(date)
  POST: String(Datetime)

=cut

sub langDateToSqlDatetime
{
  my $self = shift;
  my $value = shift;

  my ($year,$month,$day);
  
  if ($value =~ /(\d{1,2})(\.)(\d{1,2})(\.)(\d{2,4})/) {
    $day = sprintf "%02d", $1;
    $month = sprintf "%02d", $3;
    if (length($5) == 2) {
      $year = "20".$5;  
    } else {
      $year = $5;
    }
    $value = "$year-$month-$day 00:00:00";
  }
  
  return $value;
}

1;

__END__

# Log record
# $Log: HTML.pm,v $
# Revision 1.1.1.1  2008/11/09 09:19:24  upfister
# Copy to sourceforge
#
# Revision 1.1.1.1  2007/02/10 14:15:23  up
# Initial code base ArchivistaBox 2007
#
# Revision 1.3  2005/11/24 12:52:48  ms
# Added POD
#
# Revision 1.2  2005/11/22 17:06:49  ms
# Barcodeprint and Workflow adaption to CI
#
# Revision 1.1  2005/11/21 10:40:43  ms
# Added to project
#
# Revision 1.2  2005/02/17 11:49:37  ms
# Import der Aenderungen auf dem gewa archivserver
#
# Revision 1.1  2005/01/21 15:58:38  ms
# Added files, new namespace Gewa
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
