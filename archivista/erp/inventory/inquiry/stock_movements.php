<?php


$page_security = 2;
$path_to_root="../..";
include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/banking.inc");
include_once($path_to_root . "/sales/includes/sales_db.inc");

include_once($path_to_root . "/includes/ui.inc");
$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(800, 500);
if ($use_date_picker)
	$js .= get_js_date_picker();

page(tr("Inventory Item Movement"), false, false, "", $js);

if (isset($_GET['stock_id']))
{
	$_POST['stock_id'] = $_GET['stock_id'];
}

start_form(false, true);

if (!isset($_POST['stock_id']))
	$_POST['stock_id'] = get_global_stock_item();

start_table("class='tablestyle_noborder'");

stock_items_list_cells(tr("Item:"), 'stock_id', $_POST['stock_id']);

locations_list_cells(tr("From Location:"), 'StockLocation', null);

date_cells(tr("From:"), 'AfterDate', null, -30);
date_cells(tr("To:"), 'BeforeDate');

submit_cells('ShowMoves',tr("Show Movements"));
end_table();
end_form();

set_global_stock_item($_POST['stock_id']);

$before_date = date2sql($_POST['BeforeDate']);
$after_date = date2sql($_POST['AfterDate']);

$sql = "SELECT type, trans_no, tran_date, person_id, qty, reference
	FROM stock_moves
	WHERE loc_code='" . $_POST['StockLocation'] . "'
	AND tran_date >= '". $after_date . "'
	AND tran_date <= '" . $before_date . "'
	AND stock_id = '" . $_POST['stock_id'] . "' ORDER BY tran_date,trans_id";
$result = db_query($sql, "could not query stock moves");

check_db_error("The stock movements for the selected criteria could not be retrieved",$sql);

start_table("$table_style width=70%");
$th = array(tr("Type"), tr("#"), tr("Reference"), tr("Date"), tr("Detail"),
	tr("Quantity In"), tr("Quantity Out"), tr("Quantity On Hand"));

table_header($th);

$sql = "SELECT SUM(qty) FROM stock_moves WHERE stock_id='" . $_POST['stock_id'] . "'
	AND loc_code='" . $_POST['StockLocation'] . "'
	AND tran_date < '" . $after_date . "'";
$before_qty = db_query($sql, "The starting quantity on hand could not be calculated");

$before_qty_row = db_fetch_row($before_qty);
$after_qty = $before_qty = $before_qty_row[0];

if (!isset($before_qty_row[0])) 
{
	$after_qty = $before_qty = 0;
}

start_row("class='inquirybg'");
label_cell("<b>".tr("Quantity on hand before") . " " . $_POST['AfterDate']."</b>", "align=center colspan=7");
qty_cell($before_qty);
end_row();

$j = 1;
$k = 0; //row colour counter

$total_in = 0;
$total_out = 0;

while ($myrow = db_fetch($result)) 
{

	alt_table_row_color($k);

	$trandate = sql2date($myrow["tran_date"]);

	$type_name = systypes::name($myrow["type"]);

	if ($myrow["qty"] > 0) 
	{
		$quantity_formatted = number_format2($myrow["qty"],user_qty_dec());
		$total_in += $myrow["qty"];
	}
	else 
	{
		$quantity_formatted = number_format2(-$myrow["qty"],user_qty_dec());
		$total_out += -$myrow["qty"];
	}
	$after_qty += $myrow["qty"];

	label_cell($type_name);

	label_cell(get_trans_view_str($myrow["type"], $myrow["trans_no"]));

	label_cell(get_trans_view_str($myrow["type"], $myrow["trans_no"], $myrow["reference"]));

	label_cell($trandate);

	$person = $myrow["person_id"];
	$gl_posting = "";

	if (($myrow["type"] == 10) || ($myrow["type"] == 11)) 
	{
		$cust_row = get_customer_details_from_trans($myrow["type"], $myrow["trans_no"]);

		if (strlen($cust_row['name']) > 0)
			$person = $cust_row['name'] . " (" . $cust_row['br_name'] . ")";

	} 
	elseif ($myrow["type"] == 25) 
	{
		// get the supplier name
		$sql = "SELECT supp_name FROM suppliers WHERE supplier_id = '" . $myrow["person_id"] . "'";
		$supp_result = db_query($sql,"check failed");

		$supp_row = db_fetch($supp_result);

		if (strlen($supp_row['supp_name']) > 0)
			$person = $supp_row['supp_name'];
	} 
	elseif ($myrow["type"] == systypes::location_transfer() || $myrow["type"] == systypes::inventory_adjustment()) 
	{
		// get the adjustment type
		$movement_type = get_movement_type($myrow["person_id"]);
		$person = $movement_type["name"];
	} 
	elseif ($myrow["type"]==systypes::work_order() || $myrow["type"] == 28  || 
		$myrow["type"] == 29) 
	{
		$person = "";
	}

	label_cell($person);

	label_cell((($myrow["qty"] >= 0) ? $quantity_formatted : ""), "nowrap align=right");
	label_cell((($myrow["qty"] < 0) ? $quantity_formatted : ""), "nowrap align=right");
	label_cell(number_format2($after_qty,user_qty_dec()), "nowrap align=right");
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

if ($total_in != 0 || $total_out != 0) 
{
	start_row("class='inquirybg'");
    label_cell("<b>".tr("Quantity on hand after") . " " . $_POST['BeforeDate']."</b>", "align=center colspan=7");
    qty_cell($after_qty);
    end_row();
}

end_table(1);

end_page();

?>
