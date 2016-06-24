'use strict';
define(["d3"],
  function(d3) {
    var Graph = function(n, y_start, y_end) {
      this.prevTime = 0;
      this.n = n;
      this.graphData = [{
        dataPoint: 0,
        time: 0
      }, {
        dataPoint: 2,
        time: 2.5
      }, {
        dataPoint: 0,
        time: 3
      }];
      var self = this;
      this.margin = {
        top: 20,
        right: 20,
        bottom: 20,
        left: 40
      };
      this.width = 960 - this.margin.left - this.margin.right;
      this.height = 100 - this.margin.top - this.margin.bottom;
      this.x = d3.scale.linear().domain([0, n - 1]).range([0, this.width]);
      this.y = d3.scale.linear().domain([y_start, y_end]).range([this.height, 0]);
      this.line = d3.svg.line()
        .x(function(d, i) {
          return self.x(d.time);
        })
        .y(function(d, i) {
          return self.y(d.dataPoint);
        });

      console.log('width height', this.width, this.height);
      /// Add an SVG element with the desired dimensions and margin.
      var graph = d3.select("body").append("svg:svg")
        .attr("width", this.width + this.margin.right + this.margin.left)
        .attr("height", this.height + this.margin.bottom + this.margin.left)
        .append("svg:g")
        .attr("transform", "translate(" + this.margin.left + "," + this.margin.top + ")");
      

      // create yAxis
      var xAxis = d3.svg.axis().scale(this.x).tickSize(-this.height).tickSubdivide(true);
      // Add the x-axis.
      graph.append("svg:g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + this.height + ")")
        .call(xAxis);
      // create left yAxis
      var yAxisLeft = d3.svg.axis().scale(this.y).ticks(4).orient("left");
      // Add the y-axis to the left
       graph.append("svg:g")
        .attr("class", "y axis")
        .attr("transform", "translate(-25,0)")
        .call(yAxisLeft);

      // Add the line by appending an svg:path element with the data line we created above
      // do this AFTER the axes above so that the line is above the tick-lines
     graph.append("svg:path").attr("d", this.line(this.graphData));
        this.graphData.push({
        dataPoint: 1,
        time: 4
      });
      
      this.render({
        dataPoint: 1,
        time: 4
      });

    


    };

    Graph.prototype.render = function(data){
  // generate new dataset
  this.graphData.push(data);
   /*var yMin = this.graphData.reduce(function(pv,cv){
    var currentMin = cv.reduce(function(pv,cv){
      return Math.min(pv,cv.y);
    },100);
    return Math.min(pv,currentMin);
  },100);
  var yMax = this.graphData.reduce(function(pv,cv){
    var currentMax = cv.reduce(function(pv,cv){
      return Math.max(pv,cv.y);
    },0);
    return Math.max(pv,currentMax);
  },0);
 
  this.x.domain([yMin,yMax]);*/
 
  var yAxis = d3.svg.axis().scale(this.y).orient("left");
 
  this.svg.selectAll(".y.axis").remove();
 
  this.svg.append("g").attr("class","y axis").call(yAxis);
 
  this.svg.selectAll(".line").remove();
 
  var lines = this.svg.selectAll(".line").data(this.graphData).attr("class","line");
 
  lines.enter().append("path")
    .attr("class","line");
    console.log(this.svg)
};



    Graph.prototype.tick = function(dataPoint, time) {
      //console.log('tick', dataPoint);
      // push a new data point onto the back
      this.graphData.push({
        dataPoint: dataPoint,
        time: time
      });

      //this.path.attr("d", this.line);

      this.zoom.translate([time, 0]);
      this.zoom.event(this.svg);

      /*if (time > this.n) {
               console.log("time", time, "n",this.n, time-this.prevTime)

        this.line
        .attr("transform", null)
        .transition()
        .attr("transform", "translate(" + this.x(this.prevTime-time) + ",0)")
        .duration(1)
        }
       
          
       
      //this.path.each("end", this.tick);
      // pop the old data point off the front
      //this.graphData.shift();*/
      this.prevTime = time;
    };
    return Graph;

  });