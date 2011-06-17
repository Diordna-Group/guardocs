<?php
$page_security = 11;
$path_to_root="..";
include_once($path_to_root . "/purchasing/includes/po_class.inc");

include_once($path_to_root . "/includes/session.inc");
include_once($path_to_root . "/purchasing/includes/purchasing_db.inc");
include_once($path_to_root . "/purchasing/includes/purchasing_ui.inc");

$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(900, 500);
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Receive Purchase Order Items"), false, false, "", $js);

//---------------------------------------------------------------------------------------------------------------

if (isset($_GET['AddedID'])) 
{
	$grn = $_GET['AddedID'];
	$trans_type = 25;

	display_notification_centered(tr("Purchase Order Delivery has been processed"));

	display_note(get_trans_view_str($trans_type, $grn, tr("View this Delivery")));

	//echo "<BR>";
	//echo get_gl_view_str(25, $grn, tr("View the GL Journal Entries for this Delivery"));

//	echo "<br>";
	hyperlink_no_params("$path_to_root/purchasing/inquiry/po_search.php", tr("Select a different purchase order for receiving items against"));

	display_footer_exit();
}

//--------------------------------------------------------------------------------------------------

if ((!isset($_GET['PONumber']) || $_GET['PONumber'] == 0) && !isset($_SESSION['PO'])) 
//if (isset($_GET['PONumber']) && !$_GET['PONumber'] > 0 && !isset($_SESSION['PO'])) 
{
	die (tr("This page can only be opened if a purchase order has been selected. Please select a purchase order first."));
}

//--------------------------------------------------------------------------------------------------

function display_po_receive_items()
{
	global $table_style;
    start_table("colspan=7 $table_style width=90%");
    $th = array(tr("Item Code"), tr("Description"), tr("Ordered"), tr("Units"), tr("Received"),
    	tr("Outstanding"), tr("This Delivery"), tr("Price"), tr("Total"));
    table_header($th);	

    /*show the line items on the order with the quantity being received for modification */

    $total = 0;
    $k = 0; //row colour counter

    if (count($_SESSION['PO']->line_items)> 0 )
    {
       	foreach ($_SESSION['PO']->line_items as $ln_itm) 
       	{

			alt_table_row_color($k);

    		$qty_outstanding = $ln_itm->quantity - $ln_itm->qty_received;

    	  	if ($ln_itm->receive_qty == 0)
    	  	{   //If no quantites yet input default the balance to be received
    	    	$ln_itm->receive_qty = $qty_outstanding;
    		}

    		$line_total = ($ln_itm->receive_qty * $ln_itm->price);
    		$total += $line_total;

			label_cell($ln_itm->stock_id);
			if ($qty_outstanding > 0)
				text_cells(null, $ln_itm->stock_id . "Desc", $ln_itm->item_description, 30, 50);
			else
				label_cell($ln_itm->item_description);
			qty_cell($ln_itm->quantity);
			label_cell($ln_itm->units);
			qty_cell($ln_itm->qty_received);
			qty_cell($qty_outstanding);

			if ($qty_outstanding > 0)
				qty_cells(null, $ln_itm->line_no, qty_format($ln_itm->receive_qty), "align=right");
			else
				qty_cells(null, $ln_itm->line_no, qty_format($ln_itm->receive_qty), "align=right", 
					"disabled");

			amount_cell($ln_itm->price);
			amount_cell($line_total);
			end_row();
       	}
    }

    $display_total = number_format2($total,user_price_dec());
    label_row(tr("Total value of items received"), $display_total, "colspan=8 align=right",
    	"nowrap align=right");
    end_table();
}

//--------------------------------------------------------------------------------------------------

function check_po_changed()
{
	/*Now need to check that the order details are the same as they were when they were read into the Items array. If they've changed then someone else must have altered them */
	// Sherifoz 22.06.03 Compare against COMPLETED items only !!
	// Otherwise if you try to fullfill item quantities separately will give error.
	$sql = "SELECT item_code, quantity_ordered, quantity_received, qty_invoiced
		FROM purch_order_details
		WHERE order_no=" . $_SESSION['PO']->order_no . "
		AND (quantity_ordered > quantity_received)
		ORDER BY po_detail_item";

	$result = db_query($sql, "could not query purch order details");
    check_db_error("Could not check that the details of the purchase order had not been changed by another user ", $sql);

	$line_no = 1;
	while ($myrow = db_fetch($result)) 
	{
		$ln_item = $_SESSION['PO']->line_items[$line_no];

		// only compare against items that are outstanding
		$qty_outstanding = $ln_item->quantity - $ln_item->qty_received;
		if ($qty_outstanding > 0) 
		{
    		if ($ln_item->qty_inv != $myrow["qty_invoiced"]	|| 
    			$ln_item->stock_id != $myrow["item_code"] || 
    			$ln_item->quantity != $myrow["quantity_ordered"] || 
    			$ln_item->qty_received != $myrow["quantity_received"]) 
    		{
    			return true;
    		}
		}
		$line_no++;
	} /*loop through all line items of the order to ensure none have been invoiced */

	return false;
}

//--------------------------------------------------------------------------------------------------

