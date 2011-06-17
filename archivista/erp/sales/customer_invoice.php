<?php
//---------------------------------------------------------------------------
//
//	Entry/Modify Sales Invoice against single delivery
//	Entry/Modify Batch Sales Invoice against batch of deliveries
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

if (isset($_GET['ModifyInvoice'])) {
	$_SESSION['page_title'] = sprintf(tr("Modifying Sales Invoice # %d.") ,
	                                  $_GET['ModifyInvoice']);
	$help_page_title = tr("Modifying Sales Invoice");
} elseif (isset($_GET['DeliveryNumber'])) {
	$_SESSION['page_title'] = tr("Issue an Invoice for Delivery Note");
} elseif (isset($_GET['BatchInvoice'])) {
	$_SESSION['page_title'] = tr("Issue Batch Invoice for Delivery Notes");
}

page($_SESSION['page_title'], false, false, "", $js);

//-----------------------------------------------------------------------------

if (isset($_GET['AddedID'])) {
	$invoice_no = $_GET['AddedID'];
	$trans_type = 10;
	print_hidden_script(10);
	display_notification(tr("Selected deliveries has been processed"), true);
	display_note(get_customer_trans_view_str($trans_type, $invoice_no, 
	  tr("View This Invoice")), 0, 1);
	display_note(print_document_link($invoice_no, 
	  tr("Print This Invoice"), true, 10));
	display_note(get_gl_view_str($trans_type, $invoice_no, 
	  tr("View the GL Journal Entries for this Invoice")),1);
	hyperlink_params("$path_to_root/sales/inquiry/sales_deliveries_view.php",
	  tr("Select Another Delivery For Invoicing"), "OutstandingOnly=1");
	display_footer_exit();
} elseif (isset($_GET['UpdatedID']))  {
	$invoice_no = $_GET['UpdatedID'];
	print_hidden_script(10);
	display_notification_centered(sprintf(
	  tr('Sales Invoice # %d has been updated.'),$invoice_no));
	display_note(get_trans_view_str(10, $invoice_no, tr("View This Invoice")));
	echo '<br>';
	display_note(print_document_link($invoice_no, 
	  tr("Print This Invoice"), true, 10));
	hyperlink_no_params($path_to_root . "/sales/inquiry/customer_inquiry.php",
	  tr("Select A Different Invoice to Modify"));
	display_footer_exit();
} elseif (isset($_GET['RemoveDN'])) {
	for($line_no=0;$line_no<count($_SESSION['Items']->line_items);$line_no++) {
		$line = &$_SESSION['Items']->line_items[$line_no];
		if ($line->src_no == $_GET['RemoveDN']) {
			$line->quantity = $line->qty_done;
			$line->qty_dispatched=0;
		}
	}
	unset($line);
}

//-----------------------------------------------------------------------------

