<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Balance Sheet
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_balance_sheet();


//----------------------------------------------------------------------------------------------------

function print_balance_sheet()
{
	global $comp_path, $path_to_root;

	include_once($path_to_root . "reporting/includes/pdf_report.inc");
	$dim = get_company_pref('use_dimension');
	$dimension = $dimension2 = 0;

	$from = $_REQUEST['PARAM_0'];
	$to = $_REQUEST['PARAM_1'];
	if ($dim == 2)
	{
		$dimension = $_REQUEST['PARAM_2'];
		$dimension2 = $_REQUEST['PARAM_3'];
		$graphics = $_REQUEST['PARAM_4'];
		$comments = $_REQUEST['PARAM_5'];
	}
	else if ($dim == 1)
	{
		$dimension = $_REQUEST['PARAM_2'];
		$graphics = $_REQUEST['PARAM_3'];
		$comments = $_REQUEST['PARAM_4'];
	}
	else
	{
		$graphics = $_REQUEST['PARAM_2'];
		$comments = $_REQUEST['PARAM_3'];
	}
	if ($graphics)
	{
		include_once($path_to_root . "reporting/includes/class.graphic.inc");
		$pg = new graph();
	}
	$dec = 0;

	$cols = array(0, 50, 200, 350, 425,	500);
	//------------0--1---2----3----4----5--

	$headers = array(tr('Account'), tr('Account Name'), tr('Open Balance'), tr('Period'),
		tr('Close Balance'));

	$aligns = array('left',	'left',	'right', 'right', 'right');

    if ($dim == 2)
    {
    	$params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Period'),'from' => $from, 'to' => $to),
                    	2 => array('text' => tr('Dimension')." 1",
                            'from' => get_dimension_string($dimension), 'to' => ''),
                    	3 => array('text' => tr('Dimension')." 2",
                            'from' => get_dimension_string($dimension2), 'to' => ''));
    }
    else if ($dim == 1)
    {
    	$params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Period'),'from' => $from, 'to' => $to),
                    	2 => array('text' => tr('Dimension'),
                            'from' => get_dimension_string($dimension), 'to' => ''));
    }
    else
    {
    	$params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Period'),'from' => $from, 'to' => $to));
    }

	$rep = new FrontReport(tr('Balance Sheet'), "BalanceSheet.pdf", user_pagesize());

	$rep->Font();
	$rep->Info($params, $cols, $headers, $aligns);
	$rep->Header();

	$classname = '';
	$group = '';
	$totalopen = 0.0;
	$totalperiod = 0.0;
	$totalclose = 0.0;
	$classopen = 0.0;
	$classperiod = 0.0;
	$classclose = 0.0;
	$assetsopen = 0.0;
	$assetsperiod = 0.0;
	$assetsclose = 0.0;
	$closeclass = false;

	$accounts = get_gl_accounts_all(1);

	while ($account=db_fetch($accounts))
	{
		$prev_balance = get_gl_balance_from_to("", $from, $account["account_code"], $dimension, $dimension2);

		$curr_balance = get_gl_trans_from_to($from, $to, $account["account_code"], $dimension, $dimension2);

		if (!$prev_balance && !$curr_balance)
			continue;

		if ($account['AccountClassName'] != $classname)
		{
			if ($classname != '')
			{
				$closeclass = true;
			}
		}

		if ($account['AccountTypeName'] != $group)
		{
			if ($group != '')
			{
				$rep->Line($rep->row + 6);
				$rep->row -= 6;
				$rep->TextCol(0, 2,	tr('Total') . " " . $group);
				$rep->TextCol(2, 3,	number_format2($totalopen, $dec));
				$rep->TextCol(3, 4,	number_format2($totalperiod, $dec));
				$rep->TextCol(4, 5,	number_format2($totalclose, $dec));
				if ($graphics)
				{
					$pg->x[] = $group;
					$pg->y[] = abs($totalclose);
				}
				$totalopen = $totalperiod = $totalclose = 0.0;
				$rep->row -= ($rep->lineHeight + 4);
				if ($closeclass)
				{
					$rep->Line($rep->row + 6);
					$rep->row -= 6;
					$rep->Font('bold');
					$rep->TextCol(0, 2,	tr('Total') . " " . $classname);
					$rep->TextCol(2, 3,	number_format2($classopen, $dec));
					$rep->TextCol(3, 4,	number_format2($classperiod, $dec));
					$rep->TextCol(4, 5,	number_format2($classclose, $dec));
					$rep->Font();
					$assetsopen += $classopen;
					$assetsperiod += $classperiod;
					$assetsclose += $classclose;
					$classopen = $classperiod = $classclose = 0.0;
					$rep->NewLine(3);
					$closeclass = false;
				}
			}
			if ($account['AccountClassName'] != $classname)
			{
				$rep->Font('bold');
				$rep->TextCol(0, 5, $account['AccountClassName']);
				$rep->Font();
				$rep->row -= ($rep->lineHeight + 4);
			}
			$group = $account['AccountTypeName'];
			$rep->TextCol(0, 5, $account['AccountTypeName']);
			$rep->Line($rep->row - 4);
			$rep->row -= ($rep->lineHeight + 4);
		}
		$classname = $account['AccountClassName'];

		$totalopen += $prev_balance;
		$totalperiod += $curr_balance;
		$totalclose = $totalopen + $totalperiod;
		$classopen += $prev_balance;
		$classperiod += $curr_balance;
		$classclose = $classopen + $classperiod;
		$rep->TextCol(0, 1,	$account['account_code']);
		$rep->TextCol(1, 2,	$account['account_name']);

		$rep->TextCol(2, 3,	number_format2($prev_balance, $dec));
		$rep->TextCol(3, 4,	number_format2($curr_balance, $dec));
		$rep->TextCol(4, 5,	number_format2($curr_balance + $prev_balance, $dec));

		$rep->NewLine();

		if ($rep->row < $rep->bottomMargin + 3 * $rep->lineHeight)
		{
			$rep->Line($rep->row - 2);
			$rep->Header();
		}
	}
	if ($account['AccountClassName'] != $classname)
	{
		if ($classname != '')
		{
			$closeclass = true;
		}
	}
	if ($account['AccountTypeName'] != $group)
	{
		if ($group != '')
		{
			$rep->Line($rep->row + 6);
			$rep->row -= 6;
			$rep->TextCol(0, 2,	tr('Total') . " " . $group);
			$rep->TextCol(2, 3,	number_format2($totalopen, $dec));
			$rep->TextCol(3, 4,	number_format2($totalperiod, $dec));
			$rep->TextCol(4, 5,	number_format2($totalclose, $dec));
			if ($graphics)
			{
				$pg->x[] = $group;
				$pg->y[] = abs($totalclose);
			}
			$rep->row -= ($rep->lineHeight + 4);
			if ($closeclass)
			{
				$rep->Line($rep->row + 6);
				$calculateopen = -$assetsopen - $classopen;
				$calculateperiod = -$assetsperiod - $classperiod;
				$calculateclose = -$assetsclose  - $classclose;
				$rep->row -= 6;

				$rep->TextCol(0, 2,	tr('Calculated Return'));
				$rep->TextCol(2, 3,	number_format2($calculateopen, $dec));
				$rep->TextCol(3, 4,	number_format2($calculateperiod, $dec));
				$rep->TextCol(4, 5,	number_format2($calculateclose, $dec));
				if ($graphics)
				{
					$pg->x[] = tr('Calculated Return');
					$pg->y[] = abs($calculateclose);
				}
				$rep->row -= ($rep->lineHeight + 4);

				$rep->Font('bold');
				$rep->TextCol(0, 2,	tr('Total') . " " . $classname);
				$rep->TextCol(2, 3,	number_format2(-$assetsopen, $dec));
				$rep->TextCol(3, 4,	number_format2(-$assetsperiod, $dec));
				$rep->TextCol(4, 5,	number_format2(-$assetsclose, $dec));
				$rep->Font();
				$rep->NewLine();
			}
		}
	}
	$rep->Line($rep->row);
	if ($graphics)
	{
		global $decseps, $graph_skin;
		$pg->title     = $rep->title;
		$pg->axis_x    = tr("Group");
		$pg->axis_y    = tr("Amount");
		$pg->graphic_1 = $to;
		$pg->type      = $graphics;
		$pg->skin      = $graph_skin;
		$pg->built_in  = false;
		$pg->fontfile  = $path_to_root . "reporting/fonts/Vera.ttf";
		$pg->latin_notation = ($decseps[$_SESSION["wa_current_user"]->prefs->dec_sep()] != ".");
		$filename =  $comp_path.'/'.user_company()."/pdf_files/test.png";
		$pg->display($filename, true);
		$w = $pg->width / 1.5;
		$h = $pg->height / 1.5;
		$x = ($rep->pageWidth - $w) / 2;
		$rep->NewLine(2);
		if ($rep->row - $h < $rep->bottomMargin)
			$rep->Header();
		$rep->AddImage($filename, $x, $rep->row - $h, $w, $h);
	}
	$rep->End();
}

?>