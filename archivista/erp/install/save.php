<?php

	$_POST['operating_system'] = 'linux'; // always linux
	$_POST['database_host'] = 'localhost'; // only localhost
	$_POST['database_username'] = 'root'; // only root
	$_POST['install_tables'] = true; // install tables
			
error_reporting(E_ALL);
ini_set("display_errors", "On");

// Start a session
if(!defined('SESSION_STARTED')) 
{
	session_name('ba_session_id');
	session_start();
	define('SESSION_STARTED', true);
}

// Function to set error
function set_error($message) 
{
	global $_POST;
	if(isset($message) AND $message != '') 
	{
		// Copy values entered into session so user doesn't have to re-enter everything
		if(isset($_POST['company_name'])) 
		{
			$_SESSION['ba_url'] = $_POST['ba_url'];
			if(!isset($_POST['operating_system'])) 
			{
				$_SESSION['operating_system'] = 'linux';
			} 
			else 
			{
				$_SESSION['operating_system'] = $_POST['operating_system'];
			}
			if(!isset($_POST['world_writeable'])) 
			{
				$_SESSION['world_writeable'] = false;
			} 
			else 
			{
				$_SESSION['world_writeable'] = true;
			}
			$_SESSION['database_host'] = $_POST['database_host'];
			$_SESSION['database_username'] = $_POST['database_username'];
			$_SESSION['database_password'] = $_POST['database_password'];
			$_SESSION['database_name'] = $_POST['database_name'];
			if(!isset($_POST['install_tables'])) 
			{
				$_SESSION['install_tables'] = false;
			} 
			else 
			{
				$_SESSION['install_tables'] = true;
			}
			$_SESSION['company_name'] = $_POST['company_name'];
			$_SESSION['admin_email'] = $_POST['admin_email'];
			$_SESSION['admin_password'] = $_POST['admin_password'];

		}
		// Set the message
		$_SESSION['message'] = $message;
		// Specify that session support is enabled
		$_SESSION['session_support'] = '<font class="good">Enabled</font>';
		// Redirect to first page again and exit
		header('Location: index.php?sessions_checked=true');
		exit();
	}
}

// Function to check if the accounting scheme is ok
function accounting_scheme() {
  global $_POST,$path_to_root;
	$path = $path_to_root.'/sql/';
  $file = $_POST['admin_accounting'];
	if ($file=='')
	  $file = 'de_CH-new.sql';
	$file = $path.$file;
  if (!file_exists($file)) 
	  $file = $path.'de_CH-new.sql';
	return $file;
}

// Function to workout what the default permissions are for files created by the webserver
function default_file_mode($temp_dir) 
{
	$v = explode(".",PHP_VERSION);
	$v = $v[0].$v[1];
	if($v > 41 && is_writable($temp_dir)) 
	{
		$filename = $temp_dir.'/test_permissions.txt';
		$handle = fopen($filename, 'w');
		fwrite($handle, 'This file is to get the default file permissions');
		fclose($handle);
		$default_file_mode = '0'.substr(sprintf('%o', fileperms($filename)), -3);
		unlink($filename);
	} 
	else 
	{
		$default_file_mode = '0777';
	}
	return $default_file_mode;
}

// Function to workout what the default permissions are for directories created by the webserver
function default_dir_mode($temp_dir) 
{
	$v = explode(".",PHP_VERSION);
	$v = $v[0].$v[1];
	if ($v > 41 && is_writable($temp_dir)) 
	{
		$dirname = $temp_dir.'/test_permissions/';
		mkdir($dirname);
		$default_dir_mode = '0'.substr(sprintf('%o', fileperms($dirname)), -3);
		rmdir($dirname);
	} 
	else 
	{
		$default_dir_mode = '0777';
	}
	return $default_dir_mode;
}

function add_slashes($input) 
{
	if (get_magic_quotes_gpc() || (!is_string($input))) 
	{
		return $input;
	}
	$output = addslashes($input);
	return $output;
}
function check_db_error($err_msg, $sql)
{
	return true;
}	

if (isset($_POST['path_to_root']))
	$path_to_root = $_POST['path_to_root'];
else	
	$path_to_root = "..";
	
// Begin check to see if form was even submitted
// Set error if no post vars found
if (!isset($_POST['company_name'])) 
{
	set_error('Please fill-in the form below');
}
// End check to see if form was even submitted

// Begin path and timezone details code

// Check if user has entered the installation url
if (!isset($_POST['ba_url']) || $_POST['ba_url'] == '') 
{
	set_error('Please enter an absolute URL');
} 
else 
{
	$ba_url = $_POST['ba_url'];
}

// Remove any slashes at the end of the URL
if(substr($ba_url, strlen($ba_url) - 1, 1) == "/") 
{
	$ba_url = substr($ba_url, 0, strlen($ba_url) - 1);
}
if(substr($ba_url, strlen($ba_url) - 1, 1) == "\\") 
{
	$ba_url = substr($ba_url, 0, strlen($ba_url) - 1);
}
if(substr($ba_url, strlen($ba_url) - 1, 1) == "/") 
{
	$ba_url = substr($ba_url, 0, strlen($ba_url) - 1);
}
if(substr($ba_url, strlen($ba_url) - 1, 1) == "\\") 
{
	$ba_url = substr($ba_url, 0, strlen($ba_url) - 1);
}
// End path

