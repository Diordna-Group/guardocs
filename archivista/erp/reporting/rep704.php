<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	GL Accounts Transactions
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_GL_transactions();

//----------------------------------------------------------------------------------------------------

function print_GL_transactions()
{
	global $path_to_root;

	include_once($path_to_root . "reporting/includes/pdf_report.inc");

	$rep = new FrontReport(tr('GL Account Transactions'), "GLAccountTransactions.pdf", user_pagesize());
	$dim = get_company_pref('use_dimension');
	$dimension = $dimension2 = 0;

	$from = $_REQUEST['PARAM_0'];
	$to = $_REQUEST['PARAM_1'];
	$fromacc = $_REQUEST['PARAM_2'];
	$toacc = $_REQUEST['PARAM_3'];
	if ($dim == 2)
	{
		$dimension = $_REQUEST['PARAM_4'];
		$dimension2 = $_REQUEST['PARAM_5'];
		$comments = $_REQUEST['PARAM_6'];
	}
	else if ($dim == 1)
	{
		$dimension = $_REQUEST['PARAM_4'];
		$comments = $_REQUEST['PARAM_5'];
	}
	else
	{
		$comments = $_REQUEST['PARAM_4'];
	}
	$dec = user_price_dec();

	$cols = array(0, 70, 90, 140, 210, 280, 340, 400, 450, 510, 570);
	//------------0--1---2---3----4----5----6----7----8----9----10-------
	//-----------------------dim1-dim2-----------------------------------
	//-----------------------dim1----------------------------------------
	//-------------------------------------------------------------------
	$aligns = array('left',	'left',	'left',	'left',	'left',	'left',	'right', 'right', 'right');

	if ($dim == 2)
		$headers = array(tr('Type'),	tr('#'),	tr('Date'), tr('Dimension')." 1", tr('Dimension')." 2",
			tr('Person/Item'), tr('Debit'),	tr('Credit'), tr('Balance'));
	else if ($dim == 1)
		$headers = array(tr('Type'),	tr('#'),	tr('Date'), tr('Dimension'), "", tr('Person/Item'),
			tr('Debit'),	tr('Credit'), tr('Balance'));
	else
		$headers = array(tr('Type'),	tr('#'),	tr('Date'), "", "", tr('Person/Item'),
			tr('Debit'),	tr('Credit'), tr('Balance'));

	if ($dim == 2)
	{
    	$params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Period'), 'from' => $from, 'to' => $to),
    				    2 => array('text' => tr('Accounts'),'from' => $fromacc,'to' => $toacc),
                    	3 => array('text' => tr('Dimension')." 1", 'from' => get_dimension_string($dimension),
                            'to' => ''),
                    	4 => array('text' => tr('Dimension')." 2", 'from' => get_dimension_string($dimension2),
                            'to' => ''));
    }
    else if ($dim == 1)
    {
    	$params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Period'), 'from' => $from, 'to' => $to),
    				    2 => array('text' => tr('Accounts'),'from' => $fromacc,'to' => $toacc),
                    	3 => array('text' => tr('Dimension'), 'from' => get_dimension_string($dimension),
                            'to' => ''));
    }
    else
    {
    	$params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Period'), 'from' => $from, 'to' => $to),
    				    2 => array('text' => tr('Accounts'),'from' => $fromacc,'to' => $toacc));
    }

	$rep->Font();
	$rep->Info($params, $cols, $headers, $aligns);
	$rep->Header();

	$accounts = get_gl_accounts($fromacc, $toacc);

	while ($account=db_fetch($accounts))
	{
		if (is_account_balancesheet($account["account_code"]))
			$begin = "";
		else
		{
			if ($from < $begin)
				$begin = add_days($from, -1);
			else
				$begin = add_days(begin_fiscalyear(), -1);
		}
		$prev_balance = get_gl_balance_from_to($begin, $from, $account["account_code"], $dimension, $dimension2);

		$trans = get_gl_transactions($from, $to, -1, $account['account_code'], $dimension, $dimension2);
		$rows = db_num_rows($trans);
		if ($prev_balance == 0.0 && $rows == 0)
			continue;
		$rep->Font('bold');
		$rep->TextCol(0, 3,	$account['account_code'] . " " . $account['account_name']);
		$rep->TextCol(3, 5, tr('Opening Balance'));
		if ($prev_balance > 0.0)
			$rep->TextCol(6, 7,	number_format2(abs($prev_balance), $dec));
		else
			$rep->TextCol(7, 8,	number_format2(abs($prev_balance), $dec));
		$rep->Font();
		$total = $prev_balance;
		$rep->NewLine(2);
		if ($rows > 0)
		{
			while ($myrow=db_fetch($trans))
			{
				$total += $myrow['amount'];

				$rep->TextCol(0, 1,	systypes::name($myrow["type"]));
				$rep->TextCol(1, 2,	$myrow['type_no']);
				$rep->TextCol(2, 3,	sql2date($myrow["tran_date"]));
				if ($dim >= 1)
					$rep->TextCol(3, 4,	get_dimension_string($myrow['dimension_id']));
				if ($dim > 1)
					$rep->TextCol(4, 5,	get_dimension_string($myrow['dimension2_id']));
				$rep->TextCol(5, 6,	payment_person_types::person_name($myrow["person_type_id"],$myrow["person_id"], false));
				if ($myrow['amount'] > 0.0)
					$rep->TextCol(6, 7,	number_format2(abs($myrow['amount']), $dec));
				else
					$rep->TextCol(7, 8,	number_format2(abs($myrow['amount']), $dec));
				$rep->TextCol(8, 9,	number_format2($total, $dec));
				$rep->NewLine();
				if ($rep->row < $rep->bottomMargin + $rep->lineHeight)
				{
					$rep->Line($rep->row - 2);
					$rep->Header();
				}
			}
			$rep->NewLine();
		}
		$rep->Font('bold');
		$rep->TextCol(3, 5,	tr("Ending Balance"));
		if ($total > 0.0)
			$rep->TextCol(6, 7,	number_format2(abs($total), $dec));
		else
			$rep->TextCol(7, 8,	number_format2(abs($total), $dec));
		$rep->Font();
		$rep->Line($rep->row - $rep->lineHeight + 4);
		$rep->NewLine(2, 1);
	}
	$rep->End();
}

?>