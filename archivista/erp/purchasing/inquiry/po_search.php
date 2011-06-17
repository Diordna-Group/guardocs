<?php

$page_security = 2;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

include($path_to_root . "/purchasing/includes/purchasing_ui.inc");
include_once($path_to_root . "/reporting/includes/reporting.inc");

$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 500);
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Search Outstanding Purchase Orders"), false, false, "", $js);

if (isset($_GET['order_number']))
{
	$_POST['order_number'] = $_GET['order_number'];
}

//---------------------------------------------------------------------------------------------

start_form(false, true);

start_table("class='tablestyle_noborder'");
start_row();
ref_cells(tr("#:"), 'order_number');

date_cells(tr("from:"), 'OrdersAfterDate', null, -30);
date_cells(tr("to:"), 'OrdersToDate');

locations_list_cells(tr("Location:"), 'StockLocation', null, true);

stock_items_list_cells(tr("Item:"), 'SelectStockFromList', null, true);

submit_cells('SearchOrders', tr("Search"));
end_row();
end_table();

end_form();

//---------------------------------------------------------------------------------------------

if (isset($_POST['order_number']) && ($_POST['order_number'] != ""))
{
	$order_number = $_POST['order_number'];
}

if (isset($_POST['SelectStockFromList']) && ($_POST['SelectStockFromList'] != "") &&
	($_POST['SelectStockFromList'] != $all_items))
{
 	$selected_stock_item = $_POST['SelectStockFromList'];
}
else
{
	unset($selected_stock_item);
}

$today = date2sql(Today());

//figure out the sql required from the inputs available
$sql = "SELECT purch_orders.order_no, suppliers.supp_name, purch_orders.into_stock_location,
	purch_orders.ord_date, purch_orders.requisition_no, purch_orders.reference,
	suppliers.curr_code, locations.location_name,
	Sum(purch_order_details.unit_price*purch_order_details.quantity_ordered) AS OrderValue,
	Sum(purch_order_details.delivery_date < '" . $today. "'
	AND (purch_order_details.quantity_ordered > purch_order_details.quantity_received)) As OverDue
	FROM purch_orders, purch_order_details, suppliers, locations
	WHERE purch_orders.order_no = purch_order_details.order_no
	AND purch_orders.supplier_id = suppliers.supplier_id
	AND locations.loc_code = purch_orders.into_stock_location
	AND (purch_order_details.quantity_ordered > purch_order_details.quantity_received) ";

if (isset($order_number) && $order_number != "")
{
	$sql .= "AND purch_orders.reference LIKE '%". $order_number . "%'";
}
else
{

	$data_after = date2sql($_POST['OrdersAfterDate']);
	$data_before = date2sql($_POST['OrdersToDate']);

	$sql .= "  AND purch_orders.ord_date >= '$data_after'";
	$sql .= "  AND purch_orders.ord_date <= '$data_before'";

	if (isset($_POST['StockLocation']) && $_POST['StockLocation'] != $all_items)
	{
		$sql .= " AND purch_orders.into_stock_location = '". $_POST['StockLocation'] . "' ";
	}

	if (isset($selected_stock_item))
	{
		$sql .= " AND purch_order_details.item_code='". $selected_stock_item ."' ";
	}
} //end not order number selected

$sql .= " GROUP BY purch_orders.order_no";

$result = db_query($sql,"No orders were returned");

print_hidden_script(18);

/*show a table of the orders returned by the sql */

start_table("$table_style colspan=7 width=80%");

if (isset($_POST['StockLocation']) && $_POST['StockLocation'] == $all_items)
	$th = array(tr("#"), tr("Reference"), tr("Supplier"), tr("Location"),
		tr("Supplier's Reference"), tr("Order Date"), tr("Currency"), tr("Order Total"),"","","");
else
	$th = array(tr("#"), tr("Reference"), tr("Supplier"),
		tr("Supplier's Reference"), tr("Order Date"), tr("Currency"), tr("Order Total"),"","","");

table_header($th);

$j = 1;
$k = 0; //row colour counter
$overdue_items = false;
while ($myrow = db_fetch($result))
{

	if ($myrow["OverDue"] == 1)
	{
		 start_row("class='overduebg'");
		 $overdue_items = true;
	}
	else
	{
		alt_table_row_color($k);
	}

	$modify = "$path_to_root/purchasing/po_entry_items.php?" . SID . "ModifyOrderNumber=" . $myrow["order_no"];
	$receive = "$path_to_root/purchasing/po_receive_items.php?" . SID . "PONumber=" . $myrow["order_no"];

	$date = sql2date($myrow["ord_date"]);

	label_cell(get_trans_view_str(systypes::po(), $myrow["order_no"]));
	label_cell($myrow["reference"]);
	label_cell($myrow["supp_name"]);
	if (isset($_POST['StockLocation']) && $_POST['StockLocation'] == $all_items)
		label_cell($myrow["location_name"]);
	label_cell($myrow["requisition_no"]);
	label_cell($date);
	label_cell($myrow["curr_code"]);
	amount_cell($myrow["OrderValue"]);
	label_cell("<a href=$modify>" . tr("Edit") . "</a>");
  	label_cell(print_document_link($myrow['order_no'], tr("Print")));
	label_cell("<a href=$receive>" . tr("Receive") . "</a>");
	end_row();

	$j++;
	If ($j == 12)
	{
		$j = 1;
		table_header($th);
	}
//end of page full new headings if
}
//end of while loop

end_table();

if ($overdue_items)
	display_note(tr("Marked orders have overdue items."), 0, 1, "class='overduefg'");

end_page();
?>
