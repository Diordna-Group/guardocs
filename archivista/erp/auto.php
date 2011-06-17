<?php
$_POST["user_name_entry_field"] = "admin";
$_POST["company_login_name"] = "0";
$_POST["password"] = "archivista";
$page_security = 1;
include("includes/session.inc");
chdir("./sales"); # printing of orders/quotes is called from sales directory
include("../reporting/includes/reporting.inc");
include("../reporting/includes/pdf_report.inc");
include("../reporting/rep109.php");
$sql = "SELECT sales_orders.order_no from sales_orders where order_no=20";
$result = db_query($sql,$db);
if ($result) {
  while ($myrow = db_fetch($result)) { 
    $nr = $myrow[0];
  }
  $bank = get_first_bank_account();
  $quote = 1;
  $comments = "";
  printit($nr,$nr,"CHF",$bank,0,$quote,"","/tmp/output.pdf");
}
?>
