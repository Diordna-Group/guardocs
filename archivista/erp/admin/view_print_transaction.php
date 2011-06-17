<?php

$path_to_root="..";
$page_security = 5;

include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/reporting/includes/reporting.inc");
$js = "";
if ($use_popup_windows)
	$js .= get_js_open_window(800, 500);
page(tr("View or Print Transactions"), false, false, "", $js);

//----------------------------------------------------------------------------------------

function viewing_controls()
{
	display_note(tr("Only documents can be printed."));
    start_form(false, true);

    start_table("class='tablestyle_noborder'");
	start_row();

	systypes_list_cells(tr("Type:"), 'filterType', null, true);

	if (!isset($_POST['FromTransNo']))
		$_POST['FromTransNo'] = "1";
	if (!isset($_POST['ToTransNo']))
		$_POST['ToTransNo'] = "999999";

    ref_cells(tr("from #:"), 'FromTransNo');

    ref_cells(tr("to #:"), 'ToTransNo');

    submit_cells('ProcessSearch', tr("Search"));

	end_row();
    end_table(1);

	end_form();
}

//----------------------------------------------------------------------------------------

function check_valid_entries()
{
	if (!is_numeric($_POST['FromTransNo']) OR $_POST['FromTransNo'] <= 0)
	{
		display_note(tr("The starting transaction number is expected to be numeric and greater than zero."));
		return false;
	}

	if (!is_numeric($_POST['ToTransNo']) OR $_POST['ToTransNo'] <= 0)
	{
		echo tr("The ending transaction number is expected to be numeric and greater than zero.");
		return false;
	}
	if (!isset($_POST['filterType']) || $_POST['filterType'] == "")
		return false;

	return true;
}

//----------------------------------------------------------------------------------------

function handle_search()
{
	global $table_style;
	if (check_valid_entries()==true)
	{
		$db_info = get_systype_db_info($_POST['filterType']);

		if ($db_info == null)
			return;

		$table_name = $db_info[0];
		$type_name = $db_info[1];
		$trans_no_name = $db_info[2];
		$trans_ref = $db_info[3];

		$sql = "SELECT DISTINCT $trans_no_name ";

		if ($trans_ref)
			$sql .= " ,$trans_ref ";

		$sql .= " FROM $table_name
			WHERE $trans_no_name >= " . $_POST['FromTransNo']. "
			AND  $trans_no_name <= " . $_POST['ToTransNo'];

		if ($type_name != null)
			$sql .= " AND $type_name = " . $_POST['filterType'];

		$sql .= " ORDER BY $trans_no_name";

		$result = db_query($sql, "could not query transactions on $table_name");

		if (db_num_rows($result) == 0)
		{
			echo tr("There are no transactions for the given parameters.");
			return;
		}
		$print_type = $_POST['filterType'];
		$print_out = ($print_type == 10 || $print_type == 11 || $print_type == systypes::cust_dispatch() ||
			$print_type == systypes::po() || $print_type == systypes::sales_order());
		if ($print_out)
		{
			print_hidden_script($print_type);
			if ($trans_ref)
				$th = array(tr("#"), tr("Reference"), tr("View"), tr("Print"), tr("GL"));
			else
				$th = array(tr("#"), tr("View"), tr("Print"), tr("GL"));
		}
		else
		{
			if ($trans_ref)
				$th = array(tr("#"), tr("Reference"), tr("View"), tr("GL"));
			else
				$th = array(tr("#"), tr("View"), tr("GL"));
		}
		start_table($table_style);
		table_header($th);
		$k = 0;
		while ($line = db_fetch($result))
		{

			alt_table_row_color($k);

			label_cell($line[$trans_no_name]);
			if ($trans_ref)
				label_cell($line[$trans_ref]);
			label_cell(get_trans_view_str($_POST['filterType'],$line[$trans_no_name], tr("View")));
			if ($print_out)
				label_cell(print_document_link($line[$trans_no_name], tr("Print"), true,	$print_type));
        	label_cell(get_gl_view_str($_POST['filterType'], $line[$trans_no_name], tr("View GL")));

	    	end_row();

		}

		end_table();
	}
}

//----------------------------------------------------------------------------------------

if (isset($_POST['ProcessSearch']))
{
	if (!check_valid_entries())
		unset($_POST['ProcessSearch']);
}

//----------------------------------------------------------------------------------------

viewing_controls();

handle_search();

br(2);

end_page();

?>
