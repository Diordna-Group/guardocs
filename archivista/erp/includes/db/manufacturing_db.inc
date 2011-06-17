<?php

function get_mb_flag($stock_id)
{
	$sql = "SELECT mb_flag FROM stock_master WHERE stock_id = '" . $stock_id . "'";
	$result = db_query($sql, "retreive mb_flag from item");
	
	if (db_num_rows($result) == 0)
		return -1;

	$myrow = db_fetch_row($result);
	return $myrow[0];
}

//--------------------------------------------------------------------------------------

function get_bom($item)
{
	$sql = "SELECT bom.*, locations.location_name, workcentres.name AS WorkCentreDescription, 
    	stock_master.description, stock_master.mb_flag AS ResourceType, 
    	stock_master.material_cost+ stock_master.labour_cost+stock_master.overhead_cost AS standard_cost, units, 
    	bom.quantity * (stock_master.material_cost+ stock_master.labour_cost+ stock_master.overhead_cost) AS ComponentCost 
    	FROM (workcentres, locations, bom) INNER JOIN stock_master ON bom.component = stock_master.stock_id 
    	WHERE bom.parent = '" . $item . "'
		AND workcentres.id=bom.workcentre_added
		AND bom.loc_code = locations.loc_code ORDER BY bom.id";
	
	return db_query($sql, "The bill of material could not be retrieved");
}

//--------------------------------------------------------------------------------------

function has_bom($item)
{
    $result = get_bom($item);
    
    return (db_num_rows($result) != 0);
}

//--------------------------------------------------------------------------------------

?>