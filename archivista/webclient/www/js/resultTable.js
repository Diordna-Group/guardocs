// resultTable.js: dynamically update search result table
// Copyright (c) 2009, Archivista GmbH, m. allan noah

// global pointer to self if caller wants to use it
var GRT = '';

var ResultTable = Class.create({

  /////////////////////////////////////////////////
  // initialize object members
  initialize: function(element,rElement,url,view,tab,index,doc,page,zoom,rotate,download,initmode) {

    this.element = element;
    this.rElement = rElement;
    this.url = url;
    this.view = view;
    this.tab = tab;
		this.init = 1; // wait until first time view mode is called

	  this.curheight = 0;

    if(!this.element || !this.rElement || !this.url.length || 
		   !this.view.length || !this.tab.length) {
      return;
		}

    // initial record to highlight
    this.index = index || 0;
    this.doc = doc || 0;
    this.page = page || 0;

    // eventually wont need to read these from server
    this.zoom = zoom || 0;
    this.rotate = rotate || 0;

    // show download column
    this.download = download || 0;

    // show thumbnail view
    this.initmode = initmode || 0;
    this.photomode = 0;

    // we parse our id, and use it to find other pieces
    this.header = $(this.element.id+'Header');
    this.scroll = $(this.element.id+'Scroll');
    this.body = $(this.element.id+'Body');
    this.table = $(this.element.id+'Table');
    this.thumbs = $(this.element.id+'Thumbs');

    if(!this.header || !this.scroll || !this.body || !this.table || !this.thumbs)
      return;

    this.colw = [];

    // figure out the columns we have to draw
    this.cols = [];

    // add all EventListener to the application
    if (window.addEventListener) {
      window.addEventListener('DOMMouseScroll', this.wheel, false);
    }
    window.onmousewheel = document.onmousewheel = this.wheel;
		var browser = getBrowser();
		if (browser != "Explorer") {
	    window.onresize = this.go_resize;
		}
	 
    if (browser == "Netscape") {
      document.onkeypress = this.keyListener;
		} else {
      document.onkeydown = this.keyNone;
      document.onkeypress = this.keyReturn;
      document.onkeyup = this.keyListener;
		}

    var tds = this.header.getElementsByTagName("td");
    for(var i=0; i<tds.length; i++){
      var id = tds[i].id.replace(/^Results_/,'');
      if(tds[i].id == id)
        continue;

      this.cols.push(id);
    }

    if(!this.cols.length)
      return;

    // stuff for updating rows after scroll/resize
    this.updating = 0;
    this.timer = '';
    this.initialized = 0;
    this.bs = 20;
    this.side = '';

		// get things from server with AJAX:
		// - Total number of rows (totalRows)
    // - A few rows of search results (resultRows)
    // - sorting params (unused?)
    this.totalRows = 0;
    this.resultRows = [];
    this.sortCol = '';
    this.sortDir = '';

    // bind to scroll method to download more rows
    this.updateRef = this.update.bindAsEventListener(this);
    Event.observe(this.scroll, "scroll", this.updateRef);

    // Column resizing stuff
    this.startPtr = [];
    this.resizing = -1;
    this.dir = '';

    this.tds = this.header.getElementsByTagName("td");
    for(var i=0; i<this.tds.length; i++){
      var cell = $(this.tds[i]);
      cell.onmousemove = this.headerCursor.bindAsEventListener(this,cell,i);
      cell.onmousedown = this.headerGrab.bindAsEventListener(this,cell,i);
    }

    this.headerMoveRef = this.headerMove.bindAsEventListener(this);
    this.headerReleaseRef = this.headerRelease.bindAsEventListener(this);

    this.cls = this.header.getElementsByTagName("col");
    this.cls2 = this.table.getElementsByTagName("col");

    // we also own the keyboard handler
    //document.onkeydown = this.keyHandler.bindAsEventListener(this);
    //document.onkeypress = this.keyHandler.bindAsEventListener(this);
    //document.onkeyup = this.keyHandler.bindAsEventListener(this);

    this.slider1 = new Control.Slider('handle1','track1',
      {
        sliderValue:this.zoom,
				minimum: 0,
				maximum: 1,
        onChange: function(v) { GRT.zoomit(v); } 
      }
    );

		if (view=='Page') { // we told it that we want to page view
			this.view="Main";
		  this.go_page();
		} else {
		  this.go_display();
			if (getBrowser() == "Explorer") { this.go_resize(); }
		}

    // we parse our id, and use it to find other pieces
    this.tabs = $(this.rElement.id+'Tabs');
    this.left = $(this.rElement.id+'DetailScroll');
    this.right = $(this.rElement.id+'Image');

    if(!this.tabs || !this.left || !this.right)
      return;

    // reset scroll offset
    this.left.scrollLeft = 0;
    this.left.scrollTop = 0;

    // add handler to the tabs
    var tabs = this.tabs.getElementsByTagName("a");
    for(var i=0; i<tabs.length; i++){
      if(tabs[i].id == 'EditTab') {
        tabs[i].onclick = this.makeActiveTabRec.bind(this,tabs[i].id,'extactions','select_action','');
      } else {
        tabs[i].onclick = this.makeActiveTabRec.bind(this,tabs[i].id,'','','');
			}
    }

		var obj = $(this.tab);
    if(obj) obj.onclick();


  },

  /////////////////////////////////////////////////
  // resize sib uses these to manipulate our height
  getHeight: function(){
    return this.element.offsetHeight;
  },

  setHeight: function(height) {
    var delta = height - this.element.offsetHeight;
    // resize thumbnail window
    if(this.photomode==1) {
		  // nothing to do
    } else {
      // resize table rows
      if (this.scroll.offsetHeight + delta < 12) {
        delta = 12 - this.scroll.offsetHeight;
			}
      if (delta) {
        var htab = parseInt($('htab').getAttribute('values'));
				var hdelta = parseInt(delta);
				htab = htab + delta;
				if (htab < 50) { htab = 50; }
        $('htab').setAttribute('values',htab);
				this.go_display();
			}
      // check for any exposed rows
      this.update();
    }
    return this.element.offsetHeight;
  },

  update: function(event) {
    // handle every type of event which might require loading more rows
    // from the server (resize, scroll, etc)

    if(this.updating) {
      // cant block scroll, but we dont want to setup timer again
      return false;
    }

    if(this.timer) {
      clearTimeout(this.timer);
    }

    // what rows to grab
    var offset;
    var length;

    if (!this.initialized) {
      // big first load
      // we want three blocks
      length = this.bs*3;
      // get almost three blocks before this record
      // and 1 record after this record
      // but dont go negative
      offset = this.index - length + 2;
      if (offset<0) {
			  offset=0;
			}
      this.side = '';
      this.element.style.cursor='wait';
      this.updateRows(offset,length);
    } else {
      // subsequent, smaller load if we are near edge
      var scrollTop = this.scroll.scrollTop;
      var scrollHeight = this.scroll.offsetHeight;
      var tableHeight = this.table.offsetHeight;
      var first = parseInt(this.body.firstChild.id.replace(/^row_/,''));
      var last = parseInt(this.body.lastChild.id.replace(/^row_/,''));

      // at top of rough opening and rows remain, grab previous block
      if(scrollTop == 0 && first != 0){
        offset = first-this.bs;
        length = this.bs;
        if(offset<0){
          length += offset;
          offset = 0;
        }
        this.side = 'top';
      } else if (scrollTop+scrollHeight >= tableHeight && 
			           last != this.totalRows-1) {
        // at bottom of rough opening and rows remain, grab next block
        offset = last+1;
        length = this.bs;
        this.side = 'bottom';
      } else {
        // nothing to do, bail out
        return true;
      }
      this.element.style.cursor='wait';
      this.timer = setTimeout(this.updateRows.bind(this,offset,length),1000);
    }
    return true;
  },

  updateRows: function(offset,length) {
    // call Ajax to add/remove rows from our 'rough opening' 
    // advisory 'lock' the object
    this.updating = 1;
    // use AJAX call to get JSON struct of rows
    new Ajax.Request(this.url, {
        method:'post',
        parameters : {
          go_result_rows:1,
          result_offset:offset,
          result_length:length
        },
        requestHeaders: {Accept: 'application/json'},
        onFailure: this.updateFailure.bind(this),
        onSuccess: this.updateSuccess.bind(this)
      }
    );
    return true;
  },

  // callback used by ajax onFailure
  updateFailure: function(transport){
    return this.updateFinished();
  },

  // callback used by ajax onSuccess
  // add/remove rows from table, update counters
  updateSuccess: function(transport){
    //alert(transport.responseText);
    try {
      var json = transport.responseText.evalJSON();
    } catch(err) {
      //alert(err);
      return this.updateFinished();
    }
    // used if we are prepending
    var ref = this.body.firstChild;
		var nobr0 = "";
		var nobr1 = "";
		if (getBrowser()=="Explorer") {
		  nobr0 = "<nobr>";
			nobr1 = "</nobr>";
		}

    for (var i=0; i<json.resultRows.length; i++) {
      var index = json.resultRows[i].index;
      // copy into cache
      this.resultRows[index] = json.resultRows[i];
      var doc = this.resultRows[index].Laufnummer;
      // new tr element
      var row = document.createElement('tr');
      row.id = 'row_'+index;
      // add the requested cells
      for (var j=0; j<this.cols.length; j++) {
        var cell = document.createElement('td');
        var text = this.resultRows[index][this.cols[j]].toString();
        if(!text.length) {
          text = "\u00a0";
				}
        cell.innerHTML = nobr0 + text + nobr1;
        row.appendChild(cell);
      }
    
      // special case for download links
      if(this.download){
        var cell = document.createElement('td');
        this.updateCell(cell,index);
        row.appendChild(cell);
      }

      // special case for check box
      var cell = document.createElement('td');
      
      if(this.resultRows[index].edit){
        var link = document.createElement('input');
        link.setAttribute('type','checkbox');
        link.setAttribute('name', 'seldocs');
        link.setAttribute('value', doc);
        link.className = 'cb';
        link.style.display='none';
        link.id = 'cb_'+index;
        if(this.resultRows[index].checked){
          link.setAttribute('defaultChecked', 1);
        }
        if(this.tab == 'EditTab'){
          link.style.display='inline';
        }
        cell.appendChild(link);

        var text = document.createTextNode("\u00a0");
        cell.appendChild(text);

        row.appendChild(cell);
      }
 
      // update the class and handlers on the row
      row.className = 'Deactive';
      row.onclick = this.makeActiveRow.bindAsEventListener(this, index);

      if(this.side == 'top'){
        this.body.insertBefore(row,ref);
        this.scroll.scrollTop += row.offsetHeight;
      } else {
        this.body.appendChild(row);
      }
    }

    // update counters
    this.totalRows = json.totalRows;
		if (this.totalRows==0) {
      var stat = $('StatusBar');
      if(stat) stat.innerHTML = json.error;
      this.makeActiveTabRec("SearchTab",'','','');
		}
  
    if(!this.initialized){
      // if this is first screenful, 'click' a row
      var up = $('row_'+this.index);
      if (up) {
        this.makeActiveRow(0,this.index);
			}
      // switch to thumb view if asked
      if(this.initmode) {
        this.go_thumbs();
			}
      this.initialized = 1;
    }
    return this.updateFinished();
  },

  // rewrites the download link cell
  updateCell: function(cell,index) {  
    cell.innerHTML = '';
    var doc = this.resultRows[index].Laufnummer;
    if(this.resultRows[index].pdf.length) {
      var link = document.createElement('a');
      link.setAttribute('href',this.url + '?go_pdf_' + 
			          index + '_' + doc + '&x=internal.pdf');
      link.setAttribute('target','_blank');
      link.appendChild(document.createTextNode(this.resultRows[index].pdf));
      cell.appendChild(link);
    }
    
    if(this.resultRows[index].img.length) {
      link = document.createElement('a');
      link.setAttribute('href',this.url + '?go_image_' + 
			               doc + '_' + this.page + '_1_1_0_1');
      link.setAttribute('target','_blank');
      link.appendChild(document.createTextNode(this.resultRows[index].img));
      cell.appendChild(link);
    }
      
    if(this.resultRows[index].pic.length){
      link = document.createElement('a');
      link.setAttribute('href',this.url + '?go_image_' + 
			             doc + '_' + this.page + '_800_0_0_1');
      link.setAttribute('target','_blank');
      link.appendChild(document.createTextNode(this.resultRows[index].pic));
      cell.appendChild(link);
    }
  
    if(this.resultRows[index].zip.length){
      var link = document.createElement('a');
      link.setAttribute('href',this.url + '?go_zip_' + doc);
      link.setAttribute('target','_blank');
      link.appendChild(document.createTextNode(this.resultRows[index].zip));
      cell.appendChild(link);
    }

    //NOTE: this is input with onclick handler
    if(this.resultRows[index].mail.length){
      var link = document.createElement('input');
      link.setAttribute('type','submit');
      link.setAttribute('name','go_mail_' + doc);
      link.setAttribute('value',this.resultRows[index].mail);
      var mess = this.resultRows[index].mailmsg;
      link.onclick = this.checkMail.bindAsEventListener(this,mess);
      cell.appendChild(link);
    }
    
    if(this.resultRows[index].file.length){
      var link = document.createElement('a');
      link.setAttribute('href',this.url + '?go_file_' + doc);
      link.setAttribute('target','_blank');
      link.appendChild(document.createTextNode(this.resultRows[index].file));
      cell.appendChild(link);
    }
  },

  updateFinished: function(){
    this.updating = 0;
    this.element.style.cursor='auto';
    return false;
  },

  /////////////////////////////////////////////////
  // handlers for clicking tabs and rows
  makeActiveTab: function(id,extid,extsel,selval){
    this.tab = id;
    // special case for edit tab
    var display = "none";
    if(id == 'EditTab'){
      display = "";
    }
 
    var obj2 = $('ResultsHeaderCB');
    if(obj2) obj2.style.display = display;

    // loop thru all the rows, and show/hide each checkbox
    var children = this.body.childNodes;
    for(var i=0; i<children.length; i++){
      var id = parseInt(children[i].id.replace(/^row_/,''));
      var cb = $('cb_' + id);
      if(cb) cb.style.display = display;
    }

    // show/hide all buttons with the right classes set
    var children = $('ButtonBar').select('.Hideable');
    for(var i=0; i<children.length; i++){
      if ( children[i].hasClassName(this.view)
        || children[i].hasClassName(this.view + this.tab)
      ){
        children[i].style.display='';
      }
      else{
        children[i].style.display='none';
      }
    }

    // show/hide the zoom
    // FIXME: stop hardcoding the names
    var ext = $('ZoomWrapper');
    if(ext){
      if(this.view == 'Page')
        ext.style.display='block';
      else
        ext.style.display='none';
    }
    
    // show/hide extended edit controls
    // FIXME: stop hardcoding the names
    var names = ['extactions','extactions2','adddocs'];
    for(var i=0; i<names.length; i++){
      var ext = $(names[i]);
      if(ext){
        if(names[i] == extid)
          ext.style.display='block';
        else
          ext.style.display='none';
      }
    }
    
    if(extsel.length && (obj2 = $(extsel))){
  
      var re = new RegExp(selval,"");
  
      if(obj2.tagName == 'SELECT'){
        obj2.selectedIndex = 0;
        for (i=0; i<obj2.options.length; i++) {
          if(re.match(obj2.options[i].value)){
            obj2.selectedIndex = i;
            break;
          }
        }
      }
    }

    return;
  },

  makeActiveRow: function(event,index){
    // firefox event capture instead of bubble?
    if(event){
      var src = Event.element(event);
      if(src.tagName && (
         src.tagName=='A'
      || src.tagName=='INPUT'
      || src.tagName=='SELECT' 
      || src.tagName=='BUTTON'
      || src.tagName=='TEXTAREA'
        )
      ) return;
    }

    var obj = $('row_'+index);
    if(!obj) return;

    if(obj.className == 'Active') return false;

    makeActive(obj);

    // if in thumbnail mode, update img class too
    var img = $('thumb_'+index);
    if(img) makeActive(img);

    this.index = index;

    // changing doc or initial record after fulltext search,
    // need to change page too
    if(this.doc != this.resultRows[index].Laufnummer || this.page < 1){
      this.doc = this.resultRows[index].Laufnummer;
      this.page = 1;
    }

    // change docs
    this.setDoc(this.index,this.doc,this.page);

    return false;
  },

  setDoc: function(index,doc,page,move){
    this.index = index;
    this.doc = doc;
    this.page = page;

    // update lower part of screen
    this.setDocRec(this.index,this.doc,this.page,move);

    // update all download links with new page number
    if(this.download){
      var children = this.body.childNodes;
      for(var i=0; i<children.length; i++){
        var cell = children[i].lastChild.previousSibling;
				var cell1 = children[i].lastChild.innerHTML;
				if (cell1.search(/cb/)==-1) { // if no checkbox, then use last column
          cell = children[i].lastChild;
				}
        var id = parseInt(children[i].id.replace(/^row_/,''));
        this.updateCell(cell,id);
      }
    }

    // change the status bar
    var stat = $('StatusIndex');
    if(stat) stat.innerHTML = this.index+1;

    stat = $('StatusTotal');
    if(stat) stat.innerHTML = this.totalRows;

    stat = $('StatusDoc');
    if(stat) stat.innerHTML = this.doc;

    stat = $('StatusPage');
    if(stat) stat.innerHTML = this.page;

    stat = $('StatusPages');
    if(stat) stat.innerHTML = this.resultRows[this.index].Seiten;

    // make sure this record is visible on screen
    var theight = 0;
    var bheight = 0;
    var children = this.body.childNodes;
    var scrollTop = this.scroll.scrollTop;
    var scrollHeight = this.scroll.offsetHeight;
  
    for(var i=0; i<children.length; i++){
  
      bheight += children[i].offsetHeight;
      var id = parseInt(children[i].id.replace(/^row_/,''));
  
      // got to the record, move and bail
      if(id == this.index){
  
        var tdelta = scrollTop - theight;
        var bdelta = bheight - (scrollTop+scrollHeight);
  
        if(tdelta > 0){
          this.scroll.scrollTop = scrollTop - tdelta;
        }
        else if(bdelta > 0){
          this.scroll.scrollTop = scrollTop + bdelta;
        }
  
        break;
      }
  
      theight = bheight;
    }

    return;
  },

  ////////////////////////////////////////////////////////
  // random button handlers
  newNote: function(obj){
	 
    if(obj)
      obj.blur();
    // call function in note.js
    newNote(this.url,this.doc,this.page,this.rotate,this.zoom);
    return false;
  },

  go_all: function(obj){
    if(obj)
      obj.blur();

    return false;
  },

  go_zoom: function(obj,val){
    if(obj)
      obj.blur();
    
    if(!val){
      this.zoom=0;
    }
    else if(val == '+'){
      this.zoom += 0.25;
    }
    else if(val == '-'){
      this.zoom -= 0.25;
    }
    else{
      if (val>=0 && val<=1) {
        this.zoom = val;
      }
    }

    if(this.zoom > 1) this.zoom = 1;
    else if(this.zoom < 0) this.zoom = 0;
	
    this.setSliderValue(this.slider1,this.zoom);

    // have to reload the image and initialize the notes
    this.setDocRec(this.index,this.doc,this.page);

    return false;
  },

  go_rotate: function(obj,val){
    if(obj)
      obj.blur();
    
		this.rotate=(this.rotate+val)%360;
    // have to reload the image and initialize the notes
    this.setDocRec(this.index,this.doc,this.page);
    return false;
  },

  go_page: function(obj){
    if(obj)
      obj.blur();

    var handle1 = $('handle1');
    var track1 = $('track1');
		 
    if(this.view == 'Main'){
      this.view = 'Page';
      handle1.style.display='block';
      track1.style.display='block';
		} else {
      this.view = 'Main';
			handle1.style.display='none';
			track1.style.display='none';
		  if (this.photomode==1) {
			  this.go_thumbs(); // go always to table mode
		  }
    }

    // have to re-initialize the notes
    this.setDocRec(this.index,this.doc,this.page,1);

    // now that we have loaded the doc,
    // 'click' the tab to update extedit controls
    // special case for page+edit, different controls
    if(this.view == 'Page' && this.tab == 'EditTab'){
      this.makeActiveTabRec(this.tab,'extactions2','','');
    } else {
      var tab = $(this.tab);
      if(tab) tab.onclick();
    }
		this.go_display();
    return false;
  },

  go_thumbs: function(obj){
    var height = this.element.offsetHeight
    if(this.photomode==1){
      this.photomode = 0;
      this.thumbs.style.display='none';
      this.header.style.display='table';
      this.scroll.style.display='block';
      //this.setHeight(height);
    }
    else{
      var indexes = this.getVisibleIndexes();

      this.photomode = 1;
      this.thumbs.innerHTML = '';
      this.header.style.display='none';
      this.scroll.style.display='none';
      this.thumbs.style.display='block';
      //this.setHeight(height);

      // maximum thumbnail size
      var width = 150;
      var height = 150;
      // loop thru formerly visible rows, and get their images
      for(var i=indexes.start; i<=indexes.stop; i++){
        var img = document.createElement('img');
        var doc = this.resultRows[i].Laufnummer;

        img.id = "thumb_" + i;
        if(i == this.index)
          img.className = 'Active';
        else
          img.className = 'Deactive';
        img.src = this.url + "?go_image_" + doc + '_1_' + width + '_' + height + '__0_';

        //img.onload = function(){initNotes(this.url, doc, 1)}.bindAsEventListener(this);
        img.onclick = this.makeActiveRow.bindAsEventListener(this, i);
        
        this.thumbs.appendChild(img);
      }
    }

    if(obj)
      obj.blur();

    // use AJAX call to update session on server
    new Ajax.Request(this.url,
      {
        method:'post',
        parameters: {
          go_result_thumbs:1,
          result_thumbs:this.photomode
        }
      }
    );

    return false;
  },

  docs_prev: function(obj){
    var height = this.scroll.offsetHeight;
		var plus = parseInt(height/16);
	  var anz = document.getElementById("ResultsBody").childNodes.length;
		if (anz>0) {
      if(this.index-plus > 0){
        this.index-=plus;
		  } else {
		    this.index=0;
		  }
      this.page = 1;
      this.makeActiveRow('',this.index);
    }
    if (obj)
      obj.blur();
    return false;
  },

  docs_next: function(obj){
    var height = this.scroll.offsetHeight;
		var plus = parseInt(height/16);
	  var anz = document.getElementById("ResultsBody").childNodes.length;
		if (anz>0) {
      if(this.index+plus < anz){
        this.index+=plus;
		  } else {
		    this.index=anz-1;
		  }
      this.page = 1;
      this.makeActiveRow('',this.index);
    }
    if (obj)
      obj.blur();
    return false;
  },

  doc_prev: function(obj){
    if(this.index > 0){
      this.index--;
      this.page = 1;
      this.makeActiveRow('',this.index);
    }
    if (obj)
      obj.blur();
    return false;
  },
	
  doc_next: function(obj){
	  var anz = document.getElementById("ResultsBody").childNodes.length;
    if(this.index < anz-1){
      this.index++;
      this.page = 1;
      this.makeActiveRow('',this.index);
    }
    if (obj) 
      obj.blur();
    return false;
  },

  page_first: function(obj){
    if(this.page > 1){
      this.page = 1;
      this.setDoc(this.index,this.doc,this.page,1);
    }
    if (obj)
      obj.blur();
    return false;
  },
	
  page_last: function(obj){
    if(this.page < this.resultRows[this.index].Seiten){
      this.page = this.resultRows[this.index].Seiten;
      this.setDoc(this.index,this.doc,this.page,1);
    }
    if (obj)
      obj.blur();
    return false;
  },

  page_prev: function(obj){
    if(this.page > 1){
      this.page--;
      this.setDoc(this.index,this.doc,this.page,1);
    }
    if (obj)
      obj.blur();
    return false;
  },
	
  page_next: function(obj){
    if(this.page < this.resultRows[this.index].Seiten){
      this.page++;
      this.setDoc(this.index,this.doc,this.page,1);
    }
    if (obj)
      obj.blur();
    return false;
  },

  page_jump: function(obj,id){
    var box = $(id);
    if(box){
      if(parseInt(box.value) > parseInt(this.resultRows[this.index].Seiten)){
        box.value = this.resultRows[this.index].Seiten;
      }
      if(parseInt(box.value) < 1){
        box.value = 1;
      }
      if(this.page != parseInt(box.value)){
        this.page = parseInt(box.value);
        this.setDoc(this.index,this.doc,this.page,1);
      }
    }
    if(obj)
      obj.blur();
    return false;
  },

  ////////////////////////////////////////////////////
  // table header resize code
  headerCursor: function(event,obj,index) {

    if(this.resizing != -1)
      return;

    Event.extend(event);
    var cursor = this.direction(event,obj,index);

    if(cursor.length)
      obj.style.cursor = cursor + '-resize';
    else
      obj.style.cursor = 'auto';
  },

  direction: function(event,obj,index) {
    var offsets = obj.viewportOffset();
    var pointer = [event.clientX, event.clientY];
    var rhw = 10;
    var dir = '';

    if (offsets[0] + obj.offsetWidth - pointer[0] < rhw){
      dir = 'e';
    }
    else if (pointer[0]-offsets[0] < rhw){
      dir = 'w';
    }

    if(index == 0 && dir == 'w')
      dir = '';

    if(index == this.cls.length-1 && dir == 'e')
      dir = '';

    return dir;
  },

  headerGrab: function(event,obj,index) {

    Event.extend(event);
    var temp = event.pointer();
    this.startPtr = [temp.x,temp.y];
    this.resizing = index;
    this.dir = this.direction(event,obj,index);
    if(!this.dir.length) return;

    Event.observe(document, "mousemove", this.headerMoveRef);
    Event.observe(document, "mouseup", this.headerReleaseRef);
    document.body.style.cursor = this.dir + '-resize';

    event.stop();
    return false;
  },

  // document level handlers
  headerMove: function(event) {
    event.stop();
    return false;
  },

  headerRelease: function(event) {
    Event.stopObserving(document, "mousemove", this.headerMoveRef);
    Event.stopObserving(document, "mouseup", this.headerReleaseRef);
    document.body.style.cursor = 'auto';

		var border = 0;
		if (isExplorer6or7()) {
		  border = 4;
		}

    var temp = event.pointer();
    var delta = temp.x - this.startPtr[0];

    var left = this.resizing;

    // grabbed left side
    if(this.dir == 'w'){
      left--;
    }

    // moving left, check left sib first
    if(delta < 0){
      var leftW = parseInt(this.cls[left].width);
      //var leftW2 = parseInt(this.cls2[left].width);
			var leftW2 = leftW;
      if(leftW + delta < 5) delta = 5-leftW;
      if(leftW2 + delta < 5) delta = 5-leftW2;

      if(delta < 0){
        // figure available space
        // use cls2 because header is wider over scrollbar
        var total = 0;
        for(var i=left+1; i<this.cls.length; i++){
          total += parseInt(this.cls2[i].width);
        }
  
        //distribute delta across right sibs
        var actdelta = 0;
        for(var i=left+1; i<this.cls.length; i++){
          var curr = parseInt(this.cls[i].width);
          //var curr2 = parseInt(this.cls2[i].width);
					var curr2 = curr;
          var subdelta = Math.round(delta * curr2 / total - .5);
          this.cls[i].width = curr-subdelta - border;
          //this.cls2[i].width = curr2-subdelta;
          this.cls2[i].width = this.cls[i].width;
          actdelta += subdelta;
        }
  
        this.cls[left].width = leftW+actdelta - border;
        //this.cls2[left].width = leftW2+actdelta;
        this.cls2[left].width = this.cls[left].width;
      }
    }

    // moving right, shrink right sibs first
    else if(delta){

      // figure available space
      // use cls2 because header is wider over scrollbar
      var total = 0;
      for(var i=left+1; i<this.cls.length; i++){
        total += parseInt(this.cls2[i].width) - 1;
      }

      // dont over shrink
      if(delta > total){
        delta = total;
      }

      //distribute delta across right sibs
      if(delta){
        var actdelta = 0;
        for(var i=left+1; i<this.cls.length; i++){
          var curr = parseInt(this.cls[i].width) - 1;
          //var curr2 = parseInt(this.cls2[i].width) - 1;
					var curr2 = curr;
          var subdelta = Math.round(delta * curr2 / total);
          this.cls[i].width = curr+1-subdelta - border;
          //this.cls2[i].width = curr2+1-subdelta;
          this.cls2[i].width = this.cls[i].width;
          actdelta += subdelta;
        }
  
        var leftW = parseInt(this.cls[left].width);
        //var leftW2 = parseInt(this.cls2[left].width);
				var leftW2 = leftW;
        this.cls[left].width = leftW+actdelta - border;
        //this.cls2[left].width = leftW2+actdelta;
        this.cls2[left].width = this.cls[left].width;
      }
    }

    this.resizing = -1;
    event.stop();
    return false;
  },

  // deselect all non-visible rows
  // select or deselect all visible ones
  selectAllDocs: function() {
    var indexes = this.getVisibleIndexes();

    // loop thru all the rows, and show/hide each checkbox
    var children = this.body.childNodes;
    for(var i=0; i<children.length; i++){
      var id = parseInt(children[i].id.replace(/^row_/,''));
      var cb = $('cb_' + id);
      if(cb){
        if ( id>=indexes.start
          && id<=indexes.stop
          && document.forms['avform'].selalldocs.checked ){
            cb.checked = true;
          }
        else
          cb.checked = false;
      }
    }

    /* this does not work with IE6?
    for(i=0; i<form.seldocs.length; i++) {
    }*/
  },

  // util code for determining visible rows
  getVisibleIndexes: function(){
    var children = this.body.childNodes;
    var indexes = this.getVisibleChildren();
    return {
      start : parseInt(children[indexes.start].id.replace(/^row_/,'')),
      stop  : parseInt(children[indexes.stop].id.replace(/^row_/,''))
    };
  },

  getVisibleChildren: function(){
    var height = 0;
    var start = 0;
    var stop = this.totalRows;
    var children = this.body.childNodes;
    var scrollTop = this.scroll.scrollTop;
    var scrollHeight = this.scroll.offsetHeight;

    for(var i=0; i<children.length; i++){
  
      var childHeight = children[i].offsetHeight;
      var partHeight = parseInt(childHeight/2);

      height += childHeight;

      // below the bottom of visible content, bail out
      if(height-partHeight > scrollTop+scrollHeight){
        break;
      }
  
      // above the visible content, skip
      if(height-partHeight < scrollTop){
        start = i+1;
        continue;
      }

      stop = i;
    }
    return {start:start,stop:stop};
  },

  keyHandler: function(event){
    //console.log(event);
    if(event.type == 'keydown'){
      return true;
    }
    else if(event.type == 'keyup'){
      return true;
    }
    // keypress events
    // F2
    if (event.keyCode == 113) {
      if (event.ctrlKey && event.shiftKey) {
        this.page_jump('','page_jump');
      }
    }
  },

  wheel: function(event){
    var delta = 0;
    var browser = getBrowser();
		var tab1 = GRT.tab;
    event = checkEvent(event,browser);
    if (event.wheelDelta) {
      delta = event.wheelDelta/120;
      if (window.opera) delta = -delta;
    } else if (event.detail) {
      delta = -event.detail/3;
    }
    if (delta > 0) { 
		  if (GRT.view == "Page") {
		    scrollup(); 
			} else {
			  if (tab1 == "ViewTab") {
          GRT.docs_prev();
				}
			}
		}
    if (delta < 0) { 
		  if (GRT.view == "Page") {
		    scrolldown(); 
			} else {
			  if (tab1 == "ViewTab") {
			    GRT.docs_next();
				}
			}
		}
    return false;
  },


  keyNone: function(event){
    // supress codes so that Explorer does not call internall function keys
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
          return code;
        }
      }
    }
  },

  keyReturn: function(event) {
    var browser = getBrowser();
    event = checkEvent(event,browser);
    var code = event.keyCode;
    if (code==13) {
			if (document.forms["login"]){
        getScreenSize();
        document.forms["login"].submit();
        return false;
			} else {
        return false;
			}
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
  },

  keyPress: function(event){
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
      GRT.go_action(key,shift1,alt1,ctrl1);
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
          GRT.go_action(key,shift1,alt1,ctrl1);
        }
      }
      if (code!=13) {
        ret = code;
      }
    }
    return ret;
  },

  keyListener: function(event) {
    var browser = getBrowser();
    event = checkEvent(event,browser);
    if (event.keyCode==38) {
		  if (GRT.view == "Page") {
		    scrollup();
			} else {
        GRT.doc_prev();
			}
		}
    if (event.keyCode==40) {
		  if (GRT.view == "Page") {
		    scrolldown();
			} else {
				var field = document.activeElement.id;
				var type = document.activeElement.tagName;
				if (type != "INPUT") {
          GRT.doc_next();
				}
				/* try to catch it also in input fields -- not yet done
				  var search = /(.*?)(_)(.*?)(_)(.*)/;
				  search.exec(field);
					var check = "drp_"+RegExp.$3+RegExp.$4+RegExp.$5;
					var dropdown = document.getElementsByName(check);
					alert(dropdown.name);
					if (!dropdown) {
					  alert("ok");
            GRT.doc_next();
					}
				} else {
					alert("ok");
          GRT.doc_next();
				}
				*/
			}
		}
    if(event.keyCode==37)scrollleft();
    if(event.keyCode==39)scrollright();
    var ret = GRT.keyPress(event);
    return ret;
  },

	go_submit: function(key,shft,alt,ctrl) {
    document.forms["avform"].key.value=key;
    document.forms["avform"].shft.value=shft;
    document.forms["avform"].alt.value=alt;
    document.forms["avform"].ctrl.value=ctrl;
    document.forms["avform"].submit();
    document.forms["avform"].key.value='';
	},

  go_action: function(key,shft,alt,ctrl) {
    if (key==2) { GRT.go_action_f2(key,shft,alt,ctrl); }
    if (key==3) { GRT.go_action_f3(key,shft,alt,ctrl); }
    if (key==4) { GRT.go_action_f4(key,shft,alt,ctrl); }
    if (key==5) { GRT.go_action_f5(key,shft,alt,ctrl); }
    if (key==6) { GRT.go_action_f6(key,shft,alt,ctrl); }
    if (key==7) { GRT.go_action_f7(key,shft,alt,ctrl); }
    if (key==8) { GRT.go_action_f8(key,shft,alt,ctrl); }
    if (key==9) { GRT.go_action_f9(key,shft,alt,ctrl); }
    if (key==12) { GRT.go_action_f12(key,shft,alt,ctrl); }
    if (key==67) { GRT.go_copy(key,shft,alt,ctrl); }
    if (key==86) { GRT.go_pase(key,shft,alt,ctrl); }
  },

  go_action_f2: function(key,shft,alt,ctrl){
    var cmd = "";
    var jokerend = "";
    if (ctrl==1 && shft==1) {
      GRT.page_jump('','page_jump');
    } else {
      if (this.view == 'Main') {
        if (shft==1) {
          this.makeActiveTabRec('EditTab','adddocs','','');
        } else {
          if (ctrl==1 && jokerend=='') { // update mode, so save
            cmd = 'GO_UPDATE';
          } else {
            var ext = document.getElementById("select_action");
						var pos = 0;
            pos = ext.value.search(/^scan/);
						if (pos==0) {
						  GRT.go_submit(key,shft,alt,ctrl);
						} else {
              this.makeActiveTabRec('EditTab','extactions','select_action','scan!');
            }
          }
        }
      } else { // we are in page mode, so zoom in or zoom out
        if (ctrl==1) {
				  GRT.go_zoom(null,"-");
        } else {
          if (shft==1) {
					  GRT.go_zoom(null,"+");
          } else {
					  if (this.zoom==0) {
					    GRT.go_zoom(null,1);
						} else {
						  GRT.go_zoom(null,0);
						}
          }
        }
      }
    }
  },

  go_action_f3: function(key,shft,alt,ctrl) {
    if (shft==0 && ctrl==0) {
      GRT.doc_prev();
    } else {
      if (shft==1 && ctrl==0) {
        GRT.page_prev();
      } else {
        if (shft==0 && ctrl==1) {
          GRT.docs_prev();
        } else {
          if (shft==1 && ctrl==1) {
            GRT.page_first();
          }
        }
      }
    }
    return false;
  },

  go_action_f4: function(key,shft,alt,ctrl) {
    if (shft==0 && ctrl==0) {
      GRT.doc_next();
    } else {
      if (shft==1 && ctrl==0) {
        GRT.page_next();
      } else {
        if (shft==0 && ctrl==1) {
          GRT.docs_next();
        } else {
          if (shft==1 && ctrl==1) {
            GRT.page_last();
          }
        }
      }
    }
    return false;  
  },

  go_action_f5: function(key,shft,alt,ctrl) {
    if (shft==0 && ctrl==0) {
		  var t1 = this.tab;
			if (t1 == "SearchTab") {
        GRT.go_submit(key,shft,alt,ctrl);
			} else {
        this.makeActiveTabRec("SearchTab",'','','');
			}
    } else {
      if (shft==1 && ctrl==0) {
        this.makeActiveTabRec("EditTab",'extactions','select_action','');
      } else {
        if (shft==0 && ctrl==1) {
          this.makeActiveTabRec("ViewTab",'','','');
        } else {
          if (shft==1 && ctrl==1) {
					  GRT.updateDoc();
          }
        }
      }
    }
  },

  go_action_f6: function(key,shft,alt,ctrl) {
    if (shft==0) {
		  GRT.go_submit(key,shft,alt,ctrl);
    }
  },

  go_action_f7: function(key,shft,alt,ctrl) {
    if (shft==1) {
      GRT.go_rotate(null,180);
    } else {
      GRT.go_rotate(null,90);
    }
  },

  go_action_f8: function(key,shft,alt,ctrl) {
    if (shft==1) {
      GRT.go_rotate(null,180);
    } else {
      GRT.go_rotate(null,270);
    }
  },
  
  go_action_f9: function(key,shft,alt,ctrl) {
    if (shft==1 && ctrl==1) {
      //$val{go} = GO_IMAGE;
      //$val{imagedoc}=$val{imgdoc};
      //$val{imagepage}=$val{imgpage};
    } else {
      if (shft==1) {
        // $val{go} = GO_THUMBS;
      } else {
        if (ctrl==1) {
          // $val{go} = GO_PDF;
        } else {
					GRT.go_page();
        }
      }
    }
  },

  go_action_f12: function(key,shft,alt,ctrl) {
	  GRT.go_submit(key,shft,alt,ctrl);
  },

  go_copy: function(key,shft,alt,ctrl) {
	  GRT.go_submit(key,shft,alt,ctrl);
  },

  go_paste: function(key,shft,alt,ctrl) {
    // $val{go} = GO_PASTE; not implemented!!!!!!!
  },

	zoomit: function(zoom) {
	  if (this.sliderupdate==1)
		  return false;

		this.zoom=zoom;
		if (this.zoom<0) 
		  this.zoom=0;
		if (this.zoom>1)
		  this.zoom=1;
    // have to reload the image and initialize the notes
    this.setDocRec(this.index,this.doc,this.page);
	},

  setSliderValue: function(slider1,value) {
		//if (value == '') return;
		this.sliderupdate=1;
		if (isNaN(value)) {
			slider1.setValue(0);
		} else {
			slider1.setValue(value);
		}
		this.sliderupdate=0;
	},

	go_resize: function() {
		try {
		  GRT.go_display();
		} catch(err) {
		}
    var neww = getScreenX()-14;
    getScreenSize();
    var obj = $('ResultsHeader');
    var obj2 = $('ResultsTable');
    var hcols = $('hcols').getAttribute('values'); // all cols till showpdf
    var hall = parseInt($('hall').getAttribute('values')); // screen size
    var hpdf = parseInt($('hpdf').getAttribute('values')); // link (0=dont show)
    var hsel = parseInt($('hsel').getAttribute('values')); // selection column
    var hdiff = parseInt($('hdiff').getAttribute('values')); // diff pixels 
		var diff = neww - hall;
		var border = 0;
		if (isExplorer6or7()) {
		  border = 4;
		}
		var widths = new Array();
		widths = hcols.split(',');
		for(i=0;i<widths.length;i++) {
      widths[i] = parseInt(widths[i]);
		}
		var elements = widths.length;
		var varelements = elements-4;
		var diffa = diff+hdiff;
		var delta = parseInt((diff+hdiff)/varelements);
		var diff2 = diff-(varelements*delta);
		for(i=4;i<widths.length;i++) {
		  widths[i] = widths[i] + delta;
		}
		var hcols2 = "";
		for(i=0;i<widths.length;i++) {
		  if (i>0 && i<widths.length) { hcols2 = hcols2+","; }
			hcols2 = hcols2 + widths[i];
		}
		var left = 0;
		
    cls = obj.getElementsByTagName("col");
    cls2 = obj2.getElementsByTagName("col");
		last = cls.length - 2;
		obj.width = neww;
		obj2.width = neww;
		for(i=0;i<last;i++) {
		  var colw = widths[i];
			if (colw<=0) { colw=15; }
			if (i==4) {
			  var colw1 = colw;
			  colw = colw + diff2;
				if (colw<0) {
				  colw = colw1;
				}
		  }
			var colwa = colw-border;
			if (colwa<=0) { colwa=15; };
			cls[i].left = left;
			cls[i].width = colwa;
			cls2[i].left = left;
			var colw2 = colw-border;
			if (colw2<=0) { colw2=15; };
		  cls2[i].width = colw2;
			left = left + colw - border;
		}
    $('hcols').setAttribute('values',hcols); // all cols till showpdf
    $('hall').setAttribute('values',neww); // screen size
    $('hpdf').setAttribute('values',hpdf); // link (0=dont show)
    $('hsel').setAttribute('values',hsel); // selection column
    $('hdiff').setAttribute('values',diff2); // diff pixels 
    var hcols = $('hcols').getAttribute('values'); // all cols till showpdf
    var hall = parseInt($('hall').getAttribute('values')); // screen size
    var hpdf = parseInt($('hpdf').getAttribute('values')); // link (0=dont show)
    var hsel = parseInt($('hsel').getAttribute('values')); // selection column
    var hdiff = parseInt($('hdiff').getAttribute('values')); // diff pixels 
	},

	postit: function(obj,left,top,width,height,pos,overflow) {
	  if (pos != 'relative') { pos='absolute'; }
    var pos = "position:"+pos+"; left:"+left+"px; top:"+top+"px; " +
		          "width:"+width+"px; height:"+height+"px; display: block;";
		if (overflow == "auto") { pos = pos +" overflow: "+overflow+";" }
		obj.style.cssText = pos;
	},

	go_display: function() {
    var rand = 7;
	  var x = getScreenX()-(2*rand);
		var y = getScreenY()-(2*rand);
		var buttons = $('ButtonBar');
		var results = $('Results');
		var scroll = $('ResultsScroll');
		var record = $('Record');
		var image = $('RecordImage');
		var status = $('StatusBar');
		var detail = $('RecordDetailScroll');
		var thumbs = $('ResultsThumbs');
		var print = $('Printing');
    var htab = parseInt($('htab').getAttribute('values')); // table height
    a = document.cookie;
    var val1 = a.substr(a.search(/(TableHeight=)([0-9])/));
		if (val1) {
		  var val2 = val1.substr(val1.search(/([0-9]+?)/));
		  var val3 = val2.substr(0,val2.search(/;/));
			var val4 = parseInt(val3);
			if (val4 < y && val4 > 0) {
			  htab = val4;
			}
		}
		if (htab < 50) { htab=50; }
		
    var top = rand;
		var left = rand;
		var buttonh = 22;
		var statush = 16;
		var resultsh = htab;
		
		var recordh = y - statush - resultsh - buttonh - (3*rand);
		var recordw = 600;
		var imagew = x -recordw - rand;
		if (imagew < 50) {
		  imagew = 50;
			recordw = x - imagew - rand;
		}
		var imagel = recordw + (2*rand);
		var imageh = recordh;
		var topresults = rand + buttonh + rand;
		var toprecord = topresults + resultsh + rand;
		var topstatus = toprecord + recordh + rand;
    this.postit(buttons,left,top,x,buttonh);
	  if (GRT.view == 'Page') {
		  imageh = resultsh + rand + recordh 
			imagew = x
			imagel = rand;
		  results.style.cssText = "display: none;";
			record.style.cssText = "display: none;";
			this.postit(image,imagel,topresults,imagew,imageh,'absolute','auto');
		} else {
			this.postit(results,left,topresults,x,resultsh);
			var scrollh = resultsh; // dont show sizer (not yet implemented)
			thumbs.style.cssText = "height:"+scrollh+"px;";
			scrollh = resultsh-24;
			scroll.style.cssText = "height:"+scrollh+"px;";
			this.postit(record,left,toprecord,recordw,recordh);
			this.postit(detail,0,0,recordw,recordh-30,'relative');
			imageh = imageh - 20;
			var imaget = toprecord + 20;
			this.postit(image,imagel,imaget,imagew,imageh,'absolute','auto');
		}
		this.setImage();
		if (print) {
		  var plang = 350;
		  var right = x-plang+rand;
			if (right<0) { right=0; }
			var width = x-plang;
			var ptop = topstatus-2;
		  this.postit(status,left,topstatus,width,statush);
		  this.postit(print,right,ptop,plang,statush);
		} else {
		  this.postit(status,left,topstatus,x,statush);
		}
	},

  setDocRec: function(index,doc,page,move){

    this.index = index;
    this.doc = doc;
    this.page = page;

    // use AJAX call to get JSON struct of rows
    var params = {
      go_result_record:1,
      result_index:index,
      result_doc:doc,
      result_page:page,
			result_move:move
    };
   
    new Ajax.Request(this.url,
      {
        method:'post',
        parameters: params,
        requestHeaders: {Accept: 'application/json'},
        onSuccess: this.setDocSuccess.bind(this),
        onFailure: this.setDocFailure.bind(this)
      }
    );
  },

  setPage: function(index,doc,page,ocr){
    this.index = index;
    this.doc = doc;
    this.page = page;
    this.setImage();

		var tab = $("ViewTab");
    if(this.view=="Main" && tab.className == "Active" && ocr==1){
      // use AJAX call to get JSON struct of rows
      var params = {
        go_result_page:1,
        result_index:index,
        result_doc:doc,
        result_page:page
      };
   
      new Ajax.Request(this.url,
        {
          method:'post',
          parameters: params,
          requestHeaders: {Accept: 'application/json'},
          onSuccess: this.setPageSuccess.bind(this),
          onFailure: this.setDocFailure.bind(this)
        }
      );
		}
  },

  setImage: function(){
    var obj = $('noteImage');
    if(!obj) return;

    var wrap = obj.parentNode.parentNode;
    if(!wrap) return;
    // flaming hack- IE6 gives wrong size
    // for newly displayed divs. use content div instead
    if(wrap.id == 'avimage')
      wrap = $('Content');
    if(!wrap) return;

    // allow editing if user is in edit mode on page view
    var edit = 0;
    if(GRT.view == 'Page' && GRT.tab == 'EditTab'){
      edit = 1;
    }

    // dont zoom if user is on main view
    var zoom = GRT.zoom;
    if(GRT.view == 'Main'){
      zoom = 0;
    }

    obj.onload = initNotes.bind(
      this,this.url,this.doc,this.page,edit,GRT.rotate,zoom
    );

    var mode = 0; // decide if we want to load full/reduced image copy
    if(GRT.view == 'Page'){
		  mode = 1;
		}
		if (this.doc>0) {
      obj.src = this.url + "?go_image_" + this.doc + '_' + this.page + '_'
        + wrap.offsetWidth + '_' + wrap.offsetHeight + '__' + mode + '_'
        + GRT.rotate + '_' + zoom;
		} else {
		  // is only a dummy button_pixel.gif image, do not load it
		}
    return true;
  },

  // callback used by ajax onSuccess
  setDocSuccess: function(transport){
    //alert(transport.responseText);
    try{
      var json = transport.responseText.evalJSON();
    }
    catch(err){
      //alert(err);
      return false;
    }

    // setup the 'view' table
		var init = 0;
		var ocr = 0;
		var newpage = this.page;
    for (var name in json){
		  if(name == 'docpage') {
			  // get back current page in doc (from MainResultRecord)
			  var page1 = json[name];
				if (page1>0) {
			    newpage = page1;
				}
			}
			if(name == 'Seiten') {
			  // we have no pages in document, so adjust it to 0
			  var page1 = json[name];
				if (page1 == 0) {
				  newpage = 0;
				}
			}
		  if(name == 'init') init=json[name];
			if(name == 'ocr') ocr=json[name];
      if(name == 'Treffer') continue; // an array
      var obj = $('Detail_view_' + name);
      if(!obj) continue;
      obj.innerHTML = json[name];
    }

    // show/hide Treffer row (fulltext search hits)
    var obj = $('Detail_view_Treffer_row');
    if(obj && !json['Treffer'].length){
      obj.style.display='none';
    }
    else if(obj){
      obj.style.display='';
    }

    // draw Treffer contents
    var obj = $('Detail_view_Treffer');
    if(obj){
      obj.innerHTML='';
      for(i=0; i<json['Treffer'].length; i++){
			  if (i==0 && init==1) {
				  newpage = json['Treffer'][i];
				}
        var link = document.createElement('a');
        link.onclick=this.setPage.bind(this,this.index,this.doc,json['Treffer'][i],1);
        link.appendChild(document.createTextNode(json['Treffer'][i]));
        link.setAttribute('href','#');
        link.style.marginRight='6px';
        link.style.padding='2px';
        if(this.page == json['Treffer'][i]){
          link.style.background = '#efefef';
          link.style.border = '1px solid #aaaaaa';
        }
        obj.appendChild(link);
				if ((i % 15)==0 && i>0) {
				  var br = document.createElement('br')
					obj.appendChild(br);
				}
      }
    }

    // user does not have edit rights
    // move off tab, and hide it
    if(!json.edit){
      var tab = $("EditTab");
      if(tab.className == "Active"){
        this.makeActiveTabRec("ViewTab",'','','');
      }
      tab.style.display='none';
    }

    // user does have edit rights
    // show tab, and fill in details
    else{

      var tab = $("EditTab");
      tab.style.display='inline';

      for (var name in json){
        var obj = $('Detail_edit_' + name);
        if(!obj) continue;
  
        if(obj.tagName == 'SELECT'){
          obj.selectedIndex = 0;
          for (i = 0; i < obj.options.length; i++) {
            if(obj.options[i].value == json[name]){
              obj.selectedIndex = i;
              break;
            }
          }
        }
    
        else if(obj.tagName == 'INPUT' && obj.getAttribute("type") == 'checkbox'){
          obj.checked = json[name];
        }
  
        else if(obj.tagName == 'INPUT' && obj.getAttribute("type") == 'text'){
          obj.value = json[name];
        }
    
        else if(obj.tagName == 'TEXTAREA'){
          //obj.value = json[name].replace(/<br>/g,'\r\n');
          obj.value = json[name];
        }
  
        else {
          obj.innerHTML = json[name];
        }
      }
    }

		this.checkEditTabInputVals();
    this.page=newpage;
    this.setPage(this.index,this.doc,this.page,ocr);
    return;
  },

  // callback used by ajax onFailure
  setDocFailure: function(transport){
    return false;
  },

  // callback used by ajax onSuccess
  setPageSuccess: function(transport){
    //alert(transport.responseText);
    try{
      var json = transport.responseText.evalJSON();
    }
    catch(err){
      //alert(err);
      return false;
    }
    // show fulltext
    for (var name in json){
      var obj = $('Detail_view_' + name);
      if(!obj) continue;
      obj.innerHTML = json[name];
    }
    var stat = $('StatusPage');
    if(stat) stat.innerHTML = this.page;
    return;
  },

  // used to switch between view/search/edit tabs
  makeActiveTabRec: function(id,extid,extsel,selval){

    var obj = $(id);
    if(!obj) return;

    this.tab = id;

    // remove dotted outline
    obj.blur();
  
    // use AJAX call to update session on server
    new Ajax.Request(this.url,
      {
        method:'post',
        parameters: {
          go_result_tab:1,
          result_tab:id
        }
      }
    );

    // make colored bar
    var wrap = $('RecordDetailScroll');
    if(!wrap) return false;
    //alert(wrap.className);
    wrap.className = id.replace(/Tab$/,'');
    //wrap.setAttribute('class', id.replace(/Tab$/,''));
    //wrap.setAttribute('className', id.replace(/Tab$/,''));
    //alert(wrap.className);
  
    // find table
    wrap = $(id + 'le');
    if(!wrap) return false;
  
    makeActive(obj);
    makeVisible(wrap);
 
    this.makeActiveTab(this.tab,extid,extsel,selval);

		if (this.tab != "ViewTab") {
		  this.init=1; // set back fulltext to initialize (loading page text)
		}
		
		if (this.tab == "ViewTab" && this.init==1) {
		  // call fulltext if we switch to ViewTab
      this.setDocRec(this.index,this.doc,this.page);
			this.init=0; // don't call it again
		}
		this.checkEditTabInputVals();
		if (this.tab == "EditTab") {
      if (this.view == "Main") {
			  if (document.avform.fld_edit_Datum.visible==1) {
			    document.avform.fld_edit_Datum.focus();
				}
			}
		}
		if (this.tab == "SearchTab") {
		  if (this.view  == "Main") {
			  if (document.avform.fld_search_Datum.visible==1) {
			    document.avform.fld_search_Datum.focus();
				}
			}
		}
    return false;
  },

  getHeightRec: function(){
    return this.rElement.offsetHeight;
  },

  setHeightRec: function(height){
    var delta = height - this.rElement.offsetHeight;

    if(this.left.offsetHeight + delta < 0)
      delta = this.left.offsetHeight * -1;
    if(this.right.offsetHeight + delta < 0)
      delta = this.right.offsetHeight * -1;

    this.left.style.height = this.left.offsetHeight + delta + 'px';
    this.right.style.height = this.right.offsetHeight + delta + 'px';
    this.setImage();
    return this.rElement.offsetHeight;
  },

	checkMail: function(event,mess){
    return confirm(mess);
	},

	getSeldocs: function(){
	  var seldocs = "";
    var children = this.body.childNodes;
    for(var i=0; i<children.length; i++) {
      var id = parseInt(children[i].id.replace(/^row_/,''));
      var cb = $('cb_' + id);
      if (cb) {
	      if (cb.checked == true) {
			    if (seldocs != "") {
				    seldocs = seldocs + ",";
				  }
	        seldocs = seldocs + cb.value;
			  }
		  }
    }
		return seldocs;
	},

  // Get a confirmation if we call edit functions 
  checkConfirm: function(mainview,mess1,mess2,mess3){
    var nrOfDocsSel = 0;
    var formObj = document.forms["avform"];
    if (mainview==0 || mainview=='') {
      if (this.blur)
        this.blur();
      return confirm(mess1);
    } else {
      var selectedIndex = formObj.action.selectedIndex;
      var selectedValue = formObj.action[selectedIndex].value;
			if (selectedValue == '') {
        selectedIndex = formObj.action2.selectedIndex;
        selectedValue = formObj.action2[selectedIndex].value;
			}
      // loop thru all the rows, and show/hide each checkbox
      var children = this.body.childNodes;
			var anz = children.length;
      for(var i=0; i<anz; i++){
        var id = parseInt(children[i].id.replace(/^row_/,''));
        var cb = $('cb_' + id);
        if (cb) {
				  if (cb.checked==true) {
            nrOfDocsSel++;
					}
				}
			}
      if (nrOfDocsSel == 0 &&
         (selectedValue == "delete" ||
          selectedValue == "publish" ||
          selectedValue == "unpublish")) {
        alert(mess2);
        return false;
      } else {
        if (selectedValue == "export") {
          var dbname;
          dbname = prompt(mess3,"");
          if (dbname != "") {
            formObj.exportdb.value = dbname;
            return true;
          } else {
            return false;
          }
        } else {
          if (confirm(mess1)) {
					  if (selectedValue == "savepage") {
						  this.rotate = 0;
						} else {
						  if (selectedValue == "createpdfs") {
							  var seldocs = this.getSeldocs();
						    var url = window.location.href;
								url = url + "?go_createpdfs&pdfdocs="+seldocs;
							  var title = "ArchivistaBox";
								var opt = "";
                window.open(url,title,opt);
						    return false;
						  } else {
                return true;
							}
						}
          } else {
						return false;
          }
        }
      }
		}
  },


  updateDoc: function(){

	  var edit = $("EditTable");
    var flds = edit.getElementsByTagName("input");
    var params = {
      go_result_update:1,
      result_index:this.index,
      result_doc:this.doc,
      result_page:this.page,
			result_utf8:1
    };

    for(var i=0; i<flds.length; i++){
		  var fld = flds[i].id;
			if (fld != '') {
			  params[flds[i].name] = flds[i].value;
			}
    }

    var flds = edit.getElementsByTagName("textarea");
    for(var i=0; i<flds.length; i++){
		  var fld = flds[i].id;
			if (fld != '') {
			  params[flds[i].name] = flds[i].value;
			}
    }

    new Ajax.Request(this.url,
      {
        method:'post',
        parameters: params,
        requestHeaders: {Accept: 'application/json'},
        onFailure: this.updateFailure.bind(this),
        onSuccess: this.updateDocSuccess.bind(this)
      }
    );
  },

  updateDocSuccess: function(transport) {
    //alert(transport.responseText);
    try {
      var json = transport.responseText.evalJSON();
    } catch(err) {
      //alert(err);
      return this.updateFinished();
    }
    var id = 'row_'+this.index; // get back the current row in table
		var row = document.getElementById(id);
    var children = row.childNodes;
		for(var i=0; i<this.cols.length; i++){ // pass all fld columns
		  var fld = this.cols[i];
      for (var name in json){ // have a look for the field 
			  if (fld == name) { // field found, so get value
          var value = json[name];
          if(!value.length) {
            value = "\u00a0";
				  }
					this.resultRows[this.index][i] = value; // finally change it
					children[i].innerHTML = "<nobr>"+value+"</nobr>";
				}
			}
		}
    this.setDoc(this.index,this.doc,this.page); // actualizise record info
	},

  checkEditTabInputVals: function() {
		if (this.tab == "EditTab") {
	    var edit = $("EditTable");
      var flds = edit.getElementsByTagName("input");
      for(var i=0; i<flds.length; i++){
		    var fld = flds[i].id;
			  if (fld != '') {
			    var value = flds[i].value;
					if (value != "") {
					  value = value.replace(/&amp;/g, "&");
					  value = value.replace(/&gt;/g,"<");
					  value = value.replace(/&lt;/g,">");
					  value = value.replace(/&quot;/g,'"');
					  flds[i].value = value;
					}
			  }
			}
    }
	}

});
