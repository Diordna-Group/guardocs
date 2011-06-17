<?php
//-----------------------------------------------------------------------------
//
//	Entry/Modify Delivery Note against Sales Order
//
$page_security = 2;
$path_to_root="..";

include_once($path_to_root . "/sales/includes/cart_class.inc");
include_once($path_to_root . "/includes/session.inc");
include_once($path_to_root . "/includes/data_checks.inc");
include_once($path_to_root . "/includes/manufacturing.inc");
include_once($path_to_root . "/sales/includes/sales_db.inc");
include_once($path_to_root . "/sales/includes/sales_ui.inc");
include_once($path_to_root . "/reporting/includes/reporting.inc");
include_once($path_to_root . "/taxes/tax_calc.inc");

$js = "";
if ($use_popup_windows) {
	$js .= get_js_open_window(900, 500);
}
if ($use_date_picker) {
	$js .= get_js_date_picker();
}

if (isset($_GET['ModifyDelivery'])) {
	$_SESSION['page_title'] = sprintf(tr("Modifying Delivery Note # %d."), $_GET['ModifyDelivery']);
	$help_page_title = tr("Modifying Delivery Note");
	processing_start();
} elseif (isset($_GET['OrderNumber'])) {
	$_SESSION['page_title'] = tr("Deliver Items for a Sales Order");
	processing_start();
}

page($_SESSION['page_title'], false, false, "", $js);

if (isset($_GET['AddedID'])) {
	$dispatch_no = $_GET['AddedID'];
	print_hidden_script(13);

	display_notification(tr("Dispatch processed:") . ' '.$_GET['AddedID'], true);

	display_note(get_customer_trans_view_str(13, $dispatch_no, tr("View this dispatch")), 0, 1);

	display_note(print_document_link($dispatch_no, tr("Print this delivery"), true, 13));

	display_note(get_gl_view_str(13, $dispatch_no, tr("View the GL Journal Entries for this Dispatch")),1);

	hyperlink_params("$path_to_root/sales/customer_invoice.php", tr("Invoice This Delivery"), "DeliveryNumber=$dispatch_no");

	hyperlink_params("$path_to_root/sales/inquiry/sales_orders_view.php", tr("Select Another Order For Dispatch"), "OutstandingOnly=1");

	display_footer_exit();

} elseif (isset($_GET['UpdatedID'])) {

	$delivery_no = $_GET['UpdatedID'];
	print_hidden_script(13);

	display_notification_centered(sprintf(tr('Delivery Note # %d has been updated.'),$delivery_no));

	display_note(get_trans_view_str(13, $delivery_no, tr("View this delivery")));
	echo '<br>';
	display_note(print_document_link($delivery_no, tr("Print this delivery"), true, 13));

	hyperlink_params($path_to_root . "/sales/customer_invoice.php", tr("Confirm Delivery and Invoice"), "DeliveryNumber=$delivery_no");

	hyperlink_params($path_to_root . "/sales/inquiry/sales_deliveries_view.php", tr("Select A Different Delivery"), "OutstandingOnly=1");

	display_footer_exit();
}
//-----------------------------------------------------------------------------

