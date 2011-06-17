<?php

$page_security = 10;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

page(tr("Chart of Accounts"));

include($path_to_root . "/includes/ui.inc");
include($path_to_root . "/gl/includes/gl_db.inc");
include_once($path_to_root . "/includes/data_checks.inc");

check_db_has_gl_account_groups(tr("There are no account groups defined. Please define at least one account group before entering accounts."));

//-------------------------------------------------------------------------------------

if (isset($_POST['Select'])) 
{
	$_POST['selected_account'] = $_POST['AccountList'];
}

if (isset($_POST['selected_account']))
{
	$selected_account = $_POST['selected_account'];
} 
elseif (isset($_GET['selected_account']))
{
	$selected_account = $_GET['selected_account'];
}
else
	$selected_account = "";

//-------------------------------------------------------------------------------------

if (isset($_POST['add']) || isset($_POST['update'])) 
{

	$input_error = 0;

	if (strlen($_POST['account_code']) == 0) 
	{
		$input_error = 1;
		display_error( tr("The account code must be entered."));
		set_focus('account_code');
	} 
	elseif (strlen($_POST['account_name']) == 0) 
	{
		$input_error = 1;
		display_error( tr("The account name cannot be empty."));
		set_focus('account_name');
	} 
	elseif (!$accounts_alpha && !is_numeric($_POST['account_code'])) 
	{
	    $input_error = 1;
	    display_error( tr("The account code must be numeric."));
		set_focus('account_code');
	}

	if ($input_error != 1)
	{
		if ($accounts_alpha == 2)
			$_POST['account_code'] = strtoupper($_POST['account_code']);
    	if ($selected_account)
    		update_gl_account($_POST['account_code'], $_POST['account_name'], $_POST['account_type'], $_POST['account_code2'], $_POST['tax_code']);    		
    	else
    		add_gl_account($_POST['account_code'], $_POST['account_name'], $_POST['account_type'], $_POST['account_code2'], $_POST['tax_code']);
		meta_forward($_SERVER['PHP_SELF']);    	
	}
} 

//-------------------------------------------------------------------------------------

function can_delete($selected_account)
{
	if ($selected_account == "")
		return false;
	$sql= "SELECT COUNT(*) FROM gl_trans WHERE account='$selected_account'";
	$result = db_query($sql,"Couldn't test for existing transactions");

	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this account because transactions have been created using this account."));
		return false;
	}

	$sql= "SELECT COUNT(*) FROM company WHERE debtors_act='$selected_account' 
		OR pyt_discount_act='$selected_account' 
		OR creditors_act='$selected_account' 
		OR grn_act='$selected_account' 
		OR exchange_diff_act='$selected_account' 
		OR purch_exchange_diff_act='$selected_account' 
		OR retained_earnings_act='$selected_account'
		OR freight_act='$selected_account'
		OR default_sales_act='$selected_account' 
		OR default_sales_discount_act='$selected_account'
		OR default_prompt_payment_act='$selected_account'
		OR default_inventory_act='$selected_account'
		OR default_cogs_act='$selected_account'
		OR default_adj_act='$selected_account'
		OR default_inv_sales_act='$selected_account'
		OR default_assembly_act='$selected_account'
		OR payroll_act='$selected_account'";
	$result = db_query($sql,"Couldn't test for default company GL codes");

	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this account because it is used as one of the company default GL accounts."));
		return false;
	}
	
	$sql= "SELECT COUNT(*) FROM bank_accounts WHERE account_code='$selected_account'";
	$result = db_query($sql,"Couldn't test for bank accounts");

	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this account because it is used by a bank account."));
		return false;
	}	

	$sql= "SELECT COUNT(*) FROM stock_master WHERE 
		inventory_account='$selected_account' 
		OR cogs_account='$selected_account'
		OR adjustment_account='$selected_account' 
		OR sales_account='$selected_account'";
	$result = db_query($sql,"Couldn't test for existing stock GL codes");

	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this account because it is used by one or more Items."));
		return false;
	}	
	
	$sql= "SELECT COUNT(*) FROM tax_types WHERE sales_gl_code='$selected_account' OR purchasing_gl_code='$selected_account'";
	$result = db_query($sql,"Couldn't test for existing tax GL codes");

	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this account because it is used by one or more Taxes."));
		return false;
	}	
	
	$sql= "SELECT COUNT(*) FROM cust_branch WHERE 
		sales_account='$selected_account' 
		OR sales_discount_account='$selected_account'
		OR receivables_account='$selected_account'
		OR payment_discount_account='$selected_account'";
	$result = db_query($sql,"Couldn't test for existing cust branch GL codes");

	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this account because it is used by one or more Customer Branches."));
		return false;
	}		
	
	$sql= "SELECT COUNT(*) FROM suppliers WHERE 
		purchase_account='$selected_account' 
		OR payment_discount_account='$selected_account' 
		OR payable_account='$selected_account'";
	$result = db_query($sql,"Couldn't test for existing suppliers GL codes");

	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this account because it is used by one or more suppliers."));
		return false;
	}									
	
	return true;
}

//--------------------------------------------------------------------------------------

if (isset($_POST['delete'])) 
{

	if (can_delete($selected_account))
	{
		delete_gl_account($selected_account);
		meta_forward($_SERVER['PHP_SELF']);		
	}
} 

//-------------------------------------------------------------------------------------

start_form();

if (db_has_gl_accounts()) 
{
	echo "<center>";
    echo tr("Select an Account:") . "&nbsp;";
    gl_all_accounts_list('AccountList', null);
    echo "&nbsp;";
    submit('Select', tr("Edit Account"));
    echo "</center>";
} 
	
hyperlink_no_params($_SERVER['PHP_SELF'], tr("New Account"));
br(1);

start_table($table_style2);

if ($selected_account != "") 
{
	//editing an existing account
	$myrow = get_gl_account($selected_account);

	$_POST['account_code'] = $myrow["account_code"];
	$_POST['account_code2'] = $myrow["account_code2"];
	$_POST['account_name']	= $myrow["account_name"];
	$_POST['account_type'] = $myrow["account_type"];
	$_POST['tax_code'] = $myrow["tax_code"];

	hidden('account_code', $_POST['account_code']);
	hidden('selected_account', $_POST['selected_account']);
		
	label_row(tr("Account Code:"), $_POST['account_code']);
} 
else 
{
	text_row_ex(tr("Account Code:"), 'account_code', 11);
}

text_row_ex(tr("Account Code 2:"), 'account_code2', 11);

text_row_ex(tr("Account Name:"), 'account_name', 60);

gl_account_types_list_row(tr("Account Group:"), 'account_type', null);

tax_types_list_row(tr("Tax Type:"), 'tax_code', null, true, tr('No Tax'));

end_table(1);

if ($selected_account == "") 
{
	submit_center('add', tr("Add Account"));
} 
else 
{
    submit_center_first('update', tr("Update Account"));
    submit_center_last('delete', tr("Delete account"));
}

end_form();

end_page();

?>
