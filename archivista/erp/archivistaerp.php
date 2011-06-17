<?php

include_once('themes/default/renderer.php');
$path_to_root=".";
include_once($path_to_root . "/includes/session.inc");

class archivistaerp {
	var $user;
	var $settings;
	var $applications;
	var $selected_application;
	// GUI
	var $menu;
	var $renderer;
	function archivistaerp() { $this->renderer = new renderer(); }
	function add_application($app) { $this->applications[$app->id] = &$app; }
	function get_application($id) {
	  if (isset($this->applications[$id]))
			return $this->applications[$id];
		return null;
	}
	function get_selected_application() {
		if (isset($this->selected_application))
		  return $this->applications[$this->selected_application];
		foreach ($this->applications as $application)
			return $application;
		return null;
	}
	function display() {
		$this->init();
 	  $this->renderer->wa_header();
		$this->renderer->menu_header($this->menu);
		$this->renderer->display_applications($this);
		$this->renderer->menu_footer($this->menu);
		$this->renderer->wa_footer();
	}
	function init() {
		$this->menu = new menu(tr("Main  Menu"));
		$this->menu->add_item(tr("Main  Menu"), "index.php");
		$this->menu->add_item(tr("Logout"), "/logout.php");
		$this->applications = array();
		$this->add_application(new customers_app());
		$this->add_application(new suppliers_app());
		$this->add_application(new inventory_app());
		$this->add_application(new manufacturing_app());
		$this->add_application(new dimensions_app());
		$this->add_application(new general_ledger_app());
		$this->add_application(new setup_app());
	}	
}

class menu_item {
	var $label;
	var $link;
	function menu_item($label, $link) {
		$this->label = $label;
		$this->link = $link;
	}
}

class menu {
	var $title;
	var $items;
	function menu($title) {
		$this->title = $title;
		$this->items = array();
	}
	function add_item($label, $link) {
		$item = new menu_item($label,$link);
		array_push($this->items,$item);
		return $item;
	}
}

class app_function {
	var $label;
	var $link;
	var $access;
	function app_function($label,$link,$access=1) {
		$this->label = $label;
		$this->link = $link;
		$this->access = $access;
	}
}

class module {
	var $name;
	var $icon;
	var $lappfunctions;
	var $rappfunctions;
	function module($name,$icon = null) {
		$this->name = $name;
		$this->icon = $icon;
		$this->lappfunctions = array();
		$this->rappfunctions = array();
	}
	function add_lapp_function($label,$link="",$access=1) {
		$appfunction = new app_function($label,$link,$access);
		//array_push($this->lappfunctions,$appfunction);
		$this->lappfunctions[] = $appfunction;
		return $appfunction;
	}
	function add_rapp_function($label,$link="",$access=1) {
		$appfunction = new app_function($label,$link,$access);
		//array_push($this->rappfunctions,$appfunction);
		$this->rappfunctions[] = $appfunction;
		return $appfunction;
	}
}

class application {
	var $id;
	var $name;
	var $modules;
	var $enabled;
	function application($id, $name, $enabled=true) {
		$this->id = $id;
		$this->name = $name;
		$this->enables = $enabled;
		$this->modules = array();
	}
	function add_module($name, $icon = null) {
		$module = new module($name,$icon);
		//array_push($this->modules,$module);
		$this->modules[] = $module;
		return $module;
	}
	function add_lapp_function($level, $label,$link="",$access=1) {
		$this->modules[$level]->lappfunctions[] = 
		  new app_function($label, $link, $access);
	}	
	function add_rapp_function($level, $label,$link="",$access=1) {
		$this->modules[$level]->rappfunctions[] = 
		  new app_function($label, $link, $access);
	}	
}

