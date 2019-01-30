genericSlider = function(containerName,initVal,callback){

  // init values:
  this.containerName=containerName;
  this.canvas=document.getElementById(containerName);
  this.canvas.canvasSliderObject=this;
  this.context=this.canvas.getContext("2d");
  this.value=initVal;
  this.r=5; //this is the marker radius
  this.mouseDown=false;
  this.callback=callback;
  this.mouseMoved=false;

  this.set=function(val, isFinal, only_redraw) {
    if (typeof only_redraw === "undefined") {
      only_redraw = false;
    }

    if(val<0)
      val=0;
    if(val>1)
      val=1;
    this.value=val;
    this.redraw();
    if (only_redraw !== true) {
      this.callback(val,isFinal);
    }
  }

  this.get=function() {
    return this.value;
  }

  this.redraw=function(){
    var w=this.canvas.width;
    var h=this.canvas.height;
    var c=this.context;
    var markerX=(w-this.r)*this.value+this.r/2;

    c.clearRect(0,0,w,h);
    c.strokeStyle = 'gray';

    // the circle
    c.beginPath();
    c.arc(markerX,h/2,this.r,0,2*Math.PI);
    c.fillStyle = this.fillColor();
    c.fill();

    c.stroke();
    c.closePath();

    //vertical line
    c.beginPath();
    c.moveTo(markerX,h/2-2);
    c.lineTo(markerX,h/2+2);
    c.stroke();
    c.closePath();

    //horizontal line
    c.beginPath();
    c.moveTo(this.r/2,h/2);
    c.lineTo(w-this.r/2,h/2);
    c.stroke();
    c.closePath();

    // marks:
    for(var i=0;i<=1;i+=0.25) {
      c.beginPath();
      c.moveTo(this.r/2+(w-this.r)*i,h-3);
      c.lineTo(this.r/2+(w-this.r)*i,h);
      c.stroke();
      c.closePath();
    }

  }

  this.onMouseDown=function(e) {
    s=this.canvasSliderObject;
    var v=((e.offsetX-s.r/2)/(s.canvas.width- s.r));
    for(var i=0;i<=1;i+=0.25) {
      if(v>i-0.05 && v<i+0.05)
        v=i;
    }

    s.set(v,false);
    s.mouseDown=true;
    this.mouseMoved=false;
  }

  this.onMouseUp=function(e) {
    if(s.mouseDown===false)
      return;
    s=this.canvasSliderObject;
    s.mouseDown=false;
    var v=((e.offsetX-s.r/2)/(s.canvas.width- s.r));
    if(this.mouseMoved==false) {
      for(var i=0;i<=1;i+=0.25) {
        if(v>i-0.05 && v<i+0.05)
          v=i;
      }
    }

    s.set(v,true);
  }

  this.onMouseMove=function(e) {
    s=this.canvasSliderObject;
    if(s.mouseDown===false)
      return;
    var v=((e.offsetX-s.r/2)/(s.canvas.width- s.r));
    s.set(v,false);
    this.mouseMoved=true;
  }

  this.onMouseLeave=function(e) {
    if(s.mouseDown===false)
      return;
    s=this.canvasSliderObject;
    s.mouseDown=false;
    var v=((e.offsetX-s.r/2)/(s.canvas.width- s.r));
    s.set(v,true);
  }

  this.fillColor = function() {
    return JustdoColorGradient.getColorHex(parseInt(this.value * 100, 10));
  }

  //link mouse events:
  this.canvas.addEventListener("mousedown",this.onMouseDown,false);
  this.canvas.addEventListener("mouseup",this.onMouseUp,false);
  this.canvas.addEventListener("mousemove",this.onMouseMove,false);
  this.canvas.addEventListener("mouseleave",this.onMouseLeave,false);
  this.redraw();
}
