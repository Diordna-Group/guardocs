<?php

$page_security = 3;
$path_to_root="..";
include_once($path_to_root . "/includes/ui/items_cart.inc");
include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/gl/includes/ui/gl_deposit_ui.inc");
include_once($path_to_root . "/gl/includes/gl_db.inc");
include_once($path_to_root . "/gl/includes/gl_ui.inc");

$js = '';
if ($use_popup_windows)
	$js .= get_js_open_window(800, 500);
if ($use_date_picker)
	$js .= get_js_date_picker();
set_focus('CodeID2');
page(tr("Bank Account Deposit Entry"), false, false, '', $js);

//-----------------------------------------------------------------------------------------------

check_db_has_bank_accounts(tr("There are no bank accounts defined in the system."));

check_db_has_bank_trans_types(tr("There are no bank payment types defined in the system."));

//-----------------------------------------------------------------------------------------------

if (isset($_GET['AddedID'])) 
{
	$trans_no = $_GET['AddedID'];
	$trans_type = systypes::bank_deposit();

   	display_notification_centered(tr("Deposit has been entered"));

	display_note(get_gl_view_str($trans_type, $trans_no, tr("View the GL Postings for this Deposit")));

	hyperlink_no_params($_SERVER['PHP_SELF'], tr("Enter Another Deposit"));

	display_footer_exit();
}

//--------------------------------------------------------------------------------------------------

function copy_to_py()
{
	$_SESSION['deposit_items']->from_loc = $_POST['bank_account'];
	$_SESSION['deposit_items']->tran_date = $_POST['date_'];
	$_SESSION['deposit_items']->transfer_type = $_POST['type'];
	$_SESSION['deposit_items']->increase = $_POST['PayType'];
	if (!isset($_POST['person_id']))
		$_POST['person_id'] = "";	
	$_SESSION['deposit_items']->person_id = $_POST['person_id'];
	if (!isset($_POST['PersonDetailID']))
		$_POST['PersonDetailID'] = "";
	$_SESSION['deposit_items']->branch_id = $_POST['PersonDetailID'];
	$_SESSION['deposit_items']->memo_ = $_POST['memo_'];
}

//--------------------------------------------------------------------------------------------------

function copy_from_py()
{
	$_POST['bank_account'] = $_SESSION['deposit_items']->from_loc;
	$_POST['date_'] = $_SESSION['deposit_items']->tran_date;
	$_POST['type'] = $_SESSION['deposit_items']->transfer_type;
	$_POST['PayType'] = $_SESSION['deposit_items']->increase;
	$_POST['person_id'] = $_SESSION['deposit_items']->person_id;
	$_POST['PersonDetailID'] = $_SESSION['deposit_items']->branch_id;
	$_POST['memo_'] = $_SESSION['deposit_items']->memo_;
}

//-----------------------------------------------------------------------------------------------

function handle_new_order()
{
	if (isset($_SESSION['deposit_items']))
	{
		$_SESSION['deposit_items']->clear_items();
		unset ($_SESSION['deposit_items']);
	}

	session_register("deposit_items");

	$_SESSION['deposit_items'] = new items_cart;
	$_POST['date_'] = Today();
	if (!is_date_in_fiscalyear($_POST['date_']))
		$_POST['date_'] = end_fiscalyear();
	$_SESSION['deposit_items']->tran_date = $_POST['date_'];	
}

//-----------------------------------------------------------------------------------------------

if (isset($_POST['Process']))
{

	$input_error = 0;

	if (!references::is_valid($_POST['ref'])) 
	{
		display_error( tr("You must enter a reference."));
		set_focus('ref');
		$input_error = 1;
	} 
	elseif (!is_new_reference($_POST['ref'], systypes::bank_deposit())) 
	{
		display_error( tr("The entered reference is already in use."));
		set_focus('ref');
		$input_error = 1;
	}

	if (!is_date($_POST['date_'])) 
	{
		display_error(tr("The entered date for the deposit is invalid."));
		set_focus('date_');
		$input_error = 1;
	}

	if (!is_date_in_fiscalyear($_POST['date_']))
	{
		display_error(tr("The entered date is not in fiscal year."));
		set_focus('date_');
		$input_error = 1;
	}

	if ($input_error == 1)
		unset($_POST['Process']);
}

