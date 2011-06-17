<?php


function add_gl_account($account_code, $account_name, $account_type, $account_code2, $tax_code)
{
	$account_name = db_escape($account_name);
	$sql = "INSERT INTO chart_master (account_code, account_code2, account_name, account_type,
		tax_code)
		VALUES (".db_escape($account_code).", ".db_escape($account_code2).", $account_name, $account_type, $tax_code)";

	db_query($sql, "could not add gl account");
}

function update_gl_account($account_code, $account_name, $account_type, $account_code2, $tax_code)
{
	$account_name = db_escape($account_name);
    $sql = "UPDATE chart_master SET account_name=$account_name,
		account_type=$account_type, account_code2=".db_escape($account_code2).",
		tax_code=$tax_code WHERE account_code = '$account_code'";

	db_query($sql, "could not update gl account");
}

function delete_gl_account($code)
{
	$sql = "DELETE FROM chart_master WHERE account_code='$code'";

	db_query($sql, "could not delete gl account");
}

function get_gl_accounts($from=null, $to=null)
{
	$sql = "SELECT chart_master.*,chart_types.name AS AccountTypeName
		FROM chart_master,chart_types
		WHERE chart_master.account_type=chart_types.id";
	if ($from != null)
		$sql .= " AND chart_master.account_code >= '$from'";
	if ($to != null)
		$sql .= " AND chart_master.account_code <= '$to'";
	$sql .= " ORDER BY account_code";

	return db_query($sql, "could not get gl accounts");
}

function get_gl_accounts_all($balance=-1)
{
	$sql = "SELECT chart_master.*,chart_types.name AS AccountTypeName,chart_class.class_name AS AccountClassName
		FROM chart_master,chart_types, chart_class
		WHERE chart_master.account_type=chart_types.id AND
		chart_types.class_id=chart_class.cid";
	if ($balance != -1)
		$sql .= " AND chart_class.balance_sheet=$balance";
	$sql .= " ORDER BY chart_class.cid, chart_types.id, chart_master.account_code";

	return db_query($sql, "could not get gl accounts");
}

function get_gl_account($code)
{
	$sql = "SELECT * FROM chart_master WHERE account_code='$code'";

	$result = db_query($sql, "could not get gl account");
	return db_fetch($result);
}

function is_account_balancesheet($code)
{
	$sql = "SELECT chart_class.balance_sheet FROM chart_class, chart_types, chart_master
		WHERE chart_master.account_type=chart_types.id AND
		chart_types.class_id=chart_class.cid
		AND chart_master.account_code='$code'";

	$result = db_query($sql,"could not retreive the account class for $code");
	$row = db_fetch_row($result);
	return $row[0];
}

function get_gl_account_name($code)
{
	$sql = "SELECT account_name from chart_master WHERE account_code='$code'";

	$result = db_query($sql,"could not retreive the account name for $code");

	if (db_num_rows($result) == 1)
	{
		$row = db_fetch_row($result);
		return $row[0];
	}

	display_db_error("could not retreive the account name for $code", $sql, true);
}


?>
