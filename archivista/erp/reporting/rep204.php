<?php

$page_security = 2;
// ----------------------------------------------------------------
// $ Revision:	2.0 $
// Creator:	Joe Hunt
// date_:	2005-05-19
// Title:	Outstanding GRNs Report
// ----------------------------------------------------------------
$path_to_root="../";

include_once($path_to_root . "includes/session.inc");
include_once($path_to_root . "includes/date_functions.inc");
include_once($path_to_root . "includes/data_checks.inc");
include_once($path_to_root . "gl/includes/gl_db.inc");

//----------------------------------------------------------------------------------------------------

// trial_inquiry_controls();
print_outstanding_GRN();

function getTransactions($fromsupp)
{
	$sql = "SELECT grn_batch.id,
			order_no,
			grn_batch.supplier_id,
			suppliers.supp_name,
			grn_items.item_code,
			grn_items.description,
			qty_recd,
			quantity_inv,
			std_cost_unit,
			act_price,
			unit_price
		FROM grn_items,
			grn_batch,
			purch_order_details,
			suppliers
		WHERE grn_batch.supplier_id=suppliers.supplier_id
		AND grn_batch.id = grn_items.grn_batch_id
		AND grn_items.po_detail_item = purch_order_details.po_detail_item
		AND qty_recd-quantity_inv <>0 ";
	if ($fromsupp != reserved_words::get_all_numeric())
		$sql .= "AND grn_batch.supplier_id ='" . $fromsupp . "' ";
	$sql .= "ORDER BY grn_batch.supplier_id, 
			grn_batch.id";

    return db_query($sql, "No transactions were returned");
}

//----------------------------------------------------------------------------------------------------

function print_outstanding_GRN()
{
    global $path_to_root;

    include_once($path_to_root . "reporting/includes/pdf_report.inc");

    $fromsupp = $_REQUEST['PARAM_0'];
    $comments = $_REQUEST['PARAM_1'];
    
	if ($fromsupp == reserved_words::get_all_numeric())
		$from = tr('All');
	else
		$from = get_supplier_name($fromsupp);
    $dec = user_price_dec();

	$cols = array(0, 40, 80, 190,	250, 320, 385, 450,	515);

	$headers = array(tr('GRN'), tr('Order'), tr('Item') . '/' . tr('Description'), tr('Qty Recd'), tr('qty Inv'), tr('Balance'),
		tr('Std Cost'), tr('Value'));

	$aligns = array('left',	'left',	'left',	'right', 'right', 'right', 'right', 'right');

    $params =   array( 	0 => $comments,
    				    1 => array('text' => tr('Supplier'), 'from' => $from, 'to' => ''));

    $rep = new FrontReport(tr('Outstanding GRNs Report'), "OutstandingGRN.pdf", user_pagesize());

    $rep->Font();
    $rep->Info($params, $cols, $headers, $aligns);
    $rep->Header();

	$Tot_Val=0;
	$Supplier = '';
	$SuppTot_Val=0;
	$res = getTransactions($fromsupp);
	
	While ($GRNs = db_fetch($res))
	{	
		if ($Supplier != $GRNs['supplier_id'])
		{
			if ($Supplier != '')
			{
				$rep->NewLine(2);
				$rep->TextCol(0, 7, tr('Total'));
				$rep->TextCol(7, 8, number_format2($SuppTot_Val, $dec));
				$rep->Line($rep->row - 2);
				$rep->NewLine(3);
				$SuppTot_Val = 0;
			}
			$rep->TextCol(0, 6, $GRNs['supp_name']);
			$Supplier = $GRNs['supplier_id'];
		}
		$rep->NewLine();
		$rep->TextCol(0, 1, $GRNs['id']);
		$rep->TextCol(1, 2, $GRNs['order_no']);
		$rep->TextCol(2, 3, $GRNs['item_code'] . '-' . $GRNs['description']);
		$rep->TextCol(3, 4, number_format2($GRNs['qty_recd'], $dec));
		$rep->TextCol(4, 5, number_format2($GRNs['quantity_inv'], $dec));
		$QtyOstg = $GRNs['qty_recd'] - $GRNs['quantity_inv'];
		$Value = ($GRNs['qty_recd'] - $GRNs['quantity_inv']) * $GRNs['std_cost_unit'];
		$rep->TextCol(5, 6, number_format2($QtyOstg, $dec));
		$rep->TextCol(6, 7, number_format2($GRNs['std_cost_unit'], $dec));
		$rep->TextCol(7, 8, number_format2($Value, $dec));
		$Tot_Val += $Value;
		$SuppTot_Val += $Value;

		$rep->NewLine(0, 1);
	}
	if ($Supplier != '')
	{
		$rep->NewLine();
		$rep->TextCol(0, 7, tr('Total'));
		$rep->TextCol(7, 8, number_format2($SuppTot_Val, $dec));
		$rep->Line($rep->row - 2);
		$rep->NewLine(3);
		$SuppTot_Val = 0;
	}
	$rep->NewLine(2);
	$rep->TextCol(0, 7, tr('Grand Total'));
	$rep->TextCol(7, 8, number_format2($Tot_Val, $dec));
	$rep->Line($rep->row - 2);
    $rep->End();
}

?>