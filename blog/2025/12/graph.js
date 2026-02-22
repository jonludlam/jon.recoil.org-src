/* Graph.js
 *
 * Version 0.1
 *
 */

var SVG_NS="http://www.w3.org/2000/svg"

var graphs=new Object;
var datasets=new Object;
var handles=new Object;

/* Convert between graph, screen and event coordinates */

function xtosx ( x ) { return (this.o_x + ((x - this.min_x) / (this.max_x - this.min_x)) * this.size_x * this.width);}
function ytosy ( y ) { return (this.height - (this.o_y + ((y - this.min_y) / (this.max_y - this.min_y)) * this.size_y * this.height)); }
function sxtox ( sx) { return ((sx - this.o_x)*((this.max_x - this.min_x)/(this.size_x*this.width))+this.min_x);}
function sytoy ( sy) { return (((this.height - sy) - this.o_y)*((this.max_y - this.min_y)/(this.size_y*this.height))+this.min_y);}
function rsxtox (sx) { return (this.sxtox(sx - this.mygraph.getScreenCTM().e)); }
function rsytoy (sy) { return (this.sytoy(sy - this.mygraph.getScreenCTM().f)); }


/* Helper ticking function */

function nicenum(x) {
	if (x==0.0)
		return 0.0;
	
	var xsign;
	if (x<0.0)
		xsign=-1.0;
	else
		xsign=1.0;

	x = Math.abs(x);

	var fexp = Math.floor(Math.log(x) / Math.log(10.0));

	var sx = x / Math.pow(10.0,fexp) / 10.0;
	var rx = Math.floor(sx);
	var f = 10.0 * (sx - rx);
	var y;
	if(f<1.0)
		y=1.0;
	else if(f<3.0)
		y=2.0;
	else if(f<7.0)
		y=5.0;
	else y=10.0;
	var sx = rx + (y / 10.0) 

	return (xsign * sx * 10.0 * Math.pow(10.0,fexp));

}


/* Dataset constructor */

function dataset (data,min,max) {
	this.min=min;
	this.max=max;
	this.data=data;
	return this;
}

function get_dataset(name) {
	return datasets[name];
}

function set_dataset(name,set) {
	datasets[name]=set;
}


/* Graph class */

function insert_line(parent,x1,y1,x2,y2,style)
{
	var tick = document.createElementNS(SVG_NS,"path");
	tick.setAttribute("d","M "+x1+","+y1+" L "+x2+","+y2);
	tick.setAttribute("style",style);
	parent.appendChild(tick);
}

function insert_text(parent,x,y,text,font_size,angle)
{
	var data = document.createTextNode(text);
	var text = document.createElementNS(SVG_NS,"text");
	text.setAttribute("x",x);
	text.setAttribute("y",y);
	text.setAttribute("fill","black");
	text.setAttribute("text-anchor","middle");
	text.setAttribute("font-size",font_size);
	text.setAttribute("rotate",angle);
	text.appendChild(data);
	parent.appendChild(text);
}