function can_process()
{
	if (count($_SESSION['PO']->line_items) <= 0)
	{
        display_error(tr("There is nothing to process. Please enter valid quantities greater than zero."));
    	return false;
	}

	if (!is_date($_POST['DefaultReceivedDate'])) 
	{
		display_error(tr("The entered date is invalid."));
		set_focus('DefaultReceivedDate');
		return false;
	}

    if (!references::is_valid($_POST['ref'])) 
    {
		display_error(tr("You must enter a reference."));
		set_focus('ref');
		return false;
	}

	if (!is_new_reference($_POST['ref'], 25)) 
	{
		display_error(tr("The entered reference is already in use."));
		set_focus('ref');
		return false;
	}

	$something_received = 0;
	foreach ($_SESSION['PO']->line_items as $order_line) 
	{
	  	if ($order_line->receive_qty > 0) 
	  	{
			$something_received = 1;
			break;
	  	}
	}

    // Check whether trying to deliver more items than are recorded on the actual purchase order (+ overreceive allowance)
    $delivery_qty_too_large = 0;
	foreach ($_SESSION['PO']->line_items as $order_line) 
	{
	  	if ($order_line->receive_qty+$order_line->qty_received > 
	  		$order_line->quantity * (1+ (sys_prefs::over_receive_allowance() / 100))) 
	  	{
			$delivery_qty_too_large = 1;
			break;
	  	}
	}

    if ($something_received == 0)
    { 	/*Then dont bother proceeding cos nothing to do ! */
        display_error(tr("There is nothing to process. Please enter valid quantities greater than zero."));
    	return false;
    } 
    elseif ($delivery_qty_too_large == 1)
    {
    	display_error(tr("Entered quantities cannot be greater than the quantity entered on the purchase order including the allowed over-receive percentage") . " (" . sys_prefs::over_receive_allowance() ."%)."
    		. "<br>" .
    	 	tr("Modify the ordered items on the purchase order if you wish to increase the quantities."));
    	return false;
    }

	return true;
}

//--------------------------------------------------------------------------------------------------

function process_receive_po()
{
	global $path_to_root;

	if (!can_process())
		return;

	if (check_po_changed()) 
	{
		echo "<br> " . tr("This order has been changed or invoiced since this delivery was started to be actioned. Processing halted. To enter a delivery against this purchase order, it must be re-selected and re-read again to update the changes made by the other user.") . "<BR>";

		echo "<center><a href='$path_to_root/purchasing/inquiry/po_search.php?" . SID . "'>" . tr("Select a different purchase order for receiving goods against") . "</a></center>";
		echo "<center><a href='$path_to_root/po_receive_items.php?" . SID . "PONumber=" . $_SESSION['PO']->OrderNumber . "'>" . tr("Re-Read the updated purchase order for receiving goods against") . "</a></center>";
		unset($_SESSION['PO']->line_items);
		unset($_SESSION['PO']);
		unset($_POST['ProcessGoodsReceived']);
		exit;
	}

	$grn = add_grn($_SESSION['PO'], $_POST['DefaultReceivedDate'],
		$_POST['ref'], $_POST['Location']);

	unset($_SESSION['PO']->line_items);
	unset($_SESSION['PO']);

	meta_forward($_SERVER['PHP_SELF'], "AddedID=$grn");
}

//--------------------------------------------------------------------------------------------------

if (isset($_GET['PONumber']) && $_GET['PONumber'] > 0 && !isset($_POST['Update'])) 
{

	create_new_po();

	/*read in all the selected order into the Items cart  */
	read_po($_GET['PONumber'], $_SESSION['PO']);
}

//--------------------------------------------------------------------------------------------------

if (isset($_POST['Update']) || isset($_POST['ProcessGoodsReceived'])) 
{

	/* if update quantities button is hit page has been called and ${$line->line_no} would have be
 	set from the post to the quantity to be received in this receival*/
	foreach ($_SESSION['PO']->line_items as $line) 
	{

		$_POST[$line->line_no] = max($_POST[$line->line_no], 0);
		if (!check_num($line->line_no))
			$_POST[$line->line_no] = qty_format(0);

		if (!isset($_POST['DefaultReceivedDate']) || $_POST['DefaultReceivedDate'] == "")
			$_POST['DefaultReceivedDate'] = Today();

		$_SESSION['PO']->line_items[$line->line_no]->receive_qty = input_num($line->line_no);

		if (isset($_POST[$line->stock_id . "Desc"]) && strlen($_POST[$line->stock_id . "Desc"]) > 0) 
		{
			$_SESSION['PO']->line_items[$line->line_no]->item_description = $_POST[$line->stock_id . "Desc"];
		}
	}
}

//--------------------------------------------------------------------------------------------------

if (isset($_POST['ProcessGoodsReceived']))
{
	process_receive_po();
}

//--------------------------------------------------------------------------------------------------

start_form(false, true);

display_grn_summary($_SESSION['PO'], true);
display_heading(tr("Items to Receive"));
display_po_receive_items();

echo "<br><center>";
submit('Update', tr("Update"));
echo "&nbsp";
submit('ProcessGoodsReceived', tr("Process Receive Items"));
echo "</center>";

end_form();

//--------------------------------------------------------------------------------------------------

end_page();
?>

