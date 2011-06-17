<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Purchase Orders
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
//include_once($path_to_root . "sales/includes/sales_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_po();

//----------------------------------------------------------------------------------------------------
function get_po($order_no)
{
   	$sql = "SELECT purch_orders.*, suppliers.supp_name, 
   		suppliers.curr_code, suppliers.payment_terms, locations.location_name,
   		suppliers.email, suppliers.address 
		FROM purch_orders, suppliers, locations 
		WHERE purch_orders.supplier_id = suppliers.supplier_id
		AND locations.loc_code = into_stock_location 
		AND purch_orders.order_no = " . $order_no;
   	$result = db_query($sql, "The order cannot be retrieved");
    return db_fetch($result);
}

function get_po_details($order_no)
{
	$sql = "SELECT purch_order_details.*, units 
		FROM purch_order_details 
		LEFT JOIN stock_master 
		ON purch_order_details.item_code=stock_master.stock_id 
		WHERE order_no =$order_no ";
	$sql .= " ORDER BY po_detail_item";
	return db_query($sql, "Retreive order Line Items");
}

function print_po()
{
	global $path_to_root;
	
	include_once($path_to_root . "reporting/includes/pdf_report.inc");
	
	$from = $_REQUEST['PARAM_0'];
	$to = $_REQUEST['PARAM_1'];
	$currency = $_REQUEST['PARAM_2'];
	$bankaccount = $_REQUEST['PARAM_3'];
	$email = $_REQUEST['PARAM_4'];	
	$comments = $_REQUEST['PARAM_5'];

	if ($from == null)
		$from = 0;
	if ($to == null)
		$to = 0;
	$dec = user_price_dec();
	
	$cols = array(4, 60, 225, 300, 325, 385, 450, 515);

	// $headers in doctext.inc	
	$aligns = array('left',	'left',	'left', 'left', 'right', 'right', 'right');
	
	$params = array('comments' => $comments,
					'bankaccount' => $bankaccount);
	
	$baccount = get_bank_account($params['bankaccount']);
	$cur = get_company_Pref('curr_default');
	
	if ($email == 0)
	{
		$rep = new FrontReport(tr('PURCHASE ORDER'), "PurchaseOrderBulk.pdf", user_pagesize());
		$rep->currency = $cur;
		$rep->Font();
		$rep->Info($params, $cols, null, $aligns);
	}

	for ($i = $from; $i <= $to; $i++)
	{
		$myrow = get_po($i);

		if ($email == 1)
		{
			$rep = new FrontReport("", "", user_pagesize());
			$rep->currency = $cur;
			$rep->Font();
			$rep->title = tr('PURCHASE ORDER');
			$rep->filename = "PurchaseOrder" . $i . ".pdf";
			$rep->Info($params, $cols, null, $aligns);
		}
		else
			$rep->title = tr('PURCHASE ORDER');
		$rep->Header2($myrow, null, $myrow, $baccount, 8);

		$result = get_po_details($i);
		$SubTotal = 0;
		while ($myrow2=db_fetch($result))
		{
			$Net = round(($myrow2["unit_price"] * $myrow2["quantity_ordered"]),
			  user_price_dec());
			$SubTotal += $Net;
			$DisplayPrice = number_format2($myrow2["unit_price"],$dec);
			$DisplayQty = number_format2($myrow2["quantity_ordered"],user_qty_dec());
			$DisplayNet = number_format2($Net,$dec);
			//$rep->TextCol(0, 1,	$myrow2['item_code'], -2);
			$rep->TextCol(0, 2,	$myrow2['description'], -2);
			$rep->TextCol(2, 3,	$myrow2['delivery_date'], -2);
			$rep->TextCol(3, 4,	$DisplayQty, -2);
			$rep->TextCol(4, 5,	$myrow2['units'], -2);
			$rep->TextCol(5, 6,	$DisplayPrice, -2);
			$rep->TextCol(6, 7,	$DisplayNet, -2);
			$rep->NewLine(1);
			if ($rep->row < $rep->bottomMargin + (15 * $rep->lineHeight)) 
				$rep->Header2($myrow, $branch, $sales_order, $baccount);
		}
		if ($myrow['comments'] != "")
		{
			$rep->NewLine();
			$rep->TextColLines(1, 5, $myrow['comments'], -2);
		}	
		$DisplaySubTot = number_format2($SubTotal,$dec);

		$rep->row = $rep->bottomMargin + (15 * $rep->lineHeight);
		$linetype = true;
		$doctype = 8;
		if ($rep->currency != $myrow['curr_code'])
		{
			include($path_to_root . "reporting/includes/doctext2.inc");			
		}	
		else
		{
			include($path_to_root . "reporting/includes/doctext.inc");			
		}	

		$rep->TextCol(3, 6, $doc_Sub_total, -2);
		$rep->TextCol(6, 7,	$DisplaySubTot, -2);
		$rep->NewLine();
		$DisplayTotal = number_format2($SubTotal, $dec);
		$rep->Font('bold');	
		$rep->TextCol(3, 6, $doc_TOTAL_PO, - 2);
		$rep->TextCol(6, 7,	$DisplayTotal, -2);
		$rep->Font();	
		if ($email == 1)
		{
			$myrow['contact_email'] = $myrow['email'];
			$myrow['DebtorName'] = $myrow['supp_name'];
			$myrow['reference'] = $myrow['order_no'];
			$rep->End($email, $doc_Order_no . " " . $myrow['reference'], $myrow);
		}	
	}
	if ($email == 0)
		$rep->End();
}

?>