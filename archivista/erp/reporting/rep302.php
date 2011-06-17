<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Inventory Planning
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");
include_once($path_to_root . "inventory/includes/db/items_category_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_inventory_planning();

function getTransactions($category, $location)
{
	$sql = "SELECT stock_master.category_id,
			stock_category.description AS cat_description,
			stock_master.stock_id,
			stock_master.description,
			stock_moves.loc_code,
			SUM(stock_moves.qty) AS qty_on_hand
		FROM stock_master,
			stock_category,
			stock_moves
		WHERE stock_master.stock_id=stock_moves.stock_id
		AND stock_master.category_id=stock_category.category_id
		AND (stock_master.mb_flag='B' OR stock_master.mb_flag='M')";
	if ($category != 0)
		$sql .= " AND stock_master.category_id = '$category'";
	if ($location != 'all')
		$sql .= " AND stock_moves.loc_code = '$location'";
	$sql .= " GROUP BY stock_master.category_id,
		stock_master.description,
		stock_category.description,
		stock_moves.stock_id,
		stock_master.stock_id
		ORDER BY stock_master.category_id,
		stock_master.stock_id";

    return db_query($sql,"No transactions were returned");

}

function getCustQty($stockid, $location)
{
	$sql = "SELECT SUM(sales_order_details.quantity - sales_order_details.qty_sent) AS qty_demand
				FROM sales_order_details,
					sales_orders
				WHERE sales_order_details.order_no=sales_orders.order_no AND
					sales_orders.from_stk_loc ='$location' AND
					sales_order_details.stk_code = '$stockid'";

    $TransResult = db_query($sql,"No transactions were returned");
	$DemandRow = db_fetch($TransResult);
	return $DemandRow['qty_demand'];
}

function getCustAsmQty($stockid, $location)
{
	$sql = "SELECT SUM((sales_order_details.quantity-sales_order_details.qty_sent)*bom.quantity)
				   AS Dem
				   FROM sales_order_details,
						sales_orders,
						bom,
						stock_master
				   WHERE sales_order_details.stk_code=bom.parent AND
				   sales_orders.order_no = sales_order_details.order_no AND
				   sales_orders.from_stk_loc='$location' AND
				   sales_order_details.quantity-sales_order_details.qty_sent > 0 AND
				   bom.component='$stockid' AND
				   stock_master.stock_id=bom.parent AND
				   stock_master.mb_flag='A'";

    $TransResult = db_query($sql,"No transactions were returned");
	if (db_num_rows($TransResult) == 1)
	{
		$DemandRow = db_fetch_row($TransResult);
		$DemandQty = $DemandRow[0];
	}
	else
		$DemandQty = 0.0;

    return $DemandQty;
}

function getSuppQty($stockid, $location)
{
	$sql = "SELECT SUM(purch_order_details.quantity_ordered - purch_order_details.quantity_received) AS QtyOnOrder
				FROM purch_order_details,
					purch_orders
				WHERE purch_order_details.order_no = purch_orders.order_no
				AND purch_order_details.item_code = '$stockid'
				AND purch_orders.into_stock_location= '$location'";

    $TransResult = db_query($sql,"No transactions were returned");
	$DemandRow = db_fetch($TransResult);
	return $DemandRow['QtyOnOrder'];
}

function getPeriods($stockid, $location)
{
	$date5 = date('Y-m-d');
	$date4 = date('Y-m-d',mktime(0,0,0,date('m'),1,date('Y')));
	$date3 = date('Y-m-d',mktime(0,0,0,date('m')-1,1,date('Y')));
	$date2 = date('Y-m-d',mktime(0,0,0,date('m')-2,1,date('Y')));
	$date1 = date('Y-m-d',mktime(0,0,0,date('m')-3,1,date('Y')));
	$date0 = date('Y-m-d',mktime(0,0,0,date('m')-4,1,date('Y')));

	$sql = "SELECT SUM(CASE WHEN tran_date >= '$date0' AND tran_date < '$date1' THEN -qty ELSE 0 END) AS prd0,
		   		SUM(CASE WHEN tran_date >= '$date1' AND tran_date < '$date2' THEN -qty ELSE 0 END) AS prd1,
				SUM(CASE WHEN tran_date >= '$date2' AND tran_date < '$date3' THEN -qty ELSE 0 END) AS prd2,
				SUM(CASE WHEN tran_date >= '$date3' AND tran_date < '$date4' THEN -qty ELSE 0 END) AS prd3,
				SUM(CASE WHEN tran_date >= '$date4' AND tran_date <= '$date5' THEN -qty ELSE 0 END) AS prd4
			FROM stock_moves
			WHERE stock_id='$stockid'
			AND loc_code ='$location'
			AND (type=10 OR type=11)
			AND visible=1";

    $TransResult = db_query($sql,"No transactions were returned");
	return db_fetch($TransResult);
}

//----------------------------------------------------------------------------------------------------

function print_inventory_planning()
{
    global $path_to_root;

    include_once($path_to_root . "reporting/includes/pdf_report.inc");

    $category = $_REQUEST['PARAM_0'];
    $location = $_REQUEST['PARAM_1'];
    $comments = $_REQUEST['PARAM_2'];

    $dec = user_qty_dec();

	if ($category == reserved_words::get_all_numeric())
		$category = 0;
	if ($category == 0)
		$cat = tr('All');
	else
		$cat = get_category_name($category);

	if ($location == reserved_words::get_all())
		$location = 'all';
	if ($location == 'all')
		$loc = tr('All');
	else
		$loc = $location;

	$cols = array(0, 50, 150, 180, 210, 240, 270, 300, 330, 390, 435, 480, 525);

	$per0 = strftime('%b',mktime(0,0,0,date('m'),date('d'),date('Y')));
	$per1 = strftime('%b',mktime(0,0,0,date('m')-1,date('d'),date('Y')));
	$per2 = strftime('%b',mktime(0,0,0,date('m')-2,date('d'),date('Y')));
	$per3 = strftime('%b',mktime(0,0,0,date('m')-3,date('d'),date('Y')));
	$per4 = strftime('%b',mktime(0,0,0,date('m')-4,date('d'),date('Y')));

	$headers = array(tr('Category'), '', $per4, $per3, $per2, $per1, $per0, '3*M',
		tr('QOH'), tr('Cust Ord'), tr('Supp Ord'), tr('Sugg Ord'));

	$aligns = array('left',	'left',	'right', 'right', 'right', 'right', 'right', 'right',
		'right', 'right', 'right', 'right');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Category'), 'from' => $cat, 'to' => ''),
    				    2 => array('text' => tr('Location'), 'from' => $loc, 'to' => ''));

    $rep = new FrontReport(tr('Inventory Planning Report'), "InventoryPlanning.pdf", user_pagesize());

    $rep->Font();
    $rep->Info($params, $cols, $headers, $aligns);
    $rep->Header();

	$res = getTransactions($category, $location);
	$catt = '';
	while ($trans=db_fetch($res))
	{
		if ($catt != $trans['cat_description'])
		{
			if ($catt != '')
			{
				$rep->Line($rep->row - 2);
				$rep->NewLine(2, 3);
			}
			$rep->TextCol(0, 1, $trans['category_id']);
			$rep->TextCol(1, 2, $trans['cat_description']);
			$catt = $trans['cat_description'];
			$rep->NewLine();
		}

		$custqty = getCustQty($trans['stock_id'], $trans['loc_code']);
		$custqty += getCustAsmQty($trans['stock_id'], $trans['loc_code']);
		$suppqty = getSuppQty($trans['stock_id'], $trans['loc_code']);
		$period = getPeriods($trans['stock_id'], $trans['loc_code']);
		$rep->NewLine();
		$rep->TextCol(0, 1, $trans['stock_id']);
		$rep->TextCol(1, 2, $trans['description']);
		$rep->TextCol(2, 3, number_format2($period['prd0'], $dec));
		$rep->TextCol(3, 4, number_format2($period['prd1'], $dec));
		$rep->TextCol(4, 5, number_format2($period['prd2'], $dec));
		$rep->TextCol(5, 6, number_format2($period['prd3'], $dec));
		$rep->TextCol(6, 7, number_format2($period['prd4'], $dec));

		$MaxMthSales = Max($period['prd0'], $period['prd1'], $period['prd2'], $period['prd3']);
		$IdealStockHolding = $MaxMthSales * 3;
		$rep->TextCol(7, 8, number_format2($IdealStockHolding, $dec));

		$rep->TextCol(8, 9, number_format2($trans['qty_on_hand'], $dec));
		$rep->TextCol(9, 10, number_format2($custqty, $dec));
		$rep->TextCol(10, 11, number_format2($suppqty, $dec));

		$SuggestedTopUpOrder = $IdealStockHolding - $trans['qty_on_hand'] + $custqty - $suppqty;
		if ($SuggestedTopUpOrder < 0.0)
			$SuggestedTopUpOrder = 0.0;
		$rep->TextCol(11, 12, number_format2($SuggestedTopUpOrder, $dec));
	}
	$rep->Line($rep->row - 4);
    $rep->End();
}

?>