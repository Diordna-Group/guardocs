function price_format(post, num, dec, label) {
	//num = num.toString().replace(/\$|\,/g,'');
	if(isNaN(num))
		num = "0";
	sign = (num == (num = Math.abs(num)));
	if(dec<0) dec = 2;
	decsize = Math.pow(10, dec);
	num = Math.floor(num*decsize+0.50000000001);
	cents = num%decsize;
	num = Math.floor(num/decsize).toString();
	for( i=cents.toString().length; i<dec; i++){
		cents = "0" + cents;
	}
	for (var i = 0; i < Math.floor((num.length-(1+i))/3); i++)
		num = num.substring(0,num.length-(4*i+3))+' '+
			num.substring(num.length-(4*i+3));
	 num = ((sign)?'':'-') + num;
	 if(dec!=0) num = num + ',' + cents;
	if(label)
	    document.getElementById(post).innerHTML = num;
	else
	    document.getElementsByName(post)[0].value = num;
	}
	function get_amount(doc, label) {
	    if(label)
		var val = document.getElementById(doc).innerHTML;
	    else
		var val = document.getElementsByName(doc)[0].value;
		val = val.replace(/\ /g,'');
		val = val.replace(/\,/g,'.');
		return 1*val;
	}
	