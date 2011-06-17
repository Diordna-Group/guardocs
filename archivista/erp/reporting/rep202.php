<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Ages Supplier Analysis
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_aged_supplier_analysis();

//----------------------------------------------------------------------------------------------------

function get_invoices($supplier_id, $to)
{
	$todate = date2sql($to);
	$PastDueDays1 = get_company_pref('past_due_days');
	$PastDueDays2 = 2 * $PastDueDays1;

	// Revomed allocated from sql
	$sql = "SELECT sys_types.type_name, 
			supp_trans.reference, 
			supp_trans.tran_date, 
			(supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount) as Balance,
			IF (payment_terms.days_before_due > 0,
				CASE WHEN TO_DAYS('$todate') - TO_DAYS(supp_trans.tran_date) >= payment_terms.days_before_due 
				THEN 
					supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount 
				ELSE
					0 
				END,
				
				CASE WHEN TO_DAYS('$todate') - TO_DAYS(DATE_ADD(DATE_ADD(supp_trans.tran_date, 
					INTERVAL 1 MONTH), INTERVAL (payment_terms.day_in_following_month - 
					DAYOFMONTH(supp_trans.tran_date)) DAY)) >= 0 
				THEN 
					supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount 
				ELSE 
					0 
				END
			) AS Due,
			IF (payment_terms.days_before_due > 0,
				CASE WHEN TO_DAYS('$todate') - TO_DAYS(supp_trans.tran_date) > payment_terms.days_before_due 
					AND TO_DAYS('$todate') - TO_DAYS(supp_trans.tran_date) >= (payment_terms.days_before_due + $PastDueDays1) 
				THEN 
					supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount 
				ELSE 
					0 
				END,

				CASE WHEN TO_DAYS('$todate') - TO_DAYS(DATE_ADD(DATE_ADD(supp_trans.tran_date, 
					INTERVAL 1 MONTH), INTERVAL (payment_terms.day_in_following_month - 
					DAYOFMONTH(supp_trans.tran_date)) DAY)) >= $PastDueDays1 
				THEN 
					supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount 
				ELSE 
					0 
				END
			) AS Overdue1,
			IF (payment_terms.days_before_due > 0,
				CASE WHEN TO_DAYS('$todate') - TO_DAYS(supp_trans.tran_date) > payment_terms.days_before_due 
					AND TO_DAYS('$todate') - TO_DAYS(supp_trans.tran_date) >= (payment_terms.days_before_due + $PastDueDays2) 
				THEN 
					supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount 
				ELSE 
					0 
				END,

				CASE WHEN TO_DAYS('$todate') - TO_DAYS(DATE_ADD(DATE_ADD(supp_trans.tran_date,
					INTERVAL 1 MONTH), INTERVAL (payment_terms.day_in_following_month - 
					DAYOFMONTH(supp_trans.tran_date)) DAY)) >= $PastDueDays2 
				THEN 
					supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount 
				ELSE 
					0 
				END
			) AS Overdue2
	   
	   		FROM suppliers, 
				payment_terms, 
				supp_trans, 
				sys_types
	   
	   		WHERE sys_types.type_id = supp_trans.type 
				AND suppliers.payment_terms = payment_terms.terms_indicator 
				AND suppliers.supplier_id = supp_trans.supplier_id
				AND supp_trans.supplier_id = $supplier_id 
				AND supp_trans.tran_date <= '$todate' 
				AND ABS(supp_trans.ov_amount + supp_trans.ov_gst + supp_trans.ov_discount) > 0.004
				ORDER BY supp_trans.tran_date";


	return db_query($sql, "The supplier details could not be retrieved");
}

//----------------------------------------------------------------------------------------------------

