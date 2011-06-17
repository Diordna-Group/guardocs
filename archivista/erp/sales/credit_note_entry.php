<?php
//---------------------------------------------------------------------------
//
//	Entry/Modify free hand Credit Note
//
$page_security = 3;
$path_to_root="..";
include_once($path_to_root . "/sales/includes/cart_class.inc");
include_once($path_to_root . "/includes/session.inc");
include_once($path_to_root . "/includes/data_checks.inc");
include_once($path_to_root . "/sales/includes/sales_db.inc");
include_once($path_to_root . "/sales/includes/sales_ui.inc");
include_once($path_to_root . "/sales/includes/ui/sales_credit_ui.inc");
include_once($path_to_root . "/sales/includes/ui/sales_order_ui.inc");

$js = "";
if ($use_popup_windows) {
	$js .= get_js_open_window(900, 500);
}
if ($use_date_picker) {
	$js .= get_js_date_picker();
}

if(isset($_GET['NewCredit'])) {
	$_SESSION['page_title'] = tr("Customer Credit Note");
	handle_new_credit(0);
} elseif (isset($_GET['ModifyCredit'])) {
	$_SESSION['page_title'] = sprintf(tr("Modifying Customer Credit Note #%d"), $_GET['ModifyCredit']);
	handle_new_credit($_GET['ModifyCredit']);
	$help_page_title = tr("Modifying Customer Credit Note");
}

page($_SESSION['page_title'],false, false, "", $js);

//-----------------------------------------------------------------------------

check_db_has_stock_items(tr("There are no items defined in the system."));

check_db_has_customer_branches(tr("There are no customers, or there are no customers with branches. Please define customers and customer branches."));

//-----------------------------------------------------------------------------

if (isset($_GET['AddedID'])) {
	$credit_no = $_GET['AddedID'];
	$trans_type = 11;

	display_notification_centered(sprintf(tr("Credit Note # %d has been processed"),$credit_no));

	display_note(get_customer_trans_view_str($trans_type, $credit_no, tr("View this credit note")), 0, 1);

	display_note(get_gl_view_str($trans_type, $credit_no, tr("View the GL Journal Entries for this Credit Note")));

	hyperlink_params($_SERVER['PHP_SELF'], tr("Enter Another Credit Note"), "NewCredit=yes");

	display_footer_exit();
}
//--------------------------------------------------------------------------------

function line_start_focus() {
  set_focus(get_company_pref('no_supplier_list') ? 'stock_id_edit' : 'StockID2');
}

//-----------------------------------------------------------------------------

function copy_to_cn()
{
	$_SESSION['Items']->Comments = $_POST['CreditText'];
	$_SESSION['Items']->document_date = $_POST['OrderDate'];
	$_SESSION['Items']->freight_cost = input_num('ChargeFreightCost');
	$_SESSION['Items']->Location = $_POST["Location"];
	$_SESSION['Items']->sales_type = $_POST['sales_type_id'];
	$_SESSION['Items']->reference = $_POST['ref'];
	$_SESSION['Items']->ship_via = $_POST['ShipperID'];
}

//-----------------------------------------------------------------------------

function copy_from_cn()
{
	$_POST['CreditText'] = $_SESSION['Items']->Comments;
	$_POST['OrderDate'] = $_SESSION['Items']->document_date;
	$_POST['ChargeFreightCost'] = price_format($_SESSION['Items']->freight_cost);
	$_POST['Location'] = $_SESSION['Items']->Location;
	$_POST['sales_type_id'] = $_SESSION['Items']->sales_type;
	$_POST['ref'] = $_SESSION['Items']->reference;
	$_POST['ShipperID'] = $_SESSION['Items']->ship_via;
}

//-----------------------------------------------------------------------------

function handle_new_credit($trans_no)
{
	processing_start();
	$_SESSION['Items'] = new Cart(11,$trans_no);
	copy_from_cn();
}

//-----------------------------------------------------------------------------

