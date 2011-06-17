<?php

$page_security =10;
$path_to_root="..";
include($path_to_root . "/includes/session.inc");

page(tr("Company Setup"));

include_once($path_to_root . "/includes/date_functions.inc");
include_once($path_to_root . "/includes/ui.inc");

include_once($path_to_root . "/admin/db/company_db.inc");

//-------------------------------------------------------------------------------------------------

if (isset($_POST['deleteImage']) == '1') {
  $sql= "update company set image='' where coy_code=1";
  $result = db_query($sql, "could not delete image");
}
$blob = image_load($max_image_size);

if (isset($_POST['submit']) && $_POST['submit'] != "")
{
	$input_error = 0;

	if (strlen($_POST['coy_name'])==0)
	{
		$input_error = 1;
		display_error(tr("The company name must be entered."));
		set_focus('coy_name');
	}
	if ($input_error != 1)
	{
		update_company_setup($_POST['coy_name'], $_POST['coy_no'], $_POST['gst_no'], $_POST['tax_prd'], $_POST['tax_last'],
			$_POST['postal_address'], $_POST['phone'], $_POST['fax'], $_POST['email'], $_POST['coy_logo'], $_POST['domicile'],
			$_POST['use_dimension'], $_POST['custom1_name'], $_POST['custom2_name'], $_POST['custom3_name'],
			$_POST['custom1_value'], $_POST['custom2_value'], $_POST['custom3_value'],
			$_POST['curr_default'], $_POST['f_year'], check_value('no_item_list'), check_value('no_customer_list'),
			check_value('no_supplier_list'),$blob);

		display_notification_centered(tr("Company setup has been updated."));
	}

} /* end of if submit */

//---------------------------------------------------------------------------------------------


start_form(true);

$myrow = get_company_prefs();

$_POST['coy_name'] = $myrow["coy_name"];
$_POST['gst_no'] = $myrow["gst_no"];
$_POST['tax_prd'] = $myrow["tax_prd"];
$_POST['tax_last'] = $myrow["tax_last"];
$_POST['coy_no']  = $myrow["coy_no"];
$_POST['postal_address']  = $myrow["postal_address"];
$_POST['phone']  = $myrow["phone"];
$_POST['fax']  = $myrow["fax"];
$_POST['email']  = $myrow["email"];
$_POST['coy_logo']  = $myrow["coy_logo"];
$_POST['domicile']  = $myrow["domicile"];
$_POST['use_dimension']  = $myrow["use_dimension"];
$_POST['no_item_list']  = $myrow["no_item_list"];
$_POST['no_customer_list']  = $myrow["no_customer_list"];
$_POST['no_supplier_list']  = $myrow["no_supplier_list"];
$_POST['custom1_name']  = $myrow["custom1_name"];
$_POST['custom2_name']  = $myrow["custom2_name"];
$_POST['custom3_name']  = $myrow["custom3_name"];
$_POST['custom1_value']  = $myrow["custom1_value"];
$_POST['custom2_value']  = $myrow["custom2_value"];
$_POST['custom3_value']  = $myrow["custom3_value"];
$_POST['curr_default']  = $myrow["curr_default"];
$_POST['f_year']  = $myrow["f_year"];

start_table($table_style2);

text_row_ex(tr("Name (to appear on reports):"), 'coy_name', 42, 50);
text_row_ex(tr("Official Company Number:"), 'coy_no', 25);
text_row_ex(tr("Tax Authority Reference:"), 'gst_no', 25);

text_row_ex(tr("Tax Periods:"), 'tax_prd', 10, 10, null, null, tr('Months.'));
text_row_ex(tr("Tax Last Period:"), 'tax_last', 10, 10, null, null, tr('Months back.'));

currencies_list_row(tr("Home Currency:"), 'curr_default', $_POST['curr_default']);
fiscalyears_list_row(tr("Fiscal Year:"), 'f_year', $_POST['f_year']);

textarea_row(tr("Address:"), 'postal_address', $_POST['postal_address'], 35, 5);

text_row_ex(tr("Telephone Number:"), 'phone', 25, 55);
text_row_ex(tr("Facsimile Number:"), 'fax', 25);
text_row_ex(tr("Email Address:"), 'email', 25, 55);

//text_row_ex(tr("Company Logo:"), 'coy_logo', 25, 55);
start_row();
label_cells(tr("Image File (.jpg)") . ":", "<input type='file' id='pic' name='pic'>");
$fileimg = $path_to_root."/image.php?id=1&table=company";
$stock_img_link = "<img src='$fileimg' width='100px' border='0'>";
$stock_img_link .= "<br>".tr("Delete").
      "<input type='checkbox' name='deleteImage' value='1'>";
label_cell($stock_img_link, "valign=top align=center rowspan=6");
end_row();

text_row_ex(tr("Domicile:"), 'domicile', 25, 55);

number_list_row(tr("Use Dimensions:"), 'use_dimension', null, 0, 2);

check_row(tr("No Item List"), 'no_item_list', $_POST['no_item_list']);
check_row(tr("No Customer List"), 'no_customer_list', $_POST['no_customer_list']);
check_row(tr("No Supplier List"), 'no_supplier_list', $_POST['no_supplier_list']);


start_row();
end_row();
label_row(tr("Custom Field Name"), tr("Custom Field Value"));

start_row();
text_cells(null, 'custom1_name', $_POST['custom1_name'], 25, 25);
text_cells(null, 'custom1_value', $_POST['custom1_value'], 30, 30);
end_row();

start_row();
text_cells(null, 'custom2_name', $_POST['custom2_name'], 25, 25);
text_cells(null, 'custom2_value', $_POST['custom2_value'], 30, 30);
end_row();

start_row();
text_cells(null, 'custom3_name', $_POST['custom3_name'], 25, 25);
text_cells(null, 'custom3_value', $_POST['custom3_value'], 30, 30);
end_row();

end_table(1);

submit_center('submit', tr("Update"));

end_form(2);
//-------------------------------------------------------------------------------------------------

end_page();

?>
