<?php

$page_security = 9;
$path_to_root="../..";
include_once($path_to_root . "/includes/session.inc");

page(tr("Currencies"));

include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/banking.inc");

//---------------------------------------------------------------------------------------------

if (isset($_GET['selected_id']))
{
	$selected_id = $_GET['selected_id'];
} 
elseif (isset($_POST['selected_id']))
{
	$selected_id = $_POST['selected_id'];
}
else
	$selected_id = "";
//---------------------------------------------------------------------------------------------

function check_data()
{
	if (strlen($_POST['Abbreviation']) == 0) 
	{
		display_error( tr("The currency abbreviation must be entered."));
		set_focus('Abbreviation');
		return false;
	} 
	elseif (strlen($_POST['CurrencyName']) == 0) 
	{
		display_error( tr("The currency name must be entered."));
		set_focus('CurrencyName');
		return false;		
	} 
	elseif (strlen($_POST['Symbol']) == 0) 
	{
		display_error( tr("The currency symbol must be entered."));
		set_focus('Symbol');
		return false;		
	} 
	elseif (strlen($_POST['hundreds_name']) == 0) 
	{
		display_error( tr("The hundredths name must be entered."));
		set_focus('hundreds_name');
		return false;		
	}  	
	
	return true;
}

//---------------------------------------------------------------------------------------------

function handle_submit()
{
	global $selected_id;
	
	if (!check_data())
		return false;
		
	if ($selected_id != "") 
	{

		update_currency($_POST['Abbreviation'], $_POST['Symbol'], $_POST['CurrencyName'], 
			$_POST['country'], $_POST['hundreds_name']);
	} 
	else 
	{

		add_currency($_POST['Abbreviation'], $_POST['Symbol'], $_POST['CurrencyName'], 
			$_POST['country'], $_POST['hundreds_name']);
	}
	
	return true;
}

//---------------------------------------------------------------------------------------------

function check_can_delete()
{
	global $selected_id;
		
	if ($selected_id == "")
		return false;
	// PREVENT DELETES IF DEPENDENT RECORDS IN debtors_master
	$sql= "SELECT COUNT(*) FROM debtors_master WHERE curr_code = '$selected_id'";
	$result = db_query($sql);
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this currency, because customer accounts have been created referring to this currency."));
		return false;
	}

	$sql= "SELECT COUNT(*) FROM suppliers WHERE curr_code = '$selected_id'";
	$result = db_query($sql);
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this currency, because supplier accounts have been created referring to this currency."));
		return false;
	}
		
	$sql= "SELECT COUNT(*) FROM company WHERE curr_default = '$selected_id'";
	$result = db_query($sql);
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this currency, because the company preferences uses this currency."));
		return false;
	}
	
	// see if there are any bank accounts that use this currency
	$sql= "SELECT COUNT(*) FROM bank_accounts WHERE bank_curr_code = '$selected_id'";
	$result = db_query($sql);
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) 
	{
		display_error(tr("Cannot delete this currency, because thre are bank accounts that use this currency."));
		return false;
	}
	
	return true;
}

//---------------------------------------------------------------------------------------------

function handle_delete()
{
	global $selected_id;
	if (!check_can_delete())
		return;
	//only delete if used in neither customer or supplier, comp prefs, bank trans accounts
	
	delete_currency($selected_id);

	meta_forward($_SERVER['PHP_SELF']);
}

//---------------------------------------------------------------------------------------------

function display_currencies()
{
	global $table_style;

	$company_currency = get_company_currency();	
	
    $result = get_currencies();
    
    start_table($table_style);
    $th = array(tr("Abbreviation"), tr("Symbol"), tr("Currency Name"),
    	tr("Hundredths name"), tr("Country"), "", "");
    table_header($th);	
    
    $k = 0; //row colour counter
    
    while ($myrow = db_fetch($result)) 
    {
    	
    	if ($myrow[1] == $company_currency) 
    	{
    		start_row("class='currencybg'");
    	} 
    	else
    		alt_table_row_color($k);
    		
    	label_cell($myrow["curr_abrev"]);
		label_cell($myrow["curr_symbol"]);
		label_cell($myrow["currency"]);
		label_cell($myrow["hundreds_name"]);
		label_cell($myrow["country"]);
		edit_link_cell("selected_id=" . $myrow["curr_abrev"]);
		if ($myrow["curr_abrev"] != $company_currency)
			delete_link_cell("selected_id=" . $myrow["curr_abrev"]. "&delete=1");
		
		end_row();
		
    } //END WHILE LIST LOOP
    
    end_table();
    
    display_note(tr("The marked currency is the home currency which cannot be deleted."), 0, 0, "class='currentfg'");
}

//---------------------------------------------------------------------------------------------

function display_currency_edit($selected_id)
{
	global $table_style2;
	
	start_form();
	start_table($table_style2);

	if ($selected_id != "") 
	{
		//editing an existing currency
		$myrow = get_currency($selected_id);

		$_POST['Abbreviation'] = $myrow["curr_abrev"];
		$_POST['Symbol'] = $myrow["curr_symbol"];
		$_POST['CurrencyName']  = $myrow["currency"];
		$_POST['country']  = $myrow["country"];
		$_POST['hundreds_name']  = $myrow["hundreds_name"];

		hidden('selected_id', $selected_id);
		hidden('Abbreviation', $_POST['Abbreviation']);
		label_row(tr("Currency Abbreviation:"), $_POST['Abbreviation']);		
	} 
	else 
	{ 
		text_row_ex(tr("Currency Abbreviation:"), 'Abbreviation', 4, 3);		
	}

	text_row_ex(tr("Currency Symbol:"), 'Symbol', 10);
	text_row_ex(tr("Currency Name:"), 'CurrencyName', 20);
	text_row_ex(tr("Hundredths Name:"), 'hundreds_name', 15);	
	text_row_ex(tr("Country:"), 'country', 40);	

	end_table(1);

	submit_add_or_update_center($selected_id == "");

	end_form();
}

//---------------------------------------------------------------------------------------------

if (isset($_POST['ADD_ITEM']) || isset($_POST['UPDATE_ITEM'])) 
{

	if (handle_submit()) 
	{
		meta_forward($_SERVER['PHP_SELF']);		
	}	
}

//--------------------------------------------------------------------------------------------- 

if (isset($_GET['delete'])) 
{

	handle_delete();
}

//---------------------------------------------------------------------------------------------

display_currencies();

hyperlink_no_params($_SERVER['PHP_SELF'], tr("Enter a New Currency"));

display_currency_edit($selected_id);

//---------------------------------------------------------------------------------------------

end_page();

?>
