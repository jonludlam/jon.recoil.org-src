/* javascript to animate the fungus svg */

var time=10.0;
var expt=5;
var mysplot;
var xs=new Array;
var ys=new Array;

function initme()
{
	create_graph('graph',400,400);
	var g=get_graph('graph');
	g.set_bounds(0,30,0,150);
	mysplot=new splot('splot',get_graph('graph'),[0],[0]);	
	set_time(12.0);

}

function plot()
{
	xs=new Array(time+1);
	ys=new Array(time+1);

	for(i=0; i<=time; i++)
	{
		xs[i]=i;
		ys[i]=timecourse[expt][i];	
	}

	mysplot.xs=xs;
	mysplot.ys=ys;
	mysplot.graph.update();
}

function set_time(t)
{
	time=t;

	for(i=0; i<cellids.length-1; i++)
	{
		var id=cellids[i];
		var e=document.getElementById(id);
		if(e)
		{
			if(celltimes[expt][i]>=0.0 && celltimes[expt][i]<t)
				e.setAttribute("fill","red");
			else
				e.setAttribute("fill","white");
			
		}
	}

	var timeelt=document.getElementById("time");
	timeelt.removeChild(timeelt.firstChild);
	timeelt.appendChild(document.createTextNode("Time: "+time.toFixed(1)));

	var repelt=document.getElementById("rep");
	repelt.removeChild(repelt.firstChild);
	repelt.appendChild(document.createTextNode("Rep: "+expt));

	plot();
}

function back()
{
	set_time(time-1.0);
}

function forward()
{
	set_time(time+1.0);
}

function next_rep()
{
	if(expt<cellids.length-1)
	{
		expt=expt+1;
		set_time(12.0);
	}
}

function prev_rep()
{
	if(expt>0)
	{
		expt=expt-1;
		set_time(12.0);
	}
}