function can_process()
{

	$input_error = 0;

	if ($_SESSION['Items']->count_items() == 0 && (!check_num('ChargeFreightCost',0)))
		return false;
	if($_SESSION['Items']->trans_no == 0) {
	    if (!references::is_valid($_POST['ref'])) {
		display_error( tr("You must enter a reference."));
		set_focus('ref');
		$input_error = 1;
	    } elseif (!is_new_reference($_POST['ref'], 11))	{
		display_error( tr("The entered reference is already in use."));
		set_focus('ref');
		$input_error = 1;
	    } 
	}
	if (!is_date($_POST['OrderDate'])) {
		display_error(tr("The entered date for the credit note is invalid."));
		set_focus('OrderDate');
		$input_error = 1;
	} elseif (!is_date_in_fiscalyear($_POST['OrderDate'])) {
		display_error(tr("The entered date is not in fiscal year."));
		set_focus('OrderDate');
		$input_error = 1;
	}
	return ($input_error == 0);
}

//-----------------------------------------------------------------------------

if (isset($_POST['ProcessCredit']) && can_process()) {
	if ($_POST['CreditType'] == "WriteOff" && (!isset($_POST['WriteOffGLCode']) ||
		$_POST['WriteOffGLCode'] == '')) {
		display_note(tr("For credit notes created to write off the stock, a general ledger account is required to be selected."), 1, 0);
		display_note(tr("Please select an account to write the cost of the stock off to, then click on Process again."), 1, 0);
		exit;
	}
	if (!isset($_POST['WriteOffGLCode'])) {
		$_POST['WriteOffGLCode'] = 0;
	}
	$credit_no = $_SESSION['Items']->write($_POST['WriteOffGLCode']);
	processing_end();
	meta_forward($_SERVER['PHP_SELF'], "AddedID=$credit_no");

} /*end of process credit note */

  //-----------------------------------------------------------------------------

function check_item_data()
{
	if (!check_num('qty',0)) {
		display_error(tr("The quantity must be greater than zero."));
		set_focus('qty');
		return false;
	}
	if (!check_num('price',0)) {
		display_error(tr("The entered price is negative or invalid."));
		set_focus('price');
		return false;
	}
	if (!check_num('Disc', 0, 100)) {
		display_error(tr("The entered discount percent is negative, greater than 100 or invalid."));
		set_focus('Disc');
		return false;
	}
	return true;
}

//-----------------------------------------------------------------------------

function handle_update_item()
{
	if ($_POST['UpdateItem'] != "" && check_item_data()) {
		$_SESSION['Items']->update_cart_item($_POST['line_no'], input_num('qty'),
			input_num('price'), input_num('Disc') / 100);
	}
    line_start_focus();
}

//-----------------------------------------------------------------------------

function handle_delete_item($line_no)
{
	$_SESSION['Items']->remove_from_cart($line_no);
    line_start_focus();
}

//-----------------------------------------------------------------------------

function handle_new_item()
{

	if (!check_item_data())
		return;

	add_to_order($_SESSION['Items'], $_POST['stock_id'], input_num('qty'),
		input_num('price'), input_num('Disc') / 100);
    line_start_focus();
}
//-----------------------------------------------------------------------------
$id = find_submit('Delete');
if ($id!=-1)
	handle_delete_item($id);

if (isset($_POST['AddItem']) || isset($_POST['UpdateItem']))
	copy_to_cn();

if (isset($_POST['AddItem']))
	handle_new_item();

if (isset($_POST['UpdateItem']))
	handle_update_item();

if (isset($_POST['CancelItemChanges']) || isset($_POST['UpdateItem']))
	line_start_focus();

//-----------------------------------------------------------------------------

if (!processing_active()) {
	handle_new_credit();
} else {
	if (!isset($_POST['customer_id']))
		$_POST['customer_id'] = $_SESSION['Items']->customer_id;
	if (!isset($_POST['branch_id']))
		$_POST['branch_id'] = $_SESSION['Items']->Branch;
}

//-----------------------------------------------------------------------------

start_form(false, true);

$customer_error = display_credit_header($_SESSION['Items']);

if ($customer_error == "") {
	start_table("$table_style width=80%", 10);
	echo "<tr><td>";
	display_credit_items(tr("Credit Note Items"), $_SESSION['Items']);
	credit_options_controls();
	echo "</td></tr>";
	end_table();
} else {
	display_error($customer_error);
}

echo "<br><center><table><tr>";
submit_cells('Update', tr("Update"));
submit_cells('ProcessCredit', tr("Process Credit Note"));
echo "</tr></table>";

end_form();
end_page();

?>
