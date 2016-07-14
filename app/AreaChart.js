//AreaSeries.js
'use strict';
define(["d3", "app/BaseChart"],
  function(d3, BaseChart) {
    var AreaChart = function() {
      BaseChart.call(this);
      this.xDomain = [0, 10];
      this.yDomain = [0, 6];
      this.height = 56.5;
      this.yMargin = 20;
      this.xMargin = 20;

    };

    AreaChart.prototype = new BaseChart();

    AreaChart.prototype.constructor = AreaChart;


    AreaChart.prototype.render = function() {
      var self = this;
      this.container
        .transition().duration(500).ease("sin-in-out")
        .attr("width", this.width+this.xMargin)
        .attr("height", this.height+this.yMargin)
        .attr("transform", "translate(" + this.x + "," + this.y + ")");
      this.renderAxes();
      var area = d3.svg.area()
        .x(self.xMap(self))
        .y0(this.height)
        .y1(self.yMap(self))
        .interpolate("linear");
    if (this.container.selectAll(".area")[0].length < 1) {
      var path = this.container.append("path")
      
        .attr("class", "area")
        .attr("d", area(this.data))
        .attr("fill", "blue")
        path.attr("clip-path", "url(#clip"+this.id+")");

      }
      else{
        var a =  this.container.selectAll(".area")
        .transition().duration(500).ease("sin-in-out")
        .attr("d", area(this.data))
        .attr("clip-path", "url(#clip"+this.id+")");

      }
    };

    AreaChart.prototype.xAxisTranslation = function(){
      return [this.xMargin, this.height];
    };

AreaChart.prototype.yAxis = function() {

      var yAxis = d3.svg.axis()
        .scale(this.yScale())
        .orient("left")
        .ticks(4);
      return yAxis;
    };
    AreaChart.prototype.yMap = function(target) {
      return function(d) {
        return target.yScale()(target.yValue(d));
      };
    };

    return AreaChart;

  });

