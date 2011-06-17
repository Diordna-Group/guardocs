<?php
class BoxReports 
{
	var $ar_classes;

	function ReportClasses() 
	{
		$this->ar_classes = array();
	}

	function addReportClass($class_name) 
	{
		$this->ar_classes[$class_name] = array();
	}

	function addReport($class_name, $id, $rep_name, $params=null) 
	{
		$this->ar_classes[$class_name][] = new Report($id,$rep_name,$params);
	}

	function getDisplay($class=null) 
	{
		global $table_style2;
		$temp = array_values($this->ar_classes);
		$display_class = $class==null ? $temp[0] : $this->ar_classes[$class];
		$class_counter = 0;
		$rep_counter = 0;
		$st_reports = "";
		$st_params = "";
		$st_classes = "<b>" . tr("Report Classes:") . "</b><br>";
		foreach($this->ar_classes as $key=>$value) 
		{
			$style = $class_counter==0 ? '' : $style = "style='display:none'";
			$st_classes .= "<a href='javascript:showClass($class_counter)'>$key</a> <br>";
			$st_reports .= "<table id='TAB_" . $class_counter++ ."' $style cellpadding=0 cellspacing=0 border=0 width='100%'><tr><td><b>" . tr("Reports For Class: ") . "&nbsp;$key</b></td></tr>";
			foreach($value as $report) 
			{
				$st_reports .= "<tr><td><a href='javascript:showReport($rep_counter)'>" . $report->name . "</a></td></tr>";
				$st_params .= "<table border=0 id='REP_" . $rep_counter++ . "' style='display:none'>";
				$st_params .= "<tr><td>" . $report->getDisplay() . "</td></tr></table>";
			}
			$st_reports .= "</table>";
		}

		$st = 	"<script language='javascript'>
					function showClass(pClass) {
						for(i=0; i<$class_counter; i++) {
							eval('document.getElementById(\"TAB_\" + i).style.display=\"none\"')
						}
						eval('document.getElementById(\"TAB_\" + pClass).style.display=\"block\"')
						for (i=0; i<$rep_counter; i++) {
							eval('document.getElementById(\"REP_\" + i).style.display=\"none\"')
						}
					}
					function showReport(pId) {
						var tab;
						for(i=0; i<$rep_counter; i++) {
							eval('document.getElementById(\"REP_\" + i).style.display=\"none\"')
						}
						eval('document.getElementById(\"REP_\" + pId).style.display=\"block\"')
					}
				</script>
				";
		$st .= "<table align='center' width='80%' $table_style2><tr valign='top'>";
		$st .= "<td width='30%'>$st_classes</td>";
		$st .= "<td width='35%'>$st_reports</td>";
		$st .= "<td width='35%'>$st_params</td>";
		$st .= "</tr></table><br>";

		return $st;
	}
}

class Report 
{
	var $id;
	var $name;
	var $ar_params;

