<?php

function add_tax_type($name, $sales_gl_code, $purchasing_gl_code, $rate)
{
	$sql = "INSERT INTO tax_types (name, sales_gl_code, purchasing_gl_code, rate)
		VALUES (".db_escape($name).", ".db_escape($sales_gl_code)
		.", ".db_escape($purchasing_gl_code).", $rate)";

	db_query($sql, "could not add tax type");
}

function update_tax_type($type_id, $name, $sales_gl_code, $purchasing_gl_code, $rate)
{
	$sql = "UPDATE tax_types SET name=".db_escape($name).",
		sales_gl_code=".db_escape($sales_gl_code).",
		purchasing_gl_code=".db_escape($purchasing_gl_code).",
		rate=$rate
		WHERE id=$type_id";

	db_query($sql, "could not update tax type");
}

function get_all_tax_types()
{
	$sql = "SELECT tax_types.*,
		Chart1.account_name AS SalesAccountName,
		Chart2.account_name AS PurchasingAccountName
		FROM tax_types, chart_master AS Chart1,
		chart_master AS Chart2
		WHERE tax_types.sales_gl_code = Chart1.account_code
		AND tax_types.purchasing_gl_code = Chart2.account_code";

	return db_query($sql, "could not get all tax types");
}

function get_all_tax_types_simple()
{
	$sql = "SELECT * FROM tax_types";

	return db_query($sql, "could not get all tax types");
}

function get_tax_type($type_id)
{
	$sql = "SELECT tax_types.*,
		Chart1.account_name AS SalesAccountName,
		Chart2.account_name AS PurchasingAccountName
		FROM tax_types, chart_master AS Chart1,
		chart_master AS Chart2
		WHERE tax_types.sales_gl_code = Chart1.account_code
		AND tax_types.purchasing_gl_code = Chart2.account_code AND id=$type_id";

	$result = db_query($sql, "could not get tax type");

	return db_fetch($result);
}

function get_tax_type_default_rate($type_id)
{
	$sql = "SELECT rate FROM tax_types WHERE id=$type_id";

	$result = db_query($sql, "could not get tax type rate");

	$row = db_fetch_row($result);
	return $row[0];
}

function delete_tax_type($type_id)
{
	begin_transaction();

	$sql = "DELETE FROM tax_types WHERE id=$type_id";

	db_query($sql, "could not delete tax type");

	// also delete any item tax exemptions associated with this type
	$sql = "DELETE FROM item_tax_type_exemptions WHERE tax_type_id=$type_id";

	db_query($sql, "could not delete item tax type exemptions");

	commit_transaction();
}

?>