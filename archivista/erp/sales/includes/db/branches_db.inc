<?php


function get_branch($branch_id)
{
	$sql = "SELECT cust_branch.*,salesman.salesman_name 
		FROM cust_branch, salesman 
		WHERE cust_branch.salesman=salesman.salesman_code 
		AND branch_code=$branch_id";
	
	$result = db_query($sql, "Cannot retreive a customer branch");
	
	return db_fetch($result);   	
}

function get_branch_accounts($branch_id)
{
	$sql = "SELECT receivables_account,sales_account, sales_discount_account, payment_discount_account 
		FROM cust_branch WHERE branch_code=$branch_id";
	
	$result = db_query($sql, "Cannot retreive a customer branch");
	
	return db_fetch($result);   	
}

function get_branch_name($branch_id)
{
	$sql = "SELECT br_name FROM cust_branch 
		WHERE branch_code = '$branch_id'";

	$result = db_query($sql,"could not retreive name for branch" . $branch_id);

	$myrow = db_fetch_row($result);	
	return $myrow[0];
}

?>