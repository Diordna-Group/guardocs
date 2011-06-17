<?php

$page_security = 1;
$path_to_root="../..";

include($path_to_root . "/includes/session.inc");

page(tr("View Bank Payment"), true);

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");

include_once($path_to_root . "/gl/includes/gl_db.inc");

if (isset($_GET["trans_no"]))
{
	$trans_no = $_GET["trans_no"];
}

// get the pay-from bank payment info
$result = get_bank_trans(systypes::bank_payment(), $trans_no);

if (db_num_rows($result) != 1)
	display_db_error("duplicate payment bank transaction found", "");

$from_trans = db_fetch($result);

$company_currency = get_company_currency();

$show_currencies = false;

if ($from_trans['bank_curr_code'] != $company_currency) 
{
	$show_currencies = true;
}

display_heading(tr("GL Payment") . " #$trans_no");

echo "<br>";
start_table("$table_style width=80%");

if ($show_currencies)
{
	$colspan1 = 5;
	$colspan2 = 8;
}
else
{
	$colspan1 = 3;
	$colspan2 = 6;
}
start_row();
label_cells(tr("From Bank Account"), $from_trans['bank_account_name'], "class='tableheader2'");
if ($show_currencies)
	label_cells(tr("Currency"), $from_trans['bank_curr_code'], "class='tableheader2'");
label_cells(tr("Amount"), number_format2(-$from_trans['amount'], user_price_dec()), "class='tableheader2'", "align=right");
label_cells(tr("Date"), sql2date($from_trans['trans_date']), "class='tableheader2'");
end_row();
start_row();
label_cells(tr("Pay To"), payment_person_types::person_name($from_trans['person_type_id'], $from_trans['person_id']), "class='tableheader2'", "colspan=$colspan1");
label_cells(tr("Payment Type"), $from_trans['BankTransType'], "class='tableheader2'");
end_row();
start_row();
label_cells(tr("Reference"), $from_trans['ref'], "class='tableheader2'", "colspan=$colspan2");
end_row();
comments_display_row(systypes::bank_payment(), $trans_no);

end_table(1);

$voided = is_voided_display(systypes::bank_payment(), $trans_no, tr("This payment has been voided."));

$items = get_gl_trans(systypes::bank_payment(), $trans_no);

if (db_num_rows($items)==0)
{
	echo "<br>" . tr("There are no items for this payment.");
} 
else 
{

	display_heading2(tr("Items for this Payment"));
	if ($show_currencies)
		display_heading2(tr("Item Amounts are Shown in :") . " " . $company_currency);

    echo "<br>";
    start_table("$table_style width=80%");
    $th = array(tr("Account Code"), tr("Account Description"),
    	tr("Amount"), tr("Memo"));
	table_header($th);

    $k = 0; //row colour counter
	$totalAmount = 0;

    while ($item = db_fetch($items)) 
    {

		if ($item["account"] != $from_trans["account_code"]) 
		{
    		alt_table_row_color($k);

        	label_cell($item["account"]);
    		label_cell($item["account_name"]);
    		amount_cell($item["amount"]);
    		label_cell($item["memo_"]);
    		end_row();
    		$totalAmount += $item["amount"];
		}
	}

	label_row(tr("Total"), number_format2($totalAmount, user_price_dec()),"colspan=2 align=right", "align=right");

	end_table(1);

	if (!$voided)
		display_allocations_from($from_trans['person_type_id'], $from_trans['person_id'], 1, $trans_no, -$from_trans['amount']);
}

end_page(true);
?>