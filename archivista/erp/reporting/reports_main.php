<?php

$path_to_root="..";
$page_security = 5;
include_once($path_to_root . "/includes/session.inc");

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/data_checks.inc");
include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/reporting/includes/reports_classes.inc");
$js = "";
if ($use_date_picker)
	$js .= get_js_date_picker();
page(tr("Reports and Analysis"), false, false, "", $js);

$reports = new BoxReports;

$dim = get_company_pref('use_dimension');

$reports->addReportClass(tr('Customer'));
$reports->addReport(tr('Customer'),101,tr('Customer Balances'),
	array(	new ReportParam(tr('End Date'),'DATE'),
			new ReportParam(tr('Customer'),'CUSTOMERS_NO_FILTER'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),102,tr('Aged Customer Analysis'),
	array(	new ReportParam(tr('End Date'),'DATE'),
			new ReportParam(tr('Customer'),'CUSTOMERS_NO_FILTER'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Summary Only'),'YES_NO'),
			new ReportParam(tr('Graphics'),'GRAPHIC'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),103,tr('Customer Detail Listing'),
	array(	new ReportParam(tr('Activity Since'),'DATEBEGIN'),
			new ReportParam(tr('Sales Areas'),'AREAS'),
			new ReportParam(tr('Sales Folk'),'SALESMEN'), new ReportParam(tr('Activity Greater Than'),'TEXT'), new ReportParam(tr('Activity Less Than'),'TEXT'), new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),104,tr('Price Listing'),
	array(	new ReportParam(tr('Inventory Category'),'CATEGORIES'),
			new ReportParam(tr('Sales Types'),'SALESTYPES'),
			new ReportParam(tr('Show Pictures'),'YES_NO'),
			new ReportParam(tr('Show GP %'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),105,tr('Order Status Listing'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Inventory Category'),'CATEGORIES'),
			new ReportParam(tr('Stock Location'),'LOCATIONS'),
			new ReportParam(tr('Back Orders Only'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),106,tr('Salesman Listing'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Summary Only'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),107,tr('Print Invoices/Credit Notes'),
	array(	new ReportParam(tr('From'),'INVOICE'),
			new ReportParam(tr('To'),'INVOICE'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Bank Account'),'BANK_ACCOUNTS'),
			new ReportParam(tr('email Customers'),'YES_NO'),
			new ReportParam(tr('Payment Link'),'PAYMENT_LINK'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),110,tr('Print Deliveries'),
	array(	new ReportParam(tr('From'),'DELIVERY'),
			new ReportParam(tr('To'),'DELIVERY'),
			new ReportParam(tr('email Customers'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),108,tr('Print Statements'),
	array(	new ReportParam(tr('Customer'),'CUSTOMERS_NO_FILTER'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Bank Account'),'BANK_ACCOUNTS'),
			new ReportParam(tr('Email Customers'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Customer'),109,tr('Print Sales Orders'),
	array(	new ReportParam(tr('From'),'ORDERS'),
			new ReportParam(tr('To'),'ORDERS'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Bank Account'),'BANK_ACCOUNTS'),
			new ReportParam(tr('Email Customers'),'YES_NO'),
			new ReportParam(tr('Print as Quote'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));

$reports->addReportClass(tr('Supplier'));
$reports->addReport(tr('Supplier'),201,tr('Supplier Balances'),
	array(	new ReportParam(tr('End Date'),'DATE'),
			new ReportParam(tr('Supplier'),'SUPPLIERS_NO_FILTER'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Supplier'),202,tr('Aged Supplier Analyses'),
	array(	new ReportParam(tr('End Date'),'DATE'),
			new ReportParam(tr('Supplier'),'SUPPLIERS_NO_FILTER'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Summary Only'),'YES_NO'),
			new ReportParam(tr('Graphics'),'GRAPHIC'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Supplier'),203,tr('Payment Report'),
	array(	new ReportParam(tr('End Date'),'DATE'),
			new ReportParam(tr('Supplier'),'SUPPLIERS_NO_FILTER'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Supplier'),204,tr('Outstanding GRNs Report'),
	array(	new ReportParam(tr('Supplier'),'SUPPLIERS_NO_FILTER'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Supplier'),209,tr('Print Purchase Orders'),
	array(	new ReportParam(tr('From'),'PO'),
			new ReportParam(tr('To'),'PO'),
			new ReportParam(tr('Currency Filter'),'CURRENCY'),
			new ReportParam(tr('Bank Account'),'BANK_ACCOUNTS'),
			new ReportParam(tr('Email Customers'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));

$reports->addReportClass(tr('Inventory'));
$reports->addReport(tr('Inventory'),301,tr('Inventory Valuation Report'),
	array(	new ReportParam(tr('Inventory Category'),'CATEGORIES'),
			new ReportParam(tr('Location'),'LOCATIONS'),
			new ReportParam(tr('Detailed Report'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Inventory'),302,tr('Inventory Planning Report'),
	array(	new ReportParam(tr('Inventory Category'),'CATEGORIES'),
			new ReportParam(tr('Location'),'LOCATIONS'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('Inventory'),303,tr('Stock Check Sheets'),
	array(	new ReportParam(tr('Inventory Category'),'CATEGORIES'),
			new ReportParam(tr('Location'),'LOCATIONS'),
			new ReportParam(tr('Show Pictures'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));

$reports->addReportClass(tr('Manufactoring'));
$reports->addReport(tr('Manufactoring'),401,tr('Bill of Material Listing'),
	array(	new ReportParam(tr('From component'),'ITEMS'),
			new ReportParam(tr('To component'),'ITEMS'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReportClass(tr('Dimensions'));
if ($dim > 0)
{
	$reports->addReport(tr('Dimensions'),501,tr('Dimension Summary'),
	array(	new ReportParam(tr('From Dimension'),'DIMENSION'),
			new ReportParam(tr('To Dimension'),'DIMENSION'),
			new ReportParam(tr('Show Balance'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	//$reports->addReport(tr('Dimensions'),502,tr('Dimension Details'),
	//array(	new ReportParam(tr('Dimension'),'DIMENSIONS'),
	//		new ReportParam(tr('Comments'),'TEXTBOX')));
}
$reports->addReportClass(tr('Banking'));
//$reports->addReport(tr('Banking'),601,tr('Bank Account Transactions'),
//	array(	new ReportParam(tr('Bank Accounts'),'BANK_ACCOUNTS'),
//			new ReportParam(tr('Start Date'),'DATE'),
//			new ReportParam(tr('End Date'),'DATE'),
//			new ReportParam(tr('Comments'),'TEXTBOX')));

$reports->addReportClass(tr('General Ledger'));
$reports->addReport(tr('General Ledger'),701,tr('Chart of Accounts'),
	array(	new ReportParam(tr('Show Balances'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
$reports->addReport(tr('General Ledger'),702,tr('List of Journal Entries'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Type'),'SYS_TYPES'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
//$reports->addReport(tr('General Ledger'),703,tr('GL Account Group Summary'),
//	array(	new ReportParam(tr('Comments'),'TEXTBOX')));
if ($dim == 2)
{
	$reports->addReport(tr('General Ledger'),704,tr('GL Account Transactions'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('From Account'),'GL_ACCOUNTS'),
			new ReportParam(tr('To Account'),'GL_ACCOUNTS'),
			new ReportParam(tr('Dimension')." 1", 'DIMENSIONS1'),
			new ReportParam(tr('Dimension')." 2", 'DIMENSIONS2'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),705,tr('Annual Expense Breakdown'),
	array(	new ReportParam(tr('Year'),'TRANS_YEARS'),
			new ReportParam(tr('Dimension')." 1", 'DIMENSIONS1'),
			new ReportParam(tr('Dimension')." 2", 'DIMENSIONS2'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),706,tr('Balance Sheet'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGIN'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Dimension')." 1", 'DIMENSIONS1'),
			new ReportParam(tr('Dimension')." 2", 'DIMENSIONS2'),
			new ReportParam(tr('Graphics'),'GRAPHIC'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),707,tr('Profit and Loss Statement'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Compare to'),'COMPARE'),
			new ReportParam(tr('Dimension')." 1", 'DIMENSIONS1'),
			new ReportParam(tr('Dimension')." 2", 'DIMENSIONS2'),
			new ReportParam(tr('Graphics'),'GRAPHIC'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),708,tr('Trial Balance'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Zero values'),'YES_NO'),
			new ReportParam(tr('Dimension')." 1", 'DIMENSIONS1'),
			new ReportParam(tr('Dimension')." 2", 'DIMENSIONS2'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
}
else if ($dim == 1)
{
	$reports->addReport(tr('General Ledger'),704,tr('GL Account Transactions'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('From Account'),'GL_ACCOUNTS'),
			new ReportParam(tr('To Account'),'GL_ACCOUNTS'),
			new ReportParam(tr('Dimension'), 'DIMENSIONS1'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),705,tr('Annual Expense Breakdown'),
	array(	new ReportParam(tr('Year'),'TRANS_YEARS'),
			new ReportParam(tr('Dimension'), 'DIMENSIONS1'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),706,tr('Balance Sheet'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGIN'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Dimension'), 'DIMENSIONS1'),
			new ReportParam(tr('Graphics'),'GRAPHIC'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),707,tr('Profit and Loss Statement'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Compare to'),'COMPARE'),
			new ReportParam(tr('Dimension'), 'DIMENSIONS1'),
			new ReportParam(tr('Graphics'),'GRAPHIC'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),708,tr('Trial Balance'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Zero values'),'YES_NO'),
			new ReportParam(tr('Dimension'), 'DIMENSIONS1'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
}
else
{
	$reports->addReport(tr('General Ledger'),704,tr('GL Account Transactions'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('From Account'),'GL_ACCOUNTS'),
			new ReportParam(tr('To Account'),'GL_ACCOUNTS'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),705,tr('Annual Expense Breakdown'),
	array(	new ReportParam(tr('Year'),'TRANS_YEARS'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),706,tr('Balance Sheet'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGIN'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Graphics'),'GRAPHIC'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),707,tr('Profit and Loss Statement'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Compare to'),'COMPARE'),
			new ReportParam(tr('Graphics'),'GRAPHIC'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
	$reports->addReport(tr('General Ledger'),708,tr('Trial Balance'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINM'),
			new ReportParam(tr('End Date'),'DATEENDM'),
			new ReportParam(tr('Zero values'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));
}
$reports->addReport(tr('General Ledger'),709,tr('Tax Report'),
	array(	new ReportParam(tr('Start Date'),'DATEBEGINTAX'),
			new ReportParam(tr('End Date'),'DATEENDTAX'),
			new ReportParam(tr('Summary Only'),'YES_NO'),
			new ReportParam(tr('Comments'),'TEXTBOX')));

echo "
<form method=post>
	<input type='hidden' name='REP_ID' value=''>
	<input type='hidden' name='PARAM_COUNT' value=''>
	<input type='hidden' name='PARAM_0' value=''>
	<input type='hidden' name='PARAM_1' value=''>
	<input type='hidden' name='PARAM_2' value=''>
	<input type='hidden' name='PARAM_3' value=''>
	<input type='hidden' name='PARAM_4' value=''>
	<input type='hidden' name='PARAM_5' value=''>
	<input type='hidden' name='PARAM_6' value=''>

	<script language='javascript'>
		function onWindowLoad() {
			showClass(" . $_GET['Class'] . ")
		}
		window.onload=onWindowLoad;
	</script>
";
echo $reports->getDisplay();
echo "</form>";

end_page();
?>