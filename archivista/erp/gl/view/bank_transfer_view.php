<?php

$page_security = 1;
$path_to_root="../..";

include($path_to_root . "/includes/session.inc");

page(tr("View Bank Transfer"), true);

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/gl/includes/gl_db.inc");

if (isset($_GET["trans_no"])){

	$trans_no = $_GET["trans_no"];
}

$result = get_bank_trans(systypes::bank_transfer(), $trans_no);

if (db_num_rows($result) != 2)
	display_db_error("Bank transfer does not contain two records", $sql);

$trans1 = db_fetch($result);
$trans2 = db_fetch($result);

if ($trans1["amount"] < 0) 
{
    $from_trans = $trans1; // from trans is the negative one
    $to_trans = $trans2;
} 
else 
{
	$from_trans = $trans2;
	$to_trans = $trans1;
}

$company_currency = get_company_currency();

$show_currencies = false;
$show_both_amounts = false;

if (($from_trans['bank_curr_code'] != $company_currency) || ($to_trans['bank_curr_code'] != $company_currency))
	$show_currencies = true;

if ($from_trans['bank_curr_code'] != $to_trans['bank_curr_code']) 
{
	$show_currencies = true;
	$show_both_amounts = true;
}

display_heading(systypes::name(systypes::bank_transfer()) . " #$trans_no");

echo "<br>";
start_table("$table_style width=80%");

start_row();
label_cells(tr("From Bank Account"), $from_trans['bank_account_name'], "class='tableheader2'");
if ($show_currencies)
	label_cells(tr("Currency"), $from_trans['bank_curr_code'], "class='tableheader2'");
label_cells(tr("Amount"), number_format2(-$from_trans['amount'], user_price_dec()), "class='tableheader2'", "align=right");
if ($show_currencies)
{
	end_row();
	start_row();
}	
label_cells(tr("To Bank Account"), $to_trans['bank_account_name'], "class='tableheader2'");
if ($show_currencies)
	label_cells(tr("Currency"), $to_trans['bank_curr_code'], "class='tableheader2'");
if ($show_both_amounts)
	label_cells(tr("Amount"), number_format2($to_trans['amount'], user_price_dec()), "class='tableheader2'", "align=right");
end_row();
start_row();
label_cells(tr("Date"), sql2date($from_trans['trans_date']), "class='tableheader2'");
label_cells(tr("Transfer Type"), $from_trans['BankTransType'], "class='tableheader2'");
label_cells(tr("Reference"), $from_trans['ref'], "class='tableheader2'");
end_row();
comments_display_row(systypes::bank_transfer(), $trans_no);

end_table(1);

is_voided_display(systypes::bank_transfer(), $trans_no, tr("This transfer has been voided."));

end_page(true);
?>