class customers_app extends application {
	function customers_app() {
		$this->application("orders",tr("Sales"));
		$this->add_module(tr("Transactions"));
		$this->add_lapp_function(0, tr("Quote and Sales Order Entry"),"sales/sales_order_entry.php?NewOrder=Yes");
		$this->add_lapp_function(0, tr("Direct Delivery"),"sales/sales_order_entry.php?NewDelivery=0");			
		$this->add_lapp_function(0, tr("Direct Invoice"),"sales/sales_order_entry.php?NewInvoice=0");
		$this->add_lapp_function(0, "","");
		$this->add_lapp_function(0, tr("Delivery Against Sales Orders"),"sales/inquiry/sales_orders_view.php?OutstandingOnly=1");
		$this->add_lapp_function(0, tr("Invoice Against Sales Delivery"),"sales/inquiry/sales_deliveries_view.php?OutstandingOnly=1");
		$this->add_rapp_function(0, tr("Template Delivery"),"sales/inquiry/sales_orders_view.php?DeliveryTemplates=Yes");
		$this->add_rapp_function(0, tr("Template Invoice"),"sales/inquiry/sales_orders_view.php?InvoiceTemplates=Yes");
		$this->add_rapp_function(0, "","");
		$this->add_rapp_function(0, tr("Customer Payments"),"sales/customer_payments.php?");
		$this->add_rapp_function(0, tr("Customer Credit Notes"),"sales/credit_note_entry.php?NewCredit=Yes");
		$this->add_rapp_function(0, tr("Allocate Customer Payments or Credit Notes"),"sales/allocations/customer_allocation_main.php?");
		$this->add_module(tr("Inquiries and Reports"));
		$this->add_lapp_function(1, tr("Sales Order Inquiry"),"sales/inquiry/sales_orders_view.php?");
		$this->add_lapp_function(1, tr("Customer Transaction Inquiry"),"sales/inquiry/customer_inquiry.php?");
		$this->add_lapp_function(1, "","");
		$this->add_lapp_function(1, tr("Customer Allocation Inquiry"),"sales/inquiry/customer_allocation_inquiry.php?");
		$this->add_rapp_function(1, tr("Customer and Sales Reports"),"reporting/reports_main.php?Class=0");
		$this->add_module(tr("Maintenance"));
		$this->add_lapp_function(2, tr("Add and Manage Customers"),"sales/manage/customers.php?");
		$this->add_lapp_function(2, tr("Customer Branches"),"sales/manage/customer_branches.php?");
		$this->add_rapp_function(2, tr("Sales Types"),"sales/manage/sales_types.php?");
		$this->add_rapp_function(2, tr("Sales Persons"),"sales/manage/sales_people.php?");
		$this->add_rapp_function(2, tr("Sales Areas"),"sales/manage/sales_areas.php?");
		$this->add_rapp_function(2, tr("Credit Status Setup"),"sales/manage/credit_status.php?");
  }
}
	
class dimensions_app extends application {
	function dimensions_app() {
		$dim = get_company_pref('use_dimension');
		$this->application("proj",tr("Dimensions"));
		if ($dim > 0) {
			$this->add_module(tr("Transactions"));
			$this->add_lapp_function(0, tr("Dimension Entry"),"dimensions/dimension_entry.php?");
			$this->add_lapp_function(0, tr("Outstanding Dimensions"),"dimensions/inquiry/search_dimensions.php?OutstandingOnly=1");
			$this->add_module(tr("Inquiries and Reports"));
			$this->add_lapp_function(1, tr("Dimension Inquiry"),"dimensions/inquiry/search_dimensions.php?");
			$this->add_rapp_function(1, tr("Dimension Reports"),"reporting/reports_main.php?Class=4");
		}
	}
}

