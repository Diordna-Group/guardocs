<?php

include_once($path_to_root . "/includes/ui.inc");

//--------------------------------------------------------------------------------------

function display_bom($item_check)
{
	global $table_style;

    $result = get_bom($item_check);

    if (db_num_rows($result) == 0)
    {
    	display_note(tr("The bill of material for this item is empty."), 0, 1);
    } 
    else 
    {

        start_table($table_style);
        $th = array(tr("Component"), tr("Description"), tr("Work Centre"),
        	tr("From Location"), tr("Quantity"), tr("Unit Cost"), tr("Total Cost"));

        table_header($th);

        $j = 1;
        $k = 0; //row colour counter

        $total_cost = 0;

        while ($myrow = db_fetch($result)) 
        {

			alt_table_row_color($k);

			label_cell($myrow["component"]);
			label_cell($myrow["description"]);
			label_cell($myrow["WorkCentreDescription"]);
			label_cell($myrow["location_name"]);
			qty_cell($myrow["quantity"]);
			amount_cell($myrow["standard_cost"]);
			amount_cell($myrow["ComponentCost"]);
			end_row();
        	$total_cost += $myrow["ComponentCost"];

        	$j++;
        	If ($j == 12)
        	{
        		$j = 1;
        		table_header($th);
        	}//end of page full new headings if
		}//end of while

        label_row("<b>" . tr("Total Cost") . "</b>", "<b>" . number_format2($total_cost,user_price_dec()) ."</b>",
        	"colspan=6 align=right", "nowrap align=right");
		end_table();
    }
}

//--------------------------------------------------------------------------------------

function display_wo_requirements($woid, $quantity, $show_qoh=false, $date=null)
{
	global $table_style;

    $result = get_wo_requirements($woid);

    if (db_num_rows($result) == 0)
    {
    	display_note(tr("There are no Requirements for this Order."), 1, 0);
    } 
    else 
    {

        start_table("$table_style width=80%");
        $th = array(tr("Component"), tr("From Location"), tr("Work Centre"),
        	tr("Unit Quantity"), tr("Total Quantity"), tr("Units Issued"), tr("On Hand"));

        table_header($th);

        $k = 0; //row colour counter
		$has_marked = false;

		if ($date == null)
			$date = Today();

        while ($myrow = db_fetch($result)) 
        {

			$qoh = 0;

			// if it's a non-stock item (eg. service) don't show qoh
			if (!has_stock_holding($myrow["mb_flag"]))
				$show_qoh = false;

			if ($show_qoh)
				$qoh = get_qoh_on_date($myrow["stock_id"], $myrow["loc_code"], $date);

			if ($show_qoh && ($myrow["units_req"] * $quantity > $qoh) && 
				!sys_prefs::allow_negative_stock()) 
			{
				// oops, we don't have enough of one of the component items
				start_row("class='stockmankobg'");
				$has_marked = true;
			} 
			else
				alt_table_row_color($k);

        	if (user_show_codes())
        		label_cell($myrow["stock_id"]. " - " . $myrow["description"]);
        	else
        		label_cell($myrow["description"]);

			label_cell($myrow["location_name"]);
			label_cell($myrow["WorkCentreDescription"]);
            qty_cell($myrow["units_req"]);
			qty_cell($myrow["units_req"] * $quantity);
            qty_cell($myrow["units_issued"]);
			if ($show_qoh)
				qty_cell($qoh);
			else
				label_cell("");
			end_row();

		}

		end_table();

		if ($has_marked)
			display_note(tr("Marked items have insufficient quantities in stock."), 0, 0, "class='red'");
    }
}

//--------------------------------------------------------------------------------------

function display_wo_productions($woid)
{
	global $path_to_root, $table_style;

    $result = get_work_order_productions($woid);

    if (db_num_rows($result) == 0)
    {
    	display_note(tr("There are no Productions for this Order."), 1, 1);
    } 
    else 
    {
        start_table($table_style);
        $th = array(tr("#"), tr("Reference"), tr("Date"), tr("Quantity"));

        table_header($th);

        $k = 0; //row colour counter
		$total_qty = 0;

        while ($myrow = db_fetch($result)) 
        {

			alt_table_row_color($k);

			$total_qty += $myrow['quantity'];

        	label_cell(get_trans_view_str(29, $myrow["id"]));
			label_cell($myrow['reference']);
			label_cell(sql2date($myrow["date_"]));
			qty_cell($myrow['quantity']);
			end_row();
		}//end of while

		label_row(tr("Total"), number_format2($total_qty,user_qty_dec()), 
			"colspan=3", "nowrap align=right");

		end_table();
    }
}

//--------------------------------------------------------------------------------------

