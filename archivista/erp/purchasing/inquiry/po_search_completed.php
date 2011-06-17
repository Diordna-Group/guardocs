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
page(tr("Search Purchase Orders"), false, false, "", $js);

if (isset($_GET['order_number']))
{
	$order_number = $_GET['order_number'];
}

//---------------------------------------------------------------------------------------------

start_form(false, true);

start_table("class='tablestyle_noborder'");
start_row();
ref_cells(tr("#:"), 'order_number');

date_cells(tr("from:"), 'OrdersAfterDate', null, -30);
date_cells(tr("to:"), 'OrdersToDate');

locations_list_cells(tr("into location:"), 'StockLocation', null, true);

stock_items_list_cells(tr("for item:"), 'SelectStockFromList', null, true);

submit_cells('SearchOrders', tr("Search"));
end_row();
end_table();

end_form();

//---------------------------------------------------------------------------------------------

if (isset($_POST['order_number']))
{
	$order_number = $_POST['order_number'];
}

if (isset($_POST['SelectStockFromList']) &&	($_POST['SelectStockFromList'] != "") &&
	($_POST['SelectStockFromList'] != reserved_words::get_all()))
{
 	$selected_stock_item = $_POST['SelectStockFromList'];
}
else
{
	unset($selected_stock_item);
}

//---------------------------------------------------------------------------------------------

//figure out the sql required from the inputs available
$sql = "SELECT purch_orders.order_no, suppliers.supp_name, purch_orders.ord_date, purch_orders.into_stock_location,
	purch_orders.requisition_no, purch_orders.reference, locations.location_name,
	suppliers.curr_code, Sum(purch_order_details.unit_price*purch_order_details.quantity_ordered) AS OrderValue
	FROM purch_orders, purch_order_details, suppliers, locations
	WHERE purch_orders.order_no = purch_order_details.order_no
	AND purch_orders.supplier_id = suppliers.supplier_id
	AND locations.loc_code = purch_orders.into_stock_location ";

if (isset($order_number) && $order_number != "")
{
	$sql .= "AND purch_orders.reference LIKE '%". $order_number . "%'";
}
else
{

	$data_after = date2sql($_POST['OrdersAfterDate']);
	$date_before = date2sql($_POST['OrdersToDate']);

	$sql .= " AND purch_orders.ord_date >= '$data_after'";
	$sql .= " AND purch_orders.ord_date <= '$date_before'";

	if (isset($_POST['StockLocation']) && $_POST['StockLocation'] != reserved_words::get_all())
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

start_table("$table_style colspan=7 width=80%");

if (isset($_POST['StockLocation']) && $_POST['StockLocation'] == reserved_words::get_all())
	$th = array(tr("#"), tr("Reference"), tr("Supplier"), tr("Location"),
		tr("Supplier's Reference"), tr("Order Date"), tr("Currency"), tr("Order Total"),"");
else
	$th = array(tr("#"), tr("Reference"), tr("Supplier"),
		tr("Supplier's Reference"), tr("Order Date"), tr("Currency"), tr("Order Total"),"");

table_header($th);

$j = 1;
$k = 0; //row colour counter
while ($myrow = db_fetch($result))
{

	alt_table_row_color($k);

	$date = sql2date($myrow["ord_date"]);

	label_cell(get_trans_view_str(systypes::po(), $myrow["order_no"]));
	label_cell($myrow["reference"]);
	label_cell($myrow["supp_name"]);
	if (isset($_POST['StockLocation']) && $_POST['StockLocation'] == reserved_words::get_all())
		label_cell($myrow["location_name"]);
	label_cell($myrow["requisition_no"]);
	label_cell($date);
	label_cell($myrow["curr_code"]);
	amount_cell($myrow["OrderValue"]);
  	label_cell(print_document_link($myrow['order_no'], tr("Print")));
	end_row();

	$j++;
	if ($j == 12)
	{
		$j = 1;
		table_header($th);
	}
}

end_table(2);

//---------------------------------------------------------------------------------------------------

end_page();
?>
