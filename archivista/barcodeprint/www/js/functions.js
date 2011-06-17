function ac()
{
  var q = document.getElementById("bcFormField0").value;
  var len = q.length;
  if (len >= 8) { 
    document.forms["bcprint"].submit();
  }
}

function selectItem()
{
  var item = document.getElementsByName("aclist")[0].value;
  
  // Get all fields values
  var fieldValues = item.split("%20");
  
  for (i = 0; i < fieldValues.length; i++) {
    document.getElementById("bcFormField"+i).value = fieldValues[i];
  }
  
  document.getElementsByTagName("div")['ac'].style.visibility = 'hidden';
}

function resetFields()
{
  var nrOfInputFields = document.getElementsByName("nrOfInputFields")[0].value;

  for (i = 0; i < nrOfInputFields; i++) {
    document.getElementById("bcFormField"+i).value = "";
  }
}

function setSelect()
{
  document.getElementById("bcFormField0").select();
}

function setClear()
{
  clear = false;
}

function setFocus()
{
  document.getElementById("bcFormField0").focus();
}