function graph_do_ticks () {
	var initx = Math.round((this.min_x / this.tick_x) + 0.5);
	var inity = Math.round((this.min_y / this.tick_y) + 0.5);
	var endx = Math.round((this.max_x / this.tick_x) + 0.5);
	var endy = Math.round((this.max_y / this.tick_y) + 0.5);

	var xticksg = document.createElementNS(SVG_NS,"g");
	
	for(i=initx; i<endx; i++)
	{
		if(i!=0)
		{
			var x = Math.round(this.xtosx(i*this.tick_x));	

			if(this.min_y < 0 && this.max_y > 0)
				var y = Math.round(this.ytosy(0));
			else
				var y = Math.round(this.ytosy(this.min_y));

			var y1 = y+this.tick_length;
			var ymx = Math.round(this.ytosy(this.max_y));
			var ymn = Math.round(this.ytosy(this.min_y));
			insert_line(xticksg,x,y,x,y1,"fill:none; stroke-width:0.5px; stroke:rgb(0,0,0);");
			insert_line(xticksg,x,ymn,x,ymx,"fill:none; stroke-width:0.5px; stroke:rgb(232,232,255);");
			insert_text(xticksg,x,y1+this.tick_length+10.0,
				(i*this.tick_x).toPrecision(3),this.font_size,0);
		}
	}

	var oldxticks = document.getElementById(this.name+"xticks");
	if(oldxticks) this.mygraphg.removeChild(oldxticks);

	xticksg.setAttribute("id",this.name+"xticks");
	this.mygraphg.appendChild(xticksg);

	var yticksg = document.createElementNS(SVG_NS,"g");
	
	for(i=inity; i<endy; i++)
	{
		if(i!=0)
		{
		var y = Math.round(this.ytosy(i*this.tick_y));

			if(this.min_x < 0 && this.max_x > 0)
				var x = Math.round(this.xtosx(0));
			else
				var x = Math.round(this.xtosx(this.min_x));

		var x1 = x-this.tick_length;
		var xmx = Math.round(this.xtosx(this.max_x));
		var xmn = Math.round(this.xtosx(this.min_x));
		insert_line(yticksg,x,y,x1,y,"fill:none; stroke-width:0.5px; stroke:rgb(0,0,0);");
		insert_line(yticksg,xmn,y,xmx,y,"fill:none; stroke-width:0.5px; stroke:rgb(232,232,255);");
		insert_text(yticksg,x-this.tick_length-10.0,y+5.0,
			(i*this.tick_y).toPrecision(3),this.font_size,0);
		}

	}

	var oldyticks = document.getElementById(this.name+"yticks");
	if(oldyticks) this.mygraphg.removeChild(oldyticks);

	yticksg.setAttribute("id",this.name+"yticks");
	this.mygraphg.appendChild(yticksg);
}

function graph_init()
{
	this.mygraph.setAttribute("width",this.width+10);
        this.mygraph.setAttribute("height",this.height+10);

	this.background.setAttribute("x",5);
	this.background.setAttribute("y",5);
	this.background.setAttribute("width",this.width);
	this.background.setAttribute("height",this.height);
	this.background.setAttribute("style","fill:rgb(224,224,255);stroke-width:1px;stroke:rgb(0,0,0);");

	var x = this.width * ((1.0 - this.size_x) / 2.0);
	var y = this.height * ((1.0 - this.size_y) / 2.0);
	this.o_x = x;
	this.o_y = y;

	this.foreground.setAttribute("x",x);
	this.foreground.setAttribute("y",y);
	this.foreground.setAttribute("width",this.width * this.size_x);
	this.foreground.setAttribute("height",this.height * this.size_y);
	this.foreground.setAttribute("style","fill:rgb(255,255,255);stroke-width:1px;stroke:rgb(0,0,0);");

	this.forecliprect.setAttribute("x",x);
	this.forecliprect.setAttribute("y",y);
	this.forecliprect.setAttribute("width",this.width * this.size_x);
	this.forecliprect.setAttribute("height",this.height * this.size_y);

	this.font_size = Math.round(2.0 + (this.width / 100.0)) + "pt";

	var sxmin = Math.round(this.xtosx(this.min_x));
	var sxmax = Math.round(this.xtosx(this.max_x));
	var sx0 = Math.round(this.xtosx(0));
	var symin = Math.round(this.ytosy(this.min_y));
	var symax = Math.round(this.ytosy(this.max_y));
	var sy0 = Math.round(this.ytosy(0));

	this.tick_x = nicenum(this.max_x - this.min_x) / 10.0;
	this.tick_y = nicenum(this.max_y - this.min_y) / 10.0;
	
	this.xaxis.setAttribute("d","M " + sxmin +","+sy0+" L "+sxmax+","+sy0);
	this.xaxis.setAttribute("style","fill:none; stroke-width:0.5px; stroke:rgb(0,0,0);");

	this.yaxis.setAttribute("d","M " + sx0 +","+symin+" L "+sx0+","+symax);
	this.yaxis.setAttribute("style","fill:none; stroke-width:0.5px; stroke:rgb(0,0,0);");

//	insert_text(this.mygraphg,(sxmin+sxmax)/2.0,symin+this.tick_length+10.0,this.axis_label_x,this.font_size,0);
//	insert_text(this.mygraphg,sxmin-this.tick_length-(10.0),(symin+symax)/2.0,this.axis_label_y,this.font_size,90);
}

function graph_set_bounds(min_x,max_x,min_y,max_y)
{
	this.min_x=min_x;
	this.max_x=max_x;
	this.min_y=min_y;
	this.max_y=max_y;
	this.init();
	this.do_ticks();
	this.update();
}

