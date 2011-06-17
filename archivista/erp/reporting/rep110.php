<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Janusz Dobrwolski
// date_:	2008-01-14
// Title:	Print Delivery Notes
// draft version!
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "sales/includes/sales_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_deliveries();

//----------------------------------------------------------------------------------------------------

function print_deliveries()
{
	global $path_to_root;
	
	include_once($path_to_root . "reporting/includes/pdf_report.inc");
	
	$from = $_REQUEST['PARAM_0'];
	$to = $_REQUEST['PARAM_1'];
	$email = $_REQUEST['PARAM_2'];	
	$comments = $_REQUEST['PARAM_3'];

	if ($from == null)
		$from = 0;
	if ($to == null)
		$to = 0;
	$dec = user_price_dec();
	
	$fno = explode("-", $from);
	$tno = explode("-", $to);

	$cols = array(5, 70, 260, 340, 365, 420, 470, 520);

	// $headers in doctext.inc	
	$aligns = array('left',	'left',	'right', 'left', 'right', 'right', 'right');
	
	$params = array('comments' => $comments);
	
	$cur = get_company_Pref('curr_default');
	
	if ($email == 0)
	{
		$rep = new FrontReport(tr('DELIVERY'), "DeliveryNoteBulk.pdf", user_pagesize());
		$rep->currency = $cur;
	  $rep->fontSize = 10;
		$rep->Font();
		$rep->Info($params, $cols, null, $aligns);
	}

	for ($i = $fno[0]; $i <= $tno[0]; $i++)
	{
			if (!exists_customer_trans(13, $i))
				continue;
			$myrow = get_customer_trans($i, 13);

		$sales_order = get_sales_order_header($myrow["order_"]); // ?
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
					$rep->title = tr('DELIVERY NOTE');
					$rep->filename = "Delivery" . $myrow['reference'] . ".pdf";
				$rep->Info($params, $cols, null, $aligns);
			}
			else
				$rep->title = tr('DELIVERY NOTE');
			$rep->Header2($myrow, $branch, $sales_order, '', 13);
			
   		$result = get_customer_trans_details(13, $i);
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
				$rep->TextCol(0, 1,	$myrow2['stock_id'], -2);
			  $rep->TextCol(1, 2,	$DisplayDate . " ".$myrow2['description'], -2);
				$rep->TextCol(2, 3,	$DisplayQty, -2);
				$rep->TextCol(3, 4,	$myrow2['units'], -2);
				$rep->TextCol(4, 5,	$DisplayPrice, -2);
				$rep->TextCol(5, 6,	$DisplayDiscount, -2);
				$rep->TextCol(6, 7,	$DisplayNet, -2);
				$rep->NewLine(1);
				if ($rep->row < $rep->bottomMargin + (15 * $rep->lineHeight)) 
					$rep->Header2($myrow, $branch, $sales_order,'',13);
			}
			
			$comments = get_comments(13, $i);
			if ($comments && db_num_rows($comments))
			{ 	
				$rep->NewLine();
    			while ($comment=db_fetch($comments)) 
    				$rep->TextColLines(0, 6, $comment['memo_'], -2);
			}	
				
   			$DisplaySubTot = number_format2($SubTotal,$dec,1);
   			$DisplayFreight = number_format2($myrow["ov_freight"],$dec,1);

    		$rep->row = $rep->bottomMargin + (15 * $rep->lineHeight);
			$linetype = true;
			$doctype=13;
			if ($rep->currency != $myrow['curr_code'])
			{
				include($path_to_root . "reporting/includes/doctext.inc");			
			}	
			else
			{
				include($path_to_root . "reporting/includes/doctext.inc");			
			}	
    		
			$amount = $myrow["ov_freight"] + $SubTotal;
      $subtotal3 = number_format2($amount,$dec,1);
			$rep->TextCol(3, 6, $doc_Sub_total, -2);
			$rep->TextCol(6, 7,	$DisplaySubTot, -2);
			$rep->NewLine();
			$rep->TextCol(3, 6, $doc_Shipping, -2);
			$rep->TextCol(6, 7,	$DisplayFreight, -2);
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
		$rep->TextCol(3, 6, $doc_TOTAL_DELIVERY, - 2);
		$rep->TextCol(6, 7,	$DisplayTotal, -2);
		$rep->Font();








/*
			$tax_items = get_customer_trans_tax_details(13, $i);
    		while ($tax_item = db_fetch($tax_items)) 
    		{
    			$DisplayTax = number_format2($tax_item['amount'], $dec,1);
    			if ($tax_item['included_in_price'])
    			{
					$rep->TextCol(3, 7, $doc_Included . " " . $tax_item['tax_type_name'] . 
						" (" . $tax_item['rate'] . "%) " . $doc_Amount . ":" . $DisplayTax, -2);
				}		
    			else
    			{
					$rep->TextCol(3, 6, $tax_item['tax_type_name'] . " (" . 
						$tax_item['rate'] . "%)", -2);
					$rep->TextCol(6, 7,	$DisplayTax, -2);
				}    			
				$rep->NewLine();
    		}
    		//$rep->NewLine();
			$DisplayTotal = number_format2($myrow["ov_freight"] +$myrow["ov_freight_tax"] + $myrow["ov_gst"] +
				$myrow["ov_amount"],$dec,1);
			$rep->Font('bold');	
			$rep->TextCol(3, 6, $doc_TOTAL_DELIVERY, - 2); 
			$rep->TextCol(6, 7,	$DisplayTotal, -2);
			$rep->Font();	

*/

			if ($email == 1)
			{
				$myrow['dimension_id'] = $paylink; // helper for pmt link
				if ($myrow['email'] == '')
				{
					$myrow['email'] = $branch['email'];
					$myrow['DebtorName'] = $branch['br_name'];
				}
				$rep->End($email, $doc_Delivery_no . " " . $myrow['reference'], $myrow, 13);
			}	
	}
	if ($email == 0)
		$rep->End();
}

?>
