<?php

$path_to_root="..";
$page_security = 3;
include_once($path_to_root . "/includes/session.inc");
include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/banking.inc");
include_once($path_to_root . "/includes/data_checks.inc");
include_once($path_to_root . "/sales/includes/sales_db.inc");

$js = "";
if ($use_popup_windows) {
	$js .= get_js_open_window(900, 500);
}
if ($use_date_picker) {
	$js .= get_js_date_picker();
}
page(tr("Customer Payment Entry"), false, false, "", $js);

//----------------------------------------------------------------------------------------------

check_db_has_customers(tr("There are no customers defined in the system."));

check_db_has_bank_accounts(tr("There are no bank accounts defined in the system."));

check_db_has_bank_trans_types(tr("There are no bank payment types defined in the system."));

//----------------------------------------------------------------------------------------

if (isset($_GET['AddedID'])) {
	$payment_no = $_GET['AddedID'];

	display_notification_centered(tr("The customer payment has been successfully entered."));

	display_note(get_gl_view_str(12, $payment_no, tr("View the GL Journal Entries for this Customer Payment")));

	hyperlink_params($path_to_root . "/sales/allocations/customer_allocate.php", tr("Allocate this Customer Payment"), "trans_no=$payment_no&trans_type=12");

	hyperlink_no_params($path_to_root . "/sales/customer_payments.php", tr("Enter Another Customer Payment"));
	br(1);
	end_page();
	exit;
}

//----------------------------------------------------------------------------------------------

function can_process()
{
	if (!isset($_POST['DateBanked']) || !is_date($_POST['DateBanked'])) {
		display_error(tr("The entered date is invalid. Please enter a valid date for the payment."));
		set_focus('DateBanked');
		return false;
	} elseif (!is_date_in_fiscalyear($_POST['DateBanked'])) {
		display_error(tr("The entered date is not in fiscal year."));
		set_focus('DateBanked');
		return false;
	}

	if (!references::is_valid($_POST['ref'])) {
		display_error(tr("You must enter a reference."));
		set_focus('ref');
		return false;
	}

	if (!is_new_reference($_POST['ref'], 12)) {
		display_error(tr("The entered reference is already in use."));
		set_focus('ref');
		return false;
	}

	if (!check_num('amount', 0)) {
		display_error(tr("The entered amount is invalid or negative and cannot be processed."));
		set_focus('amount');
		return false;
	}

	if (!check_num('discount')) {
		display_error(tr("The entered discount is not a valid number."));
		set_focus('discount');
		return false;
	}

	if ((input_num('amount') - input_num('discount') <= 0)) {
		display_error(tr("The balance of the amount and discout is zero or negative. Please enter valid amounts."));
		set_focus('discount');
		return false;
	}

	return true;
}

//----------------------------------------------------------------------------------------------

// validate inputs
if (isset($_POST['AddPaymentItem'])) {

	if (!can_process()) {
		unset($_POST['AddPaymentItem']);
	}
}

//----------------------------------------------------------------------------------------------

if (isset($_POST['AddPaymentItem'])) {
	$payment_no = write_customer_payment(0, $_POST['customer_id'], $_POST['BranchID'],
		$_POST['bank_account'], $_POST['DateBanked'], $_POST['ReceiptType'], $_POST['ref'],
		input_num('amount'), input_num('discount'), $_POST['memo_']);

	meta_forward($_SERVER['PHP_SELF'], "AddedID=$payment_no");
}

//----------------------------------------------------------------------------------------------

function read_customer_data()
{
	$sql = "SELECT debtors_master.pymt_discount,
		credit_status.dissallow_invoices
		FROM debtors_master, credit_status
		WHERE debtors_master.credit_status = credit_status.id
			AND debtors_master.debtor_no = '" . $_POST['customer_id'] . "'";

	$result = db_query($sql, "could not query customers");

	$myrow = db_fetch($result);

	$_POST['HoldAccount'] = $myrow["dissallow_invoices"];
	$_POST['pymt_discount'] = $myrow["pymt_discount"];
	$_POST['ref'] = references::get_next(12);
}

//-------------------------------------------------------------------------------------------------

function display_item_form()
{
	global $table_style2;
	start_table($table_style2, 5, 7);
	echo "<tr><td valign=top>"; // outer table

	echo "<table>";

	if (!isset($_POST['customer_id']))
		$_POST['customer_id'] = get_global_customer(false);
	if (!isset($_POST['DateBanked'])) {
		$_POST['DateBanked'] = Today();
		if (!is_date_in_fiscalyear($_POST['DateBanked'])) {
			$_POST['DateBanked'] = end_fiscalyear();
		}
	}
	customer_list_row(tr("From Customer:"), 'customer_id', null, false, true);

	if (db_customer_has_branches($_POST['customer_id'])) {
		customer_branches_list_row(tr("Branch:"), $_POST['customer_id'], 'BranchID', null, false, true, true);
	} else {
		hidden('BranchID', reserved_words::get_any_numeric());
	}

	read_customer_data();

	set_global_customer($_POST['customer_id']);

	if (isset($_POST['HoldAccount']) && $_POST['HoldAccount'] != 0)	{
		echo "</table></table>";
		display_note(tr("This customer account is on hold."), 0, 0, "class='redfb'");
	} else {
		$display_discount_percent = percent_format($_POST['pymt_discount']*100) . "%";

		amount_row(tr("Amount:"), 'amount');

		amount_row(tr("Amount of Discount:"), 'discount');

		label_row(tr("Customer prompt payment discount :"), $display_discount_percent);

		date_row(tr("Date of Deposit:"), 'DateBanked');

		echo "</table>";
		echo "</td><td valign=top class='tableseparator'>"; // outer table
		echo "<table>";

		bank_accounts_list_row(tr("Into Bank Account:"), 'bank_account', null, true);

		$cust_currency = get_customer_currency($_POST['customer_id']);
		$bank_currency = get_bank_account_currency($_POST['bank_account']);

		if ($cust_currency != $bank_currency) {
			exchange_rate_display($cust_currency, $bank_currency, $_POST['DateBanked']);
		}

		bank_trans_types_list_row(tr("Type:"), 'ReceiptType', null);

		text_row(tr("Reference:"), 'ref', null, 20, 40);

		textarea_row(tr("Memo:"), 'memo_', null, 22, 4);

		echo "</table>";

		echo "</td></tr>";
		end_table(); // outer table

		if ($cust_currency != $bank_currency)
			display_note(tr("Amount and discount are in customer's currency."));

		echo"<br>";

		submit_center('AddPaymentItem', tr("Add Payment"));
	}

	echo "<br>";
}

//----------------------------------------------------------------------------------------------

start_form();

display_item_form();

end_form();
end_page();
?>
