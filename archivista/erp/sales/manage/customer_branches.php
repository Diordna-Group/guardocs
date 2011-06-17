<?php

$page_security = 3;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

page(tr("Customer Branches"));

include($path_to_root . "/includes/ui.inc");

//------------------------------------------------------------------

check_db_has_customers(tr("There are no customers defined in the system. Please define a customer to add customer branches."));

check_db_has_sales_people(tr("There are no sales people defined in the system. At least one sales person is required before proceeding."));

check_db_has_sales_areas(tr("There are no sales areas defined in the system. At least one sales area is required before proceeding."));

check_db_has_shippers(tr("There are no shipping companies defined in the system. At least one shipping company is required before proceeding."));

check_db_has_tax_groups(tr("There are no tax groups defined in the system. At least one tax group is required before proceeding."));

//------------------------------------------------------------------

if (isset($_GET['debtor_no'])) {
	$_POST['customer_id'] = strtoupper($_GET['debtor_no']);
	$_POST['New'] = "1";
}

if (isset($_GET['SelectedBranch'])) {
	$_POST['branch_code'] = strtoupper($_GET['SelectedBranch']);
	unset($_POST['New']);
}

if (!isset($_GET['SelectedBranch']) && !isset($_POST['AddUpdate'])) {
	$_POST['New'] = "1";
}

check_branches(); // we always want to have a branch (if possible)

//---------------------------------------------------------------------

if (isset($_POST['ADD_ITEM']) || isset($_POST['UPDATE_ITEM'])) {
	//initialise no input errors assumed initially before we test
	$input_error = 0;
	//first off validate inputs sensible
	if (strlen($_POST['br_name']) == 0) {
		$input_error = 1;
		display_error(tr("The Branch name cannot be empty."));
	}
	if ($input_error != 1) {
		if (isset($_POST['UPDATE_ITEM'])) {
			/*SelectedBranch could also exist if submit had not
			  been clicked this code would not run in this case 
				cos submit is false of course see the delete code below*/
			$sql = "UPDATE cust_branch SET br_name = " . 
	      db_escape($_POST['br_name']) . 
				",br_address = ".db_escape($_POST['br_address']). 
				",phone=".db_escape($_POST['phone']). 
				",fax=".db_escape($_POST['fax']).
				",contact_name=".db_escape($_POST['contact_name']).
				",salesman= ".db_escape($_POST['salesman']).
				",area=".db_escape($_POST['area']).
				",email=".db_escape($_POST['email']).
				",tax_group_id=".db_escape($_POST['tax_group_id']).
				",sales_account=".db_escape($_POST['sales_account']).
				",sales_discount_account=".db_escape($_POST['sales_discount_account']).
				",receivables_account=".db_escape($_POST['receivables_account']).
				",payment_discount_account=".
				db_escape($_POST['payment_discount_account']).
				",default_location=".db_escape($_POST['default_location']).
				",br_post_address =".db_escape($_POST['br_post_address']).
				",disable_trans=".db_escape($_POST['disable_trans']).
				",default_ship_via=".db_escape($_POST['default_ship_via']).
				",lang_code=".db_escape($_POST['lang_code'])." ".
				"WHERE branch_code =".db_escape($_POST['branch_code'])." ".
    	  "AND debtor_no=".db_escape($_POST['customer_id']);
		} else {
			/*Selected branch is null cos no item selected on first time
			  round so must be adding a	record must be submitting new 
				entries in the new Customer Branches form */
			$sql = "INSERT INTO cust_branch (debtor_no, br_name, br_address, ".
				"salesman, phone, fax, contact_name, area, email, tax_group_id, ".
				"sales_account, receivables_account, payment_discount_account, ".
				"sales_discount_account, default_location, br_post_address, ".
				"disable_trans, default_ship_via,lang_code) ".
				"VALUES (".db_escape($_POST['customer_id']).",".
				db_escape($_POST['br_name']).",".
				db_escape($_POST['br_address']).",".
				db_escape($_POST['salesman']).",".
				db_escape($_POST['phone']).",".
				db_escape($_POST['fax']).",".
				db_escape($_POST['contact_name']).",".
				db_escape($_POST['area']).",".
				db_escape($_POST['email']).",".
				db_escape($_POST['tax_group_id']).",". 
				db_escape($_POST['sales_account']).",".
				db_escape($_POST['receivables_account']).",".
				db_escape($_POST['payment_discount_account']).",".
				db_escape($_POST['sales_discount_account']).",".
				db_escape($_POST['default_location']).",".
				db_escape($_POST['br_post_address']).",".
				db_escape($_POST['disable_trans']).",".
				db_escape($_POST['default_ship_via']).",".
				db_escape($_POST['lang_code']).")"; 
		}
		//run the sql from either of the above possibilites
		db_query($sql,"The branch record could not be inserted or updated");
		meta_forward($_SERVER['PHP_SELF'], "debtor_no=" . $_POST['customer_id']);
	}
} elseif (isset($_GET['delete'])) {
	//the link to delete a selected record was clicked instead of
	// the submit button
	// PREVENT DELETES IF DEPENDENT RECORDS IN 'debtor_trans'
	$sql= "SELECT COUNT(*) FROM debtor_trans WHERE branch_code='".
	  $_POST['branch_code']."' AND debtor_no = '".$_POST['customer_id']. "'";
	$result = db_query($sql,"could not query debtortrans");
	$myrow = db_fetch_row($result);
	if ($myrow[0] > 0) {
		display_error(tr("Cannot delete this branch because customer transactions have been created to this branch."));
	} else {
		$sql= "SELECT COUNT(*) FROM sales_orders WHERE branch_code='".
		  $_POST['branch_code']."' AND debtor_no = '".$_POST['customer_id']."'";
		$result = db_query($sql,"could not query sales orders");
		$myrow = db_fetch_row($result);
		if ($myrow[0] > 0) {
			display_error(tr("Cannot delete this branch because sales orders exist for it. Purge old sales orders first."));
		} else {
			$sql="DELETE FROM cust_branch WHERE branch_code='".
			$_POST['branch_code']."' AND debtor_no='".$_POST['customer_id']."'";
			db_query($sql,"could not delete branch");
			meta_forward($_SERVER['PHP_SELF'],"debtor_no=".$_POST['customer_id']);
		}
	} //end ifs to test if the branch can be deleted
}

