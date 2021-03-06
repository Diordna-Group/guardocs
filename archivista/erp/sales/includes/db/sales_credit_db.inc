<?php

//----------------------------------------------------------------------------------------
// if ($writeoff_acc==0) return goods into $cart->Location
// if src_docs!=0 => credit invoice else credit note
//
function write_credit_note($credit_note, $write_off_acc)
{
	$credit_invoice = count($credit_note->src_docs) ? key($credit_note->src_docs) : 0;


	$credit_date = $credit_note->document_date;
	$tax_group_id = $credit_note->tax_group_id;

	$trans_no = $credit_note->trans_no;
	if (is_array($trans_no)) {
		$trans_no = key($trans_no);
	}

	$credit_type = $write_off_acc == 0 ? 'Return' : 'Writeoff';

	begin_transaction();

	$company_data = get_company_prefs();
	$branch_data = get_branch_accounts($credit_note->Branch);

	$credit_note_total = $credit_note->get_items_total_dispatch();
	$freight_tax = $credit_note->get_shipping_tax();

	$taxes = $credit_note->get_taxes();

	$tax_total = 0;
	foreach ($taxes as $taxitem) {
		$tax_total +=  $taxitem['Value'];
	}

	if ($credit_note->tax_included == 0) {
	    $items_added_tax = $tax_total-$freight_tax;
	    $freight_added_tax = $freight_tax;
	} else {
	    $items_added_tax = 0;
	    $freight_added_tax = 0;
	}

//	$sales_order=$invoice->order_no;	//?
//    if (is_array($sales_order)) $sales_order = $sales_order[0]; //?

	/*Now insert the Credit Note into the debtor_trans table with the allocations as calculated above*/
	// all amounts in debtor's currency
	$credit_no = write_customer_trans(11, $trans_no, $credit_note->customer_id,
		$credit_note->Branch, $credit_date, $credit_note->reference,
		$credit_note_total, 0, $items_added_tax,
		$credit_note->freight_cost, $freight_added_tax,
		$credit_note->sales_type,
		$credit_note->order_no, $credit_invoice, $credit_note->ship_via
		//, $credit_note->due_date
		);

	if ($trans_no==0) {
		$credit_note->trans_no = array($credit_no=>0);
		set_document_parent($credit_note);
	} else {
		delete_comments(11, $credit_no);
		void_cust_allocations(11, $credit_no);
		void_gl_trans(11, $credit_no, true);
		void_stock_move(11, $credit_no);
		void_customer_trans_tax_details(11, $credit_no);
	}

	if ($credit_invoice) {
		$invoice_alloc_balance = get_DebtorTrans_allocation_balance(10, $credit_invoice);
		update_customer_trans_version(get_parent_type(11), $credit_note->src_docs );
		if ($invoice_alloc_balance > 0) { 	/*the invoice is not already fully allocated */
			$total = $credit_note_total + $credit_note->freight_cost +
			    $items_added_tax + $freight_added_tax;

			$allocate_amount = ($invoice_alloc_balance > $total) ? $total : $invoice_alloc_balance;
			/*Now insert the allocation record if > 0 */
			if ($allocate_amount != 0) {
				update_debtor_trans_allocation(10, $credit_invoice, $allocate_amount);
				update_debtor_trans_allocation(11, $credit_no, $allocate_amount); // ***
				add_cust_allocation($allocate_amount, 11, $credit_no, 10, $credit_invoice);
			}
		}
	}

	foreach ($credit_note->line_items as $credit_line) {

		if ($credit_invoice && $credit_line->qty_dispatched!=$credit_line->qty_old ) {
			update_parent_line(11, $credit_line->id,($credit_line->qty_dispatched
					-$credit_line->qty_old));
		}

		$line_taxfree_price = get_tax_free_price_for_item($credit_line->stock_id, $credit_line->price,
		  0, $credit_note->tax_included, $credit_note->tax_group_array);

		$line_tax = get_full_price_for_item($credit_line->stock_id, $credit_line->price,
		  0, $credit_note->tax_included, $credit_note->tax_group_array) - $line_taxfree_price;

		write_customer_trans_detail_item(11, $credit_no, $credit_line->stock_id,
			$credit_line->item_description, $credit_line->qty_dispatched,
			$credit_line->line_price(), $line_tax, $credit_line->discount_percent,
			$credit_line->standard_cost, $trans_no==0 ? 0:  $credit_line->id);

		add_credit_movements_item($credit_note, $credit_line,
			$credit_type, $line_taxfree_price+$line_tax, $credit_invoice);

		add_gl_trans_credit_costs($credit_note, $credit_line, $credit_no,
		    $credit_date, $credit_type, $write_off_acc, $branch_data);
	} /*end of credit_line loop */

	/*Post credit note transaction to GL credit debtors,
	debit freight re-charged and debit sales */

	if (($credit_note_total + $credit_note->freight_cost) != 0) {

		add_gl_trans_customer(11, $credit_no, $credit_date, $branch_data["receivables_account"], 0, 0,
			-($credit_note_total + $credit_note->freight_cost + $items_added_tax + $freight_added_tax),
			$credit_note->customer_id,
			"The total debtor GL posting for the credit note could not be inserted");
	}

	if ($credit_note->freight_cost !=0) {
		add_gl_trans_customer(11, $credit_no, $credit_date, $company_data["freight_act"], 0, 0,
			$credit_note->get_tax_free_shipping(), $credit_note->customer_id,
			"The freight GL posting for this credit note could not be inserted");
	}

	foreach ($taxes as $taxitem) {
		if ($taxitem['Value'] != 0) {

			add_customer_trans_tax_detail_item(11, $credit_no, $taxitem['tax_type_id'],
				$taxitem['rate'], $credit_note->tax_included, $taxitem['Value']);

			add_gl_trans_customer(11, $credit_no, $credit_date, $taxitem['sales_gl_code'], 0, 0,
				$taxitem['Value'], $credit_note->customer_id,
				"A tax GL posting for this credit note could not be inserted");
		}
	}

	add_comments(11, $credit_no, $credit_date, $credit_note->Comments);

	if ($trans_no == 0) {
		references::save_last($credit_note->reference, 11);
	}

	commit_transaction();

	return $credit_no;
}

