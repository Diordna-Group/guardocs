<?php

//---------------------------------------------------------------------------------------------------

function display_grn_summary(&$po, $editable=false)
{
	global $table_style2;
    start_table("$table_style2 width=90%");
    
    start_row();
	label_cells(tr("Supplier"), $po->supplier_name, "class='tableheader2'");
    
    if (!is_company_currency($po->curr_code))
    	label_cells(tr("Order Currency"), $po->curr_code, "class='tableheader2'");
    
    label_cells(tr("For Purchase Order"), get_trans_view_str(systypes::po(), $po->order_no),
    	"class='tableheader2'");
    
	label_cells(tr("Ordered On"), $po->orig_order_date, "class='tableheader2'");
	label_cells(tr("Supplier's Reference"), $po->requisition_no, "class='tableheader2'");
	end_row();
		
   	start_row();
    if ($editable) 
    {
    	if (!isset($_POST['ref']))
    	    $_POST['ref'] = references::get_next(25);
    	ref_cells(tr("Reference"), 'ref', null, "class='tableheader2'");
    	    	
        if (!isset($_POST['Location']))
        	$_POST['Location'] = $po->Location;
        label_cell(tr("Deliver Into Location"), "class='tableheader2'");
        locations_list_cells(null, "Location", $_POST['Location']);
        
    	if (!isset($_POST['DefaultReceivedDate']))
     	  	$_POST['DefaultReceivedDate'] = Today();
    	
    	date_cells(tr("Date Items Received"), 'DefaultReceivedDate', null, 0, 0, 0, "class='tableheader2'");    
        
    } 
    else 
    {
    	label_cells(tr("Reference"), $po->reference, "class='tableheader2'");
    	label_cells(tr("Deliver Into Location"), get_location_name($po->Location), "class='tableheader2'");
    }
    
    end_row();
    
    if (!$editable)
    
    	label_row(tr("Delivery Address"), $po->delivery_address, "class='tableheader2'", "colspan=9");
    
    if ($po->Comments != "")
    	label_row(tr("Order Comments"), $po->Comments, "class='tableheader2'", "colspan=9");
    end_table(1);	
}

?>