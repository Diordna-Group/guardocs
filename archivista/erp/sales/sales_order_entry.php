<?php
//-----------------------------------------------------------------------------
//
//	Entry/Modify Sales Order
//	Entry Direct Delivery
//	Entry Direct Invoice
//

$page_security = 1;
$path_to_root="..";

include_once($path_to_root . "/sales/includes/cart_class.inc");
include_once($path_to_root . "/includes/session.inc");
include_once($path_to_root . "/sales/includes/sales_ui.inc");
include_once($path_to_root . "/sales/includes/ui/sales_order_ui.inc");
include_once($path_to_root . "/sales/includes/sales_db.inc");
include_once($path_to_root . "/sales/includes/db/sales_types_db.inc");
include_once($path_to_root . "/reporting/includes/reporting.inc");

$js = '';
if ($use_popup_windows) {
	$js .= get_js_open_window(900, 500);
}
if ($use_date_picker) {
	$js .= get_js_date_picker();
}

if (isset($_GET['NewDelivery']) && is_numeric($_GET['NewDelivery'])) {

	$_SESSION['page_title'] = tr("Direct Sales Delivery");
	create_cart(13, $_GET['NewDelivery']);

} elseif (isset($_GET['NewInvoice']) && is_numeric($_GET['NewInvoice'])) {

	$_SESSION['page_title'] = tr("Direct Sales Invoice");
	create_cart(10, $_GET['NewInvoice']);

} elseif (isset($_GET['ModifyOrderNumber']) && is_numeric($_GET['ModifyOrderNumber'])) {

	$help_page_title = tr('Modifying Sales Order');
	$_SESSION['page_title'] = sprintf( tr("Modifying Sales Order # %d"), $_GET['ModifyOrderNumber']);
	create_cart(30, $_GET['ModifyOrderNumber']);

} elseif (isset($_GET['NewOrder'])) {

	$_SESSION['page_title'] = tr("New Sales Order Entry");
	create_cart(30, 0);
}

page($_SESSION['page_title'], false, false, "", $js);

//-----------------------------------------------------------------------------

if (isset($_GET['AddedID'])) {
	$order_no = $_GET['AddedID'];
	print_hidden_script(30);

	display_notification_centered(sprintf( tr("Order # %d has been entered."),$order_no));

	display_note(get_trans_view_str(30, $order_no, tr("View This Order")));
	echo '<br>';
	display_note(print_document_link($order_no, tr("Print This Order"), true, 30));

	echo '<br>';
	display_note(print_document_link($order_no, tr("Print as Quote"), true, 30, 1));

	hyperlink_params($path_to_root . "/sales/customer_delivery.php",
		tr("Make Delivery Against This Order"), "OrderNumber=$order_no");

	hyperlink_params($_SERVER['PHP_SELF'], tr("Enter a New Order"), "NewOrder=0");

	display_footer_exit();

} elseif (isset($_GET['UpdatedID'])) {
	$order_no = $_GET['UpdatedID'];
	print_hidden_script(30);

	display_notification_centered(sprintf( tr("Order # %d has been updated."),$order_no));

	display_note(get_trans_view_str(30, $order_no, tr("View This Order")));
	echo '<br>';
	display_note(print_document_link($order_no, tr("Print This Order"), true, 30));

	hyperlink_params($path_to_root . "/sales/customer_delivery.php",
		tr("Confirm Order Quantities and Make Delivery"), "OrderNumber=$order_no");

	hyperlink_params($path_to_root . "/sales/inquiry/sales_orders_view.php",
		tr("Select A Different Order"), "OutstandingOnly=1");

	display_footer_exit();

} elseif (isset($_GET['AddedDN'])) {
	$delivery = $_GET['AddedDN'];
	print_hidden_script(13);

	display_notification_centered(sprintf(tr("Delivery # %d has been entered."),$delivery));

	display_note(get_trans_view_str(13, $delivery, tr("View This Delivery")));
	echo '<br>';
	display_note(print_document_link($delivery, tr("Print Delivery Note"), true, 13));

	hyperlink_params($path_to_root . "/sales/customer_invoice.php",
	tr("Make Invoice Against This Delivery"), "DeliveryNumber=$delivery");

	if ((isset($_GET['Type']) && $_GET['Type'] == 1))
	hyperlink_params("inquiry/sales_orders_view.php",
		tr("Enter a New Template Delivery"), "DeliveryTemplates=Yes");
	else
	hyperlink_params($_SERVER['PHP_SELF'], tr("Enter a New Delivery"), "NewDelivery=0");

	display_footer_exit();

} elseif (isset($_GET['AddedDI'])) {
	$invoice = $_GET['AddedDI'];
	print_hidden_script(10);

	display_notification_centered(sprintf(tr("Invoice # %d has been entered."),$invoice));

	display_note(get_trans_view_str(10, $invoice, tr("View This Invoice")));
	echo '<br>';
	display_note(print_document_link($invoice, tr("Print Sales Invoice"), true, 10));

	if ((isset($_GET['Type']) && $_GET['Type'] == 1))
	hyperlink_params("inquiry/sales_orders_view.php",
		tr("Enter a New Template Invoice"), "InvoiceTemplates=Yes");
	else
	hyperlink_params($_SERVER['PHP_SELF'], tr("Enter a New Direct Invoice"), "NewInvoice=0");

	display_footer_exit();
}

