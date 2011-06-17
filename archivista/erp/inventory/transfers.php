<?php

$page_security = 3;
$path_to_root="..";
include_once($path_to_root . "/includes/ui/items_cart.inc");

include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/inventory/includes/stock_transfers_ui.inc");
include_once($path_to_root . "/inventory/includes/inventory_db.inc");
$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(800, 500);
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Inventory Location Transfers"), false, false, "", $js);


//-----------------------------------------------------------------------------------------------

check_db_has_costable_items(tr("There are no inventory items defined in the system (Purchased or manufactured items)."));

check_db_has_movement_types(tr("There are no inventory movement types defined in the system. Please define at least one inventory adjustment type."));

//-----------------------------------------------------------------------------------------------

if (isset($_GET['AddedID'])) 
{
	$trans_no = $_GET['AddedID'];
	$trans_type = systypes::location_transfer();

	display_notification_centered(tr("Inventory transfer has been processed"));
	display_note(get_trans_view_str($trans_type, $trans_no, tr("View this transfer")));

	hyperlink_no_params($_SERVER['PHP_SELF'], tr("Enter Another Inventory Transfer"));

	display_footer_exit();
}

//--------------------------------------------------------------------------------------------------

function copy_to_st()
{
	$_SESSION['transfer_items']->from_loc = $_POST['FromStockLocation'];
	$_SESSION['transfer_items']->to_loc = $_POST['ToStockLocation'];
	$_SESSION['transfer_items']->tran_date = $_POST['AdjDate'];
	$_SESSION['transfer_items']->transfer_type = $_POST['type'];
	$_SESSION['transfer_items']->memo_ = $_POST['memo_'];
}

//--------------------------------------------------------------------------------------------------

function copy_from_st()
{
	$_POST['FromStockLocation'] = $_SESSION['transfer_items']->from_loc;
	$_POST['ToStockLocation'] = $_SESSION['transfer_items']->to_loc;
	$_POST['AdjDate'] = $_SESSION['transfer_items']->tran_date;
	$_POST['type'] = $_SESSION['transfer_items']->transfer_type;
	$_POST['memo_'] = $_SESSION['transfer_items']->memo_;
}

//-----------------------------------------------------------------------------------------------

function handle_new_order()
{
	if (isset($_SESSION['transfer_items']))
	{
		$_SESSION['transfer_items']->clear_items();
		unset ($_SESSION['transfer_items']);
	}

    session_register("transfer_items");

	$_SESSION['transfer_items'] = new items_cart;
	$_POST['AdjDate'] = Today();
	if (!is_date_in_fiscalyear($_POST['AdjDate']))
		$_POST['AdjDate'] = end_fiscalyear();
	$_SESSION['transfer_items']->tran_date = $_POST['AdjDate'];	
}

//-----------------------------------------------------------------------------------------------

if (isset($_POST['Process']))
{

	$input_error = 0;

	if (!references::is_valid($_POST['ref'])) 
	{
		display_error(tr("You must enter a reference."));
		set_focus('ref');
		$input_error = 1;
	} 
	elseif (!is_new_reference($_POST['ref'], systypes::location_transfer())) 
	{
		display_error(tr("The entered reference is already in use."));
		set_focus('ref');
		$input_error = 1;
	} 
	elseif (!is_date($_POST['AdjDate'])) 
	{
		display_error(tr("The entered date for the adjustment is invalid."));
		set_focus('AdjDate');
		$input_error = 1;
	} 
	elseif (!is_date_in_fiscalyear($_POST['AdjDate'])) 
	{
		display_error(tr("The entered date is not in fiscal year."));
		set_focus('AdjDate');
		$input_error = 1;
	} 
	elseif ($_POST['FromStockLocation'] == $_POST['ToStockLocation'])
	{
		display_error(tr("The locations to transfer from and to must be different."));
		set_focus('FromStockLocation');
		$input_error = 1;
	} 
	else 
	{
		$failed_item = $_SESSION['transfer_items']->check_qoh($_POST['FromStockLocation'], $_POST['AdjDate'], true);
		if ($failed_item != null) 
		{
        	display_error(tr("The quantity entered is greater than the available quantity for this item at the source location :") .
        		" " . $failed_item->stock_id . " - " .  $failed_item->item_description);
        	echo "<br>";
			$input_error = 1;
		}
	}

	if ($input_error == 1)
		unset($_POST['Process']);
}

//-------------------------------------------------------------------------------

if (isset($_POST['Process']))
{

	$trans_no = add_stock_transfer($_SESSION['transfer_items']->line_items,
		$_POST['FromStockLocation'], $_POST['ToStockLocation'],
		$_POST['AdjDate'], $_POST['type'], $_POST['ref'], $_POST['memo_']);

	$_SESSION['transfer_items']->clear_items();
	unset($_SESSION['transfer_items']);

   	meta_forward($_SERVER['PHP_SELF'], "AddedID=$trans_no");
} /*end of process credit note */

//-----------------------------------------------------------------------------------------------

function check_item_data()
{
	if (!check_num('qty'))
	{
		display_error( tr("The quantity entered is not a valid number."));
		set_focus('qty');
		return false;
	}

	if (!check_num('qty', 0))
	{
		display_error(tr("The quantity entered must be a positive number."));
		set_focus('qty');
		return false;
	}

   	return true;
}

//-----------------------------------------------------------------------------------------------

function handle_update_item()
{
    if($_POST['UpdateItem'] != "" && check_item_data())
    {
    	if (!isset($_POST['std_cost']))
    		$_POST['std_cost'] = $_SESSION['transfer_items']->line_items[$_POST['stock_id']]->standard_cost;
    	$_SESSION['transfer_items']->update_cart_item($_POST['stock_id'], input_num('qty'), $_POST['std_cost']);
    }
}

//-----------------------------------------------------------------------------------------------

function handle_delete_item()
{
	$_SESSION['transfer_items']->remove_from_cart($_GET['Delete']);
}

//-----------------------------------------------------------------------------------------------

function handle_new_item()
{
	if (!check_item_data())
		return;
	if (!isset($_POST['std_cost']))
   		$_POST['std_cost'] = 0;
	add_to_order($_SESSION['transfer_items'], $_POST['stock_id'], input_num('qty'), $_POST['std_cost']);
}

//-----------------------------------------------------------------------------------------------

if (isset($_GET['Delete']) || isset($_GET['Edit']))
	copy_from_st();

if (isset($_GET['Delete']))
	handle_delete_item();

if (isset($_POST['AddItem']) || isset($_POST['UpdateItem']))
	copy_to_st();
	
if (isset($_POST['AddItem']))
	handle_new_item();

if (isset($_POST['UpdateItem']))
	handle_update_item();

//-----------------------------------------------------------------------------------------------

if (isset($_GET['NewTransfer']) || !isset($_SESSION['transfer_items']))
{
	handle_new_order();
}

//-----------------------------------------------------------------------------------------------

start_form(false, true);

display_order_header($_SESSION['transfer_items']);

start_table("$table_style width=70%", 10);
start_row();
echo "<td>";
display_transfer_items(tr("Items"), $_SESSION['transfer_items']);
transfer_options_controls();
echo "</td>";
end_row();
end_table(1);

if (!isset($_POST['Process']))
{
	if ($_SESSION['transfer_items']->count_items() >= 1)
	{
    	submit_center_first('Update', tr("Update"));
	    submit_center_last('Process', tr("Process Transfer"));
	}
	else
    	submit_center('Update', tr("Update"));
}
end_form();
end_page();

?>
