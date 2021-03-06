<?php

include_once($path_to_root . "/includes/prefs/sysprefs.inc");
include_once($path_to_root . "/inventory/includes/inventory_db.inc");

class items_cart
{

	var $line_items;
	var $gl_items;

	var $gl_item_count;

	var	$order_id;

	var $editing_item, $deleting_item;

	var $from_loc;
	var $to_loc;
	var $tran_date;
	var $transfer_type;
	var $increase;
	var $memo_;
	var $person_id;
	var $branch_id;

	function items_cart()
	{
		$this->clear_items();
	}

	// --------------- line item functions

	function add_to_cart($stock_id, $date_from,$qty,$standard_cost,$description=null,$date_from)
	{
		if (isset($stock_id) && $stock_id != "" && isset($qty))
		{
			$this->line_items[$stock_id] = new line_item($stock_id, $qty,
				$standard_cost, $description,$date_from);
			$this->clear_editing_flags();
			return true;
		}
		else
		{
			// shouldn't come here under normal circumstances
			display_db_error("unexpected - adding an invalid item or null quantity", "", true);
		}

		return false;
	}

	function find_cart_item($stock_id)
	{
		if (isset($this->line_items[$stock_id]) && $this->line_items[$stock_id] != null)
			return $this->line_items[$stock_id];
		return null;
	}

	function update_cart_item($update_item, $qty, $standard_cost,$date_from)
	{
		$this->line_items[$update_item]->quantity = $qty;
		$this->line_items[$update_item]->standard_cost = $standard_cost;
		$this->line_items[$update_item]->date_from = $date_from;
		$this->clear_editing_flags();
	}

	function remove_from_cart(&$stock_id)
	{
		if (isset($stock_id))
		{
			unset($this->line_items[$stock_id]);
			$this->clear_editing_flags();
		}
	}

	function count_items()
	{
		return count($this->line_items);
	}

	function check_qoh($location, $date_, $reverse=false)
	{
		foreach ($this->line_items as $line_item)
		{
			$item_ret = $line_item->check_qoh($location, $date_, $reverse);
			if ($item_ret != null)
				return $line_item;
		}
	}

	// ----------- GL item functions

	function add_gl_item($code_id, $dimension_id, $dimension2_id, $amount, $reference, $description=null)
	{
		if (isset($code_id) && $code_id != "" && isset($amount) && isset($dimension_id)  &&
			isset($dimension2_id))
		{
			$this->gl_items[$this->gl_item_count] = new gl_item($this->gl_item_count,
				$code_id, $dimension_id, $dimension2_id, $amount, $reference, $description);
			$this->gl_item_count++;
			$this->clear_editing_flags();
			return true;
		}
		else
		{
			// shouldn't come here under normal circumstances
			display_db_error("unexpected - adding an invalid item or null quantity", "", true);
		}

		return false;
	}

	function update_gl_item($index, $dimension_id, $dimension2_id, $amount, $reference, $description=null)
	{
		$this->gl_items[$index]->index = $index;
		$this->gl_items[$index]->dimension_id = $dimension_id;
		$this->gl_items[$index]->dimension2_id = $dimension2_id;
		$this->gl_items[$index]->amount = $amount;
		$this->gl_items[$index]->reference = $reference;
		if ($description != null)
			$this->gl_items[$index]->description = $description;

		$this->clear_editing_flags();
	}

	function remove_gl_item($index)
	{
		if (isset($index))
		{
			unset($this->gl_items[$index]);
			$this->clear_editing_flags();
		}
	}

	function count_gl_items()
	{
		return count($this->gl_items);
	}

	function gl_items_total()
	{
		$total = 0;
		foreach ($this->gl_items as $gl_item)
			$total += $gl_item->amount;
		return $total;
	}

	function gl_items_total_debit()
	{
		$total = 0;
		foreach ($this->gl_items as $gl_item)
		{
			if ($gl_item->amount > 0)
				$total += $gl_item->amount;
		}
		return $total;
	}

	function gl_items_total_credit()
	{
		$total = 0;
		foreach ($this->gl_items as $gl_item)
		{
			if ($gl_item->amount < 0)
				$total += $gl_item->amount;
		}
		return $total;
	}

	// ------------ common functions

	function clear_items()
	{
    	unset($this->line_items);
		$this->line_items = array();

    	unset($this->gl_items);
		$this->gl_items = array();
		$this->gl_item_count = 1;

		$this->clear_editing_flags();
	}

	function clear_editing_flags()
	{
		$this->editing_item = $this->deleting_item = 0;
	}

	function get_editing_item()
	{
		return $this->editing_item;
	}

	function get_deleting_item()
	{
		return $this->deleting_item;
	}

	function is_editing_item($index)
	{
		return ($this->editing_item > 0) && ($this->editing_item == $index);
	}

	function is_deleting_item($index)
	{
		return ($this->deleting_item > 0) && ($this->deleting_item == $index);
	}

}

//--------------------------------------------------------------------------------------------

class line_item
{
	var $stock_id;
	var $item_description;
	var $units;
	var $mb_flag;

	var $quantity;
	var $price;
	var $standard_cost;
	var $date_from;

	function line_item ($stock_id, $qty, $standard_cost=null,$description=null,$date_from)
	{
		$item_row = get_item($stock_id);

		if ($item_row == null)
			display_db_error("invalid item added to order : $stock_id", "");

		$this->mb_flag = $item_row["mb_flag"];
		$this->units = $item_row["units"];

		if ($description == null)
			$this->item_description = $item_row["description"];
		else
			$this->item_description = $description;

		if ($standard_cost == null)
			$this->standard_cost = $item_row["actual_cost"];
		else
			$this->standard_cost = $standard_cost;

		$this->stock_id = $stock_id;
		$this->quantity = $qty;
		$this->date_from = $date_from;
		//$this->price = $price;
		$this->price = 0;
	}

	function check_qoh($location, $date_, $reverse)
	{
    	if (!sys_prefs::allow_negative_stock())
    	{
			if (has_stock_holding($this->mb_flag))
			{
				$quantity = $this->quantity;
				if ($reverse)
					$quantity = -$this->quantity;

				if ($quantity >= 0)
					return null;

				$qoh = get_qoh_on_date($this->stock_id, $location, $date_);
        		if ($quantity + $qoh < 0)
        		{
        			return $this;
        		}
    		}
    	}

    	return null;
	}
}

//---------------------------------------------------------------------------------------

class gl_item
{

	var $index;
	var $code_id;
	var $dimension_id;
	var $dimension2_id;
	var $amount;
	var $reference;
	var $description;

	function gl_item($index, $code_id, $dimension_id, $dimension2_id, $amount, $reference,
		$description=null)
	{
		//echo "adding $index, $code_id, $dimension_id, $amount, $reference<br>";

		if ($description == null)
			$this->description = get_gl_account_name($code_id);
		else
			$this->description = $description;

		$this->index = $index;
		$this->code_id = $code_id;
		$this->dimension_id = $dimension_id;
		$this->dimension2_id = $dimension2_id;
		$this->amount = $amount;
		$this->reference = $reference;
	}
}

//---------------------------------------------------------------------------------------

?>