class general_ledger_app extends application {
	function general_ledger_app() {
		$this->application("GL",tr("Banking and General Ledger"));
		$this->add_module(tr("Transactions"));
		$this->add_lapp_function(0, tr("Payments"),"gl/gl_payment.php?NewPayment=Yes");
		$this->add_lapp_function(0, tr("Deposits"),"gl/gl_deposit.php?NewDeposit=Yes");
		$this->add_lapp_function(0, tr("Bank Account Transfers"),"gl/bank_transfer.php?");
		$this->add_rapp_function(0, tr("Journal Entry"),"gl/gl_journal.php?NewJournal=Yes");
		$this->add_rapp_function(0, tr("Budget Entry"),"gl/gl_budget.php?");
		$this->add_module(tr("Inquiries and Reports"));
		$this->add_lapp_function(1, tr("Bank Account Inquiry"),"gl/inquiry/bank_inquiry.php?");
		$this->add_lapp_function(1, tr("GL Account Inquiry"),"gl/inquiry/gl_account_inquiry.php?");
		$this->add_lapp_function(1, "","");
		$this->add_lapp_function(1, tr("Trial Balance"),"gl/inquiry/gl_trial_balance.php?");
		$this->add_rapp_function(1, tr("Banking Reports"),"reporting/reports_main.php?Class=5");
		$this->add_rapp_function(1, tr("General Ledger Reports"),"reporting/reports_main.php?Class=6");
		$this->add_module(tr("Maintenance"));
		$this->add_lapp_function(2, tr("Bank Accounts"),"gl/manage/bank_accounts.php?");
		$this->add_lapp_function(2, tr("Payment, Deposit and Transfer Types"),"gl/manage/bank_trans_types.php?");
		$this->add_lapp_function(2, "","");
		$this->add_lapp_function(2, tr("Currencies"),"gl/manage/currencies.php?");
		$this->add_lapp_function(2, tr("Exchange Rates"),"gl/manage/exchange_rates.php?");

		$this->add_rapp_function(2, tr("GL Accounts"),"gl/manage/gl_accounts.php?");
		$this->add_rapp_function(2, tr("GL Account Groups"),"gl/manage/gl_account_types.php?");
		$this->add_rapp_function(2, tr("GL Account Classes"),"gl/manage/gl_account_classes.php?");
	}
}

class inventory_app extends application {
	function inventory_app() {
		$this->application("stock",tr("Items and Inventory"));
		$this->add_module(tr("Transactions"));
		$this->add_lapp_function(0, tr("Inventory Location Transfers"),"inventory/transfers.php?NewTransfer=1");
		$this->add_lapp_function(0, tr("Inventory Adjustments"),"inventory/adjustments.php?NewAdjustment=1");
		$this->add_module(tr("Inquiries and Reports"));
		$this->add_lapp_function(1, tr("Inventory Item Movements"),"inventory/inquiry/stock_movements.php?");
		$this->add_lapp_function(1, tr("Inventory Item Status"),"inventory/inquiry/stock_status.php?");
		$this->add_rapp_function(1, tr("Inventory Reports"),"reporting/reports_main.php?Class=2");
		$this->add_module(tr("Maintenance"));
		$this->add_lapp_function(2, tr("Items"),"inventory/manage/items.php?");
		$this->add_lapp_function(2, tr("Item Categories"),"inventory/manage/item_categories.php?");
		$this->add_lapp_function(2, tr("Item Translations"),"inventory/manage/item_translations.php?");
		$this->add_lapp_function(2, tr("Inventory Locations"),"inventory/manage/locations.php?");
		$this->add_rapp_function(2, tr("Inventory Movement Types"),"inventory/manage/movement_types.php?");
		$this->add_rapp_function(2, tr("Item Tax Types"),"taxes/item_tax_types.php?");
		$this->add_rapp_function(2, tr("Units of Measure"),"inventory/manage/item_units.php?");
		$this->add_rapp_function(2, tr("Reorder Levels"),"inventory/reorder_level.php?");
		$this->add_module(tr("Pricing and Costs"));
		$this->add_lapp_function(3, tr("Sales Pricing"),"inventory/prices.php?");
		$this->add_lapp_function(3, tr("Purchasing Pricing"),"inventory/purchasing_data.php?");
		$this->add_rapp_function(3, tr("Standard Costs"),"inventory/cost_update.php?");
	}
}

class manufacturing_app extends application	{
	function manufacturing_app() {
		$this->application("manuf",tr("Manufacturing"));
		$this->add_module(tr("Transactions"));
		$this->add_lapp_function(0, tr("Work Order Entry"),"manufacturing/work_order_entry.php?");
		$this->add_lapp_function(0, tr("Outstanding Work Orders"),"manufacturing/search_work_orders.php?OutstandingOnly=1");
		$this->add_module(tr("Inquiries and Reports"));
		//$this->add_lapp_function(1, tr("Costed Bill Of Material Inquiry"),"manufacturing/inquiry/bom_cost_inquiry.php?");
		$this->add_lapp_function(1, tr("Inventory Item Where Used Inquiry"),"manufacturing/inquiry/where_used_inquiry.php?");
		$this->add_lapp_function(1, tr("Work Order Inquiry"),"manufacturing/search_work_orders.php?");
		$this->add_rapp_function(1, tr("Manufactoring Reports"),"reporting/reports_main.php?Class=3");
		$this->add_module(tr("Maintenance"));
		$this->add_lapp_function(2, tr("Bills Of Material"),"manufacturing/manage/bom_edit.php?");
		$this->add_lapp_function(2, tr("Work Centres"),"manufacturing/manage/work_centres.php?");
	}
}


