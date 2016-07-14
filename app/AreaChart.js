//AreaSeries.js
'use strict';
define(["d3", "app/BaseChart"],
  function(d3, BaseChart) {
    var AreaChart = function() {
      BaseChart.call(this);
      this.xDomain = [0, 10];
      this.yDomain = [0, 6];
      this.height = 56.5;


    };

    AreaChart.prototype = new BaseChart();

    AreaChart.prototype.constructor = AreaChart;


    AreaChart.prototype.render = function() {
      var self = this;
      this.container
        .transition().duration(1000).ease("sin-in-out")
        .attr("width", this.width)
        .attr("height", this.height)
        .attr("transform", "translate(" + this.x + "," + this.y + ")");
      this.renderAxes();
      var area = d3.svg.area()
        .x(self.xMap(self))
        .y0(self.height)
        .y1(self.yMap(self))
        .interpolate("linear");

      this.container.append("path")
        .attr("class", "area")
        .attr("d", area(this.data))
        .attr("fill", "blue");
    };

    AreaChart.prototype.xAxisTranslation = function() {
      return [0, (this.height / 2 - 40)];
    };

    AreaChart.prototype.yMap = function(target) {
      return function(d) {
        return target.height-target.yScale()(target.yValue(d));
      };
    };

    return AreaChart;

  });

