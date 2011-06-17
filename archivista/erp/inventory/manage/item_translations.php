<?php

$page_security = 11;
$path_to_root="../..";
include($path_to_root . "/includes/session.inc");

page(tr("Item Translations"));

include_once($path_to_root . "/includes/ui.inc");
include_once($path_to_root . "/inventory/includes/db/items_translations_db.inc");

if (isset($_GET['id_edit'])) {
	$selected_id = $_GET['id_edit'];
} else if (isset($_POST['id'])) {
	$selected_id = $_POST['id'];
}
if (isset($_GET['New'])) {
	$_POST['New'] = "1";
}

if (isset($_POST['ADD_ITEM']) || isset($_POST['UPDATE_ITEM'])) {
	//initialise no input errors assumed initially before we test
	$input_error = 0;
	if (strlen($_POST['id_stock']) == 0) {
		$input_error = 1;
		display_error(tr("The item code cannot be empty."));
		set_focus('id_stock');
	}
	if (strlen($_POST['description']) == 0) {
		$input_error = 1;
		display_error(tr("The item name cannot be empty."));
		set_focus('description');
	}
	if (strlen($_POST['areas']) == 0) {
		$input_error = 1;
		display_error(tr("The areas field cannot be empty."));
		set_focus('areas');
	}
	if ($input_error !=1) {
   	write_item_translation(isset($selected_id) ? $selected_id : '',
		$_POST['id_stock'], $_POST['description'], $_POST['long_description'],
		$_POST['areas'] );
		meta_forward($_SERVER['PHP_SELF']); 
	}
}

if (isset($_POST['delete'])) {
	delete_item_translation($selected_id);
	meta_forward($_SERVER['PHP_SELF']); 		
}

start_form();

if (isset($_POST['SelectItemTranslation'])) {
	start_table("class='tablestyle_noborder'");
  label_row(tr("Id:"), $_POST['id']);
	//editing an existing item category
	$myrow = get_item_translation($selected_id);
	$_POST['id_stock'] = $myrow["id_stock"];
	$_POST['description']  = $myrow["description"];
	$_POST['long_description']  = $myrow["long_description"];
	$_POST['areas']  = $myrow["areas"];
	hidden('id', $selected_id);
  text_row(tr("Item Code:"), 'id_stock', $_POST['id_stock'], 20, 20);
  text_row(tr("Name:"), 'description', $_POST['description'], 40, 200);  
  textarea_row(tr("Description:"), 'long_description', 
	            $_POST['long_description'], 40, 10);  
  text_row(tr("Areas:"), 'areas', $_POST['areas'], 40, 200);  
  end_table(1);
	br();
  submit_add_or_update_center(!isset($selected_id));
	br();
  submit_center('delete', tr("Delete"));
	br();
} elseif (isset($_POST['NewItemTranslation'])) {
	start_table("class='tablestyle_noborder'");
  text_row(tr("Item Code:"), 'id_stock', null, 20, 20);
  text_row(tr("Name:"), 'description', null, 40, 200);  
  textarea_row(tr("Description:"), 'long_description', null, 40, 10);  
  text_row(tr("Areas:"), 'areas', null, 40, 200);
	end_table(1);
	br();
	submit_center('ADD_ITEM', tr("Save"));
	br();
} else {
  if (db_has_item_translations()) {
	  start_table("class='tablestyle_noborder'");
	  start_row();
    item_translations_list_cells(tr("Select a translation:"), 'id', null);
    submit_cells('SelectItemTranslation', tr("Edit"));
	  end_row();
	  end_table();
		br();
	}
	submit_center('NewItemTranslation', tr("New Item Translation"));
	br();
}

end_form();
end_page();
?>
