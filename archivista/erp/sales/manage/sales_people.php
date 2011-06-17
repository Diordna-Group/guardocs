<?php

$page_security = 3;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

page(tr("Sales Persons"));

include($path_to_root . "/includes/ui.inc");

if (isset($_GET['selected_id']))
{
	$selected_id = strtoupper($_GET['selected_id']);
}
elseif (isset($_POST['selected_id']))
{
	$selected_id = strtoupper($_POST['selected_id']);
}

//------------------------------------------------------------------------------------------------

if (isset($_POST['ADD_ITEM']) || isset($_POST['UPDATE_ITEM']))
{

	//initialise no input errors assumed initially before we test
	$input_error = 0;

	if (strlen($_POST['salesman_name']) == 0)
	{
		$input_error = 1;
		display_error(tr("The sales person name cannot be empty."));
	}
	$pr1 = check_num('provision', 0,100);
	if (!$pr1 || !check_num('provision2', 0, 100)) {
		$input_error = 1;
		display_error( tr("Salesman provision cannot be less than 0 or more than 100%."));
		set_focus(!$pr1 ? 'provision' : 'provision2');
	}
	if (!check_num('break_pt', 0)) {
		$input_error = 1;
		display_error( tr("Salesman provision breakpoint must be numeric and not less than 0."));
		set_focus('break_pt');
	}
	if ($input_error != 1)
	{
    	if (isset($selected_id))
    	{
    		/*selected_id could also exist if submit had not been clicked this code would not run in this case cos submit is false of course  see the delete code below*/

    		$sql = "UPDATE salesman SET salesman_name=".db_escape($_POST['salesman_name']) . ",
    			salesman_phone=".db_escape($_POST['salesman_phone']) . ",
    			salesman_fax=".db_escape($_POST['salesman_fax']) . ",
    			salesman_email=".db_escape($_POST['salesman_email']) . ",
    			provision=".input_num('provision').",
    			break_pt=".input_num('break_pt').",
    			provision2=".input_num('provision2')."
    			WHERE salesman_code = '$selected_id'";
    	}
    	else
    	{
    		/*Selected group is null cos no item selected on first time round so must be adding a record must be submitting new entries in the new Sales-person form */
    		$sql = "INSERT INTO salesman (salesman_name, salesman_phone, salesman_fax, salesman_email,
    			provision, break_pt, provision2)
    			VALUES (".db_escape($_POST['salesman_name']) . ", "
				  .db_escape($_POST['salesman_phone']) . ", "
				  .db_escape($_POST['salesman_fax']) . ", "
				  .db_escape($_POST['salesman_email']) . ", ".
    			input_num('provision').", ".input_num('break_pt').", "
				.input_num('provision2').")";
    	}

    	//run the sql from either of the above possibilites
    	db_query($sql,"The insert or update of the salesperson failed");

		meta_forward($_SERVER['PHP_SELF']);
	}
}
if (isset($_GET['delete']))
{
	//the link to delete a selected record was clicked instead of the submit button

	// PREVENT DELETES IF DEPENDENT RECORDS IN 'debtors_master'

	$sql= "SELECT COUNT(*) FROM cust_branch WHERE salesman='$selected_id'";
	$result = db_query($sql,"check failed");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0)
	{
		display_error("Cannot delete this sales-person because branches are set up referring to this sales-person - first alter the branches concerned.");
	}
	else
	{
		$sql="DELETE FROM salesman WHERE salesman_code='$selected_id'";
		db_query($sql,"The sales-person could not be deleted");

		meta_forward($_SERVER['PHP_SELF']);
	}
}

//------------------------------------------------------------------------------------------------

$sql = "SELECT * FROM salesman";
$result = db_query($sql,"could not get sales persons");

start_table("$table_style width=60%");
$th = array(tr("Name"), tr("Phone"), tr("Fax"), tr("Email"), tr("Provision"), tr("Break Pt."), tr("Provision")." 2", "", "");
table_header($th);

$k = 0;

while ($myrow = db_fetch($result))
{

	alt_table_row_color($k);

    label_cell($myrow["salesman_name"]);
   	label_cell($myrow["salesman_phone"]);
   	label_cell($myrow["salesman_fax"]);
   	label_cell($myrow["salesman_email"]);
	label_cell(percent_format($myrow["provision"])." %", "nowrap align=right");
   	amount_cell($myrow["break_pt"]);
	label_cell(percent_format($myrow["provision2"])." %", "nowrap align=right");
	edit_link_cell(SID . "selected_id=" . $myrow["salesman_code"]);
   	delete_link_cell(SID . "selected_id=" . $myrow["salesman_code"]. "&delete=1");
  	end_row();

} //END WHILE LIST LOOP

end_table();

//------------------------------------------------------------------------------------------------

hyperlink_no_params($_SERVER['PHP_SELF'], tr("New Sales Person"));

//------------------------------------------------------------------------------------------------

start_form();

if (isset($selected_id))
{
	//editing an existing Sales-person
	$sql = "SELECT *  FROM salesman WHERE salesman_code='$selected_id'";

	$result = db_query($sql,"could not get sales person");
	$myrow = db_fetch($result);

	$_POST['salesman_name'] = $myrow["salesman_name"];
	$_POST['salesman_phone'] = $myrow["salesman_phone"];
	$_POST['salesman_fax'] = $myrow["salesman_fax"];
	$_POST['salesman_email'] = $myrow["salesman_email"];
	$_POST['provision'] = percent_format($myrow["provision"]);
	$_POST['break_pt'] = price_format($myrow["break_pt"]);
	$_POST['provision2'] = percent_format($myrow["provision2"]);

	hidden('selected_id', $selected_id);
}

start_table("$table_style2 width=60%");

text_row_ex(tr("Sales person name:"), 'salesman_name', 30);
text_row_ex(tr("Telephone number:"), 'salesman_phone', 20);
text_row_ex(tr("Fax number:"), 'salesman_fax', 20);
text_row_ex(tr("Email:"), 'salesman_email', 40);
percent_row(tr("Provision"), 'provision');
amount_row(tr("Break Pt.:"), 'break_pt');
percent_row(tr("Provision")." 2", 'provision2');
end_table(1);

submit_add_or_update_center(!isset($selected_id));

end_form();

end_page();

?>
