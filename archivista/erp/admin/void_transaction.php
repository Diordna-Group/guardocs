<?php

$path_to_root="..";
$page_security = 14;
include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/admin/db/voiding_db.inc");
$js = "";
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Void a Transaction"), false, false, "", $js);

//----------------------------------------------------------------------------------------

function voiding_controls()
{
	global $table_style2;
	
	start_form(false, true);

	start_table($table_style2);

	systypes_list_row(tr("Transaction Type:"), "filterType", null, true);

    text_row(tr("Transaction #:"), 'trans_no', null, 12, 12);

    date_row(tr("Voiding Date:"), 'date_');

    textarea_row(tr("Memo:"), 'memo_', null, 30, 4);

	end_table(1);

    if (!isset($_POST['ProcessVoiding']))
    	submit_center('ProcessVoiding', tr("Void Transaction"));
    else 
    {
 	
    	display_note(tr("Are you sure you want to void this transaction ? This action cannot be undone."), 0, 1);
    	submit_center_first('ConfirmVoiding', tr("Proceed"));
    	submit_center_last('CancelVoiding', tr("Cancel"));
    }

	end_form();
}

//----------------------------------------------------------------------------------------

function check_valid_entries()
{
	if (!is_date($_POST['date_']))
	{
		display_error(tr("The entered date is invalid."));
		set_focus('date_');
		return false;
	}
	if (!is_date_in_fiscalyear($_POST['date_']))
	{
		display_error(tr("The entered date is not in fiscal year."));
		set_focus('date_');
		return false;
	}

	if (!is_numeric($_POST['trans_no']) OR $_POST['trans_no'] <= 0)
	{
		display_error(tr("The transaction number is expected to be numeric and greater than zero."));
		set_focus('trans_no');
		return false;
	}

	return true;
}

//----------------------------------------------------------------------------------------

function handle_void_transaction()
{
	if (check_valid_entries()==true) 
	{

		$void_entry = get_voided_entry($_POST['filterType'], $_POST['trans_no']);
		if ($void_entry != null) 
		{
			display_error(tr("The selected transaction has already been voided."), true);
			unset($_POST['trans_no']);
			unset($_POST['memo_']);
			unset($_POST['date_']);
			set_focus('trans_no');
			return;
		}

		$ret = void_transaction($_POST['filterType'], $_POST['trans_no'],
			$_POST['date_'], $_POST['memo_']);

		if ($ret) 
		{
			display_notification_centered(tr("Selected transaction has been voided."));
			unset($_POST['trans_no']);
			unset($_POST['memo_']);
			unset($_POST['date_']);
		}
		else {
			display_error(tr("The entered transaction does not exist or cannot be voided."));
			set_focus('trans_no');

		}
	}
}

//----------------------------------------------------------------------------------------

if (!isset($_POST['date_']))
{
	$_POST['date_'] = Today();
	if (!is_date_in_fiscalyear($_POST['date_']))
		$_POST['date_'] = end_fiscalyear();
}		
	
if (isset($_POST['ProcessVoiding']))
{
	if (!check_valid_entries())
		unset($_POST['ProcessVoiding']);
}

if (isset($_POST['ConfirmVoiding']))
{
	handle_void_transaction();
}

//----------------------------------------------------------------------------------------

voiding_controls();

end_page();

?>