<?php

$page_security = 8;
$path_to_root="../..";

include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/includes/data_checks.inc");

include_once($path_to_root . "/gl/includes/gl_db.inc");

$js = "";
if ($use_date_picker)
	$js = get_js_date_picker();

page(tr("Trial Balance"), false, false, "", $js);

//----------------------------------------------------------------------------------------------------


function gl_inquiry_controls()
{
    start_form();

    start_table("class='tablestyle_noborder'");

    date_cells(tr("From:"), 'TransFromDate', null, -30);
	date_cells(tr("To:"), 'TransToDate');
	check_cells(tr("No zero values"), 'NoZero', null);

    submit_cells('Show',tr("Show"));
    end_table();
    end_form();
}

//----------------------------------------------------------------------------------------------------

function get_balance($account, $from, $to, $from_incl=true, $to_incl=true) {

	$sql = "SELECT SUM(amount) As TransactionSum FROM gl_trans
		WHERE account='$account'";

	if ($from)
	{
		$from_date = date2sql($from);
		if ($from_incl)
			$sql .= " AND tran_date >= '$from_date'";
		else
			$sql .= " AND tran_date > '$from_date'";
	}

	if ($to)
	{
		$to_date = date2sql($to);
		if ($to_incl)
			$sql .= " AND tran_date <= '$to_date' ";
		else
			$sql .= " AND tran_date < '$to_date' ";
	}

	$result = db_query($sql,"No general ledger accounts were returned");

	$row = db_fetch_row($result);
	return $row[0];
}

//----------------------------------------------------------------------------------------------------

function display_trial_balance()
{
	global $table_style, $path_to_root;

	start_table($table_style);
	$tableheader =  "<tr>
        <td rowspan=2 class='tableheader'>" . tr("Account") . "</td>
        <td rowspan=2 class='tableheader'>" . tr("Account Name") . "</td>
		<td colspan=2 class='tableheader'>" . tr("Brought Forward") . "</td>
		<td colspan=2 class='tableheader'>" . tr("This Period") . "</td>
		<td colspan=2 class='tableheader'>" . tr("Balance") . "</td>
		</tr><tr>
		<td class='tableheader'>" . tr("Debit") . "</td>
        <td class='tableheader'>" . tr("Credit") . "</td>
		<td class='tableheader'>" . tr("Debit") . "</td>
		<td class='tableheader'>" . tr("Credit") . "</td>
        <td class='tableheader'>" . tr("Debit") . "</td>
        <td class='tableheader'>" . tr("Credit") . "</td>
        </tr>";

    echo $tableheader;

	$k = 0;

	$accounts = get_gl_accounts();

	while ($account = db_fetch($accounts))
	{
		if (is_account_balancesheet($account["account_code"]))
			$begin = null;
		else
		{
			$begin = begin_fiscalyear();
			if ($_POST['TransFromDate'] < $begin)
				$begin = $_POST['TransFromDate'];
			$begin = add_days($begin, -1);
		}
		$prev_balance = get_balance($account["account_code"], $begin, $_POST['TransFromDate'], false, false);

		$curr_balance = get_balance($account["account_code"], $_POST['TransFromDate'], $_POST['TransToDate']);
		if (check_value("NoZero") && !$prev_balance && !$curr_balance)
			continue;
		alt_table_row_color($k);

		$url = "<a href='$path_to_root/gl/inquiry/gl_account_inquiry.php?" . SID . "TransFromDate=" . $_POST["TransFromDate"] . "&TransToDate=" . $_POST["TransToDate"] . "&account=" . $account["account_code"] . "'>" . $account["account_code"] . "</a>";

		label_cell($url);
		label_cell($account["account_name"]);

		display_debit_or_credit_cells($prev_balance);
		display_debit_or_credit_cells($curr_balance);
		display_debit_or_credit_cells($prev_balance + $curr_balance);
		end_row();
	}

	end_table(1);

}

//----------------------------------------------------------------------------------------------------

gl_inquiry_controls();

display_trial_balance();

//----------------------------------------------------------------------------------------------------

end_page();

?>

