<?php

$page_security = 2;
$path_to_root="..";
include_once($path_to_root . "/includes/session.inc");

page(tr("Inventory Item Sales prices"));

include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/inventory/includes/inventory_db.inc");

//---------------------------------------------------------------------------------------------------

check_db_has_stock_items(tr("There are no items defined in the system."));

check_db_has_sales_types(tr("There are no sales types in the system. Please set up sales types befor entering pricing."));

//---------------------------------------------------------------------------------------------------

$input_error = 0;

if (isset($_GET['stock_id']))
{
	$_POST['stock_id'] = $_GET['stock_id'];
}
if (isset($_GET['Item']))
{
	$_POST['stock_id'] = $_GET['Item'];
}

if (!isset($_POST['curr_abrev']))
{
	$_POST['curr_abrev'] = get_company_currency();
}

//---------------------------------------------------------------------------------------------------

start_form(false, true);

if (!isset($_POST['stock_id']))
	$_POST['stock_id'] = get_global_stock_item();

echo "<center>" . tr("Item:"). "&nbsp;";
stock_items_list('stock_id', $_POST['stock_id'], false, true);
echo "<hr>";

// if stock sel has changed, clear the form
if ($_POST['stock_id'] != get_global_stock_item()) 
{
	clear_data();
}

set_global_stock_item($_POST['stock_id']);

//----------------------------------------------------------------------------------------------------

function clear_data()
{
	unset($_POST['PriceID']);
	unset($_POST['price']);
	unset($_POST['factor']);
}

//----------------------------------------------------------------------------------------------------

if (isset($_POST['updatePrice'])) 
{

	if (!check_num('price', 0) && !check_num('factor',0)) 
	{
		$input_error = 1;
		display_error( tr("The price entered must be numeric."));
		set_focus('price');
	}

	if ($input_error != 1)
	{

		if (isset($_POST['PriceID'])) 
		{
			//editing an existing price
			update_item_price($_POST['PriceID'], $_POST['sales_type_id'], 
			$_POST['curr_abrev'], input_num('price'), input_num('factor'));

			$msg = tr("This price has been updated.");
		} 
		elseif ($input_error !=1) 
		{

			add_item_price($_POST['stock_id'], $_POST['sales_type_id'], 
			    $_POST['curr_abrev'], input_num('price'), input_num('factor'));

			display_note(tr("The new price has been added."));
		}
		clear_data();
	}

}

//------------------------------------------------------------------------------------------------------

if (isset($_GET['delete'])) 
{

	//the link to delete a selected record was clicked
	delete_item_price($_GET['PriceID']);
	echo tr("The selected price has been deleted.");

}

//---------------------------------------------------------------------------------------------------

$mb_flag = get_mb_flag($_POST['stock_id']);

$prices_list = get_prices($_POST['stock_id']);

start_table("$table_style width=30%");

$th = array(tr("Currency"), tr("Sales Type"), tr("Price"), tr("Factor"), "", "");
table_header($th);
$k = 0; //row colour counter

while ($myrow = db_fetch($prices_list)) 
{

	alt_table_row_color($k);

	label_cell($myrow["curr_abrev"]);
    label_cell($myrow["sales_type"]);
    amount_cell($myrow["price"]);
    amount_cell($myrow["factor"]);
    edit_link_cell("PriceID=" . $myrow["id"]. "&Edit=1");
    delete_link_cell("PriceID=" . $myrow["id"]. "&delete=yes");
    end_row();

}
end_table();

//------------------------------------------------------------------------------------------------

if (db_num_rows($prices_list) == 0) 
{
	display_note(tr("There are no prices set up for this part."));
}

echo "<br>";

if (isset($_GET['Edit']))
{
	$myrow = get_stock_price($_GET['PriceID']);
	hidden('PriceID', $_GET['PriceID']);
	$_POST['curr_abrev'] = $myrow["curr_abrev"];
	$_POST['sales_type_id'] = $myrow["sales_type_id"];
	$_POST['price'] = price_format($myrow["price"]);
	$_POST['factor'] = price_format($myrow["factor"]);
}

start_table($table_style2);

currencies_list_row(tr("Currency:"), 'curr_abrev', null);

sales_types_list_row(tr("Sales Type:"), 'sales_type_id', null);

small_amount_row(tr("Price:"), 'price', null);

small_amount_row(tr("Factor:"), 'factor', null);

end_table(1);

submit_center('updatePrice', tr("Add/Update Price"));


end_form();
end_page();
?>