//-----------------------------------------------------------------------------

function copy_to_cart()
{
	$cart = &$_SESSION['Items'];

	if ($cart->trans_type!=30) {
		$cart->reference = $_POST['ref'];
	}
	$cart->Comments =  $_POST['Comments'];
	$cart->document_date = $_POST['OrderDate'];
	$cart->due_date = $_POST['delivery_date'];
	$cart->cust_ref = $_POST['cust_ref'];
	$cart->freight_cost = input_num('freight_cost');
	$cart->deliver_to = $_POST['deliver_to'];
	$cart->delivery_address = $_POST['delivery_address'];
	$cart->phone = $_POST['phone'];
	$cart->Location = $_POST['Location'];
	$cart->ship_via = $_POST['ship_via'];

	if (isset($_POST['email']))
		$cart->email =$_POST['email'];
	else
		$cart->email = '';
	$cart->customer_id	= $_POST['customer_id'];
	$cart->Branch = $_POST['branch_id'];
	$cart->sales_type = $_POST['sales_type'];
}

//-----------------------------------------------------------------------------

function copy_from_cart()
{
	$cart = &$_SESSION['Items'];
	if ($cart->trans_type!=30) {
		$_POST['ref'] = $cart->reference;
	}
	$_POST['Comments'] = $cart->Comments;

	$_POST['OrderDate'] = $cart->document_date;
	$_POST['delivery_date'] = $cart->due_date;
	$_POST['cust_ref'] = $cart->cust_ref;
	$_POST['freight_cost'] = price_format($cart->freight_cost);

	$_POST['deliver_to'] = $cart->deliver_to;
	$_POST['delivery_address'] = $cart->delivery_address;
	$_POST['phone'] = $cart->phone;
	$_POST['Location'] = $cart->Location;
	$_POST['ship_via'] = $cart->ship_via;

	$_POST['customer_id'] = $cart->customer_id;
	$_POST['branch_id'] = $cart->Branch;
	$_POST['sales_type'] = $cart->sales_type;
}
//--------------------------------------------------------------------------------

function line_start_focus() {
  set_focus(get_company_pref('no_supplier_list') ? 'stock_id_edit' : 'StockID2');
}
//--------------------------------------------------------------------------------

function can_process() {
	if (!is_date($_POST['OrderDate'])) {
		display_error(tr("The entered date is invalid."));
		set_focus('OrderDate');
		return false;
	}
	if ($_SESSION['Items']->trans_type!=30 && !is_date_in_fiscalyear($_POST['OrderDate'])) {
		display_error(tr("The entered date is not in fiscal year"));
		set_focus('OrderDate');
		return false;
	}
	if (count($_SESSION['Items']->line_items) == 0)	{
		display_error(tr("You must enter at least one non empty item line."));
		set_focus('AddItem');
		return false;
	}
	if (strlen($_POST['deliver_to']) <= 1) {
		display_error(tr("You must enter the person or company to whom delivery should be made to."));
		set_focus('deliver_to');
		return false;
	}
	if (strlen($_POST['delivery_address']) <= 1) {
		display_error( tr("You should enter the street address in the box provided. Orders cannot be accepted without a valid street address."));
		set_focus('delivery_address');
		return false;
	}

	if ($_POST['freight_cost'] == "")
		$_POST['freight_cost'] = price_format(0);

	if (!check_num('freight_cost',0)) {
		display_error(tr("The shipping cost entered is expected to be numeric."));
		set_focus('freight_cost');
		return false;
	}
	if (!is_date($_POST['delivery_date'])) {
		display_error(tr("The delivery date is invalid."));
		set_focus('delivery_date');
		return false;
	}
	if (date1_greater_date2($_SESSION['Items']->document_date, $_POST['delivery_date'])) {
		display_error(tr("The requested delivery date is before the date of the order."));
		set_focus('delivery_date');
		return false;
	}
	if ($_SESSION['Items']->trans_type != 30 && !references::is_valid($_POST['ref'])) {
		display_error(tr("You must enter a reference."));
		set_focus('ref');
		return false;
	}

	return true;
}

