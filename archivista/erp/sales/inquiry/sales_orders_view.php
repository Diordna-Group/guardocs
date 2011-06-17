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
	$_POST['order_view_mode'] = 'OutstandingOnly';
	$_SESSION['page_title'] = tr("Search Outstanding Sales Orders");
}
elseif (isset($_GET['InvoiceTemplates']) && ($_GET['InvoiceTemplates'] == true))
{
	$_POST['order_view_mode'] = 'InvoiceTemplates';
	$_SESSION['page_title'] = tr("Search Template for Invoicing");
}
elseif (isset($_GET['DeliveryTemplates']) && ($_GET['DeliveryTemplates'] == true))
{
	$_POST['order_view_mode'] = 'DeliveryTemplates';
	$_SESSION['page_title'] = tr("Select Template for Delivery");
}
elseif (!isset($_POST['order_view_mode']))
{
	$_POST['order_view_mode'] = false;
	$_SESSION['page_title'] = tr("Search All Sales Orders");
}

page($_SESSION['page_title'], false, false, "", $js);

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

//-----------------------------------------------------------------------------------
/*
$action = $_SERVER['PHP_SELF'];

if ($_POST['order_view_mode']=='OutstandingOnly')
{
  	$action .= "?OutstandingOnly=" . $_POST['order_view_mode']$_PO;
}
elseif ($_POST['order_view_mode']=='InvoiceTemplates')
{
  	$action .= "?InvoiceTemplates=" . $_POST['InvoiceTemplates'];
}
elseif ($_POST['order_view_mode']=='DeliveryTemplates')
{
  	$action .= "?DeliveryTemplates=" . $_POST['InvoiceTemplates'];
}
*/
start_form(false, false, $_SERVER['PHP_SELF'] .SID);

start_table("class='tablestyle_noborder'");
start_row();
ref_cells(tr("#:"), 'OrderNumber');
if ($_POST['order_view_mode'] != 'DeliveryTemplates' && $_POST['order_view_mode'] != 'InvoiceTemplates')
{
  	date_cells(tr("from:"), 'OrdersAfterDate', null, -30);
  	date_cells(tr("to:"), 'OrdersToDate', null, 1);
}
locations_list_cells(tr("Location:"), 'StockLocation', null, true);

stock_items_list_cells(tr("Item:"), 'SelectStockFromList', null, true);

submit_cells('SearchOrders', tr("Search"));

hidden('order_view_mode', $_POST['order_view_mode']);

end_row();

end_table();
end_form();

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
if (isset($_POST['ChangeTmpl']) && $_POST['ChangeTmpl'] != 0)
{
  	$sql = "UPDATE sales_orders SET type = !type WHERE order_no=".$_POST['ChangeTmpl'];

  	db_query($sql, "Can't change sales order type");
}
//---------------------------------------------------------------------------------------------

$sql = "SELECT sales_orders.order_no, debtors_master.curr_code, debtors_master.name, cust_branch.br_name,
	sales_orders.ord_date, sales_orders.deliver_to, sales_orders.delivery_date,
	sales_orders.type, ";
$sql .= " Sum(sales_order_details.qty_sent) AS TotDelivered, ";
$sql .= " Sum(sales_order_details.quantity) AS TotQuantity, ";
$sql .= " Sum(sales_order_details.unit_price*sales_order_details.quantity*(1-sales_order_details.discount_percent)) AS OrderValue, ";

//if ($_POST['order_view_mode']=='InvoiceTemplates' || $_POST['order_view_mode']=='DeliveryTemplates')
  $sql .= "sales_orders.comments, ";
//else
  $sql .= "sales_orders.customer_ref";

$sql .=	" FROM sales_orders, sales_order_details, debtors_master, cust_branch
		WHERE sales_orders.order_no = sales_order_details.order_no
			AND sales_orders.debtor_no = debtors_master.debtor_no
			AND sales_orders.branch_code = cust_branch.branch_code
			AND debtors_master.debtor_no = cust_branch.debtor_no ";

