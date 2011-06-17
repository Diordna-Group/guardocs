<?php

$path_to_root="..";
$page_security = 5;
include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/banking.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/purchasing/includes/purchasing_db.inc");
$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 500);
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Supplier Payment Entry"), false, false, "", $js);


if (isset($_GET['supplier_id']))
{
	$_POST['supplier_id'] = $_GET['supplier_id'];
}

//----------------------------------------------------------------------------------------

check_db_has_suppliers(tr("There are no suppliers defined in the system."));

check_db_has_bank_accounts(tr("There are no bank accounts defined in the system."));

check_db_has_bank_trans_types(tr("There are no bank payment types defined in the system."));

//----------------------------------------------------------------------------------------

if (isset($_GET['AddedID'])) 
{
	$payment_id = $_GET['AddedID'];

   	display_notification_centered( tr("Payment has been sucessfully entered"));

    display_note(get_gl_view_str(22, $payment_id, tr("View the GL Journal Entries for this Payment")));

    hyperlink_params($path_to_root . "/purchasing/allocations/supplier_allocate.php", tr("Allocate this Payment"), "trans_no=$payment_id&trans_type=22");

	hyperlink_params($_SERVER['PHP_SELF'], tr("Enter another supplier payment"), "supplier_id=" . $_POST['supplier_id']);

	display_footer_exit();
}

//----------------------------------------------------------------------------------------

function display_controls()
{
	global $table_style2;
	start_form(false, true);

	if (!isset($_POST['supplier_id']))
		$_POST['supplier_id'] = get_global_supplier(false);
	if (!isset($_POST['DatePaid']))
	{
		$_POST['DatePaid'] = Today();
		if (!is_date_in_fiscalyear($_POST['DatePaid']))
			$_POST['DatePaid'] = end_fiscalyear();
	}		
	start_table($table_style2, 5, 7);
	echo "<tr><td valign=top>"; // outer table

	echo "<table>";

    bank_accounts_list_row(tr("From Bank Account:"), 'bank_account', null, true);

	amount_row(tr("Amount of Payment:"), 'amount');
	amount_row(tr("Amount of Discount:"), 'discount');

    date_row(tr("Date Paid") . ":", 'DatePaid');

	echo "</table>";
	echo "</td><td valign=top class='tableseparator'>"; // outer table
	echo "<table>";

    supplier_list_row(tr("Payment To:"), 'supplier_id', null, false, true);

	set_global_supplier($_POST['supplier_id']);

	$supplier_currency = get_supplier_currency($_POST['supplier_id']);
	$bank_currency = get_bank_account_currency($_POST['bank_account']);
	if ($bank_currency != $supplier_currency) 
	{
		exchange_rate_display($bank_currency, $supplier_currency, $_POST['DatePaid']);
	}

	bank_trans_types_list_row(tr("Payment Type:"), 'PaymentType', null);

    ref_row(tr("Reference:"), 'ref', references::get_next(22));

    text_row(tr("Memo:"), 'memo_', null, 52,50);

	echo "</table>";

	echo "</td></tr>";
	end_table(1); // outer table

	submit_center('ProcessSuppPayment',tr("Enter Payment"));

	if ($bank_currency != $supplier_currency) 
	{
		display_note(tr("The amount and discount are in the bank account's currency."), 2, 0);
	}

	end_form();
}

//----------------------------------------------------------------------------------------

function check_inputs()
{
	if ($_POST['amount'] == "") 
	{
		$_POST['amount'] = price_format(0);
	}

	if (!check_num('amount', 0))
	{
		display_error(tr("The entered amount is invalid or less than zero."));
		set_focus('amount');
		return false;
	}

	if ($_POST['discount'] == "") 
	{
		$_POST['discount'] = 0;
	}

	if (!check_num('discount', 0))
	{
		display_error(tr("The entered discount is invalid or less than zero."));
		set_focus('amount');
		return false;
	}

	if (input_num('amount') - input_num('discount') <= 0) 
	{
		display_error(tr("The total of the amount and the discount negative. Please enter positive values."));
		set_focus('amount');
		return false;
	}

   	if (!is_date($_POST['DatePaid']))
   	{
		display_error(tr("The entered date is invalid."));
		set_focus('DatePaid');
		return false;
	} 
	elseif (!is_date_in_fiscalyear($_POST['DatePaid'])) 
	{
		display_error(tr("The entered date is not in fiscal year."));
		set_focus('DatePaid');
		return false;
	}
    if (!references::is_valid($_POST['ref'])) 
    {
		display_error(tr("You must enter a reference."));
		set_focus('ref');
		return false;
	}

	if (!is_new_reference($_POST['ref'], 22)) 
	{
		display_error(tr("The entered reference is already in use."));
		set_focus('ref');
		return false;
	}

	return true;
}

//----------------------------------------------------------------------------------------

function handle_add_payment()
{
	$payment_id = add_supp_payment($_POST['supplier_id'], $_POST['DatePaid'],
		$_POST['PaymentType'], $_POST['bank_account'],
		input_num('amount'), input_num('discount'), $_POST['ref'], $_POST['memo_']);

	//unset($_POST['supplier_id']);
   	unset($_POST['bank_account']);
   	unset($_POST['DatePaid']);
   	unset($_POST['PaymentType']);
   	unset($_POST['currency']);
   	unset($_POST['memo_']);
   	unset($_POST['amount']);
   	unset($_POST['discount']);
   	unset($_POST['ProcessSuppPayment']);

	meta_forward($_SERVER['PHP_SELF'], "AddedID=$payment_id&supplier_id=".$_POST['supplier_id']);
}

//----------------------------------------------------------------------------------------

if (isset($_POST['ProcessSuppPayment']))
{
	 /*First off  check for valid inputs */
    if (check_inputs() == true) 
    {
    	handle_add_payment();
    	end_page();
     	exit;
    }
}

display_controls();

end_page();
?>