start_form();

echo "<center>" . tr("Select a customer: ") . "&nbsp;&nbsp;";
customer_list('customer_id', null, false, true);
echo "</center><br><br>";

check_branches(); // we always want to have a branch (if possible)

$num_branches = db_customer_has_branches($_POST['customer_id']);
if ($num_branches) {
	$sql = "SELECT debtors_master.name, cust_branch.*, salesman.salesman_name,".
		"areas.description, tax_groups.name AS tax_group_name ".
		"FROM cust_branch, debtors_master, areas, salesman, tax_groups ".
		"WHERE cust_branch.debtor_no=debtors_master.debtor_no ".
		"AND cust_branch.tax_group_id=tax_groups.id ".
		"AND cust_branch.area=areas.area_code ".
		"AND cust_branch.salesman=salesman.salesman_code ".
		"AND cust_branch.debtor_no = '" . $_POST['customer_id']. "'";
	$result = db_query($sql,"could not get customer branches");
	start_table("$table_style width=60%");
	$th = array(tr("Name"), tr("Contact"), tr("Sales Person"), tr("Area"),
		tr("Phone No"), tr("Fax No"), tr("E-mail"), tr("Tax Group"), "", "");
	table_header($th);	

	while ($myrow = db_fetch($result)) {
		start_row();
		label_cell($myrow["br_name"]);
		label_cell($myrow["contact_name"]);
		label_cell($myrow["salesman_name"]);
		label_cell($myrow["description"]);
		label_cell($myrow["phone"]);
		label_cell($myrow["fax"]);
		label_cell("<a href=mailto:".$myrow["email"].">".$myrow["email"]. "</a>");
		label_cell($myrow["tax_group_name"]);
		edit_link_cell("debtor_no=".$_POST['customer_id']."&SelectedBranch=".
		  $myrow["branch_code"]);
		delete_link_cell("debtor_no=".$_POST['customer_id']."&SelectedBranch=".
		  $myrow["branch_code"]. "&delete=yes");
		end_row();
	} 
	end_table();
	//END WHILE LIST LOOP
} else {
	display_note(tr("The selected customer does not have any branches. Please create at least one branch."));
}

if ($_POST['customer_id'] != "" && $_POST['branch_code'] != '') {
	hyperlink_params($_SERVER['PHP_SELF'],tr("New Customer Branch"),
	  "debtor_no=".$_POST['customer_id']);
}
echo "<br>";
start_table("$table_style2 width=60%", 5);
echo "<tr valign=top><td>"; // outer table
echo "<table>";