if ( (isset($_GET['DeliveryNumber']) && ($_GET['DeliveryNumber'] > 0) )
	|| isset($_GET['BatchInvoice'])) {
	processing_start();
	if (isset($_GET['BatchInvoice'])) {
		$src = $_SESSION['DeliveryBatch'];
		unset($_SESSION['DeliveryBatch']);
	} else {
		$src = array($_GET['DeliveryNumber']);
	}
	/*read in all the selected deliveries into the Items cart  */
	$dn = new Cart(13, $src, true);
	if ($dn->count_items() == 0) {
		hyperlink_params($path_to_root . "/sales/inquiry/sales_deliveries_view.php",
			tr("Select a different delivery to invoice"), "OutstandingOnly=1");
		die ("<br><b>" . tr("There are no delivered items with a quantity left ".
		               "to invoice. There is nothing left to invoice.") . "</b>");
	}
	$dn->trans_type = 10;
	$dn->src_docs = $dn->trans_no;
	$dn->trans_no = 0;
	$dn->reference = references::get_next(10);
	$dn->due_date = get_invoice_duedate($dn->customer_id, $dn->document_date);
	$_SESSION['Items'] = $dn;
	copy_from_cart();
} elseif (isset($_GET['ModifyInvoice']) && $_GET['ModifyInvoice'] > 0) {
	if ( get_parent_trans(10, $_GET['ModifyInvoice']) == 0) { // 1.xx compatibility hack
		echo"<center><br><b>" . tr("There in no delivery notes for this invoice.<br>
		Most likely this invoice was created in Front Accounting version prior to 2.0
		and therefore can not be modified.") . "</b></center>";
		display_footer_exit();
	}
	processing_start();
	$_SESSION['Items'] = new Cart(10, $_GET['ModifyInvoice']);
	if ($_SESSION['Items']->count_items() == 0) {
		echo"<center><br><b>" . tr("All quantities on this invoice has been ".
		"credited. There is nothing to modify on this invoice") . "</b></center>";
		display_footer_exit();
	}
	copy_from_cart();
} elseif (!processing_active()) {
	// This page can only be called with a delivery for 
	// invoicing or invoice no for edit
	display_error(tr("This page can only be opened after delivery selection. ".
	                 "Please select delivery to invoicing first."));
	hyperlink_no_params("$path_to_root/sales/inquiry/sales_deliveries_view.php", 
	                    tr("Select Delivery to Invoice"));
	end_page();
	exit;
} else {
	foreach ($_SESSION['Items']->line_items as $line_no=>$itm) {
		if (isset($_POST['Line'.$line_no])) {
			if (!check_num('Line'.$line_no, 0, ($itm->quantity - $itm->qty_done))) {
				$_SESSION['Items']->line_items[$line_no]->qty_dispatched =
				    input_num('Line'.$line_no);
			}
		}
		if (isset($_POST['Line'.$line_no.'Desc'])) {
			$line_desc = $_POST['Line'.$line_no.'Desc'];
			if (strlen($line_desc) > 0) {
				$_SESSION['Items']->line_items[$line_no]->item_description = $line_desc;
			}
		}
	}
}

//-----------------------------------------------------------------------------

function copy_to_cart() {
	$cart = &$_SESSION['Items'];
	$cart->ship_via = $_POST['ship_via'];
	$cart->freight_cost = input_num('ChargeFreightCost');
	$cart->document_date =  $_POST['InvoiceDate'];
	$cart->due_date =  $_POST['due_date'];
	$cart->Comments = $_POST['Comments'];
}
//-----------------------------------------------------------------------------

function copy_from_cart() {
	$cart = &$_SESSION['Items'];
	$_POST['ship_via'] = $cart->ship_via;
	$_POST['ChargeFreightCost'] = price_format($cart->freight_cost);
	$_POST['InvoiceDate']= $cart->document_date;
	$_POST['due_date'] = $cart->due_date;
	$_POST['Comments']= $cart->Comments;
}

//-----------------------------------------------------------------------------

function check_data() {
	if (!isset($_POST['InvoiceDate']) || !is_date($_POST['InvoiceDate'])) {
		display_error(tr("The entered invoice date is invalid."));
		set_focus('InvoiceDate');
		return false;
	}
	if (!is_date_in_fiscalyear($_POST['InvoiceDate'])) {
		display_error(tr("The entered invoice date is not in fiscal year."));
		set_focus('InvoiceDate');
		return false;
	}
	if (!isset($_POST['due_date']) || !is_date($_POST['due_date']))	{
		display_error(tr("The entered invoice due date is invalid."));
		set_focus('due_date');
		return false;
	}
	if ($_SESSION['Items']->trans_no == 0) {
		if (!references::is_valid($_POST['ref'])) {
			display_error(tr("You must enter a reference."));
			set_focus('ref');
			return false;
		}
		if (!is_new_reference($_POST['ref'], 10)) {
			display_error(tr("The entered reference is already in use."));
			set_focus('ref');
			return false;
		}
	}
	if ($_POST['ChargeFreightCost'] == "") {
		$_POST['ChargeFreightCost'] = price_format(0);
	}
	if (!check_num('ChargeFreightCost', 0)) {
		display_error(tr("The entered shipping value is not numeric."));
		set_focus('ChargeFreightCost');
		return false;
	}
	if ($_SESSION['Items']->has_items_dispatch() == 0 && 
	                 input_num('ChargeFreightCost') == 0) {
		display_error(tr("There are no item quantities on this invoice."));
		return false;
	}
	return true;
}

//-----------------------------------------------------------------------------
if (isset($_POST['process_invoice']) && check_data()) {
	$newinvoice=  $_SESSION['Items']->trans_no == 0;
	copy_to_cart();
	$invoice_no = $_SESSION['Items']->write();
	processing_end();
	if ($newinvoice) {
		meta_forward($_SERVER['PHP_SELF'], "AddedID=$invoice_no");
	} else {
		meta_forward($_SERVER['PHP_SELF'], "UpdatedID=$invoice_no");
	}
}
// find delivery spans for batch invoice display
$dspans = array();
$lastdn = ''; $spanlen=1;
for ($line_no=0;$line_no<count($_SESSION['Items']->line_items);$line_no++) {
	$line = $_SESSION['Items']->line_items[$line_no];
	if ($line->quantity == $line->qty_done) {
		continue;
	}
	if ($line->src_no == $lastdn) {
		$spanlen++;
	} else {
		if ($lastdn != '') {
			$dspans[] = $spanlen;
			$spanlen = 1;
		}
	}
	$lastdn = $line->src_no;
}
$dspans[] = $spanlen;

//-----------------------------------------------------------------------------

$is_batch_invoice = count($_SESSION['Items']->src_docs) > 1;
$is_edition = $_SESSION['Items']->trans_type == 10 && 
                   $_SESSION['Items']->trans_no != 0;
start_form(false, true);
start_table("$table_style2 width=80%", 5);
start_row();
label_cells(tr("Customer"), $_SESSION['Items']->customer_name, 
  "class='tableheader2'");
label_cells(tr("Branch"), get_branch_name($_SESSION['Items']->Branch),
  "class='tableheader2'");
label_cells(tr("Currency"), $_SESSION['Items']->customer_currency, 
  "class='tableheader2'");
end_row();
start_row();
if ($_SESSION['Items']->trans_no == 0) {
	ref_cells(tr("Reference"), 'ref', $_SESSION['Items']->reference, 
	  "class='tableheader2'");
} else {
	label_cells(tr("Reference"), $_SESSION['Items']->reference, 
	  "class='tableheader2'");
}
label_cells(tr("Delivery Notes"),
get_customer_trans_view_str(systypes::cust_dispatch(), 
  array_keys($_SESSION['Items']->src_docs)), "class='tableheader2'");
label_cells(tr("Sales Type"), $_SESSION['Items']->sales_type_name, 
  "class='tableheader2'");
end_row();
start_row();
if (!isset($_POST['ship_via'])) {
	$_POST['ship_via'] = $_SESSION['Items']->ship_via;
}
label_cell(tr("Shipping Company"), "class='tableheader2'");
shippers_list_cells(null, 'ship_via', $_POST['ship_via']);
if (!isset($_POST['InvoiceDate']) || !is_date($_POST['InvoiceDate'])) {
	$_POST['InvoiceDate'] = Today();
	if (!is_date_in_fiscalyear($_POST['InvoiceDate'])) {
		$_POST['InvoiceDate'] = end_fiscalyear();
	}
}
date_cells(tr("Date"), 'InvoiceDate', $_POST['InvoiceDate'], 0, 0, 0, 
  "class='tableheader2'");
if (!isset($_POST['due_date']) || !is_date($_POST['due_date'])) {
	$_POST['due_date'] = get_invoice_duedate($_SESSION['Items']->customer_id, 
	  $_POST['InvoiceDate']);
}
date_cells(tr("Due Date"), 'due_date', $_POST['due_date'], 0, 0, 0, 
  "class='tableheader2'");
end_row();
end_table();
display_heading(tr("Invoice Items"));
start_table("$table_style width=80%");
$th = array(tr("Item Code"), tr("Item Description"), 
            tr("Date"), tr("Description"), 
						tr("Delivered"), tr("Units"), tr("Invoiced"),
	          tr("This Invoice"),tr("Price"),tr("Tax Type"),
						tr("Discount"),tr("Total"));
if ($is_batch_invoice) {
    $th[] = tr("DN");
    $th[] = "";
}
if ($is_edition) {
    $th[4] = tr("Credited");
}
table_header($th);
$k = 0;
$has_marked = false;
$show_qoh = true;
$dn_line_cnt = 0;
foreach ($_SESSION['Items']->line_items as $line=>$ln_itm) {
	if ($ln_itm->quantity == $ln_itm->qty_done) {
		continue; // this line was fully invoiced
	}
	alt_table_row_color($k);
	view_stock_status_cell($ln_itm->stock_id);
	text_cells(null, 'Line'.$line.'Desc', $ln_itm->item_description, 30, 50);
	label_cell($ln_itm->date_from);
	label_cell($ln_itm->notes);
	qty_cell($ln_itm->quantity);
	label_cell($ln_itm->units);
	qty_cell($ln_itm->qty_done);
	if ($is_batch_invoice) {
		// for batch invoices we can only remove whole deliveries
		echo '<td nowrap align=right>';
		hidden('Line' . $line, $ln_itm->qty_dispatched );
		echo qty_format($ln_itm->qty_dispatched).'</td>';
	} else {
		small_qty_cells(null, 'Line'.$line, qty_format($ln_itm->qty_dispatched));
	}
	$display_discount_percent=percent_format($ln_itm->discount_percent*100)." %";
	$line_total = ($ln_itm->qty_dispatched * $ln_itm->price * 
	  (1 - $ln_itm->discount_percent));
	amount_cell($ln_itm->price);
	label_cell($ln_itm->tax_type_name);
	label_cell($display_discount_percent, "nowrap align=right");
	amount_cell($line_total);
	if ($is_batch_invoice) {
		if ($dn_line_cnt == 0) {
			$dn_line_cnt = $dspans[0];
			$dspans = array_slice($dspans, 1);
			label_cell($ln_itm->src_no, "rowspan=$dn_line_cnt class=oddrow");
			label_cell("<a href='" . $_SERVER['PHP_SELF'] . "?RemoveDN=".
				$ln_itm->src_no."'>" . tr("Remove") . "</a>", 
				"rowspan=$dn_line_cnt class=oddrow");
		}
		$dn_line_cnt--;
	}
	end_row();
}
/*Don't re-calculate freight if some of the order has already been delivered -
depending on the business logic required this condition may not be required.
It seems unfair to charge the customer twice for freight if the order
was not fully delivered the first time ?? */
if (!isset($_POST['ChargeFreightCost']) || $_POST['ChargeFreightCost']=="") {
	if ($_SESSION['Items']->any_already_delivered() == 1) {
		$_POST['ChargeFreightCost']=price_format(0);
	} else {
		$_POST['ChargeFreightCost']=price_format($_SESSION['Items']->freight_cost);
	}
	if (!check_num('ChargeFreightCost')) {
		$_POST['ChargeFreightCost'] = price_format(0);
	}
}
start_row();
small_amount_cells(tr("Shipping Cost"), 'ChargeFreightCost', 
  null, "colspan=11 align=right");
if ($is_batch_invoice) {
  label_cell('', 'colspan=2');
}
end_row();
$inv_items_total = $_SESSION['Items']->get_items_total_dispatch();
$display_sub_total = price_format($inv_items_total + 
  input_num('ChargeFreightCost'));
label_row(tr("Sub-total"), $display_sub_total, "colspan=11 align=right",
  "align=right", $is_batch_invoice ? 2 : 0);
$taxes = $_SESSION['Items']->get_taxes(input_num('ChargeFreightCost'));
$tax_total = display_edit_tax_items($taxes, 11, 
  $_SESSION['Items']->tax_included, $is_batch_invoice ? 2:0);
$display_total = price_format(($inv_items_total + 
  input_num('ChargeFreightCost') + $tax_total));
label_row(tr("Invoice Total"), $display_total, "colspan=11 align=right",
  "align=right", $is_batch_invoice ? 2 : 0);
end_table(1);
start_table($table_style2);
textarea_row(tr("Memo"), 'Comments', null, 50, 4);
end_table(1);
submit_center_first('Update', tr("Update"));
submit_center_last('process_invoice', tr("Process Invoice"));
end_form();
end_page();

?>
