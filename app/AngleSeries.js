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
      this.children.push(child);
      return this;
    };


    return AngleSeries;


  });