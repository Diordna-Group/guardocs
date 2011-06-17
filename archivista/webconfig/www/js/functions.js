
// Check if we delete records

function checkConfirm(mess1,mess2,count) {
  var answer;
  var nrOfDocsSel = 0;
	var attr1 = "main_ext";
	var val1 = document.forms["avform"]["mainext"].value;
	if (val1 == "go_del_string") {
    if (count>1) {
      for (i = 0; i < count; i++) {
		    if (document.forms["avform"].seldoc[i].checked) {
  		    nrOfDocsSel++;
	      }
	    }
    } else {
	    if (count == 1) {
		    if (document.forms["avform"].seldoc.checked) {
			    nrOfDocsSel++;
		    }
		  }
	  }
    if (nrOfDocsSel == 0) {
		  alert(mess2);
		  return false;
	  } else {
		  if (confirm(mess1)) {
		    return true;
		  } else {
	  	  document.forms["avform"].selalldocs.checked = false;
				if (count>1) {
			    for(i = 0; i < count; i++) {
				    document.forms["avform"].seldoc[i].checked = false;
			    }
				} else {
				  if (count == 1) {
		        document.forms["avform"].seldoc.checked = false;
				  }
				}
		    document.forms["avform"].go_mainext.value="Cancel";
			  return false;
		  }
    }
  }
}



// get the current screen size (inner values)

function getScreenSize() {
  var x,y;
  if (self.innerHeight) // all except Explorer
  {
    x = self.innerWidth;
		y = self.innerHeight;
	}
	else if (document.documentElement &&
					 document.documentElement.clientHeight)
     // Explorer 6 Strict Mode
	{
    x = document.documentElement.clientWidth;
    y =	document.documentElement.clientHeight;
	}
	else if (document.body) // other Explorers
	{
    x = document.body.clientWidth;
    y =	document.body.clientHeight;
	}
	document.cookie = "ScreenWidth=" + x;
	document.cookie = "ScreenHeight=" + y;
}



// activate all rows in table   

function activateAllDocSel(count) {
	if (count == 1) {
  	if (document.forms["avform"].selalldocs.checked) {
    	document.forms["avform"].seldoc.checked = true;
		} else {
			document.forms["avform"].seldoc.checked = false;
		}
	} else {
		for(i = 0; i < count; i++) {
			if (document.forms["avform"].selalldocs.checked) {
				document.forms["avform"].seldoc[i].checked = true;
			} else {
				document.forms["avform"].seldoc[i].checked = false;
			}
		}
	}
}




// Changes RN

/* 
 * =TimeZone()
 *
 * Set the specific zone Dropdown Menu to visible.
 * Other are set unvisible.
 */

function TimeZone() {
   var area = document.getElementById('areas');
    var selected = area.value;
   var zones = new Array ('Africa','America',
                       'Antarctica','Arctic','Asia',
                       'Atlantic','Australia','Europe',
                       'Indian','Pacific');
    for (var a=0;a<zones.length;a++) {
      var z = document.getElementById('zone_'+zones[a]);
      if (zones[a] != selected) {
				 z.className="hidden_zone";
      } else {
				 z.className="";
     }
  }
}


function HIDE_IP() {
  var dhcp = document.getElementById('net_dhcp');
  var ip = document.getElementById('ip_row');
  var ns = document.getElementById('ns_row');
  var gw = document.getElementById('gw_row');
  var gwon = document.getElementById('gwon_row');
  var nson = document.getElementById('nson_row');
	var toset = [ ip,ns,gw,gwon,nson ]
  for (var a=0;a<toset.length;a++) {
	  var css_class="";
	  if (dhcp.checked) {
		  css_class='hidden_ip';
		}
		toset[a].className=css_class;
	}
}



