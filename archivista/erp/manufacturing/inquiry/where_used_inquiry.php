<?php

$page_security = 2;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

page(tr("Inventory Item Where Used Inquiry"));

//include($path_to_root . "/includes/date_functions.inc");
include($path_to_root . "/includes/ui.inc");

check_db_has_stock_items(tr("There are no items defined in the system."));

start_form(false, true);

if (!isset($_POST['stock_id']))
	$_POST['stock_id'] = get_global_stock_item();

echo "<center>" . tr("Select an item to display its parent item(s).") . "&nbsp;";
stock_items_list('stock_id', $_POST['stock_id'], false, true);
echo "<hr><center>";

set_global_stock_item($_POST['stock_id']);

if (isset($_POST['stock_id'])) 
{
    $sql = "SELECT bom.*,stock_master.description,workcentres.name As WorkCentreName, locations.location_name
		FROM bom, stock_master, workcentres, locations
		WHERE bom.parent = stock_master.stock_id AND bom.workcentre_added = workcentres.id
		AND bom.loc_code = locations.loc_code
		AND bom.component='" . $_POST['stock_id'] . "'";

    $result = db_query($sql,"No parent items were returned");

   	if (db_num_rows($result) == 0) 
   	{
   		display_note(tr("The selected item is not used in any BOMs."));
   	} 
   	else 
   	{

        start_table("$table_style width=80%");

        $th = array(tr("Parent Item"), tr("Work Centre"), tr("Location"), tr("Quantity Required"));
        table_header($th);

		$k = $j = 0;
        while ($myrow = db_fetch($result)) 
        {

			alt_table_row_color($k);

    		$select_item = $path_to_root . "/manufacturing/manage/bom_edit.php?" . SID . "stock_id=" . $myrow["parent"];

        	label_cell("<a href='$select_item'>" . $myrow["parent"]. " - " . $myrow["description"]. "</a>");
        	label_cell($myrow["WorkCentreName"]);
        	label_cell($myrow["location_name"]);
        	label_cell(qty_format($myrow["quantity"]));
			end_row();
			
        	$j++;
        	If ($j == 12)
        	{
        		$j = 1;
        		table_header($th);
        	}
        //end of page full new headings if
        }

        end_table();
   	}
}

end_form();
end_page();

?>