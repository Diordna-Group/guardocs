<?php

include_once($path_to_root . "/includes/banking.inc");
include_once($path_to_root . "/includes/db/inventory_db.inc");
include_once($path_to_root . "/sales/includes/db/sales_order_db.inc");
include_once($path_to_root . "/sales/includes/db/sales_credit_db.inc");
include_once($path_to_root . "/sales/includes/db/sales_invoice_db.inc");
include_once($path_to_root . "/sales/includes/db/sales_delivery_db.inc");
include_once($path_to_root . "/sales/includes/db/custalloc_db.inc");
include_once($path_to_root . "/sales/includes/db/cust_trans_db.inc");
include_once($path_to_root . "/sales/includes/db/cust_trans_details_db.inc");
include_once($path_to_root . "/sales/includes/db/payment_db.inc");
include_once($path_to_root . "/sales/includes/db/branches_db.inc");
include_once($path_to_root . "/sales/includes/db/customers_db.inc");

//----------------------------------------------------------------------------------------
// $price in customer's currency
// $quantity is used as is (if it's neg it's neg, if it's pos it's pos)
// $std_cost is in home currency
// $show_or_hide 1 show this item in invoice/credit views, 0 to hide it (used for write-off items)
// $type is 10 (invoice) or 11 (credit)

function add_stock_move_customer($type, $stock_id, $trans_id, $location, $date_, $reference,
	$quantity, $std_cost, $show_or_hide=1, $price=0, $discount_percent=0)
{
	return add_stock_move($type, $stock_id, $trans_id, $location, $date_, $reference,
		$quantity, $std_cost, 0, $show_or_hide, $price, $discount_percent,
		"The customer stock movement record cannot be inserted");
}

//----------------------------------------------------------------------------------------
// add a debtor-related gl transaction
// $date_ is display date (non-sql)
// $amount is in CUSTOMER'S currency

function add_gl_trans_customer($type, $type_no, $date_, $account, $dimension, $dimension2,
	$amount, $customer_id, $err_msg="")
{
	if ($err_msg == "")
		$err_msg = "The customer GL transaction could not be inserted";

	return add_gl_trans($type, $type_no, $date_, $account, $dimension, $dimension2, "", $amount,
		get_customer_currency($customer_id),
		payment_person_types::customer(), $customer_id, $err_msg);
}

//----------------------------------------------------------------------------------------

