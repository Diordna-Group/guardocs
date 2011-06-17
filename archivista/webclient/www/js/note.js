// note.js: Interface to view/edit document page notes in Achivista db
// Copyright (c) 2008, Archivista GmbH, m. allan noah

// global list of notes
// required to be able to trash them later
var GNL = [];

// shrink wrapper div down to size of image
// required due to lame css centering
// and get list of existing notes from server
function initNotes(url,doc,page,edit,rotate,zoom) {

  // IE6 fix to prevent reload page when showing notes edit
	var x = document.getElementById("nm");
	if (x.style.display=="block") {
	  return;
	}

  var wrapper = $('noteWrapper');
  if(!wrapper) return;

  for(i=0; i<GNL.length; i++){
	  try {
      wrapper.removeChild(GNL[i].element);
		} catch(err){
      //return;
    }
  }
  GNL = [];

  var noteMenu = $('nm');
  if(noteMenu) noteMenu.style.display = 'none';

  var image = $('noteImage');
  if(!image) return;

  wrapper.style.width = image.offsetWidth + 'px';
  wrapper.style.height= image.offsetHeight + 'px';

  var params = {
    go_note_list:1,
    note_doc:doc,
    note_page:page,
    note_editable:edit,
    note_cWidth:parseInt(wrapper.style.width),
    note_cHeight:parseInt(wrapper.style.height),
    note_cRotate:rotate,
    note_cZoom:zoom
  };

  new Ajax.Request(url,
    {
      method:'get',
      parameters: params,
      requestHeaders: {Accept: 'application/json'},
      onSuccess: function(transport){
        //alert(transport.responseText);
        try{
          var json = transport.responseText.evalJSON();
        }
        catch(err){
          //alert(err);
          return;
        }
        for(var i=0; i<json.length; i++){
          insertNote(json[i]);
        }
      }
    }
  );

  return true;
}

// get new default note from server
function newNote(url,doc,page,rotate,zoom) {

  var wrapper = $('noteWrapper');
  if(!wrapper) return;

  var params = {
    go_note_add:1,
    note_doc:doc,
    note_page:page,
    note_editable:1,
    note_cWidth:parseInt(wrapper.style.width),
    note_cHeight:parseInt(wrapper.style.height),
    note_cRotate:rotate,
    note_cZoom:zoom
  };

  new Ajax.Request(url,
    {
      method:'get',
      parameters: params,
      requestHeaders: {Accept: 'application/json'},
      onSuccess: function(transport){
        //alert(transport.responseText);
        try{
          var json = transport.responseText.evalJSON();
        }
        catch(err){
          //alert(err);
          return;
        }
        insertNote(json);
      }
    }
  );

  return false;
}

function insertNote(options) {
  if(!options) return;

  options.resize_cageID = 'noteWrapper';

  var wrapper = $(options.resize_cageID);
  if(!wrapper) return;

  var element = Builder.node('div');
  GNL.push(new Note(element,options));

  $(wrapper).appendChild(element);

  return false;
}

