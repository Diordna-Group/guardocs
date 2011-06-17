#!/usr/bin/perl

# updateproducts.pl -> (c) 2010-03-01 by Urs Pfister
# Extract prices from oscommerce to ArchivistaERP

use lib '/home/cvs/archivista/jobs';
use AVJobs;
my $langde = 2;
my $langen = 1;
my $prod = "sales_account='3000',cogs_account='4000',".
           "inventory_account='1200',adjustment_account='6700',".
			     "assembly_account='6700',tax_type_id=1,selling=1";
my $work = "work";
my $type = "sales_type_id=1 and curr_abrev='CHF' and factor=0";
my $curr = "CHF";

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
	  my $sql = "select products_id,products_model,products_price from products";
		my $pres = $dbh->selectall_arrayref($sql);
		foreach (@$pres) {
			my ($id,$key,$price) = @$_;
			$price = int $price;
			if ($key ne "") {
			  $sql = "select products_name from products_description ".
				       "where products_id=$id and language_id=$langen";
				my ($namee) = $dbh->selectrow_array($sql);
			  $sql = "select products_name from products_description ".
				       "where products_id=$id and language_id=$langde";
				my ($name) = $dbh->selectrow_array($sql);
			  print "$key--$name--$namee--$price--$dep--$id\n";
				check_product($erp,$key,$name,$price,"",$prod,$work,$type,$namee,
				              $dbh,$id,0,$curr);
			  $sql = "select * from products_attributes where products_id=$id ".
				       "order by options_values_price asc";
				my $pres1 = $dbh->selectall_arrayref($sql);
				foreach (@$pres1) {
				  my ($attrid,$prodid,$optid,$valid,$price2,$plusminus) = @$_;
					$sql = "select * from products_options where ".
					       "products_options_id=$optid and language_id=$langen";
				  my ($optid2e,$langid2e,$name1e) = $dbh->selectrow_array($sql);
					$sql = "select * from products_options where ".
					       "products_options_id=$optid and language_id=$langde";
				  my ($optid2,$langid2,$name1) = $dbh->selectrow_array($sql);
					$sql = "select products_options_values_name ".
					       "from products_options_values where ".
								 "products_options_values_id=$valid and language_id=$langen";
					my ($name2e) = $dbh->selectrow_array($sql);
					$sql = "select products_options_values_name ".
					       "from products_options_values where ".
								 "products_options_values_id=$valid and language_id=$langde";
					my ($name2) = $dbh->selectrow_array($sql);
					my $key2 = "$key-$attrid";
					$name= "$name1 - $name2";
					$namee="$name1e - $name2e";
					$price = int $price2;
					$price = $price - (2*$price) if $plusminus eq "-";
					print "$key2--$name--$namee--$price--$dep\n";
				  check_product($erp,$key2,$name,$price,$key,$prod,$work,$type,$namee,
					              $dbh,$id,$attrid,$curr);
				}
			}
		}
		$sql = "select sales_types_name,sales_types_factor ".
		       "from sales_types";
		my $pres1 = $dbh->selectall_arrayref($sql);
		foreach (@$pres1) {
		  my ($name,$factor) = @$_;
			if ($factor>0 && $factor !=1) {
			  $sql = "select id from sales_types ".
				       "where sales_type=".$erp->quote($name);
				my @row = $erp->selectrow_array($sql);
				$sql = "insert into";
				$sql = "update" if $row[0]>0;
				$sql .= " sales_types set sales_type=".$dbh->quote($name).",".
				        "price_factor=$factor";
				$sql .= " where id=$row[0]" if $row[0]>0;
				$erp->do($sql);
			}
	  }
	}
}



