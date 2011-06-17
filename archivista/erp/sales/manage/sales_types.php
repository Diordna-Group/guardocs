<?php

$page_security = 14;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

page(tr("Sales Types"));

include($path_to_root . "/includes/ui.inc");
include($path_to_root . "/sales/includes/db/sales_types_db.inc");

if (isset($_POST['selected_id']))
{
	$selected_id = $_POST['selected_id'];
} 
elseif (isset($_GET['selected_id']))
{
	$selected_id = $_GET['selected_id'];
}
else
	$selected_id = -1;

//----------------------------------------------------------------------------------------------------

function can_process() 
{
	if (strlen($_POST['sales_type']) == 0) 
	{
		display_error(tr("The sales type description cannot be empty."));
		return false;
	} 
	return true;
}

//----------------------------------------------------------------------------------------------------

if (isset($_POST['ADD_ITEM']) && can_process()) 
{
	add_sales_type($_POST['sales_type'], isset($_POST['tax_included']),
	               input_num('price_factor') );
	meta_forward($_SERVER['PHP_SELF']);    	
}

//----------------------------------------------------------------------------------------------------

if (isset($_POST['UPDATE_ITEM']) && can_process()) 
{

	update_sales_type($selected_id, $_POST['sales_type'],
	isset($_POST['tax_included']) ? 1:0, input_num('price_factor'));
	meta_forward($_SERVER['PHP_SELF']);    	
} 

//----------------------------------------------------------------------------------------------------

if (isset($_GET['delete'])) 
{
	// PREVENT DELETES IF DEPENDENT RECORDS IN 'debtor_trans'

	$sql= "SELECT COUNT(*) FROM debtor_trans WHERE tpe='$selected_id'";
	$result = db_query($sql,"check failed");
	check_db_error("The number of transactions using this Sales type record could not be retrieved", $sql);

	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this sale type because customer transactions have been created using this sales type."));

	} 
	else 
	{

		$sql = "SELECT COUNT(*) FROM debtors_master WHERE sales_type='$selected_id'";
		$result = db_query($sql,"check failed");
  		check_db_error("The number of customers using this Sales type record could not be retrieved", $sql);
  					
		$myrow = db_fetch_row($result);
		if ($myrow[0] > 0) 
		{
			display_error(tr("Cannot delete this sale type because customers are currently set up to use this sales type."));
		} 
		else 
		{
			delete_sales_type($selected_id);
			meta_forward($_SERVER['PHP_SELF']);				  
		}
	} //end if sales type used in debtor transactions or in customers set up
}

//----------------------------------------------------------------------------------------------------

$result = get_all_sales_types();

start_table("$table_style width=30%");

$th = array (tr("Type Name"), 'Tax Incl', 'Price factor','','');
table_header($th);
$k = 0;

while ($myrow = db_fetch($result)) 
{
	alt_table_row_color($k);
	label_cell($myrow["sales_type"]);	
	label_cell($myrow["tax_included"] ? tr('Yes'):tr('No'),'align=center');	
	qty_cell($myrow["price_factor"],null,2); 
  edit_link_cell("selected_id=".$myrow["id"]);
  delete_link_cell("selected_id=".$myrow["id"]."&delete=1");
	end_row();
}

end_table();

//----------------------------------------------------------------------------------------------------

hyperlink_no_params($_SERVER['PHP_SELF'], tr("New Sales type"));

start_form();
 if (!isset($_POST['tax_included']))
	$_POST['tax_included'] = 0;

start_table("$table_style2 width=30%");

if ($selected_id != -1) 
{

	$myrow = get_sales_type($selected_id);
	
	$_POST['sales_type']  = $myrow["sales_type"];
	$_POST['tax_included']  = $myrow["tax_included"];
	$_POST['price_factor']  = number_format2($myrow["price_factor"],2);
	
	hidden('selected_id', $selected_id);
} 

text_row_ex(tr("Sales Type Name:"), 'sales_type', 20);
check_row("Tax  included", 'tax_included', $_POST['tax_included']);
amount_row("Price factor",'price_factor',$_POST['price_factor']);

end_table(1);

submit_add_or_update_center($selected_id == -1);

end_form();

end_page();

?>
