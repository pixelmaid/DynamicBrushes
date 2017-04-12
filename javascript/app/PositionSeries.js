//PositionSeries.js
'use strict';
define(["d3", "app/BaseChart", "app/PositionChart"],
  function(d3, BaseChart, PositionChart) {
    var PositionSeries = function() {
      BaseChart.call(this);
      this.xDomain = [0, 10];
      this.yDomain = [1, 0];
      this.height = 56.5;
     
      
    };

    PositionSeries.prototype = new BaseChart();

    PositionSeries.prototype.constructor = PositionSeries;

    PositionSeries.prototype.addSingleChild = function(data) {
      var child = new PositionChart();
      child.setData(data.position);
      child.parent = this;

      this.children.push(child);
      return this;
    };

    PositionSeries.prototype.generate = function(){
      BaseChart.prototype.generate.call(this);
      this.generateChildren();
    }


    PositionSeries.prototype.generateChildren = function() {
      var graphGroup = this.container.append("g");
        graphGroup.attr("clip-path", "url(#clip"+this.id+")"); // clip the rectangle
      
      var split = 76;
      var currentPos = 0;
      for (var i = 0; i < this.children.length; i += 25) {
                  var x = this.xMap(this)(this.data[i].time);

        if ((i === 0) || (x >= currentPos)) {
          this.children[i].setTarget(graphGroup).generate();
          currentPos =x + split;
          
        }
      }
    };

  

    PositionSeries.prototype.renderChildren = function() {

      var split = 76;
      var currentPos = 0;
      for (var i = 0; i < this.children.length; i += 25) {
          var x = this.xMap(this)(this.data[i].time)+this.xMargin;
          var y = this.yMargin+this.height/2-this.children[i].height/2;
        if ((i === 0) || (x >= currentPos)) {
        
          this.children[i].setX(x).setY(y).render();
         
            currentPos = x + split;
          
        }
      }
    };



    return PositionSeries;

  });