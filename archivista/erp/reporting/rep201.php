<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Supplier Balances
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_supplier_balances();

function getTransactions($supplier_id, $date)
{
	$date = date2sql($date);

    $sql = "SELECT supp_trans.*, sys_types.type_name,
				(supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount)
				AS TotalAmount, supp_trans.alloc AS Allocated,
				((supp_trans.type = 20)
					AND supp_trans.due_date < '$date') AS OverDue
    			FROM supp_trans, sys_types
    			WHERE supp_trans.tran_date <= '$date' AND supp_trans.supplier_id = '$supplier_id'
    				AND supp_trans.type = sys_types.type_id
    				ORDER BY supp_trans.tran_date";

    $TransResult = db_query($sql,"No transactions were returned");

    return $TransResult;
}

//----------------------------------------------------------------------------------------------------

function print_supplier_balances()
{
    global $path_to_root;

    include_once($path_to_root . "reporting/includes/pdf_report.inc");

    $to = $_REQUEST['PARAM_0'];
    $fromsupp = $_REQUEST['PARAM_1'];
    $currency = $_REQUEST['PARAM_2'];
    $comments = $_REQUEST['PARAM_3'];

	if ($fromsupp == reserved_words::get_all_numeric())
		$from = tr('All');
	else
		$from = get_supplier_name($fromsupp);
    $dec = user_price_dec();

	if ($currency == reserved_words::get_all())
	{
		$convert = true;
		$currency = tr('Balances in Home currency');
	}
	else
		$convert = false;

	$cols = array(0, 100, 130, 190,	250, 320, 385, 450,	515);

	$headers = array(tr('Trans Type'), tr('#'), tr('Date'), tr('Due Date'), tr('Charges'),
		tr('Credits'), tr('Allocated'), tr('Outstanding'));

	$aligns = array('left',	'left',	'left',	'left',	'right', 'right', 'right', 'right');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('End Date'), 'from' => $to, 'to' => ''),
    				    2 => array('text' => tr('Supplier'), 'from' => $from, 'to' => ''),
    				    3 => array(  'text' => tr('Currency'),'from' => $currency, 'to' => ''));

    $rep = new FrontReport(tr('Supplier Balances'), "SupplierBalances.pdf", user_pagesize());

    $rep->Font();
    $rep->Info($params, $cols, $headers, $aligns);
    $rep->Header();

	$total = array();
	$grandtotal = array(0,0,0,0);

	$sql = "SELECT supplier_id, supp_name AS name, curr_code FROM suppliers ";
	if ($fromsupp != reserved_words::get_all_numeric())
		$sql .= "WHERE supplier_id=$fromsupp ";
	$sql .= "ORDER BY supp_name";
	$result = db_query($sql, "The customers could not be retrieved");

	while ($myrow=db_fetch($result))
	{
		if (!$convert && $currency != $myrow['curr_code'])
			continue;
		$rep->fontSize += 2;
		$rep->TextCol(0, 3, $myrow['name']);
		if ($convert)
			$rep->TextCol(3, 4,	$myrow['curr_code']);
		$rep->fontSize -= 2;
		$rep->NewLine(1, 2);
		$res = getTransactions($myrow['supplier_id'], $to);
		if (db_num_rows($res)==0)
			continue;
		$rep->Line($rep->row + 4);
		$total[0] = $total[1] = $total[2] = $total[3] = 0.0;
		while ($trans=db_fetch($res))
		{
			$rep->NewLine(1, 2);
			$rep->TextCol(0, 1,	$trans['type_name']);
			$rep->TextCol(1, 2,	$trans['reference']);
			$date = sql2date($trans['tran_date']);
			$rep->TextCol(2, 3,	$date);
			if ($trans['type'] == 20)
				$rep->TextCol(3, 4,	sql2date($trans['due_date']));
			$item[0] = $item[1] = 0.0;
			if ($convert)
				$rate = get_exchange_rate_from_home_currency($myrow['curr_code'], $date);
			else
				$rate = 1.0;
			if ($trans['TotalAmount'] > 0.0)
			{
				$item[0] = Abs($trans['TotalAmount']) * $rate;
				$rep->TextCol(4, 5,	number_format2($item[0], $dec));
			}
			else
			{
				$item[1] = Abs($trans['TotalAmount']) * $rate;
				$rep->TextCol(5, 6,	number_format2($item[1], $dec));
			}
			$item[2] = $trans['Allocated'] * $rate;
			$rep->TextCol(6, 7,	number_format2($item[2], $dec));
			if ($trans['type'] == 20)
				$item[3] = ($trans['TotalAmount'] - $trans['Allocated']) * $rate;
			else
				$item[3] = ($trans['TotalAmount'] + $trans['Allocated']) * $rate;
			$rep->TextCol(7, 8,	number_format2($item[3], $dec));
			for ($i = 0; $i < 4; $i++)
			{
				$total[$i] += $item[$i];
				$grandtotal[$i] += $item[$i];
			}
		}
		$rep->Line($rep->row - 8);
		$rep->NewLine(2);
		$rep->TextCol(0, 3,	tr('Total'));
		for ($i = 0; $i < 4; $i++)
		{
			$rep->TextCol($i + 4, $i + 5, number_format2($total[$i], $dec));
			$total[$i] = 0.0;
		}
    	$rep->Line($rep->row  - 4);
    	$rep->NewLine(2);
	}
	$rep->fontSize += 2;
	$rep->TextCol(0, 3,	tr('Grand Total'));
	$rep->fontSize -= 2;
	for ($i = 0; $i < 4; $i++)
		$rep->TextCol($i + 4, $i + 5,number_format2($grandtotal[$i], $dec));
	$rep->Line($rep->row  - 4);
    $rep->End();
}

?>