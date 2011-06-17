<?php

function add_bank_trans_type($name)
{
	$sql = "INSERT INTO bank_trans_types (name) VALUES (".db_escape($name).")";

	db_query($sql, "could not add bank transaction type");
}

function update_bank_trans_type($type_id, $name)
{
	$sql = "UPDATE bank_trans_types SET name=".db_escape($name)."	WHERE id=$type_id";

	db_query($sql, "could not update bank transaction type");
}

function get_all_bank_trans_type()
{
	$sql = "SELECT * FROM bank_trans_types";

	return db_query($sql, "could not get all bank transaction type");
}

function get_bank_trans_type($type_id)
{
	$sql = "SELECT * FROM bank_trans_types WHERE id=$type_id";

	$result = db_query($sql, "could not get bank transaction type");

	return db_fetch($result);
}

function delete_bank_trans_type($type_id)
{
	$sql="DELETE FROM bank_trans_types WHERE id=$type_id";

	db_query($sql, "could not delete bank transaction type");
}

?>