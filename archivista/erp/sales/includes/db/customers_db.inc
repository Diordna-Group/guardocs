<?php

function get_customer_details($customer_id, $to=null)
{

	if ($to == null)
		$todate = date("Y-m-d");
	else
		$todate = date2sql($to);
	$past1 = get_company_pref('past_due_days');
	$past2 = 2 * $past1;
	// removed - debtor_trans.alloc from all summations

    $value = "IF(debtor_trans.type=11 OR debtor_trans.type=12 OR debtor_trans.type=2,
	-1, 1) *".
      "(debtor_trans.ov_amount + debtor_trans.ov_gst + "
		."debtor_trans.ov_freight + debtor_trans.ov_freight_tax + "
		."debtor_trans.ov_discount)";

    $sql = "SELECT debtors_master.name, debtors_master.curr_code, payment_terms.terms,
		debtors_master.credit_limit, credit_status.dissallow_invoices, credit_status.reason_description,

		Sum(".$value.") AS Balance,

		Sum(IF (payment_terms.days_before_due > 0,
			CASE WHEN (TO_DAYS('$todate') - TO_DAYS(debtor_trans.tran_date)) >= payment_terms.days_before_due
			THEN
			    $value
			ELSE 0
			END,

			CASE WHEN TO_DAYS('$todate') - TO_DAYS(DATE_ADD(DATE_ADD(debtor_trans.tran_date,
				INTERVAL 1 MONTH), INTERVAL (payment_terms.day_in_following_month -
				DAYOFMONTH(debtor_trans.tran_date)) DAY)) >= 0
			THEN
			    $value
			ELSE 0
			END

		)) AS Due,

		Sum(IF (payment_terms.days_before_due > 0,
			CASE WHEN TO_DAYS('$todate') - TO_DAYS(debtor_trans.tran_date) > payment_terms.days_before_due
				AND TO_DAYS('$todate') - TO_DAYS(debtor_trans.tran_date) >= (payment_terms.days_before_due + $past1)
			THEN
				$value
			ELSE
				0
			END,

			CASE WHEN (TO_DAYS('$todate') - TO_DAYS(DATE_ADD(DATE_ADD(debtor_trans.tran_date,
				INTERVAL 1  MONTH), INTERVAL (payment_terms.day_in_following_month -
				DAYOFMONTH(debtor_trans.tran_date)) DAY)) >= $past1)
			THEN
				$value
			ELSE
				0
			END

		)) AS Overdue1,

		Sum(IF (payment_terms.days_before_due > 0,
			CASE WHEN TO_DAYS('$todate') - TO_DAYS(debtor_trans.tran_date) > payment_terms.days_before_due
				AND TO_DAYS('$todate') - TO_DAYS(debtor_trans.tran_date) >= (payment_terms.days_before_due + $past2)
			THEN
			    $value
			ELSE
				0
			END,

			CASE WHEN (TO_DAYS('$todate') - TO_DAYS(DATE_ADD(DATE_ADD(debtor_trans.tran_date,
				INTERVAL 1  MONTH), INTERVAL (payment_terms.day_in_following_month -
				DAYOFMONTH(debtor_trans.tran_date)) DAY)) >= $past2)
			THEN
				$value
			ELSE
				0
			END

		)) AS Overdue2

		FROM debtors_master,
			 payment_terms,
			 credit_status,
			 debtor_trans

		WHERE
			 debtors_master.payment_terms = payment_terms.terms_indicator
			 AND debtors_master.credit_status = credit_status.id
			 AND debtors_master.debtor_no = $customer_id
			 AND debtor_trans.tran_date <= '$todate'
			 AND debtor_trans.type <> 13
			 AND debtors_master.debtor_no = debtor_trans.debtor_no

		GROUP BY
			  debtors_master.name,
			  payment_terms.terms,
			  payment_terms.days_before_due,
			  payment_terms.day_in_following_month,
			  debtors_master.credit_limit,
			  credit_status.dissallow_invoices,
			  credit_status.reason_description";

    $result = db_query($sql,"The customer details could not be retrieved");

    if (db_num_rows($result) == 0)
    {

    	/*Because there is no balance - so just retrieve the header information about the customer - the choice is do one query to get the balance and transactions for those customers who have a balance and two queries for those who don't have a balance OR always do two queries - I opted for the former */

    	$nil_balance = true;

    	$sql = "SELECT debtors_master.name, debtors_master.curr_code, debtors_master.debtor_no,  payment_terms.terms,
    		debtors_master.credit_limit, credit_status.dissallow_invoices, credit_status.reason_description
    		FROM debtors_master,
    		     payment_terms,
    		     credit_status

    		WHERE
    		     debtors_master.payment_terms = payment_terms.terms_indicator
    		     AND debtors_master.credit_status = credit_status.id
    		     AND debtors_master.debtor_no = '$customer_id'";

    	$result = db_query($sql,"The customer details could not be retrieved");

    }
    else
    {
    	$nil_balance = false;
    }

    $customer_record = db_fetch($result);

    if ($nil_balance == true)
    {
    	$customer_record["Balance"] = 0;
    	$customer_record["Due"] = 0;
    	$customer_record["Overdue1"] = 0;
    	$customer_record["Overdue2"] = 0;
    }

    return $customer_record;

}

function get_customer_name($customer_id)
{
	$sql = "SELECT name FROM debtors_master WHERE debtor_no=$customer_id";

	$result = db_query($sql, "could not get customer");

	$row = db_fetch_row($result);

	return $row[0];
}

function get_area_name($id)
{
	$sql = "SELECT description FROM areas WHERE area_code=$id";

	$result = db_query($sql, "could not get sales type");

	$row = db_fetch_row($result);
	return $row[0];
}

function get_salesman_name($id)
{
	$sql = "SELECT salesman_name FROM salesman WHERE salesman_code=$id";

	$result = db_query($sql, "could not get sales type");

	$row = db_fetch_row($result);
	return $row[0];
}




?>
