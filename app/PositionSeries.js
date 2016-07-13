//PositionSeries.js
'use strict';
define(["d3", "app/BaseChart", "app/PositionChart"],
	function(d3, BaseChart, PositionChart) {
		var PositionSeries = function() {
		  BaseChart.call(this);	
      this.xDomain = [0,10];
      this.yDomain = [0,1];	
      this.height = 56.5;
      this.xAxis = d3.svg.axis()
        .scale(this.xScale())
        .orient("bottom")
        .innerTickSize(-this.height)
        .outerTickSize(0)
        .tickPadding(10);
    };

    PositionSeries.prototype = new BaseChart();

    PositionSeries.prototype.constructor = PositionSeries;

    PositionSeries.prototype.addSingleChild = function(data){
      var child = new PositionChart();
      child.setData(data.position);
      child.setX(this.xMap(this)(data.time));
      this.children.push(child);

      console.log("x pos",this.xMap(this)(data.time));
      return this;
    };


    PositionSeries.prototype.generate = function() {
      BaseChart.prototype.generate.call(this);
    };
     

      
    PositionSeries.prototype.generateChildren = function() { 
      var graphGroup = this.container.append("g");

      var split =76;
      var currentPos = 0;
      for (var i = 0; i < this.children.length; i+=25) {
        if(i===0){
         this.children[i].setTarget(graphGroup).generate();
          currentPos = this.children[i].x+split;
        }
        else{
          if(this.children[i].x>=currentPos){
             this.children[i].setTarget(graphGroup).generate();
             currentPos = this.children[i].x+split;
          }
        }
      }
    };

     PositionSeries.prototype.renderChildren = function() { 
            
      var split =76;
      var currentPos = 0;
      for (var i = 0; i < this.children.length; i+=25) {
        if(i===0){
         this.children[i].render();
          currentPos = this.children[i].x+split;
        }
        else{
          if(this.children[i].x>=currentPos){
             this.children[i].render();
             currentPos = this.children[i].x+split;
          }
        }
      }
    };


		
		return PositionSeries;

	});