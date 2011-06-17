<?php

$page_security = 3;
$path_to_root="..";
include_once($path_to_root . "/includes/ui/items_cart.inc");

include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/manufacturing/includes/manufacturing_db.inc");
include_once($path_to_root . "/manufacturing/includes/manufacturing_ui.inc");
include_once($path_to_root . "/manufacturing/includes/work_order_issue_ui.inc");
$js = "";
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Issue Items to Work Order"), false, false, "", $js);

//-----------------------------------------------------------------------------------------------

if (isset($_GET['AddedID'])) 
{
   	echo "<center>" . tr("The work order issue has been entered.");
   	echo "<br>";
   	hyperlink_no_params("search_work_orders.php", tr("Select another Work Order to Process"));
   	echo "<br><br>";
   	end_page();
   	exit;
}

//--------------------------------------------------------------------------------------------------

function handle_new_order()
{
	if (isset($_SESSION['issue_items']))
	{
		$_SESSION['issue_items']->clear_items();
		unset ($_SESSION['issue_items']);
	}

     Session_register("issue_items");

     $_SESSION['issue_items'] = new items_cart;
     $_SESSION['issue_items']->order_id = $_GET['trans_no'];
}

//-----------------------------------------------------------------------------------------------

function can_process()
{
	if (!is_date($_POST['date_'])) 
	{
		display_error(tr("The entered date for the issue is invalid."));
		set_focus('date_');
		return false;
	} 
	elseif (!is_date_in_fiscalyear($_POST['date_'])) 
	{
		display_error(tr("The entered date is not in fiscal year."));
		set_focus('date_');
		return false;
	}
	if (!references::is_valid($_POST['ref'])) 
	{
		display_error(tr("You must enter a reference."));
		set_focus('ref');
		return false;
	}

	if (!is_new_reference($_POST['ref'], 28)) 
	{
		display_error(tr("The entered reference is already in use."));
		set_focus('ref');
		return false;
	}

	$failed_item = $_SESSION['issue_items']->check_qoh($_POST['Location'], $_POST['date_'], !$_POST['IssueType']);
	if ($failed_item != null) 
	{
    	display_error( tr("The issue cannot be processed because an entered item would cause a negative inventory balance :") .
    		" " . $failed_item->stock_id . " - " .  $failed_item->item_description);
		return false;
	}

	return true;
}

if (isset($_POST['Process']))
{

	// if failed, returns a stockID
	$failed_data = add_work_order_issue($_SESSION['issue_items']->order_id,
		$_POST['ref'], $_POST['IssueType'], $_SESSION['issue_items']->line_items,
		$_POST['Location'], $_POST['WorkCentre'], $_POST['date_'], $_POST['memo_']);

	if ($failed_data != null) 
	{
		display_error(tr("The process cannot be completed because there is an insufficient total quantity for a component.") . "<br>"
		. tr("Component is :"). $failed_data[0] . "<br>"
		. tr("From location :"). $failed_data[1] . "<br>");
	} 
	else 
	{
		meta_forward($_SERVER['PHP_SELF'], "AddedID=1");
	}

} /*end of process credit note */

//-----------------------------------------------------------------------------------------------

function check_item_data()
{
	if (!is_numeric($_POST['qty']))
	{
		display_error(tr("The quantity entered is not a valid number."));
		set_focus('qty');
		return false;
	}

	if ($_POST['qty'] <= 0)
	{
		display_error(tr("The quantity entered must be greater than zero."));
		set_focus('qty');
		return false;
	}

	if (!is_numeric($_POST['std_cost']) || $_POST['std_cost'] < 0)
	{
		display_error(tr("The entered standard cost is negative or invalid."));
		set_focus('std_cost');
		return false;
	}

   	return true;
}

//-----------------------------------------------------------------------------------------------

function handle_update_item()
{
    if($_POST['UpdateItem'] != "" && check_item_data())
    {
    	$_SESSION['issue_items']->update_cart_item($_POST['stock_id'], $_POST['qty'], $_POST['std_cost']);
    }
}

//-----------------------------------------------------------------------------------------------

function handle_delete_item()
{
	$_SESSION['issue_items']->remove_from_cart($_GET['Delete']);
}

//-----------------------------------------------------------------------------------------------

function handle_new_item()
{
	if (!check_item_data())
		return;

	add_to_order($_SESSION['issue_items'], $_POST['stock_id'], $_POST['qty'], $_POST['std_cost']);
}

//-----------------------------------------------------------------------------------------------

if ($_GET['Delete']!="")
	handle_delete_item();

if ($_POST['AddItem']!="")
	handle_new_item();

if ($_POST['UpdateItem']!="")
	handle_update_item();

//-----------------------------------------------------------------------------------------------

if (isset($_GET['trans_no']))
{
	handle_new_order();
}

//-----------------------------------------------------------------------------------------------

display_order_header($_SESSION['issue_items']);

start_form(false, true);

start_table("$table_style width=90%", '10');
echo "<tr><td>";
display_adjustment_items(tr("Items to Issue"), $_SESSION['issue_items']);
adjustment_options_controls();
echo "</td></tr>";

end_table();

if (!isset($_POST['Process']))
{
	start_table();
    start_row();
    submit_cells('Update', tr("Update"));
	if ($_SESSION['issue_items']->count_items() >= 1)
	{
	    submit_cells('Process', tr("Process Issue"));
	}
	end_row();
	end_table();
}

end_form();

//------------------------------------------------------------------------------------------------

end_page();

?>
