<?php

$page_security = 15;
$path_to_root="..";
include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/admin/db/company_db.inc");
include_once($path_to_root . "/admin/db/maintenance_db.inc");
include_once($path_to_root . "/includes/ui.inc");

page(tr("Create/Update Company"));

$comp_subdirs = array('images', 'pdf_files', 'backup','js_cache', 'reporting');

//---------------------------------------------------------------------------------------------

if (isset($_GET['selected_id']))
{
	$selected_id = $_GET['selected_id'];
}
elseif (isset($_POST['selected_id']))
{
	$selected_id = $_POST['selected_id'];
}
else
	$selected_id = -1;

//---------------------------------------------------------------------------------------------

function check_data()
{
	global $db_connections, $tb_pref_counter;

	foreach($db_connections as $id=>$con) {
	  if ($_POST['host'] == $con['host'] && $_POST['dbname'] == $con['dbname']) {
			return false;
		}
	}
	  return true;
}

//---------------------------------------------------------------------------------------------

function remove_connection($id) {
	global $db_connections;

	$dbase = $db_connections[$id]['dbname'];
	$err = db_drop_db($db_connections[$id]);

	unset($db_connections[$id]);
	$conn = array_values($db_connections);
	$db_connections = $conn;
	//$$db_connections = array_values($db_connections);
    return $err;
}
//---------------------------------------------------------------------------------------------

function handle_submit()
{
	global $db_connections, $def_coy, $tb_pref_counter, $db,
	    $comp_path, $comp_subdirs;

	$new = false;

	if (!check_data())
		return false;

	$id = $_GET['id'];

	$db_connections[$id]['name'] = $_POST['name'];
	$db_connections[$id]['host'] = $_POST['host'];
	$db_connections[$id]['dbuser'] = $_POST['dbuser'];
	$db_connections[$id]['dbpassword'] = $_POST['dbpassword'];
	$db_connections[$id]['dbname'] = $_POST['dbname'];
	if ((bool)$_POST['def'] == true)
		$def_coy = $id;
	if (isset($_GET['ul']) && $_GET['ul'] == 1)
	{
		$conn = $db_connections[$id];
		if (($db = db_create_db($conn)) == 0)
		{
			display_error(tr("Error creating Database: ") . $conn['dbname'] . tr(", Please create it manually"));
			remove_connection($id);
			set_global_connection();
			return false;
		}

		$filename = $_FILES['uploadfile']['tmp_name'];
		if (is_uploaded_file ($filename))
		{
			db_import($filename, $conn, $id);
			if (isset($_POST['admpassword']) && $_POST['admpassword'] != "")
				db_query("UPDATE users set password = '".md5($_POST['admpassword']). "' WHERE user_id = 'admin'");
		}
		else
		{
			display_error(tr("Error uploading Database Script, please upload it manually"));
			set_global_connection();
			return false;
		}
		set_global_connection();
	}
	$error = write_config_db($new);
	if ($error == -1)
		display_error(tr("Cannot open the configuration file - ") . $path_to_root . "/config_db.php");
	else if ($error == -2)
		display_error(tr("Cannot write to the configuration file - ") . $path_to_root . "/config_db.php");
	else if ($error == -3)
		display_error(tr("The configuration file ") . $path_to_root . "/config_db.php" . tr(" is not writable. Change its permissions so it is, then re-run the operation."));
	if ($error != 0)
	{
		return false;
	}
	$index = "<?php\nheader(\"Location: ../../index.php\");\n?>";

	if ($new)
	{
	    $cdir = $comp_path.'/'.$id;
	    @mkdir($cdir);
	    save_to_file($cdir.'/'.'index.php', 0, $index);

	    foreach($comp_subdirs as $dir)
	    {
			@mkdir($cdir.'/'.$dir);
			save_to_file($cdir.'/'.$dir.'/'.'index.php', 0, $index);
	    }
	}
	return true;
}

//---------------------------------------------------------------------------------------------

function handle_delete()
{
	global $comp_path, $def_coy, $db_connections, $comp_subdirs;

	$id = $_GET['id'];

	$err = remove_connection($id);
	if ($err == 0)
		display_error(tr("Error removing Database: ") . $dbase . tr(", please remove it manuallly"));

	if ($def_coy == $id)
		$def_coy = 0;
	$error = write_config_db();
	if ($error == -1)
		display_error(tr("Cannot open the configuration file - ") . $path_to_root . "/config_db.php");
	else if ($error == -2)
		display_error(tr("Cannot write to the configuration file - ") . $path_to_root . "/config_db.php");
	else if ($error == -3)
		display_error(tr("The configuration file ") . $path_to_root . "/config_db.php" . tr(" is not writable. Change its permissions so it is, then re-run the operation."));
	if ($error != 0)
		return;

	$cdir = $comp_path.'/'.$id;
	flush_dir($cdir);
	if (!rmdir($cdir))
	{
		display_error(tr("Cannot remove company data directory ") . $cdir);
		return;
	}

	meta_forward($_SERVER['PHP_SELF']);
}