function graph_update() {
	var i;
	var s="plot names: ";
	for(i=0; i<this.plots.length; i++)
		s+=this.plots[i].name + ", ";

	for(i=0; i<this.plots.length; i++)
		this.plots[i].update();
}

function graph(name,w,h) {
	this.name = name;
	this.mygraph = document.getElementById(name);

	this.width = w;
	this.height = h;
	
	this.size_x = 0.8;
	this.size_y = 0.85;

	this.min_x = -5.0;
	this.max_x = 10.0;
	this.min_y = -5.0;
	this.max_y = 10.0;
	this.tick_x = 2.0;
	this.tick_y = 2.0;
	this.tick_length = Math.round(w / 100.0);

	this.axis_label_x="x";
	this.axis_label_y="y";

	this.o_x = 0;
	this.o_y = 0;

// Member functions
	this.xtosx = xtosx;
	this.ytosy = ytosy;
	this.sxtox = sxtox;
	this.sytoy = sytoy;
	this.rsxtox = rsxtox;
	this.rsytoy = rsytoy;

	this.mygraphg = document.createElementNS(SVG_NS,"g");
	this.mygraphg.setAttribute("transform","translate(0.5,0.5)");
	this.mygraph.appendChild(this.mygraphg);

	this.background = document.createElementNS(SVG_NS,"rect");
	this.background.setAttribute("id",this.name+"background");
	this.mygraphg.appendChild(this.background);

	this.foreground = document.createElementNS(SVG_NS,"rect");
	this.foreground.setAttribute("id",this.name+"foreground");
	this.mygraphg.appendChild(this.foreground);

	this.foreclip = document.createElementNS(SVG_NS,"clipPath");
	this.foreclip.setAttribute("id",this.name+"foreclip");
	this.mygraphg.appendChild(this.foreclip);

	this.forecliprect = document.createElementNS(SVG_NS,"rect");
	this.foreclip.appendChild(this.forecliprect);

	this.xaxis = document.createElementNS(SVG_NS,"path");
	this.xaxis.setAttribute("id",this.name+"xaxis");
	this.mygraphg.appendChild(this.xaxis);

	this.yaxis = document.createElementNS(SVG_NS,"path");
	this.yaxis.setAttribute("id",this.name+"yaxis");
	this.mygraphg.appendChild(this.yaxis);

	this.plots=[];

	this.init=graph_init;
	this.do_ticks=graph_do_ticks;
	this.update=graph_update;
	this.set_bounds=graph_set_bounds;
	return this;
}

function get_graph(name) {
	return graphs[name];
}

function set_graph(name,graph) {
	graphs[name]=graph;
}

function create_graph(name,w,h) {
	var g=new graph(name,w,h);
	set_graph(name,g);
	g.init();
	g.do_ticks();
}


/* Plot classes */

function fplot_update()
{
	this.plot();
}

function fplot_plot()
{
	minsx = this.graph.xtosx(this.graph.min_x);
	y0 = this.graph.ytosy(this.f(this.graph.min_x));

	var path = "M "+minsx+","+y0;

	for(i=1; i<=20; i++)
        {
		x = (i/20.0)*(this.max_x - this.min_x) + this.min_x;
		y = this.f(x);	

		path = path + " L "+ this.graph.xtosx(x) + ","+this.graph.ytosy(y);
	}

	this.myplot.setAttribute("d",path);
}

function fplot(name,graph,f)
{
	this.name=name;
	this.f=f;
	this.myplot=document.createElementNS(SVG_NS,"path");
	this.myplot.setAttribute("style","fill:none; stroke-width:0.5px; stroke:rgb(0,0,0);");
	this.myplot.setAttribute("clip-path","url(#"+graph.name+"foreclip)");
	this.graph=graph;
	this.update=fplot_update;
	graph.plots.push(this);
	this.plot=fplot_plot;
	graph.mygraphg.appendChild(this.myplot);
	this.min_x=graph.min_x;
	this.max_x=graph.max_x;
}

/* Set plot */

function set_plot_update()
{
	this.plot();
}

function set_plot_plot()
{
	var path = "M "+this.graph.xtosx(this.xs[0]) + "," + 
			this.graph.ytosy(this.ys[0]);

	for(i=1; i<this.xs.length; i++)
        {
		x = this.xs[i];
		y = this.ys[i];

		path = path + " L "+ this.graph.xtosx(x) + ","+this.graph.ytosy(y);
	}

	this.myplot.setAttribute("d",path);	
}

