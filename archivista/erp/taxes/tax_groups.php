<?php

$page_security = 3;
$path_to_root="..";

include($path_to_root . "/includes/session.inc");

page(tr("Tax Groups"));

include_once($path_to_root . "/includes/data_checks.inc");
include_once($path_to_root . "/includes/ui.inc");

include_once($path_to_root . "/taxes/db/tax_groups_db.inc");
include_once($path_to_root . "/taxes/db/tax_types_db.inc");

if (isset($_GET['selected_id']))
{
	$selected_id = $_GET['selected_id'];
} 
elseif(isset($_POST['selected_id']))
{
	$selected_id = $_POST['selected_id'];
}
else
	$selected_id = -1;
	
check_db_has_tax_types(tr("There are no tax types defined. Define tax types before defining tax groups."));

//-----------------------------------------------------------------------------------

if (isset($_POST['ADD_ITEM']) || isset($_POST['UPDATE_ITEM'])) 
{

	//initialise no input errors assumed initially before we test
	$input_error = 0;

	if (strlen($_POST['name']) == 0) 
	{
		$input_error = 1;
		display_error(tr("The tax group name cannot be empty."));
		set_focus('name');
	} 
	else 
	{
		// make sure any entered rates are valid
    	for ($i = 0; $i < 5; $i++) 
    	{
    		if (isset($_POST['tax_type_id' . $i]) && 
    			$_POST['tax_type_id' . $i] != reserved_words::get_all_numeric()	&& 
    			!check_num('rate' . $i, 0))
    		{
			display_error( tr("An entered tax rate is invalid or less than zero."));
    			$input_error = 1;
			set_focus('rate');
			break;
    		}
    	}
	}

	if ($input_error != 1) 
	{

		// create an array of the taxes and array of rates
    	$taxes = array();
    	$rates = array();

    	for ($i = 0; $i < 5; $i++) 
    	{
    		if (isset($_POST['tax_type_id' . $i]) &&
   				$_POST['tax_type_id' . $i] != reserved_words::get_any_numeric()) 
   			{
        		$taxes[] = $_POST['tax_type_id' . $i];
        		$rates[] = input_num('rate' . $i);
    		}
    	}

    	if ($selected_id != -1) 
    	{

    		update_tax_group($selected_id, $_POST['name'], $_POST['tax_shipping'], $taxes, 
    			$rates);

    	} 
    	else 
    	{

    		add_tax_group($_POST['name'], $_POST['tax_shipping'], $taxes, $rates);
    	}

		meta_forward($_SERVER['PHP_SELF']);
	}
}

//-----------------------------------------------------------------------------------

function can_delete($selected_id)
{
	if ($selected_id == -1)
		return false;
	$sql = "SELECT COUNT(*) FROM cust_branch WHERE tax_group_id=$selected_id";
	$result = db_query($sql, "could not query customers");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_note(tr("Cannot delete this tax group because customer branches been created referring to it."));
		return false;
	}

	$sql = "SELECT COUNT(*) FROM suppliers WHERE tax_group_id=$selected_id";
	$result = db_query($sql, "could not query suppliers");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_note(tr("Cannot delete this tax group because suppliers been created referring to it."));
		return false;
	}


	return true;
}


//-----------------------------------------------------------------------------------

if (isset($_GET['delete'])) 
{

	if (can_delete($selected_id))
	{
		delete_tax_group($selected_id);
		meta_forward($_SERVER['PHP_SELF']);
	}
}

//-----------------------------------------------------------------------------------

$result = get_all_tax_groups();

start_table($table_style);
$th = array(tr("Description"), tr("Tax Shipping"), "", "");
table_header($th);

$k = 0;
while ($myrow = db_fetch($result)) 
{

	alt_table_row_color($k);

	label_cell($myrow["name"]);
	if ($myrow["tax_shipping"])
		label_cell(tr("Yes"));
	else
		label_cell(tr("No"));

	/*for ($i=0; $i< 5; $i++)
		if ($myrow["type" . $i] != reserved_words::get_all_numeric())
			echo "<td>" . $myrow["type" . $i] . "</td>";*/

	edit_link_cell("selected_id=" . $myrow["id"]);
	delete_link_cell("selected_id=" . $myrow["id"]. "&delete=1");
	end_row();;
}

end_table();

//-----------------------------------------------------------------------------------

hyperlink_no_params($_SERVER['PHP_SELF'], tr("New Tax Group"));

start_form();

start_table($table_style2);

if ($selected_id != -1) 
{
	//editing an existing status code

	if (!isset($_POST['name']))
	{
    	$group = get_tax_group($selected_id);

    	$_POST['name']  = $group["name"];
    	$_POST['tax_shipping'] = $group["tax_shipping"];

    	$items = get_tax_group_items($selected_id);

    	$i = 0;
    	while ($tax_item = db_fetch($items)) 
    	{
    		$_POST['tax_type_id' . $i]  = $tax_item["tax_type_id"];
    		$_POST['rate' . $i]  = percent_format($tax_item["rate"]);
    		$i ++;
    	}
	}

	hidden('selected_id', $selected_id);
}
text_row_ex(tr("Description:"), 'name', 40);
yesno_list_row(tr("Tax Shipping:"), 'tax_shipping', null, "", "", true);

end_table();

display_note(tr("Select the taxes that are included in this group."), 1);

start_table($table_style2);
$th = array(tr("Tax"), tr("Default Rate (%)"), tr("Rate (%)"));
table_header($th);
for ($i = 0; $i < 5; $i++) 
{
	start_row();
	if (!isset($_POST['tax_type_id' . $i]))
		$_POST['tax_type_id' . $i] = 0;
	tax_types_list_cells(null, 'tax_type_id' . $i, $_POST['tax_type_id' . $i], true, tr("None"), true);

	if ($_POST['tax_type_id' . $i] != 0 && $_POST['tax_type_id' . $i] != reserved_words::get_all_numeric()) 
	{

		$default_rate = get_tax_type_default_rate($_POST['tax_type_id' . $i]);
		label_cell(percent_format($default_rate), "nowrap align=right");

		if (!isset($_POST['rate' . $i]) || $_POST['rate' . $i] == "")
			$_POST['rate' . $i] = percent_format($default_rate);
		small_amount_cells(null, 'rate' . $i, $_POST['rate' . $i], null, null, 
		  user_percent_dec());
	}
	end_row();
}

end_table(1);

submit_add_or_update_center(!isset($selected_id));

end_form();

//------------------------------------------------------------------------------------

end_page();

?>
