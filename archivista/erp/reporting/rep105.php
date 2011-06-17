<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Order Status List
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "sales/includes/sales_db.inc");
include_once($path_to_root . "inventory/includes/db/items_category_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_order_status_list();

//----------------------------------------------------------------------------------------------------

function GetSalesOrders($from, $to, $category=0, $location=null, $backorder=0)
{
	$fromdate = date2sql($from);
	$todate = date2sql($to);

	$sql= "SELECT sales_orders.order_no,
				sales_orders.debtor_no,
                sales_orders.branch_code,
                sales_orders.customer_ref,
                sales_orders.ord_date,
                sales_orders.from_stk_loc,
                sales_orders.delivery_date,
                sales_order_details.stk_code,
                stock_master.description,
                stock_master.units,
                sales_order_details.quantity,
                sales_order_details.qty_sent
            FROM sales_orders
            	INNER JOIN sales_order_details
            	    ON sales_orders.order_no = sales_order_details.order_no
            	INNER JOIN stock_master
            	    ON sales_order_details.stk_code = stock_master.stock_id
            WHERE sales_orders.ord_date >='$fromdate'
                AND sales_orders.ord_date <='$todate'";
	if ($category > 0)
		$sql .= " AND stock_master.category_id=$category";
	if ($location != null)
		$sql .= " AND sales_orders.from_stk_loc='$location'";
	if ($backorder)
		$sql .= "AND sales_order_details.quantity - sales_order_details.qty_sent > 0";
	$sql .= " ORDER BY sales_orders.order_no";

	return db_query($sql, "Error getting order details");
}

//----------------------------------------------------------------------------------------------------

function print_order_status_list()
{
	global $path_to_root;

	include_once($path_to_root . "reporting/includes/pdf_report.inc");

	$from = $_REQUEST['PARAM_0'];
	$to = $_REQUEST['PARAM_1'];
	$category = $_REQUEST['PARAM_2'];
	$location = $_REQUEST['PARAM_3'];
	$backorder = $_REQUEST['PARAM_4'];
	$comments = $_REQUEST['PARAM_5'];

	$dec = user_qty_dec();

	if ($category == reserved_words::get_all_numeric())
		$category = 0;
	if ($location == reserved_words::get_all())
		$location = null;
	if ($category == 0)
		$cat = tr('All');
	else
		$cat = get_category_name($category);
	if ($location == null)
		$loc = tr('All');
	else
		$loc = $location;
	if ($backorder == 0)
		$back = tr('All Orders');
	else
		$back = tr('Back Orders Only');

	$cols = array(0, 60, 150, 260, 325,	385, 450, 515);

	$headers2 = array(tr('Order'), tr('Customer'), tr('Branch'), tr('Customer Ref'),
		tr('Ord Date'),	tr('Del Date'),	tr('Loc'));

	$aligns = array('left',	'left',	'right', 'right', 'right', 'right',	'right');

	$headers = array(tr('Code'),	tr('Description'), tr('Ordered'),	tr('Invoiced'),
		tr('Outstanding'), '');

    $params =   array( 	0 => $comments,
	    				1 => array(  'text' => tr('Period'), 'from' => $from, 'to' => $to),
	    				2 => array(  'text' => tr('Category'), 'from' => $cat,'to' => ''),
	    				3 => array(  'text' => tr('Location'), 'from' => $loc, 'to' => ''),
	    				4 => array(  'text' => tr('Selection'),'from' => $back,'to' => ''));

	$cols2 = $cols;
	$aligns2 = $aligns;

	$rep = new FrontReport(tr('Order Status Listing'), "OrderStatusListing.pdf", user_pagesize());
	$rep->Font();
	$rep->Info($params, $cols, $headers, $aligns, $cols2, $headers2, $aligns2);

	$rep->Header();
	$orderno = 0;

	$result = GetSalesOrders($from, $to, $category, $location, $backorder);

	while ($myrow=db_fetch($result))
	{
		if ($rep->row < $rep->bottomMargin + (2 * $rep->lineHeight))
		{
			$orderno = 0;
			$rep->Header();
		}
		$rep->NewLine(0, 2, false, $orderno);
		if ($orderno != $myrow['order_no'])
		{
			if ($orderno != 0)
			{
				$rep->Line($rep->row);
				$rep->NewLine();
			}
			$rep->TextCol(0, 1,	$myrow['order_no']);
			$rep->TextCol(1, 2,	get_customer_name($myrow['debtor_no']));
			$rep->TextCol(2, 3,	get_branch_name($myrow['branch_code']));
			$rep->TextCol(3, 4,	$myrow['customer_ref']);
			$rep->TextCol(4, 5,	sql2date($myrow['ord_date']));
			$rep->TextCol(5, 6,	sql2date($myrow['delivery_date']));
			$rep->TextCol(6, 7,	$myrow['from_stk_loc']);
			$rep->NewLine(2);
			$orderno = $myrow['order_no'];
		}
		$rep->TextCol(0, 1,	$myrow['stk_code']);
		$rep->TextCol(1, 2,	$myrow['description']);
		$rep->TextCol(2, 3,	number_format2($myrow['quantity'], $dec));
		$rep->TextCol(3, 4,	number_format2($myrow['qty_sent'], $dec));
		$rep->TextCol(4, 5,	number_format2($myrow['quantity'] - $myrow['qty_sent'], $dec));
		if ($myrow['quantity'] - $myrow['qty_sent'] > 0)
		{
			$rep->Font('italic');
			$rep->TextCol(5, 6,	tr('Outstanding'));
			$rep->Font();
		}
		$rep->NewLine();
		if ($rep->row < $rep->bottomMargin + (2 * $rep->lineHeight))
		{
			$orderno = 0;
			$rep->Header();
		}
	}
	$rep->Line($rep->row);
	$rep->End();
}

?>