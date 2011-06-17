<?php
//------------------------------------------------------------------------------
//	Retreive parent document number(s) for given transaction
//
function get_parent_trans($trans_type, $trans_no) {

	$sql = 'SELECT trans_link FROM debtor_trans WHERE '.
			'(trans_no=' .$trans_no. ' AND type='.$trans_type.' AND trans_link!=0)';

	$result = db_query($sql, 'Parent document numbers cannot be retrieved');

	if (db_num_rows($result)) {
		$link = db_fetch($result);
		return array($link['trans_link']);
	}
	if ($trans_type!=10) return 0;	// this is credit note with no parent invoice
	// invoice: find batch invoice parent trans.
	$sql = 'SELECT trans_no FROM debtor_trans WHERE '.
			'(trans_link='.$trans_no.' AND type='. get_parent_type($trans_type) .')';

	$result = db_query($sql, 'Delivery links cannot be retrieved');

	$delivery = array();
	if(db_num_rows($result)>0) {
		while($link = db_fetch($result)) {
			$delivery[] = $link['trans_no'];
		}
	}
	return count($delivery) ? $delivery : 0;
}

//----------------------------------------------------------------------------------------
// Mark changes in debtor_trans_details
//
function update_customer_trans_version($type, $versions) {

	$sql= 'UPDATE debtor_trans SET version=version+1
			WHERE type='.$type. ' AND (';

	foreach ($versions as $trans_no=>$version)
		$where[] = 	'(trans_no='.$trans_no.
			' AND version='.$version.')';

		$sql .= implode(' OR ', $where) .')';

	return  db_query($sql, 'Concurrent editing conflict');
}

//----------------------------------------------------------------------------------------
// Gets document header versions for transaction set of type $type
// $trans_no = array(num1, num2,...);
// returns array(num1=>ver1, num2=>ver2...)
//
function get_customer_trans_version($type, $trans_no) {
	if (!is_array($trans_no))
		$trans_no = array( $trans_no );

	$sql= 'SELECT trans_no, version FROM debtor_trans
			WHERE type='.$type.' AND (';

	foreach ($trans_no as $key=>$trans)
		$trans_no[$key] = 	'trans_no='.$trans_no[$key];

	$sql .= implode(' OR ', $trans_no) . ')';

	$res = db_query($sql, 'document version retreival');

	$vers = array();
	while($mysql=db_fetch($res)) {
		$vers[$mysql['trans_no']] = $mysql['version'];
	}
	return $vers;
}
//----------------------------------------------------------------------------------------
// $Total, $Tax, $Freight, $discount all in customer's currency
// date_ is display date (non-sql)
function write_customer_trans($trans_type, $trans_no, $debtor_no, $BranchNo,
	$date_, $reference, $Total, $discount=0, $Tax=0, $Freight=0, $FreightTax=0,
	$sales_type=0, $order_no=0, $trans_link=0, $ship_via="", $due_date=null,
	$AllocAmt=0)
{

	$curr = get_customer_currency($debtor_no);
	$rate = get_exchange_rate_from_home_currency($curr, $date_);

	$SQLDate = date2sql($date_);
	$SQLDueDate = date2sql($due_date);

	if ($trans_no==0) {
	$trans_no = get_next_trans_no($trans_type);

	$sql = "INSERT INTO debtor_trans (
		trans_no, type,
		debtor_no, branch_code,
		tran_date, due_date,
		reference, tpe,
		order_, ov_amount, ov_discount,
		ov_gst, ov_freight, ov_freight_tax,
		rate, ship_via, alloc, trans_link
		) VALUES ($trans_no, $trans_type, 
		".db_escape($debtor_no).", ".db_escape($BranchNo).",
		'$SQLDate', '$SQLDueDate', ".db_escape($reference).",
		".db_escape($sales_type).", $order_no, $Total, ".db_escape($discount).", $Tax, 
		".db_escape($Freight).",
		$FreightTax, $rate, ".db_escape($ship_via).", $AllocAmt, ".db_escape($trans_link) . ")";
	} else {	// may be optional argument should stay unchanged ?
	$sql = "UPDATE debtor_trans SET
		debtor_no=".db_escape($debtor_no)." , branch_code=".db_escape($BranchNo).",
		tran_date='$SQLDate', due_date='$SQLDueDate',
		reference=".db_escape($reference).", tpe=".db_escape($sales_type).", order_=$order_no,
		ov_amount=$Total, ov_discount=".db_escape($discount).", ov_gst=$Tax,
		ov_freight=".db_escape($Freight).", ov_freight_tax=$FreightTax, rate=$rate,
		ship_via=".db_escape($ship_via).", alloc=$AllocAmt, trans_link=$trans_link
		WHERE trans_no=$trans_no AND type=$trans_type";
	}
	db_query($sql, "The debtor transaction record could not be inserted");

	return $trans_no;
}

//----------------------------------------------------------------------------------------

function get_customer_trans($trans_id, $trans_type)
{
	$sql = "SELECT debtor_trans.*,
		ov_amount+ov_gst+ov_freight+ov_freight_tax+ov_discount AS Total,
		debtors_master.name AS DebtorName, debtors_master.address, debtors_master.email,
		debtors_master.curr_code, debtors_master.tax_id, debtors_master.payment_terms ";

	if ($trans_type == systypes::cust_payment()) {
		// it's a payment so also get the bank account
		$sql .= ", bank_accounts.bank_name, bank_accounts.bank_account_name,
			bank_trans_types.name AS BankTransType ";
	}

	if ($trans_type == 10 OR $trans_type == 11 OR $trans_type == 13) {
		// it's an invoice so also get the shipper and salestype
		$sql .= ", shippers.shipper_name, "
		."sales_types.sales_type, "
		."sales_types.tax_included, "
		."cust_branch.*, "
		."debtors_master.discount, "
		."tax_groups.name AS tax_group_name, "
		."tax_groups.id AS tax_group_id ";
	}


	$sql .= " FROM debtor_trans, debtors_master ";

	if ($trans_type == systypes::cust_payment()) {
		// it's a payment so also get the bank account
		$sql .= ", bank_trans, bank_accounts, bank_trans_types ";
	}

	if ($trans_type == 10 OR $trans_type == 11 OR $trans_type == 13) {
		// it's an invoice so also get the shipper, salestypes
		$sql .= ", shippers, sales_types, cust_branch, tax_groups ";
	}

	$sql .= " WHERE debtor_trans.trans_no=$trans_id
		AND debtor_trans.type=$trans_type
		AND debtor_trans.debtor_no=debtors_master.debtor_no";

	if ($trans_type == systypes::cust_payment()) {
		// it's a payment so also get the bank account
		$sql .= " AND bank_trans.trans_no =$trans_id
			AND bank_trans.type=$trans_type
			AND bank_trans_types.id = bank_trans.bank_trans_type_id
			AND bank_accounts.account_code=bank_trans.bank_act ";
	}
	if ($trans_type == 10 OR $trans_type == 11 OR $trans_type == 13) {
		// it's an invoice so also get the shipper
		$sql .= " AND shippers.shipper_id=debtor_trans.ship_via
			AND sales_types.id = debtor_trans.tpe
			AND cust_branch.branch_code = debtor_trans.branch_code
			AND cust_branch.tax_group_id = tax_groups.id ";
	}

	$result = db_query($sql, "Cannot retreive a debtor transaction");

	if (db_num_rows($result) == 0) {
		// can't return nothing
		display_db_error("no debtor trans found for given params", $sql, true);
		exit;
	}

	if (db_num_rows($result) > 1) {
		// can't return multiple
		display_db_error("duplicate debtor transactions found for given params", $sql, true);
		exit;
	}

	return db_fetch($result);
}

//----------------------------------------------------------------------------------------

function get_customer_transactions($extra_fields=null, $extra_conditions=null, $extra_tables=null)
{
	$sql = "SELECT debtor_trans.*,
		ov_amount+ov_gst+ov_freight+ov_freight_tax+ov_discount AS Total,
		debtors_master.name AS DebtorName, debtors_master.address,
		debtors_master.curr_code, debtor_trans.version ";

	if ($extra_fields)
		$sql .= ", $extra_fields ";

	$sql .= " FROM debtor_trans, debtors_master ";
	if ($extra_tables)
		$sql .= ",$extra_tables ";

	$sql .= " WHERE debtor_trans.debtor_no=debtors_master.debtor_no";

	if ($extra_conditions)
		$sql .= " AND $extra_conditions ";

	$sql .= " ORDER BY trans_no";

	return db_query($sql, "Cannot retreive debtor transactions");
}

//----------------------------------------------------------------------------------------

function exists_customer_trans($type, $type_no)
{
	$sql = "SELECT trans_no FROM debtor_trans WHERE type=$type
		AND trans_no=$type_no";

	$result = db_query($sql, "Cannot retreive a debtor transaction");

	return (db_num_rows($result) > 0);
}

//----------------------------------------------------------------------------------------

// retreives the related sales order for a given trans

function get_customer_trans_order($type, $type_no)
{
	$sql = "SELECT order_ FROM debtor_trans WHERE type=$type AND trans_no=$type_no";

	$result = db_query($sql, "The debtor transaction could not be queried");

	$row = db_fetch_row($result);

	return $row[0];
}

//----------------------------------------------------------------------------------------

function get_customer_details_from_trans($type, $type_no)
{
	$sql = "SELECT debtors_master.name, debtors_master.curr_code, cust_branch.br_name
		FROM debtors_master,cust_branch,debtor_trans
		WHERE debtor_trans.type=$type AND debtor_trans.trans_no=$type_no
		AND debtors_master.debtor_no = debtor_trans.debtor_no
		AND	cust_branch.branch_code = debtor_trans.branch_code";

	$result = db_query($sql, "could not get customer details from trans");
	return db_fetch($result);
}

//----------------------------------------------------------------------------------------

function void_customer_trans($type, $type_no)
{
	// clear all values and mark as void
	$sql = "UPDATE debtor_trans SET ov_amount=0, ov_discount=0, ov_gst=0, ov_freight=0,
		ov_freight_tax=0, alloc=0, version=version+1 WHERE type=$type AND trans_no=$type_no";

	db_query($sql, "could not void debtor transactions for type=$type and trans_no=$type_no");
}

//----------------------------------------------------------------------------------------

function post_void_customer_trans($type, $type_no)
{
	switch ($type) {
		case 10 :
		case 11 :
			void_sales_invoice($type, $type_no);
			break;
		case 13 :
			void_sales_delivery($type, $type_no);
			break;
		case 12 :
			void_customer_payment($type, $type_no);
			break;
	}
}

//---------------------------------------------------------------------------------------

function get_customer_trans_link($type, $type_no)
{
	$row = db_query("SELECT trans_link from debtor_trans
		WHERE type=$type AND trans_no=$type_no",
		"could not get transaction link for type=$type and trans_no=$type_no");
	return $row[0];
}
//---------------------------------------------------------------------------------------

?>
