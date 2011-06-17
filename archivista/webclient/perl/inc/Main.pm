# Archivista WebClient (c) 2008, Archivista GmbH, Urs Pfister

package inc::Main;

# Current revision $Revision: 1.119 $
# On branch $Name:  $
# Latest change by $Author: upfister $ on $Date: 2010/03/06 13:31:58 $

use strict;
#use CGI::Carp qw(fatalsToBrowser);
#use Data::Dumper ();
use inc::Check;

my %langtr; # All Language strings of all Languages!

BEGIN {
  use Exporter();
  use DynaLoader();
  @inc::Main::ISA    = qw(Exporter DynaLoader);
  @inc::Main::EXPORT = qw(Main);
  #use lib qw(/home/cvs/archivista/jobs/im2/objdir/api);
  use lib qw(/home/cvs/archivista/webclient/perl);
  use ExactImage;
  use File::Basename "basename";
  use File::Copy;
  use File::Temp "tempfile";
  use Archive::Zip;
  my %check; # check names used in hashes
	use constant CHECKIT => 0;
	if (CHECKIT==1) {
  $check{val} = [ # The hash var is under control
    'sid', # session id (bridge cookie->session table)
    'dbh', # database handler (application database)
    'dbh2', # session handler (mainly sessionweb table)
    'lang', # stores language code (de/en/fr)
    'mode', # what mode should be active (mainview,mainedit...)
    'error', # last error message (login form)
    'errorint', # error message for status line 
    'host', # host to logon
    'db', # database to logon
    'user', # user to logon
    'uid', # old synonym for user
    'pw', # password to logon
    'pwd', # old synonym for password
    'go', # current action
    'user_nr', # unique user id from user table
    'user_groups', # Pseudo archivista groups (xxx,yyy)
    'user_limit', # Max. number of records to show
    'user_level', # Rights: 0,1,2,3,255
    'user_new', # the owner for scanned documents
    'user_pwnew', # 0=no,1=pw,2=change,3=change (not empty)
    'user_addnew', # User can add 
    'user_sqlnew', # start sql definition
    'user_form', # form definition
    'user_web', # user can acces via web client
    'user_field', # custom field (e.g. used for printer to print)
    'workflow', # if >0, get start definition from workflow table
    'target', # change to the desired target windows (from outside)
    'showocr', # show the ocr text in detail form
    'newPassword', # give a new password for s user account
    'retypePassword', # confirmation of new password for a user acount
    'newPasswordCheck', # 0=don't check for a new pw, 1=check for new pw
    'pages', # number of pages in current document
    'docstart', # stores in which table frame we are (i.e. 0,16, 16,16, 32,16)
    'cookie', # the cookie we want send to the client side
    'rows', # stores current sql result
    'field_tab', # the current field tab definition   
    'field_obj', # the current field object definitions
    'fields', # store current field names
    'sqlstart', # starting point for current record frame
    'sqllimit', # number of records to show
    'sqlposrel', # relative position in search frame
    'searchmode', # NEW, AND, OR (type of sql request)
    'search_fulltext', # fulltext part in select sub sql string
    'fulltext_min', # first hit of fulltext search (pointer to array)
    'fulltext_max', # last hit of fulltext search (pointer to array)
    'jokerstart', # Joker at the Begin of text fields
    'jokerend', # Joker at the End of text fields
    'orderfield', # field after we want to order
    'selectnr', # desired selection number in a table
    'selectdoc', # desired document number in a table
    'selectpage', # desired page in selected document
    'imagedoc', # desired image to view (document number)
    'imagepage', # desired image to view (page number)
    'imagew', # width of the available destination range
    'imageh', # height of the available destination range
    'imagefast', # fast b/w image downsize (bader quality)
    'imagehigh', # give (if available) always high resolution copy back
    'imgdoc', # goes to imagedoc (from function key)
    'imgpage', # goes to imagedoc (from function key)
    'imghigh', # if available (get high resolution)
    'imagerotate', # 0,90,180,270
    'imagezoom', # 0 .. 1
    'action', # action from main view
    'action2', # action from page view
    'print_list', # Printing Page or Document
    'print_from', # Start Page to Print
    'print_to',   # End Page to Print
    'owner', # owner from main view
    'hostslave', # store in session if we are in slave mode
    'docowner', # store in session what owner the current doc has
    'edvname', # store the edvname (file name)
    'ajaxfield', # field for auto completion
    'ajaxval', # value for auto completion
    'list_1_field', # field 1 to add information
    'list_1_val', # value for field 1
    'list_2_field', # field 2 to add information
    'list_2_val', # value for field 2
    'list_type', # type of the field
    'go_list', # command (add, del)
    'linked', # name of field for 1toN type (ajax)
    'val', # value of field from fld name (ajax)
    'type', # type of the ajax field
    'jump', # jump to a page
    'seldocs', # gives back the selected document(s) (from JavaScript)
    '$fld', # field values
    '$fld1', # field1 values
    'zoom', # current zoom factor after slider change (ajax)
    'view', # main/page view mode
    'state', # view/search/edit state mode
    'key', # key that was pressed (instead of mouse click)
    'shft', # shift key was pressed (instead of mouse click)
    'alt', # alt key was pressed (instead of mouse click)
    'ctrl', # ctrl key was pressed (instead of mouse click)
    'deleted', # store the last deleted documents/pages
    'ocrdoc', # used to get a text from a document (given doc nr)
    'ocrpage', # used to get a text from a document (given page nr)
    'meta', # field to give values while scanning via external access
    '$arr[0]', # compare it when reading it from get/post
    'firefox', # decide if we are in firefox or not
    'exportdb', # name of the db we use for an export of documents
    '$chk', # check if we need a hidden form
    '$fld2', # link to 1:N field
    '$_', # default variable
    'scandef', # scandefinition Number for scanning
    'append_to', # Append Scan to Document?
    'post', # Content (val) of the post method (incl. file)
    'filename', # Filename of the uploaded file
    'filestart', # start position of file
    'filelength', # length of the file
    'uploadbits', # bits for uploading file
    'uploadocr', # ocr definition for uploaded file
    'uploaddef', # definition we use to upload files
    'adddocs', # Show adddocs menu=1 or do not show adddocs menu=0
    'mailstatus', # give back 'Ok' or 'Cancel' (do not send mail)
    'avversion', # hidden value for version information
    'copyselect', # select the current document, so it is active
    'reconnect', # reconnect at this call (external access)
    'note_index', # the index of current note
    'note_doc', # document for note
    'note_page', # page for note
    'note_cWidth', # note parameter sent by ajax
    'note_cHeight', # note parameter sent by ajax
    'note_cRotate', # note parameter sent by ajax
    'note_cZoom', # note parameter sent by ajax
    'note_bColor', # note parameter sent by ajax
    'note_bWidth', # note parameter sent by ajax
    'note_bgTop', # note parameter sent by ajax
    'note_bgLeft', # note parameter sent by ajax
    'note_bgWidth', # note parameter sent by ajax
    'note_bgHeight', # note parameter sent by ajax
    'note_bgColor', # note parameter sent by ajax
    'note_bgOpacity', # note parameter sent by ajax
    'note_fgColor', # note parameter sent by ajax
    'note_fgFamily', # note parameter sent by ajax
    'note_fgSize', # note parameter sent by ajax
    'note_fgItalic', # note parameter sent by ajax
    'note_fgBold', # note parameter sent by ajax
    'note_fgUnderline', # note parameter sent by ajax
    'note_fgText', # note parameter sent by ajax
    'note_fgRotation', # note parameter sent by ajax
    'note_editable', # note parameter sent by ajax
    'result_offset', # main results table ajax, first record
    'result_length', # main results table, block length
    'result_doc', # main results record, doc to load
    'result_page', # main results record, page to load
    'result_index', # main results record, which row
    'result_tab', # which tab user clicked on
    'result_thumbs', # user asked for thumbnail view
		'result_image', # used to store if we are switching main/page view
		'result_move', # always move to a desired page
		"result_utf8", # if 1 then convert back to iso8859-1 chars
		'redirect', # 1 redirect to main page (after login)
		'pdfdocs', # doclist to generate a single pdf file, i.e. 4,3,2,1,5
		'pdfname', # document name for single pdf file   
		'docnr', # document number for deleteing a page
		'docpage', # page inside of docnr or current document (if no docnr)
  ];

  $check{usp} = [ # The hash usp is under control
    'mode', # mainview,mainsearch,mainedit,pageview,pagesearch,pagedit
    'doc', # the current document
    'page', # the current page
    'sqlquery', # last sql query
    'sqlorder', # last order by
    'sqlpos', # current record in selection
    'sqlstart', # default sql query for user
    'sqlfulltext', # last fulltext
    'sqlftspeed', # don't show detailed fulltext
    'sqlftmax', # max. number of results in fulltext
    'sqlrecords', # Number of records after selection
    'publishfield', # publish field (according db)
    'exportallowed', # store information about export of docs from web client
    'photomode', # photomode (if it is on, then 1)
    'titlehide', # don't show title field
    'titlewidth', # width of title column
    'target', # the desired target where we show the results
    'showocr', # store if we need to show ocr text in detail form
    'showpdf', # show the pdf download link the table         
    'lang', # used language between sessions
    'rotate', # rotation angle (0,90,180,270)
    'zoom', # zoom factor
    'hideowner', # don't show owner field
    'editOwner', # the selected owner 
    'editAction', # the selected action
    'ajaxlimit', # the limit of shown elements
    'archivefolders', # number of folders for extended table structure
		'fulltextengine', # 0=no fulltext, 1=mysql, 2=sphinx
		'orderanyway', # always order according to a given field (or default)
		'showeditfield', # decide if we show edit field or not
    '$_' # default variable
		
  ];
	} # end of checkit mode
  ### Load File
  my $file = "/usr/lib/perl5/site_perl/languages.txt";
	$file = "/etc/perl/languages.txt" if !-e $file;
  my %de;
  my %en;
  my %fr;
  my %it;
  $langtr{de} = \%de;
  $langtr{en} = \%en;
  $langtr{fr} = \%fr;
  $langtr{it} = \%it;
  open(FLANG,"<",$file);
  binmode(FLANG);
  while (my $line = <FLANG>) {
    $line =~ /^(.+?)\t(.*?)\t(.+?)\t(.+?)\t(.+?)\t(.+?)\t(.*)$/;
    my $key = $1;
    my $pos = index($key,'web_');
    if ($pos==0) {
      $key = substr($key,4,length($key)-4); 
      my $de = $3;
      my $en = $4;
      my $fr = $5;
      my $it = $6;
      $langtr{'de'}->{$key} = $de;
      $langtr{'en'}->{$key} = $en;
      $langtr{'fr'}->{$key} = $fr;
      $langtr{'it'}->{$key} = $it;
    }
  }
  close(FLANG);
  ### File Loaded
  inc::Check::hashes(__PACKAGE__,\%check) if CHECKIT==1;
  use obj::Note;
}

use DBI;
use Digest::MD5 qw(md5_hex);
use inc::Global;
use inc::ExLogin;
use POSIX qw(locale_h);
setlocale(LC_COLLATE, "german");
setlocale(LC_CTYPE, "german");
use locale;
use Encode;


my %tr; # translations
my %usp; # session information (get at the beginning, saving at the end)
my %val; # parameter from get/post + internal variables (not saved)

use constant CGIDIR => "/perl/avclient";
use constant CGIPRG => "/index.pl";
use constant WWWDIR => "/avclient";
use constant DOCROOT => "/home/cvs/archivista/webclient/www";
use constant DB_JOBS => 'archivista';
use constant TABLE_ARCHIVE => 'archiv';
use constant TABLE_IMAGES => 'archivbilder';
use constant TABLE_ARCHIVED => 'archimg';
use constant TABLE_PAGES => 'archivseiten';
use constant TABLE_JOBS => 'jobs';
use constant TABLE_JOBSDATA => 'jobs_data';
use constant TABLE_SESSION => 'sessionweb';
use constant TABLE_ACCESS => 'access';
use constant AV_VERSIONTEXT => '2011/IV';
use constant AV_VERSIONNR => '520';
use constant AV_NAME => 'Archivista';
use constant MYSQL_PORT => 3306;
use constant TEMP_PATH => '/home/data/archivista/tmp/';
use constant PRG_JPG => 'jpeg2ps';
use constant PRG_PS2PDF => 'ps2pdf';
use constant TARGET => '_top';
use constant WRAP_COLUMNS => ''; # or 'nowrap ';
use constant SLASH => '/';
use constant FIELD_WIDTH => 15; # Dividor for field width (1pixel=15units)
use constant TABLE_HEIGHT => 308; # Height of the table
use constant LANG_EN => "en"; # default language
use constant LANG_DE => "de"; # german language
use constant LANG_FR => "fr"; # french language
use constant LANG_IT => "it"; # italian language
use constant ICONTYPE => ".gif"; # Type for button icons
use constant AVFORM => "avform"; # form name
use constant SQL_LIMIT => 16; # Number of records
use constant ACCESS_LOG => "ACCESS_LOG"; # if 1, access log is activated
use constant VERSIONS => 'VERSIONS'; # field for versioning
use constant VERSIONKEY => 'VERSIONKEY'; # key field for versioning
use constant PDFWHOLEDOC => 'PDFWHOLEDOC'; # 1=whole doc,0=single page
use constant SEARCH_FULLTEXT => "SEARCH_FULLTEXT"; # fulltext search field
use constant AVVERSION => "AVVersion"; # value for version number 
use constant SCAN_DEFS => "ScannenDefinitionen"; # scan defs  
use constant OCR_DONE => -1; # Ausschliessen=0,Erfasst=1 in archivseiten
use constant OCR_EXCLUDE => -2; # Ausschliessen=1,Erfasst=0 in archivseiten
use constant HIDE_EXTICONS => 'HideExtIcons'; # 0=show ext. icons/1=hide

# 'Ok' value of a standard submit button, if checkConfirm is enabled
# and user pressed 'Cancel', then submit value will be changed to 'Cancel'
use constant OK => 'Ok'; 
use constant CANCEL => 'Cancel';

use constant GO => 'go_'; # init go value
use constant GO_LOGOUT => GO.'_logout'; # logout
use constant GO_PAGEVIEW => GO.'pageview'; # switch to pageview
use constant GO_PAGESWITCH => GO.'pageswitch'; # switch between page/main view
use constant GO_THUMBS => GO.'thumbs'; # switch to photomode (or back)
use constant GO_ALL => GO.'all'; # select all docs
use constant GO_DOCS_PREV => GO.'docs_prev'; # one frame back
use constant GO_DOC_PREV => GO.'doc_prev'; # one record back
use constant GO_PAGE_FIRST => GO.'page_first'; # go to first page
use constant GO_PAGE_PREV => GO.'page_prev'; # go one page back
use constant GO_PAGE_JUMP => GO.'page_jump'; # jump to a certain page
use constant GO_PAGE_NEXT => GO.'page_next'; # go to next page
use constant GO_PAGE_LAST => GO.'page_last'; # go to last page
use constant GO_DOC_NEXT => GO.'doc_next'; # go to next doc
use constant GO_DOCS_NEXT => GO.'docs_next'; # go to next frame
use constant GO_MAINVIEW => GO.'mainview'; # switch to main view
use constant GO_ROTATE_LEFT => GO.'rotate_left'; # rotate left
use constant GO_ROTATE_180 => GO.'rotate_180'; # rotate 180 degree
use constant GO_ROTATE_RIGHT => GO.'rotate_right'; # rotate right
use constant GO_ZOOM => GO.'zoom'; # used with val{zoom} to get scaled image
use constant GO_ZOOM_NO => GO.'zoom_no'; # no zoom (full screen)
use constant GO_ZOOM_IN => GO.'zoom_in'; # zoom in
use constant GO_ZOOM_OUT => GO.'zoom_out'; # zoom out
use constant GO_VIEW => GO.'view'; # switch to view mode 
use constant GO_SEARCH => GO.'search'; # switch to search mode
use constant GO_EDIT => GO.'edit'; # switch to edit mode
use constant GO_UPDATE => GO.'update'; # update the fields
use constant GO_QUERY => GO.'query'; # new query for documents
use constant GO_QUERYFILE => GO.'queryfile'; # new query for documents
use constant GO_ORDER_ASC => GO.'order_asc'; # sort asc after $val{orderfield}
use constant GO_ORDER_DESC => GO.'order_desc'; # sort desc after orderfield
use constant GO_SELECT => GO.'select'; # select a row from the showd table
use constant GO_PDF => GO.'pdf'; # download the pdf file from a document
use constant GO_PDFS => GO.'pdfs'; # download a certain number of pdfs
use constant GO_CREATEPDFS => GO.'createpdfs'; # download the pdf file from a document
use constant GO_IMAGE => GO.'image'; # print out an image given an id
use constant GO_MAIL => GO."mail"; # send back mail to mail server
use constant GO_FILE => GO."file"; # send back file (not zipped)
use constant GO_ZIP => GO."zip"; # send back zipped mail to client
use constant GO_AJAX => GO.'ajax'; # print out autocomplete fields (ajax)
use constant GO_LIST => GO.'list'; # handles adding/removing list entries
use constant GO_HELP => GO.'help'; # access to manual (pdf)
use constant GO_PRINT => GO.'print'; # Print the Selection of Pages/Documents
use constant GO_DELETE => GO."delete"; # used while del. docs (not f. outside) 
use constant GO_TEXT => GO."text"; # Return the OCR Text of a Page
use constant GO_UPLOAD => GO."upload"; # Upload an image/pdf to the archive
use constant GO_ACT_SCAN => GO."act_scan"; # Activate first scan-definition
use constant GO_ACT_UPLOAD => GO."act_upload"; # Activate upload menu
use constant GO_COPY => GO."copy"; # copy current meta key as a new document

use constant GO_NOTE => GO."note"; # note-related ajax calls
use constant GO_RESULT => GO."result"; # main results table related ajax calls

use constant ACTION => "action"; # extended actions (go_ not included) 
use constant ACTION2 => "action2"; # extended actions in page view)
use constant OWNER => "owner"; # extended users (")
use constant GO_ACTION => GO.ACTION; # extended action (main/page view)
use constant GO_ACTION2 => GO.ACTION2; # extended action (main/page view)

use constant MAIN => 'main'; # show table, currect record and small image
use constant PAGE => 'page'; # show only image (but big one)
use constant VIEW => 'view'; # display records
use constant SEARCH => 'search'; # search for records
use constant EDIT => 'edit'; # edit records 

use constant USER_LEVEL_VIEW => 0; # No edit rights
use constant USER_LEVEL_EDIT => 1; # Edit rights, but only for user/groups
use constant USER_LEVEL_VIEW_ALL => 2; # View all, edit only user/groups
use constant USER_LEVEL_EDIT_ALL => 3; # View all, edit all
use constant USER_LEVEL_SYSOP => 255; # Archive administrator rights
use constant USER_PW_NO => 0;
use constant USER_PW_SET => 1;
use constant USER_PW_CHANGE_INC_EMPTY => 2;
use constant USER_PW_CHANGE_NOT_EMPTY => 3;

use constant DEF_OCR => "OCRSets"; # where the ocr definitions are
use constant DEF_SCAN => "ScannenDefinitionen"; # same for scan defs

use constant TYPE_CHAR => 'varchar'; # mysql field types
use constant TYPE_CHARFIX => 'char';
use constant TYPE_TIMESTAMP => 'timestamp';
use constant TYPE_YESNO => 'tinyint';
use constant TYPE_INT => 'int';
use constant TYPE_BLOB => 'blob';
use constant TYPE_TEXT => 'text';
use constant TYPE_MEDIUMBLOB => 'mediumblob';
use constant TYPE_LONGBLOB => 'longblob';
use constant TYPE_DATE => 'datetime';
use constant TYPE_KEY => 'PRI';
use constant TYPE_FULLTEXT => 'fulltext';

use constant AV_NORMAL => 0; # normal archivista field format
use constant AV_CODETEXT => 3; # text code, belongs to definition
use constant AV_DEFINITION => 4; # definition field
use constant AV_CODENUMBER => 6; # number code, belongs to definition
use constant AV_1TON => 5; # 1 to N definition, belongs to definition
use constant AV_MULTI => 7; # multi fields, belongs to definition
use constant AV_TEXT => -1; # note fields

use constant SRCH_NEW => 'new'; # for searchmode value (val)
use constant SRCH_OR => 'or';
use constant SRCH_AND => 'and';
use constant SRCH => 'searchmode';
use constant JOKERSTART => 'jokerstart';
use constant JOKEREND => 'jokerend';
use constant FULLTEXT => 'fulltext';

# constants for %usp hash

# some sql commands
use constant SQL_LASTID => "SELECT LAST_INSERT_ID()";






=head1 Main()

This is the main entry point to the application

=cut

sub Main {
  %val= DataRequest(); # read the values (raw format)
  #foreach (keys %val) {
  #  logit("$_ $val{$_}") if length($val{$_})<1000;
  #}
  #logit("\n"x4);
  MainCheckInput(); # check the values and choose an action
  $val{error}=""; # no error message
  $val{dbh2}=dbhOpen(1); # open a global dbh handler (1 IS NEEDED)
  $val{sid}=getCookie("sid"); # get the cookie
  MainCloseSession() if $val{reconnect}==1; # close session if needed
  if ($val{go} eq GO_IMAGE) {
    MainImage(); # print out an image
  } elsif ($val{go} eq GO_LIST) {
    MainList() if MainLoginDo(); # add/update/delete feldlisten
  } elsif ($val{go} eq GO_AJAX) {
    MainAjax() if MainLoginDo(); # compose feldlisten values for a field
  } elsif ($val{go} eq GO_ZIP) {
    MainSend("zip") if MainLoginDo(); # download desired file zipped
  } elsif ($val{go} eq GO_FILE) {
    MainSend("file") if MainLoginDo(); # download desired file unzipped
  } elsif ($val{go} eq GO_PDF) {
    MainPDF() if MainLoginDo(); # show the desired pdf
  } elsif ($val{go} eq GO_PDFS) {
    MainPDFS(1) if MainLoginDo(); # show the desired pdfs (print it out)
  } elsif ($val{go} eq GO_CREATEPDFS) {
    MainPDFS(1,$usp{doc}) if MainLoginDo(); # show the desired pdfs (print it)
  } elsif ($val{go} eq GO_TEXT) {
    MainText() if MainLoginDo(); # show the ocr text of a page
  } elsif ($val{go} eq GO_NOTE) {
    MainNote() if MainLoginDo(); # handle note-related ajax
  } elsif ($val{go} eq GO_RESULT) {
    MainResult() if MainLoginDo(); # handle main result table related ajax
  } else {
    MainMain(1); # Do all the rest (check always for access log)
  }
	$val{dbh}->disconnect() if $val{dbh};
	$val{dbh2}->disconnect() if $val{dbh2};
}






=head MainMain($chkaccesslog)

Standard session (print out whole form)

=cut

sub MainMain {
  my $chk = shift;
  if (MainLoginDo(1)) { # here we need to give a 1 (checkLogin)
    MainAction(); # process the desired action
	  my $chk = "frm_Laufnummer";
		MainSelection() if $val{$chk}==1;
    MainOut(); # print out form
    MainAccessLog($val{go},$usp{doc},$usp{page}) if $chk==1; # check if log
    MainUpdateSession(); # save the changed session values
  } else {
    MainOut(); # print out standard form
  }
}






=head1 MainAccessLog()

Check if we need to log the the actions

=cut

sub MainAccessLog {
  my $action = shift;
  my $doc = shift;
  my $page = shift;
  return if $val{dbh}==0;
  my $dbh = $val{dbh};
  $dbh = $val{dbh2} if $val{host} eq "localhost";
  if (getParameterValue(ACCESS_LOG)) {
    my $string = "page=$page;";
    if ($action eq GO_UPDATE) {
      $string .= MainAccessLogTimeMod($doc);
      my $prow = ${$val{rows}}[$val{selectnr}]; # get current records values
      my $pos = 0;
      foreach (@{$val{fields}}) { # go through all fields
        $string .= $_->{name}."=".$$prow[$pos].";";
        $pos++;
      }
    } elsif ($action eq GO_QUERY || $action eq GO_QUERYFILE) {
      $string .= "query=$usp{sqlquery};";
      $string .= "order=$usp{sqlorder};";
      $string .= "fulltext=$usp{sqlfulltext};";
    } elsif ($val{go} eq GO_ACTION && $usp{editAction} eq "deletepage") {
      $string .= MainAccessLogTimeMod($doc);
      $string .= "delete_page=$val{deleted};";
      $action = "go_delete_page";
    } elsif ($val{go} eq GO_ACTION && $usp{editAction} eq "savepage") {
      $string .= MainAccessLogTimeMod($doc);
      my $pagedoc = getPageNumber($doc,$page);
      my $sql = "select BildInput from ".TABLE_IMAGES." where Seite=$pagedoc";
      my $image = getSQLOneValue($sql);
      my $hash = md5_hex $image;
      $string .= "imagehash=$hash;";
      $action = "go_save_page";
    }
    my $sql = "";
    $sql .= "host=".SQLQuote($val{host});
    $sql .= ",db=".SQLQuote($val{db});
    $sql .= ",user=".SQLQuote($val{user});
    $doc=0 if $doc eq ""; # if no document is available say we are at 0
    $sql .= ",document=".$doc;
    $action =~ s/^go\_(.*)$/$1/; # remove the go_
    $sql .= ",action=".SQLQuote($action);
    $sql .= ",additional=".SQLQuote($string);
    $sql = "insert into ".TABLE_ACCESS." set $sql";
    SQLUpdate($sql,$dbh);
    my $id = getSQLOneValue(SQL_LASTID,$dbh);
    my $id2 = $id-1;
    my $hash = "";
    if ($id2>0) {
      my $sql2 = "select hash from ".TABLE_ACCESS." where id=$id2";
      $hash = getSQLOneValue($sql2,$dbh);
    }
    $string = "$sql$hash";
    $hash = md5_hex $string;
    $sql = "update ".TABLE_ACCESS." set hash=".SQLQuote($hash).
           "where id=$id";
    SQLUpdate($sql,$dbh);
  }
}






=head1 $string=MainAccessLogTimeMod()

Get the last mod time and the user from the archive table

=cut

sub MainAccessLogTimeMod {
  my $doc = shift;
  my $sql = "select UserModDatum,UserModName from ".TABLE_ARCHIVE." ".
            "where Laufnummer=$doc";
  my @row = getSQLOneRow($sql);
  my $string = "moddate=$row[0];moduser=$row[1];";
  return $string;
}






=head1 MainCheckInput()

Check if we clicked to a image submit button (starts with go_)

=cut

sub MainCheckInput {
  my $found = 0;
  if ($val{go} eq "") {
    my @keys = keys %val;
    my @arr = grep(/^go\_/,@keys);
    my $button = $arr[0];
    if ($button ne "") {
      my ($go,$name,$nr,$id,$w,$h,$opt1,$opt2,$opt3,$opt4) = split(/\_/,$button);
      if ($name eq "select" && $nr>=0 && $id>0) {
        $val{go}=GO_SELECT;
        $val{selectnr}=$nr;
        $val{selectdoc}=$id;
        $val{selectpage}=$w;
      } elsif ($name eq "pdf") {
        $val{go}=GO_PDF;
        $val{selectdoc}=$id;
      } elsif ($name eq "list") {
        $val{go}=GO_LIST;
      } elsif ($name eq "mail" && $nr>0) {
        $val{go}=GO_ACTION;
        $val{action}="mail";
        $val{selectdoc}=$nr;
      } elsif ($name eq "zip" && $nr>0) {
        $val{go}=GO_ZIP;
        $val{selectdoc}=$nr;
      } elsif ($name eq "file" && $nr>0) {
        $val{go}=GO_FILE;
        $val{selectdoc}=$nr;
      } elsif ($name eq "image" && $nr>0 && $id>=0) {
        $val{go}=GO_IMAGE;
        $val{imagedoc}=$nr;
        $val{imagepage}=$id;
        $val{imagew}=$w-2;
        $val{imageh}=$h-2;
        $val{imagefast}=$opt1;
        $val{imagehigh}=$opt2;
        $val{imagerotate}=$opt3;
        $val{imagezoom}=$opt4;
      } elsif ($name eq "logout") {
        $val{go}=GO_LOGOUT;
      } elsif ($name eq "scan") {
        $val{go}=GO_ACTION;
        $val{scandef}=0 if $val{scandef} eq ""; # if no scan def, use first
        $val{action}="scan!$val{scandef}";
        # append to document?
        $val{seldocs}=$val{append_to} if $val{append_to};
      } elsif ($name eq "upload") {
        $val{go}=GO_ACTION;
        $val{action}=$name;
      } elsif ($name eq "note") {
        $val{go}=GO_NOTE;
        $val{action}=$nr;
        $val{action}=~s/\.[xy]//;
      } elsif ($name eq "result") {
        $val{go}=GO_RESULT;
        $val{action}=$nr;
      } else {
        $button =~ s/^(go\_)(.*?)(\.)(.*)$/$1$2/;
        if ($button ne $arr[0] && $button ne "") {
          $val{go}=$button;
        } elsif ($button eq $arr[0]) {
          if ($val{$arr[0]} ne CANCEL) {
            $val{go}=$button;
          }
        }
      }
    } else {
      my @arr = grep(/^ord/,@keys); # check for order commands (asc/desc)
      if ($arr[0] ne "") {
        $button = $arr[0];
        $button =~ s/^ord(.*?)\_(.*?)$/$1$2/;
        if ($button ne $arr[0] && $button ne "") {
          $val{go}=GO_ORDER_ASC;
          $val{go}=GO_ORDER_DESC if $1 eq "Desc";
          $val{orderfield}=$2;
        }
      } else {
        my @arr = grep(/^drp/,@keys); # check for ajax
        if ($arr[0] ne "") {
          $button = $arr[0];

          # strip off 'drp' and .x/.y
          $button =~ s/^drp_(.*?\_.*?)\..*$/$1/;

          if ($button ne $arr[0] && $button ne "") {
            $val{go}=GO_AJAX;
            $val{ajaxfield}=$button;
            # strip off 'edit/search'
            $val{ajaxfield} =~ s/^.*?_//;
            my $fld = 'fld_'.$button;
            $val{ajaxval}=$val{$fld};
            $found=1;
          }
        }
        if ($found==0) {
          @arr = grep(/^fld/,@keys);
          foreach my $fld (@arr) {
            if ($val{$fld} ne "") {
              $val{go}=GO_AJAX;
              $val{ajaxfield}=$fld;
              # strip off 'fld' and 'edit/search'
              $val{ajaxfield} =~ s/^.*?_.*?_//;
              $val{linked} =~ s/^.*?_//;
              $val{ajaxval}=$val{$fld};
            }
          }
        }
      }
    }
		if ($val{go} eq GO_ACTION && $val{action} eq "createpdfs") {
      $val{pdfdocs} = $val{seldocs};
		  $val{go} = GO_CREATEPDFS; 
		}
  } else {
    my $val = $val{go};
    if ($val>0) {
      my $fld = "fld_search_Laufnummer";
      $val{$fld} = "$val";
      $val{go} = GO_QUERY;
      $val{mode} = MAIN.SEARCH;
      $val{searchmode} = SRCH_NEW;
		}
  } 
  if ($found==0) {
    $val{go} = GO_ZOOM if $val{zoom}>0;
    $val{go} = GO_ALL  if $val{go} eq "";
    $val{user} = $val{uid} if $val{uid} ne "";
    $val{pw} = $val{pwd} if $val{pwd} ne "";
    if ($val{key}>0) {
      MainCheckInputKeys();
    } elsif ($val{key} ne "") {
      $val{go}=$val{key};
    }
  }
}






