<?php

function write_item_translation($selected, $id_stock, $description,$long_description,$areas)
{
  if($selected!='')
		$sql = "UPDATE item_translations SET ".
	 	  "id_stock = ".db_escape($id_stock).",".
	 	  "description = ".db_escape($description).",".
	 	  "long_description = ".db_escape($long_description).",".
	 	  "areas = ".db_escape($areas)." ".
      "WHERE id = $selected";
  else
		$sql = "INSERT INTO item_translations ".
			"(id_stock, description, long_description, areas) VALUES( ".
			db_escape($id_stock).",".
			db_escape($description).",".
	  	db_escape($long_description).",".
			db_escape($areas).")";

	db_query($sql,"an item translation could not be updated");
}

function delete_item_translation($id)
{
	$sql="DELETE FROM item_translations WHERE id=$id";

	db_query($sql,"an item translation could not be deleted");
}

function get_item_translation($id)
{
	$sql="SELECT * FROM item_translations WHERE id=$id";

	$result = db_query($sql,"an item translation could not be retrieved");

	return db_fetch($result);
}

function get_item_description($id)
{
	$sql = "SELECT description FROM item_translations WHERE id=$id";

	$result = db_query($sql, "could not item translation");

	$row = db_fetch_row($result);
	return $row[0];
}

function item_translation_used($id) {
	$sql= "SELECT COUNT(*) FROM item_translations WHERE id=$id";
	$result = db_query($sql, "could not query item translations");
	$myrow = db_fetch_row($result);
	return ($myrow[0] > 0);
}


function get_all_item_translations() {
    $sql = "SELECT * FROM item_translations ORDER BY id_stock,id";
    return  db_query($sql, "could not get item translations");
}
?>
