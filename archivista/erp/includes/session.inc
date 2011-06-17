<?php

/*--------------------------------------------------\
|							 |							 | session.inc			 |
|---------------------------------------------------|
| ArchivistaERP																		 |
| http://www.archivista.ch													|
\--------------------------------------------------*/

function logit($text) {
  $fh = fopen("/tmp/erp.log","a");
	$text = "$text\n";
	fwrite($fh,$text);
	fclose($fh);
}

ob_start("allout");

if (!isset($path_to_root)) { $path_to_root = "./"; }
$session_save_path = session_save_path();
if (strpos($session_save_path, ";") !== false)
	$session_save_path = substr($session_save_path, 
						strpos($session_save_path, ";") + 1);
if (isset($session_save_path)) {
	session_save_path($session_save_path);
	unset($session_save_path);
}
if (!isset($path_to_root) || isset($_GET['path_to_root']) 
													|| isset($_POST['path_to_root']))
	die("Restricted access");
include_once($path_to_root . "/config_db.php");
include_once($path_to_root . "/lang/installed_languages.inc");

session_start();
// this is to fix the "back-do-you-want-to-refresh" issue - thanx PHPFreaks
//header("Cache-control: private");

// Page Initialisation
if (!isset($_SESSION['languages'])) { 
  language::load_languages(); 
}
$lang = $_SESSION['language'];

// Unnecessary for ajax calls. 
// Due to bug in php 4.3.10 for this version set globally in php4.ini
ini_set('default_charset', $_SESSION['language']->encoding);

$trstring; 
function readstrings($lang) {
  global $trstring,$path_to_root;
  $file = $path_to_root."/lang/$lang/LC_MESSAGES/$lang.po";
	if (!file_exists($file)) {
	  return;
	}
	$input = file_get_contents($file);
	$lines = explode("\n",$input);
	$strkey = "";
  $strval = "";
	$trstring = null;
	foreach ($lines as $line) {
		if ($strkey == "") {
		  list($code,$text) = explode('msgid "',$line);
		  if ($code=='' && $text != '') {
		    $strkey = substr($text,0,strlen($text)-1);
		  }
		} else {
	    list($code,$text) = explode('msgstr "',$line);
		  if ($code=='' && $text != '') {
		    $strval = substr($text,0,strlen($text)-1);
			}
		  if ($strval != "") {
		    $trstring[$strkey]=$strval;
		    $strkey="";
		    $strval="";
			}
		}
	}
}
readstrings($lang->code);

function tr($text) {
  global $trstring;
	$retVal = $trstring[$text];
	if ($retVal == "")
	  $retVal = $text;
	return $retVal;
}



include_once($path_to_root . "/config.php");
include_once($path_to_root . "/includes/db/connect_db.inc");
include_once($path_to_root . "/includes/reserved.inc");
include_once($path_to_root . "/includes/errors.inc");
include_once($path_to_root . "/includes/types.inc");
include_once($path_to_root . "/includes/systypes.inc");
include_once($path_to_root . "/includes/references.inc");
include_once($path_to_root . "/includes/prefs/sysprefs.inc");
include_once($path_to_root . "/includes/db/comments_db.inc");
include_once($path_to_root . "/includes/db/sql_functions.inc");
include_once($path_to_root . "/admin/db/users_db.inc");
include_once($path_to_root . "/includes/ui/ui_view.inc");

if (!isset($_SESSION["wa_current_user"]) ||
		(isset($_SESSION["wa_current_user"]) && 
		!$_SESSION["wa_current_user"]->logged_in())) {
	$_SESSION["wa_current_user"] = new current_user();
	// Show login screen
	if (!isset($_POST["user_name_entry_field"]) or 
					$_POST["user_name_entry_field"] == "") {
		include($path_to_root . "/login.php");
		exit;
	}
}

if (isset($_POST["user_name_entry_field"])) {
	$succeed = $_SESSION["wa_current_user"]->login($_POST["company_login_name"],
		$_POST["user_name_entry_field"],
		md5($_POST["password"]));
	if (!$succeed) {
		// Incorrect password
		login_fail();
	}
}

check_page_security($page_security);





function _set($key,$value) { get_text::set_var($key,$value); }

function reload_page($msg) {
	echo "<html>";
	echo "<head>";
	echo "<title>Changing Languages</title>";
	echo '<meta http-equiv="refresh" content="0;url=' . 
	$_SERVER['PHP_SELF'] . '">';
	echo '</head>';
	echo '<body>';
	echo '<div>';
	if ($msg != "")
		echo $msg . " " . $_SERVER['PHP_SELF'];
	echo "</div>";	
	echo "</body>";
	echo "</html>";
}

function kill_login() {
	session_unset();
	session_destroy();
}

