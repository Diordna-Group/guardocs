// JavaScript functions for Archivista WebClient 6.0
// (c) 2007 by Archivista GmbH, Urs Pfister


// Load the prototype script.aculo.us javascript classes
if(typeof Effect == 'undefined')
  throw("controls.js requires including script.aculo.us' effects.js library");



// Open new windows
function openWindow(theURL,winName,features) {
  window.open(theURL,winName,features);
}



// Add a value to feldlisten table (ajax)
function addValue(script,field,linked,type) {
  var params = getValues(field,linked,type,"add");
  ajax_request(script,params);
}



// Delete a value from feldlisten table (ajax)
function deleteValue(script,field,linked,type,mess) {
  var answer = confirm(mess);
  if (answer) {
    var params = getValues(field,linked,type,"del");
    ajax_request(script,params);
  }
}



// Compose the values for addValue and deleteValue
function getValues(field1,field2,type,action) {
  var mode = "list_";
  var pfield1 = mode+field1;
  var pval1 = document.forms["avform"][pfield1].value;
  if (type==5) {
    mode = "fld_edit_";
  }
  var pfield2 = mode+field2;
  var pval2 = "";
  if (field2.length>0) {
    pval2 = document.forms["avform"][pfield2].value;
  }
  var params = {list_1_field: field1, list_1_val: pval1,
                list_2_field: field2, list_2_val: pval2,
                list_type: type, go_list: action};
  return params;
}



// say to the user that the ajax_request was successfully
function ajax_ok(t) {
  var message = "";
  if (t.responseText != "0" && t.responseText != "1") {
    message=t.responseText;
  }
  if (message != "") {
    alert(message);
  }
}



// say to the user that the ajax_request was NOT sucessfully
function ajax_error(t) {
  if (t.responseText != "") {
    alert(t.responseText);
  }
}



// process ajax function through prototype library
function ajax_request(script,params,funct) {
  var myAjax = new Ajax.Request(script, 
      {method: 'post', parameters: params, 
       onSuccess: ajax_ok, onFailure: ajax_error});
}



// checkField: During OnBlur we check if we have a double linked field
function checkField(script,field,type,linked) {
  if (type==4 || type==3 || type==6) {
    var mode = "fld_";
    var pfield1 = mode+field;
    var pval1 = document.forms["avform"][pfield1].value;
    var params = {list_1_field: field, list_1_val: pval1,
                list_2_field: linked, list_type: type, go_list: "update"};
    var myAjax = new Ajax.Request(script, 
      {method: 'post', parameters: params, 
       onSuccess: updateField, onFailure: ajax_error});
  }
}



// Send back the hint message
function searchEntries(field,msg) {
  var mode = "fld_";
  var pfield1 = mode+field;
  alert(msg);
  document.forms["avform"][pfield1].focus();
}



// after ajax call from checkField, we update the corresponding field
function updateField(t) {
  var val = t.responseText;
  var vals = val.split("\n");
  var field = vals[0];
  var value = vals[1];
  if (field != '') {
    var mode = "fld_";
    var pfield1 = mode+field;
    document.forms["avform"][pfield1].value = value;
  }
}



// showHide does display the add/remove buttons for feldlisten entries
function showHide(fieldName, fieldObjectType, parentFieldName, visibility) {
  /* get all input fields that start with list, disable list opt. */
  var obj = document.getElementsByTagName("input");
  var max = obj.length;
  for (var c = 0; c < max; c++) {
    var name = obj[c].name;
    var res = name.search(/list.+/);
    if (res == 0) {
      obj[c].style.visibility = "hidden";
    }
  }
  /* show list options for current field */
  obj['list_'+fieldName].style.visibility = visibility;
  obj['list_'+fieldName+'.Button'].style.visibility = visibility;
  if (parentFieldName.length > 0 && 
      fieldObjectType != 5 && fieldObjectType != 7) {
    /* show parent (definition) list opt. if parent field is a
       combined linked field (type 5 + 7) */
    obj['list_'+parentFieldName+'.Button'].style.visibility = "hidden";
    obj['list_'+parentFieldName].style.visibility = visibility;
  }
}



// Change the enctype of the formular
function switchEnctype() {
  var oenctype = document.forms["avform"].enctype;
  if (oenctype == "") {
    // Document Type is empty set it to multipart
    setEnctype('multipart/form-data');
  } else {
    // Document Type is not empty set it to empty
    setEnctype('');
  }
}



// Set enctype
function setEnctype(type) {
  document.forms['avform'].enctype=type;
  document.forms['avform'].encoding=type; // IE hack
}



// Change the owner status combo field if we have publish
function changeExtActions() {
  var formobj = document.forms["avform"];
  var action = $('select_action');
  var selectedIndex = action.selectedIndex;
  var selectedValue = action[selectedIndex].value;
  if (formobj.owner) {
    formobj.owner.disabled = true;
  }
  if (selectedValue == "publish") {
    formobj.owner.disabled = false;
  } else if (selectedValue == "newdoc") {
    var upload = $('adddocs');
    var extact = $('extactions');

    upload.style.display="block";
    extact.style.display="none";

    formobj.enctype="multipart/form-data";
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
    y =  document.documentElement.clientHeight;
  }
  else if (document.body) // other Explorers
  {
    x = document.body.clientWidth;
    y =  document.body.clientHeight;
  }
  document.cookie = "ScreenWidth=" + x;
  document.cookie = "ScreenHeight=" + y;
}



