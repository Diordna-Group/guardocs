// resize.js: subclass of script.aculo.us Draggable adding resize- and cage-ability
// Copyright (c) 2008, Archivista GmbH, m. allan noah
//
// Some code from resize.js Copyright (c) 2005 Thomas Fakes (http://craz8.com)
// 
// Which was substantially based on code from script.aculo.us which has the 
// following copyright and permission notice
//
// Copyright (c) 2005 Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us)
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

var Resizeable = Class.create(Draggable,{

  // our overloaded functions
  initialize: function($super,element,userOpts) {

    // set defaults and ingest user options, ours have private prefix
    var options = Object.extend({
        resize_minHeight : 0,
        resize_minWidth  : 0,
        resize_handleWidth : 10,
        resize_cageID : '',
        scroll : window
    }, userOpts || {});

    if(!options.resize_minHeight){
      options.resize_minHeight = options.resize_handleWidth*2.5;
    }

    if(!options.resize_minWidth){
      options.resize_minWidth = options.resize_handleWidth*2.5;
    }

    // call original function, with updated options
    $super(element,options);

    // add our bookkeeping vars to a new slice
    this.resize = {
      direction : '',
      startPos : {},
      startActDim : {},
      startStyDim : {},
      startPtr : {},
      cageDim : {},
      eventCursorCheck : this.cursor.bindAsEventListener(this)
    };

    // that which contains us
    this.cageElement = '';
    if(this.options.resize_cageID.length){
      this.cageElement = $(this.options.resize_cageID);
    }

    // the cage element size
    if(this.cageElement){
      this.resize.cageDim = [
        parseInt(this.cageElement.getStyle('width')),
        parseInt(this.cageElement.getStyle('height'))
      ];
    }
    // or the body size
    else{
      var foo = $(document.documentElement).getDimensions();
      this.resize.cageDim = [foo.width,foo.height];
    }

    // bind to cursor changing method
    Event.observe(this.element, "mousemove", this.resize.eventCursorCheck);
  },

  initDrag: function($super,event) {

    $super(event);

    // superclass captured the event
    if(event.stopped){

      this.resize.direction = this.directions(event);

      this.resize.startPos = [
        parseInt(this.element.getStyle('left')),
        parseInt(this.element.getStyle('top'))
      ];

      var temp = this.element.getDimensions();
      this.resize.startActDim = [
        temp.width, temp.height
      ];

      this.resize.startStyDim = [
        parseInt(this.element.getStyle('width')),
        parseInt(this.element.getStyle('height'))
      ];

      var temp = event.pointer();
      this.resize.startPtr = [temp.x,temp.y];
    }
  },

  // the element method, not the window method
  updateDrag: function($super,event,pointer) {

    var deltaX = pointer[0] - this.resize.startPtr[0];
    var deltaY = pointer[1] - this.resize.startPtr[1];

    if(this.resize.direction.length) {

      var style = this.element.style;

      if (this.resize.direction.indexOf('w') != -1) {

        var newWidth = this.resize.startActDim[0] - deltaX;
        var newSWidth = this.resize.startStyDim[0] - deltaX;
        var newLeft = this.resize.startPos[0] + deltaX;

        if ((newSWidth >= this.options.resize_minWidth || deltaX < 0)
        && newLeft >=0) {
          style.width = newSWidth + "px";
          style.left = newLeft + "px";
        }
      }
      else if (this.resize.direction.indexOf('e') != -1) {

        var newWidth = this.resize.startActDim[0] + deltaX;
        var newSWidth = this.resize.startStyDim[0] + deltaX;
        var newRight = this.resize.startPos[0] + newWidth;

        if ((newSWidth >= this.options.resize_minWidth || deltaX > 0)
        && newRight <= this.resize.cageDim[0]) {
          style.width = newSWidth + "px";
        }
      }

      if (this.resize.direction.indexOf('n') != -1) {

        var newHeight = this.resize.startActDim[1] - deltaY;
        var newSHeight = this.resize.startStyDim[1] - deltaY;
        var newTop = this.resize.startPos[1] + deltaY;

        if ((newSHeight >= this.options.resize_minHeight || deltaY < 0)
        && newTop >= 0) {
          style.height = newSHeight + "px";
          style.top = newTop + "px";
        }
      }
      else if (this.resize.direction.indexOf('s') != -1) {

        var newHeight = this.resize.startActDim[1] + deltaY;
        var newSHeight = this.resize.startStyDim[1] + deltaY;
        var newBottom = this.resize.startPos[1] + newHeight;

        if ((newSHeight >= this.options.resize_minHeight || deltaY > 0)
        && newBottom <= this.resize.cageDim[1]) {
          style.height = newSHeight + "px";
        }
      }

      // fix gecko rendering
      if(style.visibility=="hidden") style.visibility = "";

      // fix AppleWebKit rendering
      if(navigator.appVersion.indexOf('AppleWebKit')>0) window.scrollBy(0,0); 

      Event.stop(event);
      return;
    }

    // not resizing, just dragging. clamp pointer to our cage
    var newLeft = this.resize.startPos[0] + deltaX;
    var newRight = this.resize.cageDim[0]
      - (newLeft + this.resize.startActDim[0]);
    if(newLeft < 0){
      pointer[0] -= newLeft;
    }
    if(newRight < 0){
      pointer[0] += newRight;
    }

    var newTop = this.resize.startPos[1] + deltaY;
    var newBottom = this.resize.cageDim[1]
      - (newTop + this.resize.startActDim[1]);
    if(newTop < 0){
      pointer[1] -= newTop;
    }
    if(newBottom < 0){
      pointer[1] += newBottom;
    }

    $super(event,pointer);
  },

  endDrag: function($super,event) {
    this.resize.direction = '';
    $super(event);
  },

  // our new functions
  directions: function(event) {
    var pointer = [event.clientX, event.clientY];
    var offsets = this.element.viewportOffset();
    var rhw = this.options.resize_handleWidth;

    var cursor = '';

    if (offsets[1]+this.element.offsetHeight-pointer[1] < rhw)
      cursor += 's';

    else if (pointer[1]-offsets[1] < rhw)
      cursor += 'n';

    if (offsets[0]+this.element.offsetWidth-pointer[0] < rhw)
      cursor += 'e';

    else if (pointer[0]-offsets[0] < rhw)
      cursor += 'w';

    return cursor;
  },

  cursor: function(event) {
    var cursor = this.directions(event);
    if (cursor.length > 0) {
        cursor += '-resize';
    } else {
        cursor = 'move';
    }
    this.element.style.cursor = cursor;
  }

});

