<?php

$page_security = 11;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

page(tr("Items"));

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/inventory/includes/inventory_db.inc");

$user_comp = user_company();

if (isset($_GET['stock_id'])) {
	$stock_id = strtoupper($_GET['stock_id']);
} else if (isset($_POST['stock_id'])) {
	$stock_id = strtoupper($_POST['stock_id']);
}

if (isset($_GET['New']) || !isset($_POST['NewStockID'])) {
	$_POST['New'] = "1";
}

if (isset($_POST['SelectStockItem'])) {
	$_POST['NewStockID'] = $_POST['stock_id'];
	unset($_POST['New']);
}

check_db_has_stock_categories(tr("There are no item categories defined in the system. At least one item category is required to add a item."));

check_db_has_item_tax_types(tr("There are no item tax types defined in the system. At least one item tax type is required to add a item."));

function clear_data() {
	unset($_POST['long_description']);
	unset($_POST['description']);
	unset($_POST['category_id']);
	unset($_POST['tax_type_id']);
	unset($_POST['units']);
	unset($_POST['mb_flag']);
	unset($_POST['NewStockID']);
	unset($_POST['dimension_id']);
	unset($_POST['dimension2_id']);
	unset($_POST['selling']);
	unset($_POST['depending']);
	unset($_POST['barcode']);
	unset($_POST['weight']);
	$_POST['New'] = "1";
}


if (isset($_POST['deleteImage']) == '1') {
	$sql= "update stock_master set image='' ".
	      "where stock_id='$stock_id'";
	$result = db_query($sql, "could not delete image");
}
$blob = image_load($max_image_size);

if (isset($_POST['addupdate'])) {
	$input_error = 0;
	if ($upload_file == 'No')
		$input_error = 1;
	if (strlen($_POST['description']) == 0) {
		$input_error = 1;
		display_error( tr('The item name must be entered.'));
		set_focus('description');
	} elseif (strlen($_POST['NewStockID']) == 0) {
		$input_error = 1;
		display_error( tr('The item code cannot be empty'));
		set_focus('NewStockID');
	} elseif (strstr($_POST['NewStockID'], " ") || 
	          strstr($_POST['NewStockID'],"'") || 
		        strstr($_POST['NewStockID'], "+") ||
						strstr($_POST['NewStockID'], "\"") || 
		        strstr($_POST['NewStockID'], "&")) {
		$input_error = 1;
		display_error( tr('The item code cannot contain any of the following characters -  & + OR a space OR quotes'));
		set_focus('NewStockID');
	}

	if ($input_error != 1) 	{
		if (!isset($_POST['New'])) { /*so its an existing one */
			update_item($_POST['NewStockID'], $_POST['description'],
				$_POST['long_description'], $_POST['category_id'], 
				$_POST['tax_type_id'],
				$_POST['sales_account'], $_POST['inventory_account'], 
				$_POST['cogs_account'],
				$_POST['adjustment_account'], $_POST['assembly_account'], 
				$_POST['dimension_id'], $_POST['dimension2_id'],
				$_POST['selling'], $_POST['depending'],
				$_POST['barcode'], $_POST['weight'], $blob, $_POST['units']
				);
		} else { //it is a NEW part
			add_item($_POST['NewStockID'], $_POST['description'],
				$_POST['long_description'], $_POST['category_id'], 
				$_POST['tax_type_id'],
				$_POST['units'], $_POST['mb_flag'], $_POST['sales_account'],
				$_POST['inventory_account'], $_POST['cogs_account'],
				$_POST['adjustment_account'], $_POST['assembly_account'], 
				$_POST['dimension_id'], $_POST['dimension2_id'],
				$_POST['selling'], $_POST['depending'],
				$_POST['barcode'], $_POST['weight'], $blob
				);
		}
		meta_forward($_SERVER['PHP_SELF']);
	}
}