var Note = Class.create(Resizeable,{

  ////////////////////////////////////////////////////////////
  // our overloaded functions

  initialize: function($super,element,userOpts) {

    // set defaults and ingest user options, ours have private prefix
    // others pass thru to Resizeable/Draggable
    var options = Object.extend({
        // these pass thru to parent classes
        resize_cageID : '',
        scroll        : window,

        // need these to talk to server
        note_url   : '',
        note_doc   : 0,
        note_page  : 0,
        note_index : 0,
        note_editable : 0,

        // used to scale user input
        note_cWidth  : 0,
        note_cHeight : 0,
        note_cRotate : 0,
        note_cZoom   : 0,

        // these changed by user resize/drag
        note_bgTop    : 0,
        note_bgLeft   : 0,
        note_bgWidth  : 0,
        note_bgHeight : 0,

        // these changed by context menu
        note_bColor : 0,
        note_bWidth : 0,

        note_bgColor   : 0,
        note_bgOpacity : 0,

        note_fgColor     : 0,
        note_fgFamily    : '',
        note_fgSize      : 0,
        note_fgRotation  : 0,
        note_fgItalic    : 0,
        note_fgBold      : 0,
        note_fgUnderline : 0,
        note_fgText      : ''

    }, userOpts || {});

    // call original function, with updated options
    $super(element,options);

    this.options.cWidth=this.resize.cageDim[0];
    this.options.cHeight=this.resize.cageDim[1];

    // security check. hide menu and handlers if not allowed to edit
    if(this.options.note_editable){
      // store ref to our menu
      this.noteMenu = $('nm');
  
      // list of menu tab names in order
      this.noteMenuTabs = ['Text','Font','Box','Options'];

      // save ref and install handler on note to show/hide menu on right click
      this.noteMenuToggleRef = this.noteMenuToggle.bindAsEventListener(this);
      this.element.observe("contextmenu", this.noteMenuToggleRef);
      this.element.observe("click", this.noteMenuToggleRef);
    
      // save ref and install handler on note to hide menu on left click
      // this ref is also used by close button and doc-wide right click handler
      this.noteMenuHideRef = this.noteMenuHide.bindAsEventListener(this);
    
      // save refs to handlers for menu buttons, tabs and clicks
      // these get applied only when the menu is shown,
      // so that we can share one menu with all notes on the screen
      this.noteMenuBlockRef = this.noteMenuBlock.bindAsEventListener(this);
      this.noteMenuApplyRef = this.noteMenuApply.bindAsEventListener(this);
      this.noteMenuTabRef = this.noteMenuTab.bindAsEventListener(this);
      this.noteMenuDuplicateRef
        = this.noteMenuDuplicate.bindAsEventListener(this);
      this.noteMenuDeleteRef = this.noteMenuDelete.bindAsEventListener(this);
    
      // save ref to handler for left click on entire document
      // gets applied only when menu is visible
      // right click on doc uses existing menu right click handler ref
      this.noteMenuDocLeftHideRef
        = this.noteMenuDocLeftHide.bindAsEventListener(this);
    }

    // apply styles to element
    var style = this.element.style;

    // style the note outer div
    style.top = this.options.note_bgTop + 'px';
    style.left = this.options.note_bgLeft + 'px';
    style.width = this.options.note_bgWidth + 'px';
    style.height = this.options.note_bgHeight + 'px';

    style.position = 'absolute';
    style.overflow = 'hidden';
    style.zIndex = 2;
    style.padding = '0px';
    style.margin = '0px';

    // apply image to element
    var params = {go_note_image:1};
    for (key in this.options){
      if(!/^note_/.test(key)) continue;
      params[key] = this.options[key];
    }
   
    this.noteFg = Builder.node('img',{
      className:"noteForeground",
      src:this.options.note_url +'?'+ Object.toQueryString(params)
    });
    this.element.appendChild(this.noteFg);
  },

  initDrag: function($super,event) {

    // block if editing not allowed
    if(!this.options.note_editable){
      event.stop();
      return false;
    }
  
    // show border
    var style = this.element.style;
    style.borderWidth = '1px';
    style.borderStyle = 'solid';
    style.borderColor = 'black';

    // call superclass
    return $super(event);
  },

  updateDrag: function($super,event,pointer) {
    // block if editing not allowed
    if(!this.options.note_editable){
      event.stop();
      return false;
    }
    return $super(event,pointer);
  },
  
  // grab note size/location after a drag or resize completes
  // update note, scale numeric params up
  endDrag: function($super,event) {

    // block if editing not allowed
    if(!this.options.note_editable){
      event.stop();
      return false;
    }
  
    // call superclass first
    var ret = $super(event);

    var style = this.element.style;
    var diffs = {
      note_bgLeft   : parseInt(style.left),
      note_bgTop    : parseInt(style.top),
      note_bgWidth  : parseInt(style.width),
      note_bgHeight : parseInt(style.height)
    };

    // update object with new style
    this.noteUpdateStyle(diffs);

    // hide border
    style.borderWidth = '0px';

    return ret;
  },

  ////////////////////////////////////////////////////////////
  // our private functions, with 'note' prefix

  // updates note in db by requesting image
  noteUpdateStyle: function(userOpts) {
  
    // merge changes individually, to ignore duplicated events
    var count = 0;
    for (key in userOpts){
      if(this.options[key] == userOpts[key]) continue;
      this.options[key] = userOpts[key];
      count++;
    }
    if(!count) return;

    var params = {go_note_update:1};
    for (key in this.options){
      if(!/^note_/.test(key)) continue;
      params[key] = this.options[key];
    }
 
    this.noteFg.src = this.options.note_url +'?'+ Object.toQueryString(params);
  },

  // change contents of noteMenu to look like this note,
  // swap event handlers and display
  noteMenuToggle: function(event) {
  
    // hide menu if open
    if(!this.noteMenuHide(event)) return false;

    if(event.type == 'click' && !event.ctrlKey) return true;
  
    for (key in this.options){

      var nm_key = key.replace(/^note_/,'nm_');
      if(nm_key == key) continue;

      var obj = $(nm_key);
      if(!obj) continue;

      if(obj.tagName == 'SELECT'){
        obj.selectedIndex = 0;
        for (i = 0; i < obj.options.length; i++) {
          if(obj.options[i].value == this.options[key]){
            obj.selectedIndex = i;
            break;
          }
        }
        obj.stopObserving();
        obj.observe('change',this.noteMenuApplyRef);
      }
  
      else if(obj.tagName == 'INPUT' && obj.getAttribute("type") == 'checkbox'){
        obj.checked = this.options[key];
        obj.stopObserving();
        obj.observe('click',this.noteMenuApplyRef);
      }

      else if(obj.tagName == 'INPUT' && obj.getAttribute("type") == 'text'){
        obj.value = this.options[key];
        obj.stopObserving();
        obj.observe('keyup',this.noteMenuApplyRef);
      }
  
      else if(obj.tagName == 'TEXTAREA'){
        obj.value = this.options[key].replace(/<br>/g,'\r\n');
        obj.stopObserving();
        obj.observe('keyup',this.noteMenuApplyRef);
      }
    }

    // switch to Font tab
    this.noteMenuSwitchTab(this.noteMenuTabs[0]);

    // add tab handler to all tabs
    for (var i = 0; i < this.noteMenuTabs.length; i++) {
      var tab = $($(document).getElementById('nm_tab'+this.noteMenuTabs[i]));
      if(tab){
        tab.stopObserving("click");
        tab.observe('click',this.noteMenuTabRef);
      }
    }

    // add cancel button handler
    var obj = $($(document).getElementById('nm_tabClose'));
    if(obj){
      obj.stopObserving("click");
      obj.observe('click',this.noteMenuHideRef);
    }

    // add duplicate button handler
    var obj = $($(document).getElementById('nm_duplicate'));
    if(obj){
      obj.stopObserving("click");
      obj.observe('click',this.noteMenuDuplicateRef);
    }

    // add delete button handler
    var obj = $($(document).getElementById('nm_delete'));
    if(obj){
      obj.stopObserving("click");
      obj.observe('click',this.noteMenuDeleteRef);
    }

    // setup doc-wide onClick handlers to hide menu
    $(document).stopObserving('click');
    $(document).observe('click',this.noteMenuDocLeftHideRef);
    $(document).stopObserving('contextmenu');
    $(document).observe('contextmenu',this.noteMenuHideRef);

    // protect menu from document-level handlers trying to hide it
    this.noteMenu.stopObserving("click");
    this.noteMenu.observe('click',this.noteMenuBlockRef);
    this.noteMenu.stopObserving("contextmenu");
    this.noteMenu.observe('contextmenu',this.noteMenuBlockRef);

    var style = this.noteMenu.style;
 
    var temp = event.pointer();
    style.left = (temp.x+1) + 'px';
    style.top = (temp.y+1) + 'px';
    style.display = 'block';
    
    event.stop();
    return false;
  },
  
  // hide menu if open
  noteMenuHide: function(event) {
  
    var style = this.noteMenu.style;
    if(style.display == 'block'){
      style.display = 'none';
      event.stop();

      // hide border
      this.element.style.borderWidth = '0px';

      return false;
    }

    return true;
  },

  // cancel and hide menu
  noteMenuDocLeftHide: function(event) {
    // firefox event capture instead of bubble?
    var src = Event.element(event);
    if(src.tagName && (
       src.tagName=='INPUT'
    || src.tagName=='SELECT' 
    || src.tagName=='BUTTON'
    || src.tagName=='TEXTAREA'
      )
    ) return;

    var style = this.noteMenu.style;
    if(style.display == 'block' && !event.isRightClick()){
      style.display = 'none';
      event.stop();

      // hide border
      this.element.style.borderWidth = '0px';

      return false;
    }
  },

  // block clicks
  noteMenuBlock: function(event) {

    // firefox event capture instead of bubble?
    var src = Event.element(event);
    if(src.tagName && (
       src.tagName=='INPUT'
    || src.tagName=='SELECT' 
    || src.tagName=='BUTTON'
    || src.tagName=='TEXTAREA'
      )
    ) return;

    event.stop();
    return false;
  },

  // apply noteMenu changes to object
  noteMenuApply: function(event) {

    var obj = event.element();
    if(!obj) return;

    var val = '';
    if(obj.tagName == 'SELECT'){
      val = obj.options[obj.selectedIndex].value;
    }
    else if(obj.tagName == 'INPUT' && obj.getAttribute("type") == 'checkbox'){
      val = 0;
      if(obj.checked){
        val = 1;
      }
    }
    else if(obj.tagName == 'INPUT' && obj.getAttribute("type") == 'text'){
      val = obj.value;
    }
    else if(obj.tagName == 'TEXTAREA'){
      // strip \r\n from user text
      val = obj.value.replace(/\r?\n/g,'<br>');
    }
    else{
      return;
    }

    var diff = {};
    diff[obj.id.replace(/^nm_/,'note_')] = val;

    // update object with new style
    this.noteUpdateStyle(diff);
  },

  // tab handler
  noteMenuTab: function(event) {

    var obj = event.element();
    if(!obj) return;

    var id = obj.id;
    id = id.replace(/^nm_tab/,'')

    this.noteMenuSwitchTab(id);

    event.stop();
    return false;
  },

  // utility function to switch tabs
  noteMenuSwitchTab: function(id) {

    for (var i = 0; i < this.noteMenuTabs.length; i++) {

      var body = $(document).getElementById('nm_body'+this.noteMenuTabs[i]);
      if(!body) continue;

      var tab = $(document).getElementById('nm_tab'+this.noteMenuTabs[i]);
      if(!tab) continue;

      if(this.noteMenuTabs[i] == id){
        body.style.display = 'block';
        tab.className = 'noteMenuTabCurrent';
      }
      else{
        body.style.display = 'none';
        tab.className = '';
      }
    }
  },

  // duplicate button handler
  noteMenuDuplicate: function(event) {

    var style = this.noteMenu.style;
    if(style.display == 'block'){
      style.display = 'none';
    }

    var params = {go_note_duplicate:1};
    for (key in this.options){
      if(!/^note_/.test(key)) continue;
      params[key] = this.options[key];
    }
    params.note_bgTop += 10;
    params.note_bgLeft += 10;
 
    new Ajax.Request(this.options.note_url,
      {
        method:'post',
        parameters: params,
        requestHeaders: {Accept: 'application/json'},
        onSuccess: function(transport){
          //alert(transport.responseText);
          try{
            var json = transport.responseText.evalJSON();
          }
          catch(err){
            //alert(err);
            return;
          }
          insertNote(json);
        }
      }
    );

    // hide border
    this.element.style.borderWidth = '0px';

    event.stop();
    return false;
  },

  // delete button handler
  noteMenuDelete: function(event) {

    var style = this.noteMenu.style;
    if(style.display == 'block'){
      style.display = 'none';
    }

    var params = {
      go_note_delete:1,
      note_doc:this.options.note_doc,
      note_page:this.options.note_page,
      note_index:this.options.note_index
    };
    new Ajax.Request(this.options.note_url,
      {
        method:'post',
        parameters: params,
        requestHeaders: {Accept: 'application/json'},
        onSuccess: function(transport){
          //alert(transport.responseText);
          try{
            var json = transport.responseText.evalJSON();
          }
          catch(err){
            //alert(err);
            return;
          }
        }
      }
    );

    //FIXME: any doc level handlers in superclasses?
    this.element.stopObserving();

    this.noteFg.remove();
    this.element.remove();

    event.stop();
    return false;
  },

  destroy: function() {
  }

});