//---------------------------------------------------------------------------------------------

function display_companies()
{
	global $table_style, $def_coy, $db_connections;

	$coyno = $_SESSION["wa_current_user"]->company;

	echo "
		<script language='javascript'>
		function deleteCompany(id) {
			if (!confirm('" . tr("Are you sure you want to delete company no. ") . "'+id))
				return
			document.location.replace('create_coy.php?c=df&id='+id)
		}
		</script>";
	start_table($table_style);

	$th = array(tr("Company"), tr("Database Host"), tr("Database User"),
		tr("Database Name"), tr("Table Pref"), tr("Default"), "", "");
	table_header($th);

	$k=0;
	$conn = $db_connections;
	$n = count($conn);
	for ($i = 0; $i < $n; $i++)
	{
		if ($i == $def_coy)
			$what = tr("Yes");
		else
			$what = tr("No");
		if ($i == $coyno)
    		start_row("class='stockmankobg'");
    	else
    		alt_table_row_color($k);

		label_cell($conn[$i]['name']);
		label_cell($conn[$i]['host']);
		label_cell($conn[$i]['dbuser']);
		label_cell($conn[$i]['dbname']);
		label_cell($what);
		label_cell("<a href=" . $_SERVER['PHP_SELF']. "?selected_id=" . $i . ">" . tr("Edit") . "</a>");
		if ($i != $coyno)
			label_cell("<a href='javascript:deleteCompany(" . $i . ")'>" . tr("Delete") . "</a>");
		end_row();
	}

	end_table();
    display_note(tr("The marked company is the current company which cannot be deleted."), 0, 0, "class='currentfg'");
}

//---------------------------------------------------------------------------------------------

function display_company_edit($selected_id)
{
	global $def_coy, $db_connections, $tb_pref_counter, $table_style2;

	if ($selected_id != -1)
		$n = $selected_id;
	else
		$n = count($db_connections);

	start_form(true, true);

	echo "
		<script language='javascript'>
		function updateCompany() {
			if (document.forms[0].uploadfile.value!='' && document.forms[0].dbname.value!='') {
				document.forms[0].action='create_coy.php?c=u&ul=1&id=" . $n . "&fn=' + document.forms[0].uploadfile.value
			}
			else {
				document.forms[0].action='create_coy.php?c=u&id=" . $n . "&fn=' + document.forms[0].uploadfile.value
			}
			document.forms[0].submit()
		}
		</script>";

	start_table($table_style2);

	if ($selected_id != -1)
	{
		$conn = $db_connections[$selected_id];
		$_POST['name'] = $conn['name'];
		$_POST['host']  = $conn['host'];
		$_POST['dbuser']  = $conn['dbuser'];
		$_POST['dbpassword']  = $conn['dbpassword'];
		$_POST['dbname']  = $conn['dbname'];
		if ($selected_id == $def_coy)
			$_POST['def'] = true;
		else
			$_POST['def'] = false;
		$_POST['dbcreate']  = false;
		hidden('selected_id', $selected_id);
		hidden('dbpassword', $_POST['dbpassword']);
	}
	else
	text_row_ex(tr("Company"), 'name', 30);
	text_row_ex(tr("Host"), 'host', 30);
	text_row_ex(tr("Database User"), 'dbuser', 30);
	if ($selected_id == -1)
		text_row_ex(tr("Database Password"), 'dbpassword', 30);
	text_row_ex(tr("Database Name"), 'dbname', 30);
	yesno_list_row(tr("Default"), 'def', null, "", "", false);

	start_row();
	label_cell(tr("Database Script"));
	label_cell("<input name='uploadfile' type='file'>");
	end_row();

	text_row_ex(tr("New script Admin Password"), 'admpassword', 20);

	end_table();
	display_note(tr("Choose from Database scripts in SQL folder. No Datase is created without a script."), 0, 1);
	echo "<center><input onclick='javascript:updateCompany()' type='button' style='width:150' value='". tr("Save"). "'>";


	end_form();
}


//---------------------------------------------------------------------------------------------

if (isset($_GET['c']) && $_GET['c'] == 'df')
{

	handle_delete();
}

if (isset($_GET['c']) && $_GET['c'] == 'u')
{
	if (handle_submit())
	{
		meta_forward($_SERVER['PHP_SELF']);
	}
}


//---------------------------------------------------------------------------------------------

display_companies();

hyperlink_no_params($_SERVER['PHP_SELF'], tr("Create a new company"));

display_company_edit($selected_id);

//---------------------------------------------------------------------------------------------

end_page();

?>
