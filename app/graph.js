'use strict';
define(["d3"],
  function(d3) {
    var Graph = function(width, height) {

      this.data = [{
        x: 0,
        y: 0
      }, {
        x: 10,
        y: 100
      }, {
        x: 50,
        y: 200
      }];

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

      var xScale = d3.scale.linear()
        .range([0, width - margin.left - margin.right]);

      var yScale = d3.scale.linear()
        .range([height - margin.top - margin.bottom, 0]);

      this.line = d3.svg.line().interpolate("monotone")
        .x(function(d) {
          return xScale(d.x);
        })
        .y(function(d) {
          return yScale(d.y);
        });

        this.height = height;
        this.width = width;
        this.margin = margin;


      // initial page render
      this.render();

      // continuous page render
      //setInterval(this.render, 1500);


    };

    // create random data
    Graph.prototype.newData = function(lineNumber, points) {
      return d3.range(lineNumber).map(function() {
        return d3.range(points).map(function(item, idx) {
          return {
            x: idx / (points - 1),
            y: Math.random() * 100
          };
        });
      });
    };


    Graph.prototype.render = function() {
      // generate new data
      var data = this.newData(+document.getElementById("linecount").value, +document.getElementById("pointcount").value);

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
      var yScale = d3.scale.linear()
        .range([this.height - this.margin.top - this.margin.bottom, 0]).domain([yMin, yMax]);

      // create axis scale
      var yAxis = d3.svg.axis()
        .scale(yScale).orient("left");

      // if no axis exists, create one, otherwise update it
      if (this.svg.selectAll(".y.axis")[0].length < 1) {
        this.svg.append("g")
          .attr("class", "y axis")
          .call(yAxis);
      } else {
        this.svg.selectAll(".y.axis").transition().duration(1500).call(yAxis);
      }

      // generate line paths
      var lines = this.svg.selectAll(".line").data(data).attr("class", "line");

      // transition from previous paths to new paths
      lines.transition().duration(1500)
        .attr("d", this.line)
        .style("stroke", function() {
          return '#' + Math.floor(Math.random() * 16777215).toString(16);
        });

      // enter any new data
      lines.enter()
        .append("path")
        .attr("class", "line")
        .attr("d", this.line)
        .style("stroke", function() {
          return '#' + Math.floor(Math.random() * 16777215).toString(16);
        });

      // exit
      lines.exit()
        .remove();

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