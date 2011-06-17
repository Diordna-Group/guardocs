<?php

//----------------------------------------------------------------------------------

$systypes_array = array (
					0=> array ('name' => tr("Journal Entry")),
					1=> array ('name' => tr("Bank Payment")),
					2=> array ('name' => tr("Bank Deposit")),
					4=> array ('name' => tr("Funds Transfer")),
                    10=> array ('name' => tr("Sales Invoice")),
                    11=> array ('name' => tr("Customer Credit Note")),
                    12=> array ('name' => tr("Customer Payment")),
                    13=> array ('name' => tr("Delivery Note")),
                    16=> array ('name' => tr("Location Transfer")),
                    17=> array ('name' => tr("Inventory Adjustment")),
                    18=> array ('name' => tr("Purchase Order")),
                    20=> array ('name' => tr("Supplier Invoice")),
                    21=> array ('name' => tr("Supplier Credit Note")),
                    22=> array ('name' => tr("Supplier Payment")),
                    25=> array ('name' => tr("Purchase Order Delivery")),
                    26=> array ('name' => tr("Work Order")),
                    28=> array ('name' => tr("Work Order Issue")),
                    29=> array ('name' => tr("Work Order Production")),
                    30=> array ('name' => tr("Sales Order")),
                    35=> array ('name' => tr("Cost Update")),
                    40=> array ('name' => tr("Dimension"))
		 			);
class systypes 
{

	function journal_entry() 
	{
		return 0;
	}

	function bank_payment() 
	{
		return 1;
	}

	function bank_deposit() 
	{
		return 2;
	}

	function bank_transfer() 
	{
		return 4;
	}

	function cust_payment() 
	{
		return 12;
	}

	function cust_dispatch() 
	{
		return 13;
	}

	function location_transfer() 
	{
		return 16;
	}

	function inventory_adjustment() 
	{
		return 17;
	}

	function po() 
	{
		return 18;
	}

	function supp_payment() 
	{
		return 22;
	}

	function work_order() 
	{
		return 26;
	}

	function sales_order() 
	{
		return 30;
	}

	function cost_update() 
	{
		return 35;
	}

	function dimension() 
	{
		return 40;
	}

	function name($index) 
	{
		global $systypes_array;
		if ($index < 0)
			return '';
		return $systypes_array[$index]['name'];
	}
}

//----------------------------------------------------------------------------------

$bank_account_types_array = array (
						0=> array ('id' => 0, 'name' => tr("Savings Account")),
						1=> array ('id' => 1, 'name' => tr("Chequing Account")),
						2=> array ('id' => 2, 'name' => tr("Credit Account")),
						3=> array ('id' => 3, 'name' => tr("Cash Account"))
			 			);

class bank_account_types 
{

	function get_all() 
	{
		global $bank_account_types_array;
		return $bank_account_types_array;;
	}

	function name($index) 
	{
		global $bank_account_types_array;
		return $bank_account_types_array[$index]['name'];
	}
}

//----------------------------------------------------------------------------------

include_once($path_to_root . "/manufacturing/includes/manufacturing_db.inc");
include_once($path_to_root . "/purchasing/includes/purchasing_db.inc");
include_once($path_to_root . "/sales/includes/sales_db.inc");
include_once($path_to_root . "/dimensions/includes/dimensions_db.inc");

$payment_person_types_array = array (
							0=> array ('id' => 0, 'name' => tr("Miscellaneous")),
							1=> array ('id' => 1, 'name' => tr("Work Order")),
							2=> array ('id' => 2, 'name' => tr("Customer")),
							3=> array ('id' => 3, 'name' => tr("Supplier")),
							);

class payment_person_types 
{

	function get_all() 
	{
		global $payment_person_types_array;
		return $payment_person_types_array;
	}

    function misc()  
    { 
    	return 0; 
    }

    function WorkOrder()  
    { 
    	return 1; 
    }

    function customer()  
    { 
    	return 2; 
    }

    function supplier()  
    { 
    	return 3; 
    }

    function dimension()  
    { 
    	return 4; 
    }

    //function Project()  { return 4; }

    function type_name($type)
    {
    	global $payment_person_types_array;
    	return $payment_person_types_array[$type]['name'];
    }

    function person_name($type, $person_id, $full=true)
    {
    	switch ($type)
    	{
    		case payment_person_types::misc() :
    			return $person_id;
    		case payment_person_types::WorkOrder() :
    			$wo = get_work_order($person_id);
    			return ($full?payment_person_types::type_name($type) . " ":"") . $wo["wo_ref"];
    		case payment_person_types::customer() :
    			return ($full?payment_person_types::type_name($type) . " ":"") . get_customer_name($person_id);
    		case payment_person_types::supplier() :
    			return ($full?payment_person_types::type_name($type) . " ":"") . get_supplier_name($person_id);
    		//case payment_person_types::Project() :
    		//	return ($full?payment_person_types::type_name($type) . " ":"") . get_dimension_string($person_id);
    		default :
    			//DisplayDBerror("Invalid type sent to person_name");
    			//return;
    			return '';
    	}
    }

    function person_currency($type, $person_id)
    {
    	switch ($type)
    	{
    		case payment_person_types::misc() :
    		case payment_person_types::WorkOrder() :
    		//case payment_person_types::Project() :
    			return get_company_currency();

    		case payment_person_types::customer() :
    			return get_customer_currency($person_id);

    		case payment_person_types::supplier() :
    			return get_supplier_currency($person_id);

    		default :
    			return get_company_currency();
    	}
    }

    function has_items($type)
    {
    	switch ($type)
    	{
    		case payment_person_types::misc() :
    			return true;
    		case payment_person_types::WorkOrder() : // 070305 changed to open workorders ES
    			return db_has_open_workorders();
    		case payment_person_types::customer() :
    			return db_has_customers();
    		case payment_person_types::supplier() :
    			return db_has_suppliers();
    		//case payment_person_types::Project() :
    		//	return db_has_dimensions();
    		default :
    			display_db_error("Invalid type sent to has_items", "");
    			return;
    	}
    }
}

//----------------------------------------------------------------------------------

$wo_types_array = array (
						0=> array ('id' => 0, 'name' => tr("Assemble")),
						1=> array ('id' => 1, 'name' => tr("Unassemble")),
						2=> array ('id' => 2, 'name' => tr("Advanced Manufacture"))
			 			);

class wo_types 
{

	function assemble() 
	{ 
		return 0; 
	}

	function unassemble() 
	{ 
		return 1; 
	}

	function advanced() 
	{ 
		return 2; 
	}

	function get_all() 
	{
		global $wo_types_array;
		return $wo_types_array;;
	}

	function name($index) 
	{
		global $wo_types_array;
		return $wo_types_array[$index]['name'];
	}
}


?>