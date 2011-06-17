<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Tax Report
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_tax_report();

function getCustTransactions($from, $to)
{
	$fromdate = date2sql($from);
	$todate = date2sql($to);

	$sql = "SELECT debtor_trans.reference,
			debtor_trans.type,
			sys_types.type_name,
			debtor_trans.tran_date,
			debtor_trans.debtor_no,
			debtors_master.name,
			debtors_master.curr_code,
			debtor_trans.branch_code,
			debtor_trans.order_,
			(ov_amount+ov_freight)*rate AS NetAmount,
			ov_freight*rate AS FreightAmount,
			ov_gst*rate AS Tax
		FROM debtor_trans
		INNER JOIN debtors_master ON debtor_trans.debtor_no=debtors_master.debtor_no
		INNER JOIN sys_types ON debtor_trans.type=sys_types.type_id
		WHERE debtor_trans.tran_date >= '$fromdate'
			AND debtor_trans.tran_date <= '$todate'
			AND (debtor_trans.type=10 OR debtor_trans.type=11)
		ORDER BY debtor_trans.tran_date";

    return db_query($sql,"No transactions were returned");
}

function getSuppTransactions($from, $to)
{
	$fromdate = date2sql($from);
	$todate = date2sql($to);

	$sql = "SELECT supp_trans.supp_reference,
			supp_trans.type,
			sys_types.type_name,
			supp_trans.tran_date,
			supp_trans.supplier_id,
			supp_trans.rate,
			suppliers.supp_name,
			suppliers.curr_code,
			supp_trans.rate,
			ov_amount*rate AS NetAmount,
			ov_gst*rate AS Tax
		FROM supp_trans
		INNER JOIN suppliers ON supp_trans.supplier_id=suppliers.supplier_id
		INNER JOIN sys_types ON supp_trans.type=sys_types.type_id
		WHERE supp_trans.tran_date >= '$fromdate'
			AND supp_trans.tran_date <= '$todate'
			AND (supp_trans.type=20 OR supp_trans.type=21)
		ORDER BY supp_trans.tran_date";

    return db_query($sql,"No transactions were returned");
}

function getTaxTypes()
{
	$sql = "SELECT id FROM tax_types ORDER BY id";
    return db_query($sql,"No transactions were returned");
}

function getTaxInfo($id)
{
	$sql = "SELECT * FROM tax_types WHERE id=$id";
    $result = db_query($sql,"No transactions were returned");
    return db_fetch($result);
}

function getCustInvTax($taxtype, $from, $to)
{
	$fromdate = date2sql($from);
	$todate = date2sql($to);

	$sql = "SELECT SUM(unit_price * quantity*debtor_trans.rate), SUM(amount*debtor_trans.rate)
		FROM debtor_trans_details, debtor_trans_tax_details, debtor_trans
				WHERE debtor_trans_details.debtor_trans_type>=10
					AND debtor_trans_details.debtor_trans_type<=11
					AND debtor_trans_details.debtor_trans_no=debtor_trans.trans_no
					AND debtor_trans_details.debtor_trans_type=debtor_trans.type
					AND debtor_trans_details.debtor_trans_no=debtor_trans_tax_details.debtor_trans_no
					AND debtor_trans_details.debtor_trans_type=debtor_trans_tax_details.debtor_trans_type
					AND debtor_trans_tax_details.tax_type_id=$taxtype
					AND debtor_trans.tran_date >= '$fromdate'
					AND debtor_trans.tran_date <= '$todate'";

    $result = db_query($sql,"No transactions were returned");
    return db_fetch_row($result);
}

function getSuppInvTax($taxtype, $from, $to)
{
	$fromdate = date2sql($from);
	$todate = date2sql($to);

	$sql = "SELECT SUM(unit_price * quantity * supp_trans.rate), SUM(amount*supp_trans.rate)
		FROM supp_invoice_items, supp_invoice_tax_items, supp_trans
				WHERE supp_invoice_items.supp_trans_type>=20
					AND supp_invoice_items.supp_trans_type<=21
					AND supp_invoice_items.supp_trans_no=supp_invoice_tax_items.supp_trans_no
					AND supp_invoice_items.supp_trans_type=supp_invoice_tax_items.supp_trans_type
					AND supp_invoice_items.supp_trans_no=supp_trans.trans_no
					AND supp_invoice_items.supp_trans_type=supp_trans.type
					AND supp_invoice_tax_items.tax_type_id=$taxtype
					AND supp_trans.tran_date >= '$fromdate'
					AND supp_trans.tran_date <= '$todate'";

    $result = db_query($sql,"No transactions were returned");
    return db_fetch_row($result);
}

