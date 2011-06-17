<?php

function get_wo_requirements($woid)
{
	$sql = "SELECT wo_requirements.*, stock_master.description,
		stock_master.mb_flag, 
		locations.location_name, 
		workcentres.name AS WorkCentreDescription FROM 
		(wo_requirements, locations, workcentres) INNER JOIN stock_master ON 
		wo_requirements.stock_id = stock_master.stock_id 
		WHERE workorder_id=$woid
		AND locations.loc_code = wo_requirements.loc_code
		AND workcentres.id=workcentre";

	return db_query($sql, "The work order requirements could not be retrieved");    
}

//--------------------------------------------------------------------------------------

function create_wo_requirements($woid, $stock_id)
{
	// create Work Order Requirements based on the bom
	$result = get_bom($stock_id);	
	
	while ($myrow = db_fetch($result)) 
	{
		
		$sql = "INSERT INTO wo_requirements (workorder_id, stock_id, workcentre, units_req, loc_code)
			VALUES ($woid, '" .
			$myrow["component"] . "', '"	.
			$myrow["workcentre_added"] . "', '"	.
			$myrow["quantity"] . "', '"	.
			$myrow["loc_code"] . "')";
			
        db_query($sql, "The work order requirements could not be added");
	}		
}

//--------------------------------------------------------------------------------------

function delete_wo_requirements($woid)
{
	$sql="DELETE FROM wo_requirements WHERE workorder_id=$woid";
	db_query($sql,"The work order requirements could not be deleted");	
}


//--------------------------------------------------------------------------------------

function update_wo_requirement_issued($woReqID, $quantity)
{
	$sql = "UPDATE wo_requirements SET units_issued = units_issued + $quantity
		WHERE id = '$woReqID'";
				
	db_query($sql, "The work requirements issued quantity couldn't be updated");
}

//--------------------------------------------------------------------------------------

function void_wo_requirements($woid)
{
	$sql = "UPDATE wo_requirements SET units_issued = 0 WHERE workorder_id = $woid";
				
	db_query($sql, "The work requirements issued quantity couldn't be voided");	
}

//--------------------------------------------------------------------------------------

?>