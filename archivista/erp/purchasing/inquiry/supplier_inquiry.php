<?php

$page_security=2;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

include($path_to_root . "/purchasing/includes/purchasing_ui.inc");

$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 500);
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Supplier Inquiry"), false, false, "", $js);

if (isset($_GET['supplier_id'])){
	$_POST['supplier_id'] = $_GET['supplier_id'];
}
if (isset($_GET['FromDate'])){
	$_POST['TransAfterDate'] = $_GET['FromDate'];
}
if (isset($_GET['ToDate'])){
	$_POST['TransToDate'] = $_GET['ToDate'];
}

//------------------------------------------------------------------------------------------------

start_form(false, true);

if (!isset($_POST['supplier_id']))
	$_POST['supplier_id'] = get_global_supplier();

start_table("class='tablestyle_noborder'");
start_row();

supplier_list_cells(tr("Select a supplier:"), 'supplier_id', null, true);

date_cells(tr("From:"), 'TransAfterDate', null, -30);
date_cells(tr("To:"), 'TransToDate');

supp_allocations_list_cells("filterType", null);

submit_cells('Refresh Inquiry', tr("Search"));

end_row();
end_table();

end_form();

set_global_supplier($_POST['supplier_id']);

//------------------------------------------------------------------------------------------------

function display_supplier_summary($supplier_record)
{
	global $table_style;

	$past1 = get_company_pref('past_due_days');
	$past2 = 2 * $past1;
	$nowdue = "1-" . $past1 . " " . tr('Days');
	$pastdue1 = $past1 + 1 . "-" . $past2 . " " . tr('Days');
	$pastdue2 = tr('Over') . " " . $past2 . " " . tr('Days');
	

    start_table("width=80% $table_style");
    $th = array(tr("Currency"), tr("Terms"), tr("Current"), $nowdue,
    	$pastdue1, $pastdue2, tr("Total Balance"));

	table_header($th);
    start_row();
	label_cell($supplier_record["curr_code"]);
    label_cell($supplier_record["terms"]);
    amount_cell($supplier_record["Balance"] - $supplier_record["Due"]);
    amount_cell($supplier_record["Due"] - $supplier_record["Overdue1"]);
    amount_cell($supplier_record["Overdue1"] - $supplier_record["Overdue2"]);
    amount_cell($supplier_record["Overdue2"]);
    amount_cell($supplier_record["Balance"]);
    end_row();
    end_table(1);
}

//------------------------------------------------------------------------------------------------

function get_transactions()
{
	global $db;

    $date_after = date2sql($_POST['TransAfterDate']);
    $date_to = date2sql($_POST['TransToDate']);

    // Sherifoz 22.06.03 Also get the description
    $sql = "SELECT supp_trans.type, supp_trans.trans_no,
    	supp_trans.tran_date, supp_trans.reference, supp_trans.supp_reference,
    	(supp_trans.ov_amount + supp_trans.ov_gst  + supp_trans.ov_discount) AS TotalAmount, supp_trans.alloc AS Allocated,
		((supp_trans.type = 20 OR supp_trans.type = 21) AND supp_trans.due_date < '" . date2sql(Today()) . "') AS OverDue,
    	(ABS(supp_trans.ov_amount + supp_trans.ov_gst  + supp_trans.ov_discount - supp_trans.alloc) <= 0.005) AS Settled,
		suppliers.curr_code, suppliers.supp_name, supp_trans.due_date
    	FROM supp_trans, suppliers
    	WHERE suppliers.supplier_id = supp_trans.supplier_id
     	AND supp_trans.tran_date >= '$date_after'
    	AND supp_trans.tran_date <= '$date_to'";
   	if ($_POST['supplier_id'] != reserved_words::get_all())
   		$sql .= " AND supp_trans.supplier_id = '" . $_POST['supplier_id'] . "'";
   	if (isset($_POST['filterType']) && $_POST['filterType'] != reserved_words::get_all())
   	{
   		if (($_POST['filterType'] == '1')) 
   		{
   			$sql .= " AND (supp_trans.type = 20 OR supp_trans.type = 2)";
   		} 
   		elseif (($_POST['filterType'] == '2')) 
   		{
   			$sql .= " AND supp_trans.type = 20 ";
   		} 
   		elseif ($_POST['filterType'] == '3') 
   		{
			$sql .= " AND (supp_trans.type = 22 OR supp_trans.type = 1) ";
   		} 
   		elseif (($_POST['filterType'] == '4') || ($_POST['filterType'] == '5')) 
   		{
			$sql .= " AND supp_trans.type = 21  ";
   		}

   		if (($_POST['filterType'] == '2') || ($_POST['filterType'] == '5')) 
   		{
   			$today =  date2sql(Today());
			$sql .= " AND supp_trans.due_date < '$today' ";
   		}
   	}

    $sql .= " ORDER BY supp_trans.tran_date";

    return db_query($sql,"No supplier transactions were returned");
}

