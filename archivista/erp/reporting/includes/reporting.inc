<?php

// Put this on the page only once an outside a form, e.g. print_hidden_script(systypes::sales_order());
// If you have both invoices and credit notes on the same page use 10 or 11. Is doesn't matter which.

function print_hidden_script($type_no) { } # not any longer used

// Ex. label_cell(print_document_link($myrow['order_no'], tr("Print")));
// or display_note(print_document_link($order_no, tr("Print this order")));
// or if a button
// button("button", tr("Print this order"), print_document_link($order_no, "", false))";
// or if a button inside a TD
// button_cell("button", tr("Print this order"), print_document_link($order_no, "", false))";
//
// You only need full parameter list for invoices/credit notes

function print_document_link($doc_no, $link_text, $link=true, $type_no=0,$type_opt=0) {
	global $path_to_root;
	include_once($path_to_root . "/includes/types.inc");
	$action = "";
	switch ($type_no) {
		case systypes::sales_order() :
			$action = "$path_to_root/reporting/rep109.php";
			$ar = array(
				'PARAM_0' => $doc_no,		// from - these values are updated in print_document_link()
				'PARAM_1' => $doc_no, 	// to
				'PARAM_2' => "", 	// currency
				'PARAM_3' => get_first_bank_account(), 	// bank account
				'PARAM_4' => 0, 	// email
				'PARAM_5' => $type_opt, 	// quote
				'PARAM_6' => ""); 	// comments
			break;
		case systypes::cust_dispatch() :
			$action = "$path_to_root/reporting/rep110.php";
			$ar = array(
				'PARAM_0' => $doc_no,		// from - these values are updated in print_document_link()
				'PARAM_1' => $doc_no, 	// to
				'PARAM_2' => 0, 	// email
				'PARAM_3' => ""); 	// comments
			break;
		case 10 : // Sales Invoice
		case 11 : // Customer Credit Note
			$action = "$path_to_root/reporting/rep107.php";
			$ar = array(
				'PARAM_0' => $doc_no,		// from - these values are updated in print_document_link()
				'PARAM_1' => $doc_no, 	// to
				'PARAM_2' => "", 	// currency
				'PARAM_3' => get_first_bank_account(), 	// bank account
				'PARAM_4' => 0, 	// email
				'PARAM_5' => "", 	// paylink
				'PARAM_6' => "", 	// comments
				'PARAM_7' => $type_no); 	// IV or CN
			break;
		case systypes::po() :
			$action = "$path_to_root/reporting/rep209.php";
			$ar = array(
				'PARAM_0' => $doc_no,		// from - these values are updated in print_document_link()
				'PARAM_1' => $doc_no, 	// to
				'PARAM_2' => "", 	// currency
				'PARAM_3' => get_first_bank_account(), 	// bank account
				'PARAM_4' => 0, 	// email
				'PARAM_5' => ""); 	// comments
			break;
	}
	$par = "";
	foreach ($ar as $key => $value) {
	  if ($par != "") {
	    $par .= "&";
		}
		$par .= "$key=$value";
	}
	$cmd = "$action?$par";
	$all = "<a href='$cmd' target='_blank'>$link_text</a>";
	return $all;
}




function get_first_bank_account()
{
	$sql = "SELECT bank_accounts.account_code FROM bank_accounts, company
		WHERE bank_curr_code=curr_default LIMIT 0, 1";
	$result = db_query($sql);
	$row = db_fetch_row($result);
	return $row[0];
}
?>
