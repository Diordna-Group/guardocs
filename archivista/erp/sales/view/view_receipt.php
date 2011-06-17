<?php

$page_security = 1;
$path_to_root="../..";
include_once($path_to_root . "/includes/session.inc");

page(tr("View Customer Payment"), true);

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/sales/includes/sales_db.inc");

if (isset($_GET["trans_no"]))
{
	$trans_id = $_GET["trans_no"];
}

$receipt = get_customer_trans($trans_id, systypes::cust_payment());

display_heading(sprintf(tr("Customer Payment #%d"),$trans_id));

echo "<br>";
start_table("$table_style width=80%");
start_row();
label_cells(tr("From Customer"), $receipt['DebtorName'], "class='tableheader2'");
label_cells(tr("Into Bank Account"), $receipt['bank_account_name'], "class='tableheader2'");
label_cells(tr("Date of Deposit"), sql2date($receipt['tran_date']), "class='tableheader2'");
end_row();
start_row();
label_cells(tr("Payment Currency"), $receipt['curr_code'], "class='tableheader2'");
label_cells(tr("Amount"), price_format($receipt['ov_amount']), "class='tableheader2'");
label_cells(tr("Discount"), price_format($receipt['ov_discount']), "class='tableheader2'");
end_row();
start_row();
label_cells(tr("Payment Type"), $receipt['BankTransType'], "class='tableheader2'");
label_cells(tr("Reference"), $receipt['reference'], "class='tableheader2'", "colspan=4");
end_row();
comments_display_row(systypes::cust_payment(), $trans_id);

end_table(1);

$voided = is_voided_display(systypes::cust_payment(), $trans_id, tr("This customer payment has been voided."));

if (!$voided)
{
	display_allocations_from(payment_person_types::customer(), $receipt['debtor_no'], systypes::cust_payment(), $trans_id, -$receipt['Total']);
}

end_page(true);
?>