<?php

$page_security = 2;
$path_to_root="../..";
include_once($path_to_root . "/includes/session.inc");

if (isset($_GET['stock_id'])){
	$_POST['stock_id'] = $_GET['stock_id'];
	page(tr("Inventory Item Status"), true);
} else {
	page(tr("Inventory Item Status"));
}

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/manufacturing.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/inventory/includes/inventory_db.inc");

//----------------------------------------------------------------------------------------------------

check_db_has_stock_items(tr("There are no items defined in the system."));

start_form(false, true);

if (!isset($_POST['stock_id']))
	$_POST['stock_id'] = get_global_stock_item();

echo "<center> " . tr("Item:"). " ";
stock_items_list('stock_id', $_POST['stock_id'], false, true);
echo "<br>";

echo "<hr>";

set_global_stock_item($_POST['stock_id']);

$mb_flag = get_mb_flag($_POST['stock_id']);
$kitset_or_service = false;

if (is_service($mb_flag))
{
	display_note(tr("This is a service and cannot have a stock holding, only the total quantity on outstanding sales orders is shown."));
	$kitset_or_service = true;
}

$loc_details = get_loc_details($_POST['stock_id']);

start_table($table_style);

if ($kitset_or_service == true)
{
	$th = array(tr("Location"), tr("Demand"));
} 
else 
{
	$th = array(tr("Location"), tr("Quantity On Hand"), tr("Re-Order Level"),
		tr("Demand"), tr("Available"), tr("On Order"));
}
table_header($th);
$j = 1;
$k = 0; //row colour counter

while ($myrow = db_fetch($loc_details)) 
{

	alt_table_row_color($k);

	$sql = "SELECT Sum(sales_order_details.quantity-sales_order_details.qty_sent) AS DEM
		FROM sales_order_details, sales_orders
		WHERE sales_orders.order_no = sales_order_details.order_no
		AND sales_orders.from_stk_loc='" . $myrow["loc_code"] . "'
		AND sales_order_details.qty_sent < sales_order_details.quantity
		AND sales_order_details.stk_code='" . $_POST['stock_id'] . "'";

	$demand_result = db_query($sql,"Could not retreive demand for item");

	if (db_num_rows($demand_result) == 1)
	{
	  $demand_row = db_fetch_row($demand_result);
	  $demand_qty =  $demand_row[0];
	} 
	else 
	{
	  $demand_qty =0;
	}


	$qoh = get_qoh_on_date($_POST['stock_id'], $myrow["loc_code"]);

	if ($kitset_or_service == false)
	{
		$sql = "SELECT Sum(purch_order_details.quantity_ordered - purch_order_details.quantity_received) AS qoo
			FROM purch_order_details INNER JOIN purch_orders ON purch_order_details.order_no=purch_orders.order_no
			WHERE purch_orders.into_stock_location='" . $myrow["loc_code"] . "'
			AND purch_order_details.item_code='" . $_POST['stock_id'] . "'";
		$qoo_result = db_query($sql,"could not receive quantity on order for item");

		if (db_num_rows($qoo_result) == 1)
		{
    		$qoo_row = db_fetch_row($qoo_result);
    		$qoo =  $qoo_row[0];
		} 
		else 
		{
			$qoo = 0;
		}

		label_cell($myrow["location_name"]);
		qty_cell($qoh);
        qty_cell($myrow["reorder_level"]);
        qty_cell($demand_qty);
        qty_cell($qoh - $demand_qty);
        qty_cell($qoo);
        end_row();

	} 
	else 
	{
	/* It must be a service or kitset part */
		label_cell($myrow["location_name"]);
		qty_cell($demand_qty);
		end_row();

	}
	$j++;
	If ($j == 12)
	{
		$j = 1;	
		table_header($th);
	}
}

end_table();

end_form();
end_page();

?>