function get_price ($stock_id, $currency, $sales_type_id)
{
  // Extended version of getting a price (c) by Archivista GmbH, Urs Pfister, 
	// 2008/04/22 -- 2010/02/24
	// There must be a field factor in table prices. If so, you can have 1 price 
	// and all other prices can be entered with a factor (0.7) = discount of 30%
	// Advantage of this is that you only have to update one price if you want to
	// change prices. It even works with currencies. In this case it gose to the
	// home currency and checks for the appropriate price
	// You even can define a factor in sales_types, so the price will be
	// calculated from this table, if you don't have a factor price in price list
	
  // First we check if we have a price for the currency and sales type
  $msg = "There was a problem retrieving the pricing " .
	       "information for the part $stock_id for customer";
				 
	$price = 0; // as soon as not 0, we did find a price
	$factor = 1; // price calculation according factors
	$date = Today(); // current date (actually it should be document_date!!!!!!!)
	$rate_currency = get_exchange_rate_from_home_currency($currency, $date);
  $home_currency = get_company_currency(); # home currency for unique price
	
	$sql_check = "SHOW COLUMNS FROM prices LIKE 'factor'";
	$field="price"; // if factor is not available, we use price
	$result = db_query($sql_check, $msg);
  if (db_num_rows($result) != 0) {
		$myrow = db_fetch_row($result);
		$field = $myrow[0];
	}

	$sql_select = "SELECT prices.price".
 	              ",prices.".$field.
		            " FROM prices".
	              " WHERE prices.stock_id = '" . $stock_id . "' ";

	$sql_type = "AND prices.sales_type_id = " . $sales_type_id . " ";
	$sql_curr = "AND prices.curr_abrev = '$currency' ";
	$sql_curr_home = "AND prices.curr_abrev = '$home_currency' ";
	$sql_price = "AND prices.price > 0 ";
	$sql_order = "ORDER BY prices.price DESC LIMIT 1"; // if no sales type

	$sql = $sql_select . $sql_type . $sql_curr . $sql_price;
	$result = db_query($sql, $msg);
	if (db_num_rows($result) != 0) {
		/*There is a price from one of the above so return that */
		$myrow = db_fetch_row($result);
		$price = $myrow[0];
	}

	if ($price == 0) { // check for price in home currency with sales type
	  $sql = $sql_select . $sql_type . $sql_curr_home . $sql_price;
	  $result = db_query($sql, $msg);
	  if (db_num_rows($result) != 0) {
		  // There is a price, so let us adjust currency rate
		  $myrow = db_fetch_row($result);
		  $price = $myrow[0] / $rate_currency;
		}
	}

	if ($price == 0) { // check for base price in home currency (no sales type)
    $sql = $sql_select . $sql_curr_home . $sql_price . $sql_order;
	  $result = db_query($sql, $msg);
	  if (db_num_rows($result) != 0) {
		  $myrow = db_fetch_row($result);
		  $price = $myrow[0];
			if ($price>0) {
		    // There is a price, so let us check if we have factor based price
	      $sql = $sql_select . $sql_curr_home . $sql_type;
	      $result = db_query($sql, $msg);
	      if (db_num_rows($result) != 0) {
		      $myrow = db_fetch_row($result);
				  $factor = $myrow[1];
				}
			}
				
			if ($factor==1) {
  			# we have a global price for a given customer group (i.e. reseller)
	  		$sql = "SELECT price_factor from ".
		           "sales_types WHERE id = " . $sales_type_id;
  	    $result = db_query($sql, $msg);
	  	  $myrow = db_fetch_row($result);
		    $factor = $myrow[0];
			}
			$price = ($price * $factor) / $rate_currency;
		}
	}
	if ($currency == 'CHF') {
	  $price = (floatval((intval(round($price*20),0)))/20);
	}
	return $price;
}

//-----------------------------------------------------------------------------

function set_document_parent($cart)
{
	$inv_no = key($cart->trans_no);

	if (count($cart->src_docs) == 1) {

	// if this child document has only one parent - update child link
	$del_no = key($cart->src_docs);

	$sql = 'UPDATE debtor_trans SET trans_link = ' . $del_no .
		' WHERE type='.$cart->trans_type.' AND trans_no='. $inv_no ;
	db_query($sql, 'Child document link cannot be updated');

	}
	if ($cart->trans_type != 10)
		return 0;

	// the rest is batch invoice specific

	foreach ($cart->line_items as $line) {
		if ($line->quantity != $line->qty_dispatched) {
			return 1;	// this is partial invoice
		}
	}

	$sql = 'UPDATE debtor_trans SET trans_link = ' . $inv_no .
	' WHERE type='.get_parent_type($cart->trans_type).' AND (';

	$deliveries = array_keys($cart->src_docs);

	foreach ($deliveries as $key=>$del)
		$deliveries[$key] = 'trans_no='.$del;

	$sql .= implode(' OR ', $deliveries) . ')';
	db_query($sql, 'Delivery links cannot be updated');

	return 0; // batch or complete invoice
}

//--------------------------------------------------------------------------------------------------
function get_parent_type($type)
{
	$parent_types = array( 11=>10, 10=>13, 13=>30 );
	return isset($parent_types[$type]) ?  $parent_types[$type] : 0;
}

