'use strict';
define(["d3", "app/PositionSeries", "app/AngleChart"],
  function(d3, PositionSeries, AngleChart) {
    var AngleSeries = function() {
      PositionSeries.call(this);

    };

    AngleSeries.prototype = new PositionSeries();

    AngleSeries.prototype.constructor = AngleSeries;

     AngleSeries.prototype.addSingleChild = function(data) {
      var child = new AngleChart();
      child.setData(data.angle);
            child.parent = this;

      this.children.push(child);
      return this;
    };
     AngleSeries.prototype.renderChildren = function() {

      var split = 76;
      var currentPos = 0;
      for (var i = 0; i < this.children.length; i += 25) {
          var x = this.xMap(this)(this.data[i].time)+this.xMargin;
          var y = this.yMargin;
        if ((i === 0) || (x >= currentPos)) {
        
          this.children[i].setX(x).setY(y).render();
         
            currentPos = x + split;
          
        }
      }
    };

    return AngleSeries;


  });