//editing an existing branch
$sql = "SELECT * FROM cust_branch WHERE branch_code='".
$_POST['branch_code']."' AND debtor_no='" . $_POST['customer_id'] . "'";
$result = db_query($sql,"check failed");
$myrow = db_fetch($result);
$_POST['branch_code'] = $myrow["branch_code"];
$_POST['br_name']  = $myrow["br_name"];
$_POST['br_address']  = $myrow["br_address"];
$_POST['br_post_address']  = $myrow["br_post_address"];
$_POST['contact_name'] = $myrow["contact_name"];
$_POST['salesman'] =$myrow["salesman"];
$_POST['area'] =$myrow["area"];
$_POST['phone'] =$myrow["phone"];
$_POST['fax'] =$myrow["fax"];
$_POST['email'] =$myrow["email"];
$_POST['tax_group_id'] = $myrow["tax_group_id"];
$_POST['disable_trans'] = $myrow['disable_trans'];
$_POST['default_location'] = $myrow["default_location"];
$_POST['default_ship_via'] = $myrow['default_ship_via'];
$_POST['lang_code'] = $myrow['lang_code'];
$_POST['sales_account'] = $myrow["sales_account"];
$_POST['sales_discount_account'] = $myrow['sales_discount_account'];
$_POST['receivables_account'] = $myrow['receivables_account'];
$_POST['payment_discount_account'] = $myrow['payment_discount_account'];

if (!isset($_POST['New']) && $num_branches) {
  // nothing to do
} else { 
	hidden('New', 'Yes');
}

hidden('branch_code', $_POST['branch_code']);

table_section_title(tr("Name and Contact"));
text_row(tr("Branch Name:"), 'br_name', $_POST['br_name'], 35, 40);
text_row(tr("Contact Person:"),'contact_name',$_POST['contact_name'],35,40);
text_row(tr("Phone Number:"), 'phone', null, 20, 20);
text_row(tr("Fax Number:"), 'fax', null, 20, 20);
text_row("<a href='Mailto:'>".tr("E-mail:")."</a>",'email',
  $_POST['email'], 35, 55);
table_section_title(tr("Sales"));
sales_persons_list_row( tr("Sales Person:"), 'salesman', null);
sales_areas_list_row( tr("Sales Area:"), 'area', null);
locations_list_row(tr("Default Inventory Location:"), 'default_location', null);
shippers_list_row(tr("Default Shipping Company:"), 'default_ship_via', null);
tax_groups_list_row(tr("Tax Group:"), 'tax_group_id', null, 31, 30);
language_list_row(tr("Language"), 'lang_code', null, 31, 30);
yesno_list_row(tr("Disable this Branch:"), 'disable_trans', null);
echo "</table>";

echo "</td><td  class='tableseparator'>"; // outer table

echo"<table>";
table_section_title(tr("GL Accounts"));
gl_all_accounts_list_row(tr("Sales Account:"), 'sales_account', 
  $_POST['sales_account']);
gl_all_accounts_list_row(tr("Sales Discount Account:"), 
  'sales_discount_account', $_POST['sales_discount_account']);
gl_all_accounts_list_row(tr("Accounts Receivable Account:"), 
  'receivables_account', $_POST['receivables_account']);
gl_all_accounts_list_row(tr("Prompt Payment Discount Account:"), 
  'payment_discount_account', $_POST['payment_discount_account']);
table_section_title(tr("Addresses"));
textarea_row(tr("Mailing Address:"), 'br_post_address',
  $_POST['br_post_address'], 35, 5);
textarea_row(tr("Billing Address:"), 'br_address', 
  $_POST['br_address'], 35, 5);
end_table();

end_table(1); // outer table
submit_add_or_update_center(isset($_POST['New']));
end_form();
end_page();


function check_branches() {
  $cust = $_POST['customer_id'];
	$branch = $_POST['branch_code'];
  if ($cust != "" && $branch != "") {
	  $sql = "SELECT branch_code from cust_branch WHERE debtor_no=$cust AND ".
		       "branch_code=$branch ORDER BY branch_code ASC";
  	$result = db_query($sql);
	  $myrow = db_fetch_row($result);
  	if ($myrow[0]==0) {
		  $branch = '';
		}
	}
  if ($cust != "" && $branch == '') {
	  $sql = "SELECT branch_code from cust_branch ".
	         "WHERE debtor_no=$cust ORDER BY branch_code ASC";
  	$result = db_query($sql,"Error while retrieving 1st branch code");
	  $myrow = db_fetch_row($result);
  	if ($myrow[0]>0) {
	    $branch = $myrow[0];
			$_POST['branch_code'] = $branch;
  	}
	}
	return $branch;
}

?>