function login_fail() {
	echo "<center><br><br><font size='5' color='red'><b>" .
					 tr("Incorrect Password") . "<b></font><br><br>";
	echo "<b>" . tr("The user and password combination is not valid for the system.") . "<b><br><br>";
	echo tr("If you are not an authorized user, please contact your system administrator to obtain an account to enable you to use the system.");
	echo "<br><a href='javascript:history.go(-1)'>" . tr("Back") . "</a>";
	echo "</center>";
	kill_login();
	die();
}

function check_page_security($page_security) {
	if (!$_SESSION["wa_current_user"]->check_user_access()) {
		echo "<br><br><br><center>";
		echo "<b>" . tr("Security settings have not been defined for your user account.");
		echo "<br>" . tr("Please contact your system administrator.") . "</b>";
		kill_login();
		exit;
	}
	if (!$_SESSION["wa_current_user"]->can_access_page($page_security)) {
		page(tr("Access denied"));
		echo "<center><br><br><br><b>";
		echo tr("The security settings on your account do not permit you to access this function");
		echo "</b>";
		echo "<br><br><a href='javascript:history.go(-1)'>" . tr("Back") . "</a>";
		echo "<br><br><br><br>";
		end_page();
		exit;
	}
}

function number_format2($number, $decimals=0,$nothousandsep) {
	global $thoseps, $decseps;
	$tsep = $thoseps[$_SESSION["wa_current_user"]->prefs->tho_sep()];
	if ($nothousandsep==1) {
	  $tsep = "";
	}
	$dsep = $decseps[$_SESSION["wa_current_user"]->prefs->dec_sep()];
	return number_format($number, $decimals, $dsep,	$tsep);
}

function price_format($number) {
	return number_format2($number, 
		$_SESSION["wa_current_user"]->prefs->price_dec());
}

function qty_format($number) {
	return number_format2($number, 
		$_SESSION["wa_current_user"]->prefs->qty_dec());
}

function exrate_format($number) {
	return number_format2($number, 
		$_SESSION["wa_current_user"]->prefs->exrate_dec());
}

function percent_format($number) {
	return number_format2($number, 
		$_SESSION["wa_current_user"]->prefs->percent_dec());
}

function user_numeric($input) {
	global $decseps, $thoseps;
	$num = trim($input);
	$sep = $thoseps[user_tho_sep()];
	if($sep!='') $num = str_replace( $sep, '', $num);
	str_replace($sep, '', $num);
	$sep = $decseps[user_dec_sep()];
	if($sep!='.') $num = str_replace( $sep, '.', $num);
	if (!is_numeric($num))
		return false;
	$num = (float)$num;
	if ($num == (int)$num)
		return (int)$num;
	else
		return $num;
}

function user_company() {
	return $_SESSION["wa_current_user"]->company;
}

function user_language() {
	return $_SESSION["wa_current_user"]->prefs->language();
}

function user_qty_dec() {
	return $_SESSION["wa_current_user"]->prefs->qty_dec();
}

function user_price_dec() {
	return $_SESSION["wa_current_user"]->prefs->price_dec();
}

function user_exrate_dec() {
	return $_SESSION["wa_current_user"]->prefs->exrate_dec();
}

function user_percent_dec() {
	return $_SESSION["wa_current_user"]->prefs->percent_dec();
}

function user_show_gl_info() {
	return $_SESSION["wa_current_user"]->prefs->show_gl_info();
}

function user_show_codes() {
	return $_SESSION["wa_current_user"]->prefs->show_codes();
}

function user_date_format() {
	return $_SESSION["wa_current_user"]->prefs->date_format();
}

function user_date_display() {
	return $_SESSION["wa_current_user"]->prefs->date_display();
}

function user_date_sep() {
	return $_SESSION["wa_current_user"]->prefs->date_sep();
}

function user_tho_sep() {
	return $_SESSION["wa_current_user"]->prefs->tho_sep();
}

function user_dec_sep() {
	return $_SESSION["wa_current_user"]->prefs->dec_sep();
}

function user_theme() {
	return $_SESSION["wa_current_user"]->prefs->get_theme();
}

function user_pagesize() {
	return $_SESSION["wa_current_user"]->prefs->get_pagesize();
}

function set_user_prefs($price_dec, $qty_dec, $exrate_dec, 
				 $percent_dec, $showgl, $showcodes, $date_format, $date_sep, 
				 $tho_sep, $dec_sep, $theme, $pagesize) {
	$_SESSION["wa_current_user"]->update_prefs($price_dec, $qty_dec, 
					 $exrate_dec, $percent_dec, $showgl, $showcodes,
					 $date_format, $date_sep, $tho_sep, $dec_sep, $theme, $pagesize);
}