function can_delete($stock_id) {
	$sql= "SELECT COUNT(*) FROM stock_moves ".
	      "WHERE stock_id='$stock_id'";
	$result = db_query($sql, "could not query stock moves");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) {
		display_error(tr('Cannot delete this item because there are stock '.
		                'movements that refer to this item.'));
		return false;
	}
	$sql= "SELECT COUNT(*) FROM bom WHERE component='$stock_id'";
	$result = db_query($sql, "could not query boms");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) {
		display_error(tr('Cannot delete this item record because there are bills '.
		                'of material that require this part as a component.'));
		return false;
	}
	$sql= "SELECT COUNT(*) FROM sales_order_details ".
	      "WHERE stk_code='$stock_id'";
	$result = db_query($sql, "could not query sales orders");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) {
		display_error(tr('Cannot delete this item record because there are '.
		                'existing sales orders for this part.'));
		return false;
	}
	$sql= "SELECT COUNT(*) FROM purch_order_details ".
	      "WHERE item_code='$stock_id'";
	$result = db_query($sql, "could not query purchase orders");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) {
		display_error(tr('Cannot delete this item because there are existing '.
		                'purchase order items for it.'));
		return false;
	}
	return true;
}


//------------------------------------------------------------------------------------

if (isset($_POST['delete']) && strlen($_POST['delete']) > 1) {
	if (can_delete($_POST['NewStockID'])) {
		$stock_id = $_POST['NewStockID'];
		delete_item($stock_id);
		meta_forward($_SERVER['PHP_SELF']);
	}
}

//------------------------------------------------------------------------------------

start_form(true);
if (db_has_stock_items()) {
	start_table("class='tablestyle_noborder'");
	start_row();
    stock_items_list_cells(tr("Select an item:"), 'stock_id',
		null,null,null,null,1);
    submit_cells('SelectStockItem', tr("Edit Item"));
	end_row();
	end_table();
}
hyperlink_params($_SERVER['PHP_SELF'], tr("Enter a new item"), "New=1");
echo "<br>";
start_table("$table_style2 width=40%");
table_section_title(tr("Item"));

//------------------------------------------------------------------------------------

$id = ""; // no stock item for image load
if (!isset($_POST['NewStockID']) || isset($_POST['New'])) {

/*If the page was called without $_POST['NewStockID'] passed to page then assume a new item is to be entered show a form with a part Code field other wise the form showing the fields with the existing entries against the part will show for editing with only a hidden stock_id field. New is set to flag that the page may have called itself and still be entering a new part, in which case the page needs to know not to go looking up details for an existing part*/

	hidden('New', 'Yes');
	text_row(tr("Item Code:"), 'NewStockID', null, 21, 20);
	$company_record = get_company_prefs();
  if (!isset($_POST['inventory_account']) || $_POST['inventory_account'] == "")
   	$_POST['inventory_account'] = $company_record["default_inventory_act"];

  if (!isset($_POST['cogs_account']) || $_POST['cogs_account'] == "")
  	$_POST['cogs_account'] = $company_record["default_cogs_act"];

	if (!isset($_POST['sales_account']) || $_POST['sales_account'] == "")
		$_POST['sales_account'] = $company_record["default_inv_sales_act"];

	if (!isset($_POST['adjustment_account']) || $_POST['adjustment_account'] == "")
		$_POST['adjustment_account'] = $company_record["default_adj_act"];

	if (!isset($_POST['assembly_account']) || $_POST['assembly_account'] == "")
		$_POST['assembly_account'] = $company_record["default_assembly_act"];
	
	$_POST['selling'] = 1;
} else { // Must be modifying an existing item
	if (!isset($_POST['New'])) {
	  $id = $_POST['NewStockID'];
		$myrow = get_item($_POST['NewStockID']);
		$_POST['long_description'] = $myrow["long_description"];
		$_POST['description'] = $myrow["description"];
		$_POST['category_id']  = $myrow["category_id"];
		$_POST['tax_type_id']  = $myrow["tax_type_id"];
		$_POST['units']  = $myrow["units"];
		$_POST['mb_flag']  = $myrow["mb_flag"];
		$_POST['sales_account'] =  $myrow['sales_account'];
		$_POST['inventory_account'] = $myrow['inventory_account'];
		$_POST['cogs_account'] = $myrow['cogs_account'];
		$_POST['adjustment_account']	= $myrow['adjustment_account'];
		$_POST['assembly_account']	= $myrow['assembly_account'];
		$_POST['dimension_id']	= $myrow['dimension_id'];
		$_POST['dimension2_id']	= $myrow['dimension2_id'];
		$_POST['selling']	= $myrow['selling'];
		$_POST['depending']	= $myrow['depending'];
		$_POST['barcode']	= $myrow['barcode'];
		$_POST['weight']	= $myrow['weight'];
		label_row(tr("Item Code:"),$_POST['NewStockID']);
		hidden('NewStockID', $_POST['NewStockID']);
	}
}

