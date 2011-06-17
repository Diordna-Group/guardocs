<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Bill Of Material
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_dimension_summary();

function getTransactions($from, $to)
{
	$sql = "SELECT *
		FROM
			dimensions
		WHERE reference >= '$from'
		AND reference <= '$to'
		ORDER BY
			reference";

    return db_query($sql,"No transactions were returned");
}

function getYTD($dim)
{
	$date = Today();
	$date = begin_fiscalyear($date);
	date2sql($date);
	
	$sql = "SELECT SUM(amount) AS Balance
		FROM
			gl_trans
		WHERE (dimension_id = '$dim' OR dimension2_id = '$dim')
		AND tran_date >= '$date'";

    $TransResult = db_query($sql,"No transactions were returned");
	if (db_num_rows($TransResult) == 1)
	{
		$DemandRow = db_fetch_row($TransResult);
		$balance = $DemandRow[0];
	}
	else
		$balance = 0.0;

    return $balance;
}

//----------------------------------------------------------------------------------------------------

function print_dimension_summary()
{
    global $path_to_root;

    include_once($path_to_root . "reporting/includes/pdf_report.inc");

    $fromdim = $_REQUEST['PARAM_0'];
    $todim = $_REQUEST['PARAM_1'];
    $showbal = $_REQUEST['PARAM_2'];
    $comments = $_REQUEST['PARAM_3'];
    

	$cols = array(0, 50, 210, 250, 320, 395, 465,	515);

	$headers = array(tr('Reference'), tr('Name'), tr('Type'), tr('Date'), tr('Due Date'), tr('Closed'), tr('YTD'));

	$aligns = array('left',	'left', 'left',	'left', 'left', 'left', 'right');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Dimension'), 'from' => $fromdim, 'to' => $todim));

    $rep = new FrontReport(tr('Dimension Summary'), "DimensionSummary.pdf", user_pagesize());

    $rep->Font();
    $rep->Info($params, $cols, $headers, $aligns);
    $rep->Header();

	$res = getTransactions($fromdim, $todim);
	while ($trans=db_fetch($res))
	{
		$rep->TextCol(0, 1, $trans['reference']);
		$rep->TextCol(1, 2, $trans['name']);
		$rep->TextCol(2, 3, $trans['type_']);
		$rep->TextCol(3, 4, $trans['date_']);
		$rep->TextCol(4, 5, $trans['due_date']);
		if ($trans['closed'])
			$str = tr('Yes');
		else
			$str = tr('No');
		$rep->TextCol(5, 6, $str);
		if ($showbal)
		{
			$balance = getYTD($trans['id']);
			$rep->TextCol(6, 7, number_format2($balance, 0));
		}	
		$rep->NewLine(1, 2);
	}
	$rep->Line($rep->row);
    $rep->End();
}

?>