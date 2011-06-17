// resizeSibs.js: use 'handle' to resize sibling divs
// Copyright (c) 2009, Archivista GmbH, m. allan noah

// global pointer to self if caller wants to use it
var GRS = '';

var ResizeSibs = Class.create({

  // our overloaded functions
  initialize: function(element,tld,fixed) {

    this.element = element;
    this.tld = tld;
	  // the fixed divs
    this.fixed = [];
    for (var i=0; i<fixed.length; i++) {
      var elem = $(fixed[i]);
      if(!elem) continue;
      this.fixed.push(elem);
    }
    this.element.style.cursor = 'n-resize';
    this.startPtr = [];
    // bind to grab method
    this.eventGrabRef = this.eventGrab.bindAsEventListener(this);
    Event.observe(this.element, "mousedown", this.eventGrabRef);
    // get refs for document move & release
    this.eventMoveRef = this.eventMove.bindAsEventListener(this);
    this.eventReleaseRef = this.eventRelease.bindAsEventListener(this);
    // IE sends resize event while we are resizing, lock to ignore
    this.lock = 0;
    // make the initial adjustment
    this.adjust();
    // handler for window resize
    this.eventResizeRef = this.adjust.bindAsEventListener(this);
    Event.observe(window, "resize", this.eventResizeRef);
  },

  eventGrab: function(event) {
    var temp = event.pointer();
    this.startPtr = [temp.x,temp.y];
    document.body.style.cursor = 'n-resize';
    Event.observe(document, "mousemove", this.eventMoveRef);
    Event.observe(document, "mouseup", this.eventReleaseRef);
    event.stop();
    return false;
  },

  // document level handlers
  eventMove: function(event) {
    event.stop();
    return false;
  },

  eventRelease: function(event) {
    Event.stopObserving(document, "mousemove", this.eventMoveRef);
    Event.stopObserving(document, "mouseup", this.eventReleaseRef);
    document.body.style.cursor = 'auto';
    var temp = event.pointer();
    var deltaY = temp.y - this.startPtr[1];
		var newh = this.tld.getHeight() + deltaY;
		document.cookie = "TableHeight=" + newh;
    this.tld.setHeight(newh);
		newh = this.tld.getHeight();
    event.stop();
    return false;
  },

  adjust: function(event){
    if(this.lock){
      return;
    }
    this.lock = 1;
    var fixedTotal = 40;
    for(var i=0; i<this.fixed.length; i++){
      var elem = $(this.fixed[i]);
      if(!elem) continue;
      fixedTotal += elem.offsetHeight+16;
    }
    var remain = document.viewport.getHeight() - fixedTotal;
    if(remain <= 0) return;
    var flexedTotal = this.tld.getHeight() + this.tld.getHeightRec();
    this.tld.setHeight(remain*this.tld.getHeight()/flexedTotal);
    this.lock = 0;
    return;
  }

});