function print_aged_supplier_analysis()
{
    global $comp_path, $path_to_root;

    include_once($path_to_root . "reporting/includes/pdf_report.inc");

    $to = $_REQUEST['PARAM_0'];
    $fromsupp = $_REQUEST['PARAM_1'];
    $currency = $_REQUEST['PARAM_2'];
	$summaryOnly = $_REQUEST['PARAM_3'];
    $graphics = $_REQUEST['PARAM_4'];
    $comments = $_REQUEST['PARAM_5'];
	if ($graphics)
	{
		include_once($path_to_root . "reporting/includes/class.graphic.inc");
		$pg = new graph();
	}	
    
	if ($fromsupp == reserved_words::get_all_numeric())
		$from = tr('All');
	else
		$from = get_supplier_name($fromsupp);
    $dec = user_price_dec();

	if ($summaryOnly == 1)
		$summary = tr('Summary Only');
	else
		$summary = tr('Detailed Report');
	if ($currency == reserved_words::get_all())
	{
		$convert = true;
		$currency = tr('Balances in Home Currency');
	}
	else
		$convert = false;
	$PastDueDays1 = get_company_pref('past_due_days');
	$PastDueDays2 = 2 * $PastDueDays1;
	$nowdue = "1-" . $PastDueDays1 . " " . tr('Days');
	$pastdue1 = $PastDueDays1 + 1 . "-" . $PastDueDays2 . " " . tr('Days');
	$pastdue2 = tr('Over') . " " . $PastDueDays2 . " " . tr('Days');

	$cols = array(0, 100, 130, 190,	250, 320, 385, 450,	515);

	$headers = array(tr('Supplier'),	'',	'',	tr('Current'), $nowdue, $pastdue1,$pastdue2,
		tr('Total Balance'));
	
	$aligns = array('left',	'left',	'left',	'right', 'right', 'right', 'right',	'right');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('End Date'), 'from' => $to, 'to' => ''),
    				    2 => array('text' => tr('Supplier'), 'from' => $from, 'to' => ''),
    				    3 => array('text' => tr('Currency'),'from' => $currency,'to' => ''),
                    	4 => array('text' => tr('Type'), 'from' => $summary,'to' => ''));

	if ($convert)
		$headers[2] = tr('currency');
    $rep = new FrontReport(tr('Aged Supplier Analysis'), "AgedSupplierAnalysis.pdf", user_pagesize());

    $rep->Font();
    $rep->Info($params, $cols, $headers, $aligns);
    $rep->Header();

	$total = array();
	$total[0] = $total[1] = $total[2] = $total[3] = $total[4] = 0.0;
	$PastDueDays1 = get_company_pref('past_due_days');
	$PastDueDays2 = 2 * $PastDueDays1;

	$nowdue = "1-" . $PastDueDays1 . " " . tr('Days');
	$pastdue1 = $PastDueDays1 + 1 . "-" . $PastDueDays2 . " " . tr('Days');
	$pastdue2 = tr('Over') . " " . $PastDueDays2 . " " . tr('Days');
	
	$sql = "SELECT supplier_id, supp_name AS name, curr_code FROM suppliers ";
	if ($fromsupp != reserved_words::get_all_numeric())
		$sql .= "WHERE supplier_id=$fromsupp ";
	$sql .= "ORDER BY supp_name";
	$result = db_query($sql, "The suppliers could not be retrieved");
	
	while ($myrow=db_fetch($result)) 
	{
		if (!$convert && $currency != $myrow['curr_code'])
			continue;
		$rep->fontSize += 2;
		$rep->TextCol(0, 3,	$myrow['name']);
		if ($convert)
		{
			$rate = get_exchange_rate_from_home_currency($myrow['curr_code'], $to);
			$rep->TextCol(2, 4,	$myrow['curr_code']);
		}
		else
			$rate = 1.0;
		$rep->fontSize -= 2;
		$supprec = get_supplier_details($myrow['supplier_id'], $to);
		foreach ($supprec as $i => $value) 
			$supprec[$i] *= $rate;
		$total[0] += ($supprec["Balance"] - $supprec["Due"]);
		$total[1] += ($supprec["Due"]-$supprec["Overdue1"]);
		$total[2] += ($supprec["Overdue1"]-$supprec["Overdue2"]);
		$total[3] += $supprec["Overdue2"];
		$total[4] += $supprec["Balance"];
		$str = array(number_format2(($supprec["Balance"] - $supprec["Due"]),$dec),
			number_format2(($supprec["Due"]-$supprec["Overdue1"]),$dec),
			number_format2(($supprec["Overdue1"]-$supprec["Overdue2"]) ,$dec),
			number_format2($supprec["Overdue2"],$dec),
			number_format2($supprec["Balance"],$dec));
		for ($i = 0; $i < count($str); $i++)
			$rep->TextCol($i + 3, $i + 4, $str[$i]);
		$rep->NewLine(1, 2);	
		if (!$summaryOnly)
		{
			$res = get_invoices($myrow['supplier_id'], $to);
    		if (db_num_rows($res)==0)
				continue;
    		$rep->Line($rep->row + 4);
			while ($trans=db_fetch($res))
			{
				$rep->NewLine(1, 2);
        		$rep->TextCol(0, 1,	$trans['type_name'], -2);
				$rep->TextCol(1, 2,	$trans['reference'], -2);
				$rep->TextCol(2, 3,	sql2date($trans['tran_date']), -2);
				foreach ($trans as $i => $value) 
					$trans[$i] *= $rate;
				$str = array(number_format2(($trans["Balance"] - $trans["Due"]),$dec),
					number_format2(($trans["Due"]-$trans["Overdue1"]),$dec),
					number_format2(($trans["Overdue1"]-$trans["Overdue2"]) ,$dec),
					number_format2($trans["Overdue2"],$dec),
					number_format2($trans["Balance"],$dec));
				for ($i = 0; $i < count($str); $i++)
					$rep->TextCol($i + 3, $i + 4, $str[$i]);
			}					
			$rep->Line($rep->row - 8);
			$rep->NewLine(2);
		}	
	}
	if ($summaryOnly)
	{
    	$rep->Line($rep->row  + 4);
    	$rep->NewLine();
	}
	$rep->fontSize += 2;
	$rep->TextCol(0, 3,	tr('Grand Total'));
	$rep->fontSize -= 2;
	for ($i = 0; $i < count($total); $i++)
	{
		$rep->TextCol($i + 3, $i + 4, number_format2($total[$i], $dec));
		if ($graphics && $i < count($total) - 1)
		{
			$pg->y[$i] = abs($total[$i]);
		}	
	}	
   	$rep->Line($rep->row  - 8);
   	if ($graphics)
   	{
   		global $decseps, $graph_skin;
		$pg->x = array(tr('Current'), $nowdue, $pastdue1, $pastdue2);
		$pg->title     = $rep->title;
		$pg->axis_x    = tr("Days");
		$pg->axis_y    = tr("Amount");
		$pg->graphic_1 = $to;
		$pg->type      = $graphics;
		$pg->skin      = $graph_skin;
		$pg->built_in  = false;
		$pg->fontfile  = $path_to_root . "reporting/fonts/Vera.ttf";
		$pg->latin_notation = ($decseps[$_SESSION["wa_current_user"]->prefs->dec_sep()] != ".");
		$filename = $comp_path.'/'.user_company(). "/pdf_files/test.png";
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