//------------------------------------------------------------------------------------------------

if (($_POST['supplier_id'] != "") && ($_POST['supplier_id'] != reserved_words::get_all()))
{
	$supplier_record = get_supplier_details($_POST['supplier_id']);
    display_supplier_summary($supplier_record);
}

//------------------------------------------------------------------------------------------------

$result = get_transactions();

if (db_num_rows($result) == 0)
{
	display_note(tr("There are no transactions to display for the given dates."), 1, 1);
	end_page();
	exit;
}

//------------------------------------------------------------------------------------------------

/*show a table of the transactions returned by the sql */

start_table("$table_style width=80%");
if ($_POST['supplier_id'] == reserved_words::get_all())
	$th = array(tr("Type"), tr("#"), tr("Reference"), tr("Supplier"),
		tr("Supplier's Reference"), tr("Date"), tr("Due Date"), tr("Currency"),
		tr("Debit"), tr("Credit"), "");
else		
	$th = array(tr("Type"), tr("#"), tr("Reference"),
		tr("Supplier's Reference"), tr("Date"), tr("Due Date"),
		tr("Debit"), tr("Credit"), "");
table_header($th);

$j = 1;
$k = 0; //row colour counter
$over_due = false;
while ($myrow = db_fetch($result)) 
{

	if ($myrow['OverDue'] == 1)
	{
		start_row("class='overduebg'");
		$over_due = true;
	} 
	else 
	{
		alt_table_row_color($k);
	}

	$date = sql2date($myrow["tran_date"]);

	$duedate = ((($myrow["type"]== 20) || ($myrow["type"]== 21))?sql2date($myrow["due_date"]):"");


	label_cell(systypes::name($myrow["type"]));
	label_cell(get_trans_view_str($myrow["type"],$myrow["trans_no"]));	
	label_cell(get_trans_view_str($myrow["type"],$myrow["trans_no"], $myrow["reference"]));
	if ($_POST['supplier_id'] == reserved_words::get_all())
		label_cell($myrow["supp_name"]);
	label_cell($myrow["supp_reference"]);
	label_cell($date);
	label_cell($duedate);
    if ($_POST['supplier_id'] == reserved_words::get_all())
    	label_cell($myrow["curr_code"]);
    if ($myrow["TotalAmount"] >= 0)
    	label_cell("");
	amount_cell(abs($myrow["TotalAmount"]));
	if ($myrow["TotalAmount"] < 0)
		label_cell("");

	label_cell(get_gl_view_str($myrow["type"], $myrow["trans_no"]));

	end_row();

	$j++;
	If ($j == 12)
	{
		$j=1;
		table_header($th);
	}
//end of page full new headings if
}
//end of while loop

end_table(1);
if ($over_due)
	display_note(tr("Marked items are overdue."), 0, 1, "class='overduefg'");


end_page();
?>
