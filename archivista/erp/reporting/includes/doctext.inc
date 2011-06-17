<?php
if (isset($header2type))
{
	$doc_Cust_no = tr("Cust no");
	$doc_Date = tr("Date");
	if ($print_as_quote==1) {
	  $doc_Delivered_To = tr("Delivery To");
	  $doc_Charge_To = tr("Quote To");
	} else {
	  $doc_Delivered_To = tr("Delivered To");
	  $doc_Charge_To = tr("Charge To");
	}
	$doc_Shipping_Company = tr("Shipping Company");
	if ($doctype == 9)
		$doc_Due_Date = tr("Delivery Date");
  else
		$doc_Due_Date = tr("Due Date");
	if ($print_as_quote==1) {
		$doc_Due_Date = tr("Possible Delivery Date");
	}
	$doc_Your_Ref = tr("Your Ref");
	$doc_Our_Ref = tr("Our Ref.");
	$doc_Your_VAT_no = tr("Your VAT no.");
	$doc_Our_VAT_no = tr("Our VAT No.");
	$doc_Payment_Terms = tr("Payment Terms");
	$doc_Our_Order_No = tr("Our Order No");
	$doc_Domicile = tr("Domicile");
	if($doctype == 13) {
	 $doc_Bank_Account = '';
	 $doc_Please_Quote = tr("All amounts stated in");
  } else {
	  $doc_Bank_Account = tr("Bank Account");
	  if ($print_as_quote==1) {
	    $doc_Please_Quote = tr("This quote is 30 days valid. Currency fluctuations to reserve. All amounts stated in");
	  } else {
	    $doc_Please_Quote = tr("Please quote Invoice no. when paying. All amounts stated in");
	  }
	}
	$doc_Address = tr("Address");
	$doc_Phone_Fax_Email = tr("Phone/Fax/Email");
	$doc_Bank = tr("Bank");
	$doc_Bank_Account = tr("Bank Account");
	$doc_Payment_Link = tr("You can pay through");
	if ($doctype == 8 || $doctype == 9 || $doctype == 10 || $doctype == 11 || $doctype == 13)
	{
		if ($doctype == 8)
			$this->title = tr("PURCHASE ORDER");
		else if ($doctype == 13)
			$this->title = tr("DELIVERY NOTE");
		else if ($doctype == 9)
			$this->title = ($print_as_quote==1 ? tr("QUOTE") : tr("SALES ORDER"));
		else if ($doctype == 10)
			$this->title = tr("INVOICE");
		else
			$this->title = tr("CREDIT NOTE");
		if ($doctype == 8)
			$this->headers = array(tr("Item Code"), tr("Item Description"),
				tr("Delivery Date"), tr("Quantity"), 	tr("Unit"), tr("Price"), tr("Total"));
		else
			$this->headers = array(tr("Item Code"), tr("Item Description"),	tr("Quantity"),
				tr("Unit"), tr("Price"), tr("Discount %"), tr("Total"));
	}
	else if ($doctype == 12)
	{
		$this->title = tr("STATEMENT");
		$this->headers = array(tr("Trans Type"), tr("#"), tr("Date"), tr("DueDate"), tr("Charges"),
			tr("Credits"), tr("Allocated"), tr("Outstanding"));
	}
}
if (isset($emailtype))
{
	$doc_Dear_Sirs = tr("Dear Sirs");
	$doc_AttachedFile = tr("Attached you will find ");
	$doc_Kindest_regards = tr("Kindest regards");
	$doc_Payment_Link = tr("You can pay through");
}
if (isset($header2type) || isset($linetype))
{
	$doc_Invoice_no = $doctype==13 ? tr("Delivery Note No.") : tr("Invoice no.");
	$doc_Order_no = tr("Order no.");
	$doc_Delivery_no = tr("Delivery Note No.");
	if ($print_as_quote==1) {
	  $doc_Invoice_no = tr("Quote no.");
	  $doc_Order_no = tr("Quote no.");
	}
}
if (isset($linetype))
{
	if ($doctype == 8 || $doctype == 9 || $doctype == 10 || $doctype == 11 || $doctype == 13)
	{
		$doc_Sub_total = tr("Sub-total");
		$doc_Shipping = tr("Shipping");
		$doc_Included = tr("Included");
		$doc_Amount = tr("Amount");
		$doc_TOTAL_INVOICE = tr("TOTAL INVOICE");
		$doc_TOTAL_ORDER = tr("TOTAL ORDER EX VAT");
		$doc_TOTAL_ORDER_INCL = tr("TOTAL ORDER INCL VAT");
		$doc_TOTAL_PO = tr("TOTAL PO EX VAT");
		$doc_TOTAL_DELIVERY = tr("TOTAL DELIVERY INCL. VAT");
	}
	else if ($doctype == 12)
	{
		$doc_Outstanding = tr("Outstanding Transactions");
		$doc_Current = tr("Current");
		$doc_Total_Balance = tr("Total Balance");
		$doc_Statement = tr("Statement");
		$doc_as_of = tr("as of");
		$doc_Days = tr("Days");
		$doc_Over = tr("Over");
	}
}
?>
