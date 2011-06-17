<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	price Listing
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");
include_once($path_to_root . "sales/includes/db/sales_types_db.inc");
include_once($path_to_root . "inventory/includes/db/items_category_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_price_listing();

function fetch_prices($category=0, $salestype=0)
{
		$sql = "SELECT prices.sales_type_id,
				prices.stock_id,
				stock_master.description AS name,
				prices.curr_abrev,
				prices.price,
				sales_types.sales_type,
				stock_master.material_cost+stock_master.labour_cost+stock_master.overhead_cost AS Standardcost,
				stock_master.category_id,
				stock_category.description
			FROM stock_master,
				stock_category,
				sales_types,
				prices
			WHERE stock_master.stock_id=prices.stock_id
				AND prices.sales_type_id=sales_types.id
				AND stock_master.category_id=stock_category.category_id";
		if ($salestype != 0)
			$sql .= " AND sales_types.id = '$salestype'";
		if ($category != 0)
			$sql .= " AND stock_category.category_id = '$category'";
		$sql .= " ORDER BY prices.curr_abrev,
				stock_master.category_id,
				stock_master.stock_id";

    return db_query($sql,"No transactions were returned");
}

//----------------------------------------------------------------------------------------------------

function print_price_listing()
{
    global $comp_path, $path_to_root, $pic_height, $pic_width;

    include_once($path_to_root . "reporting/includes/pdf_report.inc");

    $category = $_REQUEST['PARAM_0'];
    $salestype = $_REQUEST['PARAM_1'];
    $pictures = $_REQUEST['PARAM_2'];
    $showGP = $_REQUEST['PARAM_3'];
    $comments = $_REQUEST['PARAM_4'];

    $dec = user_price_dec();

	if ($category == reserved_words::get_all_numeric())
		$category = 0;
	if ($salestype == reserved_words::get_all_numeric())
		$salestype = 0;
	if ($category == 0)
		$cat = tr('All');
	else
		$cat = get_category_name($category);
	if ($salestype == 0)
		$stype = tr('All');
	else
		$stype = get_sales_type_name($salestype);
	if ($showGP == 0)
		$GP = tr('No');
	else
		$GP = tr('Yes');

	$cols = array(0, 100, 385, 450, 515);

	$headers = array(tr('Category/Items'), tr('Description'),	tr('Price'),	tr('GP %'));

	$aligns = array('left',	'left',	'right', 'right');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Category'), 'from' => $cat, 'to' => ''),
    				    2 => array('text' => tr('Sales Type'), 'from' => $stype, 'to' => ''),
    				    3 => array(  'text' => tr('Show GP %'),'from' => $GP,'to' => ''));

	if ($pictures)
		$user_comp = user_company();
	else
		$user_comp = "";

    $rep = new FrontReport(tr('Price Listing'), "PriceListing.pdf", user_pagesize());

    $rep->Font();
    $rep->Info($params, $cols, $headers, $aligns);
    $rep->Header();

	$result = fetch_prices($category, $salestype);

	$currcode = '';
	$catgor = '';

	while ($myrow=db_fetch($result))
	{
		if ($currcode != $myrow['curr_abrev'])
		{
			$rep->NewLine(2);
			$rep->fontSize += 2;
			$rep->TextCol(0, 3,	$myrow['curr_abrev'] . " " . tr('Prices'));
			$currcode = $myrow['curr_abrev'];
			$rep->fontSize -= 2;
			$rep->NewLine();
		}
		if ($catgor != $myrow['description'])
		{
			$rep->Line($rep->row  - $rep->lineHeight);
			$rep->NewLine(2);
			$rep->fontSize += 2;
			$rep->TextCol(0, 3, $myrow['category_id'] . " - " . $myrow['description']);
			$catgor = $myrow['description'];
			$rep->fontSize -= 2;
			$rep->NewLine();
		}
		$rep->NewLine();
		$rep->TextCol(0, 1,	$myrow['stock_id']);
		$rep->TextCol(1, 2, $myrow['name']);
		$rep->TextCol(2, 3,	number_format2($myrow['price'], $dec));
		if ($showGP)
		{
			if ($myrow['price'] != 0.0)
				$disp = ($myrow['price'] - $myrow['Standardcost']) * 100 / $myrow['price'];
			else
				$disp = 0.0;
			$rep->TextCol(3, 4,	number_format2($disp, user_percent_dec()) . " %");
		}
		if ($pictures)
		{
			$image = $comp_path . '/'. $user_comp . "/images/" . $myrow['stock_id'] . ".jpg";
			if (file_exists($image))
			{
				$rep->NewLine();
				if ($rep->row - $pic_height < $rep->bottomMargin)
					$rep->Header();
				$rep->AddImage($image, $rep->cols[1], $rep->row - $pic_height, $pic_width, $pic_height);
				$rep->row -= $pic_height;
				$rep->NewLine();
			}
		}
		else
			$rep->NewLine(0, 1);
	}
	$rep->Line($rep->row  - 4);
    $rep->End();
}

?>