// get the current x screen size (inner values)
function getScreenX() {
  var x;
  if (self.innerHeight) { // all except Explorer
    x = self.innerWidth;
  } else if (document.documentElement &&
             document.documentElement.clientHeight) {
     // Explorer 6 Strict Mode
    x = document.documentElement.clientWidth;
  } else if (document.body) { // other Explorers
    x = document.body.clientWidth;
  }
	return x;
}



// get the current y screen size (inner values)
function getScreenY() {
  var y;
  if (self.innerHeight) { // all except Explorer
    y = self.innerHeight;
  } else if (document.documentElement &&
             document.documentElement.clientHeight) {
     // Explorer 6 Strict Mode
    y =  document.documentElement.clientHeight;
  } else if (document.body) { // other Explorers
    y =  document.body.clientHeight;
  }
	return y;
}



// callback used by Ajax.Autocompleter to append to cgi params
// when a field is linked to another field
function autocompleteLinked(linked,input,params) {
  if (linked) {
    params += "&linked=" + encodeURIComponent(linked);
    params += "&val=" + encodeURIComponent(document.forms["avform"]["fld_"+linked].value);
  }
  return params;
}


// scrolling in image (page view)
function scrollup() {
  var obj = document.getElementById("RecordImage");
  if (obj==null) {
    var objs = document.getElementsByName("go_query");
    var vals = objs.length;
    var obje = document.getElementsByName("go_update");
    var vale = obje.length;
    if (vals == 0) {
      if (vale == 0) {
        document.forms["avform"].key.value="go_docs_prev";
        document.forms["avform"].submit();
        document.forms["avform"].key.value='';
      }
    }
  } else {
    var scpos = obj.scrollTop;
    scpos = scpos - 45;
    obj.scrollTop = scpos;
  }
}

function scrolldown() {
  var obj = document.getElementById("RecordImage");
  if (obj==null) {
    var objs = document.getElementsByName("go_query");
    var vals = objs.length;
    var obje = document.getElementsByName("go_update");
    var vale = obje.length;
    if (vals == 0) {
      if (vale == 0) {
        document.forms["avform"].key.value="go_docs_next";
        document.forms["avform"].submit();
        document.forms["avform"].key.value='';
      }
    }
  } else {
    var scpos = obj.scrollTop;
    scpos = scpos + 45;
    obj.scrollTop = scpos;
  }
}

function scrollleft() {
  var obj = document.getElementById("RecordImage");
  var scpos = obj.scrollLeft;
  scpos = scpos - 45;
  obj.scrollLeft = scpos;
}

function scrollright() {
  var obj = document.getElementById("RecordImage");
  var scpos = obj.scrollLeft;
  scpos = scpos + 45;
  obj.scrollLeft = scpos;
}



// add mouse wheel
function wheel(event){
  var delta = 0;
  var browser = getBrowser();
  event = checkEvent(event,browser);
  if (event.wheelDelta) {
    delta = event.wheelDelta/120;
    if (window.opera) delta = -delta;
  } else if (event.detail) {
    delta = -event.detail/3;
  }
  if (delta > 0) { scrollup(); }
  if (delta < 0) { scrolldown(); }
  return false;
}



// Give back the browser
function isExplorer6or7() {
  var res = 0;
	var pos = 0;
  var browser = getBrowser();
	if (browser=="Explorer") {
	  var version = navigator.appVersion;
    pos = version.search(/MSIE 6./);
    if (pos >= 0) {
		  res=1;
    } else {
      pos = version.search(/MSIE 7./);
      if (pos >= 0) {
		    res=1;
			}
		}
	}
	return res;
}



// listen to some keys (also in page view)
function keyListener(event) {
  var browser = getBrowser();
  event = checkEvent(event,browser);
  if(event.keyCode==38)scrollup();
  if(event.keyCode==40)scrolldown();
  if(event.keyCode==37)scrollleft();
  if(event.keyCode==39)scrollright();
  ret = keyPress(event);
  return ret;
}



// handle difference between explorer/mozilla
function checkEvent(event,browser) {
  if (browser == "Explorer") {
    if(!event)event = window.event;
  } else {
    if(!event)event = Window.Event;
  }
  return event;
}