=head MainCheckInputKeys

Check if a  function key is pressed an compose action

=cut

sub MainCheckInputKeys {
  if ($val{key}==2) {
    if ($val{ctrl}==1 && $val{shft}==1) {
      $val{go} = GO_PAGE_JUMP;
    } else {
      if ($val{state} eq "main") { # we are in main view
        if ($val{shft}==1) {
          $val{go} = GO_ACT_UPLOAD;
        } elsif ($val{ctrl}==1 && $val{jokerend} eq '') { # update mode, so save
          $val{go} = GO_UPDATE;
        } elsif (index($val{action},"scan")==0) {
          $val{go} = GO_ACTION;
        } else { # go to first scan definition
          $val{go} = GO_ACT_SCAN;
        }
      } else { # we are in page mode, so zoom in or zoom out
        $val{go} = GO_ZOOM;
        if ($val{ctrl}==1) {
          $val{zoom}=1;
        } elsif ($val{shft}==1) {
          $val{zoom}=0;
        } else {
          $val{zoom}=-1;
        }
      }
    }
  } elsif ($val{key}==3) {
    if ($val{shft}==0 && $val{ctrl}==0) {
      $val{go} = GO_DOC_PREV;
    } elsif ($val{shft}==1 && $val{ctrl}==0) {
      $val{go} = GO_PAGE_PREV;
    } elsif ($val{shft}==0 && $val{ctrl}==1) {
      $val{go} = GO_DOCS_PREV;
    } elsif ($val{shft}==1 && $val{ctrl}==1) {
      $val{go} = GO_PAGE_FIRST;
    }
  } elsif ($val{key}==4) {
    if ($val{shft}==0 && $val{ctrl}==0) {
      $val{go} = GO_DOC_NEXT;
    } elsif ($val{shft}==1 && $val{ctrl}==0) {
      $val{go} = GO_PAGE_NEXT;
    } elsif ($val{shft}==0 && $val{ctrl}==1) {
      $val{go} = GO_DOCS_NEXT;
    } elsif ($val{shft}==1 && $val{ctrl}==1) {
      $val{go} = GO_PAGE_LAST;
    }
  } elsif ($val{key}==5) {
    if ($val{shft}==0 && $val{ctrl}==0) {
      if ($val{jokerend} eq '') { # update mode, so save
        $val{go} = GO_SEARCH;
      } else {
        $val{go} = GO_QUERY;
      }
    } elsif ($val{shft}==1 && $val{ctrl}==0) {
      $val{go} = GO_EDIT;
    } elsif ($val{shft}==0 && $val{ctrl}==1) {
      $val{go} = GO_VIEW;
    } elsif ($val{shft}==1 && $val{ctrl}==1) {
      $val{go} = GO_UPDATE;
    }
  } elsif ($val{key}==6) {
    if ($val{shft}==0) {
      $val{go} = GO_ALL;
    }
  } elsif ($val{key}==7) {
    if ($val{shft}==1) {
      $val{go} = GO_ROTATE_180;
    } else {
      $val{go} = GO_ROTATE_LEFT;
    }
  } elsif ($val{key}==8) {
    if ($val{shft}==1) {
      $val{go} = GO_ROTATE_180;
    } else {
      $val{go} = GO_ROTATE_RIGHT;
    }
  } elsif ($val{key}==9) {
    if ($val{shft}==1 && $val{ctrl}==1) {
      $val{go} = GO_IMAGE;
      $val{imagedoc}=$val{imgdoc};
      $val{imagepage}=$val{imgpage};
    } elsif ($val{shft}==1) {
      $val{go} = GO_THUMBS;
    } elsif ($val{ctrl}==1) {
      $val{go} = GO_PDF;
    } else {
      $val{go} = GO_PAGESWITCH;
    }
  } elsif ($val{key}==12) {
    $val{go} = GO_LOGOUT;
  } elsif ($val{key}==67) {
    $val{go} = GO_COPY;
  } elsif ($val{key}==86) {
    print STDERR "PASTE\n";
  }
}






=head1 MainPDFs

Send out doc from a list to one pdf document

=cut

sub MainPDFS {
  my ($output,$docnr) = @_;
  my $docs = $val{pdfdocs};
	$docs = $docnr if $docnr>0 && $docs eq "";
	my $docname = $val{pdfname};
	$docname="all.pdf" if $docname eq "";
	my @docs = split(",",$docs);
	my @files = ();
	my $err = 0;
	my $multi = 1;
	foreach (@docs) {
	  $val{selectdoc} = $_;
    my $filetemp = writeTempFile("");
		$filetemp=MainPDF($filetemp,$multi);
		if (-s $filetemp) {
		  push @files,$filetemp;
		} else {
		  unlink $filetemp if -e $filetemp;
		  $err=1;
		}
	}
	my $file1 = "";
  $file1 = writeTempFile(" ");
  $file1 = getTempFile($file1,'.pdf',1);
  my $dopdf="pdftk ".join(" ",@files)." output $file1";
	system($dopdf);
	if ($output==1) {
    my $pfile = getFile2($file1,1);
    MainPDFSend("pdf",$pfile,$docname);
	}
	foreach my $file (@files) {
	  unlink $file if -e $file;
	}
	return $file1;
}






=head1 $filetemp=MainPDF($filetemp)

Send source file to client

=cut

sub MainPDF {
  my ($filetemp,$multi) = @_;
  $val{selectdoc}=$usp{doc} if $val{selectdoc}==0;
  my $sql = "SELECT Seiten,QuelleExt,ArchivArt,Ordner,Archiviert " .
            "FROM archiv WHERE Laufnummer=" .
            "$val{selectdoc} ".getEigentuemerZusatz();
  my ($pages,$sourceExt,$archivart,$folder,$archived) = getSQLOneRow($sql);
  my $firstPage = getPageNumber($val{selectdoc});
  my $lastPage = getPageNumber($val{selectdoc},$pages);
  my $docName = $val{selectdoc};
  my $page = 1;
  $sourceExt = "pdf" if $sourceExt eq "";
  my $prow = getBlobFile("Quelle",$lastPage,$folder,$archived);
  if (length($$prow[0])>0) {
    if ($val{selectdoc}==$usp{doc} && $usp{page}>0) {
      $firstPage = getPageNumber($usp{doc},$usp{page});
      $page = $usp{page};
    }
    $docName=$firstPage;
  }
  $sql = "select count(Notes) from archivseiten where " .
         "Seite between $firstPage and $lastPage AND " .
         "Notes != '' and Notes is not null";
  my $notes = getSQLOneValue($sql);
  $prow = getBlobFile("Quelle",$firstPage,$folder,$archived);
  if (length($$prow[0])>0 && $notes==0) {
    $filetemp=MainPDFSend($sourceExt,\$$prow[0],$docName,"",$filetemp,$multi);
  } else {
    $filetemp=MainPDFCreate($val{selectdoc},$page,$pages,$archivart,
		                        $folder,$archived,$filetemp,$multi);
  }
	return $filetemp;
}






=head1 $filetemp=MainPDFSend($sourceExt,$pfile,$pdfname,$filename,$filetemp)

Send out a source file to the client

=cut