//----------------------------------------------------------------------------------------
// Insert a stock movement coming back in to show the credit note and
// 	a reversing stock movement to show the write off
//
function add_credit_movements_item(&$credit_note, &$credit_line,
	$credit_type, $price, $credited_invoice=0)
{

	if ($credit_type == "Return") {

		$reference = "Return ";
		if ($credited_invoice) {
			$reference .= "Ex Inv: " . $credited_invoice;
		}

	} elseif ($credit_type == "WriteOff") {

		$reference = "WriteOff ";
		if ($credited_invoice)
			$reference .= "Ex Inv: " . $credited_invoice;

	add_stock_move_customer(11,  $credit_line->stock_id,
		key($credit_note->trans_no), $credit_note->Location,
		$credit_note->document_date, $reference, -$credit_line->qty_dispatched,
		$credit_line->standard_cost,  0, $price,
		$credit_line->discount_percent);

		}
	add_stock_move_customer(11,  $credit_line->stock_id,
		key($credit_note->trans_no), $credit_note->Location,
		$credit_note->document_date, $reference, $credit_line->qty_dispatched,
		$credit_line->standard_cost,  0, $price,
		$credit_line->discount_percent);

	}

//----------------------------------------------------------------------------------------

function add_gl_trans_credit_costs($order, $order_line, $credit_no, $date_,
	$credit_type, $write_off_gl_code, &$branch_data)
{
	$stock_gl_codes = get_stock_gl_code($order_line->stock_id);

	/* insert gl_trans to credit stock and debit cost of sales at standard cost*/
	if ($order_line->standard_cost != 0) {
		/*first the cost of sales entry*/

		add_gl_trans_std_cost(11, $credit_no, $date_, $stock_gl_codes["cogs_account"],
			$stock_gl_codes["dimension_id"], $stock_gl_codes["dimension2_id"], "",
			-($order_line->standard_cost * $order_line->qty_dispatched),
			payment_person_types::customer(), $order->customer_id,
			"The cost of sales GL posting could not be inserted");

		/*now the stock entry*/
		if ($credit_type == "WriteOff") {
			$stock_entry_account = $write_off_gl_code;
		} else {
			$stock_gl_code = get_stock_gl_code($order_line->stock_id);
			$stock_entry_account = $stock_gl_code["inventory_account"];
		}

		add_gl_trans_std_cost(11, $credit_no, $date_, $stock_entry_account, 0, 0,
			"", ($order_line->standard_cost * $order_line->qty_dispatched),
			payment_person_types::customer(), $order->customer_id,
			"The stock side (or write off) of the cost of sales GL posting could not be inserted");

	} /* end of if GL and stock integrated and standard cost !=0 */

	if ($order_line->line_price() != 0) {

		$line_taxfree_price =
		get_tax_free_price_for_item($order_line->stock_id, $order_line->price,
		  0, $order->tax_included, $order->tax_group_array);

		$line_tax = get_full_price_for_item($order_line->stock_id, $order_line->price,
		  0, $order->tax_included, $order->tax_group_array) - $line_taxfree_price;


		//Post sales transaction to GL credit sales

		add_gl_trans_customer(11, $credit_no, $date_, $stock_gl_codes["sales_account"], 0, 0,
			($line_taxfree_price * $order_line->qty_dispatched), $order->customer_id,
			"The credit note GL posting could not be inserted");

		if ($order_line->discount_percent != 0) {

			add_gl_trans_customer(11, $credit_no, $date_, $branch_data["sales_discount_account"], 0, 0,
				-($line_taxfree_price * $order_line->qty_dispatched * $order_line->discount_percent),
				$order->customer_id,
				"The credit note discount GL posting could not be inserted");

		} /*end of if discount !=0 */
	} /*if line_price!=0 */
}

?>