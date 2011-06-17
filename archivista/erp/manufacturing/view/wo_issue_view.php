<?php

$page_security = 10;
$path_to_root="../..";
include_once($path_to_root . "/includes/session.inc");

page(tr("View Work Order Issue"), true);

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/manufacturing.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/manufacturing/includes/manufacturing_db.inc");
include_once($path_to_root . "/manufacturing/includes/manufacturing_ui.inc");

//-------------------------------------------------------------------------------------------------

if ($_GET['trans_no'] != "") 
{
	$wo_issue_no = $_GET['trans_no'];
}

//-------------------------------------------------------------------------------------------------

function display_wo_issue($issue_no)
{
	global $table_style;

    $myrow = get_work_order_issue($issue_no);

    start_table($table_style);
    $th = array(tr("Issue #"), tr("Reference"), tr("For Work Order #"),
    	tr("Item"), tr("From Location"), tr("To Work Centre"), tr("Date of Issue"));
    table_header($th);	

	start_row();
	label_cell($myrow["issue_no"]);
	label_cell($myrow["reference"]);
	label_cell(get_trans_view_str(systypes::work_order(),$myrow["workorder_id"]));
	label_cell($myrow["stock_id"] . " - " . $myrow["description"]);
	label_cell($myrow["location_name"]);
	label_cell($myrow["WorkCentreName"]);
	label_cell(sql2date($myrow["issue_date"]));
	end_row();

    comments_display_row(28, $issue_no);

	end_table(1);

	is_voided_display(28, $issue_no, tr("This issue has been voided."));
}

//-------------------------------------------------------------------------------------------------

function display_wo_issue_details($issue_no)
{
	global $table_style;

    $result = get_work_order_issue_details($issue_no);

    if (db_num_rows($result) == 0)
    {
    	echo "<br>" . tr("There are no items for this issue.");
    } 
    else 
    {
        start_table($table_style);
        $th = array(tr("Component"), tr("Quantity"), tr("Units"));

        table_header($th);

        $j = 1;
        $k = 0; //row colour counter

        $total_cost = 0;

        while ($myrow = db_fetch($result)) 
        {

			alt_table_row_color($k);

        	label_cell($myrow["stock_id"]  . " - " . $myrow["description"]);
            qty_cell($myrow["qty_issued"]);
			label_cell($myrow["units"]);
			end_row();;

        	$j++;
        	If ($j == 12)
        	{
        		$j = 1;
        		table_header($th);
        	}//end of page full new headings if
		}//end of while

		end_table();
    }
}

//-------------------------------------------------------------------------------------------------

display_heading(systypes::name(28) . " # " . $wo_issue_no);

display_wo_issue($wo_issue_no);

display_heading2(tr("Items for this Issue"));

display_wo_issue_details($wo_issue_no);

//-------------------------------------------------------------------------------------------------

echo "<br>";

end_page(true);

?>

