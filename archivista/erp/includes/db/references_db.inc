<?php

//--------------------------------------------------------------------------------------------------

function get_reference($type, $id)
{
	$sql = "SELECT * FROM refs WHERE type=$type AND id=$id";

	return db_query($sql, "could not query reference table");
}

//--------------------------------------------------------------------------------------------------

function add_reference($type, $id, $reference)
{
	$sql = "INSERT INTO refs (type, id, reference)
		VALUES ($type, $id, " . db_escape(trim($reference)) . ")";

	db_query($sql, "could not add reference entry");
}

//--------------------------------------------------------------------------------------------------

function delete_reference($type, $id)
{
	$sql = "DELETE FROM refs WHERE type=$type AND id=$id";

	return db_query($sql, "could not delete from reference table");
}

//--------------------------------------------------------------------------------------------------

function find_reference($type, $reference)
{
	$sql = "SELECT id FROM refs WHERE type=$type AND reference='$reference'";

	$result = db_query($sql, "could not query reference table");

    return (db_num_rows($result) > 0);
}

//--------------------------------------------------------------------------------------------------

function save_next_reference($type, $reference)
{
    $sql = "UPDATE sys_types SET next_reference=" . db_escape(trim($reference)) . " WHERE type_id = $type";

	db_query($sql, "The next transaction ref for $type could not be updated");
}

//--------------------------------------------------------------------------------------------------

function get_next_reference($type)
{
    $sql = "SELECT next_reference FROM sys_types WHERE type_id = $type";

    $result = db_query($sql,"The last transaction ref for $type could not be retreived");

    $row = db_fetch_row($result);
    return $row[0];
}

?>