<?php
error_reporting(E_ALL);
ini_set("display_errors", "On");
// Start a session
if(!defined('SESSION_STARTED'))
{
	session_name('ba_session_id');
	session_start();
	define('SESSION_STARTED', true);
}

// Check if the page has been reloaded
if(!isset($_GET['sessions_checked']) || $_GET['sessions_checked'] != 'true')
{
	// Set session variable
	$_SESSION['session_support'] = '<font class="good">Enabled</font>';
	// Reload page
	header('Location: index.php?sessions_checked=true');
	exit(0);
}
else
{
	// Check if session variable has been saved after reload
	if(isset($_SESSION['session_support']))
	{
		$session_support = $_SESSION['session_support'];
	}
	else
	{
		$session_support = '<font class="bad">Disabled</font>';
	}
}
$path_to_root = "..";
//include_once($path_to_root.'/config.php');
$comp_path = $path_to_root."/company";

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>ArchivistaERP Installation Wizard</title>
<link href="stylesheet.css" rel="stylesheet" type="text/css">
</head>
<body>

<?php 
  if (!file_exists('/etc/erp.conf')) {
    echo "<h3>&nbsp;&nbsp;Please first enable ArchivistaERP!</h3>";
	  echo "</body></html>";
	  exit;
	}
?>

<table cellpadding="0" cellspacing="0" border="0" width="750" align="center">
<tr>
	<td width="100%" align="center" style="font-size: 20px;">
		<font style="color: #FFFFFF;">ArchivistaERP</font>
		<font style="color: #DDDDDD;">Installation Wizard</font>
	</td>
</tr>
</table>

<form name="archivistaerp_installation_wizard" action="save.php" method="post">
<input type="hidden" name="url" value="" />
<input type="hidden" name="password_fieldname" value="admin_password" />
<input type="hidden" name="remember" id="remember" value="true" />
<input type="hidden" name="path_to_root" value="<?php echo $path_to_root; ?>" />

<table cellpadding="0" cellspacing="0" border="0" width="750" align="center" style="margin-top: 10px;">
<tr>
	<td class="content">
			<h2>Welcome to the ArchivistaERP Installation Wizard.</h2>
		<center>
			<img src="<?php echo $path_to_root; ?>/themes/default/images/logo_archivistaerp.png" alt="Logo" />
		</center>


		<?php
		if(isset($_SESSION['message']) AND $_SESSION['message'] != '') {
			?><div style="width: 700px; padding: 10px; margin-bottom: 5px; border: 1px solid #FF0000; background-color: #FFDBDB;"><b>Error:</b> <?php echo $_SESSION['message']; ?></div><?php
		}
		?>
		<?php
				// Try to guess installation URL
				$guessed_url = 'http://'.$_SERVER["SERVER_NAME"].$_SERVER["SCRIPT_NAME"];
				$guessed_url = rtrim(dirname($guessed_url), 'install');
				?>
				<input type="hidden" tabindex="1" name="ba_url" style="width: 99%;" value="<?php if(isset($_SESSION['ba_url'])) { echo $_SESSION['ba_url']; } else { echo $guessed_url; } ?> ">
		
 		<table cellpadding="5" cellspacing="0" width="100%" align="center">
		<tr>
			<td colspan="5">Please enter the database name and the root password:</td>
		</tr>
		<tr>
			<td style="color: #666666;">Database Name:</td>
			<td>
				<input type="text" tabindex="8" name="database_name" style="width: 98%;" value="<?php if(isset($_SESSION['database_name'])) { echo $_SESSION['database_name']; } else { echo 'archivistaerp'; } ?>" />
			</td>
			<td>&nbsp;</td>
			<td style="color: #666666;">Password:</td>
			<td>
				<input type="password" tabindex="10" name="database_password" style="width: 98%;"<?php if(isset($_SESSION['database_password'])) { echo ' value = "'.$_SESSION['database_password'].'"'; } ?> />
			</td>
		</tr>
		<tr>
			<td style="color: #666666;" colspan="1">Company Name:</td>
			<td>
				<input type="text" tabindex="13" name="company_name" style="width: 99%;" value="<?php if(isset($_SESSION['company_name'])) { echo $_SESSION['company_name']; } else { echo 'Training Co.'; } ?>" />
			</td>
			<td>&nbsp;</td>
			<td style="color: #666666;">Accounting scheme:</td>
			<td>
				<select tabindex="14" name="admin_accounting" style="width: 98%;"<?php if(isset($_SESSION['admin_accounting'])) { echo ' value = "'.$_SESSION['admin_accounting'].'"'; } ?> />
        <option>en_US-new.sql				
				<option>en_US-demo.sql
				<option selected>de_CH-new.sql
				</select>
			</td>
		</tr>
		<tr>
			<td style="color: #666666;">Username:</td>
			<td>
				admin
			</td>
			<td>&nbsp;</td>
			<td style="color: #666666;">Password:</td>
			<td>
				<input type="password" tabindex="16" name="admin_password" style="width: 98%;"<?php if(isset($_SESSION['admin_password'])) { echo ' value = "'.$_SESSION['admin_password'].'"'; } ?> />
			</td>
		</tr>
		<tr>
			<td style="color: #666666;">Email:</td>
			<td>
				<input type="text" tabindex="15" name="admin_email" style="width: 98%;"<?php if(isset($_SESSION['admin_email'])) { echo ' value = "'.$_SESSION['admin_email'].'"'; } ?> />
			</td>
			<td>&nbsp;</td>
			<td style="color: #666666;">Re-Password:</td>
			<td>
				<input type="password" tabindex="17" name="admin_repassword" style="width: 98%;"<?php if(isset($_SESSION['admin_password'])) { echo ' value = "'.$_SESSION['admin_password'].'"'; } ?> />
			</td>
		</tr>

		<tr>
			<td colspan="5" style="padding: 10px; padding-bottom: 0;"><h1 style="font-size: 0px;">&nbsp;</h1></td>
		</tr>
		<tr>
			<td colspan="4">
				<table cellpadding="0" cellspacing="0" width="100%" border="0">
				<tr valign="top">
					<td>Please note: &nbsp;</td>
					<td>
						ArchivistaERP is released under the
						<a href="http://www.gnu.org/licenses/gpl.html" target="_blank" tabindex="19">GNU General Public License</a>
						<br />
						By clicking install, you are accepting the license.
					</td>
				</tr>
				</table>
			</td>
			<td colspan="1" align="right">
				<input type="submit" tabindex="20" name="submit" value="Install ArchivistaERP Accounting" class="submit" />
			</td>
		</tr>
		</table>

	</td>
</tr>
</table>

</form>

<table cellpadding="0" cellspacing="0" border="0" width="100%" style="padding: 10px 0px 10px 0px;">
<tr>
	<td align="center" style="font-size: 10px;">
		<!-- Please note: the below reference to the GNU GPL should not be removed, as it provides a link for users to read about warranty, etc. -->
		<a href="http://www.archivista.ch/" style="color: #000000;"
		target="_blank">ArchivistaERP</a> is	released under the
		<a href="http://www.gnu.org/licenses/gpl.html" style="color: #000000;" target="_blank">GNU General Public License</a>
		<!-- Please note: the above reference to the GNU GPL should not be removed, as it provides a link for users to read about warranty, etc. -->
	</td>
</tr>
</table>

</body>
</html>
