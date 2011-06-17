<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Payment Report
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_payment_report();

function getTransactions($supplier, $date)
{
	$date = date2sql($date);

	$sql = "SELECT sys_types.type_name,
			supp_trans.supp_reference,
			supp_trans.due_date,
			supp_trans.trans_no,
			supp_trans.type,
			(supp_trans.ov_amount + supp_trans.ov_gst - supp_trans.alloc) AS Balance,
			(supp_trans.ov_amount + supp_trans.ov_gst ) AS TranTotal
		FROM supp_trans,
			sys_types
		WHERE sys_types.type_id = supp_trans.type
		AND supp_trans.supplier_id = '" . $supplier . "'
		AND supp_trans.ov_amount + supp_trans.ov_gst - supp_trans.alloc != 0
		AND supp_trans.due_date <='" . $date . "'
		ORDER BY supp_trans.type,
			supp_trans.trans_no";

    return db_query($sql, "No transactions were returned");
}

//----------------------------------------------------------------------------------------------------

function print_payment_report()
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
		$currency = tr('Balances in Home Currency');
	}
	else
		$convert = false;

	$cols = array(0, 100, 130, 190,	250, 320, 385, 450,	515);

	$headers = array(tr('Trans Type'), tr('#'), tr('Due Date'), '', '',
		'', tr('Total'), tr('Balance'));

	$aligns = array('left',	'left',	'left',	'left',	'right', 'right', 'right', 'right');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('End Date'), 'from' => $to, 'to' => ''),
    				    2 => array('text' => tr('Supplier'), 'from' => $from, 'to' => ''),
    				    3 => array(  'text' => tr('Currency'),'from' => $currency, 'to' => ''));

    $rep = new FrontReport(tr('Payment Report'), "PaymentReport.pdf", user_pagesize());

    $rep->Font();
    $rep->Info($params, $cols, $headers, $aligns);
    $rep->Header();

	$total = array();
	$grandtotal = array(0,0);

	$sql = "SELECT supplier_id, supp_name AS name, curr_code, payment_terms.terms FROM suppliers, payment_terms
		WHERE ";
	if ($fromsupp != reserved_words::get_all_numeric())
		$sql .= "supplier_id=$fromsupp AND ";
	$sql .= "suppliers.payment_terms = payment_terms.terms_indicator
		ORDER BY supp_name";
	$result = db_query($sql, "The customers could not be retrieved");

	while ($myrow=db_fetch($result))
	{
		if (!$convert && $currency != $myrow['curr_code'])
			continue;
		$rep->fontSize += 2;
		$rep->TextCol(0, 6, $myrow['name'] . " - " . $myrow['terms']);
		if ($convert)
		{
			$rate = get_exchange_rate_from_home_currency($myrow['curr_code'], $to);
			$rep->TextCol(6, 7,	$myrow['curr_code']);
		}
		else
			$rate = 1.0;
		$rep->fontSize -= 2;
		$rep->NewLine(1, 2);
		$res = getTransactions($myrow['supplier_id'], $to);
		if (db_num_rows($res)==0)
			continue;
		$rep->Line($rep->row + 4);
		$total[0] = $total[1] = 0.0;
		while ($trans=db_fetch($res))
		{
			$rep->NewLine(1, 2);
			$rep->TextCol(0, 1,	$trans['type_name']);
			$rep->TextCol(1, 2,	$trans['supp_reference']);
			$rep->TextCol(2, 3,	sql2date($trans['due_date']));
			$item[0] = Abs($trans['TranTotal']) * $rate;
			$rep->TextCol(6, 7,	number_format2($item[0], $dec));
			$item[1] = $trans['Balance'] * $rate;
			$rep->TextCol(7, 8,	number_format2($item[1], $dec));
			for ($i = 0; $i < 2; $i++)
			{
				$total[$i] += $item[$i];
				$grandtotal[$i] += $item[$i];
			}
		}
		$rep->Line($rep->row - 8);
		$rep->NewLine(2);
		$rep->TextCol(0, 3,	tr('Total'));
		for ($i = 0; $i < 2; $i++)
		{
			$rep->TextCol($i + 6, $i + 7, number_format2($total[$i], $dec));
			$total[$i] = 0.0;
		}
    	$rep->Line($rep->row  - 4);
    	$rep->NewLine(2);
	}
	$rep->fontSize += 2;
	$rep->TextCol(0, 3,	tr('Grand Total'));
	$rep->fontSize -= 2;
	for ($i = 0; $i < 2; $i++)
		$rep->TextCol($i + 6, $i + 7,number_format2($grandtotal[$i], $dec));
	$rep->Line($rep->row  - 4);
    $rep->End();
}

?>