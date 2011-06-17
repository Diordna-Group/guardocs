<?php

$page_security = 2;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

include($path_to_root . "/sales/includes/sales_ui.inc");
include_once($path_to_root . "/reporting/includes/reporting.inc");

$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 600);
if ($use_date_picker)
	$js .= get_js_date_picker();

if (isset($_GET['OutstandingOnly']) && ($_GET['OutstandingOnly'] == true))
{
	$_POST['OutstandingOnly'] = true;
	page(tr("Search Not Invoiced Deliveries"), false, false, "", $js);
}
else
{
	$_POST['OutstandingOnly'] = false;
	page(tr("Search All Deliveries"), false, false, "", $js);
}

if (isset($_GET['selected_customer']))
{
	$selected_customer = $_GET['selected_customer'];
}
elseif (isset($_POST['selected_customer']))
{
	$selected_customer = $_POST['selected_customer'];
}
else
	$selected_customer = -1;

if (isset($_POST['BatchInvoice']))
{

	// checking batch integrity
    $del_count = 0;
    foreach($_SESSION['Batch'] as $delivery)
    {
	  	$checkbox = 'Sel_'.$delivery['trans'];
	  	if (check_value($checkbox))
	  	{
	    	if (!$del_count)
	    	{
				$del_customer = $delivery['cust'];
				$del_branch = $delivery['branch'];
	    	}
	    	else
	    	{
				if ($del_customer!=$delivery['cust'] || $del_branch != $delivery['branch'])
				{
		    		$del_count=0;
		    		break;
				}
	    	}
	    	$selected[] = $delivery['trans'];
	    	$del_count++;
	  	}
    }

    if (!$del_count)
    {
		display_error(tr('For batch invoicing you should
		    select at least one delivery. All items must be dispatched to
		    the same customer branch.'));
    }
    else
    {
		$_SESSION['DeliveryBatch'] = $selected;
		meta_forward($path_to_root . '/sales/customer_invoice.php','BatchInvoice=Yes');
    }
}
//-----------------------------------------------------------------------------------
print_hidden_script(13);

start_form(false, false, $_SERVER['PHP_SELF'] ."?OutstandingOnly=" . $_POST['OutstandingOnly'] .SID);

start_table("class='tablestyle_noborder'");
start_row();
ref_cells(tr("#:"), 'DeliveryNumber');
date_cells(tr("from:"), 'DeliveryAfterDate', null, -30);
date_cells(tr("to:"), 'DeliveryToDate', null, 1);

locations_list_cells(tr("Location:"), 'StockLocation', null, true);

stock_items_list_cells(tr("Item:"), 'SelectStockFromList', null, true);

submit_cells('SearchOrders', tr("Search"));

hidden('OutstandingOnly', $_POST['OutstandingOnly']);

end_row();

end_table();

//---------------------------------------------------------------------------------------------

if (isset($_POST['SelectStockFromList']) && ($_POST['SelectStockFromList'] != "") &&
	($_POST['SelectStockFromList'] != reserved_words::get_all()))
{
 	$selected_stock_item = $_POST['SelectStockFromList'];
}
else
{
	unset($selected_stock_item);
}

//---------------------------------------------------------------------------------------------
$sql = "SELECT debtor_trans.trans_no, "
	."debtors_master.curr_code, "
	."debtors_master.name, "
	."cust_branch.br_name, "
	."debtor_trans.reference, "
	."debtor_trans.tran_date, "
	."debtor_trans.due_date, "
	."sales_orders.customer_ref, "
	."sales_orders.deliver_to, ";

$sql .= " Sum(debtor_trans_details.quantity-"
		 ."debtor_trans_details.qty_done) AS Outstanding, ";

$sql .= " Sum(debtor_trans_details.qty_done) AS Done, ";

//$sql .= " Sum(debtor_trans_details.unit_price*"
// ."debtor_trans_details.quantity*(1-"
// ."debtor_trans_details.discount_percent)) AS DeliveryValue";
$sql .= "(ov_amount+ov_gst+ov_freight+ov_freight_tax) AS DeliveryValue ".
  "FROM sales_orders,debtor_trans,debtor_trans_details,".
	"debtors_master,cust_branch WHERE ".
	"sales_orders.order_no = debtor_trans.order_ AND ".
	"debtor_trans.debtor_no = debtors_master.debtor_no ".
	"AND debtor_trans.type = 13 ".
	"AND debtor_trans_details.debtor_trans_no = debtor_trans.trans_no ".
	"AND debtor_trans_details.debtor_trans_type = debtor_trans.type ".
	"AND debtor_trans.branch_code = cust_branch.branch_code ".
	"AND debtor_trans.debtor_no = cust_branch.debtor_no ";

//figure out the sql required from the inputs available
if (isset($_POST['DeliveryNumber']) && $_POST['DeliveryNumber'] != "")
{
	$sql .= " AND debtor_trans.trans_no LIKE '%". $_POST['DeliveryNumber'] ."' GROUP BY debtor_trans.trans_no";
}
else
{

	$date_after = date2sql($_POST['DeliveryAfterDate']);
	$date_before = date2sql($_POST['DeliveryToDate']);

	$sql .= " AND debtor_trans.tran_date >= '$date_after'";
	$sql .= " AND debtor_trans.tran_date <= '$date_before'";

	if ($selected_customer != -1)
		$sql .= " AND debtor_trans.debtor_no='" . $selected_customer . "' ";

	if (isset($selected_stock_item))
		$sql .= " AND debtor_trans_details.stock_id='". $selected_stock_item ."' ";

	if (isset($_POST['StockLocation']) && $_POST['StockLocation'] != reserved_words::get_all())
		$sql .= " AND sales_orders.from_stk_loc = '". $_POST['StockLocation'] . "' ";

	if ($_POST['OutstandingOnly'] == true) {
	 $sql .= " AND debtor_trans_details.qty_done < debtor_trans_details.quantity ";
	}

	$sql .= " GROUP BY debtor_trans.trans_no ";
//	"debtor_trans.debtor_no, "
//	"debtor_trans.branch_code, "
//		sales_orders.customer_ref, "
//		"debtor_trans.tran_date";

} //end no delivery number selected

$result = db_query($sql,"No deliveries were returned");

//-----------------------------------------------------------------------------------
if (isset($_SESSION['Batch']))
{
    foreach($_SESSION['Batch'] as $trans=>$del)
    	unset($_SESSION['Batch'][$trans]);
    unset($_SESSION['Batch']);
}
if ($result)
{
	/*show a table of the deliveries returned by the sql */

	start_table("$table_style colspan=7 width=95%");
	$th = array(tr("Delivery #"), tr("Customer"), tr("Branch"), tr("Reference"), tr("Delivery Date"),
		tr("Due By"), tr("Delivery Total"), tr("Currency"), submit('BatchInvoice','Batch Inv', false),
		 "", "", "");
	table_header($th);

	$j = 1;
	$k = 0; //row colour counter
	$overdue_items = false;
	while ($myrow = db_fetch($result))
	{
	    $_SESSION['Batch'][] = array('trans'=>$myrow["trans_no"],
	    'cust'=>$myrow["name"],'branch'=>$myrow["br_name"] );

	    $view_page = get_customer_trans_view_str(13, $myrow["trans_no"]);
	    $formated_del_date = sql2date($myrow["tran_date"]);
	    $formated_due_date = sql2date($myrow["due_date"]);
	    $not_closed =  $myrow["Outstanding"]!=0;

    	// if overdue orders, then highlight as so

    	if (date1_greater_date2(Today(), $formated_due_date) && $not_closed )
    	{
        	 start_row("class='overduebg'");
        	 $overdue_items = true;
    	}
    	else
    	{
			alt_table_row_color($k);
    	}

		label_cell($view_page);
		label_cell($myrow["name"]);
		label_cell($myrow["br_name"]);
		label_cell($myrow["reference"]);
		label_cell($formated_del_date);
		label_cell($formated_due_date);
		amount_cell($myrow["DeliveryValue"]);
		label_cell($myrow["curr_code"]);
		if (!$myrow['Done'])
		    check_cells(null,'Sel_'. $myrow['trans_no'],0,false);
		else
    		    label_cell("");
		if ($_POST['OutstandingOnly'] == true || $not_closed)
		{
    		$modify_page = $path_to_root . "/sales/customer_delivery.php?" . SID . "ModifyDelivery=" . $myrow["trans_no"];
    		$invoice_page = $path_to_root . "/sales/customer_invoice.php?" . SID . "DeliveryNumber=" .$myrow["trans_no"];
    		label_cell("<a href='$modify_page'>" . tr("Edit") . "</a>");
  		  	label_cell(print_document_link($myrow['trans_no'], tr("Print")));

    		label_cell($not_closed ? "<a href='$invoice_page'>" . tr("Invoice") . "</a>" : '');

		}
		else
		{
    		label_cell("");
    		label_cell("");
    		label_cell("");
		}
		end_row();;

		$j++;
		If ($j == 12)
		{
			$j = 1;
			table_header($th);
		}
		//end of page full new headings if
	}
	//end of while loop

	end_table();

   if ($overdue_items)
   		display_note(tr("Marked items are overdue."), 0, 1, "class='overduefg'");
}

echo "<br>";
end_form();

end_page();
?>

