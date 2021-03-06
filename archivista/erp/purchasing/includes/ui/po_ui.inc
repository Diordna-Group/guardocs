<?php

include_once($path_to_root . "/purchasing/includes/purchasing_db.inc");

// ------------------------------------------------------------------------------

function get_supplier_details_to_order(&$order, $supplier_id)
{
	$sql = "SELECT curr_code,supp_name FROM suppliers
		WHERE supplier_id = '$supplier_id'";
	$result = db_query($sql, "The supplier details could not be retreived");

	$myrow = db_fetch($result);

	$order->curr_code = $_POST['curr_code'] = $myrow["curr_code"];
	$order->supplier_name = $_POST['supplier_name'] = $myrow["supp_name"];
	$order->supplier_id = $_POST['supplier_id'] = $supplier_id;
}

//---------------------------------------------------------------------------------------------------

function create_new_po()
{
	if (isset($_SESSION['PO']))
	{
		unset ($_SESSION['PO']->line_items);
		$_SESSION['PO']->lines_on_order = 0;
		unset ($_SESSION['PO']);
	}

	session_register("PO");

	$_SESSION['PO'] = new purch_order;
	$_POST['OrderDate'] = Today();
	if (!is_date_in_fiscalyear($_POST['OrderDate']))
		$_POST['OrderDate'] = end_fiscalyear();
	$_SESSION['PO']->orig_order_date = $_POST['OrderDate'];
}

//---------------------------------------------------------------------------------------------------

function display_po_header(&$order)
{
	global $table_style2;

	$editable = ($order->order_no == 0);

	start_table("width=80% $table_style2");
	echo "<tr><td valign=center>"; // outer table
	echo "<table>";

    if ($editable)
    {
        if (!isset($_POST['supplier_id']) && (get_global_supplier() != reserved_words::get_all()))
        	$_POST['supplier_id'] = get_global_supplier();

    	supplier_list_row(tr("Supplier:"), 'supplier_id', $_POST['supplier_id'], false, true);

    	if ($order->supplier_id != $_POST['supplier_id'])
    	{
    		// supplier has changed
    		// delete all the order items - drastic but necessary because of
    		// change of currency, etc
    		$order->clear_items();
    	}
	}
	else
	{
		hidden('supplier_id', $order->supplier_id);
		label_row(tr("Supplier:"), $order->supplier_name);
    }

	//if ($editable || ($order->supplier_id != $_POST['supplier_id']))
	get_supplier_details_to_order($order, $_POST['supplier_id']);

	set_global_supplier($_POST['supplier_id']);

	if (!is_company_currency($order->curr_code))
	{
		label_row(tr("Supplier Currency:"), $order->curr_code);
		exchange_rate_display($order->curr_code, get_company_currency(),
			$_POST['OrderDate']);
	}

    if ($editable)
    {
    	ref_row(tr("Reference:"), 'ref', references::get_next(systypes::po()));
    }
    else
    {
    	hidden('ref', $order->reference);
    	label_row(tr("Reference:"), $order->reference);
    }

	echo "</table>";

	echo "</td><td valign=center>"; // outer table

	echo "<table height='5'>";
	// check this out?????????
	//if (!isset($_POST['OrderDate']) || $_POST['OrderDate'] == "")
	//	$_POST['OrderDate'] = $order->orig_order_date;
	//if (!isset($_POST['OrderDate']) || $_POST['OrderDate'] == "")
	//{
	//	$_POST['OrderDate'] = Today();
	//	if (!is_date_in_fiscalyear($_POST['OrderDate']))
	//		$_POST['OrderDate'] = end_fiscalyear();
	//}
	date_row(tr("Order Date:"), 'OrderDate', $_POST['OrderDate'], 0, 0, 0);

  	text_row(tr("Supplier's Reference:"), 'Requisition', null, 16, 15);

	echo "</table>";

	echo "</td><td valign=center>"; // outer table

  	echo "<table height='5'>";

	echo "<tr><td>" . tr("Receive Into:") . "</td>";
	echo "<td>";
    locations_list('StkLocation', null);
    echo "  ";
    submit('GetAddress', tr("Get Address"));
	echo "</td></tr>";

    if (!isset($_POST['StkLocation']) || $_POST['StkLocation'] == "" ||
    	isset($_POST['GetAddress']) || !isset($_POST['delivery_address']) ||
    	$_POST['delivery_address'] == "")
    {
    	/*If this is the first time the form loaded set up defaults */

        //$_POST['StkLocation'] = $_SESSION['UserStockLocation'];
        $sql = "SELECT delivery_address, phone FROM locations WHERE loc_code='" . $_POST['StkLocation'] . "'";
        $result = db_query($sql,"could not get location info");

        if (db_num_rows($result) == 1)
        {
    	  	$loc_row = db_fetch($result);
    	  	$_POST['delivery_address'] = $loc_row["delivery_address"];
    	  	$_SESSION['PO']->Location = $_POST['StkLocation'];
    	  	$_SESSION['PO']->delivery_address = $_POST['delivery_address'];

        }
        else
        { /*The default location of the user is crook */
    	  	echo "<br>" . tr("The default stock location set up for this user is not a currently defined stock location. Your system administrator needs to amend your user record.");
        }
    }

	textarea_row(tr("Deliver to:"), 'delivery_address', $_POST['delivery_address'], 35, 4);
  	echo "</table>";

	echo "</td></tr>";
	end_table(); // outer table
}