//-----------------------------------------------------------------------------------------------

if (isset($_POST['Process']))
{

	$trans = add_bank_deposit($_POST['bank_account'],
		$_SESSION['deposit_items'], $_POST['date_'],
		$_POST['PayType'], $_POST['person_id'], $_POST['PersonDetailID'],
		$_POST['type'],	$_POST['ref'], $_POST['memo_']);

	$trans_type = $trans[0];
   	$trans_no = $trans[1];

	$_SESSION['deposit_items']->clear_items();
	unset($_SESSION['deposit_items']);

   	meta_forward($_SERVER['PHP_SELF'], "AddedID=$trans_no");

} /*end of process credit note */

//-----------------------------------------------------------------------------------------------

function check_item_data()
{
	if (!check_num('amount', 0))
	{
		display_error( tr("The amount entered is not a valid number or is less than zero."));
		set_focus('amount');
		return false;
	}

	if ($_POST['code_id'] == $_POST['bank_account']) 
	{
		display_error( tr("The source and destination accouts cannot be the same."));
		set_focus('code_id');
		return false;
	}

	if (is_bank_account($_POST['code_id'])) 
	{
		display_error( tr("You cannot make a deposit from a bank account. Please use the transfer funds facility for this."));
		set_focus('code_id');
		return false;
	}

   	return true;
}

//-----------------------------------------------------------------------------------------------

function handle_update_item()
{
    if($_POST['UpdateItem'] != "" && check_item_data())
    {
    	$_SESSION['deposit_items']->update_gl_item($_POST['Index'], $_POST['dimension_id'], 
		  $_POST['dimension2_id'], -input_num('amount'), $_POST['LineMemo']);
    }
}

//-----------------------------------------------------------------------------------------------

function handle_delete_item()
{
	$_SESSION['deposit_items']->remove_gl_item($_GET['Delete']);
}

//-----------------------------------------------------------------------------------------------

function handle_new_item()
{
	if (!check_item_data())
		return;

	$_SESSION['deposit_items']->add_gl_item($_POST['code_id'], $_POST['dimension_id'], 
	  $_POST['dimension2_id'], -input_num('amount'), $_POST['LineMemo']);
}

//-----------------------------------------------------------------------------------------------

if (isset($_GET['Delete']) || isset($_GET['Edit']))
	copy_from_py();

if (isset($_GET['Delete']))
	handle_delete_item();

if (isset($_POST['AddItem']) || isset($_POST['UpdateItem']))
	copy_to_py();
	
if (isset($_POST['AddItem']))
	handle_new_item();

if (isset($_POST['UpdateItem']))
	handle_update_item();

//-----------------------------------------------------------------------------------------------

if (isset($_GET['NewDeposit']) || !isset($_SESSION['deposit_items']))
{
	handle_new_order();
}

//-----------------------------------------------------------------------------------------------

start_form(false, true);

display_order_header($_SESSION['deposit_items']);

start_table("$table_style width=90%", 10);
start_row();
echo "<td>";
display_gl_items(tr("Deposit Items"), $_SESSION['deposit_items']);
gl_options_controls();
echo "</td>";
end_row();
end_table(1);

if (!isset($_POST['Process']))
{
    submit_center_first('Update', tr("Update"));
	if ($_SESSION['deposit_items']->count_gl_items() >= 1)
	    submit_center_last('Process', tr("Process Deposit"));
}

end_form();

//------------------------------------------------------------------------------------------------

end_page();

?>
