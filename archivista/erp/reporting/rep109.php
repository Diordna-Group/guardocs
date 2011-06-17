<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Print Sales Orders
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "sales/includes/sales_db.inc");

//-----------------------------------------------------------------

print_sales_orders();

function print_sales_orders() {
	$from = $_REQUEST['PARAM_0'];
	$to = $_REQUEST['PARAM_1'];
	$currency = $_REQUEST['PARAM_2'];
	$bankaccount = $_REQUEST['PARAM_3'];
	$email = $_REQUEST['PARAM_4'];	
	$quote = $_REQUEST['PARAM_5'];
	$comments = $_REQUEST['PARAM_6'];
	if ($from == null) {
		$from = 0;
	}
	if ($to == null) {
		$to = 0;
  }
	if ($from>0) {
	  printit($from,$to,$currency,$bank,$email,$quote,$commeents,"");
	}
}



function printit($from,$to,$currency,$bank,$email,$quote,$comments,$file) {
	global $path_to_root;
	global $print_as_quote;
	include_once($path_to_root . "reporting/includes/pdf_report.inc");
	$dec = user_price_dec();
	$cols = array(5, 70, 260, 340, 365, 420, 470, 520);

	// $headers in doctext.inc	
	$aligns = array('left',	'left',	'right', 'left', 'right', 'right', 'right');
	
	$params = array('comments' => $comments,
					'bankaccount' => $bankaccount);
	
	$baccount = get_bank_account($params['bankaccount']);
	$cur = get_company_Pref('curr_default');
	if ($quote==1) {
	  $print_as_quote=1;
	}

	if ($email == 0) {
		if ($quote == 1) {
			$rep = new FrontReport(tr("QUOTE"), "QuoteBulk.pdf", user_pagesize());
		} else	{
			$rep = new FrontReport(tr("SALES ORDER"), 
			  "SalesOrderBulk.pdf", user_pagesize());
		}
		$rep->currency = $cur;
		$rep->fontSize = 10;
		$rep->Font();
		$rep->Info($params, $cols, null, $aligns);
	}

	for ($i = $from; $i <= $to; $i++) {
		$myrow = get_sales_order_header($i);
		$branch = get_branch($myrow["branch_code"]);
    $lang = $branch["lang_code"]; // get language from customer
		readstrings($lang);
		$tax_group_id = $branch['tax_group_id'];
		$tax_rate = 0;
		$tax_name = '';
		$msg = "Error retrieving tax values";
		$sql = "select rate from tax_group_items ";
		$sql = $sql . "where tax_group_id=" . $tax_group_id . " limit 1";
		$result1 = db_query($sql, $msg);
		if (db_num_rows($result1) != 0) {
			$myrow1 = db_fetch_row($result1);
			$tax_rate = $myrow1[0];
		}
		$sql = "select name from tax_groups ";
		$sql = $sql . "where id=" . $tax_group_id . " limit 1";
		$result1 = db_query($sql, $msg);
		if (db_num_rows($result1) != 0) {
			$myrow1 = db_fetch_row($result1);
			$tax_name = $myrow1[0];
		}
		$tax_included = 0;

		
		
		if ($email == 1)
		{
			$rep = new FrontReport("", "", user_pagesize());
			$rep->currency = $cur;
			$rep->Font();
			if ($quote == 1)
			{
				$rep->title = tr("QUOTE");
				$rep->filename = "Quote" . $i . ".pdf";
			}
			else
			{
				$rep->title = tr("SALES ORDER");
				$rep->filename = "SalesOrder" . $i . ".pdf";
			}	
			$rep->Info($params, $cols, null, $aligns);
		}
		else {
			$rep->title = ($quote==1 ? tr("QUOTE") : tr("SALES ORDER"));
		}

		$rep->Header2($myrow, $branch, $myrow, $baccount, 9);

		$result = get_sales_order_details($i);
		$SubTotal = 0;
		while ($myrow2=db_fetch($result))
		{
			$Net = round(((1 - $myrow2["discount_percent"]) * $myrow2["unit_price"] * $myrow2["quantity"]), 
			user_price_dec());
			$SubTotal += $Net;
			$DisplayPrice = number_format2($myrow2["unit_price"],$dec,1);
			$DisplayQty = number_format2($myrow2["quantity"],user_qty_dec(),1);
			$DisplayNet = number_format2($Net,$dec,1);
			$DisplayDate = sql2date($myrow2["date_from"],1);
			if ($myrow2["discount_percent"]==0)
				$DisplayDiscount ="";
			else 
				$DisplayDiscount = number_format2($myrow2["discount_percent"]*100,user_percent_dec(),1) . "%";
			$rep->TextCol(0, 1,	$myrow2['stk_code'], -2);
			$rep->TextCol(1, 2,	$DisplayDate . " ".$myrow2['description'], -2);
			$rep->TextCol(2, 3,	$DisplayQty, -2);
			$rep->TextCol(3, 4,	$myrow2['units'], -2);
			$rep->TextCol(4, 5,	$DisplayPrice, -2);
			$rep->TextCol(5, 6,	$DisplayDiscount, -2);
			$rep->TextCol(6, 7,	$DisplayNet, -2);
			$rep->NewLine(1);
			if ($rep->row < $rep->bottomMargin + (15 * $rep->lineHeight)) 
				$rep->Header2($myrow, $branch, $sales_order, $baccount);

		  if ($myrow2['notes'] != "") {
			  $rep->TextColLines(1, 2, $myrow2['notes'], -2);
		  }	

		}

		if ($myrow['comments'] != "")
		{
			$rep->NewLine();
			$rep->TextColLines(1, 5, $myrow['comments'], -2);
		}	


		$DisplaySubTot = number_format2($SubTotal,$dec,1);
		$DisplayFreight = number_format2($myrow["freight_cost"],$dec,1);

		$rep->row = $rep->bottomMargin + (15 * $rep->lineHeight);
		$linetype = true;
		$doctype = 9;
		if ($rep->currency != $myrow['curr_code']) {
			include($path_to_root . "reporting/includes/doctext.inc");			
		}	else 	{
			include($path_to_root . "reporting/includes/doctext.inc");			
		}	

		$amount = $myrow["freight_cost"] + $SubTotal;
    $subtotal3 = number_format2($amount,$dec,1);
		$rep->TextCol(3, 6, $doc_Sub_total, -4);
		$rep->TextCol(6, 7,	$DisplaySubTot, -4);
		$rep->NewLine();
		$rep->TextCol(3, 6, $doc_Shipping, -3);
		$rep->TextCol(6, 7,	$DisplayFreight, -3);
		$rep->NewLine();
		$rep->TextCol(3, 6, $doc_Sub_total, -2);
		$rep->TextCol(6, 7,	$subtotal3, -2);
		$rep->NewLine();
		$amount_tax = ($amount / 100) * $tax_rate;
		if ($rep->currency == 'CHF') {
			$val = $amount_tax;
			$val1 = (floatval((intval(round(($val*20),0)))/20));
			$amount_tax = $val1;
		}
		$amount_tot = $amount + $amount_tax;
		$DisplayTax = number_format2($amount_tax, $dec,1);
		$DisplayTotal = number_format2($amount_tot, $dec,1);
		
		if ($tax_included) {
			$rep->TextCol(3, 7, $doc_Included . " " . $tax_nmae . 
				" (" . $tax_rate . "%) " . $doc_Amount . ":" . $DisplayTax, -2);
		} else {
			$rep->TextCol(3, 6, $tax_name . " (" . $tax_rate . "%)", -2);
			$rep->TextCol(6, 7,	$DisplayTax, -2);
		}
		$rep->NewLine();
		$rep->Font('bold');	
		$rep->TextCol(3, 6, $doc_TOTAL_ORDER_INCL, - 2);
		$rep->TextCol(6, 7,	$DisplayTotal, -2);
		$rep->Font();
		
		if ($email == 1) {
			if ($myrow['contact_email'] == '') {
				$myrow['contact_email'] = $branch['email'];
				$myrow['DebtorName'] = $branch['br_name'];
			}
			$rep->End($file);
		}	
	}
	if ($email == 0) {
		$rep->End($file);
	}
}

?>
