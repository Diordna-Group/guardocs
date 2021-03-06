<?php

//----------------------------------------------------------------------------------------

function get_customer_trans_details($debtor_trans_type, $debtor_trans_no)
{
if (!is_array($debtor_trans_no))
	$debtor_trans_no = array( 0=>$debtor_trans_no );

	$sql = "SELECT debtor_trans_details.*,
		debtor_trans_details.unit_price+debtor_trans_details.unit_tax AS FullUnitPrice,
		debtor_trans_details.description As StockDescription,
		debtor_trans_details.date_from as date_from,
		debtor_trans_details.notes as notes,
		stock_master.units
		FROM debtor_trans_details,stock_master
		WHERE (";

	$tr=array();
	foreach ($debtor_trans_no as $trans_no)
		$tr[] = 'debtor_trans_no='.$trans_no;

	$sql .= implode(' OR ', $tr);


	$sql.=	") AND debtor_trans_type=$debtor_trans_type
		AND stock_master.stock_id=debtor_trans_details.stock_id
		ORDER BY id";
	return db_query($sql, "The debtor transaction detail could not be queried");
}

//----------------------------------------------------------------------------------------

function void_customer_trans_details($type, $type_no)
{
	$sql = "UPDATE debtor_trans_details SET quantity=0, unit_price=0,
		unit_tax=0, discount_percent=0, standard_cost=0
		WHERE debtor_trans_no=$type_no
		AND debtor_trans_type=$type";

	db_query($sql, "The debtor transaction details could not be voided");

	// clear the stock move items
	void_stock_move($type, $type_no);
}
//----------------------------------------------------------------------------------------

function add_customer_trans_tax_detail_item($debtor_trans_type, $debtor_trans_no,
	$tax_type_id, $rate, $included_in_price, $amount)
{
	$sql = "INSERT INTO debtor_trans_tax_details (debtor_trans_no, debtor_trans_type, tax_type_id, rate, included_in_price, amount)
		VALUES ($debtor_trans_no, $debtor_trans_type, $tax_type_id, $rate, $included_in_price, $amount)";

	db_query($sql, "The debtor transaction tax detail could not be added");
}

//----------------------------------------------------------------------------------------

function get_customer_trans_tax_details($debtor_trans_type, $debtor_trans_no)
{
	$sql = "SELECT debtor_trans_tax_details.*, tax_types.name AS tax_type_name
		FROM debtor_trans_tax_details,tax_types
		WHERE debtor_trans_no=$debtor_trans_no
		AND debtor_trans_type=$debtor_trans_type
		AND amount != 0
		AND tax_types.id = debtor_trans_tax_details.tax_type_id";

	return db_query($sql, "The debtor transaction tax details could not be queried");
}

//----------------------------------------------------------------------------------------

function void_customer_trans_tax_details($type, $type_no)
{
	$sql = "UPDATE debtor_trans_tax_details SET amount=0
		WHERE debtor_trans_no=$type_no
		AND debtor_trans_type=$type";

	db_query($sql, "The debtor transaction tax details could not be voided");
}

//----------------------------------------------------------------------------------------

function write_customer_trans_detail_item($debtor_trans_type, $debtor_trans_no,
$stock_id, $description, $date_from, $notes,
	$quantity, $unit_price, $unit_tax, $discount_percent, $std_cost, $line_id=0)
{
	if ($line_id!=0)
		$sql = "UPDATE debtor_trans_details SET
			stock_id=".db_escape($stock_id).",
			description=".db_escape($description).",
			date_from=".db_escape(date2sql($date_from)).",
			notes=".db_escape($notes).",
			quantity=$quantity,
			unit_price=$unit_price,
			unit_tax=$unit_tax,
			discount_percent=$discount_percent,
			standard_cost=$std_cost WHERE
			id=$line_id";
	else
			$sql = "INSERT INTO debtor_trans_details (debtor_trans_no,
				debtor_trans_type, stock_id, description, date_from, notes, 
				quantity, unit_price, unit_tax, discount_percent, standard_cost) 
				VALUES ($debtor_trans_no, $debtor_trans_type, ".
			          db_escape($stock_id).", ".
								db_escape($description).", ".
								db_escape(date2sql($date_from)).",".
								db_escape($notes).",
				        $quantity, $unit_price, $unit_tax, 
								$discount_percent, $std_cost)";
		echo $sql;
	db_query($sql, "The debtor transaction detail could not be written");
}

?>
