'use strict';
define(["d3"],
  function(d3) {
    var PositionSeries = function() {

      var master_width = 600,
        master_height = 100,
        master_data = [],
        target = "body";

      function generate() {
        var container = d3.select(target).append("svg")
          .attr("width", master_width)
          .attr("height", master_height);

        var graphGroup = container.append("g");

        
        //subchart function
        function chart() {

          var width = 100, // default width
            height = 80, // default height
            xPos = 0,
            yPos = 0,
            data = [];

          var xScale = d3.scale.linear()
            .domain([0, 1500])
            .range([0, width]);
          var xValue = function(d) {
            return d.x;
          }; // data -> value
          var yScale = d3.scale.linear()
            .domain([0, 1125])
            .range([height, 0]);
          var yValue = function(d) {
            return d.y;
          }; // data -> value

          var xMap = function(d) {
            return xScale(xValue(d));
          }; // data -> display
          var yMap = function(d) {
            return yScale(yValue(d));
          }; // data -> display

          var xAxis = d3.svg.axis()
            .scale(xScale)
            .orient("bottom")
            .innerTickSize(-height)
            .outerTickSize(0)
            .tickPadding(10)
            .tickFormat("");

          var yAxis = d3.svg.axis()
            .scale(yScale)
            .orient("left")
            .innerTickSize(-width)
            .outerTickSize(0)
            .tickPadding(10)
            .tickFormat("");


          function my() {
            var t = graphGroup.append("g")
              .attr("width", width)
              .attr("height", height)
              .attr("transform", "translate(" + xPos + "," + yPos + ")");


            t.append("g")
              .attr("class", "x axis")
              .attr("transform", "translate(0," + height + ")")
              .call(xAxis);

            t.append("g")
              .attr("class", "y axis")
              .call(yAxis);

            t.selectAll(".dot")
              .data(data)
              .enter().append("circle")
              .attr("class", "dot")
              .attr("r", 2)
              .attr("cx", xMap(this))
              .attr("cy", yMap(this))
              .style("fill", "red");

          }

          my.width = function(value) {
            console.log("width");

            if (!arguments.length) {
              return width;
            }
            width = value;
            return my;
          };

          my.height = function(value) {
            if (!arguments.length) {
              return height;
            }
            height = value;
            return my;
          };

          my.xPos = function(value) {
            if (!arguments.length) {
              return xPos;
            }
            xPos = value;
            return my;
          };

          my.yPos = function(value) {
            if (!arguments.length) {
              return yPos;
            }
            yPos = value;
            return my;
          };

          my.data = function(value) {
            if (!arguments.length) {
              return data;
            }
            data = value;
            return my;
          };


          return my;
        }

//loop to generate subcharts
        for (var i = 0; i < master_data.length; i++) {
          var myChart = chart().width(100).height(80).xPos(110 * i).yPos(0).data(master_data[i]);
          myChart();
        }
      }
    };

    return PositionSeries;

  });