class current_user {
	var $loginname;
	var $username;
	var	$name;
	var $company;
	var $access;
	var $logged;
	var $prefs;
	function current_user() {
		$this->loginname = $username = $this->name = $this->company = "";
		$this->logged = false;
		$this->prefs = null;
	}
	function logged_in() {
		return $this->logged;
	}
	function set_company($company) {
		$this->company = $company;
	}
	function login($company, $loginname, $password) {
		$this->set_company($company);
		$Auth_Result = get_user_for_login($loginname, $password);
		if (db_num_rows($Auth_Result) > 0) {
			$myrow = db_fetch($Auth_Result);
			$this->access = $myrow["full_access"];
			$this->name = $myrow["real_name"];
			$this->loginname = $loginname;
			$this->username = $this->loginname;
			$this->prefs = new user_prefs($myrow);
			update_user_visitdate($loginname);
			$this->logged = true;
		} else {
			$this->logged = false;
		}
		return $this->logged;
	}
	function check_user_access() {
		global $security_groups;
		return is_array($security_groups[$this->access]);
	}
	function can_access_page($page_level) {
		global $security_groups;
		return isset($page_level) && in_array($page_level, 
										 $security_groups[$this->access]);
	}
	function get_db_connection() {
		global $db_connections;
	 	$connection = $db_connections[$this->company];
	 	$db = mysql_connect($connection["host"] ,
		$connection["dbuser"], $connection["dbpassword"]);
		mysql_select_db($connection["dbname"],$db);
		return $db;
	}
	function update_prefs($price_dec, $qty_dec, $exrate_dec, 
					$percent_dec, $showgl, $showcodes, $date_format, $date_sep, 
					$tho_sep, $dec_sep, $theme, $pagesize) {
		update_user_display_prefs($this->username, $price_dec, $qty_dec, 
			$exrate_dec, $percent_dec, $showgl, $showcodes, $date_format, 
			$date_sep, $tho_sep, $dec_sep, $theme, $pagesize);
		// re-read the prefs
		$user = get_user($this->username);
		$this->prefs = new user_prefs($user);
	}
}

class user_prefs {
	var $language;
	var $qty_dec;
	var $price_dec;
	var	$exrate_dec;
	var	$percent_dec;
	var	$show_gl_info;
	var	$show_codes;
	var $date_format;
	var $date_sep;
	var $tho_sep;
	var $dec_sep;
	var $theme;
	var $pagesize; // for printing
	function user_prefs(&$user) {
		$this->language = $user["language"];
		language::set_language($this->language);
		$this->qty_dec = $user["qty_dec"];
		$this->price_dec = $user["prices_dec"];
		$this->exrate_dec = $user["rates_dec"];
		$this->percent_dec = $user["percent_dec"];
		$this->show_gl_info = $user["show_gl"];
		$this->show_codes = $user["show_codes"];
		$this->date_format = $user["date_format"];
		$this->date_sep = $user["date_sep"];
		$this->tho_sep = $user["tho_sep"];
		$this->dec_sep = $user["dec_sep"];
		$this->theme = $user["theme"];
		$this->pagesize = $user["page_size"];
	}
	function language() { return $this->language; }
	function qty_dec() { return $this->qty_dec; }
	function price_dec() { return $this->price_dec; }
	function exrate_dec() { return $this->exrate_dec; }
	function percent_dec() { return $this->percent_dec; }
	function show_gl_info() { return $this->show_gl_info; }
	function show_codes() { return $this->show_codes; }
	function date_format() { return $this->date_format; }
	function date_sep() { return $this->date_sep; }
	function date_display() { 
		global $dateseps;
		$sep = $dateseps[$this->date_sep];
		if ($this->date_format == 0)
			return "m".$sep."d".$sep."Y";
		elseif ($this->date_format == 1)
			return "d".$sep."m".$sep."Y";
		else
			return "Y".$sep."m".$sep."d";
	}
	function tho_sep() { return $this->tho_sep; }
	function dec_sep() { return $this->dec_sep; }
	function get_theme() { return $this->theme; }
	function get_pagesize() { return $this->pagesize; }
	function set_dec($price_dec, $qty_dec, $exrate_dec, $percent_dec, 
									$showgl, $showcodes) {
		$this->price_dec = $price_dec;
		$this->qty_dec = $qty_dec;
		$this->exrate_dec = $exrate_dec;
		$this->percent_dec = $percent_dec;
		$this->show_gl_info = $showgl;
		$this->show_codes = $showcodes;
	}
	function set_format($date_format, $date_sep, $tho_sep, $dec_sep, 
					 $theme, $pagesize) {
		$this->date_format = $date_format;
		$this->date_sep = $date_sep;
		$this->tho_sep = $tho_sep;
		$this->dec_sep = $dec_sep;
		$this->theme = $theme;
		$this->pagesize = $pagesize;
	}
}

