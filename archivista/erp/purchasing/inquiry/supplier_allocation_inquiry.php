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
page(tr("Supplier Allocation Inquiry"), false, false, "", $js);

if (isset($_GET['supplier_id']))
{
	$_POST['supplier_id'] = $_GET['supplier_id'];
}
if (isset($_GET['FromDate']))
{
	$_POST['TransAfterDate'] = $_GET['FromDate'];
}
if (isset($_GET['ToDate']))
{
	$_POST['TransToDate'] = $_GET['ToDate'];
}

//------------------------------------------------------------------------------------------------

start_form(false, true);

if (!isset($_POST['supplier_id']))
	$_POST['supplier_id'] = get_global_supplier();

start_table("class='tablestyle_noborder'");
start_row();

supplier_list_cells(tr("Select a supplier: "), 'supplier_id', $_POST['supplier_id'], true);

date_cells(tr("From:"), 'TransAfterDate', null, -30);
date_cells(tr("To:"), 'TransToDate', null, 1);

supp_allocations_list_cells("filterType", null);

check_cells(tr("show settled:"), 'showSettled', null);

submit_cells('Refresh Inquiry', tr("Search"));

set_global_supplier($_POST['supplier_id']);

end_row();
end_table();
end_form();


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
		suppliers.curr_code, suppliers.supp_name, supp_trans.due_date
    	FROM supp_trans, suppliers
    	WHERE suppliers.supplier_id = supp_trans.supplier_id
     	AND supp_trans.tran_date >= '$date_after'
    	AND supp_trans.tran_date <= '$date_to'";
   	if ($_POST['supplier_id'] != reserved_words::get_all())
   		$sql .= " AND supp_trans.supplier_id = '" . $_POST['supplier_id'] . "'";
   	if (isset($_POST['filterType']) && $_POST['filterType'] != reserved_words::get_all())
   	{
   		if (($_POST['filterType'] == '1') || ($_POST['filterType'] == '2')) 
   		{
   			$sql .= " AND supp_trans.type = 20 ";
   		} 
   		elseif ($_POST['filterType'] == '3') 
   		{
			$sql .= " AND supp_trans.type = 22 ";
   		} 
   		elseif (($_POST['filterType'] == '4') || ($_POST['filterType'] == '5')) 
   		{
			$sql .= " AND supp_trans.type = 21 ";
   		}

   		if (($_POST['filterType'] == '2') || ($_POST['filterType'] == '5')) 
   		{
   			$today =  date2sql(Today());
			$sql .= " AND supp_trans.due_date < '$today' ";
   		}
   	}

   	if (!check_value('showSettled')) 
   	{
   		$sql .= " AND (round(abs(ov_amount + ov_gst + ov_discount) - alloc,6) != 0) ";
   	}

    $sql .= " ORDER BY supp_trans.tran_date";

    return db_query($sql,"No supplier transactions were returned");
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
	$th = array(tr("Type"), tr("Number"), tr("Reference"), tr("Supplier"),
		tr("Supp Reference"), tr("Date"), tr("Due Date"), tr("Currency"),
		tr("Debit"), tr("Credit"), tr("Allocated"), tr("Balance"));
else		
	$th = array(tr("Type"), tr("Number"), tr("Reference"),	tr("Supp Reference"), tr("Date"), tr("Due Date"),
		tr("Debit"), tr("Credit"), tr("Allocated"), tr("Balance"));
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

	$duedate = ((($myrow["type"] == 20) || ($myrow["type"]== 21))?sql2date($myrow["due_date"]):"");


	label_cell(systypes::name($myrow["type"]));
	label_cell(get_trans_view_str($myrow["type"],$myrow["trans_no"]));
	label_cell($myrow["reference"]);
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
	amount_cell($myrow["Allocated"]);
	if ($myrow["type"] == 1 || $myrow["type"] == 21 || $myrow["type"] == 22)
		$balance = -$myrow["TotalAmount"] - $myrow["Allocated"];
	else	
		$balance = $myrow["TotalAmount"] - $myrow["Allocated"];
	amount_cell($balance);

	//if (($myrow["type"] == 1 || $myrow["type"] == 21 || $myrow["type"] == 22) &&
	//	$myrow["Void"] == 0)
	if (($myrow["type"] == 1 || $myrow["type"] == 21 || $myrow["type"] == 22) &&
		$balance > 0)
	{
		label_cell("<a href='$path_to_root/purchasing/allocations/supplier_allocate.php?trans_no=" . 	
			$myrow["trans_no"]. "&trans_type=" . $myrow["type"] . "'>" . tr("Allocations") . "</a>");
	}

	end_row();

	$j++;
	If ($j == 12)
	{
		$j = 1;
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