text_row(tr("Name:"), 'description', null, 52, 50);
textarea_row(tr('Description:'), 'long_description', null, 45, 3);
end_table();
start_table("$table_style2 width=40%");
// Add image upload for New Item  - by Joe
start_row();
label_cells(tr("Image File (.jpg)") . ":", "<input type='file' id='pic' name='pic'>");

if ($id != "") {
  $fileimg = $path_to_root."/image.php?id=".$id;
  $stock_img_link = "<img src='$fileimg' width='100px' border='0'>";
  $stock_img_link .= "<br>".tr("Delete").
                     "<input type='checkbox' name='deleteImage' value='1'>";
  label_cell($stock_img_link, "valign=top align=center rowspan=1");
}
end_row();
stock_categories_list_row(tr("Category:"), 'category_id', null);
item_tax_types_list_row(tr("Item Tax Type:"), 'tax_type_id', null);
stock_item_types_list_row(tr("Item Type:"), 'mb_flag', null,
	(!isset($_POST['NewStockID']) || isset($_POST['New'])));
stock_units_list_row(tr('Units of Measure:'), 'units', null,1);
//	(!isset($_POST['NewStockID']) || isset($_POST['New'])));
check_row(tr("Selling:"), 'selling');
text_row(tr("Depending:"), 'depending', null, 20, 20);
text_row(tr("Barcode:"), 'barcode', null, 20, 64);
amount_row(tr("Weight:"), 'weight', null);

end_table();
start_table("$table_style2 width=40%");
table_section_title(tr("GL Accounts"));

gl_all_accounts_list_row(tr("Sales Account:"), 'sales_account', 
                                     $_POST['sales_account']);
gl_all_accounts_list_row(tr("Inventory Account:"), 'inventory_account', 
                                         $_POST['inventory_account']);

if (!is_service($_POST['mb_flag'])) {
	gl_all_accounts_list_row(tr("C.O.G.S. Account:"), 
	        'cogs_account', $_POST['cogs_account']);
	gl_all_accounts_list_row(tr("Inventory Adjustments Account:"), 
	         'adjustment_account', $_POST['adjustment_account']);
} else {
	hidden('cogs_account', $_POST['cogs_account']);
	hidden('adjustment_account', $_POST['adjustment_account']);
}

if (is_manufactured($_POST['mb_flag'])) {
	gl_all_accounts_list_row(tr("Item Assembly Costs Account:"), 
	           'assembly_account', $_POST['assembly_account']);
} else {
	hidden('assembly_account', $_POST['assembly_account']);
}
$dim = get_company_pref('use_dimension');
if ($dim >= 1) {
	table_section_title(tr("Dimensions"));
	dimensions_list_row(tr("Dimension")." 1", 'dimension_id', 
	                             null, true, " ", false, 1);
	if ($dim > 1) {
		dimensions_list_row(tr("Dimension")." 2", 'dimension2_id', 
		                              null, true, " ", false, 2);
	}
}
if ($dim < 1) {
	hidden('dimension_id', 0);
}
if ($dim < 2) {
	hidden('dimension2_id', 0);
}

end_table(1);

if (!isset($_POST['NewStockID']) || 
   (isset($_POST['New']) && $_POST['New'] != "")) {
	submit_center('addupdate', tr("Insert New Item"));
} else {
	submit_center_first('addupdate', tr("Update Item"));
	submit_center_last('delete', tr("Delete This Item"));
}
end_form();
end_page();
?>
