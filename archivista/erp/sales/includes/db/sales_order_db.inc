<?php

//----------------------------------------------------------------------------------------
function get_demand_qty($stockid, $location)
{
	$sql = "SELECT SUM(sales_order_details.quantity - sales_order_details.qty_sent) AS QtyDemand
				FROM sales_order_details,
					sales_orders
				WHERE sales_order_details.order_no=sales_orders.order_no AND
					sales_orders.from_stk_loc ='$location' AND
					sales_order_details.stk_code = '$stockid'";

	$TransResult = db_query($sql,"No transactions were returned");
	$DemandRow = db_fetch($TransResult);
	return $DemandRow['QtyDemand'];
}

function get_demand_asm_qty($stockid, $location)
{
	$sql = "SELECT SUM((sales_order_details.quantity-sales_order_details.qty_sent)*bom.quantity)
				AS Dem
				FROM sales_order_details,
						sales_orders,
						bom,
						stock_master
				WHERE sales_order_details.stk_code=bom.parent AND
				sales_orders.order_no = sales_order_details.order_no AND
				sales_orders.from_stk_loc='$location' AND
				sales_order_details.quantity-sales_order_details.qty_sent > 0 AND
				bom.component='$stockid' AND
				stock_master.stock_id=bom.parent AND
				stock_master.mb_flag='A'";

	$TransResult = db_query($sql,"No transactions were returned");
	if (db_num_rows($TransResult)==1)
	{
		$DemandRow = db_fetch_row($TransResult);
		$DemandQty = $DemandRow[0];
	}
	else
		$DemandQty = 0.0;

	return $DemandQty;
}

function add_sales_order(&$order)
{
	global $loc_notification, $path_to_root;

	begin_transaction();

	$del_date = date2sql($order->due_date);
	$order_type = 0; // this is default on new order
	$sql = "INSERT INTO sales_orders (type, debtor_no, branch_code, customer_ref, comments, ord_date,
		order_type, ship_via, deliver_to, delivery_address, contact_phone,
		contact_email, freight_cost, from_stk_loc, delivery_date)
		VALUES (" .db_escape($order_type) . "," . db_escape($order->customer_id) .
		 ", " . db_escape($order->Branch) . ", ".
			db_escape($order->cust_ref) .",". 
			db_escape($order->Comments) .",'" . 
			date2sql($order->document_date) . "', " .
			db_escape($order->sales_type) . ", " .
			$_POST['ship_via'] ."," . 
			db_escape($order->deliver_to) . "," .
			db_escape($order->delivery_address) . ", " .
			db_escape($order->phone) . ", " . 
			db_escape($order->email) . ", " .
			db_escape($order->freight_cost) .", " . 
			db_escape($order->Location) .", " .
			db_escape($del_date) . ")";

	db_query($sql, "order Cannot be Added");

	$order_no = db_insert_id();
	$order->trans_no = array($order_no=>0);

	if ($loc_notification == 1)
	{
		include_once($path_to_root . "/inventory/includes/inventory_db.inc");
		$st_ids = array();
		$st_names = array();
		$st_num = array();
		$st_reorder = array();
	}
	foreach ($order->line_items as $line)
	{
		if ($loc_notification == 1 && is_inventory_item($line->stock_id))
		{
			$sql = "SELECT loc_stock.*, locations.location_name, locations.email
				FROM loc_stock, locations
				WHERE loc_stock.loc_code=locations.loc_code
				AND loc_stock.stock_id = '" . $line->stock_id . "'
				AND loc_stock.loc_code = '" . $order->Location . "'";
			$res = db_query($sql,"a location could not be retreived");
			$loc = db_fetch($res);
			if ($loc['email'] != "")
			{
				$qoh = get_qoh_on_date($line->stock_id, $order->Location);
				$qoh -= get_demand_qty($line->stock_id, $order->Location);
				$qoh -= get_demand_asm_qty($line->stock_id, $order->Location);
				$qoh -= $line->quantity;
				if ($qoh < $loc['reorder_level'])
				{
					$st_ids[] = $line->stock_id;
					$st_names[] = $line->item_description;
					$st_num[] = $qoh - $loc['reorder_level'];
					$st_reorder[] = $loc['reorder_level'];
				}
			}
		}

		$sql = "INSERT INTO sales_order_details (order_no, stk_code,description, unit_price, quantity, discount_percent,date_from,notes) VALUES (";
		$sql .= $order_no .
				",".db_escape($line->stock_id).", "
				.db_escape($line->item_description).", $line->price,
				$line->quantity,
				$line->discount_percent,".db_escape(date2sql($line->date_from)).",".
				db_escape($line->notes).")";

		db_query($sql, "order Details Cannot be Added");

	} /* inserted line items into sales order details */

	commit_transaction();

	if ($loc_notification == 1 && count($st_ids) > 0)
	{
		require_once($path_to_root . "/reporting/includes/class.mail.inc");
		$company = get_company_prefs();
		$mail = new email($company['coy_name'], $company['email']);
		$from = $company['coy_name'] . " <" . $company['email'] . ">";
		$to = $loc['location_name'] . " <" . $loc['email'] . ">";
		$subject = tr("Stocks below Re-Order Level at " . $loc['location_name']);
		$msg = "\n";
		for ($i = 0; $i < count($st_ids); $i++)
			$msg .= $st_ids[$i] . " " . $st_names[$i] . ", " . tr("Re-Order Level") . ": " . $st_reorder[$i] . ", " . tr("Below") . ": " . $st_num[$i] . "\n";
		$msg .= "\n" . tr("Please reorder") . "\n\n";
		$msg .= $company['coy_name'];
		$mail->to($to);
		$mail->subject($subject);
		$mail->text($msg);
		$ret = $mail->send();
	}
	return $order_no;
}

