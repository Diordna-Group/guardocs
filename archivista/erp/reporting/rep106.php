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
print_salesman_list();

//----------------------------------------------------------------------------------------------------

function GetSalesmanTrans($from, $to)
{
	$fromdate = date2sql($from);
	$todate = date2sql($to);

	$sql = "SELECT DISTINCT debtor_trans.*,
		ov_amount+ov_discount AS InvoiceTotal,
		debtors_master.name AS DebtorName, debtors_master.curr_code, cust_branch.br_name,
		cust_branch.contact_name, salesman.*
		FROM debtor_trans, debtors_master, sales_orders, cust_branch,
			salesman
		WHERE sales_orders.order_no=debtor_trans.order_
		    AND sales_orders.branch_code=cust_branch.branch_code
		    AND cust_branch.salesman=salesman.salesman_code
		    AND debtor_trans.debtor_no=debtors_master.debtor_no
		    AND (debtor_trans.type=10 OR debtor_trans.type=11)
		    AND debtor_trans.tran_date>='$fromdate'
		    AND debtor_trans.tran_date<='$todate'
		ORDER BY salesman.salesman_code, debtor_trans.tran_date";

	return db_query($sql, "Error getting order details");
}

//----------------------------------------------------------------------------------------------------

function print_salesman_list()
{
	global $path_to_root;

	include_once($path_to_root . "reporting/includes/pdf_report.inc");

	$from = $_REQUEST['PARAM_0'];
	$to = $_REQUEST['PARAM_1'];
	$summary = $_REQUEST['PARAM_2'];
	$comments = $_REQUEST['PARAM_3'];

	if ($summary == 0)
		$sum = tr("No");
	else
		$sum = tr("Yes");

	$dec = user_qty_dec();

	$cols = array(0, 60, 150, 220, 325,	385, 450, 515);

	$headers = array(tr('Invoice'), tr('Customer'), tr('Branch'), tr('Customer Ref'),
		tr('Inv Date'),	tr('Total'),	tr('Provision'));

	$aligns = array('left',	'left',	'left', 'left', 'left', 'right',	'right');

	$headers2 = array(tr('Salesman'), " ",	tr('Phone'), tr('Email'),	tr('Provision'),
		tr('Break Pt.'), tr('Provision')." 2");

    $params =   array( 	0 => $comments,
	    				1 => array(  'text' => tr('Period'), 'from' => $from, 'to' => $to),
	    				2 => array(  'text' => tr('Summary Only'),'from' => $sum,'to' => ''));

	$cols2 = $cols;
	$aligns2 = $aligns;

	$rep = new FrontReport(tr('Salesman Listing'), "SalesmanListing.pdf", user_pagesize());
	$rep->Font();
	$rep->Info($params, $cols, $headers, $aligns, $cols2, $headers2, $aligns2);

	$rep->Header();
	$salesman = 0;
	$subtotal = $total = $subprov = $provtotal = 0;

	$result = GetSalesmanTrans($from, $to);

	while ($myrow=db_fetch($result))
	{
		if ($rep->row < $rep->bottomMargin + (2 * $rep->lineHeight))
		{
			$salesman = 0;
			$rep->Header();
		}
		$rep->NewLine(0, 2, false, $salesman);
		if ($salesman != $myrow['salesman_code'])
		{
			if ($salesman != 0)
			{
				$rep->Line($rep->row - 8);
				$rep->NewLine(2);
				$rep->TextCol(0, 3, tr('Total'));
				$rep->TextCol(5, 6, number_format2($subtotal, $dec));
				$rep->TextCol(6, 7, number_format2($subprov, $dec));
    			$rep->Line($rep->row  - 4);
    			$rep->NewLine(2);
				//$rep->Line($rep->row);
			}
			$rep->TextCol(0, 2,	$myrow['salesman_code']." ".$myrow['salesman_name']);
			$rep->TextCol(2, 3,	$myrow['salesman_phone']);
			$rep->TextCol(3, 4,	$myrow['salesman_email']);
			$rep->TextCol(4, 5,	number_format2($myrow['provision'], user_percent_dec()) ." %");
			$rep->TextCol(5, 6,	number_format2($myrow['break_pt'], $dec));
			$rep->TextCol(6, 7,	number_format2($myrow['provision2'], user_percent_dec()) ." %");
			$rep->NewLine(2);
			$salesman = $myrow['salesman_code'];
			$total += $subtotal;
			$provtotal += $subprov;
			$subtotal = 0;
			$subprov = 0;
		}
		$date = sql2date($myrow['tran_date']);
		$rate = get_exchange_rate_from_home_currency($myrow['curr_code'], $date);
		$amt = $myrow['InvoiceTotal'] * $rate;
		if ($subprov > $myrow['break_pt'] && $myrow['provision2'] != 0)
			$prov = $myrow['provision2'] * $amt / 100;
		else
			$prov = $myrow['provision'] * $amt / 100;
		if (!$summary)
		{
			$rep->TextCol(0, 1,	$myrow['trans_no']);
			$rep->TextCol(1, 2,	$myrow['DebtorName']);
			$rep->TextCol(2, 3,	$myrow['br_name']);
			$rep->TextCol(3, 4,	$myrow['contact_name']);
			$rep->TextCol(4, 5,	$date);
			$rep->TextCol(5, 6,	number_format2($amt, $dec));
			$rep->TextCol(6, 7,	number_format2($prov, $dec));
			$rep->NewLine();
			if ($rep->row < $rep->bottomMargin + (2 * $rep->lineHeight))
			{
				$salesman = 0;
				$rep->Header();
			}
		}
		$subtotal += $amt;
		$subprov += $prov;
	}
	if ($salesman != 0)
	{
		$rep->Line($rep->row - 4);
		$rep->NewLine(2);
		$rep->TextCol(0, 3, tr('Total'));
		$rep->TextCol(5, 6, number_format2($subtotal, $dec));
		$rep->TextCol(6, 7, number_format2($subprov, $dec));
		$rep->Line($rep->row  - 4);
		$rep->NewLine(2);
		//$rep->Line($rep->row);
		$total += $subtotal;
		$provtotal += $subprov;
	}
	$rep->fontSize += 2;
	$rep->TextCol(0, 3, tr('Grand Total'));
	$rep->fontSize -= 2;
	$rep->TextCol(5, 6, number_format2($total, $dec));
	$rep->TextCol(6, 7, number_format2($provtotal, $dec));
	$rep->Line($rep->row  - 4);
	$rep->End();
}

?>