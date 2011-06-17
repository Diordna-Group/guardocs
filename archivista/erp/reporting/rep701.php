<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Chart of GL Accounts
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_Chart_of_Accounts();

//----------------------------------------------------------------------------------------------------

function print_Chart_of_Accounts()
{
	global $path_to_root;

	include_once($path_to_root . "reporting/includes/pdf_report.inc");

	$showbalance = $_REQUEST['PARAM_0'];
	$comments = $_REQUEST['PARAM_1'];
	$dec = 0;

	$cols = array(0, 50, 300, 425, 500);

	$headers = array(tr('Account'), tr('Account Name'), tr('Account Code'), tr('Balance'));
	
	$aligns = array('left',	'left',	'left',	'right');
	
	$params = array(0 => $comments);

	$rep = new FrontReport(tr('Chart of Accounts'), "ChartOfAccounts.pdf", user_pagesize());
	
	$rep->Font();
	$rep->Info($params, $cols, $headers, $aligns);
	$rep->Header();

	$classname = '';
	$group = '';

	$accounts = get_gl_accounts_all();

	while ($account=db_fetch($accounts))
	{
		if ($showbalance == 1)
		{
			$begin = begin_fiscalyear();
			if (is_account_balancesheet($account["account_code"]))
				$begin = "";
			$balance = get_gl_trans_from_to($begin, ToDay(), $account["account_code"], 0);
		}
		if ($account['AccountTypeName'] != $group)
		{
			if ($classname != '')
				$rep->row -= 4;
			if ($account['AccountClassName'] != $classname)
			{
				$rep->Font('bold');
				$rep->TextCol(0, 4, $account['AccountClassName']);
				$rep->Font();
				$rep->row -= ($rep->lineHeight + 4);
			}
			$group = $account['AccountTypeName'];
			$rep->TextCol(0, 4, $account['AccountTypeName']);
			//$rep->Line($rep->row - 4);
			$rep->row -= ($rep->lineHeight + 4);
		}
		$classname = $account['AccountClassName'];

		$rep->TextCol(0, 1,	$account['account_code']);
		$rep->TextCol(1, 2,	$account['account_name']);
		$rep->TextCol(2, 3,	$account['account_code2']);
		if ($showbalance == 1)	
			$rep->TextCol(3, 4,	number_format2($balance, $dec));

		$rep->NewLine();
		if ($rep->row < $rep->bottomMargin + 3 * $rep->lineHeight)
		{
			$rep->Line($rep->row - 2);
			$rep->Header();
		}
	}
	$rep->Line($rep->row);
	$rep->End();
}

?>