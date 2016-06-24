'use strict';
define(["d3"],
  function(d3) {

    var svg, xScale, yScale, line;

    var Graph = function(width, height) {

      this.data = [[]];

      var margin = {
        top: 20,
        right: 20,
        bottom: 20,
        left: 50
      };

      // draw and append the container
      this.svg = d3.select("body").append("svg")
        .attr("height", height)
        .attr("width", width)
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.right + ")");

        this.svg
        .append("clipPath")       // define a clip path
    .attr("id", "clip") // give the clipPath an ID
  .append("rect")          // shape it as an ellipse
    .attr("x", 0)         
    .attr("y", 0)        
   .attr("height", height)    // set the height
    .attr("width", width);    // set the width


      xScale = d3.scale.linear()
        .range([0, width - margin.left - margin.right])
        .domain([2,30]);

      yScale = d3.scale.linear()
        .range([height - margin.top - margin.bottom, 0])

      line = d3.svg.line()
        .x(function(d) {
          console.log("x =",d.x,yScale(d.x));
          return xScale(d.x);
        })
        .y(function(d) {
          console.log("y =",d.y,yScale(d.y));
          return yScale(d.y);
        });

        this.height = height;
        this.width = width;
        this.margin = margin;


      // initial page render
     this.render();
      this.data[0].push({
       y: 0,
       x: 1});
     this.render();
      // continuous page render
      var self = this;
      self.set = setInterval(function(){self.render()}, 1);


    };


    Graph.prototype.render = function() {
      console.log(this)
      // generate new data
      var data = this.data;

      console.log("data", data);
      // obtain absolute min and max
      var yMin = data.reduce(function(pv, cv) {
        var currentMin = cv.reduce(function(pv, cv) {
          return Math.min(pv, cv.y);
        }, 100);
        return Math.min(pv, currentMin);
      }, 100);
      var yMax = data.reduce(function(pv, cv) {
        var currentMax = cv.reduce(function(pv, cv) {
          return Math.max(pv, cv.y);
        }, 0);
        return Math.max(pv, currentMax);
      }, 0);

      // set domain for axis
      yScale.domain([yMin,yMax]);

      // create axis scale
      var yAxis = d3.svg.axis()
        .scale(yScale).orient("left");

         // create axis scale
      var xAxis = d3.svg.axis()
        .scale(xScale).orient("bottom");

      // if no axis exists, create one, otherwise update it
      if (this.svg.selectAll(".y.axis")[0].length < 1) {
        this.svg.append("g")
          .attr("class", "y axis")
          .call(yAxis);
      } else {
        this.svg.selectAll(".y.axis").call(yAxis);
      }


      // if no axis exists, create one, otherwise update it
      if (this.svg.selectAll(".x.axis")[0].length < 1) {
        this.svg.append("g")
          .attr("class", "x axis")
          .call(xAxis);
      } else {
        this.svg.selectAll(".x.axis").call(xAxis);
      }

      /*var line = d3.svg.line().interpolate("monotone")
        .x(function(d){ return xScale(d.x); })
        .y(function(d){ return yScale(d.y); });

*/
      // generate line paths
      var lines = this.svg.selectAll(".line").data(this.data).attr("class", "line");
      console.log('selected line',lines)

      // transition from previous paths to new paths
  lines.transition().duration(1)
    .attr("d",line);
    
      // enter any new data
      lines.enter()
        .append("path")
        .attr("clip-path", "url(#clip)") // clip the rectangle
        .attr("class", "line")
        .attr("d",line)
        .style("stroke", function() {
          return 'red';
        });

      // exit
      lines.exit()
        .remove();

    };



    Graph.prototype.tick = function(dataPoint, time) {
      //console.log('tick', dataPoint);
      // push a new data point onto the back
      this.data[0].push({
       y: dataPoint,
       x: time});


      //this.path.attr("d", this.line);

    };
    return Graph;

  });