<?php

$page_security = 1;
$path_to_root="../..";

include($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/purchasing/includes/purchasing_db.inc");
$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 500);
page(tr("View Payment to Supplier"), true, false, "", $js);

if (isset($_GET["trans_no"]))
{
	$trans_no = $_GET["trans_no"];
}

$receipt = get_supp_trans($trans_no, 22);

$company_currency = get_company_currency();

$show_currencies = false;
$show_both_amounts = false;

if (($receipt['bank_curr_code'] != $company_currency) || ($receipt['SupplierCurrCode'] != $company_currency))
	$show_currencies = true;

if ($receipt['bank_curr_code'] != $receipt['SupplierCurrCode']) 
{
	$show_currencies = true;
	$show_both_amounts = true;
}

echo "<center>";

display_heading(tr("Payment to Supplier") . " #$trans_no");

echo "<br>";
start_table("$table_style2 width=80%");

start_row();
label_cells(tr("To Supplier"), $receipt['supplier_name'], "class='tableheader2'");
label_cells(tr("From Bank Account"), $receipt['bank_account_name'], "class='tableheader2'");
label_cells(tr("Date Paid"), sql2date($receipt['tran_date']), "class='tableheader2'");
end_row();
start_row();
if ($show_currencies)
	label_cells(tr("Payment Currency"), $receipt['bank_curr_code'], "class='tableheader2'");
label_cells(tr("Amount"), number_format2(-$receipt['BankAmount'], user_price_dec()), "class='tableheader2'");
label_cells(tr("Payment Type"), $receipt['BankTransType'], "class='tableheader2'");
end_row();
start_row();
if ($show_currencies) 
{
	label_cells(tr("Supplier's Currency"), $receipt['SupplierCurrCode'], "class='tableheader2'");
}
if ($show_both_amounts)
	label_cells(tr("Amount"), number_format2(-$receipt['ov_amount'], user_price_dec()), "class='tableheader2'");
label_cells(tr("Reference"), $receipt['ref'], "class='tableheader2'");
end_row();
comments_display_row(22, $trans_no);

end_table(1);

$voided = is_voided_display(22, $trans_no, tr("This payment has been voided."));

// now display the allocations for this payment
if (!$voided) 
{
	display_allocations_from(payment_person_types::supplier(), $receipt['supplier_id'], 22, $trans_no, -$receipt['ov_amount']);
}

end_page(true);
?>