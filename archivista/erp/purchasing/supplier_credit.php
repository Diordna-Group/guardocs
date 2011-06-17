<?php

$path_to_root="..";

include_once($path_to_root . "/purchasing/includes/supp_trans_class.inc");

$page_security=5;

include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/purchasing/includes/purchasing_db.inc");
include_once($path_to_root . "/purchasing/includes/purchasing_ui.inc");
$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 500);
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Supplier Credit Note"), false, false, "", $js);

//----------------------------------------------------------------------------------------

check_db_has_suppliers(tr("There are no suppliers defined in the system."));

//---------------------------------------------------------------------------------------------------------------

if (isset($_GET['AddedID'])) 
{
	$invoice_no = $_GET['AddedID'];
	$trans_type = 21;


    echo "<center>";
    display_notification_centered(tr("Supplier credit note has been processed."));
    display_note(get_trans_view_str($trans_type, $invoice_no, tr("View this Credit Note")));

	display_note(get_gl_view_str($trans_type, $invoice_no, tr("View the GL Journal Entries for this Credit Note")), 1);

    hyperlink_params($_SERVER['PHP_SELF'], tr("Enter Another Credit Note"), "New=1");

	display_footer_exit();
}

//---------------------------------------------------------------------------------------------------

if (isset($_GET['New']))
{
	if (isset( $_SESSION['supp_trans']))
	{
		unset ($_SESSION['supp_trans']->grn_items);
		unset ($_SESSION['supp_trans']->gl_codes);
		unset ($_SESSION['supp_trans']);
	}

	$_SESSION['supp_trans'] = new supp_trans;
	$_SESSION['supp_trans']->is_invoice = false;
}

//---------------------------------------------------------------------------------------------------

function check_data()
{
	global $total_grn_value, $total_gl_value;
	
	if (!$_SESSION['supp_trans']->is_valid_trans_to_post())
	{
		display_error(tr("The credit note cannot be processed because the there are no items or values on the invoice.  Credit notes are expected to have a charge."));
		set_focus('');
		return false;
	}

	if (!references::is_valid($_SESSION['supp_trans']->reference)) 
	{
		display_error(tr("You must enter an credit note reference."));
		set_focus('reference');
		return false;
	}

	if (!is_new_reference($_SESSION['supp_trans']->reference, 21)) 
	{
		display_error(tr("The entered reference is already in use."));
		set_focus('reference');
		return false;
	}

	if (!references::is_valid($_SESSION['supp_trans']->supp_reference)) 
	{
		display_error(tr("You must enter a supplier's credit note reference."));
		set_focus('supp_reference');
		return false;
	}

	if (!is_date($_SESSION['supp_trans']->tran_date))
	{
		display_error(tr("The credit note as entered cannot be processed because the date entered is not valid."));
		set_focus('tran_date');
		return false;
	} 
	elseif (!is_date_in_fiscalyear($_SESSION['supp_trans']->tran_date)) 
	{
		display_error(tr("The entered date is not in fiscal year."));
		set_focus('tran_date');
		return false;
	}
	if (!is_date( $_SESSION['supp_trans']->due_date))
	{
		display_error(tr("The invoice as entered cannot be processed because the due date is in an incorrect format."));
		set_focus('due_date');
		return false;
	}

	if ($_SESSION['supp_trans']->ov_amount < ($total_gl_value + $total_grn_value))
	{
		display_error(tr("The credit note total as entered is less than the sum of the the general ledger entires (if any) and the charges for goods received. There must be a mistake somewhere, the credit note as entered will not be processed."));
		return false;
	}

	return true;
}

//---------------------------------------------------------------------------------------------------

function handle_commit_credit_note()
{
	copy_to_trans($_SESSION['supp_trans']);

	if (!check_data())
		return;

	$invoice_no = add_supp_invoice($_SESSION['supp_trans']);

    $_SESSION['supp_trans']->clear_items();
    unset($_SESSION['supp_trans']);

	meta_forward($_SERVER['PHP_SELF'], "AddedID=$invoice_no");
}

//--------------------------------------------------------------------------------------------------

if (isset($_POST['PostCreditNote']))
{
	handle_commit_credit_note();
}

//--------------------------------------------------------------------------------------------------

start_form(false, true);

start_table("$table_style width=80%", 8);
echo "<tr><td valign=center>"; // outer table

echo "<center>";

invoice_header($_SESSION['supp_trans']);

echo "</td></tr><tr><td valign=center>"; // outer table

$total_grn_value = display_grn_items($_SESSION['supp_trans']);

$total_gl_value = display_gl_items($_SESSION['supp_trans']);

echo "</td></tr><tr><td align=center colspan=2>"; // outer table

invoice_totals($_SESSION['supp_trans']);

echo "</td></tr>";

end_table(1); // outer table

submit_center('PostCreditNote', tr("Enter Credit Note"));
echo "<br><br>";

end_form();
end_page();
?>
