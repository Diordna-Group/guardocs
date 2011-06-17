<?php

$page_security = 1;
$path_to_root="../..";
include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/sales/includes/sales_ui.inc");

include_once($path_to_root . "/sales/includes/sales_db.inc");

$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 600);
page(tr("View Sales Invoice"), true, false, "", $js);


if (isset($_GET["trans_no"]))
{
	$trans_id = $_GET["trans_no"];
} 
elseif (isset($_POST["trans_no"]))
{
	$trans_id = $_POST["trans_no"];
}

// 3 different queries to get the information - what a JOKE !!!!

$myrow = get_customer_trans($trans_id, 10);

$branch = get_branch($myrow["branch_code"]);

$sales_order = get_sales_order_header($myrow["order_"]);

display_heading(sprintf(tr("SALES INVOICE #%d"),$trans_id));

echo "<br>";
start_table("$table_style2 width=95%");
echo "<tr valign=top><td>"; // outer table

/*Now the customer charged to details in a sub table*/
start_table("$table_style width=100%");
$th = array(tr("Charge To"));
table_header($th);

label_row(null, $myrow["DebtorName"] . "<br>" . nl2br($myrow["address"]), "nowrap");

end_table();

/*end of the small table showing charge to account details */

echo "</td><td>"; // outer table

/*end of the main table showing the company name and charge to details */

start_table("$table_style width=100%");
$th = array(tr("Charge Branch"));
table_header($th);

label_row(null, $branch["br_name"] . "<br>" . nl2br($branch["br_address"]), "nowrap");
end_table();

echo "</td><td>"; // outer table

start_table("$table_style width=100%");
$th = array(tr("Delivered To"));
table_header($th);

label_row(null, $sales_order["deliver_to"] . "<br>" . nl2br($sales_order["delivery_address"]),
	"nowrap");
end_table();

echo "</td><td>"; // outer table

start_table("$table_style width=100%");
start_row();
label_cells(tr("Reference"), $myrow["reference"], "class='tableheader2'");
label_cells(tr("Currency"), $sales_order["curr_code"], "class='tableheader2'");
label_cells(tr("Our Order No"), 
	get_customer_trans_view_str(systypes::sales_order(),$sales_order["order_no"]), "class='tableheader2'");
end_row();
start_row();
label_cells(tr("Customer Order Ref."), $sales_order["customer_ref"], "class='tableheader2'");
label_cells(tr("Shipping Company"), $myrow["shipper_name"], "class='tableheader2'");
label_cells(tr("Sales Type"), $myrow["sales_type"], "class='tableheader2'");
end_row();
start_row();
label_cells(tr("Invoice Date"), sql2date($myrow["tran_date"]), "class='tableheader2'", "nowrap");
label_cells(tr("Due Date"), sql2date($myrow["due_date"]), "class='tableheader2'", "nowrap");
end_row();
comments_display_row(10, $trans_id);
end_table();

echo "</td></tr>";
end_table(1); // outer table


$result = get_customer_trans_details(10, $trans_id);

start_table("$table_style width=95%");

if (db_num_rows($result) > 0)
{
	$th = array(tr("Item Code"), tr("Item Description"), tr("Quantity"),
		tr("Unit"), tr("Price"), tr("Discount %"), tr("Total"));
	table_header($th);	

	$k = 0;	//row colour counter
	$sub_total = 0;
	while ($myrow2 = db_fetch($result))
	{
	    if($myrow2["quantity"]==0) continue;
		alt_table_row_color($k);

		$value = round(((1 - $myrow2["discount_percent"]) * $myrow2["unit_price"] * $myrow2["quantity"]), 
		   user_price_dec());
		$sub_total += $value;

	    if ($myrow2["discount_percent"] == 0)
	    {
		  	$display_discount = "";
	    } 
	    else 
	    {
		  	$display_discount = percent_format($myrow2["discount_percent"]*100) . "%";
	    }

	    label_cell($myrow2["stock_id"]);
		label_cell($myrow2["StockDescription"]);
        qty_cell($myrow2["quantity"]);
        label_cell($myrow2["units"], "align=right");
        amount_cell($myrow2["unit_price"]);
        label_cell($display_discount, "nowrap align=right");
        amount_cell($value);
		end_row();
	} //end while there are line items to print out

} 
else
	display_note(tr("There are no line items on this invoice."), 1, 2);

$display_sub_tot = price_format($sub_total);
$display_freight = price_format($myrow["ov_freight"]);

/*Print out the invoice text entered */
label_row(tr("Sub-total"), $display_sub_tot, "colspan=6 align=right", 
	"nowrap align=right width=15%");
label_row(tr("Shipping"), $display_freight, "colspan=6 align=right", "nowrap align=right");

$tax_items = get_customer_trans_tax_details(10, $trans_id);
display_customer_trans_tax_details($tax_items, 6);

$display_total = price_format($myrow["ov_freight"]+$myrow["ov_gst"]+$myrow["ov_amount"]+$myrow["ov_freight_tax"]);

label_row(tr("TOTAL INVOICE"), $display_total, "colspan=6 align=right",
	"nowrap align=right");
end_table(1);

is_voided_display(10, $trans_id, tr("This invoice has been voided."));

end_page(true);

?>