//---------------------------------------------------------------------------------------------------

function display_po_items(&$order, $editable=true)
{
	global $table_style;

    display_heading(tr("Order Items"));

    start_table("$table_style width=80%");

   	$th = array(tr("Item Code"), tr("Item Description"), tr("Quantity"), tr("Unit"),
   		tr("Required Delivery Date"), tr("Price"), tr("Line Total"));
	
	if (count($order->line_items)) $th[] = '';
   	table_header($th);

	$total = 0;
	$k = 0;
   	foreach ($order->line_items as $po_line)
   	{

		if ($po_line->Deleted == false)
		{
    		$line_total =	round($po_line->quantity * $po_line->price,  user_price_dec());
    		if (!$editable || !isset($_GET['Edit']) || $_GET['Edit'] != $po_line->line_no)
			{
    			alt_table_row_color($k);
        		label_cell($po_line->stock_id);
    			label_cell($po_line->item_description);
                qty_cell($po_line->quantity);
    			label_cell($po_line->units);
                label_cell($po_line->req_del_date);
    			amount_cell($po_line->price);
                amount_cell($line_total);

                if ($editable)
                {
                    edit_link_cell(SID."Edit=" . $po_line->line_no);
                    delete_link_cell(SID."Delete=" . $po_line->line_no);
                }
        		end_row();
			}
			else
			{
				po_item_controls($order, $po_line->stock_id);
			}
    		$total += $line_total;
		}
    }

	if (!isset($_GET['Edit']) && $editable)
		po_item_controls($order);

    $display_total = price_format($total);
    label_row(tr("Total Excluding Shipping/Tax"), $display_total, "colspan=6 align=right",
    	"nowrap align=right");

	end_table(1);
}

//---------------------------------------------------------------------------------------------------

