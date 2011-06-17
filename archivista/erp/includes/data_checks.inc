<?php
function db_has_customers()
{
	return check_empty_result("SELECT COUNT(*) FROM debtors_master");
}

function check_db_has_customers($msg)
{
	global $path_to_root;
    if (!db_has_customers()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_currencies()
{
	return check_empty_result("SELECT COUNT(*) FROM currencies");
}

function check_db_has_currencies($msg)
{
	global $path_to_root;
    if (!db_has_currencies()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_sales_types()
{
	return check_empty_result("SELECT COUNT(*) FROM sales_types");
}

function check_db_has_sales_types($msg)
{
	global $path_to_root;
    if (!db_has_sales_types()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_item_tax_types()
{
	return check_empty_result("SELECT COUNT(*) FROM item_tax_types");
}

function check_db_has_item_tax_types($msg)
{
	global $path_to_root;
    if (!db_has_item_tax_types()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_tax_types()
{
	return check_empty_result("SELECT COUNT(*) FROM tax_types");
}

function check_db_has_tax_types($msg)
{
	global $path_to_root;
    if (!db_has_tax_types()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_tax_groups()
{
	return check_empty_result("SELECT COUNT(*) FROM tax_groups");
}

function check_db_has_tax_groups($msg)
{
	global $path_to_root;
    if (!db_has_tax_groups()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_movement_types()
{
	return check_empty_result("SELECT COUNT(*) FROM movement_types");
}

function check_db_has_movement_types($msg)
{
	global $path_to_root;
    if (!db_has_movement_types()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_bank_trans_types()
{
	return check_empty_result("SELECT COUNT(*) FROM bank_trans_types");
}

function check_db_has_bank_trans_types($msg)
{
	global $path_to_root;
    if (!db_has_bank_trans_types()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_customer_has_branches($customer_id)
{
	return check_empty_result("SELECT COUNT(*) FROM cust_branch WHERE debtor_no=$customer_id");
}

function db_has_customer_branches()
{
	return check_empty_result("SELECT COUNT(*) FROM cust_branch");
}

function check_db_has_customer_branches($msg)
{
	global $path_to_root;
    if (!db_has_customer_branches()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_sales_people()
{
	return check_empty_result("SELECT COUNT(*) FROM salesman");
}

function check_db_has_sales_people($msg)
{
	global $path_to_root;
    if (!db_has_sales_people()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_sales_areas()
{
	return check_empty_result("SELECT COUNT(*) FROM areas");
}

function check_db_has_sales_areas($msg)
{
	global $path_to_root;
    if (!db_has_sales_areas()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_shippers()
{
	return check_empty_result("SELECT COUNT(*) FROM shippers");
}

function check_db_has_shippers($msg)
{
	global $path_to_root;
    if (!db_has_shippers()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_open_workorders()
{
	return check_empty_result("SELECT COUNT(*) FROM workorders WHERE closed=0");
}

function db_has_workorders()
{
	return check_empty_result("SELECT COUNT(*) FROM workorders");
}

function check_db_has_workorders($msg)
{
	global $path_to_root;
    if (!db_has_workorders()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_open_dimensions()
{
	return check_empty_result("SELECT COUNT(*) FROM dimensions WHERE closed=0");
}

function db_has_dimensions()
{
	return check_empty_result("SELECT COUNT(*) FROM dimensions");
}

function check_db_has_dimensions($msg)
{
	global $path_to_root;
    if (!db_has_dimensions()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}


function db_has_suppliers()
{
	return check_empty_result("SELECT COUNT(*) FROM suppliers");
}

function check_db_has_suppliers($msg)
{
	global $path_to_root;
    if (!db_has_suppliers()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_stock_items()
{
	return check_empty_result("SELECT COUNT(*) FROM stock_master");
}

function check_db_has_stock_items($msg)
{
	global $path_to_root;
    if (!db_has_stock_items()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_item_translations()
{
	return check_empty_result("SELECT COUNT(*) FROM item_translations");
}

function check_db_has_item_translations($msg)
{
	global $path_to_root;
    if (!db_has_item_translations()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}


function db_has_bom_stock_items()
{
	return check_empty_result("SELECT COUNT(*) FROM stock_master WHERE (mb_flag='M' OR mb_flag='K')");
}

function check_db_has_bom_stock_items($msg)
{
	global $path_to_root;
    if (!db_has_bom_stock_items()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_manufacturable_items()
{
	return check_empty_result("SELECT COUNT(*) FROM stock_master WHERE (mb_flag='M')");
}

function check_db_has_manufacturable_items($msg)
{
	global $path_to_root;
    if (!db_has_manufacturable_items()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_purchasable_items()
{
	return check_empty_result("SELECT COUNT(*) FROM stock_master WHERE (mb_flag!='M' AND mb_flag!='K')");
}

function check_db_has_purchasable_items($msg)
{
	global $path_to_root;
    if (!db_has_purchasable_items()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_costable_items()
{
	return check_empty_result("SELECT COUNT(*) FROM stock_master WHERE (mb_flag!='D' AND mb_flag!='K')");
}

function check_db_has_costable_items($msg)
{
	global $path_to_root;
    if (!db_has_costable_items()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_stock_categories()
{
	return check_empty_result("SELECT COUNT(*) FROM stock_category");
}

function check_db_has_stock_categories($msg)
{
	global $path_to_root;
    if (!db_has_stock_categories()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_workcentres()
{
	return check_empty_result("SELECT COUNT(*) FROM workcentres");
}

function check_db_has_workcentres($msg)
{
	global $path_to_root;
    if (!db_has_workcentres()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_locations()
{
	return check_empty_result("SELECT COUNT(*) FROM locations");
}

function check_db_has_locations($msg)
{
	global $path_to_root;
    if (!db_has_locations()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_bank_accounts()
{
	return check_empty_result("SELECT COUNT(*) FROM bank_accounts");
}

function check_db_has_bank_accounts($msg)
{
	global $path_to_root;
    if (!db_has_bank_accounts()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function db_has_gl_accounts()
{
	return check_empty_result("SELECT COUNT(*) FROM chart_master");
}

function db_has_gl_account_groups()
{
	return check_empty_result("SELECT COUNT(*) FROM chart_types");
}

function check_db_has_gl_account_groups($msg)
{
	global $path_to_root;
    if (!db_has_gl_account_groups()) 
    {
    	display_error($msg, true);
    	end_page();
    	exit;	
    }	
}

function check_empty_result($sql)
{
	$result = db_query($sql, "could not do check empty query");	
	
	$myrow = db_fetch_row($result);
	return $myrow[0] > 0;	 	
}
//
//	Integer input check 
//	Return 1 if number has proper form and is within <min, max> range
//
function check_int($postname, $min=null, $max=null) {
	if(!isset($_POST[$postname]))
	  return 0;
    $num = input_num($postname);
    if(!is_int($num)) 
	  return 0;
    if (isset($min) && ($num<$min)) 
	  return 0;
    if (isset($max) && ($num>$max)) 
	  return 0;
    return 1;
}
//
//	Numeric input check.
//	Return 1 if number has proper form and is within <min, max> range
//
function check_num($postname, $min=null, $max=null) {
	if(!isset($_POST[$postname]))
	  return 0;
    $num = input_num($postname);
    if ($num === false) 
	  return 0;
    if (isset($min) && ($num<$min)) 
	  return 0;
    if (isset($max) && ($num>$max)) 
	  return 0;
    return 1;
}


?>
