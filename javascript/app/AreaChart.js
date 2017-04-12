//AreaSeries.js

'use strict';
define(["d3", "app/BaseChart", "app/ConditionalLines"],
  function(d3, BaseChart,ConditionalLines) {
     var AreaChart = function() {
       BaseChart.call(this);
      this.xDomain = [0, 10];
      this.yDomain = [0, 6];
      this.height = 56.5;
      this.yMargin = 20;
      this.xMargin = 20;
      this.setConditionType(ConditionalLines);

    };

    AreaChart.prototype = new BaseChart();

    AreaChart.prototype.constructor = AreaChart;


    AreaChart.prototype.render = function() {
      var self = this;
      this.container
        .transition().duration(500)
        .attr("width", this.width+this.xMargin)
        .attr("height", this.height+this.yMargin)
        .attr("transform", "translate(" + this.x + "," + this.y + ")");
      this.renderAxes();
      var area = d3.svg.area()
        .x(self.xMap(self))
        .y0(this.height)
        .y1(self.yMap(self))
        .interpolate("linear");
    var path;
    if (this.container.selectAll(".area")[0].length < 1) {
     path = this.container.append("path")
      
        .attr("class", "area")
        .attr("d", area(this.data))
        .attr("fill", "blue");
        path.attr("clip-path", "url(#clip"+this.id+")");

      }
      else{
        path =  this.container.selectAll(".area")
        .transition().duration(500)
        .attr("d", area(this.data))
        .attr("clip-path", "url(#clip"+this.id+")");

      }

    if(this.container.selectAll(".condGroup")[0].length<1){
      
      var bbox = path.node().getBBox();
      for(var i=0;i<this.conditions.length;i++){
      var condGroup = this.container.append("g")
      .attr("class", "condGroup")
      .attr("id", "cond_"+this.id)
      .attr("clip-path", "url(#clip"+this.id+")");
     this.conditions[i].setTarget(condGroup)
      .setWidth(this.width+this.xMargin)
      .setHeight(this.height+this.yMargin)
      .setRectDimensions(bbox);
      }   
    }
     for(var j=0;j<this.conditions.length;j++){
      this.conditions[j].render();
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
   
    return AreaChart;

  });

