<?php

$path_to_root="../..";
include($path_to_root . "/includes/ui/allocation_cart.inc");
$page_security = 3;

include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");

include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/banking.inc");

include_once($path_to_root . "/sales/includes/sales_db.inc");
$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 500);

add_js_allocate();

page(tr("Allocate Supplier Payment or Credit Note"), false, false, "", $js);


//--------------------------------------------------------------------------------

function clear_allocations()
{
	if (isset($_SESSION['alloc']))
	{
		unset($_SESSION['alloc']->allocs);
		unset($_SESSION['alloc']);
	}

	session_register("alloc");
}

//--------------------------------------------------------------------------------

function check_data()
{
	$total_allocated = 0;

	for ($counter=0; $counter < $_POST["TotalNumberOfAllocs"]; $counter++)
	{

		if (!check_num('amount' . $counter, 0))
		{
			display_error(tr("The entry for one or more amounts is invalid or negative."));
			set_focus('amount');
			return false;
		 }

		  /*Now check to see that the AllocAmt is no greater than the
		 amount left to be allocated against the transaction under review */
		 if (input_num('amount' . $counter) > $_POST['un_allocated' . $counter])
		 {
		     //$_POST['amount' . $counter] = $_POST['un_allocated' . $counter];
		 }

		 $_SESSION['alloc']->allocs[$counter]->current_allocated = input_num('amount' . $counter);

		 $total_allocated += input_num('amount' . $counter);
	}

	if ($total_allocated + $_SESSION['alloc']->amount > sys_prefs::allocation_settled_allowance())
	{
		display_error(tr("These allocations cannot be processed because the amount allocated is more than the total amount left to allocate."));
	   //echo  tr("Total allocated:") . " " . $total_allocated ;
	   //echo "  " . tr("Total amount that can be allocated:") . " " . -$_SESSION['alloc']->TransAmt . "<BR>";
		return false;
	}

	return true;
}

//-----------------------------------------------------------------------------------

function handle_process()
{
	begin_transaction();

	// clear all the allocations for this payment/credit
	clear_supp_alloctions($_SESSION['alloc']->type,	$_SESSION['alloc']->trans_no);

	// now add the new allocations
	$total_allocated = 0;
	foreach ($_SESSION['alloc']->allocs as $alloc_item)
	{
		if ($alloc_item->current_allocated > 0)
		{
			add_supp_allocation($alloc_item->current_allocated,
				$_SESSION['alloc']->type, $_SESSION['alloc']->trans_no,
		     	$alloc_item->type, $alloc_item->type_no, $_SESSION['alloc']->date_);

			update_supp_trans_allocation($alloc_item->type, $alloc_item->type_no,
				$alloc_item->current_allocated);
			$total_allocated += $alloc_item->current_allocated;
		}

	}  /*end of the loop through the array of allocations made */
	update_supp_trans_allocation($_SESSION['alloc']->type,
		$_SESSION['alloc']->trans_no, $total_allocated);

	commit_transaction();

	clear_allocations();
}

//--------------------------------------------------------------------------------

if (isset($_POST['Process']))
{
	if (check_data()) 
	{
		handle_process();
		$_POST['Cancel'] = 1;
	}
}

//--------------------------------------------------------------------------------

if (isset($_POST['Cancel']))
{
	clear_allocations();
	meta_forward($path_to_root . "/purchasing/allocations/supplier_allocation_main.php");
	exit;
}

//--------------------------------------------------------------------------------

function get_allocations_for_transaction($type, $trans_no)
{
	clear_allocations();

	$supptrans = get_supp_trans($trans_no, $type);

	$_SESSION['alloc'] = new allocation($trans_no, $type,
		$supptrans["supplier_id"], $supptrans["supplier_name"],
		$supptrans["Total"], sql2date($supptrans["tran_date"]));

	/* Now populate the array of possible (and previous actual) allocations for this supplier */
	/*First get the transactions that have outstanding balances ie Total-alloc >0 */

	$trans_items = get_allocatable_to_supp_transactions($_SESSION['alloc']->person_id);

	while ($myrow = db_fetch($trans_items))
	{
		$_SESSION['alloc']->add_item($myrow["type"], $myrow["trans_no"],
			sql2date($myrow["tran_date"]),
			sql2date($myrow["due_date"]),
			$myrow["Total"], // trans total
			$myrow["alloc"], // trans total allocated
			0); // this allocation
	}


	/* Now get trans that might have previously been allocated to by this trans
	NB existing entries where still some of the trans outstanding entered from
	above logic will be overwritten with the prev alloc detail below */

	$trans_items = get_allocatable_to_supp_transactions($_SESSION['alloc']->person_id, $trans_no, $type);

	while ($myrow = db_fetch($trans_items))
	{
		$_SESSION['alloc']->add_or_update_item ($myrow["type"], $myrow["trans_no"],
			sql2date($myrow["tran_date"]),
			sql2date($myrow["due_date"]),
			$myrow["Total"],
			$myrow["alloc"] - $myrow["amt"], $myrow["amt"]);
	}
}

