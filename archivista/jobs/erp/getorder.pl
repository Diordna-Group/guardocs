#!/usr/bin/perl

# getorder.pl -> (c) 2010-03-01 by Urs Pfister
# Get last order and insert it to ArchivistaERP

use lib '/home/cvs/archivista/jobs';
use AVJobs;

my $file = "/home/data/archivista/userpwshop.txt";
my $cont = "";

readFile2($file,\$cont,0);
my ($host,$db,$user,$pw) = split("\n",$cont);
$file = "/home/data/archivista/userpwerp.txt";
$cont = "";
readFile2($file,\$cont,0);
my ($host2,$db2,$user2,$pw2) = split("\n",$cont);

my $dbh = MySQLOpen($host,$db,$user,$pw);
if ($dbh) {
  $erp = MySQLOpen($host2,$db2,$user2,$pw2);
	if ($erp) {
	  my $sql = "select * from orders where orders_status=1 ".
		          "order by orders_id desc limit 1";
		my @order = $dbh->selectrow_array($sql);
		my $orderid = $order[0];
		my $custshop = $order[1];
	  $sql = "select debtor_no,customer_id from debtors_master ".
		       "where customer_id=$custshop";
		my @row = $erp->selectrow_array($sql);
		my $custerp = $row[0];
		if ($custshop == $row[1]) {
      $sql = "select branch_code from cust_branch ".
	           "where debtor_no=$custerp limit 1";
      my ($branch) = $erp->selectrow_array($sql);
			if ($branch>0) {
		    # customer/branch do exist, so we can process order
		    order_add($dbh,$erp,$custshop,$custerp,$branch,$orderid,\@order);
			}
		}
	}
}




sub order_add {
  my ($dbh,$erp,$custshop,$custerp,$branch,$orderid,$porder) = @_;
  my $sql = "select address from debtors_master ".
	          "where debtor_no=$custerp limit 1";
	my ($adr) = $erp->selectrow_array($sql);
	$date = $$porder[37];
	$sql = "select * from cust_branch where branch_code=$branch";
	my (@branch) = $erp->selectrow_array($sql);
	my $ship = $branch[16];
	my $phone = $branch[6];
	my $mail = $branch[9];
	$sql = "select value from orders_total where ".
	       "orders_id=$orderid and class='ot_shipping'";
	my ($shipcost) = $dbh->selectrow_array($sql);
  $sql = "insert into sales_orders set ".
	       "debtor_no=$custerp,branch_code=$branch,".
				 "delivery_address=".$erp->quote($adr).",".
				 "order_type=2,".
				 "ord_date=".$erp->quote($date).",".
				 "ship_via=$ship,".
				 "contact_phone=".$erp->quote($phone).",".
				 "contact_email=".$erp->quote($mail).",".
				 "from_stk_loc='DEF',".
				 "freight_cost=$shipcost,".
				 "delivery_date=".$erp->quote($date);
	$erp->do($sql);
	my ($order_no) = $erp->selectrow_array("select LAST_INSERT_ID()");
	$sql = "select * from orders_products where orders_id=$orderid";
	my $pres1 = $dbh->selectall_arrayref($sql);
	foreach (@$pres1) {
		my @products = @$_;
		my $prodid = $products[0];
    my $code = $products[3];
		my $name = ucfirst($code)." - ".$products[4];
		my $price = $products[5];
		my $quant = $products[8];
		order_add_product($erp,$order_no,$code,$name,$price,$quant,$date);
		$sql = "select * from orders_products_attributes where ".
		       "orders_id=$orderid and orders_products_id=$prodid";
	  my $pres2 = $dbh->selectall_arrayref($sql);
	  foreach (@$pres2) {
		  my @attr = @$_;
			my $code2 = "$code-".$attr[8];
			my $name2 = ucfirst($code)." - ". $attr[3]. " - ".$attr[4];
			my $price = $attr[5];
			my $plusminus = $attr[6];
			$price = $price-(2*$price) if $plusminus eq "-";
			order_add_product($erp,$order_no,$code2,$name2,$price,$quant,$date);
		}
	}
}




sub order_add_product {
  my ($erp,$order_no,$code,$name,$price,$quant,$date) = @_;
  my $sql = "insert into sales_order_details set ".
	          "order_no=$order_no,".
						"stk_code=".$erp->quote($code).",".
						"description=".$erp->quote($name).",".
						"unit_price=$price,".
						"quantity=$quant,".
						"date_from=".$erp->quote($date);
	$erp->do($sql);
}
		

		

