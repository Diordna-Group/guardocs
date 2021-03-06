<?php

include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/ui/items_cart.inc");

//--------------------------------------------------------------------------------

function display_order_header(&$order)
{
	global $table_style2;
	start_table("width=90% $table_style2");
	echo "<tr><td valign=top width=33%>"; // outer table

	echo "<table>";

    bank_accounts_list_row(tr("To:"), 'bank_account', null, true);

    date_row(tr("Date:"), 'date_');

	echo "</table>";

	echo "</td><td width=33%>"; // outer table

	echo "<table>";

	if (!isset($_POST['PayType']))
	{
		if (isset($_GET['PayType']))
			$_POST['PayType'] = $_GET['PayType'];
		else	
			$_POST['PayType'] = "";
	}		
	if (!isset($_POST['person_id']))
	{
		if (isset($_GET['PayPerson']))
			$_POST['person_id'] = $_GET['PayPerson'];
		else
			$_POST['person_id'] = "";
	}
    payment_person_types_list_row(tr("From:"), 'PayType', $_POST['PayType'], 'person_id');

    switch ($_POST['PayType'])
    {
		case payment_person_types::misc() :
    		text_row_ex(tr("Name:"), 'person_id', 40, 50);
    		break;
		case payment_person_types::WorkOrder() :
    		workorders_list_row(tr("Work Order:"), 'person_id', null);
    		break;
		case payment_person_types::supplier() :
    		supplier_list_row(tr("Supplier:"), 'person_id', null, false, true);
    		break;
		case payment_person_types::customer() :
    		customer_list_row(tr("Customer:"), 'person_id', null, false, true);

        	if (db_customer_has_branches($_POST['person_id'])) 
        	{
        		customer_branches_list_row(tr("Branch:"), $_POST['person_id'], 'PersonDetailID', null, false, true, true);
        	} 
        	else 
        	{
        		hidden('BranchID', reserved_words::get_any_numeric());
        	}
    		break;
		//case payment_person_types::Project() :
    	//	dimensions_list_row(tr("Dimension:"), 'person_id', $_POST['person_id'], false, null, true);
    	//	break;
    }

	//$homeCurrency = get_company_currency();
	$person_currency = payment_person_types::person_currency($_POST['PayType'], $_POST['person_id']);
	$bank_currency = get_bank_account_currency($_POST['bank_account']);

	if ($bank_currency != "" && $bank_currency != $person_currency) 
	{
		exchange_rate_display($bank_currency, $person_currency, $_POST['date_']);
	}

	echo "</table>";

	echo "</td><td>"; // outer table

	echo "<table>";

	bank_trans_types_list_row(tr("Type:"), 'type', null);

    ref_row(tr("Reference:"), 'ref', references::get_next(systypes::bank_deposit()));

	echo "</table>";

	echo "</td></tr>";

	end_table(1); // outer table
}

//---------------------------------------------------------------------------------

function display_gl_items($title, &$order)
{
	global $table_style, $path_to_root;
	
	display_heading($title);

	$dim = get_company_pref('use_dimension');
	$colspan = ($dim == 2 ? 4 : ($dim == 1 ? 3 : 2));	
	
	start_table("$table_style colspan=7 width=95%");
	
	if ($dim == 2)
		$th = array(tr("Account Code"), tr("Account Description"), tr("Dimension")." 1", 
			tr("Dimension")." 2", tr("Amount"), tr("Memo")); 
	else if ($dim == 1)
		$th = array(tr("Account Code"), tr("Account Description"), tr("Dimension"), 
			tr("Amount"), tr("Memo")); 
	else
		$th = array(tr("Account Code"), tr("Account Description"), 
		tr("Amount"), tr("Memo")); 
	table_header($th);

	$k = 0;  //row colour counter

	foreach ($order->gl_items as $item) 
	{
		if (!isset($_GET['Edit']) || $_GET['Edit'] != $item->index)
		{
    		alt_table_row_color($k);

			label_cells($item->code_id, $item->description);
    		if ($dim >= 1)
    			label_cell(get_dimension_string($item->dimension_id, true));
    		if ($dim > 1)
    			label_cell(get_dimension_string($item->dimension2_id, true));
    		amount_cell(abs($item->amount));
    		label_cell($item->reference);	
    		edit_link_cell("Edit=$item->index");
    		delete_link_cell("Delete=$item->index");
    		end_row();
		} 
		else 
		{
			gl_edit_item_controls($order, $dim, $item->index);
		}
	}

	if (!isset($_GET['Edit']))
		gl_edit_item_controls($order, $dim);

	if ($order->count_gl_items())
		label_row(tr("Total"), number_format2(abs($order->gl_items_total()), user_price_dec()),"colspan=" . $colspan . " align=right", "align=right");

    end_table();
}