function splot(name,graph,xs,ys)
{
	this.name=name;
	this.xs=xs;
	this.ys=ys;
	this.myplot=document.createElementNS(SVG_NS,"path");
	this.myplot.setAttribute("style","fill:none; stroke-width:0.5px; stroke:rgb(0,0,0);");
	this.myplot.setAttribute("clip-path","url(#"+graph.name+"foreclip)");
	this.graph=graph;
	this.update=set_plot_update;
	graph.plots.push(this);
	this.plot=set_plot_plot;
	graph.mygraphg.appendChild(this.myplot);
}

/* Handle functions */

function get_handle(name) {
	return handles[name];
}

function set_handle(name,handle) {
	handles[name]=handle;
}

function handle_setxy(x,y)
{
	this.box.setAttribute("x",this.graph.xtosx(x)-5);
	this.box.setAttribute("y",this.graph.ytosy(y)-5);
}


function handle(name,graph,initgx,initgy,constraintx,constrainty,func)
{
	this.graph=get_graph(graph);
	this.dragging=false;
	this.initx=0;
	this.inity=0;
	this.dx=0;
	this.dy=0;
	this.beforex=0;
	this.beforey=0;

	this.constraintx=constraintx;
	this.constrainty=constrainty;
	this.func=func;	
	this.setxy=handle_setxy;
	h=document.createElementNS(SVG_NS,"rect");
	h.setAttribute("x",this.graph.xtosx(initgx)-5);
	h.setAttribute("y",this.graph.ytosy(initgy)-5);
	h.setAttribute("width",10);
	h.setAttribute("height",10);
	h.setAttribute("style","fill:rgb(255,128,0);stroke-width:1px;stroke:rgb(0,0,0);");

	h.setAttribute("onmousedown","mousedownhandler('"+name+"',evt);");
	h.setAttribute("onmousemove","mousemovehandler('"+name+"',evt);");
	h.setAttribute("onmouseup","mouseuphandler(evt);");
	this.graph.mygraph.appendChild(h);
	this.graph.foreground.setAttribute("onmousemove","mousemovehandler('"+name+"',evt);");
	this.graph.foreground.setAttribute("onmouseup","mouseuphandler(evt);");
	this.box=h;
}

function mousedownhandler(handlename,event)
{
	var h=get_handle(handlename);

	h.dragging=true;

	var x = event.clientX - h.graph.mygraph.getScreenCTM().e;
	var y = event.clientY - h.graph.mygraph.getScreenCTM().f;

	h.beforex=Number(h.box.getAttribute("x"))+5;
	h.beforey=Number(h.box.getAttribute("y"))+5;

	h.initx=x;
	h.inity=y;	
}

function mousemovehandler(handlename,event)
{
	var dragging;

	for(h in handles)
	{
		if(handles[h].dragging)
			dragging=handles[h];
	}

	if(dragging)
	{
		var h=dragging;
		var g=h.graph;
		var x = event.clientX - g.mygraph.getScreenCTM().e;
		var y = event.clientY - g.mygraph.getScreenCTM().f;

		h.dx=x-h.initx;
		h.dy=y-h.inity;	

		var newx = h.graph.sxtox(h.beforex+h.dx);
		var newy = h.graph.sytoy(h.beforey+h.dy);
	
		newx=h.constraintx(newx);
		newy=h.constrainty(newy);

		h.box.setAttribute("x",h.graph.xtosx(newx)-5);
		h.box.setAttribute("y",h.graph.ytosy(newy)-5);

		h.func(newx,newy);
	}
}

function mouseuphandler(event)
{
	for(h in handles)
	{
		handles[h].dragging=false;
	}
}

function test_handle()
{
	var fnx=function(x) {return x;}
	var fny=function(y) {return y;}
	var fnnull=function() { return 0.0;}

	var g=get_graph('graph1');
	var h=new handle('blah','graph1',0.0,0.0,fnx, fny, fnnull);
	set_handle('blah',h);
}

function test_handle2()
{
	var fnx=function(x) {return x;}
	var fny=function(y) {return y;}
	var fnnull=function() { return 0.0;}

	var j=new handle('blah2','graph1',0.0,2.0,fnnull, fny, fnnull);
	set_handle('blah2',j);
}