sub check_product {
  my ($erp,$key,$name,$price,$dep,$prod,$work,$type,$namee,
	    $dbh,$id,$attr,$curr) = @_;
	my $cat = $key;
	$cat = $dep if $dep ne "";
	$cat = ucfirst($cat);
	my $sql = "select category_id,description from ".
	          "stock_category where description=".$erp->quote($cat);
	my @res = $erp->selectrow_array($sql);
	if ($res[1] ne $cat) {
	  my $sql1="insert into stock_category set description=".$erp->quote($cat);
		$erp->do($sql1);
		@res = $erp->selectrow_array($sql);
	}
	if ($res[1] eq $cat) {
	  my $catid=$res[0];
	  $sql="select stock_id from stock_master where stock_id=".$erp->quote($key);
	  my ($stockid) = $erp->selectrow_array($sql);
	  $sql1 = "update";
	  $sql1="insert into" if $stockid ne $key;
    my $sql2 = " where stock_id=".$erp->quote($key);
	  my $sql3 = "mb_flag='M'";
	  my $sql4 = "units='St.'";
	  if (index($key,"work")==0) {
	    $sql3 = "mb_flag='D'";
		  $sql4 = "units='Std.'";
	  }
	  $sql = "$sql1 stock_master set $sql3,$sql4,$prod,category_id=$catid,".
	    "stock_id=".$erp->quote($key).",description=".$erp->quote($name).",".
		  "depending=".$erp->quote($dep);
	  $sql.=$sql2 if $stockid eq $key;
	  $erp->do($sql);
	  $sql = "select stock_id from stock_master $sql2";
	  ($stockid) = $erp->selectrow_array($sql);
		if ($stockid eq $key) {
		  $sql = "select stock_id,id from prices where stock_id=".$erp->quote($key).
			       " and $type";
			my @row = $erp->selectrow_array($sql);
			$type =~ s/\sand\s/,/g;
			$sql = "insert into";
			$sql = "update" if $row[0] eq $key;
			$sql .= " prices set price=$price,$type,stock_id=".$erp->quote($key);
			$sql .= " where id=".$row[1] if $row[0] eq $key;
			$erp->do($sql);
		}
		$sql = "select products_rate1,products_rate2,products_rate3,".
		       "products_rate4,products_rate5 from products where ".
					 "products_id=$id";
		if ($attr>0) {
		  $sql = "select rate1,rate2,rate3,rate4,rate5 from ".
			       "products_attributes where products_attributes_id=$attr";
		}
		my @rates = $dbh->selectrow_array($sql);
		my $c=0;
		foreach (@rates) {
		  if ($rates[$c]>0) {
			  $factor = $rates[$c];
			  $c++;
			  $sql = "select sales_types_name ".
				       "from sales_types where sales_types_id=$c";
				my ($name) = $dbh->selectrow_array($sql);
				if ($name ne "" && $factor>0) {
				  $sql = "select id from sales_types where sales_type=".
					       $dbh->quote($name);
					my ($id) = $erp->selectrow_array($sql);
					if ($id>0) {
					  $sql = "select id,sales_type_id from prices where ".
						      "sales_type_id=$id and price=0 and stock_id=".
									$erp->quote($key)." and curr_abrev='$curr'";
						my ($price_id,$id2) = $erp->selectrow_array($sql);
						$sql = "insert into";
						$sql = "update" if $id2==$id;
						$sql .= " prices set sales_type_id=$id,factor=$factor,".
						        "stock_id=".$erp->quote($key).",curr_abrev='$curr'";
						$sql .= " where id=$price_id" if $id2==$id;
						$erp->do($sql);
					}
				}
			}
		}
		
		if ($name ne $namee) {
		  $sql = "select id from item_translations where id_stock=".
			       $erp->quote($key)." and areas='en_US'";
			my @rows = $erp->selectrow_array($sql);
			my $sql1 = "insert into";
			$sql1 = "update" if $rows[0]>0;
			$sql = "$sql1 item_translations set ".
			       "description=".$erp->quote($namee).",".
						 "id_stock=".$erp->quote($key).",".
						 "areas='en_US'";
			$sql .= " where id=$rows[0]" if $rows[0]>0;
			$erp->do($sql);
		}
	}
}