function display_wo_issues($woid)
{
	global $path_to_root, $table_style;

    $result = get_work_order_issues($woid);

    if (db_num_rows($result) == 0)
    {
    	display_note(tr("There are no Issues for this Order."), 0, 1);
    } 
    else 
    {
        start_table($table_style);
        $th = array(tr("#"), tr("Reference"), tr("Date"));

        table_header($th);

        $k = 0; //row colour counter

        while ($myrow = db_fetch($result)) 
        {

			alt_table_row_color($k);

        	label_cell(get_trans_view_str(28, $myrow["issue_no"]));
			label_cell($myrow['reference']);
			label_cell(sql2date($myrow["issue_date"]));
			end_row();
		}

		end_table();
    }
}

//--------------------------------------------------------------------------------------

function display_wo_payments($woid)
{
	global $path_to_root, $table_style;

    $result = get_bank_trans(null, null, payment_person_types::WorkOrder(), $woid);

    if (db_num_rows($result) == 0)
    {
    	echo tr("There are no Payments for this Order.") . "<br>";
    } 
    else 
    {
        start_table($table_style);
        $th = array(tr("#"), tr("Reference"), tr("Date"), tr("Amount"));

        table_header($th);

        $k = 0; //row colour counter

        while ($myrow = db_fetch($result)) 
        {

			alt_table_row_color($k);

        	label_cell(get_trans_view_str(1, $myrow["trans_no"]));
			label_cell($myrow['ref']);
			label_cell(sql2date($myrow["trans_date"]));
			amount_cell(-($myrow['amount']));
			label_cell($myrow['bank_curr_code']);
			end_row();
		}

		end_table();
    }
}

//--------------------------------------------------------------------------------------

function display_wo_details($woid, $suppress_view_link=false)
{
	global $table_style;

	$myrow = get_work_order($woid);

    if (strlen($myrow[0]) == 0) 
    {
    	display_note(tr("The work order number sent is not valid."));
    	exit;
    }

   	start_table("$table_style width=80%");

	if ($myrow["released"] == true) 
		$th = array(tr("#"), tr("Reference"), tr("Type"), tr("Manufactured Item"),
			tr("Into Location"), tr("Date"), tr("Required By"), tr("Quantity Required"),
			tr("Released Date"), tr("Manufactured"));
	else		
		$th = array(tr("#"), tr("Reference"), tr("Type"), tr("Manufactured Item"),
			tr("Into Location"), tr("Date"), tr("Required By"), tr("Quantity Required"));

	table_header($th);
	start_row();
	if ($suppress_view_link)
		label_cell($myrow["id"]);
	else
		label_cell(get_trans_view_str(systypes::work_order(), $myrow["id"]));
	label_cell($myrow["wo_ref"]);
	label_cell(wo_types::name($myrow["type"]));
	view_stock_status_cell($myrow["stock_id"], $myrow["StockItemName"]);
	label_cell($myrow["location_name"]);
	label_cell(sql2date($myrow["date_"]));
	label_cell(sql2date($myrow["required_by"]));

	qty_cell($myrow["units_reqd"]);

	if ($myrow["released"] == true) 
	{
		label_cell(sql2date($myrow["released_date"]));
		qty_cell($myrow["units_issued"]);
	}
	end_row();

	comments_display_row(systypes::work_order(), $woid);

	end_table();

    if ($myrow["closed"] == true) 
    {
    	display_note(tr("This work order is closed."));
    }
}

//--------------------------------------------------------------------------------------

function display_wo_details_quick($woid, $suppress_view_link=false)
{
	global $table_style;

	$myrow = get_work_order($woid);

    if (strlen($myrow[0]) == 0) 
    {
    	display_note(tr("The work order number sent is not valid."));
    	exit;
    }

   	start_table("$table_style width=80%");

	$th = array(tr("#"), tr("Reference"), tr("Type"), tr("Manufactured Item"),
		tr("Into Location"), tr("Date"), tr("Quantity"));
	table_header($th);	

	start_row();
	if ($suppress_view_link)
		label_cell($myrow["id"]);
	else
		label_cell(get_trans_view_str(systypes::work_order(), $myrow["id"]));
	label_cell($myrow["wo_ref"]);
	label_cell(wo_types::name($myrow["type"]));
	view_stock_status_cell($myrow["stock_id"], $myrow["StockItemName"]);
	label_cell($myrow["location_name"]);
	label_cell(sql2date($myrow["date_"]));

	qty_cell($myrow["units_issued"]);

	end_row();

	comments_display_row(systypes::work_order(), $woid);

	end_table();

    if ($myrow["closed"] == true) 
    {
    	display_note(tr("This work order is closed."));
    }
}

?>