//-----------------------------------------------------------------------------

if (isset($_POST['ProcessOrder']) && can_process()) {
	copy_to_cart();

	$modified = ($_SESSION['Items']->trans_no != 0);
	$so_type = $_SESSION['Items']->so_type;

	$_SESSION['Items']->write(1);

	$trans_no = key($_SESSION['Items']->trans_no);
	$trans_type = $_SESSION['Items']->trans_type;

	processing_end();
	if ($modified) {
		meta_forward($_SERVER['PHP_SELF'], "UpdatedID=$trans_no");
	} elseif ($trans_type == 30) {
		meta_forward($_SERVER['PHP_SELF'], "AddedID=$trans_no");
	} elseif ($trans_type == 10) {
		meta_forward($_SERVER['PHP_SELF'], "AddedDI=$trans_no&Type=$so_type");
	} else {
		meta_forward($_SERVER['PHP_SELF'], "AddedDN=$trans_no&Type=$so_type");
	}
}

//--------------------------------------------------------------------------------

function check_item_data()
{

	if (!check_num('qty', 0) || !check_num('Disc', 0, 100)) {
		display_error( tr("The item could not be updated because you are attempting to set the quantity ordered to less than 0, or the discount percent to more than 100."));
		set_focus('qty');
		return false;
	} elseif (!check_num('price', 0)) {
		display_error( tr("Price for item must be entered and can not be less than 0"));
		set_focus('price');
		return false;
	} elseif (isset($_POST['LineNo']) && isset($_SESSION['Items']->line_items[$_POST['LineNo']])
	    && !check_num('qty', $_SESSION['Items']->line_items[$_POST['LineNo']]->qty_done)) {

		set_focus('qty');
		display_error(tr("You attempting to make the quantity ordered a quantity less than has already been delivered. The quantity delivered cannot be modified retrospectively."));
		return false;
	}
	return true;
}

//--------------------------------------------------------------------------------

function handle_update_item()
{
	if ($_POST['UpdateItem'] != '' && check_item_data()) {
		$_SESSION['Items']->update_cart_item($_POST['LineNo'],
		 input_num('qty'), input_num('price'), 
		 input_num('Disc') / 100 ,
		 $_POST['date_from'],$_POST['notes']);
		 $_POST['notes'] = "";
	}
  copy_from_cart();
  line_start_focus();
}

//--------------------------------------------------------------------------------

function handle_delete_item($line_no)
{
    if ($_SESSION['Items']->some_already_delivered($line_no) == 0) {
	$_SESSION['Items']->remove_from_cart($line_no);
    } else {
	display_error(tr("This item cannot be deleted because some of it has already been delivered."));
    }
    line_start_focus();
}

//--------------------------------------------------------------------------------

function handle_new_item()
{
	if (!check_item_data()) {
			return;
	}
	
	add_to_order($_SESSION['Items'], $_POST['stock_id'], input_num('qty'),
		input_num('price'), input_num('Disc') / 100, $_POST['date_from'],	$_POST['notes']);

	$_POST['StockID2'] = $_POST['stock_id']	= "";
	$_POST['notes'] = "";
	line_start_focus();
}

//--------------------------------------------------------------------------------