function page($title, $no_menu=false, $is_index=false, $onload="", $js="") {
	global $path_to_root, $js_lib;
	$hide_menu = $no_menu;
	include($path_to_root . "/includes/page/header.inc");
	page_header($title, $no_menu, $is_index, $onload, $js);
}

function end_page($no_menu=false, $is_index=false) {
	global $path_to_root;
	$hide_menu = $no_menu;
	include($path_to_root . "/includes/page/footer.inc");
	page_footer($no_menu, $is_index);
}

function flush_dir($path) {
	$dir = opendir($path);
	while(false !== ($fname = readdir($dir))) {
		if($fname=='.' || $fname=='..') continue;
			if(is_dir($path.'/'.$fname)) {
				flush_dir($path.'/'.$fname);
				rmdir($path.'/'.$fname);
		} else
				unlink($path.'/'.$fname);
	}
}

function cache_js_file($fpath, $text) {
	// FIX compress text ...
	$file = fopen($fpath, 'w');
	if (!$file) return false;
	if (!fwrite($file, $text)) return false;
	return fclose($file);
}

function add_js_file($filename) {
	global $js_static;
	$search = array_search($filename, $js_static);
	if ($search === false || $search === null) // php>4.2.0 returns null
	$js_static[] = $filename;	
}

function add_js_ufile($filename) {
	global $js_userlib;
	$search = array_search($filename, $js_userlib);
	if ($search === false || $search === null) // php>4.2.0 returns null
	$js_userlib[] = $filename;
}

function add_js_source($text) {
	global $js_lib;
	$search = array_search($text, $js_lib);
	if ($search === false || $search === null) // php>4.2.0 returns null
	$js_lib[] = $text;
}

class language {
	var $name;
	var $code;			// eg. ar_EG, en_GB
	var $encoding;		// eg. UTF-8, CP1256, ISO8859-1
	var	$dir;			// Currently support for Left-to-Right (ltr) and
						// Right-To-Left (rtl)
	function language($name, $code, $encoding) {
		$this->name = $name;
		$this->code = $code;
		$this->encoding = $encoding;
		$this->dir = "ltr";
	}
	function get_language_dir() { return "lang/" . $this->code; }
	function get_current_language_dir() {
		$lang = $_SESSION['language'];
		return "lang/" . $lang->code;
	}
	function set_language($code) {
		if (isset($_SESSION['languages'][$code]) &&
			$_SESSION['language'] != $_SESSION['languages'][$code]) 
		{
			$_SESSION['language'] = $_SESSION['languages'][$code];
			reload_page("");
		}
	}
	function get_stylesheet() {
		return 'lang/' . $_SESSION['language']->code . '/stylesheet.css';
	}
	/**
	 * This method loads an array of language objects into a session variable
		 * called $_SESSIONS['languages']. Only supported languages are added.
		 */
	function load_languages() {
		global $installed_languages;
		$_SESSION['languages'] = array();
		foreach ($installed_languages as $lang) {
			$l = new language($lang['name'],$lang['code'],$lang['encoding']);
			if (isset($lang['rtl']))
				$l->dir = "rtl";
			$_SESSION['languages'][$l->code] = $l;
		}
		if (!isset($_SESSION['language'])) {
			$_SESSION['language'] = $_SESSION['languages']['en_GB'];
		}
	}
}

function allout($text) {
  return $text;
}



function image_load($max_image_size) {
  $upload_file = "";
	$blob = "";
  if (isset($_FILES['pic']) && $_FILES['pic']['name'] != '') {
	  $result = $_FILES['pic']['error'];
 	  $upload_file = 'Yes'; //Assume all is well to start off with
	  //But check for the worst 
	  if (strtoupper(substr(trim($_FILES['pic']['name']), 
		    strlen($_FILES['pic']['name']) - 3)) != 'JPG') {
		  display_notification(tr('Only jpg files are supported - a file '.
			                       'extension of .jpg is expected'));
		  $upload_file ='No';
	  } elseif ( $_FILES['pic']['size'] > ($max_image_size * 1024)) { //Size?
		  display_notification(tr('The file size is over the maximum allowed. '.
		         'The maximum size allowed in KB is') . ' ' . $max_image_size);
		  $upload_file ='No';
	  } elseif ( $_FILES['pic']['type'] == "text/plain" ) {  //File type Check
		  display_notification( tr('Only graphics files can be uploaded'));
      $upload_file ='No';
	  } 
	  if ($upload_file == 'Yes') {
	    $fp = fopen($_FILES['pic']['tmp_name'],"r");
		  $blob = fread($fp,filesize($_FILES['pic']['tmp_name']));
		  fclose($fp);
		  $blob = addslashes($blob);
		  unlink($_FILES['pic']['tmp_name']);
	  }
  }
	return $blob;
}




?>