	function Report($id, $name, $ar_params) 
	{
		$this->id 			= $id;
		$this->name 		= $name;
		$this->ar_params	= $ar_params;
	}
	function getDisplay() 
	{
		global $comp_path, $path_to_root, $use_date_picker;

	        $rep_file = $comp_path.'/'.user_company().
		     "/reporting/rep".$this->id.".php";	 
		if (!file_exists($rep_file))
		    $rep_file = $path_to_root ."/reporting/rep".$this->id.".php";
		    
		$st = "
<script language='javascript'>
	function displayReport_" . $this->id . "() {
		pParamCount = " . count($this->ar_params) . ";
		document.forms[0].REP_ID.value = " . $this->id . ";
		document.forms[0].PARAM_COUNT.value = pParamCount;
		for (i=0; i<pParamCount; i++) {
			eval('document.forms[0].PARAM_' + i + '.value=document.forms[0].RP_" . $this->id . "_' + i + '.value');
		}

		document.forms[0].target='_blank';
		document.forms[0].action= '$rep_file';
		document.forms[0].submit();
	}
	function checkDate(pObj) {
		var re = /^(3[01]|0[1-9]|[12]\d)\/(0[1-9]|1[012])\/\d{4}/;
		if (re.test(pObj.value)==false) {
			alert('" . tr("Invalid date format") . "')
		}
	}
</script>
			";
		$st .= "<input type='button' onclick='javascript:displayReport_" . $this->id ."()' value='" . tr("Display: ") . $this->name . "'><br><br>";
		$dummy = "";
		if ($this->ar_params==null) 
			return "";
		foreach($this->ar_params as $index=>$param) 
		{
			$st .= $param->param_name . ':<br>';
			switch ($param->param_type) 
			{
				case 'CURRENCY':
					$sql = "SELECT curr_abrev, concat(curr_abrev,' - ', currency) FROM currencies";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Currency Filter"));
					break;
				case 'DATE':
				case 'DATEBEGIN':
				case 'DATEEND':
				case 'DATEBEGINM':
				case 'DATEENDM':
				case 'DATEBEGINTAX':
				case 'DATEENDTAX':
					if ($param->param_type == 'DATEBEGIN')
						$date = begin_fiscalyear();
					elseif ($param->param_type == 'DATEEND')
						$date = end_fiscalyear();
					else
						$date = Today();
					if ($param->param_type == 'DATEBEGINM')
						$date = begin_month($date);
					elseif ($param->param_type == 'DATEENDM')
						$date = end_month($date);
					elseif ($param->param_type == 'DATEBEGINTAX' || $param->param_type == 'DATEENDTAX')
					{
						$row = get_company_prefs();
						$edate = add_months($date, -$row['tax_last']);
						$edate = end_month($edate);
						if ($param->param_type == 'DATEENDTAX')
							$date = $edate;
						else
						{
							$bdate = add_months($edate, -$row['tax_prd'] + 1);
							$date = begin_month($bdate);
						}
					}	
					$name = "RP_" . $this->id . "_$index";			
					//$st .= "<input type='text' name='$name' value='$date' onblur='javascript:checkDate(this)'>";
					$st .= "<input type='text' name='$name' value='$date'>";
					if ($use_date_picker)
						$st .= "<a href=\"javascript:date_picker(document.forms[0].$name);\">"
						. "	<img src='$path_to_root/themes/default/images/cal.gif' width='16' height='16' border='0' alt='".tr('Click Here to Pick up the date')."'></a>\n";
					
					break;
				case 'YES_NO':	
					$sel = array(tr('No'), tr("Yes"));
					$st .= dup_simple_name_list("RP_" . $this->id . "_$index", $sel);
					break;
				case 'PAYMENT_LINK':	
					$sel = array(tr("No Payment Link"), "PayPal");
					$st .= dup_simple_name_list("RP_" . $this->id . "_$index", $sel);
					break;
				case 'COMPARE':
					$sel = array(tr("Accumulated"), tr("Period Y-1"), tr("Budget"));
					$st .= dup_simple_name_list("RP_" . $this->id . "_$index", $sel);
					break;
				case 'GRAPHIC':
					$sel = array(tr("No Graphics"), tr("Vertical bars"), tr("Horizontal bars"), tr("Dots"), tr("Lines"), tr("Pie"), tr("Donut"));
					$st .= dup_simple_name_list("RP_" . $this->id . "_$index", $sel);
					break;
				case 'SYS_TYPES':
					$st .= dup_systypes_list("RP_" . $this->id . "_$index", $dummy, true, tr("No Type Filter"), true);
					break;				
				case 'TEXT':
					$st .= "<input type='text' name='RP_" . $this->id . "_$index'>";
					break;
				case 'TEXTBOX':
					$st .= "<textarea rows=4 cols=30 name='RP_" . $this->id . "_$index'></textarea>";
					break;
				case 'ACCOUNTS':
					$sql = "SELECT id, name FROM chart_types ORDER BY name";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Account Group Filter"), true);
					break;
				case 'GL_ACCOUNTS':
					$sql = "SELECT account_code, concat(account_code, ' - ', account_name) as account_name FROM chart_master ORDER BY account_code";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'BANK_ACCOUNTS':
					$sql = "SELECT bank_accounts.account_code, concat(bank_account_name, if (bank_curr_code=curr_default,'', concat(' - ', bank_curr_code))) FROM bank_accounts, chart_master, company 
						WHERE bank_accounts.account_code=chart_master.account_code";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'DIMENSION':
					$sql = "SELECT reference, concat(reference, ' - ', name) AS DimName FROM dimensions ORDER BY reference";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'DIMENSIONS':
					$sql = "SELECT reference, concat(reference, ' - ', name) as DimName FROM dimensions ORDER BY reference";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Dimension Filter"), true);
					break;
				case 'DIMENSION1':
					$sql = "SELECT reference, concat(reference, ' - ', name) AS DimName FROM dimensions WHERE type_=1 ORDER BY reference";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'DIMENSIONS1':
					$sql = "SELECT reference, concat(reference, ' - ', name) as DimName FROM dimensions WHERE type_=1 ORDER BY reference";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Dimension Filter"), true);
					break;
				case 'DIMENSION2':
					$sql = "SELECT reference, concat(reference, ' - ', name) AS DimName FROM dimensions WHERE type_=2 ORDER BY reference";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'DIMENSIONS2':
					$sql = "SELECT reference, concat(reference, ' - ', name) as DimName FROM dimensions WHERE type_=2 ORDER BY reference";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Dimension Filter"), true);
					break;
				case 'CUSTOMERS_NO_FILTER':
				case 'CUSTOMERS':
					$sql = "SELECT debtor_no, name FROM debtors_master ORDER BY name";
					if ($param->param_type == 'CUSTOMERS_NO_FILTER')
						$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Customer Filter"), true);
					else	
						$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'SUPPLIERS_NO_FILTER':
				case 'SUPPLIERS':
					$sql = "SELECT supplier_id, supp_name FROM suppliers ORDER BY supp_name";
					if ($param->param_type == 'SUPPLIERS_NO_FILTER')
						$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Supplier Filter"), true);
					else	
						$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'INVOICE':
					$IV = tr("IV");
					$CN = tr("CN");
					$sql = "SELECT concat(debtor_trans.trans_no, '-', 
						debtor_trans.type) AS TNO, concat(debtor_trans.trans_no, if (type=10, ' $IV ', ' $CN '), debtors_master.name) as IName 
						FROM debtors_master, debtor_trans WHERE (type=10 OR type=11) AND debtors_master.debtor_no=debtor_trans.debtor_no ORDER BY debtor_trans.trans_no DESC";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'DELIVERY':
					$DN = tr("DN");
					$sql = "SELECT 
					concat(debtor_trans.trans_no, '-', debtor_trans.type) AS TNO, concat(debtor_trans.trans_no, ' $DN ', 
					 debtors_master.name) as IName 
						FROM debtors_master, debtor_trans 
						WHERE type=13 AND debtors_master.debtor_no=".
						"debtor_trans.debtor_no ORDER BY debtor_trans.trans_no DESC";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'ORDERS':
					$sql = "SELECT sales_orders.order_no, concat(sales_orders.order_no, '-', 
						debtors_master.name) as IName 
						FROM debtors_master, sales_orders WHERE debtors_master.debtor_no=sales_orders.debtor_no ORDER BY sales_orders.order_no DESC";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'PO':
					$sql = "SELECT purch_orders.order_no, concat(purch_orders.order_no, '-', 
						suppliers.supp_name) as IName  
						FROM suppliers, purch_orders WHERE suppliers.supplier_id=purch_orders.supplier_id ORDER BY purch_orders.order_no DESC";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'ITEMS':
					$sql = "SELECT stock_id, concat(stock_id, '-', description) as name FROM stock_master WHERE (mb_flag='A' OR mb_flag='M') ORDER BY stock_id";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'LOCATIONS':
					$sql = "SELECT loc_code, location_name FROM locations ORDER BY location_name";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Location Filter"), false);
					break;
				case 'CATEGORIES':
					$sql = "SELECT category_id, description FROM stock_category ORDER BY description";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Category Filter"), true);
					break;
				case 'SALESTYPES':
					$sql = "SELECT id, sales_type FROM sales_types ORDER BY sales_type";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'AREAS':
					$sql = "SELECT area_code, description FROM areas ORDER BY description";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Area Filter"), true);
					break;
				case 'SALESMEN':
					$sql = "SELECT salesman_code, salesman_name FROM salesman ORDER BY salesman_name";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy, true, tr("No Sales Folk Filter"), true);
					break;
				case 'TRANS_YEARS':
					$sql = "SELECT DISTINCT YEAR(tran_date), YEAR(tran_date) FROM gl_trans";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;
				case 'ACCOUNTS_NO_FILTER':
					$sql = "SELECT id, name FROM chart_types ORDER BY name";
					$st .= dup_simple_codeandname_list($sql, "RP_" . $this->id . "_$index", $dummy);
					break;

			}
			$st .= "<br><br>";
		}
		return $st;
	}
}

