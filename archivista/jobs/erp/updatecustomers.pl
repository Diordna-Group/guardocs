#!/usr/bin/perl

# updatecustomers.pl -> (c) 2010-03-01 by Urs Pfister
# Update customers from from oscommerce to ArchivistaERP

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
		my $sql = "select * from customers";
		my $pres1 = $dbh->selectall_arrayref($sql);
		foreach (@$pres1) {
		  my @customer = @$_;
		  my $custshop = $customer[0];
	    $sql = "select debtor_no,customer_id from debtors_master ".
		         "where customer_id=$custshop";
		  my @row = $erp->selectrow_array($sql);
		  my $custerp = $row[0];
			my $cmd = "insert into";
			$cmd = "update" if $row[1]==$custshop;
		  customer_update($dbh,$erp,$custshop,$custerp,$cmd,\@customer);
		}
	}
}




sub customer_update {
  my ($dbh,$erp,$custshop,$custerp,$cmd,$pcust) = @_;

	my $name = $$pcust[2];
	$name .= " " if $name ne "" && $$pcust[3] ne "";
	$name .= $$pcust[3] if $$pcust[3] ne "";
	my $mail = $$pcust[5];
	my $addrid = $$pcust[6];
	my $phone = $$pcust[7];
	my $fax = $$pcust[8];
	my $sales_type = $$pcust[12];

  my $stype = 1; # default sales types in ArchivistaERP
  if ($sales_type>0) {
    my $sql = "select sales_types_name from sales_types ".
		          "where sales_types_id=$sales_type";
		my ($stname) = $dbh->selectrow_array($sql);
		$sql = "select id from sales_types where sales_type=".$erp->quote($stname);
		($stype) = $erp->selectrow_array($sql);
		$stype = 1 if $stype==0;
	}

	$sql = "select * from address_book where address_book_id=$addrid";
	my @adr = $dbh->selectrow_array($sql);
	my $comp = $adr[3];
	my $branch = $adr[3];
  if ($branch eq "") {
	  $bramch = $adr[4];
	  $branch .= " " if $branch ne "" && $adr[5] ne "";
	  $branch .= $adr[5] if $adr[5] ne "";
	}
	
	my $adr = $adr[6];
	my $city = $adr[9];
	my $plz = $adr[8];
	my $landc = $adr[11];
	my $vat = $adr[13];

	$sql = "select countries_name from countries where countries_id=$landc";
	my ($land) = $dbh->selectrow_array($sql);
	$land = "Switzerland" if $land eq "";
	my $curr = "CHF";
	$curr = "EUR" if $land ne "Switzerland" && $land ne "Schweiz";

  my $langcode = "de_CH";
	if ($land ne "Germany" && $land ne "Deutschland" &&
	    $land ne "Austria" && $land ne "Oesterreich" &&
	    $land ne "Switzerland" && $land ne "Schweiz") {
	  $langcode = "en_US";
	}
	
	my $name2 = $comp;
	$name2 = $name if $name2 eq "";

  my $adresse = "";
	$adresse .= $name . "\n" if $name ne $name2;
	$adresse .= $adr . "\n" if $adr ne "";
	$adresse .= "DE-" if $land eq "Germany" || $land eq "Deutschland";
	$adresse .= $plz . " " . $city . "\n";
	if ($land ne "Switzerland" && 
	    $land ne "Schweiz" &&
	    $land ne "Germany"&&
			$land ne "Deutschland") {
	  $adresse .= $land . "\n";
	}
	$area_code = 3;
	$area_code = 2 if $land eq "Germany" || $land eq "Deutschland";
	$area_code = 1 if $land eq "Switzerland" || $land eq "Schweiz";;
	my $shipvia = 2; # Swisspost GLS
	$shipvia = 1 if $land eq "Switzerland" || $land eq "Schweiz";
	
	my $sql = "$cmd debtors_master set ".
	          "name=".$erp->quote($name2).",".
						"address=".$erp->quote($adresse).",".
						"email=".$erp->quote($mail).",".
						"customer_id=".$custshop.",".
						"discount=0,pymt_discount=0,".
						"sales_type=$stype,".
						"payment_terms=1,credit_status=1,".
						"tax_id=".$erp->quote($vat).",".
						"curr_code=".$erp->quote($curr);
	$sql .= " where debtor_no=$custerp" if $cmd eq "update";
	$erp->do($sql);

	$sql = "select debtor_no from debtors_master where customer_id=$custshop";
	my ($debnr) = $erp->selectrow_array($sql);
	if ($debnr>0) {
	  $sql = "select branch_code from cust_branch where debtor_no=$debnr";
		my ($branch_code) = $erp->selectrow_array($sql);
		my $cmd2 = "insert into";
		$cmd2 = "update" if $branch_code>0;
	  $sql = "$cmd2 cust_branch set ".
		       "debtor_no=".$debnr.",".
					 "br_name=".$erp->quote($branch).",".
					 "email=".$erp->quote($mail).",".
					 "phone=".$erp->quote($phone).",".
					 "salesman=1,default_location='DEF',".
					 "sales_account=1000,".
					 "sales_discount_account=1000,".
					 "receivables_account=1000,".
					 "payment_discount_account=1000,".
					 "default_ship_via=$shipvia,".
					 "area=$area_code,tax_group_id=$area_code,".
					 "lang_code=".$erp->quote($langcode);
		$sql .= " where branch_code=$branch_code" if $cmd2 eq "update";
		$erp->do($sql);
	}
}

