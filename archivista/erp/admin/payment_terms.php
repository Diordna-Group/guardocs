<?php

$page_security = 10;
$path_to_root="..";
include($path_to_root . "/includes/session.inc");

page(tr("Payment Terms"));

include($path_to_root . "/includes/ui.inc");


//-------------------------------------------------------------------------------------------

if (isset($_GET['selected_id']))
{
	$selected_id = $_GET['selected_id'];
} 
elseif (isset($_POST['selected_id']))
{
	$selected_id = $_POST['selected_id'];
}

//-------------------------------------------------------------------------------------------

if (isset($_POST['ADD_ITEM']) OR isset($_POST['UPDATE_ITEM'])) 
{

	$inpug_error = 0;

	if (!is_numeric($_POST['DayNumber']))
	{
		$inpug_error = 1;
		display_error( tr("The number of days or the day in the following month must be numeric."));
		set_focus('DayNumber');
	} 
	elseif (strlen($_POST['terms']) == 0) 
	{
		$inpug_error = 1;
		display_error( tr("The Terms description must be entered."));
		set_focus('terms');
	} 
	elseif ($_POST['DayNumber'] > 30 && !check_value('DaysOrFoll')) 
	{
		$inpug_error = 1;
		display_error( tr("When the check box to indicate a day in the following month is the due date, the due date cannot be a day after the 30th. A number between 1 and 30 is expected."));
		set_focus('DayNumber');
	} 
	elseif ($_POST['DayNumber'] > 500 && check_value('DaysOrFoll')) 
	{
		$inpug_error = 1;
		display_error( tr("When the check box is not checked to indicate that the term expects a number of days after which accounts are due, the number entered should be less than 500 days."));
		set_focus('DayNumber');
	}

	if ($_POST['DayNumber'] == '')
		$_POST['DayNumber'] = 0;

	if ($inpug_error != 1)
	{
    	if (isset($selected_id)) 
    	{
    		if (check_value('DaysOrFoll')) 
    		{
    			$sql = "UPDATE payment_terms SET terms=" . db_escape($_POST['terms']) . ",
					day_in_following_month=0,
					days_before_due=" . db_escape($_POST['DayNumber']) . "
					WHERE terms_indicator = " .db_escape($selected_id);
    		} 
    		else 
    		{
    			$sql = "UPDATE payment_terms SET terms=" . db_escape($_POST['terms']) . ",
					day_in_following_month=" . db_escape($_POST['DayNumber']) . ",
					days_before_due=0
					WHERE terms_indicator = " .db_escape( $selected_id );
    		}

    	} 
    	else 
    	{

    		if (check_value('DaysOrFoll')) 
    		{
    			$sql = "INSERT INTO payment_terms (terms,
					days_before_due, day_in_following_month)
					VALUES (" .
					db_escape($_POST['terms']) . ", " . db_escape($_POST['DayNumber']) . ", 0)";
    		} 
    		else 
    		{
    			$sql = "INSERT INTO payment_terms (terms,
					days_before_due, day_in_following_month)
					VALUES (" . db_escape($_POST['terms']) . ",
					0, " . db_escape($_POST['DayNumber']) . ")";
    		}

    	}
    	//run the sql from either of the above possibilites
    	db_query($sql,"The payment term could not be added or updated");

		meta_forward($_SERVER['PHP_SELF']);
	}
}

if (isset($_GET['delete'])) 
{
	// PREVENT DELETES IF DEPENDENT RECORDS IN debtors_master

	$sql= "SELECT COUNT(*) FROM debtors_master WHERE payment_terms = '$selected_id'";
	$result = db_query($sql,"check failed");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this payment term, because customer accounts have been created referring to this term."));
	} 
	else 
	{
		$sql= "SELECT COUNT(*) FROM suppliers WHERE payment_terms = '$selected_id'";
		$result = db_query($sql,"check failed");
		$myrow = db_fetch_row($result);
		if ($myrow[0] > 0) 
		{
			display_error(tr("Cannot delete this payment term, because supplier accounts have been created referring to this term"));
		} 
		else 
		{
			//only delete if used in neither customer or supplier accounts

			$sql="DELETE FROM payment_terms WHERE terms_indicator='$selected_id'";
			db_query($sql,"could not delete a payment terms");

			meta_forward($_SERVER['PHP_SELF']);
		}
	}
	//end if payment terms used in customer or supplier accounts
}

//-------------------------------------------------------------------------------------------------

$sql = "SELECT * FROM payment_terms";
$result = db_query($sql,"could not get payment terms");

start_table($table_style);
$th = array(tr("Description"), tr("Following Month On"), tr("Due After (Days)"), "", "");
table_header($th);

$k = 0; //row colour counter
while ($myrow = db_fetch($result)) 
{
	if ($myrow["day_in_following_month"] == 0) 
	{
		$full_text = tr("N/A");
	} 
	else 
	{
		$full_text = $myrow["day_in_following_month"];
	}

	if ($myrow["days_before_due"] == 0) 
	{
		$after_text = tr("N/A");
	} 
	else 
	{
		$after_text = $myrow["days_before_due"] . " " . tr("days");
	}

	alt_table_row_color($k);

    label_cell($myrow["terms"]);
    label_cell($full_text);
    label_cell($after_text);
    edit_link_cell("selected_id=".$myrow["terms_indicator"]);
    delete_link_cell("selected_id=".$myrow["terms_indicator"]."&delete=1");
    end_row();


} //END WHILE LIST LOOP

end_table();

hyperlink_no_params($_SERVER['PHP_SELF'], tr("New Payment Term"));

//-------------------------------------------------------------------------------------------------

start_form();

start_table($table_style2);

$day_in_following_month = $days_before_due = 0;
if (isset($selected_id)) 
{
	//editing an existing payment terms
	$sql = "SELECT * FROM payment_terms
		WHERE terms_indicator='$selected_id'";

	$result = db_query($sql,"could not get payment term");
	$myrow = db_fetch($result);

	$_POST['terms']  = $myrow["terms"];
	$days_before_due  = $myrow["days_before_due"];
	$day_in_following_month  = $myrow["day_in_following_month"];

	hidden('selected_id', $selected_id);
}
text_row(tr("Terms Description:"), 'terms', null, 40, 40);

check_row(tr("Due After A Given No. Of Days:"), 'DaysOrFoll', $day_in_following_month == 0);

if (!isset($_POST['DayNumber'])) 
{
    if ($days_before_due != 0)
    	$_POST['DayNumber'] = $days_before_due;
    else
    	$_POST['DayNumber'] = $day_in_following_month;
}

text_row_ex(tr("Days (Or Day In Following Month):"), 'DayNumber', 3);

end_table(1);

submit_add_or_update_center(!isset($selected_id));

end_form();

end_page();

?>
