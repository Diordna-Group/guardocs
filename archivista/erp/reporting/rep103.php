<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Customer Details Listing
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_customer_details_listing();

function get_customer_details_for_report($area=0, $salesid=0) 
{
	$sql = "SELECT debtors_master.debtor_no,
			debtors_master.name,
			debtors_master.address,
			sales_types.sales_type,
			cust_branch.branch_code,
			cust_branch.br_name,
			cust_branch.br_address,
			cust_branch.contact_name,
			cust_branch.phone,
			cust_branch.fax,
			cust_branch.email,
			cust_branch.area,
			cust_branch.salesman,
			areas.description,
			salesman.salesman_name
		FROM debtors_master 
		INNER JOIN cust_branch
			ON debtors_master.debtor_no=cust_branch.debtor_no
		INNER JOIN sales_types
			ON debtors_master.sales_type=sales_types.id
		INNER JOIN areas
			ON cust_branch.area = areas.area_code
		INNER JOIN salesman
			ON cust_branch.salesman=salesman.salesman_code";
	if ($area != 0)
	{
		if ($salesid != 0)
			$sql .= " WHERE salesman.salesman_code='$salesid' 
				AND areas.area_code='$area'";
		else		
			$sql .= " WHERE areas.area_code='$area'";
	}
	elseif ($salesid != 0)
		$sql .= " WHERE salesman.salesman_code='$salesid'";
	$sql .= " ORDER BY description,
			salesman.salesman_name,
			debtors_master.debtor_no,
			cust_branch.branch_code";
					
    return db_query($sql,"No transactions were returned");
}

					
function getTransactions($debtorno, $branchcode, $date)
{
	$date = date2sql($date);

	$sql = "SELECT SUM((ov_amount+ov_freight+ov_discount)*rate) AS Turnover
		FROM debtor_trans
		WHERE debtor_no='$debtorno'
		AND branch_code='$branchcode'
		AND (type=10 or type=11)
		AND trandate >='$date'";
		
    $result = db_query($sql,"No transactions were returned");

	$row = db_fetch_row($result);
	return $row[0];
}

//----------------------------------------------------------------------------------------------------

function print_customer_details_listing()
{
    global $path_to_root;

    include_once($path_to_root . "reporting/includes/pdf_report.inc");

    $from = $_REQUEST['PARAM_0'];
    $area = $_REQUEST['PARAM_1'];
    $folk = $_REQUEST['PARAM_2'];
    $more = $_REQUEST['PARAM_3'];
    $less = $_REQUEST['PARAM_4'];
    $comments = $_REQUEST['PARAM_5'];
    
    $dec = 0;

	if ($area == reserved_words::get_all_numeric())
		$area = 0;
	if ($folk == reserved_words::get_all_numeric())
		$folk = 0;

	if ($area == 0)
		$sarea = tr('All Areas');
	else
		$sarea = get_area_name($area);
	if ($folk == 0)
		$salesfolk = tr('All Sales Folk');
	else
		$salesfolk = get_salesman_name($folk);
	if ($more != '')
		$morestr = tr('Greater than ') . number_format2($more, $dec);
	else
		$morestr = '';
	if ($less != '')
		$lessstr = tr('Less than ') . number_format2($less, $dec);
	else
		$lessstr = '';
	
	$more = (double)$more;	
	$less = (double)$less;

	$cols = array(0, 150, 300, 400, 550);

	$headers = array(tr('Customer Postal Address'), tr('Price/Turnover'),	tr('Branch Contact Information'),
		tr('Branch Delivery Address'));

	$aligns = array('left',	'left',	'left',	'left');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Activity Since'), 	'from' => $from, 		'to' => ''),
    				    2 => array('text' => tr('Sales Areas'), 		'from' => $sarea, 		'to' => ''),
    				    3 => array('text' => tr('Sales Folk'), 		'from' => $salesfolk, 	'to' => ''),
    				    4 => array('text' => tr('Activity'), 		'from' => $morestr, 	'to' => $lessstr));

    $rep = new FrontReport(tr('Customer Details Listing'), "CustomerDetailsListing.pdf", user_pagesize());

    $rep->Font();
    $rep->Info($params, $cols, $headers, $aligns);
    $rep->Header();

	$result = get_customer_details_for_report($area, $folk);
	
	$carea = '';
	$sman = '';
	while ($myrow=db_fetch($result)) 
	{
		$printcustomer = true;
		if ($more != '' || $less != '')
		{
			$turnover = getTransactions($myrow['debtor_no'], $myrow['branch_code'], $from);
			if ($more != 0.0 && $turnover <= (double)$more)
				$printcustomer = false;
			if ($less != 0.0 && $turnover >= (double)$less)
				$printcustomer = false;
		}	
		if ($printcustomer)
		{
			if ($carea != $myrow['description'])
			{
				$rep->fontSize += 2;
				$rep->NewLine(2, 7);
				$rep->Font('bold');	
				$rep->TextCol(0, 3,	tr('Customers in') . " " . $myrow['description']);
				$carea = $myrow['description'];
				$rep->fontSize -= 2;
				$rep->Font();
				$rep->NewLine();
			}	
			if ($sman != $myrow['salesman_name'])
			{
				$rep->fontSize += 2;
				$rep->NewLine(1, 7);
				$rep->Font('bold');	
				$rep->TextCol(0, 3,	$myrow['salesman_name']);
				$sman = $myrow['salesman_name'];
				$rep->fontSize -= 2;
				$rep->Font();
				$rep->NewLine();
			}
			$rep->NewLine();
			$rep->TextCol(0, 1,	$myrow['name']);
			$adr = Explode("\n", $myrow['address']);
			$count1 = count($adr);
			for ($i = 0; $i < $count1; $i++)
				$rep->TextCol(0, 1, $adr[$i], 0, ($i + 1) * $rep->lineHeight);
			$count1++;		
			$rep->TextCol(1, 2,	tr('Price List') . ": " . $myrow['sales_type']);
			if ($more != 0.0 || $less != 0.0)
				$rep->TextCol(1, 2,	tr('Turnover') . ": " . number_format2($turnover, $dec), 0, $rep->lineHeight);
			$rep->TextCol(2, 3,	$myrow['br_name']);
			$rep->TextCol(2, 3, $myrow['contact_name'], 0, $rep->lineHeight);
			$rep->TextCol(2, 3, tr('Ph') . ": " . $myrow['phone'], 0, 2 * $rep->lineHeight);
			$rep->TextCol(2, 3, tr('Fax') . ": " . $myrow['fax'], 0, 3 * $rep->lineHeight);
			$adr = Explode("\n", $myrow['br_address']);
			$count2 = count($adr);
			for ($i = 0; $i < $count2; $i++)
				$rep->TextCol(3, 4, $adr[$i], 0, ($i + 1) * $rep->lineHeight);
			$rep->TextCol(3, 4, $myrow['email'], 0, ($count2 + 1) * $rep->lineHeight);
			$count2++;
			$count1 = Max($count1, $count2);
			$count1 = Max($count1, 4);
			$rep->NewLine($count1); 
			$rep->Line($rep->row + 8);
			$rep->NewLine(0, 3);
		}
	}
    $rep->End();
}

?>