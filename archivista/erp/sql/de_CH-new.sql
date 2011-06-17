-- phpMyAdmin SQL Dump
-- version 2.11.4
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Apr 04, 2008 at 12:35 PM
-- Server version: 5.0.45
-- PHP Version: 5.2.4

--
-- Database: `en_US-new.sql, release 2.0`
--

-- --------------------------------------------------------

--
-- Table structure for table `areas`
--

DROP TABLE IF EXISTS `areas`;
CREATE TABLE IF NOT EXISTS `areas` (
  `area_code` int(11) NOT NULL auto_increment,
  `description` varchar(60) NOT NULL default '',
  PRIMARY KEY  (`area_code`),
  UNIQUE KEY `description` (`description`)
) TYPE=MyISAM  AUTO_INCREMENT=2 ;

-- --------------------------------------------------------

--
-- Table structure for table `bank_accounts`
--

DROP TABLE IF EXISTS `bank_accounts`;
CREATE TABLE IF NOT EXISTS `bank_accounts` (
  `account_code` varchar(11) NOT NULL default '',
  `account_type` smallint(6) NOT NULL default '0',
  `bank_account_name` varchar(60) NOT NULL default '',
  `bank_account_number` varchar(100) NOT NULL default '',
  `bank_name` varchar(60) NOT NULL default '',
  `bank_address` tinytext,
  `bank_curr_code` char(3) NOT NULL default '',
  PRIMARY KEY  (`account_code`),
  KEY `bank_account_name` (`bank_account_name`),
  KEY `bank_account_number` (`bank_account_number`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `bank_trans`
--

DROP TABLE IF EXISTS `bank_trans`;
CREATE TABLE IF NOT EXISTS `bank_trans` (
  `id` int(11) NOT NULL auto_increment,
  `type` smallint(6) default NULL,
  `trans_no` int(11) default NULL,
  `bank_act` varchar(11) default NULL,
  `ref` varchar(40) default NULL,
  `trans_date` date NOT NULL default '0000-00-00',
  `bank_trans_type_id` int(10) unsigned default NULL,
  `amount` double default NULL,
  `dimension_id` int(11) NOT NULL default '0',
  `dimension2_id` int(11) NOT NULL default '0',
  `person_type_id` int(11) NOT NULL default '0',
  `person_id` tinyblob,
  PRIMARY KEY  (`id`),
  KEY `bank_act` (`bank_act`,`ref`),
  KEY `type` (`type`,`trans_no`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `bank_trans_types`
--

DROP TABLE IF EXISTS `bank_trans_types`;
CREATE TABLE IF NOT EXISTS `bank_trans_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM  AUTO_INCREMENT=3 ;

-- --------------------------------------------------------

--
-- Table structure for table `bom`
--

DROP TABLE IF EXISTS `bom`;
CREATE TABLE IF NOT EXISTS `bom` (
  `id` int(11) NOT NULL auto_increment,
  `parent` char(20) NOT NULL default '',
  `component` char(20) NOT NULL default '',
  `workcentre_added` int(11) NOT NULL default '0',
  `loc_code` char(5) NOT NULL default '',
  `quantity` double NOT NULL default '1',
  PRIMARY KEY  (`parent`,`component`,`workcentre_added`,`loc_code`),
  KEY `component` (`component`),
  KEY `id` (`id`),
  KEY `loc_code` (`loc_code`),
  KEY `parent` (`parent`,`loc_code`),
  KEY `Parent_2` (`parent`),
  KEY `workcentre_added` (`workcentre_added`)
) TYPE=MyISAM AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `budget_trans`
--

DROP TABLE IF EXISTS `budget_trans`;
CREATE TABLE IF NOT EXISTS `budget_trans` (
  `counter` int(11) NOT NULL auto_increment,
  `type` smallint(6) NOT NULL default '0',
  `type_no` bigint(16) NOT NULL default '1',
  `tran_date` date NOT NULL default '0000-00-00',
  `account` varchar(11) NOT NULL default '',
  `memo_` tinytext NOT NULL,
  `amount` double NOT NULL default '0',
  `dimension_id` int(11) default '0',
  `dimension2_id` int(11) default '0',
  `person_type_id` int(11) default NULL,
  `person_id` tinyblob,
  PRIMARY KEY  (`counter`),
  KEY `Type_and_Number` (`type`,`type_no`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `chart_class`
--

DROP TABLE IF EXISTS `chart_class`;
CREATE TABLE IF NOT EXISTS `chart_class` (
  `cid` int(11) NOT NULL default '0',
  `class_name` varchar(60) NOT NULL default '',
  `balance_sheet` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`cid`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `chart_master`
--

DROP TABLE IF EXISTS `chart_master`;
CREATE TABLE IF NOT EXISTS `chart_master` (
  `account_code` varchar(11) NOT NULL default '',
  `account_code2` varchar(11) default '',
  `account_name` varchar(60) NOT NULL default '',
  `account_type` int(11) NOT NULL default '0',
  `tax_code` int(11) NOT NULL default '0',
  PRIMARY KEY  (`account_code`),
  KEY `account_code` (`account_code`),
  KEY `account_name` (`account_name`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `chart_types`
--

DROP TABLE IF EXISTS `chart_types`;
CREATE TABLE IF NOT EXISTS `chart_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  `class_id` tinyint(1) NOT NULL default '0',
  `parent` int(11) NOT NULL default '-1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM  AUTO_INCREMENT=53 ;

-- --------------------------------------------------------

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
CREATE TABLE IF NOT EXISTS `comments` (
  `type` int(11) NOT NULL default '0',
  `id` int(11) NOT NULL default '0',
  `date_` date default '0000-00-00',
  `memo_` tinytext
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `company`
--

DROP TABLE IF EXISTS `company`;
CREATE TABLE IF NOT EXISTS `company` (
  `coy_code` int(11) NOT NULL default '1',
  `coy_name` varchar(60) NOT NULL default '',
  `gst_no` varchar(25) NOT NULL default '',
  `coy_no` varchar(25) NOT NULL default '0',
  `tax_prd` int(11) NOT NULL default '1',
  `tax_last` int(11) NOT NULL default '1',
  `postal_address` tinytext NOT NULL,
  `phone` varchar(30) NOT NULL default '',
  `fax` varchar(30) NOT NULL default '',
  `email` varchar(100) NOT NULL default '',
  `coy_logo` varchar(100) NOT NULL default '',
  `domicile` varchar(55) NOT NULL default '',
  `curr_default` char(3) NOT NULL default '',
  `debtors_act` varchar(11) NOT NULL default '',
  `pyt_discount_act` varchar(11) NOT NULL default '',
  `creditors_act` varchar(11) NOT NULL default '',
  `grn_act` varchar(11) NOT NULL default '',
  `exchange_diff_act` varchar(11) NOT NULL default '',
  `purch_exchange_diff_act` varchar(11) NOT NULL default '',
  `retained_earnings_act` varchar(11) NOT NULL default '',
  `freight_act` varchar(11) NOT NULL default '',
  `default_sales_act` varchar(11) NOT NULL default '',
  `default_sales_discount_act` varchar(11) NOT NULL default '',
  `default_prompt_payment_act` varchar(11) NOT NULL default '',
  `default_inventory_act` varchar(11) NOT NULL default '',
  `default_cogs_act` varchar(11) NOT NULL default '',
  `default_adj_act` varchar(11) NOT NULL default '',
  `default_inv_sales_act` varchar(11) NOT NULL default '',
  `default_assembly_act` varchar(11) NOT NULL default '',
  `payroll_act` varchar(11) NOT NULL default '',
  `custom1_name` varchar(60) NOT NULL default '',
  `custom2_name` varchar(60) NOT NULL default '',
  `custom3_name` varchar(60) NOT NULL default '',
  `custom1_value` varchar(100) NOT NULL default '',
  `custom2_value` varchar(100) NOT NULL default '',
  `custom3_value` varchar(100) NOT NULL default '',
  `allow_negative_stock` tinyint(1) NOT NULL default '0',
  `po_over_receive` int(11) NOT NULL default '10',
  `po_over_charge` int(11) NOT NULL default '10',
  `default_credit_limit` int(11) NOT NULL default '1000',
  `default_workorder_required` int(11) NOT NULL default '20',
  `default_dim_required` int(11) NOT NULL default '20',
  `past_due_days` int(11) NOT NULL default '30',
  `use_dimension` tinyint(1) default '0',
  `f_year` int(11) NOT NULL default '1',
  `no_item_list` tinyint(1) NOT NULL default '0',
  `no_customer_list` tinyint(1) NOT NULL default '0',
  `no_supplier_list` tinyint(1) NOT NULL default '0',
  `image` blob,
  PRIMARY KEY  (`coy_code`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `credit_status`
--

DROP TABLE IF EXISTS `credit_status`;
CREATE TABLE IF NOT EXISTS `credit_status` (
  `id` int(11) NOT NULL auto_increment,
  `reason_description` char(100) NOT NULL default '',
  `dissallow_invoices` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `reason_description` (`reason_description`)
) TYPE=MyISAM  AUTO_INCREMENT=5 ;

-- --------------------------------------------------------

--
-- Table structure for table `currencies`
--

DROP TABLE IF EXISTS `currencies`;
CREATE TABLE IF NOT EXISTS `currencies` (
  `currency` varchar(60) NOT NULL default '',
  `curr_abrev` char(3) NOT NULL default '',
  `curr_symbol` varchar(10) NOT NULL default '',
  `country` varchar(100) NOT NULL default '',
  `hundreds_name` varchar(15) NOT NULL default '',
  PRIMARY KEY  (`curr_abrev`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `cust_allocations`
--

DROP TABLE IF EXISTS `cust_allocations`;
CREATE TABLE IF NOT EXISTS `cust_allocations` (
  `id` int(11) NOT NULL auto_increment,
  `amt` double unsigned default NULL,
  `date_alloc` date NOT NULL default '0000-00-00',
  `trans_no_from` int(11) default NULL,
  `trans_type_from` int(11) default NULL,
  `trans_no_to` int(11) default NULL,
  `trans_type_to` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `cust_branch`
--

DROP TABLE IF EXISTS `cust_branch`;
CREATE TABLE IF NOT EXISTS `cust_branch` (
  `branch_code` int(11) NOT NULL auto_increment,
  `debtor_no` int(11) NOT NULL default '0',
  `br_name` varchar(60) NOT NULL default '',
  `br_address` tinytext NOT NULL,
  `area` int(11) default NULL,
  `salesman` int(11) NOT NULL default '0',
  `phone` varchar(30) NOT NULL default '',
  `fax` varchar(30) NOT NULL default '',
  `contact_name` varchar(60) NOT NULL default '',
  `email` varchar(100) NOT NULL default '',
  `default_location` varchar(5) NOT NULL default '',
  `tax_group_id` int(11) default NULL,
  `sales_account` varchar(11) default NULL,
  `sales_discount_account` varchar(11) default NULL,
  `receivables_account` varchar(11) default NULL,
  `payment_discount_account` varchar(11) default NULL,
  `default_ship_via` int(11) NOT NULL default '1',
  `disable_trans` tinyint(4) NOT NULL default '0',
  `br_post_address` tinytext NOT NULL,
  `lang_code` varchar(5) NOT NULL,
  PRIMARY KEY  (`branch_code`,`debtor_no`),
  KEY `branch_code` (`branch_code`),
  KEY `br_name` (`br_name`)
) TYPE=MyISAM AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `debtors_master`
--

DROP TABLE IF EXISTS `debtors_master`;
CREATE TABLE IF NOT EXISTS `debtors_master` (
  `debtor_no` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  `address` tinytext,
  `email` varchar(100) NOT NULL default '',
  `tax_id` varchar(55) NOT NULL default '',
  `curr_code` char(3) NOT NULL default '',
  `sales_type` int(11) NOT NULL default '1',
  `dimension_id` int(11) NOT NULL default '0',
  `dimension2_id` int(11) NOT NULL default '0',
  `credit_status` int(11) NOT NULL default '0',
  `payment_terms` int(11) default NULL,
  `discount` double NOT NULL default '0',
  `pymt_discount` double NOT NULL default '0',
  `credit_limit` float NOT NULL default '1000',
  `customer_id` varchar(10) NOT NULL default '',
  PRIMARY KEY  (`debtor_no`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `debtor_trans`
--

DROP TABLE IF EXISTS `debtor_trans`;
CREATE TABLE IF NOT EXISTS `debtor_trans` (
  `trans_no` int(11) unsigned NOT NULL default '0',
  `type` smallint(6) unsigned NOT NULL default '0',
  `version` tinyint(1) unsigned NOT NULL default '0',
  `debtor_no` int(11) unsigned default NULL,
  `branch_code` int(11) NOT NULL default '-1',
  `tran_date` date NOT NULL default '0000-00-00',
  `due_date` date NOT NULL default '0000-00-00',
  `reference` varchar(60) NOT NULL default '',
  `tpe` int(11) NOT NULL default '0',
  `order_` int(11) NOT NULL default '0',
  `ov_amount` double NOT NULL default '0',
  `ov_gst` double NOT NULL default '0',
  `ov_freight` double NOT NULL default '0',
  `ov_freight_tax` double NOT NULL default '0',
  `ov_discount` double NOT NULL default '0',
  `alloc` double NOT NULL default '0',
  `rate` double NOT NULL default '1',
  `ship_via` int(11) default NULL,
  `trans_link` int(11) NOT NULL default '0',
  PRIMARY KEY  (`trans_no`,`type`),
  KEY `debtor_no` (`debtor_no`,`branch_code`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `debtor_trans_details`
--

DROP TABLE IF EXISTS `debtor_trans_details`;
CREATE TABLE IF NOT EXISTS `debtor_trans_details` (
  `id` int(11) NOT NULL auto_increment,
  `debtor_trans_no` int(11) default NULL,
  `debtor_trans_type` int(11) default NULL,
  `stock_id` varchar(20) NOT NULL default '',
  `description` tinytext,
  `unit_price` double NOT NULL default '0',
  `unit_tax` double NOT NULL default '0',
  `quantity` double NOT NULL default '0',
  `discount_percent` double NOT NULL default '0',
  `standard_cost` double NOT NULL default '0',
  `qty_done` double NOT NULL default '0',
  `date_from` date NOT NULL,
  `notes` varchar(250) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `debtor_trans_tax_details`
--

DROP TABLE IF EXISTS `debtor_trans_tax_details`;
CREATE TABLE IF NOT EXISTS `debtor_trans_tax_details` (
  `id` int(11) NOT NULL auto_increment,
  `debtor_trans_no` int(11) default NULL,
  `debtor_trans_type` int(11) default NULL,
  `tax_type_id` int(11) NOT NULL default '0',
  `tax_type_name` varchar(60) default NULL,
  `rate` double NOT NULL default '0',
  `included_in_price` tinyint(1) NOT NULL default '0',
  `amount` double NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `dimensions`
--

DROP TABLE IF EXISTS `dimensions`;
CREATE TABLE IF NOT EXISTS `dimensions` (
  `id` int(11) NOT NULL auto_increment,
  `reference` varchar(60) NOT NULL default '',
  `name` varchar(60) NOT NULL default '',
  `type_` tinyint(1) NOT NULL default '1',
  `closed` tinyint(1) NOT NULL default '0',
  `date_` date NOT NULL default '0000-00-00',
  `due_date` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `reference` (`reference`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `exchange_rates`
--

DROP TABLE IF EXISTS `exchange_rates`;
CREATE TABLE IF NOT EXISTS `exchange_rates` (
  `id` int(11) NOT NULL auto_increment,
  `curr_code` char(3) NOT NULL default '',
  `rate_buy` double NOT NULL default '0',
  `rate_sell` double NOT NULL default '0',
  `date_` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `curr_code` (`curr_code`,`date_`)
) TYPE=MyISAM AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `fiscal_year`
--

DROP TABLE IF EXISTS `fiscal_year`;
CREATE TABLE IF NOT EXISTS `fiscal_year` (
  `id` int(11) NOT NULL auto_increment,
  `begin` date default '0000-00-00',
  `end` date default '0000-00-00',
  `closed` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB  AUTO_INCREMENT=2 ;

-- --------------------------------------------------------

--
-- Table structure for table `gl_trans`
--

DROP TABLE IF EXISTS `gl_trans`;
CREATE TABLE IF NOT EXISTS `gl_trans` (
  `counter` int(11) NOT NULL auto_increment,
  `type` smallint(6) NOT NULL default '0',
  `type_no` bigint(16) NOT NULL default '1',
  `tran_date` date NOT NULL default '0000-00-00',
  `account` varchar(11) NOT NULL default '',
  `memo_` tinytext NOT NULL,
  `amount` double NOT NULL default '0',
  `dimension_id` int(11) NOT NULL default '0',
  `dimension2_id` int(11) NOT NULL default '0',
  `person_type_id` int(11) default NULL,
  `person_id` tinyblob,
  PRIMARY KEY  (`counter`),
  KEY `Type_and_Number` (`type`,`type_no`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `grn_batch`
--

DROP TABLE IF EXISTS `grn_batch`;
CREATE TABLE IF NOT EXISTS `grn_batch` (
  `id` int(11) NOT NULL auto_increment,
  `supplier_id` int(11) NOT NULL default '0',
  `purch_order_no` int(11) default NULL,
  `reference` varchar(60) NOT NULL default '',
  `delivery_date` date NOT NULL default '0000-00-00',
  `loc_code` varchar(5) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `grn_items`
--

DROP TABLE IF EXISTS `grn_items`;
CREATE TABLE IF NOT EXISTS `grn_items` (
  `id` int(11) NOT NULL auto_increment,
  `grn_batch_id` int(11) default NULL,
  `po_detail_item` int(11) NOT NULL default '0',
  `item_code` varchar(20) NOT NULL default '',
  `description` tinytext,
  `qty_recd` double NOT NULL default '0',
  `quantity_inv` double NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `item_tax_types`
--

DROP TABLE IF EXISTS `item_tax_types`;
CREATE TABLE IF NOT EXISTS `item_tax_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  `exempt` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `item_tax_type_exemptions`
--

DROP TABLE IF EXISTS `item_tax_type_exemptions`;
CREATE TABLE IF NOT EXISTS `item_tax_type_exemptions` (
  `item_tax_type_id` int(11) NOT NULL default '0',
  `tax_type_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`item_tax_type_id`,`tax_type_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `item_units`
--

DROP TABLE IF EXISTS `item_units`;
CREATE TABLE IF NOT EXISTS `item_units` (
  `abbr` varchar(20) NOT NULL,
  `name` varchar(40) NOT NULL,
  `decimals` tinyint(2) NOT NULL,
  PRIMARY KEY  (`abbr`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

DROP TABLE IF EXISTS `locations`;
CREATE TABLE IF NOT EXISTS `locations` (
  `loc_code` varchar(5) NOT NULL default '',
  `location_name` varchar(60) NOT NULL default '',
  `delivery_address` tinytext NOT NULL,
  `phone` varchar(30) NOT NULL default '',
  `fax` varchar(30) NOT NULL default '',
  `email` varchar(100) NOT NULL default '',
  `contact` varchar(30) NOT NULL default '',
  PRIMARY KEY  (`loc_code`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `loc_stock`
--

DROP TABLE IF EXISTS `loc_stock`;
CREATE TABLE IF NOT EXISTS `loc_stock` (
  `loc_code` char(5) NOT NULL default '',
  `stock_id` char(20) NOT NULL default '',
  `reorder_level` bigint(20) NOT NULL default '0',
  PRIMARY KEY  (`loc_code`,`stock_id`),
  KEY `stock_id` (`stock_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `movement_types`
--

DROP TABLE IF EXISTS `movement_types`;
CREATE TABLE IF NOT EXISTS `movement_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM  AUTO_INCREMENT=2 ;

-- --------------------------------------------------------

--
-- Table structure for table `payment_terms`
--

DROP TABLE IF EXISTS `payment_terms`;
CREATE TABLE IF NOT EXISTS `payment_terms` (
  `terms_indicator` int(11) NOT NULL auto_increment,
  `terms` char(80) NOT NULL default '',
  `days_before_due` smallint(6) NOT NULL default '0',
  `day_in_following_month` smallint(6) NOT NULL default '0',
  PRIMARY KEY  (`terms_indicator`),
  UNIQUE KEY `terms` (`terms`)
) TYPE=MyISAM  AUTO_INCREMENT=5 ;

-- --------------------------------------------------------

--
-- Table structure for table `prices`
--

DROP TABLE IF EXISTS `prices`;
CREATE TABLE IF NOT EXISTS `prices` (
  `id` int(11) NOT NULL auto_increment,
  `stock_id` varchar(20) NOT NULL default '',
  `sales_type_id` int(11) NOT NULL default '0',
  `curr_abrev` char(3) NOT NULL default '',
  `price` double NOT NULL default '0',
  `factor` double NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `price` (`stock_id`,`sales_type_id`,`curr_abrev`)
) TYPE=MyISAM AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `purch_data`
--

DROP TABLE IF EXISTS `purch_data`;
CREATE TABLE IF NOT EXISTS `purch_data` (
  `supplier_id` int(11) NOT NULL default '0',
  `stock_id` char(20) NOT NULL default '',
  `price` double NOT NULL default '0',
  `suppliers_uom` char(50) NOT NULL default '',
  `conversion_factor` double NOT NULL default '1',
  `supplier_description` char(50) NOT NULL default '',
  PRIMARY KEY  (`supplier_id`,`stock_id`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `purch_orders`
--

DROP TABLE IF EXISTS `purch_orders`;
CREATE TABLE IF NOT EXISTS `purch_orders` (
  `order_no` int(11) NOT NULL auto_increment,
  `supplier_id` int(11) NOT NULL default '0',
  `comments` tinytext,
  `ord_date` date NOT NULL default '0000-00-00',
  `reference` tinytext NOT NULL,
  `requisition_no` tinytext,
  `into_stock_location` varchar(5) NOT NULL default '',
  `delivery_address` tinytext NOT NULL,
  PRIMARY KEY  (`order_no`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `purch_order_details`
--

DROP TABLE IF EXISTS `purch_order_details`;
CREATE TABLE IF NOT EXISTS `purch_order_details` (
  `po_detail_item` int(11) NOT NULL auto_increment,
  `order_no` int(11) NOT NULL default '0',
  `item_code` varchar(20) NOT NULL default '',
  `description` tinytext,
  `delivery_date` date NOT NULL default '0000-00-00',
  `qty_invoiced` double NOT NULL default '0',
  `unit_price` double NOT NULL default '0',
  `act_price` double NOT NULL default '0',
  `std_cost_unit` double NOT NULL default '0',
  `quantity_ordered` double NOT NULL default '0',
  `quantity_received` double NOT NULL default '0',
  PRIMARY KEY  (`po_detail_item`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `refs`
--

DROP TABLE IF EXISTS `refs`;
CREATE TABLE IF NOT EXISTS `refs` (
  `id` int(11) NOT NULL default '0',
  `type` int(11) NOT NULL default '0',
  `reference` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`id`,`type`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `salesman`
--

DROP TABLE IF EXISTS `salesman`;
CREATE TABLE IF NOT EXISTS `salesman` (
  `salesman_code` int(11) NOT NULL auto_increment,
  `salesman_name` char(60) NOT NULL default '',
  `salesman_phone` char(30) NOT NULL default '',
  `salesman_fax` char(30) NOT NULL default '',
  `salesman_email` varchar(100) NOT NULL default '',
  `provision` double NOT NULL default '0',
  `break_pt` double NOT NULL default '0',
  `provision2` double NOT NULL default '0',
  PRIMARY KEY  (`salesman_code`),
  UNIQUE KEY `salesman_name` (`salesman_name`)
) TYPE=MyISAM  AUTO_INCREMENT=2 ;

-- --------------------------------------------------------

--
-- Table structure for table `sales_orders`
--

DROP TABLE IF EXISTS `sales_orders`;
CREATE TABLE IF NOT EXISTS `sales_orders` (
  `order_no` int(11) NOT NULL auto_increment,
  `version` tinyint(1) unsigned NOT NULL default '0',
  `type` tinyint(1) NOT NULL default '0',
  `debtor_no` int(11) NOT NULL default '0',
  `branch_code` int(11) NOT NULL default '0',
  `customer_ref` tinytext NOT NULL,
  `comments` tinytext,
  `ord_date` date NOT NULL default '0000-00-00',
  `order_type` int(11) NOT NULL default '0',
  `ship_via` int(11) NOT NULL default '0',
  `delivery_address` tinytext NOT NULL,
  `contact_phone` varchar(30) default NULL,
  `contact_email` varchar(100) default NULL,
  `deliver_to` tinytext NOT NULL,
  `freight_cost` double NOT NULL default '0',
  `from_stk_loc` varchar(5) NOT NULL default '',
  `delivery_date` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`order_no`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `sales_order_details`
--

DROP TABLE IF EXISTS `sales_order_details`;
CREATE TABLE IF NOT EXISTS `sales_order_details` (
  `id` int(11) NOT NULL auto_increment,
  `order_no` int(11) NOT NULL default '0',
  `stk_code` varchar(20) NOT NULL default '',
  `description` tinytext,
  `qty_sent` double NOT NULL default '0',
  `unit_price` double NOT NULL default '0',
  `quantity` double NOT NULL default '0',
  `discount_percent` double NOT NULL default '0',
  `date_from` date NOT NULL,
  `notes` varchar(250) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `sales_types`
--

DROP TABLE IF EXISTS `sales_types`;
CREATE TABLE IF NOT EXISTS `sales_types` (
  `id` int(11) NOT NULL auto_increment,
  `sales_type` char(50) NOT NULL default '',
  `tax_included` int(1) NOT NULL default '0',
  `price_format` double NOT NULL default '1',
  `price_factor` double NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `sales_type` (`sales_type`)
) TYPE=MyISAM  AUTO_INCREMENT=3 ;

-- --------------------------------------------------------

--
-- Table structure for table `shippers`
--

DROP TABLE IF EXISTS `shippers`;
CREATE TABLE IF NOT EXISTS `shippers` (
  `shipper_id` int(11) NOT NULL auto_increment,
  `shipper_name` varchar(60) NOT NULL default '',
  `phone` varchar(30) NOT NULL default '',
  `contact` tinytext NOT NULL,
  `address` tinytext NOT NULL,
  `shipper_defcost` double NOT NULL default '0',
  PRIMARY KEY  (`shipper_id`),
  UNIQUE KEY `name` (`shipper_name`)
) TYPE=MyISAM  AUTO_INCREMENT=2 ;

-- --------------------------------------------------------

--
-- Table structure for table `stock_category`
--

DROP TABLE IF EXISTS `stock_category`;
CREATE TABLE IF NOT EXISTS `stock_category` (
  `category_id` int(11) NOT NULL auto_increment,
  `description` varchar(60) NOT NULL default '',
  `stock_act` varchar(11) default NULL,
  `cogs_act` varchar(11) default NULL,
  `adj_gl_act` varchar(11) default NULL,
  `purch_price_var_act` varchar(11) default NULL,
  PRIMARY KEY  (`category_id`),
  UNIQUE KEY `description` (`description`)
) TYPE=MyISAM  AUTO_INCREMENT=5 ;

-- --------------------------------------------------------

--
-- Table structure for table `stock_master`
--

DROP TABLE IF EXISTS `stock_master`;
CREATE TABLE IF NOT EXISTS `stock_master` (
  `stock_id` varchar(20) NOT NULL default '',
  `category_id` int(11) NOT NULL default '0',
  `tax_type_id` int(11) NOT NULL default '0',
  `description` varchar(200) NOT NULL default '',
  `long_description` tinytext NOT NULL,
  `units` varchar(20) NOT NULL default 'each',
  `mb_flag` char(1) NOT NULL default 'B',
  `sales_account` varchar(11) NOT NULL default '',
  `cogs_account` varchar(11) NOT NULL default '',
  `inventory_account` varchar(11) NOT NULL default '',
  `adjustment_account` varchar(11) NOT NULL default '',
  `assembly_account` varchar(11) NOT NULL default '',
  `dimension_id` int(11) default NULL,
  `dimension2_id` int(11) default NULL,
  `actual_cost` double NOT NULL default '0',
  `last_cost` double NOT NULL default '0',
  `material_cost` double NOT NULL default '0',
  `labour_cost` double NOT NULL default '0',
  `overhead_cost` double NOT NULL default '0',
  `selling` tinyint(4) NOT NULL default '0',
  `depending` varchar(20) NOT NULL default '',
  `barcode` varchar(64) NOT NULL default '',
  `weight` double NOT NULL default '0',
  `image` blob,
  PRIMARY KEY  (`stock_id`),
  KEY `SellingI` (`selling`),
  KEY `DependingI` (`depending`)
) TYPE=InnoDB;


--
-- Table structure for table `item_translations`
--

CREATE TABLE `item_translations` (
  `id` int(11) NOT NULL auto_increment,
  `id_stock` varchar(20) NOT NULL default '',
  `description` varchar(200) NOT NULL default '',
  `long_description` tinytext NOT NULL,
  `areas` varchar(200) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `id_stockI` (`id_stock`),
  KEY `areasI` (`areas`)
) TYPE=InnoDB;


-- --------------------------------------------------------

--
-- Table structure for table `stock_moves`
--

DROP TABLE IF EXISTS `stock_moves`;
CREATE TABLE IF NOT EXISTS `stock_moves` (
  `trans_id` int(11) NOT NULL auto_increment,
  `trans_no` int(11) NOT NULL default '0',
  `stock_id` char(20) NOT NULL default '',
  `type` smallint(6) NOT NULL default '0',
  `loc_code` char(5) NOT NULL default '',
  `tran_date` date NOT NULL default '0000-00-00',
  `person_id` int(11) default NULL,
  `price` double NOT NULL default '0',
  `reference` char(40) NOT NULL default '',
  `qty` double NOT NULL default '1',
  `discount_percent` double NOT NULL default '0',
  `standard_cost` double NOT NULL default '0',
  `visible` tinyint(1) NOT NULL default '1',
  PRIMARY KEY  (`trans_id`),
  KEY `type` (`type`,`trans_no`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `suppliers`
--

DROP TABLE IF EXISTS `suppliers`;
CREATE TABLE IF NOT EXISTS `suppliers` (
  `supplier_id` int(11) NOT NULL auto_increment,
  `supp_name` varchar(60) NOT NULL default '',
  `address` tinytext NOT NULL,
  `email` varchar(100) NOT NULL default '',
  `bank_account` varchar(60) NOT NULL default '',
  `curr_code` char(3) default NULL,
  `payment_terms` int(11) default NULL,
  `dimension_id` int(11) default '0',
  `dimension2_id` int(11) default '0',
  `tax_group_id` int(11) default NULL,
  `purchase_account` varchar(11) default NULL,
  `payable_account` varchar(11) default NULL,
  `payment_discount_account` varchar(11) default NULL,
  PRIMARY KEY  (`supplier_id`)
) TYPE=MyISAM AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `supp_allocations`
--

DROP TABLE IF EXISTS `supp_allocations`;
CREATE TABLE IF NOT EXISTS `supp_allocations` (
  `id` int(11) NOT NULL auto_increment,
  `amt` double unsigned default NULL,
  `date_alloc` date NOT NULL default '0000-00-00',
  `trans_no_from` int(11) default NULL,
  `trans_type_from` int(11) default NULL,
  `trans_no_to` int(11) default NULL,
  `trans_type_to` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `supp_invoice_items`
--

DROP TABLE IF EXISTS `supp_invoice_items`;
CREATE TABLE IF NOT EXISTS `supp_invoice_items` (
  `id` int(11) NOT NULL auto_increment,
  `supp_trans_no` int(11) default NULL,
  `supp_trans_type` int(11) default NULL,
  `gl_code` varchar(11) NOT NULL default '0',
  `grn_item_id` int(11) default NULL,
  `po_detail_item_id` int(11) default NULL,
  `stock_id` varchar(20) NOT NULL default '',
  `description` tinytext,
  `quantity` double NOT NULL default '0',
  `unit_price` double NOT NULL default '0',
  `unit_tax` double NOT NULL default '0',
  `memo_` tinytext,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `supp_invoice_tax_items`
--

DROP TABLE IF EXISTS `supp_invoice_tax_items`;
CREATE TABLE IF NOT EXISTS `supp_invoice_tax_items` (
  `id` int(11) NOT NULL auto_increment,
  `supp_trans_no` int(11) default NULL,
  `supp_trans_type` int(11) default NULL,
  `tax_type_id` int(11) NOT NULL default '0',
  `tax_type_name` varchar(60) default NULL,
  `rate` double NOT NULL default '0',
  `included_in_price` tinyint(1) NOT NULL default '0',
  `amount` double NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `supp_trans`
--

DROP TABLE IF EXISTS `supp_trans`;
CREATE TABLE IF NOT EXISTS `supp_trans` (
  `trans_no` int(11) unsigned NOT NULL default '0',
  `type` smallint(6) unsigned NOT NULL default '0',
  `supplier_id` int(11) unsigned default NULL,
  `reference` tinytext NOT NULL,
  `supp_reference` varchar(60) NOT NULL default '',
  `tran_date` date NOT NULL default '0000-00-00',
  `due_date` date NOT NULL default '0000-00-00',
  `ov_amount` double NOT NULL default '0',
  `ov_discount` double NOT NULL default '0',
  `ov_gst` double NOT NULL default '0',
  `rate` double NOT NULL default '1',
  `alloc` double NOT NULL default '0',
  PRIMARY KEY  (`trans_no`,`type`),
  KEY `supplier_id` (`supplier_id`),
  KEY `SupplierID_2` (`supplier_id`,`supp_reference`),
  KEY `type` (`type`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `sys_types`
--

DROP TABLE IF EXISTS `sys_types`;
CREATE TABLE IF NOT EXISTS `sys_types` (
  `type_id` smallint(6) NOT NULL default '0',
  `type_name` varchar(60) NOT NULL default '',
  `type_no` int(11) NOT NULL default '1',
  `next_reference` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`type_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `tax_groups`
--

DROP TABLE IF EXISTS `tax_groups`;
CREATE TABLE IF NOT EXISTS `tax_groups` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  `tax_shipping` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `tax_group_items`
--

DROP TABLE IF EXISTS `tax_group_items`;
CREATE TABLE IF NOT EXISTS `tax_group_items` (
  `tax_group_id` int(11) NOT NULL default '0',
  `tax_type_id` int(11) NOT NULL default '0',
  `rate` double NOT NULL default '0',
  PRIMARY KEY  (`tax_group_id`,`tax_type_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `tax_types`
--

DROP TABLE IF EXISTS `tax_types`;
CREATE TABLE IF NOT EXISTS `tax_types` (
  `id` int(11) NOT NULL auto_increment,
  `rate` double NOT NULL default '0',
  `sales_gl_code` varchar(11) NOT NULL default '',
  `purchasing_gl_code` varchar(11) NOT NULL default '',
  `name` varchar(60) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`,`rate`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `user_id` varchar(60) NOT NULL default '',
  `password` varchar(100) NOT NULL default '',
  `real_name` varchar(100) NOT NULL default '',
  `full_access` int(11) NOT NULL default '1',
  `phone` varchar(30) NOT NULL default '',
  `email` varchar(100) default NULL,
  `language` varchar(20) default NULL,
  `date_format` tinyint(1) NOT NULL default '0',
  `date_sep` tinyint(1) NOT NULL default '0',
  `tho_sep` tinyint(1) NOT NULL default '0',
  `dec_sep` tinyint(1) NOT NULL default '0',
  `theme` varchar(20) NOT NULL default 'default',
  `page_size` varchar(20) NOT NULL default 'A4',
  `prices_dec` smallint(6) NOT NULL default '2',
  `qty_dec` smallint(6) NOT NULL default '2',
  `rates_dec` smallint(6) NOT NULL default '4',
  `percent_dec` smallint(6) NOT NULL default '1',
  `show_gl` tinyint(1) NOT NULL default '1',
  `show_codes` tinyint(1) NOT NULL default '0',
  `last_visit_date` datetime default NULL,
  PRIMARY KEY  (`user_id`)
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `voided`
--

DROP TABLE IF EXISTS `voided`;
CREATE TABLE IF NOT EXISTS `voided` (
  `type` int(11) NOT NULL default '0',
  `id` int(11) NOT NULL default '0',
  `date_` date NOT NULL default '0000-00-00',
  `memo_` tinytext NOT NULL,
  UNIQUE KEY `id` (`type`,`id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `workcentres`
--

DROP TABLE IF EXISTS `workcentres`;
CREATE TABLE IF NOT EXISTS `workcentres` (
  `id` int(11) NOT NULL auto_increment,
  `name` char(40) NOT NULL default '',
  `description` char(50) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `workorders`
--

DROP TABLE IF EXISTS `workorders`;
CREATE TABLE IF NOT EXISTS `workorders` (
  `id` int(11) NOT NULL auto_increment,
  `wo_ref` varchar(60) NOT NULL default '',
  `loc_code` varchar(5) NOT NULL default '',
  `units_reqd` double NOT NULL default '1',
  `stock_id` varchar(20) NOT NULL default '',
  `date_` date NOT NULL default '0000-00-00',
  `type` tinyint(4) NOT NULL default '0',
  `required_by` date NOT NULL default '0000-00-00',
  `released_date` date NOT NULL default '0000-00-00',
  `units_issued` double NOT NULL default '0',
  `closed` tinyint(1) NOT NULL default '0',
  `released` tinyint(1) NOT NULL default '0',
  `additional_costs` double NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `wo_ref` (`wo_ref`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `wo_issues`
--

DROP TABLE IF EXISTS `wo_issues`;
CREATE TABLE IF NOT EXISTS `wo_issues` (
  `issue_no` int(11) NOT NULL auto_increment,
  `workorder_id` int(11) NOT NULL default '0',
  `reference` varchar(100) default NULL,
  `issue_date` date default NULL,
  `loc_code` varchar(5) default NULL,
  `workcentre_id` int(11) default NULL,
  PRIMARY KEY  (`issue_no`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `wo_issue_items`
--

DROP TABLE IF EXISTS `wo_issue_items`;
CREATE TABLE IF NOT EXISTS `wo_issue_items` (
  `id` int(11) NOT NULL auto_increment,
  `stock_id` varchar(40) default NULL,
  `issue_id` int(11) default NULL,
  `qty_issued` double default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `wo_manufacture`
--

DROP TABLE IF EXISTS `wo_manufacture`;
CREATE TABLE IF NOT EXISTS `wo_manufacture` (
  `id` int(11) NOT NULL auto_increment,
  `reference` varchar(100) default NULL,
  `workorder_id` int(11) NOT NULL default '0',
  `quantity` double NOT NULL default '0',
  `date_` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `wo_requirements`
--

DROP TABLE IF EXISTS `wo_requirements`;
CREATE TABLE IF NOT EXISTS `wo_requirements` (
  `id` int(11) NOT NULL auto_increment,
  `workorder_id` int(11) NOT NULL default '0',
  `stock_id` char(20) NOT NULL default '',
  `workcentre` int(11) NOT NULL default '0',
  `units_req` double NOT NULL default '1',
  `std_cost` double NOT NULL default '0',
  `loc_code` char(5) NOT NULL default '',
  `units_issued` double NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=1 ;

--
-- Dumping data for table `areas`
--

INSERT INTO `areas` VALUES(1, 'CH');

--
-- Dumping data for table `bank_accounts`
--

INSERT INTO `bank_accounts` VALUES('1700', 0, 'Bankkonto', 'N/A', 'N/A', NULL, 'CHF');
INSERT INTO `bank_accounts` VALUES('1705', 0, 'Kasse', 'N/A', 'N/A', NULL, 'CHF');

--
-- Dumping data for table `bank_trans_types`
--

INSERT INTO `bank_trans_types` VALUES(1, 'Kasse');
INSERT INTO `bank_trans_types` VALUES(2, 'Überweisungen');

--
-- Dumping data for table `chart_class`
--

INSERT INTO `chart_class` VALUES(1, 'Aktiven', 1);
INSERT INTO `chart_class` VALUES(2, 'Passiven', 1);
INSERT INTO `chart_class` VALUES(3, 'Erfolg', 0);
INSERT INTO `chart_class` VALUES(4, 'Aufwand', 0);

--
-- Dumping data for table `chart_master`
--

INSERT INTO `chart_master` VALUES('3000', NULL, 'Verkauf', 1, 1);
INSERT INTO `chart_master` VALUES('3010', NULL, 'Verkauf - Wiederverkauf', 1, 1);
INSERT INTO `chart_master` VALUES('3020', NULL, 'Verkauf - Übriges', 1, 1);
INSERT INTO `chart_master` VALUES('3400', NULL, 'Währungsdifferenzen', 1, 0);
INSERT INTO `chart_master` VALUES('5000', NULL, 'Lohnkosten', 2, 0);
INSERT INTO `chart_master` VALUES('5050', NULL, 'Lohnkosten, zurückerhaltene', 2, 0);
INSERT INTO `chart_master` VALUES('4200', NULL, 'Materialverbrauch, Differenzen', 2, 4);
INSERT INTO `chart_master` VALUES('4210', NULL, 'Materialverbrauch', 2, 4);
INSERT INTO `chart_master` VALUES('4220', NULL, 'Materialeinkauf, Differnzen', 2, 0);
INSERT INTO `chart_master` VALUES('4000', NULL, 'Materialeinkauf', 2, 4);
INSERT INTO `chart_master` VALUES('4250', NULL, 'Rabatte, Erhaltene', 2, 0);
INSERT INTO `chart_master` VALUES('4260', NULL, 'Währungsabweichungen', 2, 0);
INSERT INTO `chart_master` VALUES('4300', NULL, 'Frachtkosten, eigene', 2, 4);
INSERT INTO `chart_master` VALUES('4010', NULL, 'Verkaufskosten, Endkunden', 2, 4);
INSERT INTO `chart_master` VALUES('6790', NULL, 'Bankspesen', 5, 4);
INSERT INTO `chart_master` VALUES('6800', NULL, 'Unterhaltskosten', 5, 4);
INSERT INTO `chart_master` VALUES('6810', NULL, 'Prozesskosten/Recht', 5, 4);
INSERT INTO `chart_master` VALUES('6600', NULL, 'Reparaturen Büro/Mobiliar', 5, 4);
INSERT INTO `chart_master` VALUES('6730', NULL, 'Telefon', 5, 4);
INSERT INTO `chart_master` VALUES('8200', NULL, 'Bankzinsen', 52, 0);
INSERT INTO `chart_master` VALUES('6840', NULL, 'Kreditorenkontrolle', 5, 0);
INSERT INTO `chart_master` VALUES('7040', NULL, 'Abschreibungen Büro/Mobiliar', 51, 0);
INSERT INTO `chart_master` VALUES('3800', NULL, 'Frachtkosten, Dritte', 5, 4);
INSERT INTO `chart_master` VALUES('4500', NULL, 'Verpackungsmaterial', 5, 4);
INSERT INTO `chart_master` VALUES('6400', NULL, 'Kommissionen', 5, 0);
INSERT INTO `chart_master` VALUES('3200', NULL, 'Rabatte, pünktliche Zahlungen', 1, 0);
INSERT INTO `chart_master` VALUES('6700', NULL, 'Ausgaben, allgemeine', 5, 4);
INSERT INTO `chart_master` VALUES('5200', NULL, 'Lohnkosten, indirekte', 2, 0);
INSERT INTO `chart_master` VALUES('5210', NULL, 'Gemeinkosten', 5, 0);
INSERT INTO `chart_master` VALUES('1700', NULL, 'Bankkonto', 10, 0);
INSERT INTO `chart_master` VALUES('1705', NULL, 'Kasse', 10, 0);
INSERT INTO `chart_master` VALUES('1710', NULL, 'Fremdwährungskonto', 10, 0);
INSERT INTO `chart_master` VALUES('1500', NULL, 'Debitoren', 20, 0);
INSERT INTO `chart_master` VALUES('1400', NULL, 'Lager Rohwaren', 45, 0);
INSERT INTO `chart_master` VALUES('1410', NULL, 'Lager in Arbeit stehende Güter', 45, 0);
INSERT INTO `chart_master` VALUES('1420', NULL, 'Lager vertiggestellte Güter', 45, 0);
INSERT INTO `chart_master` VALUES('1430', NULL, 'Erhaltene Güter, Verrechnungskonto', 30, 0);
INSERT INTO `chart_master` VALUES('2630', NULL, 'Kreditoren', 30, 0);
INSERT INTO `chart_master` VALUES('2660', NULL, 'MwSt CH', 30, 0);
INSERT INTO `chart_master` VALUES('2662', NULL, 'MwSt CH \(Hardware\)', 30, 0);
INSERT INTO `chart_master` VALUES('2664', NULL, 'MwSt DE', 30, 0);
INSERT INTO `chart_master` VALUES('2680', NULL, 'MwSt CH \(Vorsteuer\)', 30, 0);
INSERT INTO `chart_master` VALUES('2682', NULL, 'MwSt DE \(Vorsteuer\)', 30, 0);
INSERT INTO `chart_master` VALUES('2050', NULL, 'Gewinnvortrag', 50, 0);
INSERT INTO `chart_master` VALUES('2000', NULL, 'Eigenkaptial', 50, 0);

--
-- Dumping data for table `chart_types`
--

INSERT INTO `chart_types` VALUES(1, 'Verkauf', 3, -1);
INSERT INTO `chart_types` VALUES(2, 'Verkaufskosten', 4, -1);
INSERT INTO `chart_types` VALUES(5, 'Ausgaben', 4, -1);
INSERT INTO `chart_types` VALUES(10, 'Kasse/Bank', 1, -1);
INSERT INTO `chart_types` VALUES(20, 'Debitoren', 1, -1);
INSERT INTO `chart_types` VALUES(30, 'Kreditoren', 2, -1);
INSERT INTO `chart_types` VALUES(40, 'Fixkosten', 1, -1);
INSERT INTO `chart_types` VALUES(45, 'Lager', 1, -1);
INSERT INTO `chart_types` VALUES(50, 'Kapital', 2, -1);
INSERT INTO `chart_types` VALUES(51, 'Abschreibungen', 4, -1);
INSERT INTO `chart_types` VALUES(52, 'Finanzauskünfte', 4, -1);

--
-- Dumping data for table `company`
--

INSERT INTO `company` VALUES(1, 'Firmenname', '', '', 1, 1, 'N/A', '', '', '', '', '', 'CHF', '1500', '4250', '2630', '1430', '4260', '4220', '2050', '3800', '3000', '3000', '3200', '1420', '4010', '4210', '3000', '1410', '5000', '', '', '', '', '', '', 0, 10, 10, 1000, 20, 20, 30, 1, 1, 1, 1, 1,'');

--
-- Dumping data for table `credit_status`
--

INSERT INTO `credit_status` VALUES(1, 'Gute Zahlungsmoral', 0);
INSERT INTO `credit_status` VALUES(3, 'Zahlung nur gegen Vorkasse', 1);
INSERT INTO `credit_status` VALUES(4, 'In Liquidation', 1);

--
-- Dumping data for table `currencies`
--

INSERT INTO `currencies` VALUES('Euro', 'EUR', '?', 'Europe', 'Cents');
INSERT INTO `currencies` VALUES('Pounds', 'GBP', '?', 'England', 'Pence');
INSERT INTO `currencies` VALUES('US Dollars', 'USD', '$', 'United States', 'Cents');
INSERT INTO `currencies` VALUES('Franken', 'CHF', '$', 'Switzerland', 'Rappen');

--
-- Dumping data for table `fiscal_year`
--

INSERT INTO `fiscal_year` VALUES(1, '2011-01-01', '2011-12-31', 0);

--
-- Dumping data for table `item_units`
--

INSERT INTO `item_units` VALUES('St.', 'Stück', 0);

--
-- Dumping data for table `locations`
--

INSERT INTO `locations` VALUES('DEF', 'Standard', 'k.A.', '', '', '', '');

--
-- Dumping data for table `movement_types`
--

INSERT INTO `movement_types` VALUES(1, 'Abgleichungen');

--
-- Dumping data for table `payment_terms`
--

INSERT INTO `payment_terms` VALUES(1, 'Zahlungen innerhalb 10 Tage', 10, 0);
INSERT INTO `payment_terms` VALUES(2, 'Zahlungen innerhalb 30 Tage', 30, 0);
INSERT INTO `payment_terms` VALUES(3, 'Nur gegen Zahlung', 1, 0);

--
-- Dumping data for table `salesman`
--

INSERT INTO `salesman` VALUES(1, 'Verkaufsperson', '', '', '', 5, 1000, 4);

--
-- Dumping data for table `sales_types`
--

INSERT INTO `sales_types` VALUES(1, 'Endkunden', 0,1,0);
INSERT INTO `sales_types` VALUES(2, 'Wiederverkauf', 0,1,0);

--
-- Dumping data for table `shippers`
--

INSERT INTO `shippers` VALUES(1, 'Default', '', '', '',0);

--
-- Dumping data for table `stock_category`
--

INSERT INTO `stock_category` VALUES(1, 'Komponenten', NULL, NULL, NULL, NULL);
INSERT INTO `stock_category` VALUES(2, 'Chargen', NULL, NULL, NULL, NULL);
INSERT INTO `stock_category` VALUES(3, 'Systeme', NULL, NULL, NULL, NULL);
INSERT INTO `stock_category` VALUES(4, 'Dienstleistungen', NULL, NULL, NULL, NULL);

--
-- Dumping data for table `sys_types`
--

INSERT INTO `sys_types` VALUES(0, 'Journal - Hauptbuch', 17, '1');
INSERT INTO `sys_types` VALUES(1, 'Ausgaben - Hauptbuch', 7, '1');
INSERT INTO `sys_types` VALUES(2, 'Einkünfte - Hauptbuch', 4, '1');
INSERT INTO `sys_types` VALUES(4, 'Zahlungsverkehr', 3, '1');
INSERT INTO `sys_types` VALUES(10, 'Verkaufsrechnungen', 16, '1');
INSERT INTO `sys_types` VALUES(11, 'Gutschriften', 2, '1');
INSERT INTO `sys_types` VALUES(12, 'Anlieferungen', 6, '1');
INSERT INTO `sys_types` VALUES(13, 'Lieferungen', 1, '1');
INSERT INTO `sys_types` VALUES(16, 'Lieferungen an Standort', 2, '1');
INSERT INTO `sys_types` VALUES(17, 'Lagerabgleichungen', 2, '1');
INSERT INTO `sys_types` VALUES(18, 'Einkaufsbestellungen', 1, '1');
INSERT INTO `sys_types` VALUES(20, 'Lieferantenrechnungen', 6, '1');
INSERT INTO `sys_types` VALUES(21, 'Lieferantengutschriften', 1, '1');
INSERT INTO `sys_types` VALUES(22, 'Lieferantenzahlungen', 3, '1');
INSERT INTO `sys_types` VALUES(25, 'Einkaufslieferungen für Bestellungen', 1, '1');
INSERT INTO `sys_types` VALUES(26, 'Aufträge', 1, '1');
INSERT INTO `sys_types` VALUES(28, 'Aufträge - Punkte', 1, '1');
INSERT INTO `sys_types` VALUES(29, 'Aufträge - In Produktion', 1, '1');
INSERT INTO `sys_types` VALUES(30, 'Verkaufsbestellung', 1, '1');
INSERT INTO `sys_types` VALUES(35, 'Kalkulationsaufwand', 1, '1');
INSERT INTO `sys_types` VALUES(40, 'Masse', 1, '1');

--
-- Dumping data for table `users`
--

INSERT INTO `users` VALUES('admin', '', 'Administrator', 2, '', 'adm@adm.com', 'de_CH', 1, 1, 2, 1, 'default', 'A4', 2, 2, 4, 1, 1, 0, '2011-04-04 12:34:29');