//---------------------------------------------------------------------------------

function gl_edit_item_controls(&$order, $dim, $Index=null)
{
	start_row();

	if (isset($_GET['Edit']) && $Index != null)
	{
		if (!isset($_POST['code_id']))
			$_POST['code_id'] = $order->gl_items[$Index]->code_id;
		if (!isset($_POST['dimension_id']))
			$_POST['dimension_id'] = $order->gl_items[$Index]->dimension_id;
		if (!isset($_POST['dimension2_id']))
			$_POST['dimension2_id'] = $order->gl_items[$Index]->dimension2_id;
		if (!isset($_POST['amount']) || ($_POST['amount'] == ""))
			$_POST['amount'] = -price_format($order->gl_items[$Index]->amount);
		if (!isset($_POST['description']) || ($_POST['description'] == ""))
			$_POST['description'] = $order->gl_items[$Index]->description;
		if (!isset($_POST['LineMemo']) || ($_POST['LineMemo'] == ""))
			$_POST['LineMemo'] = $order->gl_items[$Index]->reference;

		hidden('Index', $order->gl_items[$Index]->index);
		hidden('code_id', $order->gl_items[$Index]->code_id);

		label_cell($_POST['code_id']);
		label_cell($order->gl_items[$Index]->description);
		if ($dim >= 1)
			dimensions_list_cells(null, 'dimension_id', $_POST['dimension_id'], true, " ", false, 1);
		if ($dim > 1)
			dimensions_list_cells(null, 'dimension2_id', $_POST['dimension2_id'], true, " ", false, 2);
	}
	else
	{
		$_POST['amount'] = price_format(0);
		$_POST['dimension_id'] = 0;
		$_POST['dimension2_id'] = 0;
		$_POST['LineMemo'] = "";

		if ($_POST['PayType'] == payment_person_types::customer())
		{
			$acc = get_branch_accounts($_POST['PersonDetailID']);
			$_POST['code_id'] = $acc['receivables_account'];
		}
		elseif ($_POST['PayType'] == payment_person_types::supplier())
		{
			$acc = get_supplier_accounts($_POST['person_id']);
			$_POST['code_id'] = $acc['payable_account'];
		}
		elseif ($_POST['PayType'] == payment_person_types::WorkOrder())
			$_POST['code_id'] = get_company_pref('default_assembly_act');
		else	
			$_POST['code_id'] = get_company_pref('default_inv_sales_act');
		text_cells(null, "CodeID2", $_POST['code_id'], 12, 10, "", "", "class='combo' rel='code_id'");	
		gl_all_accounts_list_cells(null, 'code_id', $_POST['code_id'], true, false, "class='combo' rel='CodeID2'");
    	if ($dim >= 1)
			dimensions_list_cells(null, 'dimension_id', null, true, " ", false, 1);
    	if ($dim > 1)
			dimensions_list_cells(null, 'dimension2_id', null, true, " ", false, 2);
	}
	if ($dim < 1)
		hidden('dimension_id', 0);
	if ($dim < 2)
		hidden('dimension2_id', 0);

	amount_cells(null, 'amount');
	text_cells_ex(null, 'LineMemo', 35, 50);

	if (isset($_GET['Edit'])) 
	{
    	submit_cells('UpdateItem', tr("Update"));
    	submit_cells('CancelItemChanges', tr("Cancel"));
	} 
	else 
	{
		submit_cells('AddItem', tr("Add item"), "colspan=2");
	}

	end_row();
}


//---------------------------------------------------------------------------------

function gl_options_controls()
{
	echo "<br><table align='center'>";

	textarea_row(tr("Memo"), 'memo_', null, 50, 3);

	echo "</table>";
}


//---------------------------------------------------------------------------------

?>