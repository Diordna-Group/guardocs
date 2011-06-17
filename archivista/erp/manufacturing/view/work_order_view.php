<?php

$page_security = 10;
$path_to_root="../..";

include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/manufacturing.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/manufacturing/includes/manufacturing_db.inc");
include_once($path_to_root . "/manufacturing/includes/manufacturing_ui.inc");
$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(800, 500);
page(tr("View Work Order"), true, false, "", $js);

//-------------------------------------------------------------------------------------------------
$woid = 0;
if ($_GET['trans_no'] != "") 
{	
	$woid = $_GET['trans_no'];
}

display_heading(systypes::name(systypes::work_order()) . " # " . $woid);

$myrow = get_work_order($woid);

if ($myrow["type"]  == wo_types::advanced())
	display_wo_details($woid, true);
else
	display_wo_details_quick($woid, true);

echo "<center>";

// display the WO requirements 
echo "<br>";
if ($myrow["released"] == false) 
{	
    display_heading2(tr("BOM for item:") . " " . $myrow["StockItemName"]);
    display_bom($myrow["stock_id"]);
} 
else 
{
	display_heading2(tr("Work Order Requirements"));		
	display_wo_requirements($woid, $myrow["units_reqd"]);
	if ($myrow["type"] == wo_types::advanced()) 
	{	
    	echo "<br><table cellspacing=7><tr valign=top><td>";
    	display_heading2(tr("Issues"));		
    	display_wo_issues($woid);
    	echo "</td><td>";
    	display_heading2(tr("Productions"));
    	display_wo_productions($woid);
    	echo "</td><td>";
    	display_heading2(tr("Payments"));
    	display_wo_payments($woid);	
    	echo "</td></tr></table>";
	}		
}

echo "<br>";

is_voided_display(systypes::work_order(), $woid, tr("This work order has been voided."));

end_page(true);

?>