sub MainPDFSend {
  my $sourceExt = shift;
  my $pfile = shift;
  my $displayedPage = shift;
  my $filename = shift;
	my $filetemp = shift;
	my $multi = shift;
  my $contentType = MainContentType($sourceExt);
  $displayedPage .= "." . lc($sourceExt);
  $displayedPage = $filename if $filename ne "";
	if ($filetemp eq "") {
    if (length($$pfile)>0) {
      # say to the browser that we send him a pdf file (2. line: explorer)
      print "Content-type: $contentType\n";
      print "Content-length: ".length($$pfile)."\n";
      print "Content-Disposition: inline; Filename=$displayedPage; \n\n";
      print $$pfile;
    } else {
		  if ($multi==0) {
        my $string = "Content-type: text/html\n\n";
        $string.=qq{<html><body><font style="font-family: arial, helvetica, } .
                 qq{sans-serif;font-size: 12pt;">$tr{nopdf}<br></body></html>};
        print $string;
			}
		}
  } else {
    my $ok=writeFile($filetemp,$$pfile,1);
		$filetemp="" if $ok != 1;
	}
	return $filetemp;
}






=head1 MainSend($type)

Send zip file to client

=cut

sub MainSend {
  my ($mode) = @_;
  $val{selectdoc}=$usp{doc} if $val{selectdoc}==0;
	my $versfld = "";
	my $keyfld = "";
  my $sql = "SELECT Seiten,Ordner,Archiviert,EDVName " .
            "FROM archiv WHERE Laufnummer=" .
            "$val{selectdoc} ".getEigentuemerZusatz();
  my ($pages,$folder,$archived,$edvname) = getSQLOneRow($sql);
  my ($type,$name) = split(";",$edvname);
	my $name1 = $name;
  $name = qq{"$name"}; # Add quotes so we can use empty chars
  if ($type eq "mail" || $type eq "office") {
    my $nr = ($val{selectdoc}*1000)+1;
    my $prow = getBlobFile("BildA",$nr,$folder,$archived);
    if (length($$prow[0])>0) {
      if ($mode eq "zip") {
        MainPDFSend("zip",\$$prow[0],$val{selectdoc});
      } else {
        my @parts = split(/\./,$name);
        my $ext = pop @parts;
        my $file1 = writeTempFile(\$$prow[0]);
        my $file2 = writeTempFile("");
        $file2 = getTempFile($file2,'.'.$ext,1);
        my $zip = Archive::Zip->new();
        my $res = $zip->read($file1);
        my @files = $zip->memberNames();
        $res=$zip->extractMember($files[0],$file2);
        unlink $file1 if -e $file1;
        undef $zip;
        if (-e $file2) {
          my $vers = getParameterValue(VERSIONS);
          my $key = getParameterValue(VERSIONKEY);
					if ($vers ne "" && $key ne "") {
					  my $sql = "select $vers,$key ".
						          "from archiv where Laufnummer=".$val{selectdoc};
            my ($versval,$keyval) = getSQLOneRow($sql);
						if ($keyval > 0) {
						  $name1 = "$versval"."_"."$keyval"."_".$name1;
              $name = qq{"$name1"}; # Add quotes so we can use empty chars
						}
					}
          my $pfile = getFile2($file2,1);
          MainPDFSend($ext,$pfile,$val{selectdoc},$name);
        } else {
          MainPDFSend("zip",\$$prow[0],$val{selectdoc});
        }
      }
    }
  }
}






=head1 MainPDFCreate($doc,$seiten,$archivart)

Create the pdf file temporary and send it out to the client

=cut

sub MainPDFCreate {
  my $lnr = shift;
  my $firstpage = shift;
  my $seiten = shift;
  my $archivart = shift;
  my $folder = shift;
  my $archived = shift;
	my $filetemp = shift;
	my $multi = shift;
  my @files = ();
  my $file1 = "";
  my $whole = getParameterValue(PDFWHOLEDOC);
  my $start=1;
  if ($whole==0) {
    $start = $firstpage;
    $seiten = $firstpage;
  }
  for(my $c=$start;$c<=$seiten;$c++) {
    my $nr1=getPageNumber($lnr,$c);
    $file1 = writeTempFile(" ");
    $file1 = getTempFile($file1,'.pdf',1);

    # load the image
    my $bild = 'BildInput';
    my $prow = getBlobFile($bild,$nr1,$folder,$archived);
    if (length($$prow[0])==0) {
      $bild = 'Bild';
      $prow = getBlobFile($bild,$nr1,$folder,$archived);
    }
    my $imgo = ExactImage::newImage();
    ExactImage::decodeImage($imgo,$$prow[0]);
    # load the common note params
    my $params = {
      doc=>$lnr,
      page=>$c,
      cWidth => ExactImage::imageWidth($imgo),
      cHeight => ExactImage::imageHeight($imgo)
    };
    # extract notes from db, but dont rotate them or update params
    # pass in image to increase speed. Should always be BildInput?
    my $dbnotes = MainNoteHash($params,0,0,$imgo,$folder,$archived);
    # loop thru notes and add to image
    foreach my $note (values %{$dbnotes}){
      $note->getImage($imgo);
    }
    if ($archivart==3) {
      #ExactImage::encodeImageFile($imgo,$file1,5,"jpeg,recompress");
      ExactImage::encodeImageFile($imgo,$file1);
    } else {
      ExactImage::encodeImageFile($imgo,$file1);
    }
    ExactImage::deleteImage($imgo);
    push @files,$file1;
  }
  if ($whole==1) {
    $file1 = writeTempFile(" ");
    $file1 = getTempFile($file1,'.pdf',1);
    my $dopdf="pdftk ".join(" ",@files)." output $file1";
    system("$dopdf");
    foreach (@files) {
      unlink $_ if -e $_;
    }
  }
  my $pfile = getFile2($file1,1);
  $filetemp=MainPDFSend("pdf",$pfile,$lnr,"",$filetemp,$multi);
	return $filetemp;
}






=head1 MainText

Returns the OCR Text of a defined page

=cut

sub MainText {
  my $html = "Content-type: text/plain\n\n";
  #$usp{doc} = $val{selectdoc} if $val{selectdoc};
  #$usp{page} = $val{selectpage} if $val{selectpage};
  my $sql = "select Seiten from ".TABLE_ARCHIVE." where ".
            "Laufnummer=$usp{doc} ".getEigentuemerZusatz();
  my $seiten = getSQLOneValue($sql);
  if ($seiten>0) { # user has rights to document, give back page text 
    my $seitennr = getPageNumber($usp{doc},$usp{page});
    $sql = "select Text from ".TABLE_PAGES." where Seite=$seitennr";
    $html .= getSQLOneValue($sql);
  }  
  print $html;
}






=head1 MainContentType($sourceExt)

Return content type (PDF -> application/pdf, DOC -> application/msword)

=cut

sub MainContentType {
  my $sourceExt = shift;
  $sourceExt = lc($sourceExt);
  my $ret;
  if ($sourceExt eq "pdf") {
    $ret="application/pdf";
  } elsif ($sourceExt eq "doc") {
    $ret="application/msword";
  } elsif ($sourceExt eq "xls") {
    $ret="application/msexcel";
  } elsif ($sourceExt eq "rtf") {
    $ret="application/rtf";
  } elsif ($sourceExt eq "ppt") {
    $ret="application/mspowerpoint";
  } elsif ($sourceExt eq "zip") {
    $ret="application/zip";
  } else {
    $ret="application/octet-stream";
  }
  return $ret;
}






=head1 MainImage

Print out an image 

=cut

sub MainImage {
  my $done=0;
  if (getUserParam()) { # get the session vars
    $val{dbh}=dbhOpen();
    if ($val{dbh}) {
      getUserInfo();
      if ($val{user_nr}>0) {
        if ($val{imagedoc}>0 && $val{imagepage}>0) {
          # add these to session now that it is loaded
          # we only save these so that we can save page to db later
					if ($val{imagerotate} != $usp{rotate} ||
					    $val{imagezoom} != $usp{zoom}) {
            $usp{rotate} = $val{imagerotate};
            $usp{zoom} = $val{imagezoom};
            MainUpdateSession(1); # save the changed session values
					}
          my $sql = "select Laufnummer,Ordner,Archiviert,ArchivArt ".
					          "from ".TABLE_ARCHIVE.
            " where Laufnummer=$val{imagedoc}".getEigentuemerZusatz();
          my ($akte,$folder,$archived,$art) = getSQLOneRow($sql);
          if ($akte>0) {
            my $nr = getPageNumber($val{imagedoc},$val{imagepage});
            my $bild = "BildInput";
            $bild = "Bild" if $val{view} eq MAIN && $val{imagehigh}==0;
            my $prow = getBlobFile($bild,$nr,$folder,$archived);
            if (length($$prow[0])==0) {
              if ($bild eq "Bild") {
                $bild="BildInput";
              } else {
                $bild="Bild";
              }
              $prow = getBlobFile($bild,$nr,$folder,$archived);
            }
            $done=MainImageShow($prow,$art);
          }
        }
      }
    }
  }
  MainImageLoadCheckEmpty() if $done==0;
}






=head1 MainImageLoadCheckEmpty

Print out an empty image

=cut

sub MainImageLoadCheckEmpty {
  my $www = DOCROOT;
  my $empty = "$www/pics/white_pixel.jpg";
  my $imgo = ExactImage::newImage();
  ExactImage::decodeImageFile($imgo,$empty);
  ExactImage::imageScale($imgo,$val{imageh});
  $empty = ExactImage::encodeImage($imgo,"jpeg");
  my $print = "Content-type: image/jpeg\n\n";
  $print .= $empty;
  print $print;
}






=head1 $image=MainImageShow($prow)

Print out image with ExactImage library

=cut

sub MainImageShow {
  my $prow = shift;
	my $art = shift;
  my $doc = $val{imagedoc};
  my $page = $val{imagepage};
  my $mime = "";
	my $compr = 0;
  my $done = 0;
  if ($$prow[0] ne "" && $val{imagezoom}==1 && $usp{rotate}==0 && $art==3) {
	  $val{dbh}->disconnect() if $val{dbh};
	  $mime="jpeg";
    my $print = "Content-type: image/$mime\nCache-Control: no-cache\n\n";
    print $print;
		print $$prow[0];
    $done=1;
	} elsif ($$prow[0] ne "") {
    my $imgo = undef;
    $imgo = ExactImage::newImage();
	  $val{dbh}->disconnect() if $val{dbh};
    ExactImage::decodeImage($imgo,$$prow[0]);
		$$prow[0] = undef;
    $val{imagew} = ExactImage::imageWidth($imgo) if $val{imagew}<=1;
    $val{imageh} = ExactImage::imageHeight($imgo) if $val{imageh}<=1;
    my $col = ExactImage::imageColorspace($imgo);
    my $fact=MainImageShowFactor($imgo);
		if ($fact<1) {
		  ExactImage::imageThumbnailScale($imgo,$fact,$fact);
		} 
    MainImageRotate($imgo);
    if ($col ne "gray1" && $col ne "gray2" && $col ne "gray4") {
      $mime = "jpeg";
    } else {
      $mime = "png";
			$compr = 10;
    }
    my $print = "Content-type: image/$mime\nCache-Control: no-cache\n\n";
    print $print;
		if ($mime eq "jpeg") {
      print ExactImage::encodeImage($imgo,$mime);
		} else {
      print ExactImage::encodeImage($imgo,$mime,10);
		}
    ExactImage::deleteImage($imgo);
    $imgo = undef;
  }
	$val{dbh}->disconnect() if $val{dbh};
  return $done;
}






=head1 MainImageRotate($imgo)

Rotate an image

=cut

sub MainImageRotate {
  my $imgo = shift;
  if ($usp{rotate}==270) {
    ExactImage::imageRotate($imgo,-90);
  }
  elsif($usp{rotate}){
    ExactImage::imageRotate($imgo,$usp{rotate});
  }
}
  





=head1 $fact=MainImageShowFactor($imgo)

Calculate the right factor to show the image (exactcode library)
Convert zoom range (0 .. 1) to image size (X .. 1)
Where 'X' is the factor of the 'fits on screen' image

=cut

sub MainImageShowFactor {
  my $imgo = shift;

  my $w = ExactImage::imageWidth($imgo);
  my $h = ExactImage::imageHeight($imgo);
  if ($usp{rotate}==90 || $usp{rotate}==270) {
    my $w1 = $w;
    $w = $h;
    $h = $w1;
  }

  # find smallest image factor
  my $facw = $val{imagew}/$w;
  my $fach = $val{imageh}/$h;
  my $minfact = $facw;
  $minfact = $fach if $minfact > $fach;
  if($minfact > 1){
    $minfact = 1;
  }

  # largest image factor is always 1,
  # scale the 'zoom' as needed
  my $fact = $usp{zoom} * (1-$minfact) + $minfact;
  if($fact > 1){
    $fact = 1;
  }

  return $fact;
}



=head1 MainResult

Selects main table search results via AJAX

1. go_result_rows returns a block based on offset/length
   with basic info about each document
2. go_result_record returns detail about a record
3. go_result_tab updates session 'state'
4. go_result_thumbs updates session 'photomode'
5. go_result_page give back the page text of a singe page

=cut

sub MainResult {
  my $html = "Content-type: application/json\nCache-Control: no-cache\n\n";
  # update session based on tab click
  if($val{action} eq 'tab'){
    $val{state} = SEARCH;
    if ($val{result_tab} eq 'ViewTab') {
      $val{state} = VIEW;
    } elsif ($val{result_tab} eq 'EditTab') {
      $val{state} = EDIT;
    }
    MainUpdateSession(); # save the changed session values
  } elsif($val{action} eq 'thumbs'){
    # update session based on thumbnail view button click
    $usp{photomode} = $val{result_thumbs};
    MainUpdateSession(); # save the changed session values
  } elsif($val{action} eq 'rows'){
    # list a section of the results
    $val{sqlstart} = $val{result_offset};
    $val{sqllimit} = $val{result_length};
    MainSelection(); # select documents
    # FIXME: use sortCol and sortDir?
		$val{errorint} = toUTF8($val{errorint});
    $html .= qq|{totalRows:$usp{sqlrecords},sortCol:"Laufnummer",|.
	           qq|error:"$val{errorint}",status:1,sortDir:"asc",resultRows:[|;
    my $row = $val{sqlstart};
    foreach my $prow (@{$val{rows}}) {
      $html .= ${MainResultRecord($prow,$row,0)} . ",\n";
      $row++;
    }
    # remove , after last record
    $html =~ s/,\n$//;
    # finish block
    $html .= ']}';
  } elsif($val{action} eq 'record' || $val{action} eq "update"){
	  MainUpdate() if $val{action} eq 'update';
    $usp{doc} = $val{result_doc};
    $usp{page} = $val{result_page};
    $usp{sqlpos} = $val{result_index};
    $val{sqlstart} = $val{result_index};
    $val{sqllimit} = 1;
    MainSelection($usp{doc}); # select one doc
    my $prow = $val{rows}->[0];
    $html .= ${MainResultRecord($prow,$val{sqlstart},1)};
    MainUpdateSession(); # save the changed session values
  } elsif($val{action} eq 'page'){
    $usp{doc} = $val{result_doc};
    $usp{page} = $val{result_page};
    $usp{sqlpos} = $val{result_index};
    $val{sqlstart} = $val{result_index};
    $val{sqllimit} = 1;
    MainSelection($usp{doc}); # select one doc
    $usp{page} = $val{result_page}; # after selection set to current page
    $html .= "{". ${MainResultPage($val{sqlstart})} . "}";
	} else {
    $html .= '{}';
    warn "Invalid Result action requested";
  }
  print $html;
  return;
}



=head1 MainResultRecord($prow,$index,$fulltext)

returns a single row from db formatted as JSON string

=cut

sub MainResultRecord {
  my $prow = shift;
  my $index = shift;
  my $fulltext = shift;

  # the new way:
  my $docnr = '';
  my $owner = '';

  # extra stuff at end of query result, cache them in lexicals
  my $edvname = pop @$prow;
  my $archivart = pop @$prow;
  my $locked = pop @$prow;

  # dont really need these on javascript side?
  my $min = 0;
  my $max = 0;
  my $count = 0;
  if(length $usp{sqlfulltext}>0 && $usp{fulltextengine}!=2){
    $count = pop @$prow;
    $max = pop @$prow;
    $min = pop @$prow;
  }

  # start record, add index
  my $html = qq|{index:$index, |;

  # add non-hidden db fields
	my $max1 = $#{$val{fields}};

  foreach my $i (grep {!$val{fields}->[$_]->{hide}} 0 .. $max1) { 

    MainPrintFieldFormat(\$prow->[$i], $val{fields}->[$i]->{type});

    # check for Notiz (Note) field, can contain \r\n
		my $fld = $val{fields}->[$i]->{name};
		my $value = $prow->[$i];
		if ($fld eq "Notiz" && $value ne "") {
		  $value =~ s/\r/\\\r/g; # add backspaces for JSON
			$value =~ s/\n/\\\n/g;
		}
    $html .= toUTF8($fld).':"'. toUTF8($value) .'",'; 

    # cache these for later
    if($val{fields}->[$i]->{name} eq 'Laufnummer'){
      $docnr = $prow->[$i];
    }
    elsif($val{fields}->[$i]->{name} eq "Eigentuemer"){
      $owner = $prow->[$i];
    }
  }
	if ($val{action} eq "record") {
    $html .= toUTF8($val{fields}->[2]->{name}).':"'.toUTF8($prow->[2]) .'",';
	}
	
  # the download column, send translations to javascript
  # js will draw the links. cannot do it here, because
  # the page number changes with user clicks on client side
  my $pdf = '';
  my $img = '';
  my $pic = '';
  my $zip = '';
  my $mail = '';
  my $mailmsg = '';
  my $file = '';

  if ($usp{showpdf} && $fulltext==0) {
    $pdf = toUTF8($tr{pdf});
    $img = toUTF8($tr{img});
    $pic = toUTF8($tr{pic});
    my ($type,$name,$folder) = split(";",$edvname);
    if($type eq "mail"){
      $zip = toUTF8($tr{zip});
      $mail = toUTF8($tr{mail});
      $mailmsg = toUTF8($tr{mail2}." ".$folder);
    } elsif($type eq "office"){
      $zip = toUTF8($tr{zip});
      $file = toUTF8($tr{file});
    }
  }

  my @hits;
	my $showocr= $usp{showocr};
	
  if ($fulltext==0) {
    $html .= qq{pdf:"$pdf",img:"$img",pic:"$pic",zip:"$zip",mail:}.
		         qq("$mail",mailmsg:"$mailmsg",file:"$file",docpage:'$usp{page}',);
	} else {
    # get the pages in this doc that match the fulltext search string
    if(length $usp{sqlfulltext}){
		  $showocr=1;
		  if ($usp{fulltextengine} != 2) {
        my $sql = "select mod(".TABLE_PAGES.".Seite,1000) as hits from ".
                TABLE_ARCHIVE.",".TABLE_PAGES." WHERE Laufnummer=$docnr AND ".
                TABLE_ARCHIVE.".Laufnummer=truncate((" .TABLE_PAGES.
                ".Seite/1000),0) and match ".TABLE_PAGES.".Text against " .
                "('$usp{sqlfulltext}' in boolean mode) ".
								"ORDER BY ".TABLE_PAGES.".Seite";
        my $prows = getSQLAllRows($sql);
        foreach (@$prows) {
          push @hits,@$_[0];
        }
			} else {
			  my $nr = "";
				my $text = SphinxSearchText($usp{sqlfulltext});
     	  my $sql = "select * from $val{db} where ".
				            "match('$text') and laufnummer=$docnr limit 1000";
				SphinxSearch($sql,\$nr,1);
		    $nr =~ s/(\n+$)//sm;
				foreach (split(/\n/,$nr)) {
				  if ($_>1000) {
				    push @hits, ($_ % 1000);
					}
				}
				@hits = sort {$a <=> $b} @hits;
			}
    }
	}
  $html .= qq{Treffer:[} . join(',',@hits) . q{],};

  # add boolean flags
  my $edit = 0;
  my $checked = 0;
  if (userHasRight($docnr,$owner))  {
    $edit=1;
    if($val{copyselect}){
      $checked=1;
    }
  }

  my $init = 1;
	$init = 0 if $val{result_move}==1;
  $html .= qq(edit:$edit,checked:$checked,init:$init,ocr:$showocr);

  # end record
  $html .= '}';
  return \$html;
}



=head $text = SphinxSearchText($text)

Give back quoted fulltext

=cut

sub SphinxSearchText {
  my ($text) = @_;
	if (length($text)>2 && index($text,"\"",0)==0 && 
    index($text,"\"",length($text)-1)==length($text)-1) {
	  $text = substr($text,1,length($text)-2);
		$text = "\\\"".$text."\\\"";
	}
	return $text;
}



=head1 SphinxSearch($cmd,$pnr)

Retrieve hits from searchd (via mysql client), start it if not loaded

=cut

sub SphinxSearch {
  my ($sql,$pnr,$col) = @_;
	my $mysql = "mysql -P 3307 -h 127.0.0.1";
	my $cmd = qq[$mysql -N -s -e "$sql;" | awk '{ print \$$col }'];
	for (my $c=0;$c<3;$c++) {
    $$pnr = `$cmd`;
	  if ($$pnr eq "") {
		  my $cmd1 = qq/$mysql -e "show status;"/;
			my $res = system($cmd1);
			if ($res != 0) {
	      if ($val{host} eq "localhost" && $c==0) {
          my $host=avdb_host();
          my $db=avdb_db();
          my $user=avdb_uid();
          my $pw=avdb_pwd();
          my $sql = "INSERT INTO archivista.jobs SET status=110,job='WEBCONF',".
                    "host=".SQLQuote($host).",db=".SQLQuote($db).",".
                    "user=".SQLQuote($user).",pwd=".SQLQuote($pw);
          SQLUpdate($sql,$val{dbh2});
		      my $id = getSQLOneValue("SELECT LAST_INSERT_ID()",$val{dbh2});
          $sql = "INSERT INTO archivista.jobs_data SET jid=$id,".
                 "param='WEBC_MODE',value='SPHINX_START'";
          SQLUpdate($sql,$val{dbh2});
          $sql = "UPDATE archivista.jobs SET status=100 where id=$id";
          SQLUpdate($sql,$val{dbh2});
			  }
			  my $wait = $c*2;
			  sleep $wait;
			} else {
        last;
			}
		} else {
		  last;
		}
	}
}



sub MainResultPage {
  my $index = shift;
  # start record, add index
  my $html = "";
  my $image = getPageNumber($usp{doc},$usp{page});
  my $pstring1 = getBlobFile("Text",$image,0,0,TABLE_PAGES);
  my $string1 = $$pstring1[0];
  if (length($string1)>0) {
    FormatText(\$string1);
  } else {
    $string1 = $tr{error_notext};
  }
  # convert the fulltext into json string
  $string1 = toUTF8($string1);
  $string1 =~ s/\\/\\\\/g;
  $string1 =~ s/[\b]/\\b/g;
  $string1 =~ s/\n/\\n/g;
  $string1 =~ s/\r/\\r/g;
  $string1 =~ s/\t/\\t/g;
  $string1 =~ s/\f/\\f/g;
  $string1 =~ s/"/\\"/g;
  $string1 =~ s/\//\\\//g;
  #FIXME: other control chars too?
  $html .= qq{FullText:"$string1"};
  # end record
  return \$html;
}

 


=head1 MainNote

Modifies Notes field via AJAX or Img src=, with these actions

1. Add a new note to page (returns JSON)
2. Duplicate a note on page (returns JSON)
3. List all existing notes on page (returns array of JSON)
4. Image of existing note on page (returns image of note)
5. Update an existing note on page (returns image of note)
6. Delete an existing note from page (returns JSON)

=cut

sub MainNote {
  my $params = {
    url     => CGIDIR.CGIPRG,
    doc     => $val{note_doc},
    page    => $val{note_page},
    cWidth  => $val{note_cWidth},
    cHeight => $val{note_cHeight},
    cRotate => $val{note_cRotate},
    cZoom   => $val{note_cZoom},
    editable => $val{note_editable},
  };

  # note being updated/duplicated/deleted/imaged
  my $index = $val{note_index};

  my $needUpdate = 0;
  my $html = "Content-type: application/json\nCache-Control: no-cache\n\n";
  my $pn = getPageNumber($params->{'doc'},$params->{'page'});

  # extract notes from db and rotate them, update params if no notes found
  my $dbnotes = MainNoteHash($params,1,1);

  ##############################################################
  # list all 'text' notes
  if($val{action} eq 'list'){
    $html .= "[\n";
    $html .= join(",\n",
      map {$_->toJSON} sort grep {$_->get('type') == 3} values(%{$dbnotes})
    );
    $html .= "]\n";
  }

  ##############################################################
  # get image for client, ignores cgi params other than doc/page/index
  # or update requested idx, reads cgi params. Both return image
  elsif(($val{action} eq 'update' || $val{action} eq 'image')
    && exists $dbnotes->{$index}
  ){
    my $note = $dbnotes->{$index};

    if($val{action} eq 'update'){
      $needUpdate++;
      $note->fromCGI(\%val);
    }

    my $noteImg = $note->getImage();
    print "Content-type: image/png\nCache-Control: no-cache\n\n"
          . ExactImage::encodeImage($noteImg,'png');
    ExactImage::deleteImage($noteImg);
  }

  ##############################################################
  # Add new note, using defaults (add) or existing (duplicate)
  elsif($val{action} eq 'add' || $val{action} eq 'duplicate'){

    # find next available index
    my $next = (reverse(sort(keys %{$dbnotes})))[0]+1;

    $needUpdate++;

    my $note = obj::Note->new(%{$params});
    $note->rotate();

    if($val{action} eq 'add'){
      # set the location back to defaults (undo rotation)
      my $note2 = obj::Note->new(%{$params});
      $note->set(
        x1=>$note2->get('x1'),
        x2=>$note2->get('x2'),
        y1=>$note2->get('y1'),
        y2=>$note2->get('y2'),
        fgRotation=>$note2->get('fgRotation'),
      );
      $note->updateBgParams();
    }
    else{
      $note->fromCGI(\%val);
    }

    $note->set(
      'index'=>$next,
    );
    $dbnotes->{$next} = $note;

    # send new note to user
    $html .= $note->toJSON;
  }

  ##############################################################
  # delete requested idx
  elsif($val{action} eq 'delete' && exists $dbnotes->{$index}){
    $needUpdate++;
    my $note = $dbnotes->{$index};
    $html .= $note->toJSON;
    delete $dbnotes->{$index};
  }

  else{
    $html .= '{}';
    warn "Invalid Note action requested: $val{action}";
  }

  if($needUpdate){ # && $params->{'editable'}){

    my ($edit,$pages,$folder,$archived)=lockIfEditable($params->{'doc'});

    if($edit){
      my $string = join("\r\n",
        map {
          $dbnotes->{$_}->unrotate;
          $dbnotes->{$_}->toString
        }
        sort keys(%{$dbnotes})
      );
  
      my $sql = "update archivseiten set Notes=" . SQLQuote($string)
           . " where Seite=$pn";
      SQLUpdate($sql);
      unlockAfterEdit($params->{'doc'});
    }
  }

  ##############################################################
  # output
  print $html;
  return;
}



=head1 MainNoteHash

Returns a hash of all notes for a page, keyed on the note index
Also updates the params argument with image size info if any of the
notes contain it, or gets it from image if all of them need it.

=cut
sub MainNoteHash {
  my $params = shift; # contains: doc, page, cWidth, cHeight, and more
  my $rotate = shift;
  my $update = shift;
  my $imgo = shift; # (optional)
	my $archiviert = shift; # (optional)
	my $folder = shift; # (optional)

  my $pn = getPageNumber($params->{doc},$params->{page});
  
  ##############################################################
  # pull existing notes from db and cache them in @dbnotes
  # also determine the maximum note index
  my @dbnotes = ();
  my $maxIdx = 0;

  my $sql = "select Notes from archivseiten where Seite=$pn";
  foreach my $line (split(/\r\n/,getSQLOneValue($sql))){
    my $note = obj::Note->new();
    $note->fromString($line);
    # if the caller gave us incomplete data, use _ALL_ data from note
    if ( !$params->{'iWidth'} || !$params->{'iHeight'}
      || !$params->{'iXRes'} || !$params->{'iYRes'}
    ){
      $params->{'iWidth'} = $note->get('iWidth');
      $params->{'iHeight'} = $note->get('iHeight');
      $params->{'iXRes'} = $note->get('iXRes');
      $params->{'iYRes'} = $note->get('iYRes');
    }
    if($maxIdx < $note->get('index')){
      $maxIdx = $note->get('index');
    }
    push (@dbnotes, $note);
  }

  # if the caller AND all the notes gave us incomplete data,
  # get the correct data from image
  if ( (!$params->{'iWidth'} || !$params->{'iHeight'}
    || !$params->{'iXRes'} || !$params->{'iYRes'})
    && (scalar @dbnotes || $update)
  ){
    my $deleteImgo = 0;
    ##############################################################
    # pull image from db, to get dimensions and resolution
    if(!$imgo){
		  if ($folder==0) {
	      my $sql = "select Archiviert,Ordner from archiv where Laufnummer=".
	                $params->{'doc'};
	      ($archiviert,$folder) = getSQLOneRow($sql);
			}
      my $prow1 = getBlobFile("BildInput",$pn,$folder,$archiviert);
			if (!length($$prow1[0])) {
        $prow1 = getBlobFile("Bild",$pn,$folder,$archiviert);
      }
      if(!length($$prow1[0])){
        return {};
      }
      $imgo = ExactImage::newImage();
      ExactImage::decodeImage($imgo,$$prow1[0]);
      $deleteImgo = 1;
    }
  
    ##############################################################
    # extract size and resolution
    $params->{'iWidth'} = ExactImage::imageWidth($imgo);
    $params->{'iHeight'} = ExactImage::imageHeight($imgo);
    $params->{'iXRes'} = ExactImage::imageXres($imgo);
    $params->{'iYRes'} = ExactImage::imageYres($imgo);
  
    if($deleteImgo){
      ExactImage::deleteImage($imgo);
    }
  
    # some images dont have resolution encoded. we make a guess
    if(!$params->{'iXRes'}){
      $params->{'iXRes'} = 300;
    }
    if(!$params->{'iYRes'}){
      $params->{'iYRes'} = 300;
    }
  }

  ##############################################################
  # add missing params and index to notes made by RichClient
  # rotate note params if page view is rotated (not for pdfs)
  # convert array @dbnotes to hash %dbnotes
  my %dbnotes;
  foreach my $note (@dbnotes){

    $note->set(%{$params});
    if($rotate){
      $note->rotate();
    }
    $note->updateBgParams();

    if($note->get('index') < 1){
      $maxIdx++;
      $note->set('index'=>$maxIdx);
    }

    $dbnotes{$note->get('index')} = $note;
  }

  return \%dbnotes;
}



=head1 MainAjax 

Print out the html part for ajax based input fields

=cut

sub MainAjax {
  my $fld = fromUTF8($val{ajaxfield});
  my $wert = fromUTF8($val{ajaxval});
  my $linked = fromUTF8($val{linked});
  my $wert2 = fromUTF8($val{val});
  my $type = $val{type};
  my $ajaxlimit = $usp{ajaxlimit}; # ajax limit
  $ajaxlimit = 0 if $ajaxlimit eq '';
  my @res=();
  my $sql="";
  if ($fld eq "Eigentuemer" or $fld eq $usp{publishfield}) {
    my @vals = ();
    push @vals,"[ALL]" if $fld eq $usp{publishfield};
    my $counter = 0;
    foreach (@{getSelfAndAliasOwner()}) {
      if ($ajaxlimit != 0) {
        last unless $counter < $ajaxlimit;
        $counter++;
      }
      my $eig = $_;
      if ($wert ne "" && $wert ne " ") {
        $eig = "" if index(lc($eig),lc($wert))!=0;
      }
      push @vals, "$eig" if $eig ne "";
    }
    my $html = "";
    $html .= "Content-type: text/html\n\n";
    $html .= qq(<ul>);
    foreach (@vals) {
      $html .= qq(<li>$_</li>);
    }
    $html .= qq(</ul>);
    print $html;
    return;
  }
  if ($fld ne "" && $wert ne "" && $type>0) {
    $wert = '' if $wert eq ' ';
    my $wert1 = SQLQuote($wert);
    $wert1 =~ s/(')$/%$1/;
    if ($type == AV_1TON && $linked ne "" && $wert2 ne "") {
      $sql = "select Laufnummer from feldlisten where FeldDefinition=".
             SQLQuote($linked)." AND Definition=".SQLQuote($wert2);
      my $id = getSQLOneValue($sql);
      if ($id>0) {
        $sql = "select Definition from feldlisten where " .
               "FeldDefinition=".SQLQuote($fld)." AND " .
               "Definition like $wert1 AND ID=$id order by Definition";
      } else {
        $sql="";
      }
    } elsif ($type==AV_CODETEXT || $type==AV_CODENUMBER) {
      $sql = "select Code from feldlisten where FeldCode=".
             SQLQuote($fld)." AND Code like $wert1 order by ";
      my $sql1 = "Code";
      $sql1 = "lpad(Code,10,'0')" if $type==AV_CODENUMBER;
      $sql .= $sql1;
    } elsif ($type == AV_MULTI) {
      $sql = "select Definition from feldlisten where FeldDefinition=".
           SQLQuote($linked)." AND Definition like $wert1 order by Definition";
    } elsif ($type == AV_DEFINITION) {
      $sql = "select Definition from feldlisten where FeldDefinition=".
             SQLQuote($fld)." AND Definition like $wert1 order by Definition";
    }
  }
  if ($sql ne "") {
    my $html = "";
    $html .= "Content-type: text/html\n\n";
    $html .= qq(<ul>);
    my $prows = getSQLAllRows($sql);
    my $counter = 0;
    foreach (@$prows) {
      if ($ajaxlimit != 0) {
        last unless $counter < $ajaxlimit;
        $counter++;
      }
      my @row = @$_;
			my $row1 = $row[0];
      $row1 = Encode::encode_utf8($row[0]) if check64bit()==1;
      $html .= qq(<li>$row1</li>);
    }
    $html .= qq(</ul>);
    print $html;
  } else {
    my $html .= "Content-type: text/html\n\n";
    $html .= qq(<ul>);
    $html .= qq(</ul>);
    print $html;
  }
}



=head1 MainList

Handles ajax request (add or del field list entries or checking fields)

=cut

sub MainList {
  my $message="";
  $val{list_1_field} = fromUTF8($val{list_1_field});
  $val{list_1_field} =~ s/^.*?_//;
  $val{list_1_val} = fromUTF8($val{list_1_val});
  $val{list_2_field} = fromUTF8($val{list_2_field});
  #$val{list_2_field} =~ s/^.*?_//;
  $val{list_2_val} = fromUTF8($val{list_2_val});
  if ($val{go_list} eq "add") {
    $message = MainListAdd();
  } elsif ($val{go_list} eq "del") {
    $message = MainListDelete();
  } elsif ($val{go_list} eq "update") {
    $message = MainFieldUpdate();
  }
  print "Content-type: text/html\n\n$message";
}






=head1 $message=MainListAdd()

Check in feldlisten what value match the ajax request to add an entry

=cut

sub MainListAdd {
  my $message="";
  my %wert = ();
  if ($val{list_2_val} eq "" && $val{list_2_field} eq "") { # single def.
    $wert{FeldDefinition} = SQLQuote($val{list_1_field});
    $wert{Definition} = SQLQuote($val{list_1_val});
  } elsif ($val{list_type} == AV_MULTI) { # multi field, add it to def.
    $wert{FeldDefinition} = SQLQuote($val{list_2_field});
    $wert{Definition} = SQLQuote($val{list_1_val});
  } elsif ($val{list_type} == AV_1TON) { # 1toN, check node
    $wert{FeldDefinition} = SQLQuote($val{list_2_field});
    $wert{Definition} = SQLQuote($val{list_2_val});
    my $sql = "SELECT Laufnummer from feldlisten WHERE ".
              "FeldDefinition=$wert{FeldDefinition} AND " .
              "Definition=$wert{Definition}";
    my $id = getSQLOneValue($sql);
    if ($id>0) {
      $wert{FeldDefinition} = SQLQuote($val{list_1_field});
      $wert{Definition} = SQLQuote($val{list_1_val});
      $wert{ID} = $id;
    } else {
      $message = $tr{list_nonode};
    }
  } else { # linked fields (code/text and definition)
    $wert{FeldDefinition} = SQLQuote($val{list_2_field});
    $wert{Definition} = SQLQuote($val{list_2_val});
    $wert{FeldCode} = SQLQuote($val{list_1_field});
    $wert{Code} = SQLQuote($val{list_1_val});
  }
  if ($message eq "") {
    my @sql1 = ();
    foreach (keys %wert) {
      push @sql1,"$_=$wert{$_}";
    }
    my $sql = "SELECT Laufnummer from feldlisten WHERE ".join(" AND ",@sql1);
    if (getSQLOneValue($sql)>0) {
      $message = $tr{list_exist};
    } else {
      $sql = "INSERT INTO feldlisten set ".join(",",@sql1);
      SQLUpdate($sql);
      $message = $tr{list_added};
    }
  }
  $message = toUTF8($message);
  return $message;
}




=head1 $message=MainListDelete()

Check in feldlisten what value match the ajax request to delete an entry

=cut

sub MainListDelete {
  my $message="";
  my %wert = ();
  my $type = $val{list_type};
  if ($type == AV_MULTI) { # multi field, add it to def.
    $wert{FeldDefinition} = SQLQuote($val{list_2_field});
    $wert{Definition} = SQLQuote($val{list_1_val});
  } elsif ($type==AV_CODETEXT || $type==AV_CODENUMBER) {
    $wert{FeldCode} = SQLQuote($val{list_1_field});
    $wert{Code} = SQLQuote($val{list_1_val});
  } else {
    $wert{FeldDefinition} = SQLQuote($val{list_1_field});
    $wert{Definition} = SQLQuote($val{list_1_val});
  }
  my @sql1 = ();
  foreach (keys %wert) {
    push @sql1,"$_=$wert{$_}";
  }
  my $sql = "SELECT Laufnummer from feldlisten WHERE ".join(" AND ",@sql1);
  my $lnr = getSQLOneValue($sql);
  if ($lnr>0) {
    $sql = "SELECT ID from feldlisten WHERE ID=$lnr";
    my $id = getSQLOneValue($lnr);
    if ($id==$lnr) {
      $message = $tr{list_notempty};
    } else {
      $sql="DELETE from feldlisten where Laufnummer=$lnr";
      SQLUpdate($sql);
      $message = $tr{list_deleted};
    }
  } else {
    $message = $tr{list_not};
  }
  $message = toUTF8($message);
  return $message;
}



=head1 $message=MainFieldUpdate()

Retrieve for a double linked field a value and give it back

=cut

sub MainFieldUpdate {
  my %wert = ();
  my $type = $val{list_type};
  my $message = "";
  my $feld = "";
  if ($type==AV_CODETEXT || $type==AV_CODENUMBER) {
    $wert{FeldCode} = SQLQuote($val{list_1_field});
    $wert{Code} = SQLQuote($val{list_1_val});
    $feld="Definition";
  } elsif ($type==AV_DEFINITION) {
    $wert{FeldDefinition} = SQLQuote($val{list_1_field});
    $wert{Definition} = SQLQuote($val{list_1_val});
    $feld="Code";
  }
  if ($feld ne "") {
    my @sql1 = ();
    foreach (keys %wert) {
      push @sql1,"$_=$wert{$_}";
    }
    my $sql = "SELECT $feld from feldlisten " .
              "WHERE ".join(" AND ",@sql1);
    my $back = getSQLOneValue($sql);
    if ($back ne "") {
      $back = Encode::encode_utf8($back);
      $message = "$val{list_2_field}\n$back";
    } else {
      $message = "";
    }
  }
  return $message;
}



=head1 MainUpdateSession()

Update the session information

=cut

sub MainUpdateSession {
  my ($nolog) = @_;
  if ($val{sid} ne "") {
    my $table = TABLE_SESSION;
    my %flds = getSessionHash();
    $usp{mode} = $val{view}.$val{state};
    my $sql="";
    foreach (keys %flds) {
		  if (($_ eq "doc" || $_ eq "page") && $nolog==1) {
        # nothing to do
			} else {
        $sql .= "," if $sql ne "";
        $sql .= $flds{$_}."=".SQLQuote($usp{$_});
			}
    }
		my $st = $val{sqlstart};
		$st = 0 if $st=="";
    $sql .= ",s0050=$st";
    if ($sql ne "") {
      $sql = "UPDATE $table set $sql where sid='".$val{sid}."'";
    }
    SQLUpdate($sql,$val{dbh2});
  }
}



=head1 MainLoginDo 

Login into the database according cookie (sid)

=cut

sub MainLoginDo {
  my $checkLogin = shift;
  my $closesession = 0;
  if (getUserParam($checkLogin)) {
    getTranslations($usp{lang});
    $val{dbh}=dbhOpen() if !$val{dbh};
    if ($val{dbh}) {
      $val{hostslave}=HostIsSlave();
      if ($val{hostslave} && getParameterValue(ACCESS_LOG)==1) {
        my $sql="select UserModDatum from archiv " .
                "order by UserModDatum desc limit 1";
        my $mod = getSQLOneValue($sql);
        $val{error} = $tr{accesslog}." ($mod)!";
        $closesession=1;
      } else {
        # let the user in
				if ($val{action} ne "page" && $val{action} ne "list" && 
				    $val{action} ne "thumbs" && $val{action} ne "tab") {
          getUserInfo(); # get the user parameter
          getFieldInfo(); # retrieve all information about fields
				}
        # switch to desired mode (but do a check first)
        getUserParamMode($val{mode}) if $val{mode} ne "";
        if ($val{go} ne GO_LOGOUT) {
          if (length($val{workflow})>0) {
            $usp{sqlstart} = getUserWorkflow();
          } elsif ($usp{sqlstart} eq "") {
            $usp{sqlstart} = getUserAVStart();
          }
        } else {
          $closesession=1;
        }
      }
      if ($closesession==1) {
        MainCloseSession();
      }
    }
  }
  return $val{sid};
}






=head1 MainCloseSession

Close the session

=cut

sub MainCloseSession {
  my $table = TABLE_SESSION;
  my $sql = "DELETE FROM $table WHERE sid='$val{sid}'";
  SQLUpdate($sql,$val{dbh2});
  undef $val{dbh}; # close the database handler (get login form again)
  $val{lang}=$usp{lang};
  $val{sid}=0;
}






=head1 MainSessionCheck

Check if we can login into the database in case we don't have a cookie (sid)

=cut

sub MainSessionCheck {
  # set lang (en if not de)
  LoginFormKeyboard();
  getTranslations($val{lang});
  if (exLogin($val{host},$val{db},\$val{user},$val{pw},
    $val{dbh2},$val{user_nr})==1) {
    $val{dbh} = dbhOpen();
    if ($val{dbh}) {
      getUserInfo(); # get the user parameter
      if ($val{user_nr}>0) {
        # User was found in user table of archive database
        if (getParameterValue(AVVERSION) eq AV_VERSIONNR) {
          $val{error} = ""; # it is ok so far 
          MainPasswordCheck(); # now check for new passwords
          openSession() if ($val{user_pwnew}<=1);
        } else {
          $val{error} = $tr{version_err};
        }
      } else {
        $val{error} = $tr{error_login} if $val{pw} ne "";
      }
    } else {
      $val{error} = $tr{error_login} if $val{pw} ne "";
    }
  } else {
    $val{error} = $tr{error_login} if $val{pw} ne "";
  } 
}






=head1 MainPasswordCheck()

Checks if we need to update the password

=cut

sub MainPasswordCheck {
  if ($val{user_pwnew}>1 && $val{newPasswordCheck}==1) {
    if ($val{newPassword} eq $val{retypePassword}) {
       if ($val{newPassword} eq "" && $val{user_pwnew}==2) {
         $val{error} = $tr{password_can_not_be_empty};
       } else {
         my $sql = "UPDATE user SET PWArt=1 WHERE Laufnummer=$val{user_nr}";
         SQLUpdate($sql);
         my $vers = getSQLOneValue("select version()");
				 if ($vers>=5) {
           $sql="SET PASSWORD=OLD_PASSWORD(".SQLQuote($val{newPassword}).")";
				 } else {
           $sql="SET PASSWORD=PASSWORD(".SQLQuote($val{newPassword}).")";
				 }
         SQLUpdate($sql);
         $val{pw}=$val{newPassword};
         $val{newPasswordCheck}=0;
         $val{user_pwnew}=1;
       }
    } else {
      $val{error} = $tr{wrong_password};
    }
  }
}






=head1 MainAction

Process action that the user did choose

=cut

sub MainAction {
  $val{copyselect}=0 if $val{go} ne GO_ACT_SCAN && $val{go} ne GO_ACTION;
  $val{sqllimit}=SQL_LIMIT;
	$usp{orderanyway} = 0; # don't order at any price according fields (fulltext)
  if ($val{go} eq GO_LOGOUT) {
    # logout is done in MainLoginDo
  } elsif ($val{go} eq GO_PAGESWITCH) {
    if ($val{view} eq PAGE) {
      $val{view} = MAIN;
    } else {
      $val{view} = PAGE;
    }
  } elsif ($val{go} eq GO_PAGEVIEW) {
    $val{view} = PAGE;
   } elsif ($val{go} eq GO_THUMBS) {
    if ($usp{photomode}==1) {
      $usp{photomode}=0;
    } else {
      $usp{photomode}=1;
    }
  } elsif ($val{go} eq GO_ALL) {
    $usp{sqlrecords}=0;
    $usp{sqlquery}="";
    $usp{sqlfulltext}="";
    $val{search_fulltext}="";
    $usp{sqlpos}=0;
    $usp{page}=1;
  } elsif ($val{go} eq GO_DOCS_PREV) {
    $usp{sqlpos}=$usp{sqlpos}-$val{sqllimit};
    $usp{page}=1;
  } elsif ($val{go} eq GO_DOC_PREV) {
    $usp{sqlpos}--;
    $usp{page}=1;
  } elsif ($val{go} eq GO_PAGE_FIRST) {
    $usp{page}=1;
  } elsif ($val{go} eq GO_PAGE_PREV) {
    $usp{page}--;
  } elsif ($val{go} eq GO_PAGE_JUMP) {
    $usp{page}=$val{jump};
  } elsif ($val{go} eq GO_PAGE_NEXT) {
    $usp{page}++;
  } elsif ($val{go} eq GO_PAGE_LAST) {
    $usp{page}=640;
  } elsif ($val{go} eq GO_DOC_NEXT) {
    $usp{sqlpos}++;
    $usp{page}=1;
  } elsif ($val{go} eq GO_DOCS_NEXT) {
    $usp{sqlpos}=$usp{sqlpos}+$val{sqllimit};
    $usp{page}=1;
  } elsif ($val{go} eq GO_MAINVIEW) {
    $val{view} = MAIN;
  } elsif ($val{go} eq GO_ROTATE_LEFT) {
    $usp{rotate}=($usp{rotate}+270)%360;
  } elsif ($val{go} eq GO_ROTATE_180) {
    $usp{rotate}=($usp{rotate}+180)%360;
  } elsif ($val{go} eq GO_ROTATE_RIGHT) {
    $usp{rotate}=($usp{rotate}+90)%360;
  } elsif ($val{go} eq GO_ZOOM) {
    if ($val{zoom}==-1) { # invoked with F2 key
      if ($usp{zoom}>0) { # switch between 0 and 1
        $val{zoom}=0;
      } else {
        $val{zoom}=1;
      }
    }
    $usp{zoom}=$val{zoom};
    $usp{zoom}=0 if ($usp{zoom}<0.1);
  } elsif ($val{go} eq GO_ZOOM_NO) {
    $usp{zoom}=0;
  } elsif ($val{go} eq GO_ZOOM_IN) {
    $usp{zoom}=$usp{zoom}+0.25;
    $usp{zoom}=0.5 if $usp{zoom}<0.5;
    $usp{zoom}=1 if $usp{zoom}>1;
  } elsif ($val{go} eq GO_ZOOM_OUT) {
    $usp{zoom}=$usp{zoom}-0.25;
    $usp{zoom}=0 if $usp{zoom}<0.25;
  } elsif ($val{go} eq GO_VIEW) {
    $val{state} = VIEW;
  } elsif ($val{go} eq GO_SEARCH) {
    $val{state} = SEARCH;
  } elsif ($val{go} eq GO_EDIT) {
    $val{state} = EDIT;
  } elsif ($val{go} eq GO_QUERY || $val{go} eq GO_QUERYFILE) {
    MainQuery();
		if ($val{go} eq GO_QUERY) {
      $val{state} = VIEW;
		} else {
      $val{state} = EDIT;
		}
  } elsif ($val{go} eq GO_UPDATE) {
    MainUpdate();
  } elsif ($val{go} eq GO_PRINT) {
    MainPrinting();
  } elsif ($val{go} eq GO_COPY) {
    MainCopy();
  } elsif ($val{go} eq GO_ORDER_ASC) {
    $usp{sqlorder} = "$val{orderfield}";
    $usp{sqlpos} = 0;
		$usp{orderanyway} = 1;
  } elsif ($val{go} eq GO_ORDER_DESC) {
    $usp{sqlorder} = "$val{orderfield} DESC";
    $usp{sqlpos} = 0;
		$usp{orderanyway} = 1;
  } elsif ($val{go} eq GO_SELECT) {
    $usp{sqlpos} = $val{selectnr};
    $usp{page}=1;
    $usp{page}=$val{selectpage} if $val{selectpage}>0;
  } elsif ($val{go} eq GO_ACT_SCAN) {
    $val{state} = EDIT;
    # Set to first Scandefinition.
    $usp{editAction} = "scan!0!".shift(@{DefsByName(DEF_SCAN)});
  } elsif ($val{go} eq GO_ACT_UPLOAD) {
    $val{state} = EDIT;
    $usp{editAction} = "newdoc";
    $val{adddocs} = 1;
  } elsif ($val{go} eq GO_ACTION) {
    processExtEditActions($val{action}); 
  } elsif ($val{go} eq GO_ACTION2) {
    processExtEditActions($val{action2}); 
  }  

=head

  if ($usp{sqlpos}>=$usp{sqlrecords}) {
    $usp{sqlpos}=$usp{sqlrecords}-1;
  }
  $usp{sqlpos}=0 if $usp{sqlpos}<0;
  $val{sqlstart}=(int $usp{sqlpos}/$val{sqllimit})*$val{sqllimit};
  $val{sqlposrel}=$usp{sqlpos}-$val{sqlstart};
  $usp{doc} = $val{selectdoc} if $val{selectdoc};
  $usp{page} = $val{selectpage} if $val{selectpage};
=cut

}






=head1 MainQuery()

Compose a new query for a search

=cut

sub MainQuery {
  $usp{sqlrecords}=0;
  $usp{sqlpos}=0;
  my $sql="";
  my $c0 = 0;
  foreach (@{$val{fields}}) {
    my @flds = ();
    my ($type,$value,$not,$gt)=MainQueryFldCheck($_,\@flds);
    if ($value ne "") {
      $sql .= " AND " if $c0>0;
      my $sql1 = "";
      my $c = 0;
      foreach (@flds) {
			  my $fld = $_;
				if ($val{go} eq GO_QUERYFILE) {
				  $value =~ s/(.*)(\\)(.*?)/$3/;
					for(my $c=1;$c<20;$c++) {
					  my $sql1 = "select $fld from archiv where $fld=".SQLQuote($value);
            my @row = getSQLOneRow($sql1);
						if ($row[0] eq $value) {
						  last;
						}
						sleep 1;
					}
				}
        $sql1 .= " OR " if $sql1 ne "";
        $sql1 .= MainQueryFld($_,$type,$value,$not,$gt);
        $c++;
      }
      $sql1 = "($sql1)" if $c>1;
      $sql = $sql . $sql1;
      $c0++;
    }
  }
  if ($sql ne "") {
    if ($val{searchmode} eq SRCH_AND) {
      $sql = "(" . $usp{sqlquery} . ") AND $sql";
    } elsif ($val{searchmode} eq SRCH_OR) {
      if ($usp{sqlfulltext} eq "") {
        $sql = "(" . $usp{sqlquery} . ") OR $sql";
      } else {
        $val{errorint} = $tr{error_fulltext_2};
        $usp{sqlfulltext} = "";
      }
    }
  }
  MainQueryFulltext();
  $usp{sqlquery}=$sql;
  $usp{sqlorder}="Datum DESC, Laufnummer DESC";
	if ($usp{sqlfulltext} ne "" && $usp{fulltextengine} != 2) {
    $usp{sqlorder}="ft_count DESC,$usp{sqlorder}" 
	}
	$usp{doc}=0;
	$usp{page}=0;
	MainUpdateSession();
}






=head1 MainQueryFulltext($psql)

Check if we need to add a fulltext part

=cut

sub MainQueryFulltext {
  my $values = "";
  if ($val{search_fulltext} ne "") {
    $values = $val{search_fulltext};
		if ($usp{fulltextengine} != 2) {
      if ($values =~ /\"/) {
        # Exact search
      } else {
        # Search for +main +streen, leave them
        if ( $values =~ /([\+\-])/ ) {
          # Nothing to change
        } else {
          # No +/- found, add them
          my @volltext = split(" ",$values);
          for ( my $c = 0 ; $c <= $#volltext ; $c++ ) {
            if ($val{searchmode} ne SRCH_OR) {
              $volltext[$c] = "+" . $volltext[$c];
            }
          }
          $values = join(" ",@volltext);
        }
      }
		}
    $usp{page}=-1;
  } else {
    # set page to 1
    $usp{page}=1;
  }
  if ($usp{sqlfulltext} ne "") {
    if ($val{searchmode} eq SRCH_OR) {
      $values .= " ($usp{sqlfulltext})";
    } elsif ($val{searchmode} eq SRCH_AND) {
      $values .= " $usp{sqlfulltext}";
    }
  }
  $usp{sqlfulltext}=$values;
}






=head1 ($type,$value)=MainQueryFldCheck($pf,$pflds)

Check for a value and Multifields for a field

=cut

sub MainQueryFldCheck {
  my $pf = shift;
  my $pflds = shift;
  my $not = 0;
  my $gt = "";
  my $name = $pf->{name};
  my $type = $pf->{type};
  my $avtype = $pf->{avtype};
  my $fakt = $name;
  if ($avtype == AV_MULTI || $avtype == AV_DEFINITION) {
    $fakt = $pf->{linked} if $avtype==AV_MULTI;
    push @$pflds,$fakt;
    foreach (@{$val{fields}}) {
      my $pf1 = $_;
      if ($pf1->{linked} eq $fakt && $pf1->{avtype}==AV_MULTI) {
        push @$pflds,$pf1->{name};
      }
    }
  } else {
     push @$pflds,$name;
  }
  my $fld = "fld_search_".$name;
  my $value = $val{$fld};
	if (length($value)==0) {
    $fld = "fld_".$name;
    $value = $val{$fld};
	}
  if (length($value)>=2) {
    my $first = substr($value,0,1);
    my $sec = substr($value,1,1);
    my $rest = substr($value,2,length($value)-1);
    if ($first eq "!") {
      $not = 1;
      $value = $sec.$rest; # check 
    } elsif ($first eq "<" && $type ne TYPE_CHAR && $type ne TYPE_TEXT) {
      $gt = "<";
      $value = $sec.$rest;
    } elsif ($first eq ">" && $type ne TYPE_CHAR && $type ne TYPE_TEXT) {
      $gt = ">";
      $value = $sec.$rest;  
    } elsif ($first eq "\\" && ($sec eq '!' || $sec eq "\\")) {
      $value = $sec.$rest;
    }
  }
	
  return ($type,$value,$not,$gt);
}






=head1 $sql=MainQueryFld($name,$type,$value) 

Give back the sql part for one specific field

=cut

sub MainQueryFld {
  my $name = shift;
  my $type = shift;
  my $value = shift;
  my $not = shift;
  my $gt = shift;
  my $sql = "";
  my $value2 = "";
  $sql .= "$name ";
  if ($type eq TYPE_CHAR || $type eq TYPE_TEXT ||
	    $type eq TYPE_CHARFIX) {
    if ($val{jokerstart}==1 || $val{jokerend}==1) {
      my $sql1 = "LIKE ";
      $sql1 = "NOT $sql1" if $not==1;
      $sql .= $sql1;
    } else {
      $sql .= "= ";
      $sql = "!$sql" if $not==1;
    }
    $value = "%$value" if $val{jokerstart}==1;
    $value = "$value%" if $val{jokerend}==1;
    $value = SQLQuote($value);
    $sql .= $value;
  } elsif ($type eq TYPE_YESNO) {
    $value = lc($value);
    if ($value eq "1" or $value eq "y" or $value eq "yes" or 
        $value eq "j" or $value eq "ja" or 
        $value eq "o" or $value eq "oui") {
        $value=1;
    } else {
      $value=0;
    }
    $sql .= " = $value";
  } else {
    my ($x,$y) = split(/-/,$value);
    if ($x ne "" && $y ne "") {
      $value = $x;
      $value2 = $y;
    }
    if ($type eq TYPE_DATE) {
      $value = MainSaveValuesDate($value);
      $value2 = MainSaveValuesDate($value2) if $value2 ne "";
    } else {
      $value="NULL" if $value eq "";
    }
    if ($value2 ne "") {
      $sql .= " BETWEEN $value AND $value2 ";
    } else {
      $sql .= " $gt= $value ";
    }
  }
  return $sql;
}
  






=head1 MainUpdate()

Save the changed fields for the specific document

=cut

sub MainUpdate {
  if ($usp{doc}>0) {
    my $sql="";
		my %text = ();
    foreach (@{$val{fields}}) {
      my $pf = $_;
      my $name = $pf->{name};
      my $type = $pf->{type};
      my $fld1 = "fld_edit_".$name;
      my $fld2 = "fld_".$name;
			my $fld = "";
      $fld = $fld1 if exists $val{$fld1};
      $fld = $fld2 if exists $val{$fld2};
			if ($fld ne "") {
			  # only accept fields that are available
        my $val = $val{$fld};
        if ($pf->{edit}==1) {
				  $val = fromUTF8($val) if $val{result_utf8}==1;
          my $res = 1;
          if ($name eq "Eigentuemer" || $name eq $usp{publishfield}) {
            if ($val ne "") {
              my $pval = getSelfAndAliasOwner();
              push @$pval,"[ALL]" if $name eq $usp{publishfield};
              $res = 0;
              foreach (@$pval) {
                $res=1 if $_ eq $val;
              }
            }
          }
					my $sql2="";
          if ($res==1 && MainUpdateCheckField($pf,$val,\$sql2)) {
            $sql .= "," if $sql ne "";
            $sql .= "$name=";
            if ($type eq TYPE_CHAR || $type eq TYPE_TEXT || 
						    $type eq TYPE_CHARFIX) {
              my $save = 1;
							MainUpdateText($fld,$val,\%text);
              $sql .= SQLQuote($val) if $save==1;
            } elsif ($type eq TYPE_YESNO) {
              $val = lc($val);
              if ($val eq "1" or $val eq "y" or $val eq "yes" or 
                $val eq "j" or $val eq "ja" or 
                $val eq "o" or $val eq "oui") {
                $val=1;
              } else {
                $val=0;
              }
              $sql.="$val";
            } elsif ($type eq TYPE_DATE) {
              $sql.=MainSaveValuesDate($val);
            } else {
              $val="NULL" if $val eq "";
              $sql.=$val;
              MainUpdateText($fld,$val,\%text);
            }
						if ($sql2 ne "") {
						  $sql .= "," if $sql ne "";
							$sql .= $sql2;
						}
          }
        }
      }
    }
    if ($sql ne "") {
      $sql .= ",UserModName=".SQLQuote($val{user});
      $sql = "update archiv set $sql where Laufnummer=$usp{doc}";
      SQLUpdate($sql);
			MainUpdateTextUpdate(\%text);
    }
  }
}






=head1 MainUpdateText($fld,$val,%text) 

Store all fields we have right to save

=cut

sub MainUpdateText {
  my ($fld,$val,$ptext) = @_;
	my @parts = split("_",$fld);
  my $fld1 = pop @parts;
	$val = "NULL" if $val eq "";
	$$ptext{$fld1} = $val;
}






=head1 MainUpdateTextUpdate(%text)

Save the new values to page text table

=cut

sub MainUpdateTextUpdate {
  my ($ptext) = @_;
	if ($usp{showfieldsocr}==1 && $usp{page}>0) {
    my $seitennr = getPageNumber($usp{doc},1);
    my $pstring1 = getBlobFile("Text",$seitennr,0,0,TABLE_PAGES);
		my $sep = "-" x 40;
		$sep = "\r\n".$sep."\r\n";
		my @parts = split($sep,$$pstring1[0]);
		my $text = "";
		$text = pop @parts if $parts[1] ne "";
		my @fields = split("\r\n",$text);
		my %saved = ();
		foreach my $line (@fields) {
      my @parts1 = split(": ",$line);
			my $fld1 = shift @parts1;
			my $val1 = join(": ",@parts1);
			if (!exists $$ptext{$fld1}) {
			  $$ptext{$fld1} = $val1;
			}
		}
		my $out = "";
		foreach my $fld2 (keys %$ptext) {
		  $out .= "\r\n" if $out ne "";
			$out .= "$fld2: ".$$ptext{$fld2};
		}
		push @parts,$out;
		my $outtext = join($sep,@parts);
    my $sql = "update archivseiten set Text = ".SQLQuote($outtext).
		          "where Seite=$seitennr";
		SQLUpdate($sql);
	}
}






=head1 $save=MainUpdateCheckField($pf,$val)

Check if the requested update is ok

=cut

sub MainUpdateCheckField {
  my $pf = shift;
  my $val = shift;
	my $psql = shift;
  my %fields=();
  my $val1="";
  my $save=1;
  my $double=0;
  my $fld = $pf->{name};
  return $save if $fld eq $usp{publishfield};
  if ($pf->{avtype}>AV_NORMAL) {
    if ($pf->{avtype}==AV_DEFINITION) {
      $fields{Definition} = $val;
      $fields{FeldDefinition} = $fld;
      if ($pf->{linked} ne "") {
        my $fld1 = $pf->{linked};
        $fld = "fld_edit_".$fld1;
        $val1 = $val{$fld};
				$val1 = fromUTF8($val1) if $val{result_utf8}==1;
        foreach(@{$val{fields}}) {
          my $pf1 = $_;
          if ($pf1->{name} eq $fld1) {
            if ($pf1->{avtype} eq AV_CODENUMBER ||
                $pf1->{avtype} eq AV_CODETEXT) {
              $double=1;
              $fields{Code}=$val1;
              $fields{FeldCode}=$fld1;
              last;
            }
          }
        }
      }
    } elsif ($pf->{avtype}==AV_CODENUMBER || $pf->{avtype}==AV_CODETEXT) {
      $double=1;
      $fields{FeldCode} = $fld;
      my $fld1 = $pf->{linked};
      $fld = "fld_edit_".$fld1;
      $val1 = $val;
      $val = $val{$fld};
			$val = fromUTF8($val) if $val{result_utf8}==1;
      $fields{Code} = $val1;
			if ($val eq "" && !exists($val{$fld})) {
			  my $sql = "select Definition from feldlisten where ".
				          "Code=".SQLQuote($val1)." AND " .
									"FeldCode=".SQLQuote($fields{FeldCode});
        my @row = getSQLOneRow($sql);
				$val = $row[0];
				$$psql = "$fld1=".SQLQuote($val);
			}
      $fields{Definition}=$val;
      $fields{FeldDefinition}=$fld1;
    } elsif ($pf->{avtype}==AV_MULTI) {
      $fld = $pf->{linked};
      $fields{Definition}=$val;
      $fields{FeldDefinition}=$fld;
    } elsif ($pf->{avtype}==AV_1TON) {
      my $fld1 = $pf->{linked};
      my $fld2 = "fld_edit_$fld1";
      $val1 = $val{$fld2};
			$val1 = fromUTF8($val1) if $val{result_utf8}==1;
      my $sql = "select Laufnummer from feldlisten where " .
                "Definition=".SQLQuote($val1)." AND " .
                "FeldDefinition=".SQLQuote($fld1);
      my $id = getSQLOneValue($sql);
      if ($id>0) {
        $fields{Definition}=$val;
        $fields{FeldDefinition}=$fld;
        $fields{ID}=$id;
      }
    }
    my $sql="";
    foreach (keys %fields) {
      my $fld = $_;
      $sql .= " AND " if $sql ne "";
      $sql .= "$fld=";
      if ($fld eq "ID") {
        $sql .= $fields{$fld};
      } else {
        $sql .= SQLQuote($fields{$fld});
      }
    }
    if ($sql ne "") {
      $sql = "select Definition,Code from feldlisten where $sql";
      my @row = getSQLOneRow($sql);
      if ($double==1) {
        $save=0 if $row[0] ne $val || $row[1] ne $val1;
      } else {
        $save=0 if $row[0] ne $val;
      }
    } else {
      $save=0;
    }
  }
  return $save;
}






=head1 MainPrinting

Print out one or more documents

=cut

sub MainPrinting {
  my $printer = $val{user_field}; # Additional Field in user Table ('Zusatz')
  if ($printer) {
    if($val{print_list} eq "1") {
      foreach my $document (split(',',$val{seldocs})) {
        MainPrintingSelectedDoc($document,$printer);
      }
    } else {
      MainPrintingSelectedDoc($usp{doc},$printer);
    }
  }
}






=head1 MainCopy

Copy the current document to a new empty document

=cut

sub MainCopy {
  my $doc = $usp{doc};
  my $sql = "select Laufnummer,Eigentuemer from archiv where Laufnummer=$doc";
  my ($doc1,$owner) = getSQLOneRow($sql);
  if ($doc1 == $doc) {
    my $edit = userHasRight($doc,$owner);
    if ($edit==1) {
      my $ordner = getParameterValue("ArchivOrdner");
      $sql = "describe archiv";
      my $prows = getSQLAllRows($sql);
      my @fields = ();
      foreach (@$prows) {
        my $field = @$_[0];
        if ($field ne "Akte" && $field ne "Seiten" && 
            $field ne "ErfasstDatum" && $field ne "Ordner" && 
            $field ne "EDVName" && $field ne "Erfasst" &&
            $field ne "Archiviert" && $field ne "Gesperrt" && 
            $field ne "Laufnummer") {
          push @fields,@$_[0];
        }
      }
      $sql = "insert into archiv (".join(',',@fields).") select ".
             join(',',@fields)." from archiv where Laufnummer=$doc";
      SQLUpdate($sql);
      $sql = "select LAST_INSERT_ID()";
      my ($doc2) = getSQLOneRow($sql);
      my $date1 = DocumentAddDatForm( TimeStamp() );
      my $uid = SQLQuote($val{user});
      $sql = "update archiv set Datum=$date1,ErfasstDatum=$date1,".
             "Gesperrt='',UserNeuName=$uid,Akte=$doc2,Ordner=$ordner ".
						 "where Laufnummer=$doc2";
      SQLUpdate($sql);
      $val{copyselect}=1;
      $usp{doc}=$doc2;
      $usp{page}=0;
      $usp{sqlquery}="Laufnummer=$doc2";
      $usp{page}=$val{selectpage} if $val{selectpage}>0;
    }
  }
}






=head2 $sqldat=DocumentAddDatForm(yyyymmdd)

Format a date ('yyyy-mm-dd 00:00:00')

=cut

sub DocumentAddDatForm {
  my $d = shift;
  $d = "'".substr($d,0,4)."-".substr($d,4,2)."-".substr($d,6,2)." 00:00:00'";
  return $d;
}






=head2 $stamp=TimeStamp 

Actual date/time stamp (20040323130556)

=cut

sub TimeStamp {
  my @t = localtime( time() );
  my ( $stamp, $y, $m, $d, $h, $mi, $s );
  $y     = $t[5] + 1900;
  $m     = $t[4] + 1;
  $m     = sprintf( "%02d", $m );
  $d     = sprintf( "%02d", $t[3] );
  $h     = sprintf( "%02d", $t[2] );
  $mi    = sprintf( "%02d", $t[1] );
  $s     = sprintf( "%02d", $t[0] );
  $stamp = $y . $m . $d . $h . $mi . $s;
  return $stamp;
}






=head1 MainPrintingSelectedDoc

Print out a given document

=cut

sub MainPrintingSelectedDoc {
  my $document = shift;
  my $printer  = shift;
  my $pdftk = "/usr/bin/pdftk";
  my $pdf2ps = "/usr/bin/pdf2ps -dLanguagesLevel=2";
  my $lpr = "/usr/bin/lpr_cups";
  my $file = TEMP_PATH."print_$val{db}_$document";
  my $pdf_file = $file.".pdf";
  my $pdf_temp = $file."_tmp.pdf";
  my $ps_file = $file.".ps";
  my $tif_file = $file.".tif";
  my $jpg_file = $file.".jpg";
  my $pnm_file = $file.".pnm";
  my $from = $val{print_from};
  my $to   = $val{print_to};
  my $fol = 0;
  my $arc = 0;
  $from = 1 if $from eq "";
  if ($to eq "") {
    my $sql = "select Seiten,Ordner,Archiviert from archiv ".
              "where Laufnummer=$document";
    ($to,$fol,$arc) = getSQLOneRow($sql);
  }
  my $cmd = "";

  my $pfirstpage = getBlobFile("Quelle",getPageNumber($document),$fol,$arc);
  my $plastpage = getBlobFile("Quelle",getPageNumber($document,$to),$fol,$arc);
  if(length($$pfirstpage[0]) > 0) {
    if(length($$plastpage[0]) > 0) { # we have single pdf files
      for(my $seite=$from;$seite<=$to;$seite++) {
        my $pdf_page = $file."_".sprintf("%04d",$seite).".pdf";
        my $ppdf=getBlobFile("Quelle",getPageNumber($usp{doc},$seite),
                             $fol,$arc);
        my $ok=writeFile($pdf_page,$$ppdf[0],1);
        my $s1 = sprintf("%04d",$seite); # compose pdftk fragment
        $cmd .= "$pdf_page";
      }
      $cmd = "$pdftk $cmd cat $from-$to output $pdf_file";
      system($cmd);
    } else { # all pdf pages in one big file, so extract needed pages
      my $ppdf = getBlobFile("Quelle",getPageNumber($usp{doc}),$fol,$arc);
      if(length($$ppdf[0]) > 0) {
        writeFile($pdf_temp,$$ppdf[0]);
        $cmd = "$pdftk $pdf_temp cat $from-$to output $pdf_file";
        system($cmd);
      }
    }
    $cmd = "$pdf2ps $pdf_file $ps_file";
    system($cmd);
    $cmd = "$lpr -r -P $printer $ps_file";
    system($cmd);
  } else {
    # Create the whole pdf because it does not exist
    my $sql = "select ArchivArt from archiv where Laufnummer=$document";
    my $art = getSQLOneValue($sql);
    if ($art==1 || $art==3) {
      for(my $seite=$from;$seite<=$to;$seite++) {
        my $file1 = $file."_$seite";
        $ps_file = $file1.".ps";
        my $ps_file1 = $file1."-1.ps";
        $tif_file = $file1.".tif";
        $jpg_file = $file1.".jpg";
        $pnm_file = $file1.".pnm";
        unlink $ps_file if -e $ps_file;
        unlink $pnm_file if -e $pnm_file;
        unlink $tif_file if -e $tif_file;
        unlink $jpg_file if -e $jpg_file;
        my $ppdf =
        getBlobFile("BildInput",getPageNumber($document,$seite),
                    $fol,$arc);
        if (length($$ppdf[0])>0) {
          if ($art==1) {
            if (writeFile($tif_file,$$ppdf[0],1)) {
              my $cmd = "tifftopnm $tif_file >$pnm_file";
              system($cmd);            
            }
          } elsif ($art==3) {
            if (writeFile($jpg_file,$$ppdf[0],1)) {
              my $cmd = "jpegtopnm $jpg_file >$pnm_file";
              system($cmd);
            }
          }
          if (-e $pnm_file) {
            my $cmd = "pnmtops $pnm_file >$ps_file";
            system($cmd);
            if (-e $ps_file) {
              my $cmd = "$lpr -r -P $printer $ps_file";
              system("$cmd");
            }
          }
        }
      }
    }
  }
  unlink <$file*>; # remove all temporary files with type globing (perl 5.8)
}






=head1 MainSaveValuesDate($date)

Convert german/english date string to formatted datetime string

=cut

sub MainSaveValuesDate {
  my $date = shift;
  my $lang = $usp{lang};
  my ( undef, undef, undef, $day, $mon, $year ) = localtime();
  $year += 1900;
  $mon  += 1;
  if (length($date)==0) {
    $date = "NULL";
  } elsif ($date =~ /\s/ ) {
    $date =~ s/\s/$year-$mon-$day 00:00:00/;
    $date = "'".$date."'";
  } elsif ($lang eq "de" ) {
    $date =~ s/^(\d{1,2})(\.)(\d{1,2})$/$year-$3-$1 00:00:00/;
    $date =~ s/^(\d{1,2})(\.)(\d{1,2})(\.)(\d{2,4})$/$5-$3-$1 00:00:00/;
    $date = "'".$date."'";
  } elsif ($lang eq "fr" ) {
    $date =~ s/^(\d{1,2})(\/)(\d{1,2})$/$year-$3-$1 00:00:00/;
    $date =~ s/^(\d{1,2})(\/)(\d{1,2})(\/)(\d{2,4})$/$5-$3-$1 00:00:00/;
    $date = "'".$date."'";
  } elsif ($lang eq "en" ) {
    $date =~ s/^(\d{1,2})(\/)(\d{1,2})$/$year-$1-$3 00:00:00/;
    $date =~ s/^(\d{1,2})(\/)(\d{1,2})(\/)(\d{2,4})$/$5-$1-$3 00:00:00/;
    $date = "'".$date."'";
  }
  return $date;
}



=head1 MainSelection($doc)

Select the current needed documents

=cut

sub MainSelection {
  my $doc = shift;
  return if $val{dbh} eq "";
  my ($sql,$sql1,$limit);
	($sql,$sql1,$limit) = MainSelectionInit($doc);
  $sql .= " limit $limit";
  $val{rows} = getSQLAllRows($sql);
  MainSelectionCount($sql1,$doc);
  my $chk = 'frm_Laufnummer';
  if ($val{$chk}==1) {
    my $first=0;
    my @docs = ();
    foreach (@{$val{rows}}) {
      my $row = $_;
      if ($first==0) {
        $usp{doc}=$$row[0];
        $usp{page}=$$row[1];
        $first=1;
      }
      push @docs,$$row[0];
    }
    $val{sqlstart} = $usp{doc};
    MainUpdateSession();
  }
  # find the indexes of some interesting fields
  my $pos=0;
  my $posdoc = -1;
  my $pospages = -1;
  my $posowner = -1;
  foreach (@{$val{fields}}) {
    $posdoc=$pos if $_->{name} eq "Laufnummer";
    $pospages=$pos if $_->{name} eq "Seiten";
    $posowner=$pos if $_->{name} eq "Eigentuemer";
    $pos++;
  }

  # find the current doc
  foreach my $prow (@{$val{rows}}){
    if($prow->[$posdoc] eq $usp{doc}){
      $val{pages}=$prow->[$pospages] if $pospages >= 0;
      $val{docowner}=$prow->[$posowner] if $posowner >= 0;
      last;
    }
  }

  # cleanup session if doc has changed
  $usp{page}=$val{pages} if $usp{page}>$val{pages};
  $usp{page}=1 if $usp{page}<=0;
  $usp{page}=0 if $val{pages}==0;
}



=head1 ($sql,$limit)=MainSelectionInit($doc)

Get the current sql string based on the selection (with/without doc)

=cut
sub MainSelectionInit {
  my $doc = shift;
  if ($usp{sqlquery} eq "" && $usp{sqlfulltext} eq "") {
    ($usp{sqlquery},$usp{sqlorder})=SQLsplit($usp{sqlstart});
  }
  $usp{sqlquery}="Laufnummer>0" if $usp{sqlquery} eq "";
  $usp{sqlorder}="Laufnummer DESC" if $usp{sqlorder} eq "";
  $val{sqlstart}=0 if $val{sqlstart} eq "";
	$val{sqllimit}=16 if $val{sqllimit} eq "";
  my $limit = "$val{sqlstart},$val{sqllimit}";
  my $sel="";
  foreach (@{$val{fields}}) {
    my $pflds = $_;
    $sel.="," if $sel ne "";
    $sel.=$$pflds{name};
  }
	$sel = "Laufnummer" if $sel eq ""; # we don't have fields (reduced)
  my $sel2 = ",Gesperrt,ArchivArt,EDVName"; # add the internal fields
  my ($sel1,$whe1,$group1)=MainSelectionFulltext($doc);
  my $sql = "select $sel$sel1$sel2 from $val{db}.".TABLE_ARCHIVE;
  $sql .= ",$val{db}.".TABLE_PAGES if $sel1 ne "";
  my $sql1 .= $usp{sqlquery}.getEigentuemerZusatz();
  my $order = "order by $usp{sqlorder}";
	$order = "" if $doc>0; # don't use any order if we only call current doc
  $sql1 = MainSelectionDocument($sql1,\$limit,$doc);
  if ($whe1 ne "") { # we have fulltext at all
    $sql1 .= " AND " if $sql1 ne "";
    # FIXME: only getting one doc- why order it?
    if ($doc==0 && $usp{fulltextengine} !=2) {
      $order = "order by ft_count desc,Laufnummer desc" if $order eq "";
		} elsif ($usp{fulltextengine}==2) {
		  # sphinx engine we dont can use any order (we use ranking)
		  MainSelectionFulltextOrder(\$order,\$group1);
    } else {
      $order = "order by Laufnummer desc";
    }
	}
  $sql1 .= $whe1;
  $sql .= " where $sql1 " if $sql1 ne "";
  $sql .= "$group1 $order";
  #warn ($sql);
  return ($sql,$sql1,$limit);
}



=head1 MainSelectionFulltextOrder($porder,$pgroup1)

Give back the corrected sort order from sphinx fulltext 

=cut

sub MainSelectionFulltextOrder {
  my ($porder,$pgroup1) = @_;
	if ($usp{orderanyway}==0) {
	  $$porder = ""; # we use our own order structure
    if ($$pgroup1 ne "") {
      # we want to sort the hits according relevance, so we present
		  # the most important hit at end, less important hit at start
		  foreach (split(/,/,$$pgroup1)) {
		    $$porder = ",$$porder" if $$porder ne "";
		    $$porder = "Laufnummer=$_".$$porder;
		  }
		  $$porder = "order by $$porder";
		  $$pgroup1="";
		}
	} else {
	  # user clicked order by Buttone, so dont overwrite order by
	  $$pgroup1="";
	}
}



=head1 MainSelectionDocument(where,limit,doc)

Modify sql statement if only getting one document

=cut

sub MainSelectionDocument {
  my $whe1 = shift;
  my $plimit = shift;
  my $doc = shift;
  if($doc){
    $whe1 = "Laufnummer=$doc".getEigentuemerZusatz();
    $$plimit = "1";
  }
  return $whe1;
}






=head1 MainSelectionCount($sql1,$doc)

Check if we need to count the select

=cut

sub MainSelectionCount {
  my $sql1 = shift;
	my $doc = shift;
  my $sqlc = "";
  my $fld = "";
	if ($doc==0) { # only asc for total if we initialize query
    if ($usp{sqlrecords}==0) {
      if ($usp{sqlfulltext} ne "" && $usp{fulltextengine} !=2) {
        $sqlc = "select count(distinct Laufnummer) " .
                "from ".TABLE_ARCHIVE.",".TABLE_PAGES;
      } else {
        $sqlc = "select count(Laufnummer) from ".TABLE_ARCHIVE;
      }
      $sqlc .= " where ".$sql1 if $sql1 ne "";
      $usp{sqlrecords} = getSQLOneValue($sqlc);
    }
    if (@{$val{rows}}[0]==0) {
      $val{errorint} = $tr{error_nodocs};
      $val{state} = SEARCH if $val{state} eq VIEW;
    }  
	}
}
  


=head1 sqlpart=MainSelectionFulltext($doc);

Checks if we have a fulltext query or not

=cut

sub MainSelectionFulltext {
  my ($doc) = @_;
  my $sel1 = "";
  my $whe1 = "";
  my $group1 = "";
  if ($usp{sqlfulltext} ne "" && $doc==0) {
	  if ($usp{fulltextengine} != 2) {
      $sel1  = ",mod(min(archivseiten.Seite),1000) as ft_min".
               ",mod(max(archivseiten.Seite),1000) as ft_max".
               ",count(archivseiten.Seite) as ft_count";
      $whe1 = $val{db}.".".TABLE_ARCHIVE.".Laufnummer=truncate((".
              $val{db}.".".TABLE_PAGES.".Seite/1000),0) and match ".
              $val{db}.".".TABLE_PAGES.".Text against ".
              "('$usp{sqlfulltext}' in boolean mode) ";
      $group1 = "group by Laufnummer ";
	  } else {
		  my $nr = "";
		  my $text = SphinxSearchText($usp{sqlfulltext});
	    my $sql = "select * from $val{db} where match('$text') ".
			          "group by laufnummer limit 1000";
		  SphinxSearch($sql,\$nr,3);
		  $nr =~ s/(\n+$)//sm;
		  $nr =~ s/^,//;
		  $nr =~ s/,$//;
		  $nr =~ tr/\n/,/;
			$nr = "-1" if $nr eq "";
		  if ($nr ne "") {
        $whe1 = "Laufnummer IN ($nr)";
				$group1 = $nr;
		  }
	  }
	}
  return ($sel1,$whe1,$group1);
}






=head1 ($where,$order)=SQLsplit($sql)

Split an sql fragment into where and order by

=cut

sub SQLsplit {
  my $sql = shift;
  my $sql1 = lc($sql);
  my $ord = "order by ";
  my $lang = length($sql);
  my $lord = length($ord); 
  my $pos = rindex($sql1,$ord);
  my ($where,$order);
  if ($pos>0) {
    $where = substr($sql,0,$pos-1);
    $order = substr($sql,$pos+$lord,$lang-($pos+$lord-1));
  } elsif ($sql ne "") {
    if ($pos==0) {
      $order = substr($sql,$pos+$lord,$lang-($pos+$lord-1));
    } else {
      $where = $sql;
    }
  }
  return ($where,$order);
}






=head1 MainOut

Prints the form with the Frames

=cut

sub MainOut {
  my $print = Header();
  if ($val{user_pwnew}>1 && $val{go} ne GO_LOGOUT) {
    $print .= newPasswordRequestForm();
  } else {
    if ($val{error} eq "") {
      if ($val{dbh}) {
        my $chk = 'frm_Laufnummer';
        if ($val{$chk}==0) {
          $print .= ${MainPrint()};
        } else {
          $print .= qq(<body>);
          $print .= ${MainForm()};
          $print .= qq(</body>);
        }
      } else {
        $print .= LoginForm();
      }
    } else {
      $print .= LoginForm();
    }
  }
  $print .= qq{</html>\n};
  print $print;
}






=head1 MainForm()

Creates a form code for calling values externally

=cut

sub MainForm {
  my @form;
  my $cgi = CGIDIR.CGIPRG;
  my $print = qq{<form onSubmit="getScreenSize();" name="form" } .
              qq{action="$cgi" method="post">\n};
  $print .= qq{<input type="hidden" name="avversion" value="}.
            getVersion().qq{">};
  my $col=0;
  foreach (@{$val{fields}}) {
    my $pfld = $_;
    my $name = $pfld->{name};
    my $chk = "frm_$name";
    $form[$col]=$name if $val{$chk}==1;
    $col++;
  }
  my $prow = $_;
  my $row=0;
  foreach(@{$val{rows}}) {
    my $prow = $_;
    $col=0;
    foreach(@{$prow}) {
      my $fldval = $_;
      last if ($col==0 && $fldval ==0);
      if ($form[$col] ne "") {
        my $name = $val{fields}[$col]->{name};
        MainPrintFieldFormat(\$fldval,$val{fields}[$col]->{type});
        my $row1=$row+1;
        $print .= qq(<input type="hidden" name="$name).
                     "_".qq($row1" value="$fldval">);
      }
      $col++;
    }
    $row++;
  }
  $print .= "</form>";
  return \$print;
}






=head1 MainPrint()

Creates all html code (if we are connected)

=cut

sub MainPrint {
  my $pics = WWWDIR . '/pics';
  my $url  = CGIDIR.CGIPRG;
  my $form = AVFORM;
  my $tab = 'SearchTab'; # decide which tab to show by default
  if($val{state} eq EDIT){
    $tab = 'EditTab';
  } elsif($val{state} eq VIEW){
    $tab = 'ViewTab';
  }
  my $pos = $usp{sqlpos}; # decide which record to show by default
  $pos = 0 if $pos < 0;
  my $doc = $usp{doc};
  $doc = 0 if !length $doc;
  my $page = $usp{page};
  $page = 0 if !length $page;
  $usp{zoom}=0 if ($usp{zoom} eq '' || $usp{zoom}<0);
  $usp{zoom}=1 if $usp{zoom}>1;
  $usp{rotate}=0 if(!length $usp{rotate});
  # body and form starting tags and hidden inputs
	my $mode = "Main";
	$mode = "Page" if $val{view} eq PAGE;
	my $onresize = "";
  if ($ENV{HTTP_USER_AGENT} =~ /MSIE\s[5-9]\./) {
	  $onresize = qq{ onResize="GRT.go_resize();"};
	}
  my $html = qq/<body onload="GRT = new ResultTable/
    . qq/(\$('Results'),\$('Record'),'$url','$mode','$tab',$pos,$doc,$page,/
    . qq/$usp{zoom},$usp{rotate},$usp{showpdf},$usp{photomode}); /
    . qq/GRS = new ResizeSibs(\$('ResizeHandle'),GRT,/
    . qq/['ButtonBar','StatusBar']);"$onresize>\n/
    . qq/<form name="$form" action="$url" method="post">\n/
    . ${MainPrintHidden($val{view})};

  $html .= q{<div id="ButtonBar">}; # the button/ext edit control bar
  $html .= ${MainPrintButtons()};
  $html .= ${MainPrintExtEditMain()};
  $html .= ${MainPrintExtEditPage()};
	$html .= "</div>"; # ButtonBar

  $html .= qq/<div id="Results">/; # result table, top of main view
	$html .= ${MainPrintTable($pics)};
  $html .= qq{<div id="ResultsThumbs"></div>};
  $html .= qq{<div id="ResizeHandle"><img src="$pics/resizeHandle.gif"></div>};
  $html .= qq|</div>|; # end Results
  
	$html .= qq|<div id="Record">|; # current record (left side)
  $html .= qq|<div id="RecordTabs">|; # inside current record
  $html .= MainPrintDetailReiter('ViewTab',GO_VIEW,"view");
  $html .= MainPrintDetailReiter('SearchTab',GO_SEARCH,"search");
  $html .= MainPrintDetailReiter('EditTab',GO_EDIT,"edit");
  $html .= qq|</div>|; # end RecordTabs
  $html .= qq|<div id="RecordDetail">|; # RecordDetail (colored part)
  $html .= qq|<div id="RecordDetailScroll">|; # Scrolling part
  $html .= TableInit("ViewTable");  # the view table
  $html .= ${MainPrintDetailDoc(VIEW)} . TableEnd();
  $html .= TableInit("SearchTable"); # the search table
  $html .= ${MainPrintDetailDoc(SEARCH)} . TableEnd();
  $html .= TableInit("EditTable"); # the edit table
  $html .= ${MainPrintDetailDoc(EDIT)} . TableEnd();
  $html .= "</div></div></div>"; # end of Record 
	
  my $go = GO_PAGEVIEW;
  my $src = "$pics/button_pixel.gif"; # load 1 pixel at start, rest from js
	my $js = qq{onclick="return GRT.go_page(this)"}; 
  $html .= qq{<div id="RecordImage"><div id="noteWrapper">}; # RecordImage
  $html .= qq{<img name="$go" src="$src" id="noteImage" $js>};
  $html .= "</div></div>"; # end RecordImage
  $html .= ${MainPrintStatus()}; # status bar and notes menu
  $html .= ${obj::Note::getNotes(\%tr)};
  $html .= qq{</form></body></html>}; # close html file
  return \$html;
}



sub TableEnd {
  return "</table>\n\n";
}



sub TableInit {
  my ($id,$border,$width) = @_;
	$border = "0" if $border eq "";
	my $html = "<table ";
	$html .= qq/id="$id" / if $id ne "";
	$html .= qq/border="$border" cellpadding="0" cellspacing="0"/;
	$html .= qq/ width="$width"/ if $width ne "";
	$html .= qq/>/;
	return $html;
}
	 


sub MainPrintTable {
  my ($pics) = @_;
  my $screenWidth = getCookie("ScreenWidth")-14;
	my $pdfwidth = 135;
	my $selwidth = 40;
	my @widths = @{MainPrintTableCalc($screenWidth,$pdfwidth,$selwidth)};
	my ($html,$diff) = MainPrintTableH(\@widths,$screenWidth,$pdfwidth,$selwidth);
	$html .= TableInit("ResultsHeader",0,$screenWidth).qq/<colset>/;
	my $c=0;
	$widths[4] = $widths[4]+$diff; # adjust the not filled pixels
  foreach my $pfld (grep {!$_->{hide}} @{$val{fields}}) {
    $html .= qq(<col width="$widths[$c]">);
		$c++;
  }
  $html .= qq{<col width="$pdfwidth">\n} if $usp{showpdf}==1; # show download?
  $html .= qq{<col width="$selwidth"></colset><tr>\n};
  foreach my $pfld (grep {!$_->{hide}} @{$val{fields}}) {
    my $uname = $pfld->{name};
    my $id = 'Results_'.$uname;
    my $name = 'ordDesc_'.$uname;
    my $class = '';
    if($usp{sqlorder} eq $pfld->{name} || $usp{sqlorder} eq $uname){
      $class = 'class="Active"';
    } elsif ($usp{sqlorder} eq $pfld->{name} . ' DESC' || 
		         $usp{sqlorder} eq $uname . ' DESC') {
      $class = 'class="Active"';
      $name = "ordAsc_".$pfld->{name};
    }
    $html .= qq(<td id="$id" $class><input name="$name" type="submit" $class ).
		         qq(value="$pfld->{label}"></td>\n);
  }
  if ($usp{showpdf}==1) {  # the download column
    $html .= q(<td>&nbsp;) . $tr{download} . q(</td>);
  }
  $html .= qq{<td><input type="checkbox" }.
	         qq{id="ResultsHeaderCB" name="selalldocs" }.
					 qq{onClick="GRT.selectAllDocs()"></td>};
	$html .= qq{</tr>};
	$html .= TableEnd();
	$html .= qq{<div id="ResultsScroll">};
  $html .= TableInit("ResultsTable",0,$screenWidth);
  $html .= qq{<colset>};
	$c = 0;
  foreach my $pfld (grep {!$_->{hide}} @{$val{fields}}) {
    $html .= qq(<col width="$widths[$c]">);
		$c++;
  }
  $html .= qq{<col width="$pdfwidth">\n} if $usp{showpdf}==1; # download column
  $html .= qq{<col width="$selwidth"></colset>};
	$html .= qq{<tbody id="ResultsBody"></tbody>};
	$html .= TableEnd();
	$html .= qq{</div>}; # closing ResultsScroll
	return \$html;
}



=head1 $html = MainPrintTableH($pwidth,$screenWidth,$pdfwidth,$selwidth)

Give back hidden vars for fields and screenWidth

=cut

sub MainPrintTableH {
  my ($pwidth,$screenWidth,$pdfwidth,$selwidth) = @_;
	my $html = join(",",@$pwidth);
	$html = qq{<input id="hcols" type="hidden" name="hcols" values="$html">};
	$html .= qq{<input id="hall" type="hidden" }.
	         qq{name="hall" values="$screenWidth">};
	my $wpdf = 0;
	$wpdf = $pdfwidth if $usp{showpdf}==1;
	$html .= qq{<input id="hpdf" type="hidden" }.
	         qq{name="hall" values="$wpdf">};
	$html .= qq{<input id="hsel" type="hidden" }.
	         qq{name="hsel" values="$selwidth">};
	my $all = 0;
	foreach (@$pwidth) {
	  $all = $all + $_;
	}
	$all += $pdfwidth if $usp{showpdf}==1;
	$all += $selwidth;
	my $diff = $screenWidth-$all;
	$html .= qq{<input id="hdiff" type="hidden" }.
	         qq{name="hdiff" values="$diff">};
  my $htab = getCookie("ScreenHeight")-360;
	$html .= qq{<input id="htab" type="hidden" }.
	         qq{name="htab" values="$htab">};
	return ($html,$diff);
}



=head @widths = MainPrintTableCalc

Calculate the width of each column

=cut

sub MainPrintTableCalc {
  my ($screenWidth,$pdfwidth,$selwidth) = @_;
  my $max = 0; # store desired max. of table columns
	my $fix = 225; # laufnummer + seiten + datum + archiviert
	$fix += $pdfwidth if $usp{showpdf}==1; # add download column ?
	$fix += $selwidth; # width for seldocs
	my $var = $screenWidth - $fix; # we have max. width vor var. fields
  foreach my $pfld (grep {!$_->{hide}} @{$val{fields}}) {
    my $width = $pfld->{width};
		$width = 60 if $pfld->{name} eq "Laufnummer";
		$width = 45 if $pfld->{name} eq "Seiten";
		$width = 80 if $pfld->{name} eq "Datum";
		$width = 40 if $pfld->{name} eq "Archiviert";
		$max += $width; # put together
	}
	$max+=$pdfwidth if $usp{showpdf}==1; # add width for download column ? 
	$max+=$selwidth; # add space for download + selectdocs
	$max-=$fix; # substract the fix width         
	my $factor = $max/$var; # now calculate the factor of width we can use
	$factor = 1 if $factor <=0;
	my @widths = (); # initialize widths
  foreach my $pfld (grep {!$_->{hide}} @{$val{fields}}) {
    my $width = int($pfld->{width}/$factor); # calulcate it
		$width = 60 if $pfld->{name} eq "Laufnummer";
		$width = 45 if $pfld->{name} eq "Seiten";
		$width = 80 if $pfld->{name} eq "Datum";
		$width = 40 if $pfld->{name} eq "Archiviert";
		push @widths, $width; # store the final size we want to use
	}
	return \@widths;
}



=head1 MainPrintHidden()

Add hidden form inputs

=cut

sub MainPrintHidden {
  my $hidden = shift;
  
  my $print = qq{<input type="hidden" name="key" value="">\n};
  $print .= qq{<input type="hidden" name="shft" value="">\n};
  $print .= qq{<input type="hidden" name="ctrl" value="">\n};
  $print .= qq{<input type="hidden" name="alt" value="">\n};
  $print .= qq{<input type="hidden" name="state" value="$hidden">\n};
  $print .= qq(<input type="hidden" name="imgdoc" value="$usp{doc}">);
  $print .= qq(<input type="hidden" name="imgpage" value="$usp{page}">);
  $print .= qq{<input type="hidden" name="avversion" value="}. getVersion().qq{">\n};
  $print .= qq{<input type="hidden" name="copyselect" value="}. $val{copyselect}.qq{">\n};
  if ($usp{exportallowed} ne "") {
    $print .= qq{<input type="hidden" name="exportdb" value="">\n};
  }
  $print .= qq{<input type="hidden" name="mailstatus" value="Ok">\n};

  return \$print;
}



###############################################################
# functions for working with buttons and extended edit controls

=head1 MainPrintButtons()

Note: makes buttons for both Main and Page view,
javascript decides which ones to show based on the class

=cut

sub MainPrintButtons {
  my $cgi = CGIDIR.CGIPRG;
  my $html = '';
  if (ExitButton()) {
    $html .= PrintButton(GO_LOGOUT,$tr{exit},"pma07",'','','');
  }

  # FIXME: the translation needs to change on page view?
  $html .= PrintButton(GO_PAGEVIEW,$tr{siteview},"pma08",
    'Main Page','return GRT.go_page(this)');
  $html .= PrintButton(GO_THUMBS,$tr{thumb},"pma09",
    'Main','return GRT.go_thumbs(this)');
  $html .= PrintButton(GO_ALL,$tr{all},"pma22",'Main','');

  # these are page view specific
  $html .= PrintButton(GO_ROTATE_LEFT,$tr{left},"pga08",
    'Page','return GRT.go_rotate(this,270)');
  $html .= PrintButton(GO_ROTATE_180,$tr{n},"pga10",
    'Page','return GRT.go_rotate(this,180)');
  $html .= PrintButton(GO_ROTATE_RIGHT,$tr{right},"pga09",
    'Page','return GRT.go_rotate(this,90)');
  $html .= PrintButton(GO_ZOOM_NO,$tr{normal},"pga13",
    'Page','return GRT.go_zoom(this,0)');
  $html .= PrintButton(GO_ZOOM_IN,$tr{zoomin}, "pga14",
    'Page',q|return GRT.go_zoom(this,'+')|);
  $html .= PrintButton(GO_ZOOM_OUT,$tr{zoomout},"pga15",
    'Page',q|return GRT.go_zoom(this,'-')|);

  # all these show on main, some also page
  $html .= PrintButton(GO_DOCS_PREV, $tr{first_rs},"poa00",
    'Main',"return GRT.docs_prev(this)");
  $html .= PrintButton(GO_DOC_PREV, $tr{prev_rs}, "poa01",
    '',"return GRT.doc_prev(this)");
  $html .= PrintButton(GO_PAGE_FIRST,$tr{first_page},"pmb00",
    'Main',"return GRT.page_first(this)");
  $html .= PrintButton(GO_PAGE_PREV, $tr{prev_page}, "pga17",
    '',"return GRT.page_prev(this)");
  $html .= qq{<input class="Button Jump" }.
    qq{id="page_jump" name="jump" maxlength="3" type="text">};
  $html .= PrintButton(GO_PAGE_JUMP,$tr{jump},"pga31",
    '',"return GRT.page_jump(this,'page_jump')");
  $html .= PrintButton(GO_PAGE_NEXT,$tr{next_page},"pga18",
    '',"return GRT.page_next(this)");
  $html .= PrintButton(GO_PAGE_LAST,$tr{last_page},"pmb03",
    'Main',"return GRT.page_last(this)");
  $html .= PrintButton(GO_DOC_NEXT, $tr{next_rs},"poa02",
    '',"return GRT.doc_next(this)");
  $html .= PrintButton(GO_DOCS_NEXT,$tr{last_rs},"poa03",
    'Main',"return GRT.docs_next(this)");

  #only visible if user has right
  if ($val{user_addnew} && !getParameterValue(HIDE_EXTICONS)) {
    $html .= PrintButton(GO_ACT_SCAN,$tr{act_scan},"pga01",'Main',
      "return GRT.makeActiveTabRec('EditTab','extactions','select_action','scan!')");
    $html .= PrintButton(GO_ACT_UPLOAD,$tr{act_upload},"pga25",'Main',
      "return GRT.makeActiveTabRec('EditTab','adddocs','','')");
  }

  # javascript makes visible in pageview only with edit tab
  $html .= PrintButton(GO_NOTE . '_add',$tr{note_add},"pmaNote",
      'PageEditTab','return GRT.newNote(this)','NoteButton');

  if (ViewHelp()) {
    my $href = "/manual.pdf";
    $href = "/handbuch.pdf" if $usp{lang} eq "de";
    my $src = WWWDIR . "/pics/help" . ICONTYPE;
    $html .= 
      qq{<a class="Button" }.
      qq{href="$href" target="_new">}.
      qq(<img border="0" title="$tr{act_help}" }.
      qq{alt="$tr{act_help}" src="$src"></a>);
  }

  # the zoom slider. Only used by page view
  $html .= qq{<div id="ZoomWrapper">};
	$html .= qq|<div id="track1" style="position:absolute; width:200px; |.
	         qq|background-color:#aaa; height:5px;">|.
				   qq|<div id="handle1" style="position:absolute; width:5px; |.
					 qq|height:10px; background-color:rgb(161,54,85); cursor:move;">|;
	$html .= qq|</div></div></div>\n|;
  return \$html;
}



=head1 PrintButton($value,$title,$image,$key,$class,$onclick)

Return the html code for a button
  
=cut

sub PrintButton {
  my $value = shift;
  my $title = shift;
  my $image = shift;
  my $class = shift;
  my $onclick = shift;
  my $id = shift;
  if(length $onclick){
    $onclick = q{onclick="} . $onclick . q{"};
  }
  if(length $class){
    $class = ' Hideable ' . $class;
  }
  if(length $id){
    $id= q{id="} . $id. q{"};
  }
  my $src = WWWDIR . "/pics/$image" . ICONTYPE;
  return qq(<input class="Button$class" name="$value" type="image" $id )
       . qq(src="$src" title="$title" alt="$title" $onclick>\n);
}



=head1 $html=MainPrintExtEditMain()

Return the extended edit actions html for main view

=cut

sub MainPrintExtEditMain {
  my $print="";

  # the 'upload' controls
  if ($val{user_addnew}) {
    my $max = 128 * 1024 * 1024; # max. size of block we get (128 MByte)
    $print .= qq{<div id="adddocs">\n}.
      qq{<input type="hidden" name="MAX_FILE_SIZE" value="$max">\n}.
      qq{ <input type="file" name="upload">\n}.
      qq{<select name="uploadbits">\n}.
      qq|<option value=1>$tr{send_artbw}</option>\n|.
      qq|<option value=8>$tr{send_artgray}</option>\n|.
      qq|<option value=24>$tr{send_artcolor}</option>\n|.
      qq|</select>\n|.
      qq|$tr{send_ocr}<select name="uploadocr">\n|;

    my $count = 0; # compose all ocr definitions
    foreach my $def (@{DefsByName(DEF_OCR)}) {
      $print .= qq|<option value=$count>$def</option>\n|;
      $count++;
    }

    my $name = GO_UPLOAD;
    $print .= qq|<option value=27>$tr{ocr_excl}</option>\n|.
      qq|</select>\n|.
      qq|<input type="submit" onClick="setEnctype('multipart/form-data');"|.
      qq|name="$name" value="$tr{send_file}">\n|.
      qq|</div>\n|;
  }

  # the 'choose action' dropdown choices
  my @act = (""); # no action
  my @mes = ($tr{choose_action}); # msg for no action
  if ($val{user_addnew}!=0) {
    push @act, "newdoc";
    push @mes,$tr{upload_doc};
    push @act, "copy";
    push @mes,$tr{copy};
    push @act,"delete";
    push @mes,$tr{delete_row};
    push @act,"createpdfs";
    push @mes,$tr{createpdfs};
  }
  if ($usp{publishfield} ne "") {
    push @act,"publish","unpublish";
    push @mes,$tr{publish},$tr{unpublish};
  }
  if ($usp{exportallowed} ne "") {
    push @act,"export";
    push @mes,$tr{export};
  }
  if ($val{user_addnew}!=0) {
    my $count = 0; # compose all ocr definitions
    foreach my $def (@{DefsByName(DEF_SCAN)}) {
      push @act,"scan!$count!$def";
      push @mes,$tr{scan}.qq{&nbsp;[$def]};
      $count++;
    }
    push @act,"combine";
    push @mes,$tr{combine};
  }

  # the 'choose action' controls
  $print .= qq{<div id="extactions">};
  if ($usp{publishfield} eq "") {
    $print .= displayExtActions(ACTION,$usp{editAction},\@act,\@mes,3);
  } else {
    $print .= displayExtActions(ACTION,$usp{editAction},\@act,\@mes,1);
    @act = ("[ALL]",$val{user});
    @mes = ($tr{all_users},$val{user});
    if ($val{user_groups} ne "") {
      push @act,split /,/,$val{user_groups};
      push @mes,split /,/,$val{user_groups};
    }
    $print .= displayExtActions(OWNER,$usp{editOwner},\@act,\@mes,2);
  }
  $print .= "</div>";

  return \$print;
}



=head1 $html=MainPrintExtEditPage()

Return extended edit actions html for page view

=cut

sub MainPrintExtEditPage {
  my @act = (""); # no action
  my @mes = ($tr{choose_action}); # msg for no action
  push @act,"deletepage";
  push @mes,$tr{delete_page};
  push @act,"savepage";
  push @mes,$tr{save_page};
  my $count = 0; # compose all ocr definitions
  foreach my $def (@{DefsByName(DEF_OCR)}) {
    push @act,"ocrpage!$count!$def";
    push @mes,$tr{ocr}.qq{&nbsp;[$def]};
    $count++;
  }
  push @act,"ocrdone","ocrexclude","ocrselectdoc","ocrselectall","ocrrecpage";
  my $ocr = $tr{ocr}."&nbsp;";
  push @mes,$ocr.qq{[$tr{ocr_done}]},
            $ocr.qq{[$tr{ocr_excl}]},
            $ocr.qq{[$tr{ocr_doc}]},
            $ocr.qq{[$tr{ocr_sel}]},
            qq{$tr{ocrpage}};

  my $html = qq{<div id="extactions2">}
    . displayExtActions(ACTION2,$usp{editAction},\@act,\@mes)
    . "</div>\n";
	return \$html;
}



=head1 $html=displayExtActions($name,$old,\@act,\@mes)

Utility to compose html fragment for extended actions

=cut

sub displayExtActions {
  my $name = shift;
  my $old = shift;
  my $pact = shift;
  my $pmes = shift;
  my $opt = shift;
  my $print = "";
  $print .= qq{<select name="$name" id="select_$name"};
  $print .= qq{ onChange="changeExtActions()"} if $val{view} eq MAIN;
  if ($usp{editAction} ne "publish" && $name eq OWNER) {
    $print .= qq{ disabled};
  }
  $print .= qq{>\n};
  for (my $count=0;$count<@$pact;$count++) {
    $print .= qq{<option value="$$pact[$count]"};
    #$print .= qq{ selected} if $old eq $$pact[$count];
    $print .= qq{>$$pmes[$count]</option>\n};
  }
  $print .= qq{</select>\n};
  if ($opt!=1) {
    $name = ACTION if $name eq OWNER;
    my $mode = 0;
    my $ask_proceed = $tr{ask_proceed};
    my $doc_choose = $tr{doc_choose};
    my $exportdb = $tr{exportdb};
    $mode = 1 if $val{view} eq MAIN;
    $print .= qq{<input type="submit" id="doit" name="}.GO.qq{$name" }.
              qq{onClick="return GRT.checkConfirm('$mode','$ask_proceed',}.
              qq{'$doc_choose','$exportdb')" value="}.
              OK.qq{"></td>\n};
  }
  return $print;
}



=head1 MainPrintFieldFormat($pval,$type)

Format Date and Yes/No fields

=cut

sub MainPrintFieldFormat {
  my $pval = shift;
  my $type = shift;
  if ($type eq TYPE_DATE) {
    FormatDate($pval);
  } elsif ($type eq TYPE_YESNO) {
    FormatYesNo($pval);
  } else {
    $$pval =~ s/\&/&amp;/g;
    $$pval =~ s/\"/&quot;/g; 
    $$pval =~ s/\</&lt;/g;
    $$pval =~ s/\>/&gt;/g;
  }
}



=head1 $html=MainPrintDetailReiter($value,$src)

Prints out the input command for view/search/edit mode

=cut

sub MainPrintDetailReiter {
  my $id = shift;
  my $name = shift;
  my $text = shift;

  my ($value,$title) = MainLabelSplitFirstKlammer($tr{$text});

  my $html = qq(<a href="#" id="$id" name="$name" )
    . qq(alt="$value" title="$title">$value</a>\n);
	return $html;
}



=head1 ($label,$functionkey)=MainLabelSplitFirstKlammer($label)

Split a label according the first klammer (

=cut

sub MainLabelSplitFirstKlammer {
  my $label = shift;
  my ($label1,$title) = split(/\s\(/,$label);
  $title =~ s/\)//;
  return ($label1,$title);
}



=head1 $htmlpart = MainPrintDetailDoc(state)

Print out the detail form part (without reiter)

=cut

sub MainPrintDetailDoc {
  my $state = shift;

  # loop thru all fields, output html input or span for each
  my $print = '';
  my $pos = 0;
  foreach my $pfield (@{$val{fields}}) {
    my $hide = $pfield->{hide};
    my $name = $pfield->{name};
    if (($pfield->{avtype}==AV_MULTI && $hide==1) || $hide==0 ||
		     $name eq "Notiz" ||
         $name eq "Ordner" || ($name eq "Eigentuemer" && $usp{hideowner}==0)) {
      $print .= MainPrintDetailDocField($pfield,$pos,$state);
    }
    $pos++;

    # pretend the fulltext box is in val{fields} if searching
    if ($pos==5 && $state eq SEARCH && $usp{fulltextengine}>0) {
      my $ftfield = {
        label => $tr{fulltext},
        type  => TYPE_FULLTEXT,
        name  => FULLTEXT,
        width => 36*4,
      };
      $print .= MainPrintDetailDocField($ftfield,$pos,$state);
      $pos++;
    }
  }

  # add extra controls or fulltext, depending on state
  if ($state eq SEARCH) {
    $print .= MainPrintDetailSearchOptions();
  }
  elsif ($state eq EDIT) {
    $print .= MainPrintDetailEditOptions();  
  }
  # only for VIEW
  elsif($usp{sqlfulltext} ne "" || $usp{showocr}==1) {
    $print .= qq(<tr id="Detail_view_Treffer_row">)
    . qq(<td class="DetailHeader TopLine">$tr{fields_Treffer}</td>)
    . qq(<td class="TopLine" id="Detail_view_Treffer" colspan="4"></td></tr>)
    . qq{<tr><td class="TopLine FullText" colspan="4" id="Detail_view_FullText">}
    . qq{</td></tr>};
  }

  return \$print;
}




=head1 FormatText($ptext)

Return the formatted hightlighted OCR text

=cut

sub FormatText {
  my $ptext = shift;
  my $volltext = $usp{sqlfulltext};
	if ($usp{fulltextengine}==2) {
    $volltext =~ s/(\&)//g;
    $volltext =~ s/(\|)//g;
		$volltext =~ s/(\s+)/ /g;
	}
  my ($st,$lcstart,$lcend,$BACK,$FORWARD);
  my ($forw,$back,$cstart,$cend) = FormatTextLinks();
  $$ptext =~ tr/\000//; # remove all reserved chars
  $$ptext =~ tr/\001//;
  $$ptext =~ s/</&lt;/g;
  $$ptext =~ s/>/&gt;/g;
  $$ptext =~ s/\t/ /g;
  if ($volltext =~ /\"/) {
     # Exact compare (Text 1:1)
    $volltext =~ s/\"//g;
    FormatTextDoIt($ptext,$volltext,"");
  } else {
    my @volltext = split / /, $volltext;
    foreach $st (@volltext) {
       my $opt = "";
       if ($st =~ /\*$/) {
        $st =~ s/\*//;
        $opt = '.*?';
       } 
       $st =~ s/[\*\(\+\-\)]//g;
       FormatTextDoIt($ptext,$st,$opt);
    }
  }
  $$ptext =~ s/\n/<br>/g;
  $lcstart = $cstart;
  my $COUNT = 1;
  while ($$ptext =~ /(\000)/) {
    $lcstart = $cstart;
    $BACK = $COUNT - 1;
    if ($BACK > 0) {
       $lcstart =~ s/\[BACK\]/#$BACK/;
    } else {
      $lcstart = "<a name=$COUNT></a><b>";
       $lcstart = $lcstart.$back if $back ne "";
    }
    $lcstart =~ s/\[COUNT\]/$COUNT/;
    $$ptext =~ s/(\000)/$lcstart/;
    $COUNT++;
  }
  my $TOTAL = $COUNT - 1;
  $COUNT = 1;
  while ($$ptext =~ /(\001)/) {
    $lcend = $cend;
    $FORWARD = $COUNT + 1;
    if ($COUNT == $TOTAL) {
      $lcend = "<a name=$COUNT></a></b>";
      $lcend = $lcend.$forw if $forw ne "";
    } else {
      $lcend =~ s/\[FORWARD\]/\#$FORWARD/;
    }
    $$ptext =~ s/(\001)/$lcend/;
    $COUNT++;
   }  
  return $$ptext;
}






=head1 ($forw,$back,$cstart,$cend)=FormatTextLinks()

Give back the base html fragments for the lins for fulltext navigation

=cut

sub FormatTextLinks {
  my $cgi_dir = CGIDIR.CGIPRG;
  my $www_dir = WWWDIR;
  my $imgb = "$www_dir/pics/ft_back.gif";
  my $imgf = "$www_dir/pics/ft_next.gif";
  my $forw = "";
  my $back = "";
  if ($val{sqlposrel}>0) {
    my $sel = $val{sqlstart}+$val{sqlposrel}-1;
    my $sdoc = $val{rows}->[$val{sqlposrel}-1][0];
    my $spage = ${$val{fulltext_max}}[$val{sqlposrel}-1];
    $back = GO_SELECT."_".$sel."_".$sdoc."_".$spage."_";
    $back = qq(<input type="image" src="$imgb" ) .
            qq(style="{border: none;}" name="$back">);
  }
  if ($val{sqlposrel}+1<$val{sqllimit}) {
    my $sel = $val{sqlstart}+$val{sqlposrel}+1;
    my $edoc = $val{rows}->[$val{sqlposrel}+1][0];
    my $epage = ${$val{fulltext_min}}[$val{sqlposrel}+1];
    $forw = GO_SELECT."_".$sel."_".$edoc."_".$epage."_";
    $forw = qq(<input type="image" src="$imgf" ) .
            qq(style="{border: none;}" name="$forw">);
  }
  my $cstart = qq{<a name="[COUNT]"></a>};
  $cstart .= qq{<a href="[BACK]">};
  $cstart .= qq{<img src="$www_dir/pics/ft_back.gif" border="0">};
  $cstart .= qq{</a>};
  $cstart .= qq{<font class="Volltext"><b>};
  my $cend = qq{</b></font>};
  $cend .= qq{<a href="[FORWARD]">};
  $cend .= qq{<img src="$www_dir/pics/ft_next.gif" border="0">};
  $cend .= qq{</a>};
  return ($forw,$back,$cstart,$cend);
}

 




=head1 FormatTextDoIt($pt,$treffer,$cstart,$cend)

Helper function for format the OCR text for UC/LC

=cut

sub FormatTextDoIt {
  my ($pt,$treffer,$opt) = @_;
  FormatTextRegEx($pt,$treffer,$opt);
  FormatTextRegEx($pt,ucfirst($treffer),$opt);
  FormatTextRegEx($pt,uc($treffer),$opt);
  FormatTextRegEx($pt,lc($treffer),$opt);
}






=head1 FormatTextRegEx($pt,$treffer)

Regex function to format OCR text

=cut

sub FormatTextRegEx {
  my ($pt,$treffer,$opt) = @_;
  # Code vor Treffer
  my $cstart = "\000";
  # Code nach Treffer
  my $cend = "\001";
  # Code einbauen -> Trennzeichen in character class
  # irgendwo im Text
  $treffer =~ s/\[/\\[/g;
  $treffer =~ s/\]/\\]/g;
  if ($opt ne "") {
    $$pt =~ s/([\s,\.\)\(:!\?;\"'\-\/\<\>])+($treffer)($opt)([\s,\.\)\(:!\?;\"'\-\/\<\>])/$1${cstart}$2$3${cend}$4/gi;
  } else {
    $$pt =~ s/([\s,\.\)\(:!\?;\"'\-\/\<\>])+($treffer)([\s,\.\)\(:!\?;\"'\-\/\<\>])/$1${cstart}$2${cend}$3/gi;
  }
  # Treffer am Anfang
  $$pt =~ s/^($treffer)([\s,\.\)\(:!\?;\"'\-\/\<\>])/${cstart}$1${cend}$2/gi;
  # Treffer am Ende
  $$pt =~ s/([\s,\.\)\(:!\?;\"'\-\/\<\>])+($treffer)$/$1${cstart}$2${cend}/gi;
}






=head1 $htmlpart=MainPrintDetailDocField($pfield,$pos,$state)

Give back html part for one field

=cut

sub MainPrintDetailDocField {
  my $pfield = shift;
  my $pos = shift;
  my $state = shift;

  my $lbl = $pfield->{label};
  my $name = $pfield->{name};

  my $text = '';
  if ($state eq SEARCH || ($state eq EDIT && $pfield->{edit}==1) ) {
    $text = MainPrintDetailAjax($pfield,$state);
  } else {
    $text = q{<span id="Detail_} . $state . '_' . $name . q{"></span>};
  }

  my $print = "";  

  my $cols=2;
  $cols=1 if $state eq EDIT;
  $cols=2 if $name eq "Titel";

	my $css = "DetailHeader";
	#$css.="View" if $state eq VIEW;

  my $empty = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".
	            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".
	            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
  if ($pos==0) {
    $print .= qq(<tr>) .
              qq(<td class="$css">$lbl</td>) .
              qq(<td nowrap colspan="2">) . $text;
  } elsif ($pos<4) {
    $print .= qq(<span class="$css">$lbl</span>) . $text;
  } elsif ($pos==4) {
    $print .= qq(<span class="$css">$lbl</span>) . $text . '</td>';
		$print .= qq{<td width="150px">$empty</td>} if $state eq VIEW;
		$print .= '</tr>';
	} elsif ($name eq "Notiz") {
    $print .= qq(<tr>) .
              qq(<td class="$css">$lbl</td>) .
              qq(<td colspan="2">) . $text;
		$print .= '</tr>';
  } else {
    $print .= qq(<tr>) .
              qq(<td class="$css">$lbl</td>) .
              qq(<td nowrap colspan="$cols">) . $text . '</td>';
		$print .= qq{<td width="150px">&nbsp;</td>} if $state eq VIEW;
		$print .= '</tr>';
  }

  return $print;
}






=head1 $htmlpart=MainPrintDetailEditOptions()

Print out special html part in edit mode

=cut

sub MainPrintDetailEditOptions {
  my $ok = $tr{save};
  my $cmd = GO_UPDATE;
  my $print .= qq{\n<tr><td colspan=2>&nbsp;</td><td></tr>};
  $print .= qq{\n<tr><td colspan=2>&nbsp;</td><td>};
  my ($ok1,$title) = MainLabelSplitFirstKlammer($ok);
  $print .= qq{<input type="button" name="$cmd" value="$ok1" };
	$print .= qq{onClick="GRT.updateDoc()" title="$title">};
  $print .= qq{</td></tr>\n};
  return $print;
}






=head1 $htmlpart=MainPrintDetailSearchOptions()

Print out the special html part in search mode

=cut

sub MainPrintDetailSearchOptions {
  my $tq = $tr{type_of_query};
  my $tqnew = $tr{new};
  my $tqor = $tr{erw};
  my $tqand = $tr{ein};
  my $jbeg = $tr{search_joker_begin};
  my $jend = $tr{search_joker_end};
  my $ok = $tr{search};
  my $cmd = GO_QUERY;
  my $mode = $val{searchmode};
  $mode = SRCH_NEW if $mode eq "";
  my $tr = "\n<tr>";
  my $print = qq{\n<tr><td class="DetailHeader"><b>$tq</b>};
  $print .= "</td><td>";
  $print .= MainPrintDetailOption(SRCH,$tqnew,SRCH_NEW,$mode);
  $print .= MainPrintDetailOption(SRCH,$tqor,SRCH_OR,$mode);
  $print .= MainPrintDetailOption(SRCH,$tqand,SRCH_AND,$mode);
  $print .= "</td></tr>\n";
  $print .= "\n<tr><td>&nbsp;</td><td>";
  $print .= MainPrintDetailCheck(JOKERSTART,$jbeg,$val{jokerstart},1);
  $print .= MainPrintDetailCheck(JOKEREND,$jend,$val{jokerend},1);
  $print .= "&nbsp;" x 10;
  my ($ok1,$title) = MainLabelSplitFirstKlammer($ok);
  $print .= qq{<input id="search" type="submit" name="$cmd" }.
            qq{title="$title" value="$ok1">};
  $print .= qq{</td></tr>\n};
  return $print;
}





=head1 $htmlpart=MainPrintDetailOption()

Print out radio option box

=cut

sub MainPrintDetailOption {
  my $name = shift;
  my $label = shift;
  my $val = shift;
  my $check = shift;
  my $print = qq{<input type="radio" name="$name" value="$val" };
  $print .= "checked " if $check eq $val;
  $print .= qq{class="noBorder">&nbsp;$label&nbsp;&nbsp;};
  return $print;
}






=head1 $htmlpart=MainPrintDetailCheck($name,$label,$val,$def)

Print out check box 

=cut

sub MainPrintDetailCheck {
  my $name = shift;
  my $label = shift; 
  my $val = shift;
  my $def = shift;
  $val=$def if $val eq "";
  my $print = qq{<input style="border-width: 0px;" type="checkbox" } .
              qq{name="$name" value="$val"};
  $print .= " checked" if $val==$def;
  $print .= ">&nbsp;$label&nbsp;&nbsp;";
  return $print;
} 






=head1 $htmlpart=MainPrintDetailDocAjaxInit

Print out css style part for ajax input boxes

=cut

sub MainPrintDetailDocAjaxInit {
  my $col = "#d1ddba";
  $col = "#ffc5ad" if $val{state} eq EDIT;
  my $print = qq(\n<style>\n) .
    qq(div.auto_complete { margin-top: 4px; width: 200px; ).
    qq(background: #fff; }\n) .
    qq(div.auto_complete ul {border:1px solid #888; margin:0; ) .
           qq(padding:0; width:100%; list-style-type:none; }\n) .
    qq(div.auto_complete ul li { margin:0; padding:1px; }\n) .
    qq(div.auto_complete ul li.selected { background-color: $col; }\n) .
    qq(div.auto_complete ul strong.highlight { color: #800; ) .
           qq(margin:0; padding:0; }\n) .
    qq(</style>\n);
  return $print;
}





=head1 $htmlpart=MainPrintDetailAjax

Print out html part for ajax input fields

=cut

sub MainPrintDetailAjax {
  my $pfield = shift;
  my $state = shift;
  my $val = '';

  my $avtype = $pfield->{avtype};
  my $type = $pfield->{type};
  my $width = int ($pfield->{width})/4;
  my $field = $pfield->{name};

  # we have to make these unique
  my $name = $state . '_' . $pfield->{name};
  my $linked = '';
  if(length $pfield->{linked}){
    $linked = $state . '_' . $pfield->{linked};
  }

  my $print = "";
  my @vals = ();
  if ($type eq TYPE_YESNO) {
    my $j = 1;
    FormatYesNo(\$j);
    push @vals,$j;
    my $n = 0;
    FormatYesNo(\$n);
    push @vals,$n;
    FormatYesNo(\$val) if $val ne "";
    $print = MainPrintDetailAjaxLocal($field,$val,\@vals,$width,3,$state);
  }

  elsif ($avtype > AV_NORMAL || $field eq "Eigentuemer"
    || $field eq $usp{publishfield}) {

    my $www = WWWDIR;
    my $width1 = $width-5;
    my $msg = $tr{dropdown};
    my $prg = CGIDIR.CGIPRG;

    $print .= qq|<input autocomplete="off" id="Detail_$name" |.
      qq|name="fld_$name" size="$width1" type="text" value="$val" |.
      qq|onBlur="checkField('$prg','$name','$avtype','$linked')">\n|.
      qq|<button tabindex="200" name="drp_$name" type="button" |.
      qq|class="DropDown" onClick="searchEntries('$name','$msg')">|.
      qq|<img src="$www/pics/dropdown1.png"></button>\n|.
      qq|<div class="auto_complete" id="complete_$name"></div>\n|.
      qq|<script type="text/javascript">\n|.
      qq|new Ajax.Autocompleter('Detail_$name','complete_$name','$prg',|.
      qq|{parameters:"type=$avtype",callback:autocompleteLinked.bind(this,|.
      qq|'$linked')})\n|.
      qq|</script>\n|;
      
    if ($state eq EDIT && $field ne "Eigentuemer" && 
        $field ne $usp{publishfield}) {
      $print .= MainPrintDetailAjaxEntries($pfield,$state);
    }
  } elsif ($type eq TYPE_TEXT) {
    # read-only fields
    my $fld = "fld_";
    $fld = "" if $type eq TYPE_FULLTEXT;
    $print .= qq{<textarea rows="3" id="Detail_$name" name="$fld$name" }.
              qq{cols="55">}.$val."</textarea>";
  } else {
    # read-only fields
    my $fld = "fld_";
    $fld = "" if $type eq TYPE_FULLTEXT;
    $print .= qq{<input id="Detail_$name" name="$fld$name" }.
              qq{size="$width" value="$val" type="text">};
  }

  return $print;
}






=head1 $htmlpart = MainPrintDetailAjaxLocal($field,$val,$pvals,$width,$fakt)

Create a local autocompleter field

=cut

sub MainPrintDetailAjaxLocal {
  my $field = shift;
  my $val = shift;
  my $pvals = shift;
  my $width = shift;
  my $fakt = shift;
	my $state = shift;
  $width=$width*$fakt if ($fakt>0 and $fakt<5);
  my $print = qq{\n<input id="Detail_$state}.'_'.qq{$field" autocomplete="off" } .
    qq{size="$width" type="text" name="fld_$state}.'_'.qq{$field" value="$val" /> } .
    qq{<div class="auto_complete" id="complete_$state}.'_'.qq{$field" } .
    qq{style="display:none"></div>} .
    qq{<script type="text/javascript">} .
    qq{new Autocompleter.Local('Detail_$state}.'_'.qq{$field','complete_$state}.'_'.qq{$field',[};
  my $print1 = "";
  foreach (@$pvals) {
    $print1 .= "," if $print1 ne "";
    $print1 .= "'$_'";
  }
  $print .= qq{$print1], } ."{});</script>\n";
  return $print;  
}






=head1 MainPrintDetailAjaxEntries($pfield,$state)

Return the html string code of the input field to add values into a selection

=cut

sub MainPrintDetailAjaxEntries {
  my $pfield = shift;
	my $state = shift;

  my $string = '';
  my $width="100px";
  my $cgi = CGIDIR.CGIPRG;
  my $type=$pfield->{avtype};

  my $edit=1;
  getFieldEdit(\$edit,$pfield->{adduser}); # add value rights for field?

  if ($edit && $type>=AV_NORMAL && $state eq EDIT) {

    my $link = $pfield->{linked};
    my $name = $pfield->{name};
    my $lang = $usp{lang};
    my $show = "visible";

    if ($type == AV_DEFINITION) {
      foreach my $pf1 (@{$val{fields}}) {
        if ($pf1->{linked} eq $name && 
            $pf1->{avtype} != AV_1TON && $pf1->{avtype} != AV_MULTI) {
          $show = "hidden";
          last;
        }
      }
    }

    my $ask = $tr{delete_ask};
    $string = qq|</td>\n|.
      qq|<td><a href="#" tabindex="201" |.
      qq|onclick="showHide('$name','$type','$link','hidden')">&lt;</a>\n|.
      qq|<a href="#" tabindex="202" onclick="deleteValue('$cgi',|.
      qq|'$name','$link','$type','$ask')">x</a>\n|.
      qq|<a href="#" tabindex="203" onclick="showHide('$name',|.
      qq|'$type','$link','visible')">&gt;</a>\n|.
      qq|<input tabindex="204" type="text" name="list_$name" value="" |.
      qq|style="width:$width; visibility:hidden">\n|.
      qq|<input tabindex="205" type="button" |.
      qq|name="list_$name.Button" value="Add" |.
      qq|onClick="addValue('$cgi','$name','$link','$type')" |.
      qq|style="visibility:hidden">\n|.
      qq|&nbsp;\n|;
  }

  return $string;
}



=head1 processExtEditActions()

This method processes the extended edit actions

=cut

sub processExtEditActions {
  my $action = shift;
  my @lst = split /!/,$action;
  $usp{editAction}=$action;
  if ($action eq "delete" || $action eq "publish" || $action eq "unpublish") {
    foreach my $doc (split /,/,$val{seldocs}) {
      if ($action eq "delete") {
        deleteAkte($doc);
      } else {
        publishAkte($doc,$action);
      }
    }
    $val{seldocs}=""; # not longer selected (are processed)
    MainSelection(0) if $usp{sqlpos}==-2; # new query if deleted docs
  } elsif ($action eq "deletepage") {
	  my $doc = $val{docnr};
		my $page = $val{docpage};
		$doc = $usp{doc} if $doc<=0;
		$page = $usp{page} if $page<=0;
    deletePage($doc,$page,1);
  } elsif ($action eq "savepage") {
    savePageWithSettings($usp{doc},$usp{page});
  } elsif ($action eq "combine") {
    combineDocuments();
  } elsif ($action eq "export") {
    exportDocs();
  } elsif ($action eq "mail") {
    mailDocs();
  } elsif ($action eq "copy") {
    MainCopy();
  } else {
    if ($lst[0] eq "scan") {
      my $firstSelectedDocument;
      if ( length( $val{seldocs} ) > 0 ) {
        my @selectedDocuments = split /,/, $val{seldocs};
        $firstSelectedDocument = shift @selectedDocuments;
      }
      $lst[2]=$lst[1] if $lst[2] eq ""; # no scan def name, use scan def nbr
      saveJob($lst[2],$firstSelectedDocument,$lst[0]);
    } elsif ($lst[0] eq "upload") {
      saveJob(0,0,$lst[0]);
    } elsif ($lst[0] eq "ocrpage") {
      saveOCRDefPage($lst[1],$usp{doc},$usp{page});
    } elsif ($lst[0] eq "ocrdone") {
      saveOCRDefPage(OCR_DONE,$usp{doc},$usp{page});
    } elsif ($lst[0] eq "ocrexclude") {
      saveOCRDefPage(OCR_EXCLUDE,$usp{doc},$usp{page});
    } elsif ($lst[0] eq "ocrselectdoc" || $lst[0] eq "ocrselectall") {
      saveOCRDefSelect($lst[0],$usp{doc},$usp{page});
    } elsif ($lst[0] eq "ocrrecpage") {
      saveJob(0,0,"OCRRECPAGE");
		}
  }
}



=head1 getUserAVStart()

Return the AVSTART string for a specific user

=cut

sub getUserAVStart {
  my $var="";
  if ($val{user_sqlnew}>0) { # the user has an avstart definition
    my $sql = "SELECT Inhalt from parameter where " .
              "Laufnummer=$val{user_sqlnew}";
    $var = getSQLOneValue($sql);
  }
  if ($var eq "") { # use the default because we don't did find any def
    my $sql = "SELECT Inhalt from parameter where " .
           "Art='SQL' AND Name='AVSTART' AND Tabelle='archiv'";
    $var = getSQLOneValue($sql);
  }
  $var="Laufnummer>0 order by Datum desc,Laufnummer desc" if $var eq ""; # def
  if ($var =~ /(\[)(.*?)(\})/) { # check for current user in avstart
    my $var1 = lc($2); # If found '%[VARIABLE}%'
    $var =~ s/(\[.*?\})/$val{user}/ if $var1 eq "user";
  }
  return $var;
}






=head1 getUserWorkflow()

Return the workflow SQL definition for a specific workflow id

=cut

sub getUserWorkflow {
  my $sql = "SELECT Inhalt,Volltext FROM workflow " .
            "WHERE Laufnummer=$val{workflow}";
  my ($inhalt,$fulltext) = getSQLOneRow($sql);
  if ( length($fulltext) > 0 ) {
    $inhalt =~ s/(SELECT.*?FROM archiv)(.*)/$1,archivseiten$2/;
    $inhalt =~
s/(SELECT.*?WHERE\s)(.*)/$1MATCH archivseiten.Text AGAINST ('$fulltext' IN BOOLEAN MODE) $2/;
  }
  return $inhalt;
}






=head1 dbhOpen($global)

Give back a dbh handler. Open either a normal dbh, or a global one ($global==1)

=cut

sub dbhOpen {
  my $global=shift;
  my ($host,$db,$user,$pw);
  my $port = MYSQL_PORT;
  if ($global==1) {
    $host=avdb_host();
    $db=avdb_db();
    $user=avdb_uid();
    $pw=avdb_pwd();
  } else {
    $host=$val{host};
    $db=$val{db};
    $user=$val{user},
    $pw=$val{pw};
  } 
  my $dbh = undef;
  if ($db ne "" && $host ne "" && $user ne "") {
    my $dsn = "DBI:mysql:host=$host;database=$db;port=$port";
    $dbh = DBI->connect($dsn,$user,$pw,{PrintError=>1,RaiseError=>0});
  }
  return $dbh;
}






=head1 HostIsSlave()

Returns true if the slave running status is 'Yes'

=cut

sub HostIsSlave {
  my $hostIsSlave = 0;
  # check the session connection
  my @row = getSQLOneRow("SHOW SLAVE STATUS",$val{dbh2});
  $hostIsSlave = 1 if $row[9] eq 'Yes';
  @row = getSQLOneRow("SHOW VARIABLES LIKE 'server%'");
  $hostIsSlave = 1 if $row[1]>1;; # check the user connection
  return $hostIsSlave;
}






=head1 FormatDate($pdate)

Returns a formatted date string (dd.mm.yyyy or mm/dd/yyyy)

=cut

sub FormatDate {
  my $pdate = shift;
  $$pdate =~ /(\d{4})(-)(\d{2})(-)(\d{2})/;
  if ($usp{lang} eq LANG_DE) {
    $$pdate = "$5.$3.$1";
  } elsif ($usp{lang} eq LANG_FR || $usp{lang} eq LANG_IT) {
    $$pdate = "$5/$3/$1";
  } else {
    $$pdate = "$3/$5/$1";
  }
}






=head1 getEigentuemerZusatz()

This method creates the owner addition to add to all sql strings in order to
display the right documents
  
=cut

sub getEigentuemerZusatz {
  my $alias = $val{user_groups};
  my $level = $val{user_level};
  my $uid = $val{user};
  my $publishField = $usp{publishfield};
  my $ez;
  if ($level != USER_LEVEL_SYSOP && 
      $level != USER_LEVEL_VIEW_ALL && $level != USER_LEVEL_EDIT_ALL) {
    $ez = " AND (";
    if (length($alias) > 0) {
      if ($alias =~ /,/) {
        my @alias = split /,/, $alias;
        $alias = join "','", @alias;
      }
      $ez .= "Eigentuemer IN ('','$uid','$alias') ";
      if (length($publishField) > 0) {;
        $ez .= "OR $publishField IN ('[ALL]','$uid','$alias')";
      }
    } else {
      $ez .= "Eigentuemer IN ('','$uid') ";
      if (length($publishField) > 0) {
        $ez .= "OR $publishField IN ('[ALL]','$uid')";
      }
    }
    $ez .= ") ";
  }
  $ez .= " AND Archiviert=1 " if OnlyArchiviert();
  return $ez;
}






=head1 getSelfAndAliasOwner()

This method returns an array with all users a specific user has right to see
and edit documents (i.e. it self and all users listed in alias)

=cut

sub getSelfAndAliasOwner {
  my @owners;
  if (($val{user_level}==USER_LEVEL_EDIT_ALL || 
      $val{user_level}==USER_LEVEL_SYSOP) && $val{user_groups} eq "") {
    my $sql = "select User from user group by User";
    my $prows = getSQLAllRows($sql);
    foreach (@$prows) {
      my @row = @$_;
      push @owners,$row[0];
    }
  } else {
    foreach (split /,/, $val{user_groups}) {
      push @owners, $_;
    }
    push @owners,$val{user};
  }
  return \@owners;
}






=head1 DataRequest()
  
Retrieve all POST/GET key=value pairs

=cut

sub DataRequest {
  my $request_method = $ENV{'REQUEST_METHOD'};
  my ($form_input,@pairs,$key,$value,%request,$pairs,$multipart);
  if ($ENV{'REQUEST_METHOD'} eq "GET") {
    $form_input = "$ENV{'QUERY_STRING'}";
  } else {
    $multipart = DataRequestMultipart(\%request);
    read STDIN, $form_input, $ENV{'CONTENT_LENGTH'} if $multipart==0;
  }
  if ($multipart==0) {
    @pairs = split /&/, "$form_input";
    foreach $pairs (@pairs) {
      ($key,$value) = split /=/, $pairs;
      $key =~ tr/+/ /; 
      $key =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;
      $value =~ tr/+/ /; 
      $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;
      if (exists $request{$key}) {
        $request{$key} .= ",$value";
      } else {
        $request{$key} = $value;
      }
    }
  }
  return %request;
}






=head1 $multipart=DataRequestMultipart(\%request)
  
Check if we have a multipart POST request and if so store values

=cut

sub DataRequestMultipart {
  my $prequest = shift;
  my $len  = $ENV {'CONTENT_LENGTH'}; # length of the content (not used)    
  my $cttype = $ENV {'CONTENT_TYPE'}; # get back content type
  my $multipart = 0; # no multi part
  if ($cttype =~ /multipart\/form-data/) { # check for form-data (multipart)
    $multipart = 1;
    my (@blocks,$boundary,$index,$last);
    my $crlf = "\r\n"; # separator in blocks (headers and bodies)
    ($boundary) = $ENV {'CONTENT_TYPE'} =~ /boundary=\"?([^\";,]+)\"?/;
    my $boundary_last = "$boundary--$crlf"; # last one has two -- more
    $boundary .= $crlf; # after a boundary we always find a crlf
    my $boundary_length = length($boundary); # length of the boundary
    my $pos = -1; # starting point is that we did not find anything
    my $start = $boundary_length; # we don't want a match a the beginning
    my $max = (128 * 1024 * 1024)+2048; # max. size of block we get (128 MByte)
    my $input_length = read(STDIN,$$prequest{post},$max); # read the block
    if ($input_length>0) { # we got content
      # somethimes we have some chars before a boundary amd also crlf after it
      my $relativ = index($$prequest{post},$boundary)+length($crlf); 
      while ($index>=0) { # as long as there ar blocks
        $index = index($$prequest{post},$boundary,$start); # next position
        my $till = $index; 
        $till = index($$prequest{post},$boundary_last) if $index<0; # last?
        if ($till>0) { # we got a new block
          $pos++; # adjust position 
          $blocks[$pos]{start} = $start; # start position 
          $blocks[$pos]{length} = $till-$start-$relativ; # length of block
          DataRequestMultipartBlock($prequest,$pos,\@blocks,$crlf);
        }
        $start=$index+$boundary_length; # adjust starting pos for next block
      }
    }
  }
  return $multipart; # (0=no multipart, 1=multipart)
}






=head1 DataRequestMultipartBlock($preq,$pos,$pin,$pbl,$crlf)
  
Save a block in the final plaes (request), if file (fileval/filename)

=cut

sub DataRequestMultipartBlock {
  my ($preq,$pos,$pbl,$crlf) = @_;
  my $header_start = $$pbl[$pos]{start};
  my $header_sep = "$crlf$crlf";
  my $total_length = $$pbl[$pos]{length};
  my $header_end = index($$preq{post},$header_sep,$header_start);
  if ($header_end > 0) {
    my $header = substr($$preq{post},$header_start,$header_end-$header_start);
    my @parts = split($crlf,$header);
    my $vals = $parts[0];
    $vals =~ s/(Content-Disposition:\sform-data;\s)(.*)$/$2/; 
    my @vals = split("; ",$vals);
    my %headervals;
    foreach (@vals) {
      my $line = $_;
      my ($name,$val) = split("=",$line);
      $val =~ s/^(\")(.*?)(\")$/$2/;
      $headervals{$name} = $val;
    }
    my $body_start = $header_end + length($header_sep);
    my $body_length = $total_length - length($header) - length($header_sep);
    if (exists($headervals{filename})) {
      $$preq{filename} = $headervals{filename};      
      $$preq{filestart} = $body_start;
      $$preq{filelength} = $body_length;
    } else {
      $$preq{$headervals{name}} = substr($$preq{post},$body_start,$body_length);
    }
  }
}






=head1 Header()

Return the header for HTML pages

=cut

sub Header {

  my $print = qq|Content-type: text/html; charset=ISO-8859-1\n|;

#FIXME:
# switch charset to utf-8?
# add these as proper http caching headers?
#<meta content="no-cache" http-equiv="Cache-Control">
#<meta content="0" http-equiv="Expires">
#<meta content="no-cache" http-equiv="Pragma">

  # add cookies
	my ($redirect) = @_;
  my $pcookies = $val{cookie};
  if ($#$pcookies >= 0) {
    foreach (@$pcookies) {$print.=$_;}
  }

  # add blank line between headers and content
  $print .= "\n";

  my $www_dir = WWWDIR;
  $print .= qq|<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 |.
    qq|Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">\n|.
    qq|<html>\n|.
    qq|<head>\n|;
    my $css = "avclient"; # check if we send IE6 layout (image left sided)
	  $css .= ".css";
	
	$print .= 
    qq|<link rel="stylesheet" href="$www_dir/css/$css">\n|.
    qq|<link rel="stylesheet" href="$www_dir/css/note.css">\n|.
    qq|<title>Archivista WebClient</title>\n|.
    qq|<script src="$www_dir/js/prototype.js" |.
      qq|type="text/javascript"></script>\n|.
    qq|<script src="$www_dir/js/scriptaculous.js?load=|.
      qq|builder,effects,dragdrop,controls,slider" |.
      qq|type="text/javascript"></script>\n|.
    qq|<script src="$www_dir/js/functions.js" |.
      qq|type="text/javascript"></script>\n|.
    qq|<script src="$www_dir/js/resize.js" |.
      qq|type="text/javascript"></script>\n|.
    qq|<script src="$www_dir/js/note.js" |.
      qq|type="text/javascript"></script>\n|.
    qq|<script src="$www_dir/js/resultTable.js" |.
      qq|type="text/javascript"></script>\n|.
    qq|<script src="$www_dir/js/resizeSibs.js" |.
      qq|type="text/javascript"></script>\n|;
	if ($val{redirect}==1) { # Don't show parameters when login with get
    my $cmd = "$ENV{'QUERY_STRING'}";
		my @cmds = split('&',$cmd);
		my @outs = ();
		foreach (@cmds) {
		  my $part = $_;
		  my ($key,$val) = split('=',$part);
			if ($key ne "uid" && $key ne "host" && $key ne "db" && 
			    $key ne "pwd" && $key ne "redirect") {
			  push @outs,$part;
			}
		}
		my $cmd1 = "";
		$cmd1 .= "?".join('&',@outs) if $outs[0] ne "";
    $print .= qq|<meta http-equiv="refresh" content="0; |.
		          qq|URL=/perl/avclient/index.pl$cmd1">\n|;
	}
	$print .= qq|</head>\n|;
  return $print;
}



=head1 BodyOpen($setFocus,$styles)

Return the HTML body tag

=cut

sub BodyOpen {
  my $setFocus = shift;
  my $styles = shift;
  my $print = qq{<body style="background:#ffffff"};
  $print .= qq{ class="$styles"} if $styles ne "";
  $print .= qq{ $setFocus} if $setFocus ne "";
  $print .= ">";
  return $print;
}






=head1 LoginForm

Displays the HTML login form screen
  
=cut

sub LoginForm {
  LoginFormKeyboard();
  getTranslations($val{lang});
  $val{host} = defaultLoginHost() if length($val{host})==0;
  $val{db} = defaultLoginDb() if length($val{db})==0;
  $val{user} = defaultLoginUser() if length($val{user})==0;
  my $setFocus = qq{onLoad="document.login.host.focus();"};
  my $print = loginMaskHeader($setFocus);
  $print .= qq{<table width="400" border="0" cellpadding="0" cellspacing="0">\n};
  if (!onlyLocalhost()) {
    $print .= qq(<tr><td width="50">&nbsp;</td><td width="100" height="20">$tr{host}</td>);
    $print .= qq(<td><input type="text" name="host" value="$val{host}">);
    $print .= qq{</td></tr>\n};
  } else {
    $print .= qq(<input type="hidden" name="host" value="$val{host}">);
  }
  if (!onlyDefaultDb()) {
    $print .= qq(<tr><td width="50">&nbsp;</td><td width="100" height="20">$tr{database});
    $print .= qq(</td><td><input type="text" name="db" value="$val{db}">);
    $print .= qq{</td></tr>\n};
  } else {
    $print .= qq(<input type="hidden" name="db" value="$val{db}">);
  }
  $print .= qq(<tr><td width="50">&nbsp;</td><td width="100" height="20">$tr{uid}</td><td>);
  $print .= qq(<input type="text" name="user" value="$val{user}"></td></tr>\n);
  $print .= qq(<tr><td width="50">&nbsp;</td><td height="20">$tr{pwd}</td><td>);
  $print .= qq{<input type="password" name="pw"></td></tr>\n};
  $print .= qq(<tr><td width="50">&nbsp;</td><td height="20">$tr{lang}</td><td>);
  $print .= qq{<select name="lang">};
  $print .= qq{<option value="de"};
  $print .= " selected" if ($val{lang} eq "de");
  $print .= qq{>Deutsch</option>};
  $print .= qq{<option value="en"};
  $print .= " selected" if ($val{lang} eq "en");
  $print .= qq{>English</option>};
  $print .= qq{<option value="fr"};
  $print .= " selected" if ($val{lang} eq "fr");
  $print .= qq{>Français</option>};
  $print .= qq{<option value="it"};
  $print .= " selected" if ($val{lang} eq "it");
  $print .= qq{>Italiano</option>};
  $print .= qq{</select>};
  $print .= qq{</td></tr>};
  $print .= qq{<tr><td width="50">&nbsp;</td><td colspan="2" height="35" align="right" };
  $print .= qq(valign="middle" class="Error">$val{error}</td></tr>\n);
  $print .= qq{<tr><td width="100">&nbsp;</td><td colspan="2" align="right"><input };
  $print .= qq{type="submit" value="};
  $print .= $tr{login};
  $print .= qq{"></td></tr>\n};
  $print .= qq{<tr><td width="50">&nbsp;</td><td colspan="2" align="right">&nbsp;</td></tr>\n};
  if (!onlyLocalhost()) {
    $print .= qq{<tr><td width="50">&nbsp;</td><td colspan="2" align="right">};
    $print .= loginStringHost().qq{</td></tr>\n};
  } else {
    $print .= qq{<tr><td width="50">&nbsp;</td><td colspan="2" align="right">};
    $print .= loginStringNoHost().qq{</td></tr>\n};    
  }
  $print .= qq{</table>\n};
  $print .= loginMaskFooter();
	if (-e '/home/cvs/archivista/webclient/perl/checkit') {
    $print .= qq(<div id="bottomline">\n);
	  my $liz = `/home/cvs/archivista/webclient/perl/checkit`;
	  $print .= qq{<center><PRE>$liz</PRE></center></div>};
	} else {
	  die;
	}
  return $print;
}






=head1 LoginFormKeyboard

Read the current keyboard definition from /home/archivista/.xkb-layout

=cut

sub LoginFormKeyboard {
  if ($val{lang} ne "de" && $val{lang} ne "en" && 
      $val{lang} ne "fr" && $val{lang} ne "it") {
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
    $val{lang}="en";
    $val{lang}="de" if index($kb,"de")==0;
    $val{lang}="fr" if index($kb,"fr")==0;
    $val{lang}="it" if index($kb,"it")==0;
  }
}






=head1 newPasswordRequestForm()

Display the form to change the user password after login

=cut

sub newPasswordRequestForm {
  my $lang = $val{lang};
  my $setFocus = qq{onLoad="document.login.newPassword.focus();"};
  my $print = loginMaskHeader($setFocus);
  $print .= qq{<input type="hidden" name="newPasswordCheck" value="1">};
  $print .= qq{<input type="hidden" name="host" value="$val{host}">};
  $print .= qq{<input type="hidden" name="db" value="$val{db}">};
  $print .= qq{<input type="hidden" name="user" value="$val{user}">};
  $print .= qq{<input type="hidden" name="pw" value="$val{pw}">};
  $print .= qq{<input type="hidden" name="lang" value="$lang">};
  $print .= qq{<table width="400px" border="0" cellpadding="0" cellspacing="0">\n};
  $print .= qq{<tr><td width="30px">&nbsp;</td><td height="20" nowrap>};
  $print .= $tr{new_password};
  $print .= qq{&nbsp;&nbsp;&nbsp;</td><td><input type="password" }.
            qq{name="newPassword"></td></tr>\n};
  $print .= qq{<tr><td width="30px">&nbsp;</td><td height="20" nowrap>};
  $print .= $tr{retype_password};
  $print .= qq{</td><td><input type="password" name="retypePassword">};
  $print .= qq{</td></tr>\n};
  $print .= qq{<tr><td colspan="2" height="35" align="right" };
  $print .= qq(valign="middle" class="Error">$val{error}</td></tr>\n);
  $print .= qq{<tr><td width="30px">&nbsp;</td><td colspan="2" align="right">};
  $print .= qq{<input type="submit" value="};
  $print .= $tr{next};
  $print .= qq{"></td></tr>\n};
  $print .= qq{</table>\n};
  $print .= loginMaskFooter();
  return $print;
}






=head1 loginMaskHeader()

Displays the HTML header of the login mask

=cut

sub loginMaskHeader {
  my $setFocus = shift;
  my $www = WWWDIR;
  my $cgi = CGIDIR.CGIPRG;
  my $version = AV_VERSIONTEXT;
  my $name = AV_NAME;
  my $print = BodyOpen($setFocus);
  $print .= qq{<form onSubmit="getScreenSize();" action="$cgi" };
  $print .= qq{method="post" name="login">\n};
  if (!-e '/etc/nologinext.conf') {
    $print .= "<p>";
    $print .= qq|<a href="/index.htm">Home</a>\n|;
    $print .= " - ";
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
  $print .= qq(<div id="centered">\n);
  $print .= qq{<table width="648px" border="0" cellpadding="0" cellspacing="0">\n};
  $print .= qq{<tr><td height="53" background="$www/pics/login_header.png" } .
            qq{colspan="2"></td></tr>\n};
  $print .= qq{<tr><td width="248" height="307" } .
            qq{background="$www/pics/login_left.png">&nbsp;</td>\n};
  $print .= qq{<td><table border="0" cellpadding="0" cellspacing="0" } .
            qq{width="400">\n};
  $print .= qq{<tr><td style="text-align:right" class="Title">$name } .
            qq{WebClient<br>\n};
  $print .= qq{<font class="powered">Version $version - Powered by };
  $print .= qq{<a href="http://www.archivista.ch">Archivista GmbH</a></font>};
  $print .= qq(<br><br></td></tr>\n);
  $print .= qq{<tr><td style="text-align:center" valign="middle">\n};
  return $print;
}






=head1 loginMaskFooter()

Displays the HTML login mask footer

=cut

sub loginMaskFooter {
  my $print = qq{<input type="hidden" name="avversion" value="}.
              getVersion().qq{">};
  $print .= qq{</form></td></tr></table>\n};
  $print .= qq{</td></tr></table>\n};
  $print .= qq(</div></body>\n);
  return $print;
}






=head1 $version=getVersion()

Check if version already exists, if yes give it back, if no, read it

=cut

sub getVersion {
  my $version = $val{avversion};
  if ($version eq "") {
    open(FIN,"/boot/grub/menu.lst");
    my @lines = <FIN>;
    close(FIN);
    my $line = join("",@lines);
    $line =~ /(title)(.*?)([0-9]{8,8})/;
    $version = $3;
  }
  return $version;
}






=head1 saveOCRDefSelect($mode,$documentId)

Update the OCR definition for a document

=cut

sub saveOCRDefSelect {
  my $mode = shift;
  my $documentId = shift;
  my $pageId = shift;
  my @docs;
  if ($mode eq "ocrselectall") {
    # @docs = getDoclist(); # to do
  } else {
    push @docs,$documentId
  }
  my $nr = ($documentId * 1000)+$pageId;
  my $sql="select OCR,Ausschliessen,Erfasst from ".TABLE_PAGES.
          " where Seite=$nr";
  my ($ocr,$excl,$done) = getSQLOneRow($sql);
  foreach (@docs) {
    my $docnr = $_;
    my $sql1 = "select Seiten from archiv where Laufnummer=$docnr";
    my $seiten = getSQLOneValue($sql1);
    for (my $c=1;$c<=$seiten;$c++) {
      if ($excl==1) {
        saveOCRDefPage(OCR_EXCLUDE,$docnr,$c);
      } elsif ($done==1) {
        saveOCRDefPage(OCR_DONE,$docnr,$c);
      } else {
        saveOCRDefPage($ocr,$docnr,$c);
      }
    }
  }
}






=head1 saveOCRDefPage($ocr_id,$documentId,$_pageId)

Update the OCR definition for a page

=cut

sub saveOCRDefPage {
  my $ocr_id = shift;
  my $documentId = shift;
  my $_pageId = shift;
  # Retrieve the nrOfPages for the document
  my $pageId = getPageNumber($documentId,$_pageId);
  my $sql1 = "SELECT Seite from ".TABLE_PAGES." where Seite=$pageId";
  my $p1 = getSQLOneValue($sql1);
  $sql1 = TABLE_PAGES." set ";
  if ($ocr_id==OCR_EXCLUDE) { # no ocr at all
    $sql1 .= "Erfasst=0,Ausschliessen=1";
  } elsif ($ocr_id==OCR_DONE) { # mark ocr as already done
    $sql1 .= "Erfasst=1,Ausschliessen=0";
  } else { # set a net ocr def
    $sql1 .= "OCR=$ocr_id,Erfasst=0,Ausschliessen=0";
  }
  if ($p1==0 && $pageId>0) {
    $sql1 = "INSERT INTO $sql1,Seite=$pageId";
  } else {
    $sql1 = "UPDATE $sql1 WHERE Seite=$pageId";
  }
  SQLUpdate($sql1);
  $val{state} = EDIT;
  $val{view} = PAGE;
}






=head1 $val=getParameterValue($name,$type)

Retrieve a value of a name of parameter table

=cut

sub getParameterValue {
  my $name = shift;
  my $type = shift;
  my $query = "SELECT Inhalt FROM parameter WHERE ";
  if ($type ne "") {
    $type = SQLQuote('%'.$type.'%');
    $query .= "Art like $type and ";
  } else {
    $query .= "Art like 'parameter' and Tabelle like 'parameter' and ";
  }
  $query .= "Name='$name'";
  return getSQLOneValue($query);
}
  





=head1 \@arr = DefsByName($name)

Retrieve the names of an definition (ScannenDefinition,OCRSets)

=cut

sub DefsByName {
  my $name = shift;
  my @Names;
  foreach my $def (split /\r\n/,getParameterValue($name)) {
    my @values = split /;/,$def;
		if ($values[22] eq "" || ($values[18]!=1 && $values[22] ne "")) {
      push @Names, $values[0];
		}
  }
  return \@Names;
}






=head1 deletePage($doc,$page,$adjustglobal)

Delete the current page from the current document

=cut

sub deletePage {
  my $doc = shift;
  my $page = shift;
  my $adjustglobal = shift;
  my ($edit,$pages,$folder,$archived)=lockIfEditable($doc);
  if ($edit==1) {
    if ($page<=$pages && $page>0) {
		  deletePageCheckPDFQuelle($doc,$page,$pages,$folder,$archived);
      my $nr = getPageNumber($doc,$page);
      logDeleted($doc,$page);
      my $end = getPageNumber($doc,$pages);
      SQLUpdate("DELETE FROM ".TABLE_IMAGES." WHERE Seite=$nr");
      SQLUpdate("DELETE FROM ".TABLE_PAGES." WHERE Seite=$nr");
      for (my $c=$nr;$c<$end;$c++) {
        my $c1=$c+1;
        SQLUpdate("update ".TABLE_IMAGES." set Seite=$c where Seite=$c1");
        SQLUpdate("update ".TABLE_PAGES." set Seite=$c where Seite=$c1");
      }
      $pages--;
      SQLUpdate("update archiv set Seiten=$pages where Laufnummer=$doc");
      if ($adjustglobal==1) { # in case we did delete the last page in doc
        $usp{page}-- if $usp{page}>$pages;
      }
    }
    unlockAfterEdit($doc);
  }
  $val{state} = EDIT;
  $val{view} = PAGE;
}



=head1 deletePageCheckPDFQuelle($doc,$page,$pages,$folder,$archived)

Check if we need to remove a pdf pages and/or move source file to second page

=cut

sub deletePageCheckPDFQuelle {
  my ($doc,$page,$pages,$folder,$archived) = @_;
	if ($archived==0 && $pages>1) {
	  my $pfirst = ($doc*1000)+1;
		my $plast = ($doc*1000)+$pages;
		my $sql = "select length(Quelle) from archivbilder where Seite=$plast";
		my ($lang) = getSQLOneRow($sql);
		if ($lang==0) {
		  $sql = "select length(Quelle) from archivbilder where Seite=$pfirst";
		  ($lang) = getSQLOneRow($sql);
			if ($lang>0) {
        my $prow = getBlobFile("Quelle",$pfirst,$folder,$archived);
        my $file0 = writeTempFile(" ");
        $file0 = getTempFile($file0,'.pdf',1);
        my $file1 = writeTempFile(" ");
        $file1 = getTempFile($file1,'.pdf',1);
				writeFile($file1,$$prow[0],1);
				if (-e $file1) {
				  my $from1 = 1;
					my $from2 = $page-1;
					my $to1 = $page+1;
					my $to2 = $pages;
					my $cutting = "";
					$cutting .= "$from1-$from2" if $from2>=$from1;
					if ($to1<=$to2) {
					  $cutting .= " " if $cutting ne "";
						$cutting .= "$to1-$to2";
					}
          my $dopdf="pdftk $file1 cat $cutting output $file0";
					system($dopdf);
					if (-e $file0) {
						my $pcont = getFile2($file0,1);
						$page=2 if $page==1;
						my $pnr = ($doc*1000)+$page;
						$sql = "update archivbilder set Quelle=".SQLQuote($$pcont)." ".
						       "where Seite=$pnr";
						SQLUpdate($sql);
						unlink $file0 if -e $file0;
						unlink $file1 if -e $file1;
					}
				}
			}
		}
		if ($page==1 && $pages>1) {
      my $prow = getBlobFile("BildA",$pfirst,$folder,$archived);
			if (length($$prow[0])>0) {
				my $pnr = ($doc*1000)+2;
				$sql = "update archivbilder set BildA=".SQLQuote($$prow[0])." ".
				       "where Seite=$pnr";
				SQLUpdate($sql);
			}
		}
	}
}



=head1 ($edit,$pages)=lockIfEditable($doc,$dontcheckarch)

Check if in a given doc number we have edit rights

=cut

sub lockIfEditable {
  my $doc = shift;
  my $dontcheckarch = shift;
  my $edit = 0;
  my $sql = "select Laufnummer,Seiten,Archiviert,Gesperrt,Eigentuemer,Ordner ".
            "from archiv where Laufnummer=$doc".getEigentuemerZusatz();
  my ($lnr,$pages,$arch,$locked,$owner,$folder) = getSQLOneRow($sql);
  if ($lnr==$doc && ($arch==0 || $dontcheckarch==1) && $locked==0) {
    $edit = userHasRight($doc,$owner);
    if ($edit==1) {
      $sql = "update archiv set Gesperrt=".SQLQuote($val{user})." ".
             "where Laufnummer=$doc and (Gesperrt='' || Gesperrt is Null)";
      $edit=SQLUpdate($sql);
    }
  }
  return ($edit,$pages,$folder,$arch);
}






=head1 unlockAfterEdit($doc)

After editing a document, unlock it

=cut

sub unlockAfterEdit {
  my $doc = shift;
  my $sql = "update archiv set Gesperrt='' where Laufnummer=$doc";
  SQLUpdate($sql);
}






=head1 getImageContentType($akte)

Give back the appropriate mime type according database entry

=cut

sub getImageContentType {
  my $akte = shift;
  my $sql = "SELECT BildInputExt FROM archiv WHERE Laufnummer=$akte";
  my $imageContentType=getSQLOneValue($sql);
  if ($imageContentType eq "") {
    my $sql = "SELECT BildAExt FROM archiv WHERE Laufnummer=$akte";
    $imageContentType=getSQLOneValue($sql);
  }
  if ($imageContentType eq "PNG") {
    $imageContentType = "png";
  } elsif ($imageContentType eq "JPG") {
    $imageContentType = "jpeg";
  } elsif ($imageContentType eq "TIF") {
    $imageContentType = "tiff";
  }
  return $imageContentType;
}






=head1 scanDefVals($name)

Get a list of all scan definition names

=cut

sub scanDefVals {
  my $name = shift;
  my $id = $name;
  my $scanAll = getParameterValue(SCAN_DEFS);
  my $result = "";
  my @scanDefs = split /\r\n/,$scanAll;
	my @scanOuts = ();
	foreach (@scanDefs) {
	  my $def = $_;
    my @values = split /;/,$def;
		if ($values[22] eq "" || ($values[18]!=1 && $values[22] ne "")) {
      push @scanOuts, $def;
		}
	}
  if ((int $id) eq $name) {
    $result = $scanOuts[$id];
  } else {
    foreach my $def (@scanOuts) {
      # check all definitions for the desired name
      my @values = split /;/, $def;
      $result=$def if ($values[0] eq $name);
    }
  }
  $result = $scanOuts[0] if $result eq ""; # if none, give back first
  return $result;
}







=head1 saveJob($scanDef,$scanDoc)

Executed when saving the action 'scan'. Important is the selected scan
definition and the document id (optional) selected to scan into an already
existing document.

=cut

sub saveJob {
  my $scanDef = shift;
  my $scanDoc = shift;
  my $mode = shift;
  my $scanVals = scanDefVals($scanDef);
   if (saveJobAllowed($scanDoc,$scanVals,$mode)) {
    my $jobtype = "SANE";
    $jobtype = "WEB" if $mode eq "upload";
		$jobtype = "OCRRECPAGE" if $mode eq "OCRRECPAGE";
    my $sql = "INSERT INTO ".DB_JOBS.".";
    my $sql1 = $sql.TABLE_JOBS." SET job='$jobtype',status=110," .
               "host=".SQLQuote($val{host}).",db=".SQLQuote($val{db})."," .
               "user=".SQLQuote($val{user}).",pwd=".SQLQuote($val{pw});
    SQLUpdate($sql1,$val{dbh2});
    my $id = getSQLOneValue(SQL_LASTID,$val{dbh2});
    my $ok = 1;
    $ok = saveJobUploadFile($id) if $mode eq "upload";
    if ($ok) {
      if ( $val{meta}  ne "" ) {
        my @scanvals = split(';',$scanVals);
        $scanvals[27] = "" if $scanvals[27] eq "0"; # '0' is empty!!!
        # We want to add some meta Fields
        $val{meta} =~ s/;/*59*/g; # Don't break scan defs!!!
        my @meta_fields = split(',',$val{meta});
        foreach my $m_field (@meta_fields) {
          my ($key,$value) = split(':',$m_field);
          if ($scanvals[27] ne "" ) {
            # String ends not with ':' ?
            $scanvals[27] .= ":" if $scanvals[27] !~ /:$/;
          }
          $scanvals[27] .= "$key=".fromUTF8($value);
        }
        $scanVals = join(';',@scanvals);
      }
      my $para = getParameterValue("UserExtern01","UserExtern01");
      my @paras = split(";",$para); 
      my $chkuser = $paras[8];
      my $ownuser = $val{user_new};
      $ownuser = $val{user} if $chkuser==1; # set new owner to current user
      $sql1 = $sql.TABLE_JOBSDATA." SET jid=$id,"; # now save scan def/docnr
      my $sql2 = $sql1."param='SCAN_USER',value=".SQLQuote($val{user});
      SQLUpdate($sql2,$val{dbh2});
      if ($mode eq "OCRRECPAGE") {
        $sql2 = $sql1."param='DOC',value=".SQLQuote($usp{doc});
        SQLUpdate($sql2,$val{dbh2});
        $sql2 = $sql1."param='PAGE',value=".SQLQuote($usp{page});
        SQLUpdate($sql2,$val{dbh2});
      }
      if ($ownuser ne "") {
        $sql2 = $sql1."param='SCAN_USER2',value=".SQLQuote($ownuser);
        SQLUpdate($sql2,$val{dbh2});
      }
      if ($scanDoc>0) {
        $sql2 = $sql1."param='SCAN_TO_DOCUMENT',value=".SQLQuote($scanDoc);
        SQLUpdate($sql2,$val{dbh2});
      }
      $sql2 = $sql1."param='SCAN_DEFINITION',value=".SQLQuote($scanVals);
      SQLUpdate($sql2,$val{dbh2});
      if ($mode eq "upload") {
        my @parts = split(/\\/,$val{filename});
			  if (index($val{filename},'/',0)>=0) {
          @parts = split(/\//,$val{filename});
				}
        $val{filename} = pop @parts;
				$val{filename} =~ s/\,/ /g;
				$val{filename} =~ s/\"/ /g;
				$val{filename} =~ s/\'/ /g;
        $sql2 = $sql1."param='WEB_FILE',value=".SQLQuote($val{filename});
        SQLUpdate($sql2,$val{dbh2});
        if ($val{uploaddef} ne "") { # only store nr of def
          $sql2 = $sql1."param='WEB_DEF',value=".SQLQuote($val{uploaddef});
          SQLUpdate($sql2,$val{dbh2});
        } else { # default vals, we don't use a scan def
          $sql2 = $sql1."param='WEB_BITS',value=".SQLQuote($val{uploadbits});
          SQLUpdate($sql2,$val{dbh2});
          $sql2 = $sql1."param='WEB_OCR',value=".SQLQuote($val{uploadocr});
          SQLUpdate($sql2,$val{dbh2});
        }
      }
      $sql = "UPDATE ".DB_JOBS.".".TABLE_JOBS." SET status=100 where id=$id";
      SQLUpdate($sql,$val{dbh2});
    }
    $val{errorint} = $tr{job_working};
  }
}






=head1 $addok=saveJobAllowed($scanDoc,$scanVals)

Check if we want to scan in an existing doc and if so if they have same format

=cut

sub saveJobAllowed {
  my $scanDoc = shift;
  my $scanVals = shift;
  my $mode = shift;
  my $addok=0;
  if ($val{user_addnew}==0) {
    $val{errorint} = $tr{update_right_err};
  } elsif ($scanDoc>0) {
    my $sql = "select ArchivArt,Eigentuemer from archiv ".
              "where Laufnummer=$scanDoc".getEigentuemerZusatz();
    my @row = getSQLOneRow($sql);
    if ( checkArchived($scanDoc) ) {
      $val{errorint} = $tr{archived};
    } else {
      # Document is not archived need to check further
      if ( checkLocked($scanDoc) ) {
        $val{errorint} = $tr{locked};
      }
    }
    if ($val{errorint} eq "") {
      my $archivart = $row[0];
      my $owner = $row[1];
      if (userHasRight($scanDoc,$owner)) { # user has right, check formats
        if ($mode eq 'adddoc') {
          # Nothing for now.
        #} elsif ($mode eq 'scan') {
        } else {
          my @vals = split(";",$scanVals);
          my $scanmode = $vals[1]; # scan mode: 0=lineart, 1=gray, 2=color
          my $swopt = $vals[24]; # black/whit opt (0=off, 1=on)
          if ($archivart==1 && (($scanmode==1 || $scanmode==2) && $swopt==0)) {
            $val{errorint} = $tr{scanadderror}; # error if tiff and gray/color
          } elsif ($archivart==3 && ($scanmode==0 || $swopt==1)) {
            $val{errorint} = $tr{scanadderror}; # error if jpeg and black/white
          }
        }
      } else {
        $val{errorint} = $tr{update_right_err}; # user has no rights anyway
      }
    }
  }
  $addok=1 if $val{errorint} eq "";
  return $addok;
}






=head1 $ok=saveJobUploadFile($id)

Saves the uploaded File into tmp path according log id

=cut

sub saveJobUploadFile {
  my $jobid = shift;
  my $ok = 0;
  my $file = TEMP_PATH."job-$jobid.upl";
  unlink $file if -e $file;
  if (! -e $file) {
    open(FOUT,">$file");
    binmode(FOUT);
    print FOUT substr($val{post},$val{filestart},$val{filelength});
    close(FOUT);
    $val{post}="";
    $ok=1;
  }
  return $ok;
}






=head1 0/1=checkArchived($docnr)

Check if the given Document is archived. 1=> Archived. 0=> not archived

=cut

sub checkArchived {
  my $doc = shift;
  my $sql = "select Archiviert from archiv where Laufnummer=$doc".
            getEigentuemerZusatz();
  my $archived = getSQLOneValue($sql);
  return $archived;
}






=head1 checkLocked($docnr)

Check if the Document is locked. 1=> Locked. 0=> not locked.

=cut

sub checkLocked {
  my $docnr = shift;
  my $sql = "select Gesperrt from archiv where Laufnummer=$docnr".
            getEigentuemerZusatz();
  my $locked = getSQLOneValue($sql);
  if ($locked ne "") {
    return 1;
  } else {
    return 0;
  }
}






=head1 FormatYesNo($pvalue)

Converts 0 to No/Nein and 1 to Yes/Ja for all tinyint fields

=cut

sub FormatYesNo {
  my $pvalue = shift;
  my $out = "No";
  $$pvalue = 1 if $$pvalue eq "Ja";
  $$pvalue = 1 if $$pvalue eq "Yes";
  if ($$pvalue==0) {
    $out="Nein" if $usp{lang} eq LANG_DE;
    $out="Non" if $usp{lang} eq LANG_FR;
    $out="No" if $usp{lang} eq LANG_IT;
  } else {
    $out = "Yes";
    $out="Ja" if $usp{lang} eq LANG_DE;
    $out="Oui" if $usp{lang} eq LANG_FR;
    $out="Si" if $usp{lang} eq LANG_IT;
  }
  $$pvalue = $out;
}






=head1 publishAkte($akte,$publish)

This method can publish or unpublish a specific document for a specific owner

=cut

sub publishAkte {
  my $akte = shift;
  my $publish = shift; # Can be 'publish' or 'unpublish'
  my $user = $val{owner};
  my $doit = 0;
  if ($user eq "") {
    $user="[ALL]" if $publish eq "publish";
    $doit=1;
  } else {
    my $pusers = getSelfAndAliasOwner();
    foreach (@$pusers) {
      if ($_ eq $user) {
        $doit=1;
        last;
      }
    }
  }
  if ($usp{publishfield} ne "") {
    my $query = "UPDATE archiv SET $usp{publishfield}=".SQLQuote($user)." ".
                "WHERE Laufnummer=$akte";
    SQLUpdate($query);
    $usp{editOwner} = $user;;
  }
}






=head1 exportDocs

Export the current sql selection (insert job definition)

=cut

sub exportDocs {
  if ($usp{exportallowed} ne "" && $val{exportdb} ne "") {
    my ($sqlgo,$sqlc,$limit) = MainSelectionInit(0); # get sql without cache
    my @vals = split(";",$usp{exportallowed});
    my $user = $vals[1];
    my $anz = int $vals[2];
    my $userjob = $val{user};
    my $sql = "select User from user group by user";
    my $prows = getSQLAllRows($sql);
    foreach (@$prows) {
      my @row = @$_;
      $userjob = $row[0] if $row[0] eq $user;
    }
    $sql = "INSERT INTO ".DB_JOBS.".";
    my $sql1 = $sql.TABLE_JOBS." SET job='EXPORT',status=110," .
              "host=".SQLQuote($val{host}).",db=".SQLQuote($val{db})."," .
              "user=".SQLQuote($val{user}).",pwd=".SQLQuote($val{pw});
    SQLUpdate($sql1,$val{dbh2});
    my $id = getSQLOneValue(SQL_LASTID,$val{dbh2});
    $sql1 = $sql.TABLE_JOBSDATA." SET jid=$id,"; # now save scan def/docnr
    my $sql2 = $sql1."param='EXPORT_SQL',value=".SQLQuote($sqlgo);
    SQLUpdate($sql2,$val{dbh2});
    $sql2 = $sql1."param='EXPORT_USER',value=".SQLQuote($userjob);
    SQLUpdate($sql2,$val{dbh2});
    $sql2 = $sql1."param='EXPORT_MAX',value=".SQLQuote($anz);
    SQLUpdate($sql2,$val{dbh2});
    $sql2 = $sql1."param='EXPORT_DB',value=".SQLQuote($val{exportdb});
    SQLUpdate($sql2,$val{dbh2});
    $sql = "UPDATE ".DB_JOBS.".".TABLE_JOBS." SET status=100 where id=$id";
    SQLUpdate($sql,$val{dbh2});
  }
}






=head1 mailDocs

Send a document back to mail server

=cut

sub mailDocs {
  return if $val{mailstatus} eq CANCEL; # we said cancel to the action
  $val{selectdoc}=$usp{doc} if $val{selectdoc}==0;
  my $sql = "select EDVName from archiv where Laufnummer=$val{selectdoc}";
  my @row = getSQLOneRow($sql);
  my ($type,$name,$folder) = split(";",$row[0]);
  if ($type eq "mail") {
    $sql = "INSERT INTO ".DB_JOBS.".";
    my $sql1 = $sql.TABLE_JOBS." SET job='MAIL',status=110," .
              "host=".SQLQuote($val{host}).",db=".SQLQuote($val{db})."," .
              "user=".SQLQuote($val{user}).",pwd=".SQLQuote($val{pw});
    SQLUpdate($sql1,$val{dbh2});
    my $id = getSQLOneValue(SQL_LASTID,$val{dbh2});
    $sql1 = $sql.TABLE_JOBSDATA." SET jid=$id,"; # now save scan def/docnr
    my $sql2 = $sql1."param='MAIL_DOC',value=".SQLQuote($val{selectdoc});
    SQLUpdate($sql2,$val{dbh2});
    $sql = "UPDATE ".DB_JOBS.".".TABLE_JOBS." SET status=100 where id=$id";
    SQLUpdate($sql,$val{dbh2});
  }
}






=head1 combineDocuments

Combine documents to one single document

=cut

sub combineDocuments {
  my @docs = sort split(",",$val{seldocs});
  my $doc = $usp{doc};
  if ($val{user_addnew}==1) {
    my ($edit,$pages,$folder,$archived)=lockIfEditable($doc);
    if ($edit==1) {
      my $sql="select ArchivArt from archiv where Laufnummer=$doc";
      my $art = getSQLOneValue($sql);
      $usp{sqlpos}=-2; # we want to have a new selection
      MainAccessLog("combine",$doc,$pages);
			$val{pdfdocs} = $val{seldocs};
			my $file1 = MainPDFS();
      foreach (@docs) {
        my $doc2 = $_;
        if ($doc2 != $doc) {
          my ($edit2,$pages2,$folder,$archived)=lockIfEditable($doc2);
          if ($edit2==1) {
            my $newpages = $pages+$pages2;
            $sql="select ArchivArt from archiv where Laufnummer=$doc2";
            my $art2 = getSQLOneValue($sql);
            my $deleteit = 1; # say we want to delete it
            if ($newpages<=640 && $art==$art2) {
              for (my $page=1;$page<=$pages2;$page++) {
                $pages++;
                my $pagenr = getPageNumber($doc,$pages);
                my $oldnr = getPageNumber($doc2,$page);
                my $sql2 = "set Seite=$pagenr where Seite=$oldnr";
                $sql = "update ".TABLE_IMAGES." $sql2";
                SQLUpdate($sql);
                $sql = "update archivseiten $sql2";
                SQLUpdate($sql);
              }
              $sql="update archiv set Seiten=$pages where Laufnummer=$doc";
              SQLUpdate($sql);
              $sql="update archiv set Seiten=0 where Laufnummer=$doc2";
              SQLUpdate($sql);
            } else {
              $deleteit = 0;
            }
            unlockAfterEdit($doc2);
            deleteAkte($doc2) if $deleteit==1;
          }
        }
      }
			if (-e $file1) {
			  my $pcont = getFile2($file1,1);
				if (length($$pcont)>0) {
          my $sql="select Seiten from archiv where Laufnummer=$doc";
          my $pages = getSQLOneValue($sql);
				  for (my $c=1;$c<=$pages;$c++) {
					  my $nr = ($doc*1000)+$c;
						$sql = "update archivbilder set Quelle='' where Seite=$nr";
						SQLUpdate($sql);
					}
					my $nr = ($doc*1000)+1;
					$sql = "update archivbilder set Quelle=".SQLQuote($$pcont)." ".
					       "where Seite=$nr";
					SQLUpdate($sql);
				}
			}
      unlockAfterEdit($doc);
    }
  }
}






=head1 deleteAkte($doc)

Delete a specific document from the system (also from the filesystem)

=cut

sub deleteAkte {
  my $doc = shift;
  if ($val{user_addnew}==1) {
    my ($edit,$pages,$folder,$archived)=lockIfEditable($doc);
    if ($edit==1) {
      $usp{sqlpos}=-2; # we want to have a new selection
      MainAccessLog(GO_DELETE,$doc,$pages);
      my $sql = "DELETE FROM archiv WHERE Laufnummer=$doc";
      SQLUpdate($sql);
      my $start = getPageNumber($doc);
      my $end = getPageNumber($doc,$pages);
      my $spage = 0;
      $spage = 1 if $pages>0;
      logDeleted($doc,$spage,$pages);
      $sql = "WHERE Seite between $start AND $end";
      SQLUpdate("DELETE FROM ".TABLE_PAGES." $sql");
      SQLUpdate("DELETE FROM ".TABLE_IMAGES." $sql");
    } else {
      $val{errorint} = $tr{locked};
    }
  }
}






=head1 logDeleted

Log the deleted documents or pages

=cut

sub logDeleted {
  my $doc = shift;
  my $pagefrom = shift;
  my $pageto = shift;
  $val{deleted} .= ", " if $val{deleted} ne "";
  $val{deleted} .= $doc."(".$pagefrom if $pagefrom>0;
  $val{deleted} .= "-".$pageto if $pagefrom ne $pageto && $pageto ne "";
  $val{deleted} .= ")" if $pagefrom>0;
}






=head1 getFields($param)

Given a parameter definition from the parameter table, an array of field names
is returned.

=cut

sub getFields {
  my $param = shift;
  my ( @fields, @return );
  undef @fields;
  undef @return;
  # Save the position and the field name
  while ( $param =~ /(.*?)(;.*?;)(.*?)(;.*?;)/g ) {
    push @fields, "$3::$1";
  }
  # We want the array in the same order like the defined position
  foreach ( sort { $a <=> $b } @fields ) {
    my ( $pos, $field ) = split /::/, $_;
    push @return, $field;
  }
  return @return;
}






=head1 userHasRight($akte,$owner)

This method checks the edit and delete rights of a user
It returns 1 if the user has edit/delete rights, 0 else

=cut

sub userHasRight {
  my $akte = shift;
  my $eigentuemer = shift;
  my $hasRight=0;
  if ($val{hostslave}==0) { # if we are not in slave
    if ($val{user_level}==USER_LEVEL_VIEW) {
      $hasRight=0;
    } elsif ($val{user_level}==USER_LEVEL_EDIT or 
             $val{user_level}==USER_LEVEL_VIEW_ALL) {
      if (length($eigentuemer)==0) {
        $hasRight=1;
      } elsif ($eigentuemer eq $val{user}) {
        # User is owner
        $hasRight=1;
      } elsif ($val{user_groups} =~ /$eigentuemer/) {
        # Document belongs to a group to which the user belongs too
        $hasRight=1;
      }
    } elsif ($val{user_level}==USER_LEVEL_EDIT_ALL || 
             $val{user_level}==USER_LEVEL_SYSOP) {
      $hasRight=1;
    }
  }
  return $hasRight;
}






=head1 savePageWithSettings($phuser)

Save a modified page to the database

=cut

sub savePageWithSettings {
  my $doc = shift;
  my $page = shift;
  my $adjustglobal = shift;
  my ($edit,$pages,$folder,$archived)=lockIfEditable($doc);
  if ($edit==1) {
    if ($page<=$pages && $page>0 && $usp{rotate}!=0) {
      # load the common note params
      # dont have cWidth/cHeight because we will not render the note
      my $params = {
        doc=>$doc,
        page=>$page,
        cRotate=>$usp{rotate}
      };
      # extract notes from db, and rotate them, but dont update params
      my $dbnotes = MainNoteHash($params,1,0,"",$folder,$archived);
  
      # loop thru notes and build string
      my $string = join("\r\n",
        map { $dbnotes->{$_}->toString } sort keys(%{$dbnotes})
      );

      # put updated string in db
      my $sql = "update archivseiten set Notes=" . SQLQuote($string)
           . " where Seite=" . getPageNumber($doc,$page);
      SQLUpdate($sql);

      convertImage($doc,$page,"BildInput");
      convertImage($doc,$page,"Bild");
      # Set degrees to 0 to view the save image correctly
      $usp{rotate}=0;
      MainUpdateSession();
    }
  }
  unlockAfterEdit($doc);
  $val{state} = EDIT;
  $val{view} = PAGE;
}







=head1 convertImage($documentId,$pageId,$attribute)

Save a rotated image back to database

=cut

sub convertImage {
  my $documentId = shift;
  my $page = shift;
  my $attribute = shift;
  my $pageId = getPageNumber($documentId,$page);
  my $prow = getBlobFile($attribute,$pageId);
  if ($$prow[0] ne "") {
    my $mime = getImageContentType($documentId);
    my $imgo = ExactImage::newImage();
    ExactImage::decodeImage($imgo,$$prow[0]);
    MainImageRotate($imgo);
    my $image = ExactImage::encodeImage($imgo,$mime);
    ExactImage::deleteImage($imgo);
    my $query = "UPDATE ".TABLE_IMAGES." SET $attribute = ".
             SQLQuote($image)." WHERE Seite = $pageId";
    SQLUpdate($query);
    undef $imgo;
    undef $image;
  }
}






=head1 getUserParam()

Retrieve the stored session values
  
=cut

sub getUserParam {
  my $checkLogin = shift;
  my $table = TABLE_SESSION;
  my %flds = getSessionHash();
  my $sql1 = "";
  for(my $c=1;$c<=SQL_LIMIT;$c++) {
    $sql1 .= "s".sprintf("%04d",$c).",";
  }
  $sql1 .= "s0050,";
  my $sql = "SELECT host,db,uid,pwd,$sql1".join(",",values %flds)." ".
            "FROM $table WHERE sid='".$val{sid}."'";
  my @row = getSQLOneRow($sql,$val{dbh2});
  if ($row[0] ne "") {
    $val{host}=$row[0];
    $val{db}=$row[1];
    $val{user}=$row[2];
    $val{pw}=$row[3];
    my $c=3;
    $c=SQL_LIMIT+4;
    $val{docstart}=$row[$c];
    $c++;
    foreach (keys %flds) {
      $usp{$_} = $row[$c];
      $c++;
    }
    $val{pw}=pack("H*",$val{pw});
    $usp{lang}=$val{lang} if $usp{lang} eq "";
    $usp{target} = TARGET if $usp{target} eq "";
    $usp{target} = $val{target} if $val{target} ne "";
    $usp{showocr}=1 if $val{showocr} eq '1';
    $usp{showocr}=0 if $val{showocr} eq '0';
  } else {
    MainSessionCheck() if $checkLogin==1;;
  }
  return $val{sid};
}






=head1 getUserParamMode($mode,$force)

Switch to view and state mode (MAIN/PAGE VIEW/SEARCH/EDIT)

=cut

sub getUserParamMode {
  my $mode = shift;
  my $force = shift;
  if ($mode eq MAIN.VIEW || $mode eq MAIN.EDIT || $mode eq MAIN.SEARCH ||
      $mode eq PAGE.VIEW || $mode eq PAGE.EDIT || $mode eq PAGE.SEARCH) {
    $val{view} = substr($usp{mode},0,4);
    $val{state} = substr($usp{mode},4);
  } else {
    if ($force==1) {
      $val{view} = MAIN;
      $val{state} = VIEW;
    }
  }
  $val{state} = VIEW if $val{hostslave}; # no edit in slave mode
  $val{state} = VIEW if $val{user_level}==USER_LEVEL_VIEW;
}






=head1 getSessionHash 

Gives back a hash containing (val{value} <-> sessiontable{value}

=cut

sub getSessionHash {
  my %flds = (lang=>'lang',mode=>'modus',doc=>'akte',page=>'seite',
              sqlquery=>'query',sqlorder=>'webinput',sqlpos=>'ilimit',
              sqlstart=>'avstart',sqlfulltext=>'volltext',
              hideowner=>'searchspeed',sqlftmax=>'searchmax',
              sqlrecords=>'aktenCount',exportallowed=>'weboutput',
              publishfield=>'publishField',photomode=>'photomode',
              titlehide=>'titleField',titlewidth=>'titleFieldWidth',
              target=>'target',showocr=>'ocr',showpdf=>'height',
              editAction=>'exteditaction',editOwner=>'exteditowner',
              rotate=>'degrees',zoom=>'width',ajaxlimit=>'statussearch',
              archivefolders=>'s0049',fulltextengine=>'s0048',
							orderanyway=>'s0047', showeditfield=>'s0046',
							showfieldsocr=>'s0045',
              );
  return %flds;
}






=head1 openSession()

Open a session for the logged user with a new record on the heap table
  
=cut

sub openSession {
  my $table = TABLE_SESSION;
  my $pw=unpack("H*",$val{pw});
  $val{hostslave} = HostIsSlave();
  $val{sid} = md5_hex localtime().$val{user}.$val{db}.$val{hostslave};
  my $sql = "INSERT INTO $table set sid='".$val{sid}."'";
  $sql .= ",host=".SQLQuote($val{host});
  $sql .= ",db=".SQLQuote($val{db});
  $sql .= ",uid=".SQLQuote($val{user});
  $sql .= ",pwd=".SQLQuote($pw);
  my %flds = getSessionHash();
  foreach (keys %flds) {
    $usp{$_}=$val{$_};
  }
  $usp{titlehide}=getParameterValue("FeldTitel");
  $usp{hideowner}=getParameterValue("HIDE_OWNER");
  $usp{showeditfield}=getParameterValue("NoRichEdit");
  if ($usp{titlehide}==0) {
    $usp{titlewidth}=getParameterValue("FeldBreite");
    $usp{titlewidth}=600 if $usp{titlewidth}==0;
    $usp{titlewidth}=int ($usp{titlewidth}/FIELD_WIDTH);
  }
  $usp{photomode}=getParameterValue("PhotoMode");
  $usp{publishfield}=getParameterValue("PublishField");
  $usp{archivefolders}=getParameterValue("ArchivExtended");
  $usp{exportallowed}=getParameterValue("ExportDocs01","ExportDocs01");
  my @vals = split(";",$usp{exportallowed});
  my @users = split(",",$vals[0]);
  my $disabled = $vals[3];
  my $showit=0;
  foreach (@users) {
    if ($val{user} eq $_) {
      $showit=1;
      last;
    }
  }
  $usp{exportallowed}="" if $showit==0 || $disabled==1;
  $usp{sqlftspeed}=getParameterValue("SearchSpeed");
  $usp{sqlftmax}=getParameterValue("SearchMax");
  $usp{ajaxlimit}=getParameterValue("FeldlistenAnzahl");
	$usp{fulltextengine}=getParameterValue("SEARCH_FULLTEXT");
  $usp{showpdf}=getParameterValue('DOWNLOAD_LINK');
  $usp{showpdf}=1 if $usp{showpdf} eq "";
  $usp{showocr}=getParameterValue('SHOW_OCR');
  $usp{showfieldsocr}=getParameterValue('SHOW_FIELDSOCR');
  $usp{mode}=MAIN.SEARCH;
  foreach (keys %flds) {
    $sql .= ",".$flds{$_}."=".SQLQuote($usp{$_});
  }
  SQLUpdate($sql,$val{dbh2});
  my @cookies;
  push @cookies,"Set-Cookie: sid=$val{sid}; path=/;\n";
  $val{cookie} = \@cookies;
}


=head1 getCookie($key)

Parse the COOKIE ENV variable and return the value of the cookie

=cut

sub getCookie {
  my $get_key = shift;
  if (defined $ENV{'HTTP_COOKIE'}) {
    my @key_value_pairs = split /;\s/, $ENV{'HTTP_COOKIE'};
    foreach (@key_value_pairs) {
      my ($key,$value) = split /=/, $_;
      return $value if ($key eq $get_key);
    }
  } else {
    return 0;
  }
}



=head1 MainPrintStatus()

Show the status line informations
  
=cut

sub MainPrintStatus {
  my $print = "";
  $print .= qq{<div id="StatusBar" class="StatusBar">};
  $print .= qq{$tr{db}: $val{db}, } if ViewDatabase();

  if ($val{errorint} ne "") {
    $print .= qq(<span class="Error">&nbsp;$val{errorint}</span>);
  } else {
    my $current = $usp{sqlpos}+1;
    $print .= qq($tr{rs}: <span id="StatusIndex">$current</span>/<span id="StatusTotal">$usp{sqlrecords}</span>, );
    $print .= qq($tr{document}: <span id="StatusDoc">$usp{doc}</span>, ) if ViewAkte();
    $print .= qq($tr{page}: <span id="StatusPage">$usp{page}</span>/<span id="StatusPages">$val{pages}</span> );
  }
  $print .= qq{</div>};
  $print .= MainPrintStatusPrinting() if ($val{user_field});
  return \$print;
}






=head1 MainPrintStatusPrinting

Prints the List and the From and the To Fields. For the Printing Context

=cut

sub MainPrintStatusPrinting {
  my $name = GO_PRINT;
  my $name_list = "print_list";
  my $name_from = "print_from";
  my $name_to = "print_to";
  my $html = qq{\n<div id="Printing">};
  $html .= qq{\n<select name="$name_list">\n};
  $html .= "  <option value=\"0\">".$tr{print_current_doc}."</option>\n";
  if($val{state} eq EDIT) {
    $html .= "  <option value=\"1\">".$tr{print_selected_docs}."</option>\n"
  }
  $html .= qq{</select>\n};
  $html .= qq{&nbsp;$tr{pdf_page_from}&nbsp;};
  $html .= qq{<input type="text" name="$name_from" size=3>&nbsp;};
  $html .= qq{$tr{pdf_page_to}&nbsp;}; # the - between x and y
  $html .= qq{<input type="text" name="$name_to" size=3>&nbsp;};
  $html .= qq{<input type="submit" name="$name" value="}.$tr{print_go}.qq{">};
	$html .= qq{</div>};
  return $html;
}






=head1 getUserId($host,$uid)

Give back the current user id from the user table

=cut

sub getUserId {
  my $host = shift;
  my $uid = shift;
  my $host1 = $host; # we keep the host in case we don't find it
  my @row = getSQLOneRow("SHOW PROCESSLIST");
  if ( $row[2] ne "" ) {
    $host = $row[2];
    $host =~ s/(.*)(:[0-9]+)$/$1/;
  }
  $host1 = $host if $host ne "";
  my @p = split(/\./,$host);
  my $c1 = -1;
  my $found = 0;
  my $laufnummer = 0;

  while ($found==0) {
    # as long we dont find a record, search again
    ($laufnummer,$found) = getUserIdCheck($host1,$uid);
    if ($found==0) {
      # not found
      if ($host1 eq $host) {
        # first have look at global permissions
        $host1='%';
      } else {
        # now have a look at ip/dns name parts
        if ($p[0] ne "") {
          if ($c1==-1) {
            # ip (try first last part)
            pop @p;
            $host1 = join('.',@p) . '.%';
          } else {
            # dns name (try first first part)
            shift @p;
            $host1 = '%.' . join('.',@p);
          }
        } else {
          # switch from ip to dns lookup
          if ($c1==-1) {
            @p = split(/\./,$host);
            @p = reverse @p;
            $c1=0;
          } else {
            # say at the end, that we don't search further on
            $laufnummer=0;
            $found=1;
          }
        }
      }
    }
  }
  return $laufnummer;
}






=head1 $laufnummer=getUserIdCheck($host,$uid)

Tries to match one single host name and gives back laufnummer (if founded)

=cut

sub getUserIdCheck {
  my $host = shift;
  my $uid = shift;
  $uid = SQLQuote($uid);
  $host = SQLQuote($host);
  my $sql = "select Laufnummer from user where User=$uid and Host=$host";
  my $laufnummer = getSQLOneValue($sql);
  my $found=1 if $laufnummer>0;
  return ($laufnummer,$found);
}






=head1 getUserInfo()

Get back information about the logged in user

=cut

sub getUserInfo {
  my @row;
  if ($val{user_nr}==0) {
    $val{user_nr}=getUserId($val{host},$val{user});
    if ($val{user_nr}>0) {
      my $sql = "select Alias,Anzahl,Level,PWArt,AddOn, " .
                "AVStart,AVForm,ZugriffWeb,Zusatz,AddNew ".
                "from user where Laufnummer=$val{user_nr}";
      @row = getSQLOneRow($sql);
    }
    $val{user_groups}=$row[0];  
    $val{user_limit}=$row[1];
    $val{user_level}=$row[2];
    $val{user_pwnew}=$row[3];
    $val{user_addnew}=$row[4];
    $val{user_addnew}=0 if $val{user_level} == USER_LEVEL_VIEW;
    $val{user_addnew}=1 if $val{user_level} == USER_LEVEL_SYSOP;
    $val{user_sqlnew}=$row[5];
    $val{user_form}=$row[6];
    $val{user_web}=$row[7];
    $val{user_field}=$row[8];
    $val{user_new}=$row[9];
    $val{user_nr}=0 if $val{user_web}==0;
  }
  getUserParamMode($usp{mode},1);
}




 

=head1 getFieldInfo

Retrieve all information about fields to show

=cut

sub getFieldInfo {
  $val{fields} = getDescribeTable(TABLE_ARCHIVE);
  my ($pfldtab,$pfldobj) = getFieldInfoStructure();
  my $pflds = getFieldInfoBase();

  my @fldsview = getFields($val{field_tab});
  foreach(@fldsview) {
    getFieldInfoCurrent($_,$pflds,$pfldtab,$pfldobj);
  }
	if ($usp{showeditfield}==1) {
	  my $hide = 1; # normally don't show, only when retrieving record
	  $hide = 0 if $val{action} eq "record";
    push @$pflds,{name=>"Notiz",type=>TYPE_TEXT,edit=>1,quote=>1,
                linked=>'',label=>$tr{fields_Notiz},hide=>$hide,
                width=>$usp{titlewidth},avtype=>AV_TEXT};
	}
	

  my $c=0;
  foreach(@{$pflds}) {
    my $pfld = $_;
    foreach(@{$val{fields}}) {
      my $ptab = $_;
      if ($$ptab{name} eq $pfld->{name}) {
        $$pflds[$c]->{size} = $$ptab{size};
        if ($$pflds[$c]->{width}==-2) {
          if ($$ptab{size}==0) {
            $$pflds[$c]->{width}=60;
          } else { 
            $$pflds[$c]->{width}=$$ptab{size}*4;
            $$pflds[$c]->{width}=150 if $$pflds[$c]->{width}>150;
          }
        }
        $$pflds[$c]->{type} = $$ptab{type};
        $$pflds[$c]->{quote} = $$ptab{quote};
      }
    }
    $c++;
  }
  $c=0; # test all definition fields, if they are linked to text/code
  foreach (@$pflds) {
    my $pf = $_;
    if ($pf->{avtype}==AV_DEFINITION) {
      foreach (@$pflds) {
        my $pf1 = $_;
        if (($pf1->{avtype}==AV_CODETEXT || $pf1->{avtype}==AV_CODENUMBER) && 
            $pf1->{linked} eq $pf->{name}) {
          $$pflds[$c]->{linked}=$pf1->{name};
          last;
        }
      }
    }
    $c++;
  }
  $val{fields}=$pflds;
}





=head1 getFieldInfoCurrent($name,$pflds,$pfldtab,$pfldobj)

Give back the current fields we want to show

=cut

sub getFieldInfoCurrent {
  my $name = shift;
  my $pflds = shift;
  my $pfldtab = shift;
  my $pfldobj = shift;
  return if $usp{publishfield} eq $name;
  foreach (@$pfldtab) {
    my $ptab = $_;
    if ($ptab->{name} eq $name) {
      my $width = $ptab->{width};
      if ($width!=-1) {
        $width = int ($width/FIELD_WIDTH);
        $width = -2 if $width<=0; #calculate width according field size
      } else {
        $width = 0;
      }
      foreach (@$pfldobj) {
        my $pobj = $_;
        if ($pobj->{name} eq $name && $pobj->{field}==0) {
          my $label=$ptab->{label};
          $label=$ptab->{name} if $label eq "";
          my $type=$pobj->{avtype};
          my $hide=0; # show fields
					if ($type==AV_MULTI || $type==AV_TEXT) {
            # don't show multi/note fields in table, but when showing record
					  $hide=1 if $val{action} ne "record";
					}
          $hide=1 if $width==0; # don't show field if no width
          my $linked="";
          if ($pobj->{linked} ne "") {
            $linked=$$pfldobj[$pobj->{linked}]->{name};
          } else {
            if ($pobj->{avtype}==AV_MULTI || $pobj->{avtype}==AV_1TON) {
              $type=AV_NORMAL;
            }
          }
          my $edit=1;
          $edit=0 if $hide==1 && $type!=7;
          getFieldEdit(\$edit,$pobj->{edituser}); # edit rights for field?
          push @$pflds,{name=>$name,label=>$label,hide=>$hide,width=>$width,
                       avtype=>$type,linked=>$linked,edit=>$edit,
                       edituser=>$pobj->{edituser},adduser=>$pobj->{adduser}};
          last;
        }
      }
    }
  }
}






=head1 getFieldEdit(\$edit,$users)

Check if a user can edit a field (or add field values)

=cut

sub getFieldEdit {
  my $pedit = shift;
  my $users = shift;
  if ($users ne "") {
    my @edit = split(",",$users);
    my $pusers = getSelfAndAliasOwner();
    my $found=0;
    foreach (@edit) {
      my $ed = $_;
      foreach (@$pusers) {
        my $us = $_;
        if ($ed eq $us) {
          $found=1;
          last;
        }
      }
      last if $found==1;
    }
    $$pedit=$found;
  }
}






=head1 $pflds=getFieldInfoBase

Give back the standard fields for later processing

=cut

sub getFieldInfoBase {
  my @flds = ();
  push @flds,{name=>"Laufnummer",type=>TYPE_KEY,width=>25,
              linked=>'',label=>$tr{fields_Akte}};
  push @flds,{name=>"Seiten",type=>TYPE_INT,width=>10,
              linked=>'',label=>$tr{fields_Seiten}};
  push @flds,{name=>"Ordner",type=>TYPE_INT,width=>15,hide=>1,
              linked=>'',label=>$tr{fields_Ordner}};
  my $width=32;
  push @flds,{name=>"Datum",type=>TYPE_DATE,width=>$width,
              linked=>'',label=>$tr{fields_Datum},edit=>1};
  push @flds,{name=>"Archiviert",type=>TYPE_YESNO,width=>5,
              linked=>'',label=>$tr{fields_Archiviert}};
	my $hide = 1; # normally don't show owner, only when retrieving record
	$hide = 0 if $val{action} eq "record";
  push @flds,{name=>"Eigentuemer",type=>TYPE_CHAR,
              linked=>'',width=>60,edit=>1,hide=>$hide,
              label=>$tr{fields_Eigentuemer}};
  if ($usp{publishfield} ne "") {
    push @flds,{name=>$usp{publishfield},type=>TYPE_CHAR,
                width=>90,edit=>1,hide=>0,
                linked=>'',label=>$tr{publish},avtype=>AV_DEFINITION};
  }
  if ($usp{titlehide}==0) {
    push @flds,{name=>"Titel",type=>TYPE_CHAR,edit=>1,quote=>1,
                linked=>'',label=>$tr{fields_Titel},
                width=>$usp{titlewidth}};
  }
  return \@flds;
}






=head1 ($pfldtab,$pfldobj)=getFieldInfoStructure()

Extract the needed information for the user defined fields

=cut

sub getFieldInfoStructure {
  my $avform = sprintf "%02d", $val{user_form};
  $val{field_tab} = getParameterValue("FelderTab$avform","Felder");
  $val{field_obj} = getParameterValue("FelderObj$avform","Felder");
  #$val{field_obj} =~ s/\r//;
  my @fldobj = split(/\n/,$val{field_obj});
  my $c = 0;
  foreach(@fldobj) {
    my @tb = split(/;/,$_);
    if ($tb[4] == 0) {
      my $pos=$c;
      $fldobj[$c++] = {name=>$tb[18],field=>$tb[4],avtype=>$tb[5],posi=>$pos,
                       linked=>$tb[10],edituser=>$tb[24],adduser=>$tb[23]};
    } else {
      $fldobj[$c++] = {name=>$tb[18],field=>$tb[4]};
    }
  }
  my @fldtab = split(/\r\n/,$val{field_tab});
  $c=0;
  foreach(@fldtab) {
    my @tb = split(/;/,$_);
    $fldtab[$c++] = {name=>$tb[0],label=>$tb[1],width=>$tb[3]};
  }
  return (\@fldtab,\@fldobj);
}






=head1 getDescribeTable($table,[$dbh])

Get all information about fields in a table

=cut

sub getDescribeTable {
  my $table = shift;
  my $dbh = shift;
  my @flds = ();
  my $prows = getSQLAllRows("DESCRIBE $table",$dbh);
  foreach (@$prows) {
    my @row = @$_;
    my $name = $row[0];
    my ($type,$lang) = $row[1] =~ /(.*)\((.*)\)/; # extract type(length)
    $type=$row[1] if ($type eq ""); # some fields only have type
    my $quote=0;
    if ($type eq TYPE_CHAR || $type eq TYPE_BLOB || $type eq TYPE_TEXT ||
        $type eq TYPE_MEDIUMBLOB || $type eq TYPE_LONGBLOB || 
        $type eq TYPE_CHARFIX || $type eq TYPE_TEXT) {
      $quote=1;
    }
    $type=TYPE_KEY if $row[3] eq TYPE_KEY;
    push @flds,{name=>$name,type=>$type,size=>$lang,quote=>$quote};
  }
  return \@flds;
}






=head1 getTranslations($lang)

According language code set all messages

=cut

sub getTranslations {
  my $lang = shift;
  if ($lang eq "de") {
    foreach my $key (keys %{$langtr{de}}) {
      $tr{$key} = $langtr{de}->{$key};
    }
  } elsif ($lang eq "fr") {
    foreach my $key (keys %{$langtr{fr}}) {
      $tr{$key} = $langtr{fr}->{$key};
    }
  } elsif ($lang eq "it") {
    foreach my $key (keys %{$langtr{it}}) {
      $tr{$key} = $langtr{it}->{$key};
    }
  } else {
    foreach my $key (keys %{$langtr{en}}) {
      $tr{$key} = $langtr{en}->{$key};
    }
  }
}



=head1 $prow=getSQLRowPointer($sql,[$dbh]);

Gives back pointer to list with result of sql request from $val{dbh}|$dbh

=cut

sub getSQLRowPointer {
  my $sql = shift;
  my $dbh = shift;
  my @row;
  if ($dbh) {
    @row = $dbh->selectrow_array($sql);
  } else {
    @row = $val{dbh}->selectrow_array($sql);
  }
  return \@row;
}



=head1 $prow=getSQLRowPointerRef($sql,[$dbh]);

Gives back pointer to list with result of sql request from $val{dbh}|$dbh

=cut

sub getSQLRowPointerRef {
  my $sql = shift;
  my $dbh = shift;
	my $ref = "";
  if ($dbh) {
    $ref = $dbh->selectrow_arrayref($sql);
  } else {
    $ref = $val{dbh}->selectrow_arrayref($sql);
  }
  return $ref;
}






=head1 $prows=getSQLAllRows($sql,[$dbh])

Gives back a pointer to all rows

=cut

sub getSQLAllRows {
  my $sql = shift;
  my $dbh = shift;
  my $prows = shift;
  if ($dbh) {
    $prows=$dbh->selectall_arrayref($sql);
  } else {
    $prows=$val{dbh}->selectall_arrayref($sql);
  }
  return $prows;
}






=head1 @row=getSQLOneRow($sql,[$dbh])

Gives back a list with the result of a sql request from $val{dbh}|$dbh

=cut

sub getSQLOneRow {
  my $sql = shift;
  my $dbh = shift;
  my $prow = getSQLRowPointer($sql,$dbh);
  return @{$prow};
}





=head1 $val=getSQLOneValue($sql,[$dbh])

Gives back one column value from the $sql request in $val{dbh}|$dbh

=cut

sub getSQLOneValue {
  my $sql = shift;
  my $dbh = shift;
  my $prow = getSQLRowPointer($sql,$dbh);
  return $$prow[0];
}






=head1 $rec=SQLUpdate($sql,[$dbh]) 

Do an sql command with $val{dbh}|$dbh

=cut

sub SQLUpdate {
  my $sql = shift;
  my $dbh = shift;
  my $res = 0;
  if ($dbh) {
    $res=$dbh->do($sql);
  } else {
    $res=$val{dbh}->do($sql)
  }
  return $res;
}






=head1 $valquoted=SQLQuote($val)

Quote normal/referrenced variable (session handler is used)

=cut

sub SQLQuote {
  my $value = shift;
  if (ref($value)) {
    return $val{dbh2}->quote($$value);
  } else  {
    return $val{dbh2}->quote($value);
  } 
}






=head1 toUTF8

Convert a ISO-8859-1 string to utf8

=cut

sub toUTF8 {
  my $string = shift;
  Encode::from_to($string,"iso-8859-1","utf8");
  return $string;
}






=head1 fromUTF8

Convert a string fromUTF8 and give it back as iso-8859-1

=cut

sub fromUTF8 {
  my $string = shift;
  $string = Encode::decode_utf8($string);
  $string = encode("iso-8859-1", $string);
  return $string;
}






=head1 $ret=writeFile($outfile,$pdata,$killit)

Save pdata (scalar or pointer) to outfile, overwrite it if killit==1

=cut

sub writeFile {
  my $outfile = shift;
  my $pdata = shift;
  my $killit = shift;
  my $ret = 0;
  if (-e $outfile) {
    unlink $outfile if $killit==1;
  }
  if (!-e $outfile) {
    open(FILE,">$outfile");
    binmode(FILE);
    if (ref($pdata) eq "SCALAR") {
      print FILE $$pdata;
    } else {
      print FILE $pdata;
    }
    close(FILE);
    $ret=1 if -e $outfile;
  }
  return $ret;
}






=head1 $fname=writeTempFile($pdata)

Save pdata (scalar or pointer) to temp outfile

=cut

sub writeTempFile {
  my $pdata = shift;
  my ($fh,$tempfile) = tempfile(DIR=>"/home/data/archivista/tmp");
  if ($fh) {
    binmode($fh);
    if (ref($pdata) eq "SCALAR") {
      my $lang = length($$pdata);
      print $fh $$pdata;
    } else {
      print $fh $pdata;
    }
    close($fh);
  } else {
    $tempfile = "";
  }
  return $tempfile;
}






=head1 $fname=getTempFile($file1,$ext,[$killit])

Get a temp file with an extension and kill it if wished

=cut

sub getTempFile {
  my $file1 = shift;
  my $ext = shift;
  my $killit = shift;
  unlink $file1 if -e $file1 && $killit==1;
  $file1 .= $ext;
  unlink $file1 if -e $file1 && $killit==1;
  return $file1;
}






=head1 $pdata=getFile($file,[$killit])

Get the file back as a pointer

=cut

sub getFile {
  my $file = shift;
  my $killit = shift;
  my $data = "";
  if (-e $file) {
    open(FIN,$file);
    binmode(FIN);
    while(my $line = <FIN>) {
      $data .= $line;
    }
    close(FIN);
  }
  if ($killit==1) {
    unlink $file if -e $file;
  }
  return \$data;
}






=head1 $pdata=getFile2($file,[$killit])

Get the file back as a pointer

=cut

sub getFile2 {
  my ($file1,$killit) = @_;
  my $buf = "";
  my $out = "";
  eval { open (FH, '< :raw', $file1) or die $!; };
  my $length = 4096*1024;
  while (my $read = sysread( FH, $buf, $length) ) {
    $out .= $buf;
  }
  if ($killit==1) {
    unlink $file1 if -e $file1;
  }
  return \$out;
}






=head1 $pblob=getBlobFile($field,$page,$table)

Give back a file from the blob table archivbilder

=cut

sub getBlobFile {
  my $field = shift;
  my $page = shift;
  my $ordner = shift;
  my $archiviert = shift;
  my $table = shift;
  $table = TABLE_IMAGES if $table ne TABLE_PAGES;
  if ($archiviert==1 && $usp{archivefolders}>0) {
    my $nr = int(($ordner-1)/$usp{archivefolders});
    $nr = $nr * $usp{archivefolders};
    $table = TABLE_ARCHIVED.sprintf("%05d",$nr);
  }
  my $sql = "select $field from $table where Seite=$page";
  my $prow = getSQLRowPointerRef($sql);
  return $prow;
}






=head1 $pagenr=getPageNumber($doc,[$page])

Give back the page number for a document and a page (1 if no page)

=cut

sub getPageNumber {
  my $doc = shift;
  my $page = shift;
  $doc = 0 if $doc <= 0;
  if ($doc) {
    $page = 1 if $page<=0;
    $page = 640 if $page>640;
  } else {
    $page = 0;
  }
  my $nr = ($doc*1000)+$page;
  return $nr;
}





=head1 check64bit

Give back a 1 if we are not in 32bit mode

=cut

sub check64bit {
	my $var = $ENV{MOD_PERL};
  my $val = 1;
	$val=0 if $ENV{MOD_PERL} ne "mod_perl/2.0.1";
	return $val;
}






=head1 logit($mess)

Prints out a message to STDERR channel

=cut

sub logit {
  my $mess = shift;
  print STDERR "WEBCLIENT: ---------------- $mess\n";
}


# ATTENTION: must be here, otherwise package won't load
1;



