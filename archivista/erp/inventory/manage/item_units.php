<?php

$page_security = 11;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

page(tr("Units of Measure"));

include_once($path_to_root . "/includes/ui.inc");

include_once($path_to_root . "/inventory/includes/db/items_units_db.inc");

if (isset($_GET['selected_id']))
{
	$selected_id = $_GET['selected_id'];
} 
else if (isset($_POST['selected_id']))
{
	$selected_id = $_POST['selected_id'];
}

//----------------------------------------------------------------------------------

if (isset($_POST['ADD_ITEM']) || isset($_POST['UPDATE_ITEM'])) 
{

	//initialise no input errors assumed initially before we test
	$input_error = 0;

	if (strlen($_POST['abbr']) == 0) 
	{
		$input_error = 1;
		display_error(tr("The unit of measure code cannot be empty."));
		set_focus('abbr');
	}
	if (strlen($_POST['description']) == 0) 
	{
		$input_error = 1;
		display_error(tr("The unit of measure description cannot be empty."));
		set_focus('description');
	}
	if (!is_numeric($_POST['decimals'])) 
	{
		$input_error = 1;
		display_error(tr("The number of decimal places must be integer."));
		set_focus('decimals');
	}


	if ($input_error !=1) {
    	write_item_unit(isset($selected_id) ? $selected_id : '', $_POST['abbr'], $_POST['description'], $_POST['decimals'] );
		meta_forward($_SERVER['PHP_SELF']); 
	}
}

//---------------------------------------------------------------------------------- 

if (isset($_GET['delete'])) 
{

	// PREVENT DELETES IF DEPENDENT RECORDS IN 'stock_master'
    
	if (item_unit_used($selected_id))
	{
		display_error(tr("Cannot delete this unit of measure because items have been created using this units."));

	} 
	else 
	{
		delete_item_unit($selected_id);
		meta_forward($_SERVER['PHP_SELF']); 		
	}
}

//----------------------------------------------------------------------------------

$result = get_all_item_units();
start_table("$table_style width=50%");
$th = array(tr('Unit'), tr('Description'), tr('Decimals'), "", "");

table_header($th);
$k = 0; //row colour counter

while ($myrow = db_fetch($result)) 
{
	
	alt_table_row_color($k);

	label_cell($myrow["abbr"]);
	label_cell($myrow["name"]);
	label_cell($myrow["decimals"]);

	edit_link_cell(SID."selected_id=$myrow[0]");
	delete_link_cell(SID."selected_id=$myrow[0]&delete=yes");
	end_row();
}

end_table();

//----------------------------------------------------------------------------------

hyperlink_no_params($_SERVER['PHP_SELF'], tr("New Unit of Measure"));

start_form();

start_table("class='tablestyle_noborder'");

if (isset($selected_id)) 
{
	//editing an existing item category

	$myrow = get_item_unit($selected_id);

	$_POST['abbr'] = $myrow["abbr"];
	$_POST['description']  = $myrow["name"];
	$_POST['decimals']  = $myrow["decimals"];

	hidden('selected_id', $selected_id);
}

if (isset($selected_id) && item_unit_used($selected_id)) {
    label_row(tr("Unit Abbreviation:"), $_POST['abbr']);
    hidden('abbr', $_POST['abbr']);
} else
    text_row(tr("Unit Abbreviation:"), 'abbr', null, 20, 20);
text_row(tr("Descriptive Name:"), 'description', null, 40, 40);  
text_row(tr("Decimal Places:"), 'decimals', null, 3, 3);  

end_table(1);

submit_add_or_update_center(!isset($selected_id));

end_form();

end_page();

?>