//--------------------------------------------------------------------------------------------------
function update_parent_line($doc_type, $line_id, $qty_dispatched)
{
	$doc_type = get_parent_type($doc_type);

	//echo "update line: $line_id, $doc_type, $qty_dispatch";
	if ($doc_type==0)
		return false;
	else {
		if ($doc_type==30)
			$sql = "UPDATE sales_order_details
				SET qty_sent = qty_sent + $qty_dispatched
				WHERE id=$line_id";
		else
			$sql = "UPDATE debtor_trans_details
				SET qty_done = qty_done + $qty_dispatched
				WHERE id=$line_id";
	}
	db_query($sql, "The parent document detail record could not be updated");
	return true;
}

//--------------------------------------------------------------------------------------------------
// find inventory location for given transaction
//
function get_location(&$cart)
{
	$sql = "SELECT locations.* FROM stock_moves,".
		"locations".
		" WHERE type=".$cart->trans_type.
		" AND trans_no=".key($cart->trans_no).
		" AND qty!=0 ".
		" AND locations.loc_code=stock_moves.loc_code";
	$result = db_query($sql, 'Retreiving inventory location');


	if (db_num_rows($result)) {
		return db_fetch($result);
	}
	return null;
}
//--------------------------------------------------------------------------------------------------
// Generic read debtor transaction into cart
//
//	$trans_no - array of trans nums; special case trans_no==0 - new doc
//
function read_sales_trans($doc_type, $trans_no, &$cart)
{
	if (!is_array($trans_no) && $trans_no)
			$trans_no = array($trans_no);

	$cart->trans_type = $doc_type;
	if (!$trans_no) { // new document
		$cart->trans_no = $trans_no;
	} else {
		// read header data from first document
		$myrow = get_customer_trans($trans_no[0],$doc_type);
		if (count($trans_no)>1)
			$cart->trans_no = get_customer_trans_version($doc_type, $trans_no);
		else
			$cart->trans_no = array($trans_no[0]=>$myrow["version"]);

		$cart->set_sales_type($myrow["tpe"], $myrow["sales_type"], $myrow["tax_included"]);

		$cart->set_customer($myrow["debtor_no"], $myrow["DebtorName"],
			$myrow["curr_code"], $myrow["discount"]);

		$cart->set_branch($myrow["branch_code"], $myrow["tax_group_id"],
			$myrow["tax_group_name"],	$myrow["phone"], $myrow["email"]);

		$cart->reference = $myrow["reference"];
		$cart->order_no = $myrow["order_"];
		$cart->trans_link = $myrow["trans_link"];
		$cart->due_date = sql2date($myrow["due_date"]);
		$cart->document_date = sql2date($myrow["tran_date"]);

		$cart->Comments = '';
		foreach ( $trans_no as $trans ) {
			$coms =  get_comments($doc_type,$trans);
			while($row=db_fetch($coms)) {
				$text = $row['memo_'];
				if ($text!='') {
					if ($cart->Comments!='')
						$cart->Comments .= "\n";
					$cart->Comments .= $text;
				}
			}
		}

		// FIX this should be calculated sum() for multiply parents

		$cart->set_delivery($myrow["ship_via"], $myrow["br_name"],
		$myrow["br_address"], $myrow["ov_freight"]);

		$location = 0;
		$myrow = get_location($cart); // find location from movement

		if($myrow!=null) {
			$cart->set_location($myrow['loc_code'], $myrow['location_name']);
		}

		$result = get_customer_trans_details($doc_type,$trans_no);
		if (db_num_rows($result) > 0) {
			for($line_no=0; $myrow = db_fetch($result); $line_no++)	{
				$cart->add_to_cart($line_no,$myrow["stock_id"],
				  sql2date($myrow["date_from"]),
					$myrow["notes"],
				  $myrow["quantity"],
					$myrow["unit_price"], $myrow["discount_percent"],
					$myrow["qty_done"], $myrow["standard_cost"],
					$myrow["StockDescription"],$myrow["id"], $myrow["debtor_trans_no"]);
			}
		}
	} // !newdoc

	return true;
}
//----------------------------------------------------------------------------------------
?>
