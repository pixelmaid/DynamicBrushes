'use strict';
define(["d3"],
  function(d3) {

   // var utils = new Utils();

    var Graph = function(width, height, color) {
      var self = this;
      this.data = [
        []
      ];
      this.prevTime = 0;
      this.xDomainLimit = 15;
      var margin = {
        top: 20,
        right: 20,
        bottom: 20,
        left: 50
      };

      // draw and append the container
      this.svg = d3.select("#graphs").append("svg")
        .attr("height", height)
        .attr("width", width)
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.right + ")");

      this.svg
        .append("clipPath") // define a clip path
        .attr("id", "clip") // give the clipPath an ID
        .append("rect") // shape it as an ellipse
        .attr("x", 0)
        .attr("y", 0)
        .attr("height", height) // set the height
        .attr("width", width); // set the width


     this.xScale = d3.scale.linear()
        .range([0, width - margin.left - margin.right])
        .domain([0, this.xDomainLimit]);
     this.yScale = d3.scale.linear()
        .range([height - margin.top - margin.bottom, 0]);


      this.line = d3.svg.line()
        .x(function(d) {
          //console.log("x =",d.x,xScale(d.x));
          return self.xScale(d.x);
        })
        .y(function(d) {
          //console.log("y =",d.y,yScale(d.y));
          return self.yScale(d.y);
        });

      this.height = height;
      this.width = width;
      this.margin = margin;
      this.color = color

      // initial page render
      this.render();
      this.data[0].push({
        y: 0,
        x: 1
      });
      this.render();
      // continuous page render
      self.set = setInterval(function() {
        self.render();
      }, 1);


    };


    Graph.prototype.calculateMin = function(data, prop) {
      var min = data.reduce(function(pv, cv) {
        var currentMin = cv.reduce(function(pv, cv) {
          return Math.min(pv, cv[prop]);
        }, 100);
        return Math.min(pv, currentMin);
      }, 100);
      return min;
    };

    Graph.prototype.calculateMax = function(data, prop) {
      var max = data.reduce(function(pv, cv) {
        var currentMax = cv.reduce(function(pv, cv) {
          return Math.max(pv, cv[prop]);
        }, 0);
        return Math.max(pv, currentMax);
      }, 0);
      return max;
    };

    Graph.prototype.render = function() {
      // generate new data
      var data = this.data;
      var color = this.color
      console.log('color',color)
      // obtain absolute min and max

      var yMin = this.calculateMin(data, "y");
      var yMax = this.calculateMax(data, "y");

      var xMin = this.calculateMin(data, "x");
      var xMax = this.calculateMax(data, "x");


      // set domain for axis
      this.yScale.domain([yMin, yMax]);
      if(xMax>this.xDomainLimit){
        var start = xMax-this.xDomainLimit;
       this.xScale.domain([start,xMax]);
     }
        // create axis scale
      var yAxis = d3.svg.axis()
        .scale(this.yScale).orient("left");

      // create axis scale
      var xAxis = d3.svg.axis()
        .scale(this.xScale).orient("bottom");
       

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
          .attr("transform", "translate(0," + (this.height-40) + ")")
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

      // transition from previous paths to new paths
      lines.transition().duration(1)
        .attr("d", this.line);

      // enter any new data
      lines.enter()
        .append("path")
        .attr("clip-path", "url(#clip)") // clip the rectangle
        .attr("class", "line")
        .attr("d", this.line)
        .style("stroke", function() {
          return color;
        });

      // exit
      lines.exit()
        .remove();

    };



    Graph.prototype.setData = function(data) {
      //console.log('tick', dataPoint);
      // push a new data point onto the back
      this.data = data



      //this.path.attr("d", this.line);

    };
    return Graph;

  });