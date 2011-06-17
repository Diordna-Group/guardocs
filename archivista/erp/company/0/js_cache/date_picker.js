
function positionInfo(object) {
  var p_elm = object;
  this.getElementLeft = getElementLeft;
  function getElementLeft() {
    var x = 0;
    var elm;
    if(typeof(p_elm) == 'object'){
      elm = p_elm;
    } else {
      elm = document.getElementById(p_elm);
    }
    while (elm != null) {
      x+= elm.offsetLeft;
      elm = elm.offsetParent;
    }
    return parseInt(x);
  }
  this.getElementWidth = getElementWidth;
  function getElementWidth(){
    var elm;
    if(typeof(p_elm) == 'object'){
      elm = p_elm;
    } else {
      elm = document.getElementById(p_elm);
    }
    return parseInt(elm.offsetWidth);
  }
  this.getElementRight = getElementRight;
  function getElementRight(){
    return getElementLeft(p_elm) + getElementWidth(p_elm);
  }
  this.getElementTop = getElementTop;
  function getElementTop() {
    var y = 0;
    var elm;
    if(typeof(p_elm) == 'object'){
      elm = p_elm;
    } else {
      elm = document.getElementById(p_elm);
    }
    while (elm != null) {
      y+= elm.offsetTop;
      elm = elm.offsetParent;
    }
    return parseInt(y);
  }
  this.getElementHeight = getElementHeight;
  function getElementHeight(){
    var elm;
    if(typeof(p_elm) == 'object'){
      elm = p_elm;
    } else {
      elm = document.getElementById(p_elm);
    }
    return parseInt(elm.offsetHeight);
  }
  this.getElementBottom = getElementBottom;
  function getElementBottom(){
    return getElementTop(p_elm) + getElementHeight(p_elm);
  }
}
function CC() {
  var calendarId = 'CC';
  var currentYear = 0;
  var currentMonth = 0;
  var currentDay = 0;
  var selectedYear = 0;
  var selectedMonth = 0;
  var selectedDay = 0;
  var months = ['Januar','Februar','März','April','Mai','Juni','Juli','August','September','Oktober','November','Dezember'];
  var wdays = ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'];
  var dateField = null;
  function getProperty(p_property){
    var p_elm = calendarId;
    var elm = null;
    if(typeof(p_elm) == 'object'){
      elm = p_elm;
    } else {
      elm = document.getElementById(p_elm);
    }
    if (elm != null){
      if(elm.style){
        elm = elm.style;
        if(elm[p_property]){
          return elm[p_property];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
  }
  function setElementProperty(p_property, p_value, p_elmId){
    var p_elm = p_elmId;
    var elm = null;
    if(typeof(p_elm) == 'object'){
      elm = p_elm;
    } else {
      elm = document.getElementById(p_elm);
    }
    if((elm != null) && (elm.style != null)){
      elm = elm.style;
      elm[ p_property ] = p_value;
    }
  }
  function setProperty(p_property, p_value) {
    setElementProperty(p_property, p_value, calendarId);
  }
  function getDaysInMonth(year, month) {

    return [31,((!(year % 4 ) && ( (year % 100 ) || !( year % 400 ) ))?29:28),31,30,31,30,31,31,30,31,30,31][month-1];

  }
  function getDayOfWeek(year, month, day) {

    var date = new Date(year,month-1,day)
    return date.getDay();

  }
  this.clearDate = clearDate;
  function clearDate() {
    dateField.value = '';
    hide();
  }
  this.setDate = setDate;
  function setDate(year, month, day) {
    if (dateField) {
      if (month < 10) {month = '0' + month;}
      if (day < 10) {day = '0' + day;}

      var dateString = day+'.'+month+'.'+year;

      dateField.value = dateString;
      hide();
    }
    return;
  }
  this.changeMonth = changeMonth;
  function changeMonth(change) {
    currentMonth += change;
    currentDay = 0;
    if(currentMonth > 12) {
      currentMonth = 1;
      currentYear++;
    } else if(currentMonth < 1) {
      currentMonth = 12;
      currentYear--;
    }
    calendar = document.getElementById(calendarId);
    calendar.innerHTML = calendarDrawTable();
  }
  this.changeYear = changeYear;
  function changeYear(change) {
    currentYear += change;
    currentDay = 0;
    calendar = document.getElementById(calendarId);
    calendar.innerHTML = calendarDrawTable();
  }
  function getCurrentYear() {
    var year = new Date().getYear();
    if(year < 1900) year += 1900;
    return year;
  }
  function getCurrentMonth() {
    return new Date().getMonth() + 1;
  }
  function getCurrentDay() {
    return new Date().getDate();
  }
  function calendarDrawTable() {
    var dayOfMonth = 1;
    var wstart = 1;
    var validDay = 0;
    var startDayOfWeek = getDayOfWeek(currentYear, currentMonth, dayOfMonth);
    var daysInMonth = getDaysInMonth(currentYear, currentMonth);
    var css_class = null; //CSS class for each day
    var table = "<table cellspacing='0' cellpadding='0' border='0'>";
    table += "<tr class='header'>";
    table += "  <td colspan='2' class='previous'><a href='javascript:changeCCMonth(-1);'>&lt;</a><br><a href='javascript:changeCCYear(-1);'>&laquo;</a></td>";
    table += "  <td colspan='3' class='title'>" + months[currentMonth-1] + "<br>" + currentYear + "</td>";
    table += "  <td colspan='2' class='next'><a href='javascript:changeCCMonth(1);'>&gt;</a><br><a href='javascript:changeCCYear(1);'>&raquo;</a></td>";
    table += "</tr>";
    table += "<tr>";
    for (var n=0; n<7; n++)
    	table += "<th>" + wdays[(wstart+n)%7]+"</th>";
    table += "</tr>";
    for(var week=0; week < 6; week++) {
      table += "<tr>";
      for(var n=0; n < 7; n++) {
        dayOfWeek = (wstart+n)%7;
        if(week == 0 && startDayOfWeek == dayOfWeek) {
          validDay = 1;
        } else if (validDay == 1 && dayOfMonth > daysInMonth) {
          validDay = 0;
        }
        if(validDay) {
          if (dayOfMonth == selectedDay && currentYear == selectedYear && currentMonth == selectedMonth) {
            css_class = 'current';

          } else if (dayOfWeek == 0 || dayOfWeek == 6) {

            css_class = 'weekend';
          } else {
            css_class = 'weekday';
          }
          table += "<td><a class='"+css_class+"' href=\"javascript:setCCDate("+currentYear+","+currentMonth+","+dayOfMonth+")\">"+dayOfMonth+"</a></td>";
          dayOfMonth++;
        } else {
          table += "<td class='empty'>&nbsp;</td>";
        }
      }
      table += "</tr>";
    }
    table += "<tr class='header'><th colspan='7' style='padding: 3px;'><a href='javascript:hideCC();'>Zurück</a></td></tr>";
    table += "</table>";
    return table;
  }
  this.show = show;
  function show(field) {
    can_hide = 0;
    if (dateField == field) {
      return;
    } else {
      dateField = field;
    }
    if(dateField) {
      try {
        var dateString = new String(dateField.value);
        var dateParts = dateString.split('.');

        selectedDay = parseInt(dateParts[0],10);
        selectedMonth = parseInt(dateParts[1],10);
        selectedYear = parseInt(dateParts[2],10);

      } catch(e) {}
    }
    if (!(selectedYear && selectedMonth && selectedDay)) {

      selectedMonth = getCurrentMonth();
      selectedDay = getCurrentDay();
      selectedYear = getCurrentYear();

    }
    currentMonth = selectedMonth;
    currentDay = selectedDay;
    currentYear = selectedYear;
    if(document.getElementById){
      calendar = document.getElementById(calendarId);
      calendar.innerHTML = calendarDrawTable(currentYear, currentMonth);
      setProperty('display', 'block');
      var fieldPos = new positionInfo(dateField);
      var calendarPos = new positionInfo(calendarId);
      var x = fieldPos.getElementLeft();
      var y = fieldPos.getElementBottom();
      setProperty('left', x + 'px');
      setProperty('top', y + 'px');
      if (document.all) {
        setElementProperty('display', 'block', 'CCIframe');
        setElementProperty('left', x + 'px', 'CCIframe');
        setElementProperty('top', y + 'px', 'CCIframe');
        setElementProperty('width', calendarPos.getElementWidth() + 'px', 'CCIframe');
        setElementProperty('height', calendarPos.getElementHeight() + 'px', 'CCIframe');
      }
    }
  }
  this.hide = hide;
  function hide() {
    if(dateField) {
      setProperty('display', 'none');
      setElementProperty('display', 'none', 'CCIframe');
      dateField = null;
    }
  }
  this.visible = visible;
  function visible() {
    return dateField
  }
  this.can_hide = can_hide;
  var can_hide = 0;
}
var cC = new CC();
function date_picker(textField) {
  cC.show(textField);
}
function hideCC() {
  if (cC.visible()) {
    cC.hide();
  }
}
function setCCDate(year, month, day) {
  cC.setDate(year, month, day);
}
function changeCCYear(change) {
  cC.changeYear(change);
}
function changeCCMonth(change) {
  cC.changeMonth(change);
}
document.write("<iframe id='CCIframe' src='javascript:false;' frameBorder='0' scrolling='no'></iframe>");
document.write("<div id='CC'></div>");