function  handle_cancel_order()
{
	global $path_to_root;

	if ($_POST['CancelOrder'] != "") {

	if ($_SESSION['Items']->trans_type == 13) {
			display_note(tr("Direct delivery entry has been cancelled as requested."), 1);
			hyperlink_params($path_to_root . "/sales/sales_order_entry.php",
					tr("Enter a New Sales Delivery"), SID . "&NewDelivery=0");
	} elseif ($_SESSION['Items']->trans_type == 10) {
			display_note(tr("Direct invoice entry has been cancelled as requested."), 1);
			hyperlink_params($path_to_root . "/sales/sales_order_entry.php",
					tr("Enter a New Sales Delivery"), SID . "&NewDelivery=0");
	} else {
		if ($_SESSION['Items']->trans_no != 0) {
			if (sales_order_has_deliveries(key($_SESSION['Items']->trans_no)))
				display_error(tr("This order cannot be cancelled because some of it has already been invoiced or dispatched. However, the line item quantities may be modified."));
			else
				delete_sales_order(key($_SESSION['Items']->trans_no));
		}

			display_note(tr("This sales order has been cancelled as requested."), 1);
				hyperlink_params($path_to_root . "/sales/sales_order_entry.php",
				tr("Enter a New Sales Order"), SID . "&NewOrder=Yes");
		}
		processing_end();
		br(1);
		end_page();
		exit;
	}
}

//--------------------------------------------------------------------------------

function create_cart($type, $trans_no)
{
	processing_start();
	$doc_type = $type;

	if($type != 30 && $trans_no != 0) { // this is template
		$doc_type = 30;

		$doc = new Cart(30, array($trans_no));
		$doc->trans_type = $type;
		$doc->trans_no = 0;
		if ($type == 10)
			$doc->due_date = get_invoice_duedate($doc->customer_id, $doc->document_date);
		else
			$doc->due_date = $doc->document_date = Today();
		$doc->reference = references::get_next($doc->trans_type);
		$doc->Comments='';
		foreach($doc->line_items as $line_no => $line) {
			$doc->line_items[$line_no]->qty_done = 0;
		}
		$_SESSION['Items'] = $doc;
	} else
		$_SESSION['Items'] = new Cart($type,array($trans_no));

	copy_from_cart();
}

//--------------------------------------------------------------------------------


//if (isset($_GET['Delete']) || isset($_GET['Edit']))
//	copy_from_cart(); // GET method need form restore

if (isset($_POST['CancelOrder']))
	handle_cancel_order();

$id = find_submit('Delete');
if ($id!=-1)
	handle_delete_item($id);

if (isset($_POST['UpdateItem']))
	handle_update_item();

if (isset($_POST['AddItem']))
	handle_new_item();

if (isset($_POST['CancelItemChanges']) || isset($_POST['UpdateItem']))
	line_start_focus();

//--------------------------------------------------------------------------------

check_db_has_stock_items(tr("There are no inventory items defined in the system."));

check_db_has_customer_branches(tr("There are no customers, or there are no customers with branches. Please define customers and customer branches."));

if ($_SESSION['Items']->trans_type == 10) {
	$idate = tr("Invoice Date:");
	$orderitems = tr("Sales Invoice Items");
	$deliverydetails = tr("Enter Delivery Details and Confirm Invoice");
	$cancelorder = tr("Cancel Invoice");
	$porder = tr("Place Invoice");
} elseif ($_SESSION['Items']->trans_type == 13) {
	$idate = tr("Delivery Date:");
	$orderitems = tr("Delivery Note Items");
	$deliverydetails = tr("Enter Delivery Details and Confirm Dispatch");
	$cancelorder = tr("Cancel Delivery");
	$porder = tr("Place Delivery");
} else {
	$idate = tr("Order Date:");
	$orderitems = tr("Sales Order Items");
	$deliverydetails = tr("Enter Delivery Details and Confirm Order");
	$cancelorder = tr("Cancel Order");
	$porder = tr("Place Order");
	$corder = tr("Commit Order Changes");
}
start_form(false, true);

$customer_error = display_order_header($_SESSION['Items'],
	($_SESSION['Items']->any_already_delivered() == 0), $idate);

if ($customer_error == "") {
	start_table("$table_style width=80%", 10);
	echo "<tr><td>";
	display_order_summary($orderitems, $_SESSION['Items'], true);
	echo "</td></tr>";
	echo "<tr><td>";
	display_delivery_details($_SESSION['Items']);
	echo "</td></tr>";
	end_table(1);

	if ($_SESSION['Items']->trans_no == 0) {
		submit_center_first('ProcessOrder', $porder);
	} else {
		submit_center_first('ProcessOrder', $corder);
	}

	submit_center_last('CancelOrder', $cancelorder);
} else {
	display_error($customer_error);
}
end_form();
//--------------------------------------------------------------------------------
end_page();
?>
