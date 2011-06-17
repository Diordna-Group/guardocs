<?php

function work_order_produce($woid, $ref, $quantity, $date_, $memo_, $close_wo)
{
	begin_transaction();

	$details = get_work_order($woid);

    if (strlen($details[0]) == 0)
    {
    	echo tr("The order number sent is not valid.");
    	exit;
    }

	if (work_order_is_closed($woid))
	{
		display_error("UNEXPECTED : Producing Items for a closed Work Order");
		cancel_transaction();
		exit;
	}

    $date = date2sql($date_);

    $sql = "INSERT INTO wo_manufacture (workorder_id, reference, quantity, date_)
		VALUES ($woid, ".db_escape($ref).", $quantity, '$date')";

	db_query($sql,"A work order manufacture could not be added");

	$id = db_insert_id();

	// insert a +ve stock move for the item being manufactured
	// negative means "unproduce" or unassemble
	add_stock_move(29, $details["stock_id"], $id,
		$details["loc_code"], $date_, $memo_, $quantity, 0);

	// update wo quantity and close wo if requested
	work_order_update_finished_quantity($woid, $quantity, $close_wo);

	if ($memo_)
		add_comments(29, $id, $date_, $memo_);

	references::save_last($ref, 29);

	commit_transaction();
}

//--------------------------------------------------------------------------------------------

function get_work_order_produce($id)
{
	$sql = "SELECT wo_manufacture.*,workorders.stock_id, stock_master.description AS StockDescription
		FROM wo_manufacture, workorders, stock_master
		WHERE wo_manufacture.workorder_id=workorders.id
		AND stock_master.stock_id=workorders.stock_id
		AND wo_manufacture.id=$id";
    $result = db_query($sql, "The work order production could not be retrieved");

    return db_fetch($result);
}

//--------------------------------------------------------------------------------------

function get_work_order_productions($woid)
{
	$sql = "SELECT * FROM wo_manufacture WHERE workorder_id=$woid ORDER BY id";
    return db_query($sql, "The work order issues could not be retrieved");
}

//--------------------------------------------------------------------------------------

function exists_work_order_produce($id)
{
	$sql = "SELECT id FROM wo_manufacture WHERE id=$id";
	$result = db_query($sql, "Cannot retreive a wo production");

    return (db_num_rows($result) > 0);
}

//--------------------------------------------------------------------------------------------

function void_work_order_produce($type_no)
{
	begin_transaction();

	$row = get_work_order_produce($type_no);

	// deduct the quantity of this production from the parent work order
	work_order_update_finished_quantity($row["workorder_id"], -$row["quantity"]);

	// clear the production record
	$sql = "UPDATE wo_manufacture SET quantity=0 WHERE id=$type_no";
	db_query($sql, "Cannot void a wo production");

	// void all related stock moves
	void_stock_move(29, $type_no);

	// void any related gl trans
	void_gl_trans(29, $type_no, true);

	commit_transaction();
}


?>