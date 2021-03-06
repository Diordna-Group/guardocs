<?php


function update_company_gl_setup($debtors_act, $pyt_discount_act, $creditors_act, $grn_act,
		$exchange_diff_act, $purch_exchange_diff_act,
		$retained_earnings_act, $freight_act,
		$default_sales_act,
		$default_sales_discount_act,
		$default_prompt_payment_act,
		$default_inventory_act,
		$default_cogs_act,
		$default_adj_act,
		$default_inv_sales_act,
		$default_assembly_act,
		$payroll_act,
		$allow_negative_stock,
		$po_over_receive,
		$po_over_charge,
		$past_due_days,
		$default_credit_limit,
		$default_workorder_required,
		$default_dim_required
		)
{
	$sql = "UPDATE company SET
		debtors_act=".db_escape($debtors_act).", pyt_discount_act=".db_escape($pyt_discount_act).",
		creditors_act=".db_escape($creditors_act).", grn_act=".db_escape($grn_act).",
		exchange_diff_act=".db_escape($exchange_diff_act).",
		purch_exchange_diff_act=".db_escape($purch_exchange_diff_act).",
		retained_earnings_act=".db_escape($retained_earnings_act).",
		freight_act=".db_escape($freight_act).",
		default_sales_act=".db_escape($default_sales_act).",
		default_sales_discount_act=".db_escape($default_sales_discount_act).",
		default_prompt_payment_act=".db_escape($default_prompt_payment_act).",
		default_inventory_act=".db_escape($default_inventory_act).",
		default_cogs_act=".db_escape($default_cogs_act).",
		default_adj_act=".db_escape($default_adj_act).",
		default_inv_sales_act=".db_escape($default_inv_sales_act).",
		default_assembly_act=".db_escape($default_assembly_act).",
		payroll_act=".db_escape($payroll_act).",
		allow_negative_stock=$allow_negative_stock,
		po_over_receive=$po_over_receive,
		po_over_charge=$po_over_charge,
		past_due_days=$past_due_days,
		default_credit_limit=$default_credit_limit,
		default_workorder_required=$default_workorder_required,
		default_dim_required=$default_dim_required 
		WHERE coy_code=1";

	db_query($sql, "The company gl setup could not be updated ");
}

function update_company_setup($coy_name, $coy_no, $gst_no, $tax_prd, $tax_last, $postal_address, $phone, $fax, $email,
		$coy_logo, $domicile, $Dimension, $custom1_name, $custom2_name, $custom3_name,
		$custom1_value, $custom2_value, $custom3_value, $curr_default, $f_year, $no_item_list, $no_customer_list,
		$no_supplier_list,$blob)
{
	if ($f_year == null)
		$f_year = 0;
	$sql = "UPDATE company SET coy_name=".db_escape($coy_name).",
		coy_no = ".db_escape($coy_no).",
		gst_no=".db_escape($gst_no).",
		tax_prd=$tax_prd,
		tax_last=$tax_last,
		postal_address =".db_escape($postal_address).",
		phone=".db_escape($phone).", fax=".db_escape($fax).",
		email=".db_escape($email).",
		coy_logo=".db_escape($coy_logo).",
		domicile=".db_escape($domicile).",
		use_dimension=$Dimension,
		no_item_list=$no_item_list,
		no_customer_list=$no_customer_list,
		no_supplier_list=$no_supplier_list,
        custom1_name=".db_escape($custom1_name).",
        custom2_name=".db_escape($custom2_name).",
        custom3_name=".db_escape($custom3_name).",
        custom1_value=".db_escape($custom1_value).",
        custom2_value=".db_escape($custom2_value).",
        custom3_value=".db_escape($custom3_value).",
		curr_default=".db_escape($curr_default).",
		f_year=$f_year";
	if ($blob != "") {
	  $sql .= ",image='".$blob."'";
	}
	$sql .= " WHERE coy_code=1";
	db_query($sql, "The company setup could not be updated ");
}

function get_company_prefs()
{
	$sql = "SELECT * FROM company WHERE coy_code=1";
	$result = db_query($sql, "The company preferences could not be retrieved");

	if (db_num_rows($result) == 0)
		display_db_error("FATAL : Could not find company prefs", $sql);

	return db_fetch($result);
}

function get_company_pref($pref_name)
{
	$prefs = get_company_prefs();
	return $prefs[$pref_name];
}

// fiscal year routines
function add_fiscalyear($from_date, $to_date, $closed)
{
	$from = date2sql($from_date);
	$to = date2sql($to_date);

	$sql = "INSERT INTO fiscal_year (begin, end, closed)
		VALUES (".db_escape($from).",".db_escape($to).", $closed)";

	db_query($sql, "could not add fiscal year");
}

function update_fiscalyear($from_date, $closed)
{
	$from = date2sql($from_date);

	$sql = "UPDATE fiscal_year SET closed=$closed
		WHERE begin=".db_escape($from);

	db_query($sql, "could not update fiscal year");
}

function get_all_fiscalyears()
{
	$sql = "SELECT * FROM fiscal_year ORDER BY begin";

	return db_query($sql, "could not get all fiscal years");
}

function get_fiscalyear($from_date)
{
	$from = date2sql($from_date);

	$sql = "SELECT * FROM fiscal_year WHERE begin=".db_escape($from);

	$result = db_query($sql, "could not get fiscal year");

	return db_fetch($result);
}

function get_current_fiscalyear()
{
	$year = get_company_pref('f_year');

	$sql = "SELECT * FROM fiscal_year WHERE id=$year";

	$result = db_query($sql, "could not get current fiscal year");

	return db_fetch($result);
}

function delete_fiscalyear($from_date)
{
	$from = date2sql($from_date);
	begin_transaction();

	$sql="DELETE FROM fiscal_year WHERE begin=".db_escape($from);

	db_query($sql, "could not delete fiscal year");

	commit_transaction();
}


?>