// handle return and key f5 for mozilla/firefox
function keyReturn(event) {
  var browser = getBrowser();
  event = checkEvent(event,browser);
  var code = event.keyCode;
  if (code==13) {
    var obj = document.getElementsByTagName("go_query");
    var val1 = obj.defaultValue;
    if (val1 != undefined) {
      document.forms["avform"].key.value="go_query";
      document.forms["avform"].submit();
      document.forms["avform"].key.value='';
      return false;
    }
    else if (document.forms["login"]){
      getScreenSize();
      document.forms["login"].submit();
      return false;
    }
    return true;
  } else {
    if (browser == "Netscape") {
      var r = '';
      if (document.getElementById) {
        r += event.ctrlKey ? 'Ctrl-' : '';
        r += event.charCode;
        if (event.keyCode =="116" || r == "Ctrl-114") {
          // event fired by NS when  F5(keycode:116) button is pressed.
          // add your functionality here.
          event.preventDefault();
          event.stopPropagation();
          return false;
        }
        if (event.keyCode =="114" || r == "Ctrl-112") {
          // event fired by NS when  F3(keycode:114) button is pressed.
          // add your functionality here.
          event.preventDefault();
          event.stopPropagation();
          return false;
        }
      }
    }
     return code;
  }
}



// Check what key was pressed
function keyPress(event) {
  var browser = getBrowser();
  event = checkEvent(event,browser);
  var code = event.keyCode;
  var ret = false;
  if (code>=112 && code<=123) { // F1-F12
    if (browser == "Explorer") {
      event.keyCode=0;
    }
    var shift = event.shiftKey;
    var ctrl = event.ctrlKey;
    var alt = event.altKey;
    var key = 0;
    if (code==122){return true} // F11=>fullscreen or not
    key = code-111;
    var shift1='0';
    var alt1='0';
    var ctrl1='0';
    if (shift==1){shift1='1'};
    if (alt==1){alt1='1'};
    if (ctrl==1){ctrl1='1'};
    document.forms["avform"].key.value=key;
    document.forms["avform"].shft.value=shift1;
    document.forms["avform"].alt.value=alt1;
    document.forms["avform"].ctrl.value=ctrl1;
    document.forms["avform"].submit();
    document.forms["avform"].key.value='';
  } else {
    if (code==67 || code==86) {
      var shift = event.shiftKey;
      var ctrl = event.ctrlKey;
      var alt = event.altKey;
      var shift1='0';
      var alt1='0';
      var ctrl1='0';
      var key=code;
      if (shift==1){shift1='1'};
      if (alt==1){alt1='1'};
      if (ctrl==1){ctrl1='1'};
      if (shift1==1 && ctrl1==1) {
        document.forms["avform"].key.value=key;
        document.forms["avform"].shft.value=shift1;
        document.forms["avform"].alt.value=alt1;
        document.forms["avform"].ctrl.value=ctrl1;
        document.forms["avform"].submit();
        document.forms["avform"].key.value='';
      }
    }
    if (code!=13) {
      ret = code;
    }
  }
  return ret;
}



// supress codes so that Explorer does not call internall function keys
function keyNone(event) {
  var browser = getBrowser();
  event = checkEvent(event,browser);
  var code = event.keyCode;
  if (code>=112 && code<=123) { // F1-F12
    if (browser == "Explorer") {
      event.keyCode=0;
    }
    return false;
  } else {
    if (code!=13) {
      return code;
    } else {
      if (browser != "Netscape") {
        keyReturn(event);
      } else {
        return false;
      }
    }
  }
}



// Give back the browser
function getBrowser() {
  var browser = navigator.appName;
  var browser2 = navigator.userAgent;
  var pos = browser2.search(/Chrome/);
  if (browser == "Microsoft Internet Explorer") {
    browser = "Explorer";
  } else {
    if (pos >= 0) {
      browser = "Chrome";
    } else {
      pos = browser2.search(/Safari/);
      if (pos >= 0) {
        browser = "Safari";
      }
    }
  }
  return browser;
}


/*
// add all EventListener to the application
if (window.addEventListener)
window.addEventListener('DOMMouseScroll', wheel, false);
window.onmousewheel = document.onmousewheel = wheel;
window.onkeydown = document.onkeydown = keyNone;
window.onkeypress = document.onkeypress = keyReturn;
window.onkeyup = document.onkeyup = keyListener;
*/

//====================================================================
// utility functions called by main page objects
function makeActive(obj){

  if(obj.className == 'Active') return false;

  var tag = obj.tagName

  elem = obj.previousSibling;
  while (elem){
    if(elem.tagName == tag && elem.className == 'Active') {
      elem.className = 'Deactive';
    }
    elem = elem.previousSibling;
  }

  elem = obj.nextSibling;
  while (elem){
    if(elem.tagName == tag && elem.className == 'Active') {
      elem.className = 'Deactive';
    }
    elem = elem.nextSibling;
  }

  obj.className = 'Active';

  return false;
}

function makeVisible(obj){

  var tag = obj.tagName

  elem = obj.previousSibling;
  while (elem){
    if(elem.tagName == tag) {
      elem.style.display = 'none';
    }
    elem = elem.previousSibling;
  }

  elem = obj.nextSibling;
  while (elem){
    if(elem.tagName == tag) {
      elem.style.display = 'none';
    }
    elem = elem.nextSibling;
  }

  var style = obj.style;
  style.display = 'block';

  return false;
}


														
