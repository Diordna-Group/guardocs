<?php

$page_security = 8;
$path_to_root="../..";
include_once($path_to_root . "/includes/session.inc");

page(tr("General Ledger Transaction Details"), true);

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");

include_once($path_to_root . "/gl/includes/gl_db.inc");

if (!isset($_GET['type_id']) || !isset($_GET['trans_no'])) 
{ /*Script was not passed the correct parameters */

	echo "<p>" . tr("The script must be called with a valid transaction type and transaction number to review the general ledger postings for.") . "</p>";
	exit;
}

function display_gl_heading($myrow)
{
	global $table_style;
	$trans_name = systypes::name($_GET['type_id']);
    start_table("$table_style width=95%");
    $th = array(tr("General Ledger Transaction Details"),
    	tr("Date"), tr("Person/Item"));
    table_header($th);	
    start_row();	
    label_cell("$trans_name #" . $_GET['trans_no']);
	label_cell(sql2date($myrow["tran_date"]));
	label_cell(payment_person_types::person_name($myrow["person_type_id"],$myrow["person_id"]));
	
	end_row();

	comments_display_row($_GET['type_id'], $_GET['trans_no']);

    end_table(1);
}

$sql = "SELECT gl_trans.*, account_name FROM gl_trans, chart_master WHERE gl_trans.account = chart_master.account_code AND type= " . $_GET['type_id'] . " AND type_no = " . $_GET['trans_no'] . " ORDER BY counter";
$result = db_query($sql,"could not get transactions");
//alert("sql = ".$sql);

if (db_num_rows($result) == 0)
{
    echo "<p><center>" . tr("No general ledger transactions have been created for") . " " .systypes::name($_GET['type_id'])." " . tr("number") . " " . $_GET['trans_no'] . "</center></p><br><br>";
	end_page(true);
	exit;
}

/*show a table of the transactions returned by the sql */
$dim = get_company_pref('use_dimension');

if ($dim == 2)
	$th = array(tr("Account Code"), tr("Account Name"), tr("Dimension")." 1", tr("Dimension")." 2",
		tr("Debit"), tr("Credit"), tr("Memo"));
else if ($dim == 1)
	$th = array(tr("Account Code"), tr("Account Name"), tr("Dimension"),
		tr("Debit"), tr("Credit"), tr("Memo"));
else		
	$th = array(tr("Account Code"), tr("Account Name"),
		tr("Debit"), tr("Credit"), tr("Memo"));
$k = 0; //row colour counter
$heading_shown = false;

while ($myrow = db_fetch($result)) 
{
	if (!$heading_shown)
	{
		display_gl_heading($myrow);
		start_table("$table_style width=95%");
		table_header($th);
		$heading_shown = true;
	}	

	alt_table_row_color($k);
	
    label_cell($myrow['account']);
	label_cell($myrow['account_name']);
	if ($dim >= 1)
		label_cell(get_dimension_string($myrow['dimension_id'], true));
	if ($dim > 1)
		label_cell(get_dimension_string($myrow['dimension2_id'], true));

	display_debit_or_credit_cells($myrow['amount']);
	label_cell($myrow['memo_']);
	end_row();

}
//end of while loop
if ($heading_shown)
	end_table(1);

is_voided_display($_GET['type_id'], $_GET['trans_no'], tr("This transaction has been voided."));

end_page(true);

?>
