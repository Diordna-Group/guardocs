# MySQL dump of database 'archivistaerp' on host 'localhost'
# Backup Date and Time: 2011-04-24 19:22
# Built by ArchivistaERP 
# http://www.archivista.ch
# Company: Example Company Inc.
# User: Administrator


DROP TABLE IF EXISTS `areas`;

CREATE TABLE `areas` (
  `area_code` int(11) NOT NULL auto_increment,
  `description` varchar(60) NOT NULL default '',
  PRIMARY KEY  (`area_code`),
  UNIQUE KEY `description` (`description`)
) TYPE=MyISAM AUTO_INCREMENT=5 ;

DROP TABLE IF EXISTS `bank_accounts`;

CREATE TABLE `bank_accounts` (
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
) TYPE=MyISAM ;

DROP TABLE IF EXISTS `bank_trans`;

CREATE TABLE `bank_trans` (
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
) TYPE=InnoDB AUTO_INCREMENT=24 ;

DROP TABLE IF EXISTS `bank_trans_types`;

CREATE TABLE `bank_trans_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM AUTO_INCREMENT=4 ;

DROP TABLE IF EXISTS `bom`;

CREATE TABLE `bom` (
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
) TYPE=MyISAM AUTO_INCREMENT=6 ;

DROP TABLE IF EXISTS `budget_trans`;

CREATE TABLE `budget_trans` (
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

DROP TABLE IF EXISTS `chart_class`;

CREATE TABLE `chart_class` (
  `cid` int(11) NOT NULL default '0',
  `class_name` varchar(60) NOT NULL default '',
  `balance_sheet` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`cid`)
) TYPE=MyISAM ;

DROP TABLE IF EXISTS `chart_master`;

CREATE TABLE `chart_master` (
  `account_code` varchar(11) NOT NULL default '',
  `account_code2` varchar(11) default '',
  `account_name` varchar(60) NOT NULL default '',
  `account_type` int(11) NOT NULL default '0',
  `tax_code` int(11) NOT NULL default '0',
  PRIMARY KEY  (`account_code`),
  KEY `account_code` (`account_code`),
  KEY `account_name` (`account_name`)
) TYPE=MyISAM ;

DROP TABLE IF EXISTS `chart_types`;

CREATE TABLE `chart_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  `class_id` tinyint(1) NOT NULL default '0',
  `parent` int(11) NOT NULL default '-1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM AUTO_INCREMENT=53 ;

DROP TABLE IF EXISTS `comments`;