//----------------------------------------------------------------------------------------

function delete_sales_order($order_no)
{
	begin_transaction();

	$sql = "DELETE FROM sales_orders WHERE order_no=" . $order_no;
	db_query($sql, "order Header Delete");

	$sql = "DELETE FROM sales_order_details WHERE order_no =" . $order_no;
	db_query($sql, "order Detail Delete");

	commit_transaction();
}

//----------------------------------------------------------------------------------------
// Mark changes in sales_order_details
//
function update_sales_order_version($order)
{
  foreach ($order as $so_num => $so_ver) {
  $sql= 'UPDATE sales_orders SET version=version+1 WHERE order_no='. $so_num.
	' AND version='.$so_ver;
  db_query($sql, 'Concurrent editing conflict while sales order update');
  }
}

//----------------------------------------------------------------------------------------

function update_sales_order($order)
{
	global $loc_notification, $path_to_root;

	$del_date = date2sql($order->due_date);
	$ord_date = date2sql($order->document_date);
	$order_no =  key($order->trans_no);
	$version= current($order->trans_no);

	begin_transaction();

	$sql = "UPDATE sales_orders SET type =".$order->so_type." ,
		debtor_no = " . db_escape($order->customer_id) . ",
		branch_code = " . db_escape($order->Branch) . ",
		customer_ref = ". db_escape($order->cust_ref) .",
		comments = ". db_escape($order->Comments) .",
		ord_date = " . db_escape($ord_date) . ",
		order_type = " .db_escape($order->sales_type) . ",
		ship_via = " . db_escape($order->ship_via) .",
		deliver_to = " . db_escape($order->deliver_to) . ",
		delivery_address = " . db_escape($order->delivery_address) . ",
		contact_phone = " .db_escape($order->phone) . ",
		contact_email = " .db_escape($order->email) . ",
		freight_cost = " .db_escape($order->freight_cost) .",
		from_stk_loc = " .db_escape($order->Location) .",
		delivery_date = " .db_escape($del_date). ",
		version = ".($version+1)."
	 WHERE order_no=" . $order_no ."
	 AND version=".$version;
	db_query($sql, "order Cannot be Updated, this can be concurrent edition conflict");

	$sql = "DELETE FROM sales_order_details WHERE order_no =" . $order_no;

	db_query($sql, "Old order Cannot be Deleted");

	if ($loc_notification == 1)
	{
		include_once($path_to_root . "/inventory/includes/inventory_db.inc");
		$st_ids = array();
		$st_names = array();
		$st_num = array();
		$st_reorder = array();
	}
	foreach ($order->line_items as $line)
	{
		if ($loc_notification == 1 && is_inventory_item($line->stock_id))
		{
			$sql = "SELECT loc_stock.*, "
				  ."locations.location_name, "
				  ."locations.email
				FROM loc_stock, "
				  ."locations
				WHERE loc_stock.loc_code=locations.loc_code
				 AND loc_stock.stock_id = '" . $line->stock_id . "'
				 AND loc_stock.loc_code = '" . $order->Location . "'";
			$res = db_query($sql,"a location could not be retreived");
			$loc = db_fetch($res);
			if ($loc['email'] != "")
			{
				$qoh = get_qoh_on_date($line->stock_id, $order->Location);
				$qoh -= get_demand_qty($line->stock_id, $order->Location);
				$qoh -= get_demand_asm_qty($line->stock_id, $order->Location);
				$qoh -= $line->quantity;
				if ($qoh < $loc['reorder_level'])
				{
					$st_ids[] = $line->stock_id;
					$st_names[] = $line->item_description;
					$st_num[] = $qoh - $loc['reorder_level'];
					$st_reorder[] = $loc['reorder_level'];
				}
			}
		}
		$sql = "INSERT INTO sales_order_details
		 (order_no, stk_code,  description, unit_price, date_from, notes, quantity,
		  discount_percent, qty_sent)
		 VALUES (";
		$sql .= $order_no . ","
		  .db_escape($line->stock_id) . ","
		  .db_escape($line->item_description) . ", "
		  .db_escape($line->price) . ", "
		  .db_escape(date2sql($line->date_from)) . ", "
		  .db_escape($line->notes) . ", "
		  .db_escape($line->quantity) . ", "
		  .db_escape($line->discount_percent) . ", "
		  .db_escape($line->qty_done) ." )";

		db_query($sql, "Old order Cannot be Inserted");

	} /* inserted line items into sales order details */

	commit_transaction();
	if ($loc_notification == 1 && count($st_ids) > 0)
	{
		require_once($path_to_root . "/reporting/includes/class.mail.inc");
		$company = get_company_prefs();
		$mail = new email($company['coy_name'], $company['email']);
		$from = $company['coy_name'] . " <" . $company['email'] . ">";
		$to = $loc['location_name'] . " <" . $loc['email'] . ">";
		$subject = tr("Stocks below Re-Order Level at " . $loc['location_name']);
		$msg = "\n";
		for ($i = 0; $i < count($st_ids); $i++)
			$msg .= $st_ids[$i] . " " . $st_names[$i] . ", "
			  . tr("Re-Order Level") . ": " . $st_reorder[$i] . ", "
			  . tr("Below") . ": " . $st_num[$i] . "\n";
		$msg .= "\n" . tr("Please reorder") . "\n\n";
		$msg .= $company['coy_name'];
		$mail->to($to);
		$mail->subject($subject);
		$mail->text($msg);
		$ret = $mail->send();
	}
}

//----------------------------------------------------------------------------------------

function get_sales_order_header($order_no)
{
	$sql = "SELECT sales_orders.*, "
	  ."debtors_master.name, "
	  ."debtors_master.curr_code, "
	  ."locations.location_name, "
	  ."debtors_master.payment_terms, "
	  ."debtors_master.discount, "
	  ."sales_types.sales_type, "
	  ."sales_types.id AS sales_type_id, "
	  ."sales_types.tax_included, "
	  ."shippers.shipper_name, "
	  ."tax_groups.name AS tax_group_name , "
	  ."tax_groups.id AS tax_group_id
	FROM sales_orders, "
	  ."debtors_master, "
	  ."sales_types, "
	  ."tax_groups, "
	  ."cust_branch, "
	  ."locations, "
	  ."shippers
	WHERE sales_orders.order_type=sales_types.id
		AND cust_branch.branch_code = sales_orders.branch_code
		AND cust_branch.tax_group_id = tax_groups.id
		AND sales_orders.debtor_no = debtors_master.debtor_no
		AND locations.loc_code = sales_orders.from_stk_loc
		AND shippers.shipper_id = sales_orders.ship_via
		AND sales_orders.order_no = " . $order_no ;
	$result = db_query($sql, "order Retreival");

	$num = db_num_rows($result);
	if ($num > 1)
	{
		display_db_error("FATAL : sales order query returned a duplicate - " . db_num_rows($result), $sql, true);
	}
	else if ($num == 1)
	{
		return db_fetch($result);
	}
	else
		display_db_error("FATAL : sales order return nothing - " . db_num_rows($result), $sql, true);

}

//----------------------------------------------------------------------------------------

function get_sales_order_details($order_no) {
	$sql = "SELECT id, stk_code, unit_price, "
		."sales_order_details.description,"
		."sales_order_details.date_from,"
		."sales_order_details.notes,"
		."sales_order_details.quantity,
		  discount_percent,
		  qty_sent as qty_done, "
		."stock_master.units,
		stock_master.material_cost + "
			."stock_master.labour_cost + "
			."stock_master.overhead_cost AS standard_cost
	FROM sales_order_details, stock_master
	WHERE sales_order_details.stk_code = stock_master.stock_id
	AND order_no =" . $order_no . " ORDER BY id";

	return db_query($sql, "Retreive order Line Items");
}
//----------------------------------------------------------------------------------------

function read_sales_order($order_no, &$order)
{
	$myrow = get_sales_order_header($order_no);

	$order->trans_type = 30;
	$order->so_type =  $myrow["type"];
	$order->trans_no = array($order_no=> $myrow["version"]);

	$order->set_customer($myrow["debtor_no"], $myrow["name"],
	  $myrow["curr_code"], $myrow["discount"]);

	$order->set_branch($myrow["branch_code"], $myrow["tax_group_id"],
	  $myrow["tax_group_name"], $myrow["contact_phone"], $myrow["contact_email"]);

	$order->set_sales_type($myrow["sales_type_id"], $myrow["sales_type"], $myrow["tax_included"]);

	$order->set_location($myrow["from_stk_loc"], $myrow["location_name"]);

	$order->set_delivery($myrow["ship_via"], $myrow["deliver_to"],
	  $myrow["delivery_address"], $myrow["freight_cost"]);

	$order->cust_ref = $myrow["customer_ref"];
	$order->sales_type =$myrow["order_type"];
	$order->Comments = $myrow["comments"];
	$order->due_date = sql2date($myrow["delivery_date"]);
	$order->document_date = sql2date($myrow["ord_date"]);

	$result = get_sales_order_details($order_no);
	if (db_num_rows($result) > 0)
	{
		$line_no=0;
		while ($myrow = db_fetch($result))
		{
			$order->add_to_cart($line_no,$myrow["stk_code"],
			  sql2date($myrow["date_from"]),
			  $myrow["notes"],
			  $myrow["quantity"],
				$myrow["unit_price"], $myrow["discount_percent"],
				$myrow["qty_done"], $myrow["standard_cost"], $myrow["description"], $myrow["id"] );
		$line_no++;
		}
	}

	return true;
}

//----------------------------------------------------------------------------------------

function sales_order_has_deliveries($order_no)
{
	$sql = "SELECT SUM(qty_sent) FROM ".
	"sales_order_details WHERE order_no=$order_no";

	$result = db_query($sql, "could not query for sales order usage");

	$row = db_fetch_row($result);

	return ($row[0] > 0);
}

//----------------------------------------------------------------------------------------

function close_sales_order($order_no)
{
	// set the quantity of each item to the already sent quantity. this will mark item as closed.
	$sql = "UPDATE sales_order_details
		SET quantity = qty_sent,
			type = 0,
			WHERE order_no = $order_no";
	
	db_query($sql, "The sales order detail record could not be updated");
}

//---------------------------------------------------------------------------------------------------------------

function get_invoice_duedate($debtorno, $invdate)
{
	if (!is_date($invdate))
	{
		return Today();
	}
	$sql = "SELECT debtors_master.debtor_no, debtors_master.payment_terms, payment_terms.* FROM debtors_master,
		payment_terms WHERE debtors_master.payment_terms = payment_terms.terms_indicator AND
		debtors_master.debtor_no = '$debtorno'";

	$result = db_query($sql,"The customer details could not be retrieved");
	$myrow = db_fetch($result);

	if (db_num_rows($result) == 0)
		return $invdate;
	if ($myrow['day_in_following_month'] > 0)
		$duedate = add_days(end_month($invdate), $myrow['day_in_following_month']);
	else
		$duedate = add_days($invdate, $myrow['days_before_due']);
	return $duedate;
}

function get_customer_to_order($customer_id) {

	// Now check to ensure this account is not on hold */
	$sql = "SELECT debtors_master.name, "
		  ."debtors_master.address, "
		  ."credit_status.dissallow_invoices, "
		  ."debtors_master.sales_type AS salestype, "
		  ."sales_types.sales_type, "
		  ."sales_types.tax_included, "
		  ."debtors_master.curr_code, "
		  ."debtors_master.discount
		FROM debtors_master, "
		  ."credit_status, "
		  ."sales_types
		WHERE debtors_master.sales_type="
		  ."sales_types.id
		AND debtors_master.credit_status=credit_status.id
		AND debtors_master.debtor_no = '" . $customer_id . "'";

	$result =db_query($sql,"Customer Record Retreive");
	return 	db_fetch($result);
}

function get_branch_to_order($customer_id, $branch_id) {

    	// the branch was also selected from the customer selection so default the delivery details from the customer branches table cust_branch. The order process will ask for branch details later anyway
	 	$sql = "SELECT cust_branch.br_name, "
			."cust_branch.br_address, "
			."cust_branch.br_post_address, "
			."cust_branch.phone, "
			."cust_branch.email,
			  default_location, location_name, default_ship_via, "
			."tax_groups.name AS tax_group_name, "
			."tax_groups.id AS tax_group_id
			FROM cust_branch, "
			  ."tax_groups, "
			  ."locations
			WHERE cust_branch.tax_group_id = tax_groups.id
				AND locations.loc_code=default_location
				AND cust_branch.branch_code='" . $branch_id . "'
				AND cust_branch.debtor_no = '" . $customer_id . "'";

  	    return db_query($sql,"Customer Branch Record Retreive");
}
?>