class setup_app extends application {
	function setup_app() {
		$this->application("system",tr("Setup"));
		$this->add_module(tr("Company Setup"));
		$this->add_lapp_function(0, tr("Company Setup"),"admin/company_preferences.php?");
		$this->add_lapp_function(0, tr("User Accounts Setup"),"admin/users.php?", 15);
		$this->add_lapp_function(0, "","");
		$this->add_lapp_function(0, tr("Display Setup"),"admin/display_prefs.php?");
		$this->add_lapp_function(0, tr("Forms Setup"),"admin/forms_setup.php?");
		$this->add_rapp_function(0, tr("Taxes"),"taxes/tax_types.php?");
		$this->add_rapp_function(0, tr("Tax Groups"),"taxes/tax_groups.php?");
		$this->add_rapp_function(0, "","");
		$this->add_rapp_function(0, tr("System and General GL Setup"),"admin/gl_setup.php?");
		$this->add_rapp_function(0, tr("Fiscal Years"),"admin/fiscalyears.php?");
		$this->add_module(tr("Miscellaneous"));
		$this->add_lapp_function(1, tr("Payment Terms"),"admin/payment_terms.php?");
		$this->add_lapp_function(1, tr("Shipping Company"),"admin/shipping_companies.php?");
		$this->add_module(tr("Maintanance"));
		$this->add_lapp_function(2, tr("Void a Transaction"),"admin/void_transaction.php?");
		$this->add_lapp_function(2, tr("View or Print Transactions"),"admin/view_print_transaction.php?");
		$this->add_rapp_function(2, tr("Backup and Restore"),"admin/backups.php?", 15);
		$this->add_rapp_function(2, tr("Create/Update Companies"),"admin/create_coy.php?", 14);
		$this->add_rapp_function(2, tr("Install/Update Languages"),"admin/inst_lang.php?", 14);
		$this->add_rapp_function(2, tr("Install/Update Modules"),"admin/inst_module.php?", 15);
	}
}

class suppliers_app extends application {
	function suppliers_app() {
		$this->application("AP",tr("Purchases"));
		$this->add_module(tr("Transactions"));
		$this->add_lapp_function(0, tr("Purchase Order Entry"),"purchasing/po_entry_items.php?NewOrder=Yes");
		$this->add_lapp_function(0, tr("Outstanding Purchase Orders Maintenance"),"purchasing/inquiry/po_search.php?");
		$this->add_rapp_function(0, tr("Payments to Suppliers"),"purchasing/supplier_payment.php?");
		$this->add_rapp_function(0, "","");
		$this->add_rapp_function(0, tr("Supplier Invoices"),"purchasing/supplier_invoice.php?New=1");			
		$this->add_rapp_function(0, tr("Supplier Credit Notes"),"purchasing/supplier_credit.php?New=1");
		$this->add_rapp_function(0, tr("Allocate Supplier Payments or Credit Notes"),"purchasing/allocations/supplier_allocation_main.php?");
		$this->add_module(tr("Inquiries and Reports"));
		$this->add_lapp_function(1, tr("Purchase Orders Inquiry"),"purchasing/inquiry/po_search_completed.php?");
		$this->add_lapp_function(1, tr("Supplier Transaction Inquiry"),"purchasing/inquiry/supplier_inquiry.php?");
		$this->add_lapp_function(1, "","");
		$this->add_lapp_function(1, tr("Supplier Allocation Inquiry"),"purchasing/inquiry/supplier_allocation_inquiry.php?");
		$this->add_rapp_function(1, tr("Supplier and Purchasing Reports"),"reporting/reports_main.php?Class=1");
		$this->add_module(tr("Maintenance"));
		$this->add_lapp_function(2, tr("Suppliers"),"purchasing/manage/suppliers.php?");
	}
}

?>
