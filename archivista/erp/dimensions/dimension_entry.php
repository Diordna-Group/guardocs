<?php


$page_security = 10;
$path_to_root="..";
include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/manufacturing.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/dimensions/includes/dimensions_db.inc");
include_once($path_to_root . "/dimensions/includes/dimensions_ui.inc");

$js = "";
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Dimension Entry"), false, false, "", $js);

//---------------------------------------------------------------------------------------

if (isset($_GET['trans_no']))
{
	$selected_id = $_GET['trans_no'];
} 
elseif(isset($_POST['selected_id']))
{
	$selected_id = $_POST['selected_id'];
}
else
	$selected_id = -1;
//---------------------------------------------------------------------------------------

if (isset($_GET['AddedID'])) 
{
	$id = $_GET['AddedID'];

	display_notification_centered(tr("The dimension has been entered."));

	safe_exit();
}

//---------------------------------------------------------------------------------------

if (isset($_GET['UpdatedID'])) 
{
	$id = $_GET['UpdatedID'];

	display_notification_centered(tr("The dimension has been updated."));
	safe_exit();
}

//---------------------------------------------------------------------------------------

if (isset($_GET['DeletedID'])) 
{
	$id = $_GET['DeletedID'];

	display_notification_centered(tr("The dimension has been deleted."));
	safe_exit();
}

//---------------------------------------------------------------------------------------

if (isset($_GET['ClosedID'])) 
{
	$id = $_GET['ClosedID'];

	display_notification_centered(tr("The dimension has been closed. There can be no more changes to it.") . " #$id");
	safe_exit();
}

//-------------------------------------------------------------------------------------------------

function safe_exit()
{
	global $path_to_root;

	hyperlink_no_params("", tr("Enter a new dimension"));
	echo "<br>";
	hyperlink_no_params($path_to_root . "/dimensions/inquiry/search_dimensions.php", tr("Select an existing dimension"));
	echo "<br><br>";

	end_page();

	exit;
}

//-------------------------------------------------------------------------------------

function can_process()
{
	global $selected_id;

	if ($selected_id == -1) 
	{

    	if (!references::is_valid($_POST['ref'])) 
    	{
    		display_error( tr("The dimension reference must be entered."));
		set_focus('ref');
    		return false;
    	}

    	if (!is_new_reference($_POST['ref'], systypes::dimension())) 
    	{
    		display_error(tr("The entered reference is already in use."));
		set_focus('ref');
    		return false;
    	}
	}

	if (strlen($_POST['name']) == 0) 
	{
		display_error( tr("The dimension name must be entered."));
		set_focus('name');
		return false;
	}

	if (!is_date($_POST['date_']))
	{
		display_error( tr("The date entered is in an invalid format."));
		set_focus('date_');
		return false;
	}

	if (!is_date($_POST['due_date']))
	{
		display_error( tr("The required by date entered is in an invalid format."));
		set_focus('due_date');
		return false;
	}

	return true;
}

//-------------------------------------------------------------------------------------

if (isset($_POST['ADD_ITEM']) || isset($_POST['UPDATE_ITEM'])) 
{

	if (can_process()) 
	{

		if ($selected_id == -1) 
		{

			$id = add_dimension($_POST['ref'], $_POST['name'], $_POST['type_'], $_POST['date_'], $_POST['due_date'], $_POST['memo_']);

			meta_forward($_SERVER['PHP_SELF'], "AddedID=$id");
		} 
		else 
		{

			update_dimension($selected_id, $_POST['name'], $_POST['type_'], $_POST['date_'], $_POST['due_date'], $_POST['memo_']);

			meta_forward($_SERVER['PHP_SELF'], "UpdatedID=$selected_id");
		}
	}
}

//--------------------------------------------------------------------------------------

if (isset($_POST['delete'])) 
{

	$cancel_delete = false;

	// can't delete it there are productions or issues
	if (dimension_has_payments($selected_id) || dimension_has_deposits($selected_id))
	{
		display_error(tr("This dimension cannot be deleted because it has already been processed."));
		set_focus('ref');
		$cancel_delete = true;
	}

	if ($cancel_delete == false) 
	{ //ie not cancelled the delete as a result of above tests

		// delete
		delete_dimension($selected_id);
		meta_forward($_SERVER['PHP_SELF'], "DeletedID=$selected_id");
	}
}

//-------------------------------------------------------------------------------------

if (isset($_POST['close'])) 
{

	// update the closed flag
	close_dimension($selected_id);
	meta_forward($_SERVER['PHP_SELF'], "ClosedID=$selected_id");
}

//-------------------------------------------------------------------------------------

start_form();

start_table($table_style2);

if ($selected_id != -1)
{
	$myrow = get_dimension($selected_id);

	if (strlen($myrow[0]) == 0) 
	{
		display_error(tr("The dimension sent is not valid."));
		exit;
	}

	// if it's a closed dimension can't edit it
	if ($myrow["closed"] == 1) 
	{
		display_error(tr("This dimension is closed and cannot be edited."));
		exit;
	}

	$_POST['ref'] = $myrow["reference"];
	$_POST['closed'] = $myrow["closed"];
	$_POST['name'] = $myrow["name"];
	$_POST['type_'] = $myrow["type_"];
	$_POST['date_'] = sql2date($myrow["date_"]);
	$_POST['due_date'] = sql2date($myrow["due_date"]);
	$_POST['memo_'] = get_comments_string(systypes::dimension(), $selected_id);

	hidden('ref', $_POST['ref']);

	label_row(tr("Dimension Reference:"), $_POST['ref']);

	hidden('selected_id', $selected_id);
} 
else 
{
	ref_row(tr("Dimension Reference:"), 'ref', references::get_next(systypes::dimension()));
}

text_row_ex(tr("Name") . ":", 'name', 50, 75);

$dim = get_company_pref('use_dimension');

number_list_row(tr("Type"), 'type_', null, 1, $dim);

date_row(tr("Start Date") . ":", 'date_');

date_row(tr("Date Required By") . ":", 'due_date', null, sys_prefs::default_dimension_required_by());

textarea_row(tr("Memo:"), 'memo_', null, 40, 5);

end_table(1);

submit_add_or_update_center($selected_id == -1);

if ($selected_id != -1) 
{
	echo "<br>";

	submit_center_first('close', tr("Close This Dimension"));
	submit_center_last('delete', tr("Delete This Dimension"));
}

end_form();

//--------------------------------------------------------------------------------------------

end_page();

?>