function display_po_summary(&$po, $is_self=false, $editable=false)
{
	global $table_style2;
    start_table("$table_style2 width=90%");

    start_row();
    label_cells(tr("Reference"), $po->reference, "class='tableheader2'");

    label_cells(tr("Supplier"), $po->supplier_name, "class='tableheader2'");

    if (!is_company_currency($po->curr_code))
    	label_cells(tr("Order Currency"), $po->curr_code, "class='tableheader2'");

    if (!$is_self)
    {
    	label_cells(tr("Purchase Order"), get_trans_view_str(systypes::po(), $po->order_no),
    		"class='tableheader2'");
    }
	end_row();
	start_row();
    label_cells(tr("Date"), $po->orig_order_date, "class='tableheader2'");

    if ($editable)
    {
        if (!isset($_POST['Location']))
        	$_POST['Location'] = $po->Location;
        label_cell(tr("Deliver Into Location"), "class='tableheader2'");
        locations_list_cells(null, 'Location', $_POST['Location']);
    }
    else
    {
    	label_cells(tr("Deliver Into Location"), get_location_name($po->Location),
    		"class='tableheader2'");
    }

    if ($po->requisition_no != "")
    	label_cells(tr("Supplier's Reference"), $po->requisition_no, "class='tableheader2'");
    end_row();

    if (!$editable)
    	label_row(tr("Delivery Address"), $po->delivery_address, "class='tableheader2'",
    		"colspan=9");

    if ($po->Comments != "")
    	label_row(tr("Order Comments"), $po->Comments, "class='tableheader2'",
    		"colspan=9");
    end_table(1);
}

//--------------------------------------------------------------------------------

function po_item_controls(&$order, $stock_id=null)
{
	start_row();

	if (isset($_GET['Edit']) && $stock_id != null)
	{
		hidden('line_no', $_GET['Edit']);

		if (!isset($_POST['stock_id']))
			$_POST['stock_id'] = $order->line_items[$_GET['Edit']]->stock_id;
		if (!isset($_POST['qty']) || ($_POST['qty'] == ""))
			$_POST['qty'] = qty_format($order->line_items[$_GET['Edit']]->quantity);
		if (!isset($_POST['price']) || ($_POST['price'] == ""))
			$_POST['price'] = price_format($order->line_items[$_GET['Edit']]->price);
		if (!isset($_POST['req_del_date']) || ($_POST['req_del_date'] == ""))
			$_POST['req_del_date'] = $order->line_items[$_GET['Edit']]->req_del_date;

		$_POST['units'] = $order->line_items[$_GET['Edit']]->units;

		hidden('stock_id', $_POST['stock_id']);
		label_cell($_POST['stock_id']);
		label_cell($order->line_items[$_GET['Edit']]->item_description);
	}
	else
	{
		hidden('line_no', ($_SESSION['PO']->lines_on_order + 1));

		$no_item_list = get_company_pref('no_item_list');
		if ($no_item_list)
		{
			echo "<td colspan=2 nowrap>\n";
			stock_purchasable_items_list('stock_id', $_POST['stock_id'], false, true);
			echo "</td>\n";
		}
		else
		{
			text_cells(null, "StockID2", "", 12, 10, "", "", "class='combo' rel='stock_id' onblur='submit()'");
			stock_purchasable_items_list_cells(null, 'stock_id', $_POST['stock_id'], false, false, "class='combo' rel='StockID2'");
		}
    	$item_info = get_item_edit_info($_POST['stock_id']);
		$_POST['units'] = $item_info["units"];

   		$_POST['qty'] = qty_format(1);
		$_POST['price'] = price_format(get_purchase_price ($order->supplier_id, $_POST['stock_id']));
		$_POST['req_del_date'] = add_days(Today(), 10);
	}

	qty_cells(null, 'qty', null);

	label_cell($_POST['units']);
	date_cells(null, 'req_del_date', null, 0, 0, 0);
	amount_cells(null, 'price', null);

	//$line_total = $_POST['qty'] * $_POST['price'] * (1 - $_POST['Disc'] / 100);
	$line_total = round(input_num('qty') * input_num('price'),  user_price_dec());
	amount_cell($line_total);

	if (isset($_GET['Edit']))
	{
    	submit_cells('UpdateLine', tr("Update"));
    	submit_cells('CancelUpdate', tr("Cancel"));
	}
	else
	{
		submit_cells('EnterLine', tr("Add Item"), "colspan=2");
	}

	end_row();
}

//---------------------------------------------------------------------------------------------------



?>