<?php

// print out image from stock_master table

$path_to_root=".";
$page_security = 1;

include_once("includes/session.inc");

if(isset($_GET['id'])) {
	$id = $_GET['id'];
	$table = $_GET['table'];
	if ($table == "") {
	  $table = "stock_master";
	}
	$sql= "SELECT image from $table ".
	   		"WHERE stock_id=".db_escape($id)." limit 1";
	if ($table == "company") {
	  $sql= "SELECT image from $table ".
	     		"WHERE coy_code=$id limit 1";
	}
	$result = db_query($sql, "could not query image");
	$myrow = db_fetch_row($result);
	if (strlen($myrow[0]) > 0) {
		ob_end_clean();
		header('Content-Type: image/jpeg');
		print $myrow[0];
	} else {
		echo tr("Image not found");
	}
} else {
	echo tr("No image");
}
?>
