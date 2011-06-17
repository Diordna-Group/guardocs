<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Stock Check
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");
include_once($path_to_root . "inventory/includes/db/items_category_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_stock_check();

function getTransactions($category, $location)
{
	$sql = "SELECT stock_master.category_id,
			stock_category.description AS cat_description,
			stock_master.stock_id,
			stock_master.description,
			stock_moves.loc_code,
			SUM(stock_moves.qty) AS QtyOnHand
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
		stock_category.description,
		stock_master.stock_id,
		stock_master.description
		ORDER BY stock_master.category_id,
		stock_master.stock_id";

    return db_query($sql,"No transactions were returned");
}

function getDemandQty($stockid, $location)
{
	$sql = "SELECT SUM(sales_order_details.quantity - sales_order_details.qty_sent) AS QtyDemand
				FROM sales_order_details,
					sales_orders
				WHERE sales_order_details.order_no=sales_orders.order_no AND
					sales_orders.from_stk_loc ='$location' AND
					sales_order_details.stk_code = '$stockid'";

    $TransResult = db_query($sql,"No transactions were returned");
	$DemandRow = db_fetch($TransResult);
	return $DemandRow['QtyDemand'];
}

function getDemandAsmQty($stockid, $location)
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
	if (db_num_rows($TransResult)==1)
	{
		$DemandRow = db_fetch_row($TransResult);
		$DemandQty = $DemandRow[0];
	}
	else
		$DemandQty = 0.0;

    return $DemandQty;
}

//----------------------------------------------------------------------------------------------------

function print_stock_check()
{
    global $comp_path, $path_to_root, $pic_height, $pic_width;

    include_once($path_to_root . "reporting/includes/pdf_report.inc");

    $category = $_REQUEST['PARAM_0'];
    $location = $_REQUEST['PARAM_1'];
    $pictures = $_REQUEST['PARAM_2'];
    $comments = $_REQUEST['PARAM_3'];

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

	$cols = array(0, 100, 305, 375, 445,	515);

	$headers = array(tr('Category'), tr('Description'), tr('Quantity'), tr('Demand'), tr('Difference'));

	$aligns = array('left',	'left',	'right', 'right', 'right');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Category'), 'from' => $cat, 'to' => ''),
    				    2 => array('text' => tr('Location'), 'from' => $loc, 'to' => ''));

	if ($pictures)
		$user_comp = user_company();
	else
		$user_comp = "";

    $rep = new FrontReport(tr('Stock Check Sheets'), "StockCheckSheet.pdf", user_pagesize());

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
		$demandqty = getDemandQty($trans['stock_id'], $trans['loc_code']);
		$demandqty += getDemandAsmQty($trans['stock_id'], $trans['loc_code']);
		$rep->NewLine();
		$rep->TextCol(0, 1, $trans['stock_id']);
		$rep->TextCol(1, 2, $trans['description']);
		$rep->TextCol(2, 3, number_format2($trans['QtyOnHand'], $dec));
		$rep->TextCol(3, 4, number_format2($demandqty, $dec));
		$rep->TextCol(4, 5, number_format2($trans['QtyOnHand'] - $demandqty, $dec));
		if ($pictures)
		{
			$image = $comp_path .'/'. $user_comp . '/images/' . $trans['stock_id'] . '.jpg';
			if (file_exists($image))
			{
				$rep->NewLine();
				if ($rep->row - $height < $rep->bottomMargin)
					$rep->Header();
				$rep->AddImage($image, $rep->cols[1], $rep->row - $pic_height, $pic_width, $pic_height);
				$rep->row -= $pic_height;
				$rep->NewLine();
			}
		}
	}
	$rep->Line($rep->row - 4);
    $rep->End();
}

?>