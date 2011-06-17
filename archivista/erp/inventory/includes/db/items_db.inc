<?php

function check_numvals(&$selling,&$weight) {
  if ($selling == "") {
	  $selling=0;
	}
	if ($weight == "") {
    $weight=0;
	}
  $weight = user_numeric($weight);
	$selling = user_numeric($selling);
}

function update_item($stock_id, $description, $long_description, $category_id, $tax_type_id,
	$sales_account, $inventory_account, $cogs_account, $adjustment_account,
	$assembly_account, $dimension_id, $dimension2_id,
	$selling,$depending,$barcode,$weight,$blob,$units)
{
  check_numvals($selling,$weight);
	$sql = "UPDATE stock_master SET long_description=".db_escape($long_description).",
		description=".db_escape($description).",
		category_id='$category_id',
		sales_account='$sales_account',
		inventory_account='$inventory_account',
		cogs_account='$cogs_account',
		adjustment_account='$adjustment_account',
		assembly_account='$assembly_account',
		dimension_id=$dimension_id,
		dimension2_id=$dimension2_id,
		selling=$selling,
		depending=".db_escape($depending).",
		barcode=".db_escape($barcode).",
		units=".db_escape($units).",
		weight=$weight,";
		
  if ($blob != "") {
	  $sql .= "image='".$blob."',";
	}
	$sql .= "tax_type_id=$tax_type_id
		WHERE stock_id='$stock_id'";

	db_query($sql, "The item could not be updated");
}

function add_item($stock_id, $description, $long_description, $category_id, $tax_type_id, $units, $mb_flag,
	$sales_account, $inventory_account, $cogs_account, $adjustment_account,
	$assembly_account, $dimension_id, $dimension2_id,
	$selling,$depending,$barcode,$weight,$blob)
{
  check_numvals($selling,$weight);
	$sql = "INSERT INTO stock_master (stock_id, description, long_description, category_id,
		tax_type_id, units, mb_flag, sales_account, inventory_account, cogs_account,
		adjustment_account, assembly_account, dimension_id, dimension2_id,
		selling, depending, barcode, weight, image)
		VALUES (".db_escape($stock_id).", ".db_escape($description).", ".db_escape($long_description).",
		'$category_id', $tax_type_id, '$units', '$mb_flag',
		'$sales_account', '$inventory_account', '$cogs_account',
		'$adjustment_account', '$assembly_account', $dimension_id, $dimension2_id,
		$selling, ".db_escape($depending).",".db_escape($barcode).",
		".$weight.",'".$blob."')";

	db_query($sql, "The item could not be added");

	$sql = "INSERT INTO loc_stock (loc_code, stock_id)
		SELECT locations.loc_code, '$stock_id' FROM locations";

	db_query($sql, "The item locstock could not be added");
}

function delete_item($stock_id)
{
	$sql="DELETE FROM stock_master WHERE stock_id='$stock_id'";
	db_query($sql, "could not delete stock item");

	/*and cascade deletes in loc_stock */
	$sql ="DELETE FROM loc_stock WHERE stock_id='$stock_id'";
	db_query($sql, "could not delete stock item loc stock");

	/*and cascade deletes in purch_data */
	$sql ="DELETE FROM purch_data WHERE stock_id='$stock_id'";
	db_query($sql, "could not delete stock item purch data");

	/*and cascade deletes in prices */
	$sql ="DELETE FROM prices WHERE stock_id='$stock_id'";
	db_query($sql, "could not delete stock item prices");

	/*and cascade delete the bill of material if any */
	$sql = "DELETE FROM bom WHERE parent='$stock_id'";
	db_query($sql, "could not delete stock item bom");
}

function get_item($stock_id)
{
	$sql = "SELECT stock_master.*,item_tax_types.name AS tax_type_name
		FROM stock_master,item_tax_types
		WHERE item_tax_types.id=stock_master.tax_type_id
		AND stock_id='$stock_id'";
	$result = db_query($sql,"an item could not be retreived");

	return db_fetch($result);
}

function get_items()
{
	$sql = "SELECT * FROM stock_master";
	return db_query($sql,"items could not be retreived");
}

?>