CREATE TABLE `comments` (
  `type` int(11) NOT NULL default '0',
  `id` int(11) NOT NULL default '0',
  `date_` date default '0000-00-00',
  `memo_` tinytext
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `company`;

CREATE TABLE `company` (
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
) TYPE=MyISAM ;

DROP TABLE IF EXISTS `credit_status`;

CREATE TABLE `credit_status` (
  `id` int(11) NOT NULL auto_increment,
  `reason_description` char(100) NOT NULL default '',
  `dissallow_invoices` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `reason_description` (`reason_description`)
) TYPE=MyISAM AUTO_INCREMENT=5 ;

DROP TABLE IF EXISTS `currencies`;

CREATE TABLE `currencies` (
  `currency` varchar(60) NOT NULL default '',
  `curr_abrev` char(3) NOT NULL default '',
  `curr_symbol` varchar(10) NOT NULL default '',
  `country` varchar(100) NOT NULL default '',
  `hundreds_name` varchar(15) NOT NULL default '',
  PRIMARY KEY  (`curr_abrev`)
) TYPE=MyISAM ;

DROP TABLE IF EXISTS `cust_allocations`;

CREATE TABLE `cust_allocations` (
  `id` int(11) NOT NULL auto_increment,
  `amt` double unsigned default NULL,
  `date_alloc` date NOT NULL default '0000-00-00',
  `trans_no_from` int(11) default NULL,
  `trans_type_from` int(11) default NULL,
  `trans_no_to` int(11) default NULL,
  `trans_type_to` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=9 ;

DROP TABLE IF EXISTS `cust_branch`;

CREATE TABLE `cust_branch` (
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
) TYPE=MyISAM AUTO_INCREMENT=8 ;

DROP TABLE IF EXISTS `debtor_trans`;

CREATE TABLE `debtor_trans` (
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
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `debtor_trans_details`;

CREATE TABLE `debtor_trans_details` (
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
) TYPE=InnoDB AUTO_INCREMENT=46 ;

DROP TABLE IF EXISTS `debtor_trans_tax_details`;

CREATE TABLE `debtor_trans_tax_details` (
  `id` int(11) NOT NULL auto_increment,
  `debtor_trans_no` int(11) default NULL,
  `debtor_trans_type` int(11) default NULL,
  `tax_type_id` int(11) NOT NULL default '0',
  `tax_type_name` varchar(60) default NULL,
  `rate` double NOT NULL default '0',
  `included_in_price` tinyint(1) NOT NULL default '0',
  `amount` double NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=40 ;

DROP TABLE IF EXISTS `debtors_master`;

CREATE TABLE `debtors_master` (
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
) TYPE=MyISAM AUTO_INCREMENT=5 ;

DROP TABLE IF EXISTS `dimensions`;

CREATE TABLE `dimensions` (
  `id` int(11) NOT NULL auto_increment,
  `reference` varchar(60) NOT NULL default '',
  `name` varchar(60) NOT NULL default '',
  `type_` tinyint(1) NOT NULL default '1',
  `closed` tinyint(1) NOT NULL default '0',
  `date_` date NOT NULL default '0000-00-00',
  `due_date` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `reference` (`reference`)
) TYPE=InnoDB AUTO_INCREMENT=4 ;

DROP TABLE IF EXISTS `exchange_rates`;

CREATE TABLE `exchange_rates` (
  `id` int(11) NOT NULL auto_increment,
  `curr_code` char(3) NOT NULL default '',
  `rate_buy` double NOT NULL default '0',
  `rate_sell` double NOT NULL default '0',
  `date_` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `curr_code` (`curr_code`,`date_`)
) TYPE=MyISAM AUTO_INCREMENT=13 ;

DROP TABLE IF EXISTS `fiscal_year`;

CREATE TABLE `fiscal_year` (
  `id` int(11) NOT NULL auto_increment,
  `begin` date default '0000-00-00',
  `end` date default '0000-00-00',
  `closed` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=7 ;

DROP TABLE IF EXISTS `gl_trans`;

CREATE TABLE `gl_trans` (
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
) TYPE=InnoDB AUTO_INCREMENT=170 ;

DROP TABLE IF EXISTS `grn_batch`;

CREATE TABLE `grn_batch` (
  `id` int(11) NOT NULL auto_increment,
  `supplier_id` int(11) NOT NULL default '0',
  `purch_order_no` int(11) default NULL,
  `reference` varchar(60) NOT NULL default '',
  `delivery_date` date NOT NULL default '0000-00-00',
  `loc_code` varchar(5) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=13 ;

DROP TABLE IF EXISTS `grn_items`;

CREATE TABLE `grn_items` (
  `id` int(11) NOT NULL auto_increment,
  `grn_batch_id` int(11) default NULL,
  `po_detail_item` int(11) NOT NULL default '0',
  `item_code` varchar(20) NOT NULL default '',
  `description` tinytext,
  `qty_recd` double NOT NULL default '0',
  `quantity_inv` double NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=17 ;

DROP TABLE IF EXISTS `item_tax_type_exemptions`;

CREATE TABLE `item_tax_type_exemptions` (
  `item_tax_type_id` int(11) NOT NULL default '0',
  `tax_type_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`item_tax_type_id`,`tax_type_id`)
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `item_tax_types`;

CREATE TABLE `item_tax_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  `exempt` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=InnoDB AUTO_INCREMENT=3 ;

DROP TABLE IF EXISTS `item_units`;

CREATE TABLE `item_units` (
  `abbr` varchar(20) NOT NULL default '',
  `name` varchar(40) NOT NULL default '',
  `decimals` tinyint(2) NOT NULL default '0',
  PRIMARY KEY  (`abbr`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM COMMENT='units of measure' ;

DROP TABLE IF EXISTS `loc_stock`;

CREATE TABLE `loc_stock` (
  `loc_code` char(5) NOT NULL default '',
  `stock_id` char(20) NOT NULL default '',
  `reorder_level` bigint(20) NOT NULL default '0',
  PRIMARY KEY  (`loc_code`,`stock_id`),
  KEY `stock_id` (`stock_id`)
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `locations`;

CREATE TABLE `locations` (
  `loc_code` varchar(5) NOT NULL default '',
  `location_name` varchar(60) NOT NULL default '',
  `delivery_address` tinytext NOT NULL,
  `phone` varchar(30) NOT NULL default '',
  `fax` varchar(30) NOT NULL default '',
  `email` varchar(100) NOT NULL default '',
  `contact` varchar(30) NOT NULL default '',
  PRIMARY KEY  (`loc_code`)
) TYPE=MyISAM ;

DROP TABLE IF EXISTS `movement_types`;

CREATE TABLE `movement_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM AUTO_INCREMENT=2 ;

DROP TABLE IF EXISTS `payment_terms`;

CREATE TABLE `payment_terms` (
  `terms_indicator` int(11) NOT NULL auto_increment,
  `terms` char(80) NOT NULL default '',
  `days_before_due` smallint(6) NOT NULL default '0',
  `day_in_following_month` smallint(6) NOT NULL default '0',
  PRIMARY KEY  (`terms_indicator`),
  UNIQUE KEY `terms` (`terms`)
) TYPE=MyISAM AUTO_INCREMENT=5 ;

DROP TABLE IF EXISTS `prices`;

CREATE TABLE `prices` (
  `id` int(11) NOT NULL auto_increment,
  `stock_id` varchar(20) NOT NULL default '',
  `sales_type_id` int(11) NOT NULL default '0',
  `curr_abrev` char(3) NOT NULL default '',
  `price` double NOT NULL default '0',
  `factor` double NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `price` (`stock_id`,`sales_type_id`,`curr_abrev`)
) TYPE=MyISAM AUTO_INCREMENT=13 ;

DROP TABLE IF EXISTS `purch_data`;

CREATE TABLE `purch_data` (
  `supplier_id` int(11) NOT NULL default '0',
  `stock_id` char(20) NOT NULL default '',
  `price` double NOT NULL default '0',
  `suppliers_uom` char(50) NOT NULL default '',
  `conversion_factor` double NOT NULL default '1',
  `supplier_description` char(50) NOT NULL default '',
  PRIMARY KEY  (`supplier_id`,`stock_id`)
) TYPE=MyISAM ;

DROP TABLE IF EXISTS `purch_order_details`;

CREATE TABLE `purch_order_details` (
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
) TYPE=InnoDB AUTO_INCREMENT=18 ;

DROP TABLE IF EXISTS `purch_orders`;

CREATE TABLE `purch_orders` (
  `order_no` int(11) NOT NULL auto_increment,
  `version` tinyint(1) unsigned NOT NULL default '0',
  `supplier_id` int(11) NOT NULL default '0',
  `comments` tinytext,
  `ord_date` date NOT NULL default '0000-00-00',
  `reference` tinytext NOT NULL,
  `requisition_no` tinytext,
  `into_stock_location` varchar(5) NOT NULL default '',
  `delivery_address` tinytext NOT NULL,
  PRIMARY KEY  (`order_no`)
) TYPE=InnoDB AUTO_INCREMENT=14 ;

DROP TABLE IF EXISTS `refs`;

CREATE TABLE `refs` (
  `id` int(11) NOT NULL default '0',
  `type` int(11) NOT NULL default '0',
  `reference` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`id`,`type`)
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `sales_order_details`;

CREATE TABLE `sales_order_details` (
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
) TYPE=InnoDB AUTO_INCREMENT=24 ;

DROP TABLE IF EXISTS `sales_orders`;

CREATE TABLE `sales_orders` (
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
) TYPE=InnoDB AUTO_INCREMENT=22 ;

DROP TABLE IF EXISTS `sales_types`;

CREATE TABLE `sales_types` (
  `id` int(11) NOT NULL auto_increment,
  `sales_type` char(50) NOT NULL default '',
  `tax_included` int(1) NOT NULL default '0',
  `price_factor` double NOT NULL default '1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `sales_type` (`sales_type`)
) TYPE=MyISAM AUTO_INCREMENT=3 ;

DROP TABLE IF EXISTS `salesman`;

CREATE TABLE `salesman` (
  `salesman_code` int(11) NOT NULL auto_increment,
  `salesman_name` varchar(60) NOT NULL default '',
  `salesman_phone` varchar(30) NOT NULL default '',
  `salesman_fax` varchar(30) NOT NULL default '',
  `salesman_email` varchar(100) NOT NULL default '',
  `provision` double NOT NULL default '0',
  `break_pt` double NOT NULL default '0',
  `provision2` double NOT NULL default '0',
  PRIMARY KEY  (`salesman_code`),
  UNIQUE KEY `salesman_name` (`salesman_name`)
) TYPE=MyISAM AUTO_INCREMENT=3 ;

DROP TABLE IF EXISTS `shippers`;

CREATE TABLE `shippers` (
  `shipper_id` int(11) NOT NULL auto_increment,
  `shipper_name` varchar(60) NOT NULL default '',
  `phone` varchar(30) NOT NULL default '',
  `contact` tinytext NOT NULL,
  `address` tinytext NOT NULL,
  `shipper_defcost` double NOT NULL default '0',
  PRIMARY KEY  (`shipper_id`),
  UNIQUE KEY `name` (`shipper_name`)
) TYPE=MyISAM AUTO_INCREMENT=3 ;

DROP TABLE IF EXISTS `stock_category`;

CREATE TABLE `stock_category` (
  `category_id` int(11) NOT NULL auto_increment,
  `description` varchar(60) NOT NULL default '',
  `stock_act` varchar(11) default NULL,
  `cogs_act` varchar(11) default NULL,
  `adj_gl_act` varchar(11) default NULL,
  `purch_price_var_act` varchar(11) default NULL,
  PRIMARY KEY  (`category_id`),
  UNIQUE KEY `description` (`description`)
) TYPE=MyISAM AUTO_INCREMENT=5 ;

DROP TABLE IF EXISTS `stock_master`;

CREATE TABLE `stock_master` (
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


DROP TABLE IF EXISTS `item_translations`;
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


DROP TABLE IF EXISTS `stock_moves`;

CREATE TABLE `stock_moves` (
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
) TYPE=InnoDB AUTO_INCREMENT=42 ;

DROP TABLE IF EXISTS `supp_allocations`;

CREATE TABLE `supp_allocations` (
  `id` int(11) NOT NULL auto_increment,
  `amt` double unsigned default NULL,
  `date_alloc` date NOT NULL default '0000-00-00',
  `trans_no_from` int(11) default NULL,
  `trans_type_from` int(11) default NULL,
  `trans_no_to` int(11) default NULL,
  `trans_type_to` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=10 ;

DROP TABLE IF EXISTS `supp_invoice_items`;

CREATE TABLE `supp_invoice_items` (
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
) TYPE=InnoDB AUTO_INCREMENT=22 ;

DROP TABLE IF EXISTS `supp_invoice_tax_items`;

CREATE TABLE `supp_invoice_tax_items` (
  `id` int(11) NOT NULL auto_increment,
  `supp_trans_no` int(11) default NULL,
  `supp_trans_type` int(11) default NULL,
  `tax_type_id` int(11) NOT NULL default '0',
  `tax_type_name` varchar(60) default NULL,
  `rate` double NOT NULL default '0',
  `included_in_price` tinyint(1) NOT NULL default '0',
  `amount` double NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=5 ;

DROP TABLE IF EXISTS `supp_trans`;

CREATE TABLE `supp_trans` (
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
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `suppliers`;

CREATE TABLE `suppliers` (
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
) TYPE=MyISAM AUTO_INCREMENT=5 ;

DROP TABLE IF EXISTS `sys_types`;

CREATE TABLE `sys_types` (
  `type_id` smallint(6) NOT NULL default '0',
  `type_name` varchar(60) NOT NULL default '',
  `type_no` int(11) NOT NULL default '1',
  `next_reference` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`type_id`)
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `tax_group_items`;

CREATE TABLE `tax_group_items` (
  `tax_group_id` int(11) NOT NULL default '0',
  `tax_type_id` int(11) NOT NULL default '0',
  `rate` double NOT NULL default '0',
  `included_in_price` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`tax_group_id`,`tax_type_id`)
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `tax_groups`;

CREATE TABLE `tax_groups` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  `tax_shipping` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=InnoDB AUTO_INCREMENT=5 ;

DROP TABLE IF EXISTS `tax_types`;

CREATE TABLE `tax_types` (
  `id` int(11) NOT NULL auto_increment,
  `rate` double NOT NULL default '0',
  `sales_gl_code` varchar(11) NOT NULL default '',
  `purchasing_gl_code` varchar(11) NOT NULL default '',
  `name` varchar(60) NOT NULL default '',
  `out` tinyint(1) NOT NULL default '1',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=4 ;

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
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
) TYPE=MyISAM ;

DROP TABLE IF EXISTS `voided`;

CREATE TABLE `voided` (
  `type` int(11) NOT NULL default '0',
  `id` int(11) NOT NULL default '0',
  `date_` date NOT NULL default '0000-00-00',
  `memo_` tinytext NOT NULL,
  UNIQUE KEY `id` (`type`,`id`)
) TYPE=InnoDB ;

DROP TABLE IF EXISTS `wo_issue_items`;

CREATE TABLE `wo_issue_items` (
  `id` int(11) NOT NULL auto_increment,
  `stock_id` varchar(40) default NULL,
  `issue_id` int(11) default NULL,
  `qty_issued` double default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=2 ;

DROP TABLE IF EXISTS `wo_issues`;

CREATE TABLE `wo_issues` (
  `issue_no` int(11) NOT NULL auto_increment,
  `workorder_id` int(11) NOT NULL default '0',
  `reference` varchar(100) default NULL,
  `issue_date` date default NULL,
  `loc_code` varchar(5) default NULL,
  `workcentre_id` int(11) default NULL,
  PRIMARY KEY  (`issue_no`)
) TYPE=InnoDB AUTO_INCREMENT=2 ;

DROP TABLE IF EXISTS `wo_manufacture`;

CREATE TABLE `wo_manufacture` (
  `id` int(11) NOT NULL auto_increment,
  `reference` varchar(100) default NULL,
  `workorder_id` int(11) NOT NULL default '0',
  `quantity` double NOT NULL default '0',
  `date_` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=3 ;

DROP TABLE IF EXISTS `wo_requirements`;

CREATE TABLE `wo_requirements` (
  `id` int(11) NOT NULL auto_increment,
  `workorder_id` int(11) NOT NULL default '0',
  `stock_id` char(20) NOT NULL default '',
  `workcentre` int(11) NOT NULL default '0',
  `units_req` double NOT NULL default '1',
  `std_cost` double NOT NULL default '0',
  `loc_code` char(5) NOT NULL default '',
  `units_issued` double NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB AUTO_INCREMENT=29 ;

DROP TABLE IF EXISTS `workcentres`;

CREATE TABLE `workcentres` (
  `id` int(11) NOT NULL auto_increment,
  `name` char(40) NOT NULL default '',
  `description` char(50) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM AUTO_INCREMENT=2 ;

DROP TABLE IF EXISTS `workorders`;

CREATE TABLE `workorders` (
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
) TYPE=InnoDB AUTO_INCREMENT=8 ;

INSERT INTO `areas` VALUES ('1', 'USA');
INSERT INTO `areas` VALUES ('2', 'Far East');
INSERT INTO `areas` VALUES ('3', 'Africa');
INSERT INTO `areas` VALUES ('4', 'Europe');

INSERT INTO `bank_accounts` VALUES ('1700', '0', 'Current account', 'N/A', 'N/A', NULL, 'USD');
INSERT INTO `bank_accounts` VALUES ('1705', '0', 'Petty Cash account', 'N/A', 'N/A', NULL, 'USD');
INSERT INTO `bank_accounts` VALUES ('1710', '0', 'Saving account', '10001000', 'Saving Bank', NULL, 'GBP');

INSERT INTO `bank_trans` VALUES ('1', '12', '2', '1700', '111', '2011-01-18', '1', '5000', '0', '0', '2', '1');
INSERT INTO `bank_trans` VALUES ('2', '12', '3', '1700', '112', '2011-01-18', '1', '240', '0', '0', '2', '2');
INSERT INTO `bank_trans` VALUES ('3', '12', '4', '1700', '113', '2011-01-18', '1', '360', '0', '0', '2', '2');
INSERT INTO `bank_trans` VALUES ('4', '12', '5', '1700', '114', '2011-01-18', '1', '500', '0', '0', '2', '1');
INSERT INTO `bank_trans` VALUES ('5', '1', '2', '1700', '1', '2011-01-18', '1', '-25', '0', '0', '0', NULL);
INSERT INTO `bank_trans` VALUES ('6', '1', '3', '1705', '2', '2011-01-18', '1', '-250', '0', '0', '0', NULL);
INSERT INTO `bank_trans` VALUES ('7', '1', '4', '1700', '3', '2011-01-18', '1', '-555', '0', '0', '4', '1');
INSERT INTO `bank_trans` VALUES ('8', '4', '2', '1700', '4', '2011-01-18', '1', '-300', '0', '0', '0', NULL);
INSERT INTO `bank_trans` VALUES ('9', '4', '2', '1710', '4', '2011-01-18', '1', '250', '0', '0', '0', NULL);
INSERT INTO `bank_trans` VALUES ('10', '22', '2', '1700', '1', '2011-01-18', '1', '-5000', '0', '0', '3', '1');
INSERT INTO `bank_trans` VALUES ('11', '22', '3', '1710', '2', '2011-01-18', '1', '-3300', '0', '0', '3', '2');
INSERT INTO `bank_trans` VALUES ('12', '2', '2', '1700', '11', '2011-01-20', '1', '1050', '0', '0', '0', NULL);
INSERT INTO `bank_trans` VALUES ('13', '12', '6', '1700', '115', '2011-01-30', '1', '200', '0', '0', '2', '1');
INSERT INTO `bank_trans` VALUES ('14', '1', '5', '1700', '4', '2011-01-30', '1', '-200', '0', '0', '4', '1');
INSERT INTO `bank_trans` VALUES ('15', '2', '3', '1700', '12', '2011-01-30', '3', '70', '0', '0', '4', '2');
INSERT INTO `bank_trans` VALUES ('16', '4', '3', '1700', '5', '2011-03-09', '1', '-222', '0', '0', '0', NULL);
INSERT INTO `bank_trans` VALUES ('17', '4', '3', '1705', '5', '2011-03-09', '1', '222', '0', '0', '0', NULL);
INSERT INTO `bank_trans` VALUES ('18', '2', '4', '1700', '13', '2011-03-09', '3', '200', '0', '0', '2', '1');
INSERT INTO `bank_trans` VALUES ('19', '1', '6', '1700', '5', '2011-03-22', '1', '-200', '0', '0', '3', '1');
INSERT INTO `bank_trans` VALUES ('20', '1', '7', '1700', '6', '2011-03-22', '1', '-125', '0', '0', '0', 'Gas Transport');
INSERT INTO `bank_trans` VALUES ('21', '12', '7', '1700', '6', '2011-03-06', '1', '100', '0', '0', '2', '1');
INSERT INTO `bank_trans` VALUES ('22', '12', '8', '1700', '7', '2011-03-06', '1', '100', '0', '0', '2', '4');
INSERT INTO `bank_trans` VALUES ('23', '12', '9', '1700', '8', '2011-03-07', '1', '2000', '0', '0', '2', '1');

INSERT INTO `bank_trans_types` VALUES ('1', 'Cash');
INSERT INTO `bank_trans_types` VALUES ('2', 'Cheque');
INSERT INTO `bank_trans_types` VALUES ('3', 'Transfer');

INSERT INTO `bom` VALUES ('1', '3400', '102', '1', 'DEF', '1');
INSERT INTO `bom` VALUES ('2', '3400', '103', '1', 'DEF', '1');
INSERT INTO `bom` VALUES ('3', '3400', '104', '1', 'DEF', '1');
INSERT INTO `bom` VALUES ('4', '3400', '201', '1', 'DEF', '1');
INSERT INTO `bom` VALUES ('5', '3400', '103', '1', 'CWA', '1');

INSERT INTO `chart_class` VALUES ('1', 'Assets', '1');
INSERT INTO `chart_class` VALUES ('2', 'Liabilities', '1');
INSERT INTO `chart_class` VALUES ('3', 'Income', '0');
INSERT INTO `chart_class` VALUES ('4', 'Costs', '0');
INSERT INTO `chart_class` VALUES ('5', 'Gross', '0');

INSERT INTO `chart_master` VALUES ('3000', NULL, 'Sales', '1', '1');
INSERT INTO `chart_master` VALUES ('3010', NULL, 'Sales  - Wholesale', '1', '1');
INSERT INTO `chart_master` VALUES ('3020', NULL, 'Sales of Other items', '1', '1');
INSERT INTO `chart_master` VALUES ('3400', NULL, 'Difference On Exchange', '1', '0');
INSERT INTO `chart_master` VALUES ('5000', NULL, 'Direct Labour', '2', '0');
INSERT INTO `chart_master` VALUES ('5050', NULL, 'Direct Labour Recovery', '2', '0');
INSERT INTO `chart_master` VALUES ('4200', NULL, 'Material Usage Varaiance', '2', '4');
INSERT INTO `chart_master` VALUES ('4210', NULL, 'Consumable Materials', '2', '4');
INSERT INTO `chart_master` VALUES ('4220', NULL, 'Purchase price Variance', '2', '0');
INSERT INTO `chart_master` VALUES ('4000', NULL, 'Purchases of materials', '2', '4');
INSERT INTO `chart_master` VALUES ('4250', NULL, 'Discounts Received', '2', '0');
INSERT INTO `chart_master` VALUES ('4260', NULL, 'Exchange Variation', '2', '0');
INSERT INTO `chart_master` VALUES ('4300', NULL, 'Freight Inwards', '2', '4');
INSERT INTO `chart_master` VALUES ('4010', NULL, 'Cost of Goods Sold - Retail', '2', '4');
INSERT INTO `chart_master` VALUES ('6790', NULL, 'Bank Charges', '5', '4');
INSERT INTO `chart_master` VALUES ('6800', NULL, 'Entertainments', '5', '4');
INSERT INTO `chart_master` VALUES ('6810', NULL, 'Legal Expenses', '5', '4');
INSERT INTO `chart_master` VALUES ('6600', NULL, 'Repairs and Maintenance Office', '5', '4');
INSERT INTO `chart_master` VALUES ('6730', NULL, 'phone', '5', '4');
INSERT INTO `chart_master` VALUES ('8200', NULL, 'Bank Interest', '52', '0');
INSERT INTO `chart_master` VALUES ('6840', NULL, 'Credit Control', '5', '0');
INSERT INTO `chart_master` VALUES ('7040', NULL, 'Depreciation Office Equipment', '51', '0');
INSERT INTO `chart_master` VALUES ('3800', NULL, 'Freight Outwards', '5', '4');
INSERT INTO `chart_master` VALUES ('4500', NULL, 'Packaging', '5', '4');
INSERT INTO `chart_master` VALUES ('6400', NULL, 'Commissions', '5', '0');
INSERT INTO `chart_master` VALUES ('3200', NULL, 'Prompt Payment Discounts', '1', '0');
INSERT INTO `chart_master` VALUES ('6700', NULL, 'General Expenses', '5', '4');
INSERT INTO `chart_master` VALUES ('5200', NULL, 'Indirect Labour', '2', '0');
INSERT INTO `chart_master` VALUES ('5210', NULL, 'Overhead Recovery', '5', '0');
INSERT INTO `chart_master` VALUES ('1700', NULL, 'Bank account', '10', '0');
INSERT INTO `chart_master` VALUES ('1705', NULL, 'Petty Cash', '10', '0');
INSERT INTO `chart_master` VALUES ('1710', NULL, 'Foreign currency account', '10', '0');
INSERT INTO `chart_master` VALUES ('1500', NULL, 'Accounts Receivable', '20', '0');
INSERT INTO `chart_master` VALUES ('1400', NULL, 'Stocks of Raw Materials', '45', '0');
INSERT INTO `chart_master` VALUES ('1410', NULL, 'Stocks of Work In Progress', '45', '0');
INSERT INTO `chart_master` VALUES ('1420', NULL, 'Stocks of Finsihed Goods', '45', '0');
INSERT INTO `chart_master` VALUES ('1430', NULL, 'Goods Received Clearing account', '30', '0');
INSERT INTO `chart_master` VALUES ('2630', NULL, 'Accounts Payable', '30', '0');
INSERT INTO `chart_master` VALUES ('2660', NULL, 'VAT out 5', '30', '0');
INSERT INTO `chart_master` VALUES ('2662', NULL, 'VAT out 1', '30', '0');
INSERT INTO `chart_master` VALUES ('2664', NULL, 'VAT out 25', '30', '0');
INSERT INTO `chart_master` VALUES ('2680', NULL, 'VAT In 5', '30', '0');
INSERT INTO `chart_master` VALUES ('2682', NULL, 'VAT In 25', '30', '0');
INSERT INTO `chart_master` VALUES ('2050', NULL, 'Retained Earnings', '50', '0');
INSERT INTO `chart_master` VALUES ('2000', NULL, 'Share Capital', '50', '0');

INSERT INTO `chart_types` VALUES ('1', 'Sales', '3', '-1');
INSERT INTO `chart_types` VALUES ('2', 'Cost of Sales', '4', '-1');
INSERT INTO `chart_types` VALUES ('5', 'Expenses', '4', '-1');
INSERT INTO `chart_types` VALUES ('10', 'Cash/Bank', '1', '-1');
INSERT INTO `chart_types` VALUES ('20', 'Accounts Receivable', '1', '-1');
INSERT INTO `chart_types` VALUES ('30', 'Accounts Payable', '2', '-1');
INSERT INTO `chart_types` VALUES ('40', 'Fixed Assets', '1', '-1');
INSERT INTO `chart_types` VALUES ('45', 'Inventory', '1', '-1');
INSERT INTO `chart_types` VALUES ('50', 'Equity', '2', '-1');
INSERT INTO `chart_types` VALUES ('51', 'Depreciations', '4', '-1');
INSERT INTO `chart_types` VALUES ('52', 'Financials', '4', '-1');

INSERT INTO `comments` VALUES ('17', '2', '2011-01-18', 'initial balances');
INSERT INTO `comments` VALUES ('10', '6', '2011-01-30', 'Hi there you got it!');
INSERT INTO `comments` VALUES ('12', '6', '2011-01-30', 'This is good');
INSERT INTO `comments` VALUES ('1', '5', '2011-01-30', 'Total Gas');
INSERT INTO `comments` VALUES ('0', '6', '2011-02-02', 'A big memo');
INSERT INTO `comments` VALUES ('10', '7', '2011-02-03', 'Another big memo, which looks good.');
INSERT INTO `comments` VALUES ('4', '3', '2011-03-09', 'A little cash up front.');
INSERT INTO `comments` VALUES ('26', '6', '2011-02-28', 'nowe ');
INSERT INTO `comments` VALUES ('40', '2', '2011-01-15', 'Another project');

INSERT INTO `company` VALUES ('1', 'Example Company Inc.', '987654321', '123123123', '1', '1', 'N/A', '202-122320', '202-18889123', 'delta@delta.com', 'logo_archivistaerp.jpg', 'DownTown', 'USD', '1500', '4250', '2630', '1430', '4260', '4220', '2050', '3800', '3000', '3000', '3200', '1420', '4010', '4210', '3000', '1410', '5000', '', '', '', '', '', '', '0', '10', '10', '1000', '20', '20', '30', '1', '6', '0', '0', '0','');

INSERT INTO `credit_status` VALUES ('1', 'Good History', '0');
INSERT INTO `credit_status` VALUES ('3', 'No more work until payment received', '1');
INSERT INTO `credit_status` VALUES ('4', 'In liquidation', '1');

INSERT INTO `currencies` VALUES ('Kronor', 'SEK', 'kr', 'Sweden', '?ren');
INSERT INTO `currencies` VALUES ('Kroner', 'DKK', 'kr.', 'Denmark', '?re');
INSERT INTO `currencies` VALUES ('Euro', 'EUR', '?', 'Europe', 'Cents');
INSERT INTO `currencies` VALUES ('Pounds', 'GBP', '?', 'England', 'Pence');
INSERT INTO `currencies` VALUES ('US Dollars', 'USD', '$', 'United States', 'Cents');

INSERT INTO `cust_allocations` VALUES ('1', '200', '2011-01-30', '6', '12', '6', '10');
INSERT INTO `cust_allocations` VALUES ('4', '133', '2011-03-09', '4', '2', '6', '10');
INSERT INTO `cust_allocations` VALUES ('5', '135', '2011-03-06', '1', '11', '5', '10');
INSERT INTO `cust_allocations` VALUES ('6', '135', '2011-03-06', '2', '11', '6', '10');
INSERT INTO `cust_allocations` VALUES ('7', '135', '2011-03-06', '3', '11', '4', '10');
INSERT INTO `cust_allocations` VALUES ('8', '125', '2011-03-07', '4', '11', '4', '11');

INSERT INTO `cust_branch` VALUES ('1', '1', 'Main', '', '1', '1', '', '', 'Lucky Luke Inc.', 'lucky@luke.com', 'DEF', '1', '3000', '3000', '1500', '3200', '1', '0', 'The Road','en_US');
INSERT INTO `cust_branch` VALUES ('2', '1', 'Service divison', '', '4', '1', '', '', '', '', 'DEF', '2', '3000', '3000', '1500', '3200', '1', '0', 'Another Road','en_US');
INSERT INTO `cust_branch` VALUES ('3', '2', 'Main', '', '4', '2', '', '', 'Money Makers Ltd.', '', 'DEF', '2', '3000', '3000', '1500', '3200', '1', '0', '','en_US');
INSERT INTO `cust_branch` VALUES ('5', '3', 'Main', '', '4', '1', '', '', 'Junk Beer ApS', '', 'CWA', '2', '3000', '3000', '1500', '3200', '1', '0', '','en_US');
INSERT INTO `cust_branch` VALUES ('6', '4', 'Johny Bravo', 'Never Mind 13', '1', '1', '123', '', 'Johny Bravo', '', 'DEF', '1', '3000', '3000', '1500', '3200', '1', '0', 'Never Mind 13','en_US');
INSERT INTO `cust_branch` VALUES ('7', '3', 'Junk Beer ApS', 'N/A', '1', '1', '1223123', '', 'junk@junkbeer.dk', '', 'DEF', '1', '3000', '3000', '1500', '3200', '1', '0', 'N/A','en_US');

INSERT INTO `debtor_trans` VALUES ('1', '10', '0', '4', '6', '2011-03-06', '2011-03-16', '0', '1', '1', '125', '0', '10', '0', '0', '0', '1', '1', '1');
INSERT INTO `debtor_trans` VALUES ('1', '11', '0', '4', '6', '2011-03-06', '0000-00-00', '0', '1', '5', '125', '0', '10', '0', '0', '0', '1', '1', '5');
INSERT INTO `debtor_trans` VALUES ('1', '13', '1', '4', '6', '2011-03-06', '2011-03-16', '0', '1', '1', '125', '0', '10', '0', '0', '0', '1', '1', '1');
INSERT INTO `debtor_trans` VALUES ('2', '10', '0', '4', '6', '2011-03-06', '2011-03-06', '1', '1', '2', '125', '0', '10', '0', '0', '0', '1', '1', '2');
INSERT INTO `debtor_trans` VALUES ('2', '11', '0', '4', '6', '2011-03-06', '0000-00-00', '1', '1', '6', '125', '0', '10', '0', '0', '135', '1', '1', '6');
INSERT INTO `debtor_trans` VALUES ('2', '13', '1', '4', '6', '2011-03-06', '2011-03-06', 'auto', '1', '2', '125', '0', '10', '0', '0', '0', '1', '1', '2');
INSERT INTO `debtor_trans` VALUES ('3', '10', '0', '4', '6', '2011-03-06', '2011-03-06', '2', '1', '3', '125', '0', '10', '0', '0', '0', '1', '1', '3');
INSERT INTO `debtor_trans` VALUES ('3', '11', '0', '4', '6', '2011-03-06', '0000-00-00', '2', '1', '4', '125', '0', '10', '0', '0', '135', '1', '1', '4');
INSERT INTO `debtor_trans` VALUES ('3', '13', '1', '4', '6', '2011-03-06', '2011-03-06', 'auto', '1', '3', '125', '0', '10', '0', '0', '0', '1', '1', '3');
INSERT INTO `debtor_trans` VALUES ('4', '10', '1', '4', '6', '2011-03-06', '2011-03-06', '3', '1', '4', '125', '0', '10', '0', '0', '135', '1', '1', '4');
INSERT INTO `debtor_trans` VALUES ('4', '11', '0', '1', '1', '2011-03-07', '0000-00-00', '3', '1', '0', '100', '25', '0', '0', '0', '250', '1', '1', '0');
INSERT INTO `debtor_trans` VALUES ('4', '13', '1', '4', '6', '2011-03-06', '2011-03-06', 'auto', '1', '4', '125', '0', '10', '0', '0', '0', '1', '1', '4');
INSERT INTO `debtor_trans` VALUES ('5', '10', '1', '4', '6', '2011-03-06', '2011-03-06', '4', '1', '5', '125', '0', '10', '0', '0', '135', '1', '1', '5');
INSERT INTO `debtor_trans` VALUES ('5', '13', '1', '4', '6', '2011-03-06', '2011-03-06', 'auto', '1', '5', '125', '0', '10', '0', '0', '0', '1', '1', '5');
INSERT INTO `debtor_trans` VALUES ('6', '10', '1', '4', '6', '2011-03-06', '2011-03-06', '5', '1', '6', '125', '0', '10', '0', '0', '135', '1', '1', '6');
INSERT INTO `debtor_trans` VALUES ('6', '13', '1', '4', '6', '2011-03-06', '2011-03-06', 'auto', '1', '6', '125', '0', '10', '0', '0', '0', '1', '1', '6');
INSERT INTO `debtor_trans` VALUES ('7', '10', '0', '4', '6', '2011-03-08', '2011-03-08', '6', '1', '9', '125', '0', '10', '0', '0', '0', '1', '1', '9');
INSERT INTO `debtor_trans` VALUES ('7', '12', '0', '1', '1', '2011-03-06', '0000-00-00', '6', '0', '0', '100', '0', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `debtor_trans` VALUES ('7', '13', '0', '4', '6', '2011-03-06', '2011-03-06', '1', '1', '7', '125', '0', '10', '0', '0', '0', '1', '1', '0');
INSERT INTO `debtor_trans` VALUES ('8', '10', '0', '4', '6', '2011-03-09', '2011-03-09', '7', '1', '10', '125', '0', '12.5', '0', '0', '0', '1', '1', '10');
INSERT INTO `debtor_trans` VALUES ('8', '12', '0', '4', '6', '2011-03-06', '0000-00-00', '7', '0', '0', '100', '0', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `debtor_trans` VALUES ('8', '13', '1', '4', '6', '2011-03-07', '2011-03-07', '2', '1', '8', '125', '0', '10', '0', '0', '0', '1', '1', '13');
INSERT INTO `debtor_trans` VALUES ('9', '10', '0', '1', '1', '2011-03-09', '2011-03-09', '8', '2', '11', '100', '25', '10', '2.5', '0', '0', '1', '1', '11');
INSERT INTO `debtor_trans` VALUES ('9', '12', '0', '1', '1', '2011-03-07', '0000-00-00', '8', '0', '0', '2000', '0', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `debtor_trans` VALUES ('9', '13', '1', '4', '6', '2011-03-08', '2011-03-08', 'auto', '1', '9', '125', '0', '10', '0', '0', '0', '1', '1', '7');
INSERT INTO `debtor_trans` VALUES ('10', '10', '0', '4', '6', '2011-03-09', '2011-03-09', '9', '1', '12', '125', '0', '10', '0', '0', '0', '1', '1', '12');
INSERT INTO `debtor_trans` VALUES ('10', '13', '1', '4', '6', '2011-03-09', '2011-03-09', 'auto', '1', '10', '125', '0', '12.5', '0', '0', '0', '1', '1', '8');
INSERT INTO `debtor_trans` VALUES ('11', '10', '0', '1', '1', '2011-03-10', '2011-03-20', '10', '2', '15', '100', '25', '0', '0', '0', '0', '1', '1', '14');
INSERT INTO `debtor_trans` VALUES ('11', '13', '1', '1', '1', '2011-03-09', '2011-03-09', 'auto', '2', '11', '100', '25', '10', '2.5', '0', '0', '1', '1', '9');
INSERT INTO `debtor_trans` VALUES ('12', '10', '0', '1', '1', '2011-03-10', '2011-03-29', '11', '2', '16', '100', '25', '0', '0', '0', '0', '1', '1', '15');
INSERT INTO `debtor_trans` VALUES ('12', '13', '1', '4', '6', '2011-03-09', '2011-03-09', 'auto', '1', '12', '125', '0', '10', '0', '0', '0', '1', '1', '10');
INSERT INTO `debtor_trans` VALUES ('13', '10', '0', '4', '6', '2011-03-07', '2011-03-07', '12', '1', '8', '125', '0', '10', '0', '0', '0', '1', '1', '8');
INSERT INTO `debtor_trans` VALUES ('13', '13', '1', '4', '6', '2011-03-10', '2011-03-20', '3', '1', '14', '40', '0', '0', '0', '0', '0', '1', '1', '15');
INSERT INTO `debtor_trans` VALUES ('14', '10', '0', '4', '6', '2011-03-10', '2011-03-10', '13', '1', '18', '125', '0', '10', '0', '0', '0', '1', '1', '17');
INSERT INTO `debtor_trans` VALUES ('14', '13', '1', '1', '1', '2011-03-10', '2011-03-20', '4', '2', '15', '100', '25', '0', '0', '0', '0', '1', '1', '11');
INSERT INTO `debtor_trans` VALUES ('15', '10', '0', '4', '6', '2011-03-10', '2011-04-17', '14', '1', '14', '40', '0', '0', '0', '0', '0', '1', '1', '13');
INSERT INTO `debtor_trans` VALUES ('15', '13', '1', '1', '1', '2011-03-10', '2011-03-20', '5', '2', '16', '100', '25', '0', '0', '0', '0', '1', '1', '12');
INSERT INTO `debtor_trans` VALUES ('16', '10', '0', '4', '6', '2011-03-17', '2011-04-17', '15', '1', '19', '125', '0', '10', '0', '0', '0', '1', '1', '18');
INSERT INTO `debtor_trans` VALUES ('16', '13', '1', '3', '5', '2011-03-10', '2011-03-20', '6', '1', '17', '11', '0', '0', '0', '0', '0', '0.20563796227935', '1', '17');
INSERT INTO `debtor_trans` VALUES ('17', '10', '0', '3', '5', '2011-03-10', '2011-04-17', '16', '1', '17', '11', '0', '0', '0', '0', '0', '0.20563796227935', '1', '16');
INSERT INTO `debtor_trans` VALUES ('17', '13', '1', '4', '6', '2011-03-10', '2011-03-10', 'auto', '1', '18', '125', '0', '10', '0', '0', '0', '1', '1', '14');
INSERT INTO `debtor_trans` VALUES ('18', '10', '0', '3', '5', '2011-03-29', '2011-04-17', '17', '1', '20', '0', '0', '0', '0', '0', '0', '0.20674817019223', '1', '19');
INSERT INTO `debtor_trans` VALUES ('18', '13', '1', '4', '6', '2011-03-17', '2011-03-27', '7', '1', '19', '125', '0', '10', '0', '0', '0', '1', '1', '16');
INSERT INTO `debtor_trans` VALUES ('19', '10', '0', '4', '6', '2011-03-29', '2011-04-17', '18', '1', '21', '125', '0', '0', '0', '0', '0', '1', '1', '20');
INSERT INTO `debtor_trans` VALUES ('19', '13', '1', '3', '5', '2011-03-29', '2011-04-17', 'auto', '1', '20', '0', '0', '0', '0', '0', '0', '0.20674817019223', '1', '18');
INSERT INTO `debtor_trans` VALUES ('20', '13', '1', '4', '6', '2011-03-29', '2011-04-08', '8', '1', '21', '125', '0', '0', '0', '0', '0', '1', '1', '19');

INSERT INTO `debtor_trans_details` VALUES ('1', '1', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('2', '1', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('3', '2', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('4', '2', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('5', '3', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('6', '3', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('7', '4', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('8', '4', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('9', '5', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('10', '5', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('11', '1', '11', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('12', '6', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('13', '6', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('14', '7', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('15', '2', '11', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('16', '3', '11', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('17', '4', '11', '102', '17 inch VGA Monitor', '100', '25', '1', '0', '0', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('18', '8', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('19', '9', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('20', '7', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('21', '10', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('22', '8', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('23', '11', '13', '102', '17 inch VGA Monitor', '100', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('24', '9', '10', '102', '17 inch VGA Monitor', '100', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('25', '12', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('26', '10', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('27', '13', '13', '103', '32MB VGA Card', '40', '8', '1', '0', '20', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('28', '14', '13', '102', '17 inch VGA Monitor', '100', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('29', '11', '10', '102', '17 inch VGA Monitor', '100', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('30', '15', '13', '102', '17 inch VGA Monitor', '100', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('31', '12', '10', '102', '17 inch VGA Monitor', '100', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('32', '13', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('33', '16', '13', '102', '17 inch VGA Monitor', '11', '0', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('34', '17', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('35', '14', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('36', '15', '10', '103', '32MB VGA Card', '40', '8', '1', '0', '20', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('37', '18', '13', '102', '17 inch VGA Monitor', '125', '25', '0', '0', '-3.4114285714283', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('38', '18', '13', 'AA101', 'olie 5w40', '125', '25', '1', '0', '5.0599509174312', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('39', '16', '10', '102', '17 inch VGA Monitor', '125', '25', '0', '0', '-3.4114285714283', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('40', '16', '10', 'AA101', 'olie 5w40', '125', '25', '1', '0', '5.0599509174312', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('41', '17', '10', '102', '17 inch VGA Monitor', '11', '0', '1', '0', '80', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('42', '19', '13', '102', '17 inch VGA Monitor', '0', '0', '1', '0', '-3.4114285714283', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('43', '18', '10', '102', '17 inch VGA Monitor', '0', '0', '1', '0', '-3.4114285714283', '0','0','');
INSERT INTO `debtor_trans_details` VALUES ('44', '20', '13', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '-3.4114285714283', '1','0','');
INSERT INTO `debtor_trans_details` VALUES ('45', '19', '10', '102', '17 inch VGA Monitor', '125', '25', '1', '0', '-3.4114285714283', '0','0','');

INSERT INTO `debtor_trans_tax_details` VALUES ('1', '1', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('2', '1', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('3', '2', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('4', '2', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('5', '3', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('6', '3', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('7', '4', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('8', '4', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('9', '5', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('10', '5', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('11', '1', '11', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('12', '6', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('13', '6', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('14', '7', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('15', '2', '11', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('16', '3', '11', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('17', '4', '11', '3', NULL, '25', '0', '25');
INSERT INTO `debtor_trans_tax_details` VALUES ('18', '8', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('19', '9', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('20', '7', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('21', '10', '13', '3', NULL, '25', '1', '27.5');
INSERT INTO `debtor_trans_tax_details` VALUES ('22', '8', '10', '3', NULL, '25', '1', '27.5');
INSERT INTO `debtor_trans_tax_details` VALUES ('23', '11', '13', '3', NULL, '25', '0', '27.5');
INSERT INTO `debtor_trans_tax_details` VALUES ('24', '9', '10', '3', NULL, '25', '0', '27.5');
INSERT INTO `debtor_trans_tax_details` VALUES ('25', '12', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('26', '10', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('27', '13', '13', '3', NULL, '25', '1', '8');
INSERT INTO `debtor_trans_tax_details` VALUES ('28', '14', '13', '3', NULL, '25', '0', '25');
INSERT INTO `debtor_trans_tax_details` VALUES ('29', '11', '10', '3', NULL, '25', '0', '25');
INSERT INTO `debtor_trans_tax_details` VALUES ('30', '15', '13', '3', NULL, '25', '0', '25');
INSERT INTO `debtor_trans_tax_details` VALUES ('31', '12', '10', '3', NULL, '25', '0', '25');
INSERT INTO `debtor_trans_tax_details` VALUES ('32', '13', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('33', '17', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('34', '14', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('35', '15', '10', '3', NULL, '25', '1', '8');
INSERT INTO `debtor_trans_tax_details` VALUES ('36', '18', '13', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('37', '16', '10', '3', NULL, '25', '1', '27');
INSERT INTO `debtor_trans_tax_details` VALUES ('38', '20', '13', '3', NULL, '25', '1', '25');
INSERT INTO `debtor_trans_tax_details` VALUES ('39', '19', '10', '3', NULL, '25', '1', '25');

INSERT INTO `debtors_master` VALUES ('1', 'Lucky Luke Inc.', '35 Waldorf Street\r\nTown 19358, AR', 'joe@home.com', '12311231', 'USD', '2', '0', '0','1', '1', '0', '0', '1000','');
INSERT INTO `debtors_master` VALUES ('2', 'Money Makers Ltd.', 'N/A', '', '9876543', 'GBP', '2', '0', '0', '1', '1', '0', '0', '1000','');
INSERT INTO `debtors_master` VALUES ('3', 'Junk Beer ApS', 'N/A', '','123321123', 'DKK', '1', '0', '0', '1', '1', '0', '0', '1000','');
INSERT INTO `debtors_master` VALUES ('4', 'Retail clients', 'Never Mind 13', '','', 'USD', '1', '0', '0', '1', '1', '0', '0', '1000','');

INSERT INTO `dimensions` VALUES ('1', '1', 'Development', '1', '0', '2011-01-18', '2011-02-07');
INSERT INTO `dimensions` VALUES ('2', '2', 'Support', '1', '0', '2011-01-18', '2011-03-07');
INSERT INTO `dimensions` VALUES ('3', '3', 'Training', '2', '0', '2011-01-18', '2011-03-07');

INSERT INTO `exchange_rates` VALUES ('1', 'LE', '0.149', '0.149', '2011-01-18');
INSERT INTO `exchange_rates` VALUES ('2', 'GBP', '1.2', '1.2', '2011-01-18');
INSERT INTO `exchange_rates` VALUES ('3', 'SEK', '0.1667', '0.1667', '2011-01-29');
INSERT INTO `exchange_rates` VALUES ('4', 'DKK', '0.2', '0.2', '2011-03-05');
INSERT INTO `exchange_rates` VALUES ('5', 'EUR', '1.1', '1.1', '2011-03-05');
INSERT INTO `exchange_rates` VALUES ('6', 'DKK', '0.20563796227935', '0.20563796227935', '2011-03-06');
INSERT INTO `exchange_rates` VALUES ('7', 'EUR', '1.5561', '1.5561', '2011-03-15');
INSERT INTO `exchange_rates` VALUES ('8', 'DKK', '0.20867920985932', '0.20867920985932', '2011-03-16');
INSERT INTO `exchange_rates` VALUES ('9', 'GBP', '1.9816266221251', '1.9816266221251', '2011-03-24');
INSERT INTO `exchange_rates` VALUES ('10', 'DKK', '0.20674817019223', '0.20674817019223', '2011-03-24');
INSERT INTO `exchange_rates` VALUES ('11', 'EUR', '1.5569', '1.5569', '2011-03-25');
INSERT INTO `exchange_rates` VALUES ('12', 'EUR', '1.5796', '1.5796', '2011-03-28');

INSERT INTO `fiscal_year` VALUES ('1', '2011-01-01', '2011-12-31', '1');
INSERT INTO `fiscal_year` VALUES ('2', '2010-01-01', '2010-12-31', '0');
INSERT INTO `fiscal_year` VALUES ('5', '2009-01-01', '2009-12-31', '0');
INSERT INTO `fiscal_year` VALUES ('6', '2008-01-01', '2008-12-31', '0');

INSERT INTO `gl_trans` VALUES ('1', '13', '1', '2011-03-06', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('2', '13', '1', '2011-03-06', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('3', '10', '1', '2011-03-06', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('4', '10', '1', '2011-03-06', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('5', '10', '1', '2011-03-06', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('6', '10', '1', '2011-03-06', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('7', '13', '2', '2011-03-06', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('8', '13', '2', '2011-03-06', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('9', '10', '2', '2011-03-06', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('10', '10', '2', '2011-03-06', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('11', '10', '2', '2011-03-06', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('12', '10', '2', '2011-03-06', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('13', '13', '3', '2011-03-06', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('14', '13', '3', '2011-03-06', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('15', '10', '3', '2011-03-06', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('16', '10', '3', '2011-03-06', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('17', '10', '3', '2011-03-06', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('18', '10', '3', '2011-03-06', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('19', '13', '4', '2011-03-06', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('20', '13', '4', '2011-03-06', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('21', '10', '4', '2011-03-06', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('22', '10', '4', '2011-03-06', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('23', '10', '4', '2011-03-06', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('24', '10', '4', '2011-03-06', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('25', '13', '5', '2011-03-06', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('26', '13', '5', '2011-03-06', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('27', '10', '5', '2011-03-06', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('28', '10', '5', '2011-03-06', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('29', '10', '5', '2011-03-06', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('30', '10', '5', '2011-03-06', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('31', '11', '1', '2011-03-06', '4010', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('32', '11', '1', '2011-03-06', '1420', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('33', '11', '1', '2011-03-06', '3000', '', '125', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('34', '11', '1', '0000-00-00', '1500', '', '-10', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('35', '11', '1', '0000-00-00', '3800', '', '8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('36', '11', '1', '0000-00-00', '2664', '', '27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('37', '13', '6', '2011-03-06', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('38', '13', '6', '2011-03-06', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('39', '10', '6', '2011-03-06', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('40', '10', '6', '2011-03-06', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('41', '10', '6', '2011-03-06', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('42', '10', '6', '2011-03-06', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('43', '13', '7', '2011-03-06', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('44', '13', '7', '2011-03-06', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('45', '12', '7', '2011-03-06', '1700', '', '100', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('46', '12', '7', '2011-03-06', '1500', '', '-100', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('47', '12', '8', '2011-03-06', '1700', '', '100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('48', '12', '8', '2011-03-06', '1500', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('49', '20', '7', '2011-03-06', '2630', '', '-550', '0', '0', '3', '1');
INSERT INTO `gl_trans` VALUES ('50', '20', '7', '2011-03-06', '1420', '', '250', '0', '0', '3', '1');
INSERT INTO `gl_trans` VALUES ('51', '20', '7', '2011-03-06', '1420', '', '300', '0', '0', '3', '1');
INSERT INTO `gl_trans` VALUES ('52', '11', '2', '2011-03-06', '4010', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('53', '11', '2', '2011-03-06', '1420', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('54', '11', '2', '2011-03-06', '3000', '', '125', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('55', '11', '2', '2011-03-06', '1500', '', '-135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('56', '11', '2', '2011-03-06', '3800', '', '8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('57', '11', '2', '0000-00-00', '2664', '', '27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('58', '11', '3', '2011-03-06', '4010', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('59', '11', '3', '2011-03-06', '1420', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('60', '11', '3', '2011-03-06', '3000', '', '100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('61', '11', '3', '2011-03-06', '1500', '', '-135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('62', '11', '3', '2011-03-06', '3800', '', '8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('63', '11', '3', '0000-00-00', '2664', '', '27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('64', '12', '9', '2011-03-07', '1700', '', '2000', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('65', '12', '9', '2011-03-07', '1500', '', '-2000', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('66', '11', '4', '2011-03-07', '3000', '', '100', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('67', '11', '4', '2011-03-07', '1500', '', '-125', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('68', '11', '4', '0000-00-00', '2664', '', '25', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('69', '26', '7', '2011-03-07', '1420', '', '-80', '0', '0', NULL, NULL);
INSERT INTO `gl_trans` VALUES ('70', '26', '7', '2011-03-07', '1420', '', '-20', '0', '0', NULL, NULL);
INSERT INTO `gl_trans` VALUES ('71', '26', '7', '2011-03-07', '1420', '', '-18', '0', '0', NULL, NULL);
INSERT INTO `gl_trans` VALUES ('72', '26', '7', '2011-03-07', '1420', '', '118', '0', '0', NULL, NULL);
INSERT INTO `gl_trans` VALUES ('73', '0', '18', '2011-03-07', '1400', '', '20', '0', '0', NULL, NULL);
INSERT INTO `gl_trans` VALUES ('74', '0', '18', '2011-03-07', '3010', '', '-20', '0', '0', NULL, NULL);
INSERT INTO `gl_trans` VALUES ('75', '13', '8', '2011-03-07', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('76', '13', '8', '2011-03-07', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('77', '13', '9', '2011-03-08', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('78', '13', '9', '2011-03-08', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('79', '10', '7', '2011-03-08', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('80', '10', '7', '2011-03-08', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('81', '10', '7', '2011-03-08', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('82', '10', '7', '2011-03-08', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('83', '13', '10', '2011-03-09', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('84', '13', '10', '2011-03-09', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('85', '10', '8', '2011-03-09', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('86', '10', '8', '2011-03-09', '1500', '', '137.5', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('87', '10', '8', '2011-03-09', '3800', '', '-10', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('88', '10', '8', '2011-03-09', '2664', '', '-27.5', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('89', '13', '11', '2011-03-09', '4010', '', '80', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('90', '13', '11', '2011-03-09', '1420', '', '-80', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('91', '10', '9', '2011-03-09', '3000', '', '-100', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('92', '10', '9', '2011-03-09', '1500', '', '137.5', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('93', '10', '9', '2011-03-09', '3800', '', '-10', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('94', '10', '9', '2011-03-09', '2664', '', '-27.5', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('95', '13', '12', '2011-03-09', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('96', '13', '12', '2011-03-09', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('97', '10', '10', '2011-03-09', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('98', '10', '10', '2011-03-09', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('99', '10', '10', '2011-03-09', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('100', '10', '10', '2011-03-09', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('103', '13', '13', '2011-03-10', '4010', '', '20', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('104', '13', '13', '2011-03-10', '1420', '', '-20', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('105', '13', '14', '2011-03-10', '4010', '', '80', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('106', '13', '14', '2011-03-10', '1420', '', '-80', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('107', '10', '11', '2011-03-10', '3000', '', '-100', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('108', '10', '11', '2011-03-10', '1500', '', '125', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('109', '10', '11', '2011-03-10', '2664', '', '-25', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('110', '13', '15', '2011-03-10', '4010', '', '80', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('111', '13', '15', '2011-03-10', '1420', '', '-80', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('112', '10', '12', '2011-03-10', '3000', '', '-100', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('113', '10', '12', '2011-03-10', '1500', '', '125', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('114', '10', '12', '2011-03-10', '2664', '', '-25', '0', '0', '2', '1');
INSERT INTO `gl_trans` VALUES ('115', '10', '13', '2011-03-07', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('116', '10', '13', '2011-03-07', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('117', '10', '13', '2011-03-07', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('118', '10', '13', '2011-03-07', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('119', '13', '16', '2011-03-10', '4010', '', '80', '0', '0', '2', '3');
INSERT INTO `gl_trans` VALUES ('120', '13', '16', '2011-03-10', '1420', '', '-80', '0', '0', '2', '3');
INSERT INTO `gl_trans` VALUES ('121', '13', '17', '2011-03-10', '4010', '', '80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('122', '13', '17', '2011-03-10', '1420', '', '-80', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('123', '10', '14', '2011-03-10', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('124', '10', '14', '2011-03-10', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('125', '10', '14', '2011-03-10', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('126', '10', '14', '2011-03-10', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('127', '10', '15', '2011-03-10', '3000', '', '-32', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('128', '10', '15', '2011-03-10', '1500', '', '40', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('129', '10', '15', '2011-03-10', '2664', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('133', '20', '8', '2011-03-20', '2630', '', '0', '0', '0', '3', '2');
INSERT INTO `gl_trans` VALUES ('134', '20', '8', '2011-03-20', '1420', '', '0', '0', '0', '3', '2');
INSERT INTO `gl_trans` VALUES ('135', '20', '9', '2011-03-25', '2630', '', '-19.82', '0', '0', '3', '2');
INSERT INTO `gl_trans` VALUES ('136', '20', '9', '2011-03-25', '1420', '', '19.82', '0', '0', '3', '2');
INSERT INTO `gl_trans` VALUES ('149', '20', '10', '2011-03-25', '2630', '', '-40.48', '0', '0', '3', '4');
INSERT INTO `gl_trans` VALUES ('150', '20', '10', '2011-03-25', '1420', '', '40.48', '0', '0', '3', '4');
INSERT INTO `gl_trans` VALUES ('151', '20', '10', '2011-03-25', '2682', '', '8.1', '0', '0', '3', '4');
INSERT INTO `gl_trans` VALUES ('152', '20', '11', '2011-03-28', '2630', '', '-2618.19', '0', '0', '3', '4');
INSERT INTO `gl_trans` VALUES ('153', '20', '11', '2011-03-28', '1420', '', '2094.55', '0', '0', '3', '4');
INSERT INTO `gl_trans` VALUES ('154', '20', '11', '2011-03-28', '2682', '', '523.64', '0', '0', '3', '4');
INSERT INTO `gl_trans` VALUES ('155', '13', '18', '2011-03-17', '4010', '', '5.0599509174312', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('156', '13', '18', '2011-03-17', '1420', '', '-5.0599509174312', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('157', '10', '16', '2011-03-17', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('158', '10', '16', '2011-03-17', '1500', '', '135', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('159', '10', '16', '2011-03-17', '3800', '', '-8', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('160', '10', '16', '2011-03-17', '2664', '', '-27', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('161', '10', '17', '2011-03-10', '3000', '', '-2.26', '0', '0', '2', '3');
INSERT INTO `gl_trans` VALUES ('162', '10', '17', '2011-03-10', '1500', '', '2.26', '0', '0', '2', '3');
INSERT INTO `gl_trans` VALUES ('163', '13', '19', '2011-03-29', '4010', '', '-3.4114285714283', '0', '0', '2', '3');
INSERT INTO `gl_trans` VALUES ('164', '13', '19', '2011-03-29', '1420', '', '3.4114285714283', '0', '0', '2', '3');
INSERT INTO `gl_trans` VALUES ('165', '13', '20', '2011-03-29', '4010', '', '-3.4114285714283', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('166', '13', '20', '2011-03-29', '1420', '', '3.4114285714283', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('167', '10', '19', '2011-03-29', '3000', '', '-100', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('168', '10', '19', '2011-03-29', '1500', '', '125', '0', '0', '2', '4');
INSERT INTO `gl_trans` VALUES ('169', '10', '19', '2011-03-29', '2664', '', '-25', '0', '0', '2', '4');

INSERT INTO `grn_batch` VALUES ('1', '1', '1', '1', '2011-01-18', 'DEF');
INSERT INTO `grn_batch` VALUES ('2', '1', '2', '2', '2011-01-18', 'DEF');
INSERT INTO `grn_batch` VALUES ('3', '1', '5', '3', '2011-01-18', 'DEF');
INSERT INTO `grn_batch` VALUES ('4', '1', '6', '4', '2011-03-06', 'DEF');
INSERT INTO `grn_batch` VALUES ('5', '4', '8', '5', '2011-03-17', 'DEF');
INSERT INTO `grn_batch` VALUES ('6', '4', '8', '6', '2011-03-19', 'DEF');
INSERT INTO `grn_batch` VALUES ('7', '2', '9', '7', '2011-03-20', 'DEF');
INSERT INTO `grn_batch` VALUES ('8', '2', '10', '8', '2011-03-25', 'DEF');
INSERT INTO `grn_batch` VALUES ('9', '4', '11', '9', '2011-03-25', 'DEF');
INSERT INTO `grn_batch` VALUES ('10', '4', '13', '10', '2011-03-25', 'DEF');
INSERT INTO `grn_batch` VALUES ('11', '4', '12', '11', '2011-03-25', 'DEF');
INSERT INTO `grn_batch` VALUES ('12', '4', '13', '12', '2011-03-28', 'DEF');

INSERT INTO `grn_items` VALUES ('1', '1', '1', '102', '17 inch VGA Monitor', '10', '10');
INSERT INTO `grn_items` VALUES ('2', '1', '2', '103', '32MB VGA Card', '50', '50');
INSERT INTO `grn_items` VALUES ('3', '2', '3', '104', '52x CD Drive', '1', '1');
INSERT INTO `grn_items` VALUES ('4', '3', '6', '104', '52x CD Drive (upgraded)', '3020', '302');
INSERT INTO `grn_items` VALUES ('5', '4', '7', '102', '17 inch VGA Monitor', '10', '10');
INSERT INTO `grn_items` VALUES ('6', '4', '8', '103', '32MB VGA Card', '10', '10');
INSERT INTO `grn_items` VALUES ('7', '4', '9', '104', '52x CD Drive', '10', '0');
INSERT INTO `grn_items` VALUES ('8', '4', '10', '202', 'Electric stimulator', '10', '0');
INSERT INTO `grn_items` VALUES ('9', '5', '12', 'AA101', 'olie 5w40', '8', '8');
INSERT INTO `grn_items` VALUES ('10', '6', '12', 'AA101', 'olie 5w40', '408', '408');
INSERT INTO `grn_items` VALUES ('11', '7', '13', '102', '17 inch VGA Monitor', '5', '5');
INSERT INTO `grn_items` VALUES ('12', '8', '14', '102', '17 inch VGA Monitor', '1', '1');
INSERT INTO `grn_items` VALUES ('13', '9', '15', 'AA101', 'olie 5w40', '20', '0');
INSERT INTO `grn_items` VALUES ('14', '10', '17', '102', '17 inch VGA Monitor', '5', '0');
INSERT INTO `grn_items` VALUES ('15', '11', '16', '102', '17 inch VGA Monitor', '1', '0');
INSERT INTO `grn_items` VALUES ('16', '12', '17', '102', '17 inch VGA Monitor', '5', '0');

INSERT INTO `item_tax_type_exemptions` VALUES ('1', '1');
INSERT INTO `item_tax_type_exemptions` VALUES ('1', '2');
INSERT INTO `item_tax_type_exemptions` VALUES ('2', '2');
INSERT INTO `item_tax_type_exemptions` VALUES ('2', '3');

INSERT INTO `item_tax_types` VALUES ('1', 'Regular', '0');
INSERT INTO `item_tax_types` VALUES ('2', 'Recovery equipment', '0');

INSERT INTO `item_units` VALUES ('each', 'each', '0');
INSERT INTO `item_units` VALUES ('m', 'meters', '2');
INSERT INTO `item_units` VALUES ('kgg', 'kilograms', '3');
INSERT INTO `item_units` VALUES ('tons', 'tons', '2');
INSERT INTO `item_units` VALUES ('lbs', 'pounds', '2');
INSERT INTO `item_units` VALUES ('l', 'liters', '3');
INSERT INTO `item_units` VALUES ('dozen', 'dozens', '0');
INSERT INTO `item_units` VALUES ('pack', 'packs', '0');
INSERT INTO `item_units` VALUES ('hrs', 'hours', '1');
INSERT INTO `item_units` VALUES ('dz', 'dozijn', '0');

INSERT INTO `loc_stock` VALUES ('CWA', '102', '0');
INSERT INTO `loc_stock` VALUES ('CWA', '103', '0');
INSERT INTO `loc_stock` VALUES ('CWA', '104', '0');
INSERT INTO `loc_stock` VALUES ('CWA', '201', '0');
INSERT INTO `loc_stock` VALUES ('CWA', '202', '0');
INSERT INTO `loc_stock` VALUES ('CWA', '3400', '0');
INSERT INTO `loc_stock` VALUES ('CWA', 'AA101', '0');
INSERT INTO `loc_stock` VALUES ('DEF', '102', '0');
INSERT INTO `loc_stock` VALUES ('DEF', '103', '0');
INSERT INTO `loc_stock` VALUES ('DEF', '104', '0');
INSERT INTO `loc_stock` VALUES ('DEF', '201', '0');
INSERT INTO `loc_stock` VALUES ('DEF', '202', '0');
INSERT INTO `loc_stock` VALUES ('DEF', '3400', '0');
INSERT INTO `loc_stock` VALUES ('DEF', 'AA101', '0');

INSERT INTO `locations` VALUES ('DEF', 'Default', 'N/A', '', '', '', '');
INSERT INTO `locations` VALUES ('CWA', 'Cool Warehouse', '', '', '', '', '');

INSERT INTO `movement_types` VALUES ('1', 'Adjustment');

INSERT INTO `payment_terms` VALUES ('1', 'Due 15th Of the Following Month', '0', '17');
INSERT INTO `payment_terms` VALUES ('2', 'Due By End Of The Following Month', '0', '30');
INSERT INTO `payment_terms` VALUES ('3', 'Payment due within 10 days', '10', '0');
INSERT INTO `payment_terms` VALUES ('4', 'Cash Only', '1', '0');

INSERT INTO `prices` VALUES ('1', '102', '1', 'USD', '125','0');
INSERT INTO `prices` VALUES ('2', '103', '1', 'USD', '40','0');
INSERT INTO `prices` VALUES ('3', '104', '1', 'USD', '34','0');
INSERT INTO `prices` VALUES ('4', '201', '1', 'USD', '40','0');
INSERT INTO `prices` VALUES ('5', '3400', '1', 'USD', '600','0');
INSERT INTO `prices` VALUES ('6', '102', '2', 'USD', '100','0');
INSERT INTO `prices` VALUES ('7', '202', '2', 'USD', '50','0');
INSERT INTO `prices` VALUES ('8', '202', '1', 'USD', '52.5','0');
INSERT INTO `prices` VALUES ('9', '103', '2', 'USD', '30','0');
INSERT INTO `prices` VALUES ('10', '104', '2', 'USD', '25','0');
INSERT INTO `prices` VALUES ('11', '201', '2', 'USD', '30','0');
INSERT INTO `prices` VALUES ('12', '3400', '2', 'USD', '450','0');

INSERT INTO `purch_order_details` VALUES ('1', '1', '102', '17 inch VGA Monitor', '2011-01-28', '10', '3020', '3020', '0', '3000', '10');
INSERT INTO `purch_order_details` VALUES ('2', '1', '103', '32MB VGA Card', '2011-01-28', '50', '90', '90', '0', '300', '50');
INSERT INTO `purch_order_details` VALUES ('3', '2', '104', '52x CD Drive', '2011-01-28', '1', '26', '26', '0', '1', '1');
INSERT INTO `purch_order_details` VALUES ('4', '3', '104', '52x CD Drive', '2011-01-28', '0', '22', '0', '0', '1', '0');
INSERT INTO `purch_order_details` VALUES ('6', '5', '104', '52x CD Drive', '2011-01-28', '302', '22', '22', '0', '330', '3020');
INSERT INTO `purch_order_details` VALUES ('7', '6', '102', '17 inch VGA Monitor', '2011-03-16', '10', '25', '25', '80', '10', '10');
INSERT INTO `purch_order_details` VALUES ('8', '6', '103', '32MB VGA Card', '2011-03-16', '10', '30', '30', '20', '10', '10');
INSERT INTO `purch_order_details` VALUES ('9', '6', '104', '52x CD Drive', '2011-03-16', '0', '20', '0', '18', '10', '10');
INSERT INTO `purch_order_details` VALUES ('10', '6', '202', 'Electric stimulator', '2011-03-16', '0', '50', '0', '30', '10', '10');
INSERT INTO `purch_order_details` VALUES ('12', '8', 'AA101', 'olie 5w40', '2011-03-25', '416', '3.25', '3.25', '0', '416', '416');
INSERT INTO `purch_order_details` VALUES ('13', '9', '102', '17 inch VGA Monitor', '2011-03-30', '5', '0', '0', '80', '5', '5');
INSERT INTO `purch_order_details` VALUES ('14', '10', '102', '17 inch VGA Monitor', '2011-04-04', '1', '10', '10', '-120', '1', '1');
INSERT INTO `purch_order_details` VALUES ('15', '11', 'AA101', 'olie 5w40', '2011-04-04', '0', '3.25', '0', '5.0599485576923', '20', '20');
INSERT INTO `purch_order_details` VALUES ('16', '12', '102', '17 inch VGA Monitor', '2011-04-04', '0', '10', '0', '-17.79125', '1', '1');
INSERT INTO `purch_order_details` VALUES ('17', '13', '102', '17 inch VGA Monitor', '2011-04-04', '0', '10', '0', '-73.393333333333', '10', '10');

INSERT INTO `purch_orders` VALUES ('1', '0', '1', NULL, '2011-01-18', '3', '333', 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('2', '0', '1', NULL, '2011-01-18', '4', '44', 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('3', '0', '1', NULL, '2011-01-18', '5', NULL, 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('5', '0', '1', NULL, '2011-01-18', '7', NULL, 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('6', '0', '1', NULL, '2011-03-06', '8', NULL, 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('8', '0', '4', NULL, '2011-03-15', '9', NULL, 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('9', '0', '2', NULL, '2011-03-20', '10', NULL, 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('10', '0', '2', NULL, '2011-03-25', '11', NULL, 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('11', '0', '4', NULL, '2011-03-25', '12', NULL, 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('12', '0', '4', NULL, '2011-03-25', '13', NULL, 'DEF', 'N/A');
INSERT INTO `purch_orders` VALUES ('13', '0', '4', NULL, '2011-03-25', '14', NULL, 'DEF', 'N/A');

INSERT INTO `refs` VALUES ('2', '0', 'Joe');
INSERT INTO `refs` VALUES ('3', '0', '19');
INSERT INTO `refs` VALUES ('4', '0', '19');
INSERT INTO `refs` VALUES ('5', '0', '20');
INSERT INTO `refs` VALUES ('6', '0', '21');
INSERT INTO `refs` VALUES ('7', '0', '22');
INSERT INTO `refs` VALUES ('8', '0', '23');
INSERT INTO `refs` VALUES ('9', '0', '24');
INSERT INTO `refs` VALUES ('10', '0', '25');
INSERT INTO `refs` VALUES ('11', '0', '26');
INSERT INTO `refs` VALUES ('12', '0', '27');
INSERT INTO `refs` VALUES ('13', '0', '28');
INSERT INTO `refs` VALUES ('14', '0', '29');
INSERT INTO `refs` VALUES ('15', '0', '30');
INSERT INTO `refs` VALUES ('16', '0', '31');
INSERT INTO `refs` VALUES ('17', '0', '32');
INSERT INTO `refs` VALUES ('18', '0', '33');

INSERT INTO `sales_order_details` VALUES ('1', '1', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('2', '2', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('3', '3', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('4', '4', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('5', '5', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('6', '6', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('7', '7', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('8', '8', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('9', '9', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('10', '10', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('11', '11', '102', '17 inch VGA Monitor', '1', '100', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('12', '12', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('13', '13', '102', '17 inch VGA Monitor', '0', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('14', '14', '103', '32MB VGA Card', '1', '40', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('15', '15', '102', '17 inch VGA Monitor', '1', '100', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('16', '16', '102', '17 inch VGA Monitor', '1', '100', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('17', '17', '102', '17 inch VGA Monitor', '1', '11', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('18', '18', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('20', '19', '102', '17 inch VGA Monitor', '0', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('21', '19', 'AA101', 'olie 5w40', '1', '125', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('22', '20', '102', '17 inch VGA Monitor', '1', '0', '1', '0','2011-05-03','');
INSERT INTO `sales_order_details` VALUES ('23', '21', '102', '17 inch VGA Monitor', '1', '125', '1', '0','2011-05-03','');

INSERT INTO `sales_orders` VALUES ('1', '1', '1', '4', '6', '', NULL, '2011-03-06', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-16');
INSERT INTO `sales_orders` VALUES ('2', '1', '0', '4', '6', '', NULL, '2011-03-06', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-06');
INSERT INTO `sales_orders` VALUES ('3', '1', '0', '4', '6', '', NULL, '2011-03-06', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-06');
INSERT INTO `sales_orders` VALUES ('4', '1', '0', '4', '6', '', NULL, '2011-03-06', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-06');
INSERT INTO `sales_orders` VALUES ('5', '1', '1', '4', '6', '', NULL, '2011-03-06', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-06');
INSERT INTO `sales_orders` VALUES ('6', '1', '0', '4', '6', '', NULL, '2011-03-06', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-06');
INSERT INTO `sales_orders` VALUES ('7', '1', '0', '4', '6', '', NULL, '2011-03-06', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-06');
INSERT INTO `sales_orders` VALUES ('8', '1', '0', '4', '6', '', NULL, '2011-03-07', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-07');
INSERT INTO `sales_orders` VALUES ('9', '1', '0', '4', '6', '', NULL, '2011-03-08', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-08');
INSERT INTO `sales_orders` VALUES ('10', '1', '0', '4', '6', '', NULL, '2011-03-09', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '12.5', 'DEF', '2011-03-09');
INSERT INTO `sales_orders` VALUES ('11', '1', '0', '1', '1', '', NULL, '2011-03-09', '2', '1', 'The Road', NULL, NULL, 'Main', '10', 'DEF', '2011-03-09');
INSERT INTO `sales_orders` VALUES ('12', '1', '0', '4', '6', '', NULL, '2011-03-09', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-09');
INSERT INTO `sales_orders` VALUES ('13', '0', '0', '4', '6', '', NULL, '2011-03-10', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '0', 'DEF', '2011-03-20');
INSERT INTO `sales_orders` VALUES ('14', '1', '0', '4', '6', '', NULL, '2011-03-10', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '0', 'DEF', '2011-03-20');
INSERT INTO `sales_orders` VALUES ('15', '1', '0', '1', '1', '', NULL, '2011-03-10', '2', '1', 'The Road', NULL, NULL, 'Main', '0', 'DEF', '2011-03-20');
INSERT INTO `sales_orders` VALUES ('16', '1', '0', '1', '1', '', NULL, '2011-03-10', '2', '1', 'The Road', NULL, NULL, 'Main', '0', 'DEF', '2011-03-20');
INSERT INTO `sales_orders` VALUES ('17', '1', '0', '3', '5', '', NULL, '2011-03-10', '1', '1', 'N/A', NULL, NULL, 'Main', '0', 'CWA', '2011-03-20');
INSERT INTO `sales_orders` VALUES ('18', '1', '0', '4', '6', '', NULL, '2011-03-10', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-10');
INSERT INTO `sales_orders` VALUES ('19', '2', '0', '4', '6', '', NULL, '2011-03-17', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '10', 'DEF', '2011-03-27');
INSERT INTO `sales_orders` VALUES ('20', '1', '0', '3', '5', '', NULL, '2011-03-29', '1', '1', 'N/A', NULL, NULL, 'Main', '0', 'CWA', '2011-04-17');
INSERT INTO `sales_orders` VALUES ('21', '1', '0', '4', '6', '', NULL, '2011-03-29', '1', '1', 'Never Mind 13', '123', NULL, 'Johny Bravo', '0', 'DEF', '2011-04-08');

INSERT INTO `sales_types` VALUES ('1', 'Retail', '1','1');
INSERT INTO `sales_types` VALUES ('2', 'Wholesale', '0','1');

INSERT INTO `salesman` VALUES ('1', 'Sparc Menser', '', '', '', '5', '1000', '4');
INSERT INTO `salesman` VALUES ('2', 'Joe Hunt', '', '', '', '4', '500', '3');

INSERT INTO `shippers` VALUES ('1', 'UPS', '', '', '',40);
INSERT INTO `shippers` VALUES ('2', 'Internet', '', '', '',0);

INSERT INTO `stock_category` VALUES ('1', 'Components', NULL, NULL, NULL, NULL);
INSERT INTO `stock_category` VALUES ('2', 'Charges', NULL, NULL, NULL, NULL);
INSERT INTO `stock_category` VALUES ('3', 'Systems', NULL, NULL, NULL, NULL);
INSERT INTO `stock_category` VALUES ('4', 'Services', NULL, NULL, NULL, NULL);

INSERT INTO `stock_master` VALUES ('102', '1', '1', '17 inch VGA Monitor', '', 'each', 'B', '3000', '4010', '1420', '4210', '0', NULL, NULL, '0', '0', '-3.4114285714283', '0', '0',1,'','',0,'');
INSERT INTO `stock_master` VALUES ('103', '1', '1', '32MB VGA Card', '', 'each', 'B', '3000', '4010', '1420', '4210', '0', NULL, NULL, '0', '0', '20', '0', '0',1,'','',0,'');
INSERT INTO `stock_master` VALUES ('104', '1', '1', '52x CD Drive', '', 'each', 'B', '3000', '4010', '1420', '4210', '0', NULL, NULL, '0', '0', '18', '0', '0',1,'','',0,'');
INSERT INTO `stock_master` VALUES ('201', '2', '1', 'Assembly Labour', '', 'each', 'D', '3000', '4010', '1420', '4210', '0', NULL, NULL, '0', '0', '0', '0', '0',1,'','',0,'');
INSERT INTO `stock_master` VALUES ('202', '1', '2', 'Electric stimulator', '', 'ea.', 'B', '3000', '4010', '1420', '4210', '1410', '0', '0', '0', '0', '30', '0', '0',1,'','',0,'');
INSERT INTO `stock_master` VALUES ('3400', '3', '1', 'P4 Business System', '', 'each', 'M', '3000', '4010', '1420', '4210', '1400', NULL, NULL, '0', '160', '100', '30', '10',1,'','',0,'');
INSERT INTO `stock_master` VALUES ('AA101', '1', '1', 'olie 5w40', 'Shell Helix 5w40', 'l', 'B', '3000', '4010', '1420', '4210', '1410', '0', '0', '0', '0', '5.0599509174312', '0', '0',1,'','',0,'');

INSERT INTO `stock_moves` VALUES ('1', '4', '102', '25', 'DEF', '2011-03-06', '1', '25', '', '10', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('2', '4', '103', '25', 'DEF', '2011-03-06', '1', '30', '', '10', '0', '20', '1');
INSERT INTO `stock_moves` VALUES ('3', '4', '104', '25', 'DEF', '2011-03-06', '1', '20', '', '10', '0', '18', '1');
INSERT INTO `stock_moves` VALUES ('4', '4', '202', '25', 'DEF', '2011-03-06', '1', '50', '', '10', '0', '30', '1');
INSERT INTO `stock_moves` VALUES ('5', '1', '102', '13', 'DEF', '2011-03-06', '0', '125', '0', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('6', '2', '102', '13', 'DEF', '2011-03-06', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('7', '3', '102', '13', 'DEF', '2011-03-06', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('8', '4', '102', '13', 'DEF', '2011-03-06', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('9', '5', '102', '13', 'DEF', '2011-03-06', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('10', '1', '102', '11', 'DEF', '2011-03-06', '0', '125', 'Return Ex Inv: 5', '1', '0', '80', '0');
INSERT INTO `stock_moves` VALUES ('11', '6', '102', '13', 'DEF', '2011-03-06', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('12', '7', '102', '13', 'DEF', '2011-03-06', '0', '125', '1', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('13', '2', '102', '11', 'DEF', '2011-03-06', '0', '125', 'Return Ex Inv: 6', '1', '0', '80', '0');
INSERT INTO `stock_moves` VALUES ('14', '3', '102', '11', 'DEF', '2011-03-06', '0', '125', 'Return Ex Inv: 4', '1', '0', '80', '0');
INSERT INTO `stock_moves` VALUES ('15', '4', '102', '11', 'CWA', '2011-03-07', '0', '125', 'Return', '1', '0', '0', '0');
INSERT INTO `stock_moves` VALUES ('16', '7', '102', '26', 'DEF', '2011-03-07', '0', '0', '7', '-1', '0', '0', '1');
INSERT INTO `stock_moves` VALUES ('17', '7', '103', '26', 'DEF', '2011-03-07', '0', '0', '7', '-1', '0', '0', '1');
INSERT INTO `stock_moves` VALUES ('18', '7', '104', '26', 'DEF', '2011-03-07', '0', '0', '7', '-1', '0', '0', '1');
INSERT INTO `stock_moves` VALUES ('19', '7', '3400', '26', 'DEF', '2011-03-07', '0', '0', '7', '1', '0', '0', '1');
INSERT INTO `stock_moves` VALUES ('20', '8', '102', '13', 'DEF', '2011-03-07', '0', '125', '2', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('21', '9', '102', '13', 'DEF', '2011-03-08', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('22', '10', '102', '13', 'DEF', '2011-03-09', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('23', '11', '102', '13', 'DEF', '2011-03-09', '0', '100', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('24', '12', '102', '13', 'DEF', '2011-03-09', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('26', '13', '103', '13', 'DEF', '2011-03-10', '0', '40', '3', '-1', '0', '20', '1');
INSERT INTO `stock_moves` VALUES ('27', '14', '102', '13', 'DEF', '2011-03-10', '0', '100', '4', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('28', '15', '102', '13', 'DEF', '2011-03-10', '0', '100', '5', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('29', '16', '102', '13', 'CWA', '2011-03-10', '0', '11', '6', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('30', '17', '102', '13', 'DEF', '2011-03-10', '0', '125', 'auto', '-1', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('31', '5', 'AA101', '25', 'DEF', '2011-03-17', '4', '3.25', '', '8', '0', '0', '1');
INSERT INTO `stock_moves` VALUES ('32', '6', 'AA101', '25', 'DEF', '2011-03-19', '4', '3.25', '', '408', '0', '0', '1');
INSERT INTO `stock_moves` VALUES ('33', '7', '102', '25', 'DEF', '2011-03-20', '2', '0', '', '5', '0', '80', '1');
INSERT INTO `stock_moves` VALUES ('34', '8', '102', '25', 'DEF', '2011-03-25', '2', '10', '', '1', '0', '-120', '1');
INSERT INTO `stock_moves` VALUES ('35', '9', 'AA101', '25', 'DEF', '2011-03-25', '4', '3.25', '', '20', '0', '5.0599485576923', '1');
INSERT INTO `stock_moves` VALUES ('36', '10', '102', '25', 'DEF', '2011-03-25', '4', '10', '', '5', '0', '-73.393333333333', '1');
INSERT INTO `stock_moves` VALUES ('37', '11', '102', '25', 'DEF', '2011-03-25', '4', '10', '', '1', '0', '-17.79125', '1');
INSERT INTO `stock_moves` VALUES ('38', '12', '102', '25', 'DEF', '2011-03-28', '4', '10', '', '5', '0', '-73.393333333333', '1');
INSERT INTO `stock_moves` VALUES ('39', '18', 'AA101', '13', 'DEF', '2011-03-17', '0', '125', '7', '-1', '0', '5.0599509174312', '1');
INSERT INTO `stock_moves` VALUES ('40', '19', '102', '13', 'CWA', '2011-03-29', '0', '0', 'auto', '-1', '0', '-3.4114285714283', '1');
INSERT INTO `stock_moves` VALUES ('41', '20', '102', '13', 'DEF', '2011-03-29', '0', '125', '8', '-1', '0', '-3.4114285714283', '1');

INSERT INTO `supp_allocations` VALUES ('7', '1529', '2008-01-30', '2', '22', '4', '20');
INSERT INTO `supp_allocations` VALUES ('8', '3445', '2008-01-30', '2', '22', '2', '20');
INSERT INTO `supp_allocations` VALUES ('9', '26', '2008-01-30', '2', '22', '3', '20');

INSERT INTO `supp_invoice_items` VALUES ('1', '2', '20', '0', '1', '1', '102', '17 inch VGA Monitor', '5', '3020', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('2', '2', '20', '0', '2', '2', '103', '32MB VGA Card', '25', '90', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('3', '3', '20', '0', '3', '3', '104', '52x CD Drive', '1', '26', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('4', '4', '20', '0', '1', '1', '102', '17 inch VGA Monitor', '5', '3020', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('5', '4', '20', '0', '2', '2', '103', '32MB VGA Card', '25', '90', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('6', '5', '20', '0', '4', '6', '104', '52x CD Drive (upgraded)', '302', '22', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('7', '6', '20', '6730', '0', '0', '', NULL, '0', '200', '0', 'yes');
INSERT INTO `supp_invoice_items` VALUES ('8', '7', '20', '0', '5', '7', '102', '17 inch VGA Monitor', '10', '25', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('9', '7', '20', '0', '6', '8', '103', '32MB VGA Card', '10', '30', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('12', '8', '20', '0', '11', '13', '102', '17 inch VGA Monitor', '5', '0', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('13', '9', '20', '0', '12', '14', '102', '17 inch VGA Monitor', '1', '10', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('20', '10', '20', '0', '9', '12', 'AA101', 'olie 5w40', '8', '3.25', '0', NULL);
INSERT INTO `supp_invoice_items` VALUES ('21', '11', '20', '0', '10', '12', 'AA101', 'olie 5w40', '408', '3.25', '0.81', NULL);

INSERT INTO `supp_invoice_tax_items` VALUES ('1', '2', '20', '1', NULL, '5', '0', '162.5');
INSERT INTO `supp_invoice_tax_items` VALUES ('2', '2', '20', '2', NULL, '1', '0', '32.5');
INSERT INTO `supp_invoice_tax_items` VALUES ('3', '10', '20', '3', NULL, '25', '0', '5.2');
INSERT INTO `supp_invoice_tax_items` VALUES ('4', '11', '20', '3', NULL, '25', '0', '331.5');

INSERT INTO `supp_trans` VALUES ('2', '20', '1', '22', '22', '2011-01-18', '2011-02-22', '3250', '0', '195', '1', '3445');
INSERT INTO `supp_trans` VALUES ('2', '22', '1', '1', '', '2011-01-18', '2011-01-18', '-5000', '0', '0', '1', '5000');
INSERT INTO `supp_trans` VALUES ('3', '20', '1', '23', 'asdf', '2011-01-18', '2011-02-22', '26', '0', '0', '1', '26');
INSERT INTO `supp_trans` VALUES ('3', '22', '2', '2', '', '2011-01-18', '2011-01-18', '-3300', '0', '0', '1.2', '0');
INSERT INTO `supp_trans` VALUES ('4', '20', '1', '24', 'Himself', '2011-01-30', '2008-02-22', '17350', '0', '0', '1', '1529');
INSERT INTO `supp_trans` VALUES ('5', '20', '1', '25', '6789', '2011-02-03', '2008-03-22', '6644', '0', '0', '1', '0');
INSERT INTO `supp_trans` VALUES ('6', '1', '1', '5', '', '2011-03-22', '0000-00-00', '-200', '0', '0', '1', '0');
INSERT INTO `supp_trans` VALUES ('6', '20', '3', '26', '333333', '2011-03-05', '2008-03-12', '200', '0', '0', '0.2', '0');
INSERT INTO `supp_trans` VALUES ('7', '20', '1', '27', 'eee', '2011-03-06', '2011-04-17', '550', '0', '0', '1', '0');
INSERT INTO `supp_trans` VALUES ('8', '20', '2', '28', '213', '2011-03-20', '2011-04-17', '0', '0', '0', '1.2', '0');
INSERT INTO `supp_trans` VALUES ('9', '20', '2', '29', 'aaa', '2011-03-25', '2011-04-17', '10', '0', '0', '1.9816266221251', '0');
INSERT INTO `supp_trans` VALUES ('10', '20', '4', '30', '12w', '2011-03-25', '2011-04-17', '20.8', '0', '5.2', '1.5569', '0');
INSERT INTO `supp_trans` VALUES ('11', '20', '4', '31', 'jan', '2011-03-28', '2011-04-17', '1326', '0', '331.5', '1.5796', '0');

INSERT INTO `suppliers` VALUES ('1', 'Ghostbusters Corp.', '', '', '123456789', 'USD', '1', '0', '0', '1', '4000', '2630', '4250');
INSERT INTO `suppliers` VALUES ('2', 'Beefeater Ltd.', '', '', '987654321', 'GBP', '1', '0', '0', '2', '4000', '2630', '4250');
INSERT INTO `suppliers` VALUES ('3', 'Super Trooper AB', 'Adress', 'sven@sven.sve', '123456', 'SEK', '3', '0', '0', '2', '4000', '2630', '4250');
INSERT INTO `suppliers` VALUES ('4', 'Brezan', 'N/A', 'info@brezan.tv', '', 'EUR', '1', '0', '0', '1', '4010', '2630', '4250');

INSERT INTO `sys_types` VALUES ('0', 'Journal - GL', '18', '34');
INSERT INTO `sys_types` VALUES ('1', 'Payment - GL', '7', '7');
INSERT INTO `sys_types` VALUES ('2', 'Receipt - GL', '4', '14');
INSERT INTO `sys_types` VALUES ('4', 'Funds Transfer', '3', '6');
INSERT INTO `sys_types` VALUES ('10', 'Sales Invoice', '19', '19');
INSERT INTO `sys_types` VALUES ('11', 'Credit Note', '4', '4');
INSERT INTO `sys_types` VALUES ('12', 'Receipt', '9', '9');
INSERT INTO `sys_types` VALUES ('13', 'Delivery', '20', '9');
INSERT INTO `sys_types` VALUES ('16', 'Location Transfer', '2', '2');
INSERT INTO `sys_types` VALUES ('17', 'Inventory Adjustment', '2', '2');
INSERT INTO `sys_types` VALUES ('18', 'Purchase Order', '1', '15');
INSERT INTO `sys_types` VALUES ('20', 'Supplier Invoice', '11', '32');
INSERT INTO `sys_types` VALUES ('21', 'Supplier Credit Note', '1', '2');
INSERT INTO `sys_types` VALUES ('22', 'Supplier Payment', '3', '3');
INSERT INTO `sys_types` VALUES ('25', 'Purchase Order Delivery', '1', '13');
INSERT INTO `sys_types` VALUES ('26', 'Work Order', '1', '8');
INSERT INTO `sys_types` VALUES ('28', 'Work Order Issue', '1', '2');
INSERT INTO `sys_types` VALUES ('29', 'Work Order Production', '1', '201');
INSERT INTO `sys_types` VALUES ('30', 'Sales Order', '1', '1');
INSERT INTO `sys_types` VALUES ('35', 'Cost Update', '5', '1');
INSERT INTO `sys_types` VALUES ('40', 'Dimension', '1', '3');

INSERT INTO `tax_group_items` VALUES ('1', '1', '5', '0');
INSERT INTO `tax_group_items` VALUES ('1', '3', '25', '0');
INSERT INTO `tax_group_items` VALUES ('4', '3', '25', '0');

INSERT INTO `tax_groups` VALUES ('1', 'VAT', '0');
INSERT INTO `tax_groups` VALUES ('2', 'Tax-Free', '0');
INSERT INTO `tax_groups` VALUES ('4', 'Shipping', '1');

INSERT INTO `tax_types` VALUES ('1', '5', '2660', '2680', 'VAT', '1');
INSERT INTO `tax_types` VALUES ('2', '1', '2662', '2680', 'Manufact tax 1', '1');
INSERT INTO `tax_types` VALUES ('3', '25', '2664', '2682', 'VAT', '1');

INSERT INTO `users` VALUES('demouser', '5f4dcc3b5aa765d61d8327deb882cf99', 'Demo User', 1, '999-999-999', 'demo@demo.nu', 'en_US', 0, 0, 0, 0, 'default', 'Letter', 2, 2, 3, 1, 1, 0, '2011-02-06 19:02:35');
INSERT INTO `users` VALUES('admin', '5f4dcc3b5aa765d61d8327deb882cf99', 'Administrator', 2, '', 'adm@adm.com', 'en_US', 0, 0, 0, 0, 'default', 'Letter', 2, 2, 4, 1, 1, 0, '2011-03-20 10:52:46');

INSERT INTO `wo_issue_items` VALUES ('1', '102', '1', '10');

INSERT INTO `wo_issues` VALUES ('1', '3', '1', '2011-01-20', 'DEF', '1');

INSERT INTO `wo_manufacture` VALUES ('1', 'ab200', '3', '50', '2011-01-30');
INSERT INTO `wo_manufacture` VALUES ('2', 'ab201', '5', '20', '2011-01-30');

INSERT INTO `wo_requirements` VALUES ('1', '1', '102', '1', '1', '0', 'DEF', '20');
INSERT INTO `wo_requirements` VALUES ('2', '1', '103', '1', '1', '0', 'DEF', '20');
INSERT INTO `wo_requirements` VALUES ('3', '1', '104', '1', '1', '0', 'DEF', '20');
INSERT INTO `wo_requirements` VALUES ('4', '1', '201', '1', '1', '0', 'DEF', '20');
INSERT INTO `wo_requirements` VALUES ('5', '2', '102', '1', '1', '0', 'DEF', '5');
INSERT INTO `wo_requirements` VALUES ('6', '2', '103', '1', '1', '0', 'DEF', '5');
INSERT INTO `wo_requirements` VALUES ('7', '2', '104', '1', '1', '0', 'DEF', '5');
INSERT INTO `wo_requirements` VALUES ('8', '2', '201', '1', '1', '0', 'DEF', '5');
INSERT INTO `wo_requirements` VALUES ('9', '3', '102', '1', '1', '0', 'DEF', '0');
INSERT INTO `wo_requirements` VALUES ('10', '3', '103', '1', '1', '0', 'DEF', '0');
INSERT INTO `wo_requirements` VALUES ('11', '3', '104', '1', '1', '0', 'DEF', '0');
INSERT INTO `wo_requirements` VALUES ('12', '3', '201', '1', '1', '0', 'DEF', '0');
INSERT INTO `wo_requirements` VALUES ('13', '4', '102', '1', '1', '0', 'DEF', '5');
INSERT INTO `wo_requirements` VALUES ('14', '4', '103', '1', '1', '0', 'DEF', '5');
INSERT INTO `wo_requirements` VALUES ('15', '4', '104', '1', '1', '0', 'DEF', '5');
INSERT INTO `wo_requirements` VALUES ('16', '4', '201', '1', '1', '0', 'DEF', '5');
INSERT INTO `wo_requirements` VALUES ('17', '5', '102', '1', '1', '0', 'DEF', '0');
INSERT INTO `wo_requirements` VALUES ('18', '5', '103', '1', '1', '0', 'DEF', '0');
INSERT INTO `wo_requirements` VALUES ('19', '5', '104', '1', '1', '0', 'DEF', '0');
INSERT INTO `wo_requirements` VALUES ('20', '5', '201', '1', '1', '0', 'DEF', '0');
INSERT INTO `wo_requirements` VALUES ('21', '6', '102', '1', '1', '0', 'DEF', '10');
INSERT INTO `wo_requirements` VALUES ('22', '6', '103', '1', '1', '0', 'DEF', '10');
INSERT INTO `wo_requirements` VALUES ('23', '6', '104', '1', '1', '0', 'DEF', '10');
INSERT INTO `wo_requirements` VALUES ('24', '6', '201', '1', '1', '0', 'DEF', '10');
INSERT INTO `wo_requirements` VALUES ('25', '7', '102', '1', '1', '0', 'DEF', '1');
INSERT INTO `wo_requirements` VALUES ('26', '7', '103', '1', '1', '0', 'DEF', '1');
INSERT INTO `wo_requirements` VALUES ('27', '7', '104', '1', '1', '0', 'DEF', '1');
INSERT INTO `wo_requirements` VALUES ('28', '7', '201', '1', '1', '0', 'DEF', '1');

INSERT INTO `workcentres` VALUES ('1', 'work centre', '');

INSERT INTO `workorders` VALUES ('1', '1', 'DEF', '20', '3400', '2011-01-18', '0', '2011-01-18', '2011-01-18', '20', '1', '1', '0');
INSERT INTO `workorders` VALUES ('2', '2', 'DEF', '5', '3400', '2011-01-18', '0', '2011-01-18', '2011-01-18', '5', '1', '1', '0');
INSERT INTO `workorders` VALUES ('3', '3', 'DEF', '50', '3400', '2011-01-18', '2', '2011-02-07', '2011-01-20', '50', '1', '1', '0');
INSERT INTO `workorders` VALUES ('4', '4', 'DEF', '5', '3400', '2011-01-30', '0', '2011-01-30', '2011-01-30', '5', '1', '1', '0');
INSERT INTO `workorders` VALUES ('5', '5', 'DEF', '20', '3400', '2011-01-30', '2', '2011-02-19', '2011-01-30', '20', '1', '1', '0');
INSERT INTO `workorders` VALUES ('6', '6', 'DEF', '10', '3400', '2011-02-28', '0', '2011-02-28', '2011-02-28', '10', '1', '1', '234');
INSERT INTO `workorders` VALUES ('7', '7', 'DEF', '1', '3400', '2011-03-07', '0', '2011-03-07', '2011-03-07', '1', '1', '1', '0');