//figure out the sql required from the inputs available
if (isset($_POST['OrderNumber']) && $_POST['OrderNumber'] != "")
{
	$sql .= " AND sales_orders.order_no LIKE '%". $_POST['OrderNumber'] ."' GROUP BY sales_orders.order_no";
}
else
{
  	if ($_POST['order_view_mode']!='DeliveryTemplates' && $_POST['order_view_mode']!='InvoiceTemplates')
  	{
		$date_after = date2sql($_POST['OrdersAfterDate']);
		$date_before = date2sql($_POST['OrdersToDate']);

		$sql .= " AND sales_orders.ord_date >= '$date_after'";
		$sql .= " AND sales_orders.ord_date <= '$date_before'";
  	}
	if ($selected_customer != -1)
		$sql .= " AND sales_orders.debtor_no='" . $selected_customer . "'";

	if (isset($selected_stock_item))
		$sql .= " AND sales_order_details.stk_code='". $selected_stock_item ."'";

	if (isset($_POST['StockLocation']) && $_POST['StockLocation'] != reserved_words::get_all())
		$sql .= " AND sales_orders.from_stk_loc = '". $_POST['StockLocation'] . "' ";

	if ($_POST['order_view_mode']=='OutstandingOnly')
		$sql .= " AND sales_order_details.qty_sent < sales_order_details.quantity";
	elseif ($_POST['order_view_mode']=='InvoiceTemplates' || $_POST['order_view_mode']=='DeliveryTemplates')
		$sql .= " AND sales_orders.type=1";

	$sql .= " GROUP BY sales_orders.order_no, sales_orders.debtor_no, sales_orders.branch_code,
		sales_orders.customer_ref, sales_orders.ord_date, sales_orders.deliver_to";

} //end not order number selected

$result = db_query($sql,"No orders were returned");

//-----------------------------------------------------------------------------------

if ($result)
{
	print_hidden_script(30);

	/*show a table of the orders returned by the sql */

	start_table("$table_style colspan=6 width=95%");
	$th = array(tr("Order #"), tr("Customer"), tr("Branch"), tr("Cust Order #"), tr("Order Date"),
		tr("Required By"), tr("Delivery To"), tr("Order Total"), tr("Currency"), "");

  	if($_POST['order_view_mode']=='InvoiceTemplates' || $_POST['order_view_mode']=='DeliveryTemplates')
	{
		$th[3] = tr('Description');
	} elseif ($_POST['order_view_mode'] != 'OutstandingOnly') {
		$th[9] = tr('Tmpl');
	 $th[] =''; $th[] =''; $th[] = '';
	} 

	table_header($th);
	start_form();

	$j = 1;
	$k = 0; //row colour counter
	$overdue_items = false;
	while ($myrow = db_fetch($result))
	{

		$view_page = get_customer_trans_view_str(systypes::sales_order(), $myrow["order_no"]);
		$formated_del_date = sql2date($myrow["delivery_date"]);
		$formated_order_date = sql2date($myrow["ord_date"]);
//	    $not_closed =  $myrow['type'] && ($myrow["TotDelivered"] < $myrow["TotQuantity"]);

    	// if overdue orders, then highlight as so
    	if ($myrow['type'] == 0 && date1_greater_date2(Today(), $formated_del_date))
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
	  	if($_POST['order_view_mode']=='InvoiceTemplates' || $_POST['order_view_mode']=='DeliveryTemplates')
		  	label_cell($myrow["comments"]);
	  	else
		  	label_cell($myrow["customer_ref"]);
		label_cell($formated_order_date);
		label_cell($formated_del_date);
		label_cell($myrow["deliver_to"]);
		amount_cell($myrow["OrderValue"]);
		label_cell($myrow["curr_code"]);
		if ($_POST['order_view_mode']=='OutstandingOnly'/* || $not_closed*/)
		{
    		$delivery_note = $path_to_root . "/sales/customer_delivery.php?" . SID . "OrderNumber=" .$myrow["order_no"];
    		label_cell("<a href='$delivery_note'>" . tr("Dispatch") . "</a>");
		}
  		elseif ($_POST['order_view_mode']=='InvoiceTemplates')
		{
    		$select_order= $path_to_root . "/sales/sales_order_entry.php?" . SID . "NewInvoice=" .$myrow["order_no"];
    		label_cell("<a href='$select_order'>" . tr("Invoice") . "</a>");
		}
  		elseif ($_POST['order_view_mode']=='DeliveryTemplates')
		{
  			$select_order= $path_to_root . "/sales/sales_order_entry.php?" . SID . "NewDelivery=" .$myrow["order_no"];
    		label_cell("<a href='$select_order'>" . tr("Delivery") . "</a>");
		}
		else
		{
		  	echo "<td><input ".($myrow["type"]==1 ? 'checked' : '')." type='checkbox' name='chgtpl" .$myrow["order_no"]. "' value='1'
		   		onclick='this.form.ChangeTmpl.value= this.name.substr(6);
		   		this.form.submit();' ></td>";

  		  	$modify_page = $path_to_root . "/sales/sales_order_entry.php?" . SID . "ModifyOrderNumber=" . $myrow["order_no"];
  		  	label_cell("<a href='$modify_page'>" . tr("Edit") . "</a>");
  		  	label_cell(print_document_link($myrow['order_no'], tr("Print"),true,	30, 0));
  		  	label_cell(print_document_link($myrow['order_no'], tr("Quote"),true,	30, 1));
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
  	hidden('ChangeTmpl', 0);
	end_form();
	end_table();

   if ($overdue_items)
   		display_note(tr("Marked items are overdue."), 0, 1, "class='overduefg'");
}

echo "<br>";

end_page();
?>