if (isset($_GET['OrderNumber']) && $_GET['OrderNumber'] > 0) {

	$ord = new Cart(30,$_GET['OrderNumber'], true);

	/*read in all the selected order into the Items cart  */

	if ($ord->count_items() == 0) {
		hyperlink_params($path_to_root . "/sales/inquiry/sales_orders_view.php",
			tr("Select a different sales order to delivery"), "OutstandingOnly=1");
		die ("<br><b>" . tr("This order has no items. There is nothing to delivery.") . "</b>");
	}

	$ord->trans_type = 13;
	$ord->src_docs = $ord->trans_no;
	$ord->order_no = key($ord->trans_no);
	$ord->trans_no = 0;
	$ord->reference = references::get_next(13);
	$_SESSION['Items'] = $ord;
	copy_from_cart();

} elseif (isset($_GET['ModifyDelivery']) && $_GET['ModifyDelivery'] > 0) {

	$_SESSION['Items'] = new Cart(13,$_GET['ModifyDelivery']);

	if ($_SESSION['Items']->count_items() == 0) {
		hyperlink_params($path_to_root . "/sales/inquiry/sales_orders_view.php",
			tr("Select a different delivery"), "OutstandingOnly=1");
		echo "<br><center><b>" . tr("This delivery has all items invoiced. There is nothing to modify.") .
			"</center></b>";
		display_footer_exit();
	}

	copy_from_cart();

} elseif ( !processing_active() ) {
	/* This page can only be called with an order number for invoicing*/

	display_error(tr("This page can only be opened if an order or delivery note has been selected. Please select it first."));

	hyperlink_params("$path_to_root/sales/inquiry/sales_orders_view.php", tr("Select a Sales Order to Delivery"), "OutstandingOnly=1");

	end_page();
	exit;

} elseif (!check_quantities()) {
	display_error(tr("Selected quantity cannot be less than quantity invoiced nor more than quantity
		not dispatched on sales order."));

} elseif(!check_num('ChargeFreightCost', 0))
	display_error(tr("Freight cost cannot be less than zero"));
	set_focus('ChargeFreightCost');


//-----------------------------------------------------------------------------

function check_data()
{
	if (!isset($_POST['DispatchDate']) || !is_date($_POST['DispatchDate']))	{
		display_error(tr("The entered date of delivery is invalid."));
		set_focus('DispatchDate');
		return false;
	}

	if (!is_date_in_fiscalyear($_POST['DispatchDate'])) {
		display_error(tr("The entered date of delivery is not in fiscal year."));
		set_focus('DispatchDate');
		return false;
	}

	if (!isset($_POST['due_date']) || !is_date($_POST['due_date']))	{
		display_error(tr("The entered dead-line for invoice is invalid."));
		set_focus('due_date');
		return false;
	}

	if ($_SESSION['Items']->trans_no==0) {
		if (!references::is_valid($_POST['ref'])) {
			display_error(tr("You must enter a reference."));
			set_focus('ref');
			return false;
		}

		if ($_SESSION['Items']->trans_no==0 && !is_new_reference($_POST['ref'], 13)) {
			display_error(tr("The entered reference is already in use."));
			set_focus('ref');
			return false;
		}
	}
	if ($_POST['ChargeFreightCost'] == "") {
		$_POST['ChargeFreightCost'] = price_format(0);
	}

	if (!check_num('ChargeFreightCost',0)) {
		display_error(tr("The entered shipping value is not numeric."));
		set_focus('ChargeFreightCost');
		return false;
	}

	if ($_SESSION['Items']->has_items_dispatch() == 0 && input_num('ChargeFreightCost') == 0) {
		display_error(tr("There are no item quantities on this delivery note."));
		return false;
	}

	if (!check_quantities()) {
		display_error(tr("Selected quantity cannot be less than quantity invoiced nor more than quantity
		not dispatched on sales order."));
		return false;
	}

	return true;
}
//------------------------------------------------------------------------------
function copy_to_cart()
{
	$cart = &$_SESSION['Items'];
	$cart->ship_via = $_POST['ship_via'];
	$cart->freight_cost = input_num('ChargeFreightCost');
	$cart->document_date =  $_POST['DispatchDate'];
	$cart->due_date =  $_POST['due_date'];
	$cart->Location = $_POST['Location'];
	$cart->Comments = $_POST['Comments'];
	if ($cart->trans_no == 0)
		$dn->ref = $_POST['ref'];

}
//------------------------------------------------------------------------------

function copy_from_cart()
{
	$cart = &$_SESSION['Items'];
	$_POST['ship_via'] = $cart->ship_via;
	$_POST['ChargeFreightCost'] = price_format($cart->freight_cost);
	$_POST['DispatchDate']= $cart->document_date;
	$_POST['due_date'] = $cart->due_date;
	$_POST['Location']= $cart->Location;
	$_POST['Comments']= $cart->Comments;
}
//------------------------------------------------------------------------------

function check_quantities()
{
	$ok =1;
	// Update cart delivery quantities/descriptions
	foreach ($_SESSION['Items']->line_items as $line=>$itm) {
		if (isset($_POST['Line'.$line])) {
			if (!check_num('Line'.$line, $itm->qty_done, $itm->quantity) == 0) {
				$_SESSION['Items']->line_items[$line]->qty_dispatched = 
				  input_num('Line'.$line);
			} else {
				$ok = 0;
			}

		}

		if (isset($_POST['Line'.$line.'Desc'])) {
			$line_desc = $_POST['Line'.$line.'Desc'];
			if (strlen($line_desc) > 0) {
				$_SESSION['Items']->line_items[$line]->item_description = $line_desc;
			}
		}
	}
// ...
//	else
//	  $_SESSION['Items']->freight_cost = input_num('ChargeFreightCost');
	return $ok;
}
//------------------------------------------------------------------------------

function check_qoh()
{
	if (!sys_prefs::allow_negative_stock())	{
		foreach ($_SESSION['Items']->line_items as $itm) {

			if ($itm->qty_dispatched && has_stock_holding($itm->mb_flag)) {
				$qoh = get_qoh_on_date($itm->stock_id, $_POST['Location'], $_POST['DispatchDate']);

				if ($itm->qty_dispatched > $qoh) {
					display_error(tr("The delivery cannot be processed because there is an insufficient quantity for item:") .
						" " . $itm->stock_id . " - " .  $itm->item_description);
					return false;
				}
			}
		}
	}
	return true;
}
//------------------------------------------------------------------------------

if (isset($_POST['process_delivery']) && check_data() && check_qoh()) {

	$dn = &$_SESSION['Items'];

	if ($_POST['bo_policy']) {
		$bo_policy = 0;
	} else {
		$bo_policy = 1;
	}
	$newdelivery = ($dn->trans_no == 0);

	copy_to_cart();
	$delivery_no = $dn->write($bo_policy);

	processing_end();
	if ($newdelivery) {
		meta_forward($_SERVER['PHP_SELF'], "AddedID=$delivery_no");
	} else {
		meta_forward($_SERVER['PHP_SELF'], "UpdatedID=$delivery_no");
	}
}

//------------------------------------------------------------------------------
start_form(false, true);

start_table("$table_style2 width=80%", 5);
echo "<tr><td>"; // outer table

start_table("$table_style width=100%");
start_row();
label_cells(tr("Customer"), $_SESSION['Items']->customer_name, "class='tableheader2'");
label_cells(tr("Branch"), get_branch_name($_SESSION['Items']->Branch), "class='tableheader2'");
label_cells(tr("Currency"), $_SESSION['Items']->customer_currency, "class='tableheader2'");
end_row();
start_row();

//if (!isset($_POST['ref']))
//	$_POST['ref'] = references::get_next(13);

if ($_SESSION['Items']->trans_no==0) {
	ref_cells(tr("Reference"), 'ref', $_SESSION['Items']->reference, "class='tableheader2'");
} else {
	label_cells(tr("Reference"), $_SESSION['Items']->reference, "class='tableheader2'");
}

label_cells(tr("For Sales Order"), get_customer_trans_view_str(systypes::sales_order(), $_SESSION['Items']->order_no), "class='tableheader2'");

label_cells(tr("Sales Type"), $_SESSION['Items']->sales_type_name, "class='tableheader2'");
end_row();
start_row();

if (!isset($_POST['Location'])) {
	$_POST['Location'] = $_SESSION['Items']->Location;
}
label_cell(tr("Delivery From"), "class='tableheader2'");
locations_list_cells(null, 'Location',$_POST['Location'], false, true);

if (!isset($_POST['ship_via'])) {
	$_POST['ship_via'] = $_SESSION['Items']->ship_via;
}
label_cell(tr("Shipping Company"), "class='tableheader2'");
shippers_list_cells(null, 'ship_via', $_POST['ship_via']);

// set this up here cuz it's used to calc qoh
if (!isset($_POST['DispatchDate']) || !is_date($_POST['DispatchDate'])) {
	$_POST['DispatchDate'] = Today();
	if (!is_date_in_fiscalyear($_POST['DispatchDate'])) {
		$_POST['DispatchDate'] = end_fiscalyear();
	}
}
date_cells(tr("Date"), 'DispatchDate', $_POST['DispatchDate'], 0, 0, 0, "class='tableheader2'");
end_row();

end_table();

echo "</td><td>";// outer table

start_table("$table_style width=90%");

if (!isset($_POST['due_date']) || !is_date($_POST['due_date'])) {
	$_POST['due_date'] = get_invoice_duedate($_SESSION['Items']->customer_id, $_POST['DispatchDate']);
}
date_row(tr("Invoice Dead-line"), 'due_date', $_POST['due_date'], 0, 0, 0, "class='tableheader2'");
end_table();

echo "</td></tr>";
end_table(1); // outer table

display_heading(tr("Delivery Items"));

start_table("$table_style width=80%");
$th = array(tr("Item Code"), tr("Item Description"), 
            tr("Date"), tr("Description"),
tr("Ordered"), tr("Units"), tr("Delivered"),
	tr("This Delivery"), tr("Price"), tr("Tax Type"), tr("Discount"), tr("Total"));
table_header($th);
$k = 0;
$has_marked = false;
$show_qoh = true;

foreach ($_SESSION['Items']->line_items as $line=>$ln_itm) {
	if ($ln_itm->quantity==$ln_itm->qty_done) {
		continue; //this line is fully delivered
	}
	// if it's a non-stock item (eg. service) don't show qoh
	if (sys_prefs::allow_negative_stock() || !has_stock_holding($ln_itm->mb_flag) ||
		$ln_itm->qty_dispatched == 0) {
		$show_qoh = false;
	}

	if ($show_qoh) {
		$qoh = get_qoh_on_date($ln_itm->stock_id, $_POST['Location'], $_POST['DispatchDate']);
	}

	if ($show_qoh && ($ln_itm->qty_dispatched > $qoh)) {
		// oops, we don't have enough of one of the component items
		start_row("class='stockmankobg'");
		$has_marked = true;
	} else {
		alt_table_row_color($k);
	}
	view_stock_status_cell($ln_itm->stock_id);

	text_cells(null, 'Line'.$line.'Desc', $ln_itm->item_description, 30, 50);
	label_cell($ln_itm->date_from);
	label_cell($ln_itm->notes);
	qty_cell($ln_itm->quantity);
	label_cell($ln_itm->units);
	qty_cell($ln_itm->qty_done);

	small_qty_cells(null, 'Line'.$line, qty_format($ln_itm->qty_dispatched));

	$display_discount_percent = percent_format($ln_itm->discount_percent*100) . "%";

	$line_total = ($ln_itm->qty_dispatched * $ln_itm->price * (1 - $ln_itm->discount_percent));

	amount_cell($ln_itm->price);
	label_cell($ln_itm->tax_type_name);
	label_cell($display_discount_percent, "nowrap align=right");
	amount_cell($line_total);

	end_row();
}

$_POST['ChargeFreightCost'] = price_format($_SESSION['Items']->freight_cost);

if (!check_num('ChargeFreightCost')) {
		$_POST['ChargeFreightCost'] = price_format(0);
}

start_row();

small_amount_cells(tr("Shipping Cost"), 'ChargeFreightCost',
$_SESSION['Items']->freight_cost, "colspan=11 align=right");

$inv_items_total = $_SESSION['Items']->get_items_total_dispatch();

$display_sub_total = price_format($inv_items_total + input_num('ChargeFreightCost'));

label_row(tr("Sub-total"), $display_sub_total, "colspan=11 align=right","align=right");

$taxes = $_SESSION['Items']->get_taxes(input_num('ChargeFreightCost'));
$tax_total = display_edit_tax_items($taxes, 11, $_SESSION['Items']->tax_included);

$display_total = price_format(($inv_items_total + input_num('ChargeFreightCost') + $tax_total));

label_row(tr("Amount Total"), $display_total, "colspan=11 align=right","align=right");

end_table(1);

if ($has_marked) {
	display_note(tr("Marked items have insufficient quantities in stock as on day of delivery."), 0, 1, "class='red'");
}
start_table($table_style2);

policy_list_row(tr("Action For Balance"), "bo_policy", null);

textarea_row(tr("Memo"), 'Comments', null, 50, 4);

end_table(1);

submit_center_first('Update', tr("Update"));
submit_center_last('process_delivery', tr("Process Dispatch"));

end_form();


end_page();

?>