//--------------------------------------------------------------------------------

function edit_allocations_for_transaction($type, $trans_no)
{
	global $table_style;

	start_form(false, true);

    display_heading(tr("Allocation of") . " " . systypes::name($_SESSION['alloc']->type) . " # " . $_SESSION['alloc']->trans_no);

	display_heading($_SESSION['alloc']->person_name);

    display_heading2(tr("Date:") . " <b>" . $_SESSION['alloc']->date_ . "</b>");
    display_heading2(tr("Total:") . " <b>" . price_format(-$_SESSION['alloc']->amount) . "</b>");

    echo "<br>";

    if (count($_SESSION['alloc']->allocs) > 0)
    {
		start_table($table_style);
   		$th = array(tr("Transaction Type"), tr("#"), tr("Date"), tr("Due Date"), tr("Amount"), 
   			tr("Other Allocations"), tr("This Allocation"), tr("Left to Allocate"),'');
   		table_header($th);	

        $k = $counter = $total_allocated = 0;

        foreach ($_SESSION['alloc']->allocs as $alloc_item)
        {
    		alt_table_row_color($k);

    	    label_cell(systypes::name($alloc_item->type));
    		label_cell(get_trans_view_str($alloc_item->type, $alloc_item->type_no));
    		label_cell($alloc_item->date_, "align=right");
    		label_cell($alloc_item->due_date, "align=right");
    		amount_cell($alloc_item->amount);
		amount_cell($alloc_item->amount_allocated);

    	    if (!isset($_POST['amount' . $counter]) || $_POST['amount' . $counter] == "")
    	    	$_POST['amount' . $counter] = price_format($alloc_item->current_allocated);
    	    amount_cells(null, "amount" . $counter, price_format('amount' . $counter));

    		$un_allocated = round($alloc_item->amount - $alloc_item->amount_allocated, 6);
    		hidden("un_allocated" . $counter, $un_allocated);
    		amount_cell($un_allocated);
			label_cell("<a href='#' name=Alloc$counter onclick='allocate_all(this.name.substr(5));return true;'>"
					 . tr("All") . "</a>");
			label_cell("<a href='#' name=DeAll$counter onclick='allocate_none(this.name.substr(5));return true;'>"
					 . tr("None") . "</a>");

//			label_cell("<a href='#' onclick='forms[0].amount$counter.value=forms[0].un_allocated$counter.value; return true;'>" . tr("All") . "</a>");
//			label_cell("<a href='#' onclick='forms[0].amount$counter.value=0; return true;'>" . tr("None") . "</a>");
			end_row();

    	    $total_allocated += input_num('amount' . $counter);
    	    $counter++;
       	}
		
        label_row(tr("Total Allocated"), number_format2($total_allocated,user_price_dec()),
        	"colspan=6 align=right", "align=right id='total_allocated'");
        if (-$_SESSION['alloc']->amount - $total_allocated < 0)
        {
        	$font1 = "<font color=red>";
        	$font2 = "</font>";
        }	
        else
        	$font1 = $font2 = "";
		$left_to_allocate = price_format(-$_SESSION['alloc']->amount - $total_allocated); 
        label_row(tr("Left to Allocate"), $font1 . $left_to_allocate . $font2, "colspan=6 align=right", 
        	"nowrap align=right id='left_to_allocate'");
		end_table();		

		hidden('TotalNumberOfAllocs', $counter);
//		hidden('left_to_allocate', $left_to_allocate);
    	echo "<br><center>";
       	submit('UpdateDisplay', tr("Update"));
       	echo "&nbsp;";
       	submit('Process', tr("Process"));
       	echo "&nbsp;";
	} 
	else 
	{
    	display_note(tr("There are no unsettled transactions to allocate."), 0, 1);
    	echo "<center>";
    }

   	submit('Cancel', tr("Back to Allocations"));
   	echo "</center><br><br>";

	end_form();
}

//--------------------------------------------------------------------------------

if (isset($_GET['trans_no']) && isset($_GET['trans_type']))
{
	get_allocations_for_transaction($_GET['trans_type'], $_GET['trans_no']);
}

if (isset($_SESSION['alloc']))
{
	edit_allocations_for_transaction($_SESSION['alloc']->type, $_SESSION['alloc']->trans_no);
}

//--------------------------------------------------------------------------------

end_page();

?>