class ReportParam 
{
	var $param_name;
	var $param_type;

	function ReportParam($param_name, $param_type) 
	{
		$this->param_name = $param_name;
		$this->param_type = $param_type;
	}
}

function dup_simple_codeandname_list($sql, $name, &$selected_id,
	$all_option=false, $all_option_name=null, $all_option_numeric=false, 
	$submit_on_change=false)
{
	if ($submit_on_change == true)
		$st = "<select name='$name' onchange='this.form.submit();'>";
	else
		$st = "<select name='$name'>";

	if ($all_option == true)
	{
		if ($all_option_numeric)
			$reserved_word = reserved_words::get_all_numeric();
		else
			$reserved_word = reserved_words::get_all();

    	if ($reserved_word == $selected_id)
    	{
    	     $st .= "<option selected value='" . $reserved_word . "'>" . $all_option_name . "</option>\n";
    	} 
    	else 
    	{
    	     $st .= "<option value='" . $reserved_word . "'>" . $all_option_name . "</option>\n";
    	}
		if ($selected_id == "") 
		{
			$selected_id =  $reserved_word;
		}
	}

	$result = db_query($sql);

	while ($row = db_fetch_row($result)) 
	{
		if ($selected_id == $row[0]) 
		{
			$st .= "<option selected value='" . $row[0] . "'>";
		} 
		else 
		{
			$st .= "<option value='" . $row[0] . "'>";
		}
		$st .= $row[1] . "</option>\n";

		if ($selected_id == "") 
		{
			$selected_id = $row[0];
		}
	}

	$st .= "</select>";
	db_free_result($result);

	return $st;
}

function dup_simple_name_list($name, $selections)
{
	$st = "<select name='$name'>";
	for ($i = 0; $i < count($selections); $i++)
		$st .= "<option value='" . $i . "'>" . $selections[$i] . "</option>\n";
	$st .= "</select>";
	return $st;
}

//------------------------------------------------------------------------------------------------

function dup_systypes_list($name, &$selected_id, $all_option=false, $all_option_name=null)
{
	global $systypes_array;
	
   	$st = "<select name='$name'>";
	if ($all_option == true)
	{
		$reserved_word = reserved_words::get_all_numeric();
    	if ($reserved_word == $selected_id)
    	     $st .= "<option selected value='" . $reserved_word . "'>" . $all_option_name . "</option>\n";
    	else 
    	     $st .= "<option value='" . $reserved_word . "'>" . $all_option_name . "</option>\n";
		if ($selected_id == "") 
			$selected_id = $reserved_word;
	}

	foreach ($systypes_array as $i => $value)
	{
		if ($i == 16 || $i == 18 || $i == 25 || $i >= 28)
			continue;
    	$st .= "<option" . ($selected_id == $i ? " selected" : "") . " value='$i'>" . $value['name'] . "</option>\n";
	}    	
    $st .= "<select>";
	return $st;
}


?>