// Begin operating system specific code
// Get operating system
if (!isset($_POST['operating_system']) || $_POST['operating_system'] != 'linux' && $_POST['operating_system'] != 'windows') 
{
	set_error('Please select a valid operating system');
} 
else 
{
	$operating_system = $_POST['operating_system'];
}
// Work-out file permissions
if($operating_system == 'windows') 
{
	$file_mode = '0777';
	$dir_mode = '0777';
} 
elseif (isset($_POST['world_writeable']) && $_POST['world_writeable'] == 'true') 
{
	$file_mode = '0777';
	$dir_mode = '0777';
} 
else 
{
	$file_mode = default_file_mode('../includes');
	$dir_mode = default_dir_mode('../includes');
}
// End operating system specific code

// Begin database details code
// Check if user has entered a database host
if (!isset($_POST['database_host']) || $_POST['database_host'] == '') 
{
	set_error('Please enter a database host name');
} 
else 
{
	$database_host = $_POST['database_host'];
}
// Check if user has entered a database username
if (!isset($_POST['database_username']) || $_POST['database_username'] == '') 
{
	set_error('Please enter a database username');
} 
else 
{
	$database_username = $_POST['database_username'];
}
// Check if user has entered a database password
if (!isset($_POST['database_password'])) 
{
	set_error('Please enter a database password');
} 
else 
{
	$database_password = $_POST['database_password'];
}
// Check if user has entered a database name
if (!isset($_POST['database_name']) || $_POST['database_name'] == '') 
{
	set_error('Please enter a database name');
} 
else 
{
	$database_name = $_POST['database_name'];
}
// Get table prefix
// Find out if the user wants to install tables and data
if (isset($_POST['install_tables']) && $_POST['install_tables'] == 'true') 
{
	$install_tables = true;
} 
else 
{
	$install_tables = false;
}
// End database details code

// Begin company name code
// Get company name
if (!isset($_POST['company_name']) || $_POST['company_name'] == '') 
{
	set_error('Please enter a company name');
} 
else 
{
	$company_name = add_slashes($_POST['company_name']);
}
// End website company name

// Check if the user has entered a correct path
if (!file_exists(accounting_scheme())) 
{
	set_error('It appears the accounting scheme does not exist');
}

// Get admin email and validate it
if (!isset($_POST['admin_email']) || $_POST['admin_email'] == '') 
{
	set_error('Please enter an email for the Administrator account');
} 
else 
{
	if (eregi("^([0-9a-zA-Z]+[-._+&])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,6}$", $_POST['admin_email'])) 
	{
		$admin_email = $_POST['admin_email'];
	} 
	else 
	{
		set_error('Please enter a valid email address for the Administrator account');
	}
}
// Get the two admin passwords entered, and check that they match
if (!isset($_POST['admin_password']) || $_POST['admin_password'] == '') 
{
	set_error('Please enter a password for the Administrator account');
} 
else 
{
	$admin_password = $_POST['admin_password'];
}
if (!isset($_POST['admin_repassword']) || $_POST['admin_repassword'] == '') 
{
	set_error('Please make sure you re-enter the password for the Administrator account');
} 
else 
{
	$admin_repassword = $_POST['admin_repassword'];
}
if ($admin_password != $admin_repassword) 
{
	set_error('Sorry, the two Administrator account passwords you entered do not match');
}
// End admin user details code

include_once($path_to_root . "/includes/db/connect_db.inc");
include_once($path_to_root . "/admin/db/maintenance_db.inc");
include_once($path_to_root . "/config_db.php");

$id = count($db_connections);

$db_connections[$id]['name'] = $company_name;
$db_connections[$id]['host'] = $database_host;
$db_connections[$id]['dbuser'] = $database_username;
$db_connections[$id]['dbpassword'] = $database_password;
$db_connections[$id]['dbname'] = $database_name;

$def_coy = $id;

$config_filename = $path_to_root . '/config_db.php';

$err = write_config_db();
if ($err == -1)
	set_error("Cannot open the configuration file ($config_filename)");
else if ($err == -2)	
	set_error("Cannot write to the configuration file ($config_filename)");
else if ($err == -3) 
	set_error("The configuration file $config_filename is not writable. Change its permissions so it is, then re-run step 4.");

// Try connecting to database	

$db = mysql_connect($database_host, $database_username, $database_password);
if (!$db)
{
	set_error('Database host name, username and/or password incorrect. MySQL Error:<br />'.mysql_error());
}

if($install_tables == true) 
{
   	if (!mysql_select_db($database_name, $db))
   	{

		// Try to create the database
		mysql_query('CREATE DATABASE '.$database_name);
		mysql_select_db($database_name, $db);
	}	
	// we use swiss german and don't overwrite non existing tables
	$import_filename = accounting_scheme();
	if (!db_import($import_filename, $db_connections[$id],1))
		set_error("Import error, try to import $import_filename manually via phpMyAdmin");
}
else
{
	mysql_select_db($database_name, $db);
}
$sql = "UPDATE users SET password = '" . md5($admin_password) . "', email = ".db_escape($admin_email)." WHERE user_id = 'admin'";
db_query($sql, "could not update admin account");
$sql = "UPDATE company SET coy_name = ".db_escape($company_name)." WHERE coy_code = 1";
db_query($sql, "could not update company name. Do it manually later in Setup");

session_unset();
session_destroy();
$_SESSION = array(); 

header("Location: ".$path_to_root."/index.php");
exit();

?>