//----------------------------------------------------------------------------------------------------

function print_tax_report()
{
	global $path_to_root;

	include_once($path_to_root . "reporting/includes/pdf_report.inc");

	$rep = new FrontReport(tr('Tax Report'), "TaxReport.pdf", user_pagesize());

	$from = $_REQUEST['PARAM_0'];
	$to = $_REQUEST['PARAM_1'];
	$summaryOnly = $_REQUEST['PARAM_2'];
	$comments = $_REQUEST['PARAM_3'];
	$dec = user_price_dec();

	if ($summaryOnly == 1)
		$summary = tr('Summary Only');
	else
		$summary = tr('Detailed Report');


	$res = getTaxTypes();

	$taxes = array();
	$i = 0;
	while ($tax=db_fetch($res))
		$taxes[$i++] = $tax['id'];
	$idcounter = count($taxes);

	$totalinvout = array(0,0,0,0,0,0,0,0,0,0);
	$totaltaxout = array(0,0,0,0,0,0,0,0,0,0);
	$totalinvin = array(0,0,0,0,0,0,0,0,0,0);
	$totaltaxin = array(0,0,0,0,0,0,0,0,0,0);

	if (!$summaryOnly)
	{
		$cols = array(0, 80, 130, 190, 290, 370, 435, 500, 565);

		$headers = array(tr('Trans Type'), tr('#'), tr('Date'), tr('Name'),	tr('Branch Name'),
			tr('Net'), tr('Tax'));

		$aligns = array('left', 'left', 'left', 'left', 'left', 'right', 'right');

		$params =   array( 	0 => $comments,
							1 => array('text' => tr('Period'), 'from' => $from, 'to' => $to),
							2 => array('text' => tr('Type'), 'from' => $summary, 'to' => ''));

		$rep->Font();
		$rep->Info($params, $cols, $headers, $aligns);
		$rep->Header();
	}
	$totalnet = 0.0;
	$totaltax = 0.0;

	$transactions = getCustTransactions($from, $to);

	while ($trans=db_fetch($transactions))
	{
		if (!$summaryOnly)
		{
			$rep->TextCol(0, 1,	$trans['type_name']);
			$rep->TextCol(1, 2,	$trans['reference']);
			$rep->TextCol(2, 3,	sql2date($trans['tran_date']));
			$rep->TextCol(3, 4,	$trans['name']);
			if ($trans["branch_code"] > 0)
				$rep->TextCol(4, 5,	get_branch_name($trans["branch_code"]));

			$rep->TextCol(5, 6,	number_format2($trans['NetAmount'], $dec));
			$rep->TextCol(6, 7,	number_format2($trans['Tax'], $dec));

			$rep->NewLine();

			if ($rep->row < $rep->bottomMargin + $rep->lineHeight)
			{
				$rep->Line($rep->row - 2);
				$rep->Header();
			}
		}
		$totalnet += $trans['NetAmount'];
		$totaltax += $trans['Tax'];

	}
	if (!$summaryOnly)
	{
		$rep->NewLine();

		if ($rep->row < $rep->bottomMargin + $rep->lineHeight)
		{
			$rep->Line($rep->row - 2);
			$rep->Header();
		}
		$rep->Line($rep->row + $rep->lineHeight);
		$rep->TextCol(3, 5,	tr('Total Outputs'));
		$rep->TextCol(5, 6,	number_format2($totalnet, $dec));
		$rep->TextCol(6, 7,	number_format2($totaltax, $dec));
		$rep->Line($rep->row - 5);
		$rep->Header();
	}
	$totalinnet = 0.0;
	$totalintax = 0.0;

	$transactions = getSuppTransactions($from, $to);

	while ($trans=db_fetch($transactions))
	{
		if (!$summaryOnly)
		{
			$rep->TextCol(0, 1,	$trans['type_name']);
			$rep->TextCol(1, 2,	$trans['supp_reference']);
			$rep->TextCol(2, 3,	sql2date($trans['tran_date']));
			$rep->TextCol(3, 5,	$trans['supp_name']);
			$rep->TextCol(5, 6,	number_format2($trans['NetAmount'], $dec));
			$rep->TextCol(6, 7,	number_format2($trans['Tax'], $dec));

			$rep->NewLine();
			if ($rep->row < $rep->bottomMargin + $rep->lineHeight)
			{
				$rep->Line($rep->row - 2);
				$rep->Header();
			}
		}
		$totalinnet += $trans['NetAmount'];
		$totalintax += $trans['Tax'];

	}
	if (!$summaryOnly)
	{
		$rep->NewLine();

		if ($rep->row < $rep->bottomMargin + $rep->lineHeight)
		{
			$rep->Line($rep->row - 2);
			$rep->Header();
		}
		$rep->Line($rep->row + $rep->lineHeight);
		$rep->TextCol(3, 5,	tr('Total Inputs'));
		$rep->TextCol(5, 6,	number_format2($totalinnet, $dec));
		$rep->TextCol(6, 7,	number_format2($totalintax, $dec));
		$rep->Line($rep->row - 5);
	}
	$cols2 = array(0, 100, 200,	300, 400, 500, 600);

	$headers2 = array(tr('Tax Rate'), tr('Outputs'), tr('Output Tax'),	tr('Inputs'), tr('Input Tax'));

	$aligns2 = array('left', 'right', 'right', 'right',	'right');

	$invamount = 0.0;
	for ($i = 0; $i < $idcounter; $i++)
	{
		$amt = getCustInvTax($taxes[$i], $from, $to);
		$totalinvout[$i] += $amt[0];
		$totaltaxout[$i] += $amt[1];
		$invamount += $amt[0];
	}
	if ($totalnet != $invamount)
		$totalinvout[$idcounter] = ($invamount - $totalnet);
	for ($i = 0; $i < $idcounter; $i++)
	{
		$amt = getSuppInvTax($taxes[$i], $from, $to);
		$totalinvin[$i] += $amt[0];
		$totaltaxin[$i] += $amt[1];
		$invamount += $amt[0];
	}
	if ($totalinnet != $invamount)
		$totalinvin[$idcounter] = ($totalinnet - $invamount);

	for ($i = 0; $i < count($cols2) - 2; $i++)
	{
		$rep->cols[$i] = $rep->leftMargin + $cols2[$i];
		$rep->headers[$i] = $headers2[$i];
		$rep->aligns[$i] = $aligns2[$i];
	}
	$rep->Header();
	$counter = count($totalinvout);
	$counter = max($counter, $idcounter);
	$trow = $rep->row;
	$i = 0;
	for ($j = 0; $j < $counter; $j++)
	{
		if (isset($taxes[$j]) && $taxes[$j] > 0)
		{
			$tx = getTaxInfo($taxes[$j]);
			$str = $tx['name'] . " " . number_format2($tx['rate'], $dec) . "%";
		}
		else
			$str = tr('No tax specified');
		$rep->TextCol($i, $i + 1, $str);
		$rep->NewLine();
	}
	$i++;
	$rep->row = $trow;
	for ($j = 0; $j < $counter; $j++)
	{
		$rep->TextCol($i, $i + 1, number_format2($totalinvout[$j], $dec));
		$rep->NewLine();
	}
	$i++;
	$rep->row = $trow;
	for ($j = 0; $j < $counter; $j++)
	{
		$rep->TextCol($i, $i + 1,number_format2($totaltaxout[$j], $dec));
		$rep->NewLine();
	}
	$i++;
	$rep->row = $trow;
	for ($j = 0; $j < $counter; $j++)
	{
		$rep->TextCol($i, $i + 1, number_format2($totalinvin[$j], $dec));
		$rep->NewLine();
	}
	$i++;
	$rep->row = $trow;
	for ($j = 0; $j < $counter; $j++)
	{
		$rep->TextCol($i, $i + 1, number_format2($totaltaxin[$j], $dec));
		$rep->NewLine();
	}
	$rep->Line($rep->row - 4);

	$locale = $path_to_root . "lang/" . $_SESSION['language']->code . "/locale.inc";
	if (file_exists($locale))
	{
		$taxinclude = true;
		include($locale);
		/*
		if (function_exists("TaxFunction"))
			TaxFunction();
		*/
	}
	$rep->End();
}

?>