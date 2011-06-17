<?php

function add_item_price($stock_id, $sales_type_id, $curr_abrev, $price=0,$factor=0)
{
  if ($factor == '') { $factor = 0; }
  if ($price == '') { $price = 0; }
	
	$sql = "INSERT INTO prices ".
	  "(stock_id,sales_type_id,curr_abrev,price,factor) ".
		"VALUES ('$stock_id', $sales_type_id, '$curr_abrev', $price, $factor)";
	db_query($sql,"an item price could not be added");		
}

function update_item_price($price_id, $sales_type_id, $curr_abrev, $price=0, $factor=0)
{

  if ($factor == '') { $factor = 0; }
  if ($price == '') { $price = 0; }
	
	$sql = "UPDATE prices SET sales_type_id=$sales_type_id, ".
		     "curr_abrev='$curr_abrev', price=$price, factor=$factor ".
				 " WHERE id=$price_id";
	db_query($sql,"an item price could not be updated");		
}

function delete_item_price($price_id)
{
	$sql="DELETE FROM prices WHERE id= $price_id";
	db_query($sql,"an item price could not be deleted");			
}

function get_prices($stock_id)
{
	$sql = "SELECT sales_types.sales_type, prices.* 
		FROM prices, sales_types 
		WHERE prices.sales_type_id = sales_types.id 
		AND stock_id='$stock_id' ORDER BY curr_abrev, sales_type_id";	
	
	return db_query($sql,"item prices could not be retreived");
}

function get_stock_price($price_id)
{
	$sql = "SELECT * FROM prices	WHERE id=$price_id";	
	
	$result = db_query($sql,"price could not be retreived");
	
	return db_fetch($result);
}

?>
