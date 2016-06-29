//papergraph.js

'use strict';
define(["paper"],
  function(paper) {
    var PaperGraph = function(width, height) {

    	var xAxis = new paper.Group();
    	var axisLine = new paper.Path([new paper.Point(0,0),new paper.Point(width,0)]);
    	axisLine.strokeWidth = 1;
    	axisLine.strokeColor = 'black'
    	xAxis.addChild(axisLine);


    	var yAxis = new paper.Group();
    	var axisLine = new paper.Path([new paper.Point(0,0),new paper.Point(width,0)]);
    	axisLine.strokeWidth = 1;
    	axisLine.strokeColor = 'black'
    	xAxis.addChild(axisLine);



    }
    return PaperGraph;
 });
