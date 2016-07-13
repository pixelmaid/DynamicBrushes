//PositionSeries.js
'use strict';
define(["d3", "app/BaseChart", "app/PositionChart"],
  function(d3, BaseChart, PositionChart) {
    var PositionSeries = function() {
      BaseChart.call(this);
      this.xDomain = [0, 10];
      this.yDomain = [0, 1];
      this.height = 56.5;
     
      document.onkeydown = checkKey;
      var self = this;

      function checkKey(e) {
        var start, end;
        e = e || window.event;

        if (e.keyCode == '38') {
          // up arrow
        } else if (e.keyCode == '40') {
          // down arrow
        } else if (e.keyCode == '37') {
          start = self.xDomain[0] - 1;//; < 0 ? 0 : self.xDomain[0] - 10;
          end = self.xDomain[1]-1;
          self.setXDomain([start, end]).render();
        } else if (e.keyCode == '39') {
          start = self.xDomain[0]+1;
          end = self.xDomain[1]+ 1; //<0?0:self.xDomain[0]-10;
          self.setXDomain([start, end]).render();
        }

      }
    };

    PositionSeries.prototype = new BaseChart();

    PositionSeries.prototype.constructor = PositionSeries;

    PositionSeries.prototype.addSingleChild = function(data) {
      var child = new PositionChart();
      child.setData(data.position);
      this.children.push(child);
      return this;
    };


    PositionSeries.prototype.generateChildren = function() {
      var graphGroup = this.container.append("g");

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
          var x = this.xMap(this)(this.data[i].time);
        if ((i === 0) || (x >= currentPos)) {
        
          console.log(x,this.data[i].time,i);
          this.children[i].setX(x).render();
         
            currentPos = x + split;
          
        }
      }
    };



    return PositionSeries;

  });