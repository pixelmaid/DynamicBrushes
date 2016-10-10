'use strict';
define(["jquery", "paper", "app/ChartView", "app/graph", "app/PositionSeries", "app/AngleSeries", "app/AreaChart"],
    function($, paper, ChartView, Graph, PositionSeries, AngleSeries, AreaChart) {

        var testData = {
            "type": "behavior_data",
            "data": {
                "states": [{
                    "id": "B2DD7015-CC0B-4D10-BC88-5EBB8ED83A9E",
                    "name": "delay",
                    "mappings": []
                }, {
                    "id": "AA48D8F4-C051-42DC-AEFB-D80DE70589DF",
                    "name": "grow",
                    "mappings": [{
                        "id": "ABF5AB6B-9BAC-4F36-AEDD-209C0C1C1C42",
                        "reference": "parent.yBuffer",
                        "relative": "dy",
                        "state": "grow"
                    }, {
                        "id": "67063053-E911-4AF4-9287-CD876B4735F5",
                        "reference": "angleIncrememt",
                        "relative": "angle",
                        "state": "grow"
                    }, {
                        "id": "542C3724-52D0-471B-B16C-D50D8D1DEB01",
                        "reference": "parent.xBuffer",
                        "relative": "dx",
                        "state": "grow"
                    }]
                }, {
                    "id": "55BCF18C-056D-48EB-8C53-AE2E94B32A00",
                    "name": "reflect",
                    "mappings": []
                }, {
                    "id": "B7E8331F-8652-4BAF-B0D9-CA74A10889B7",
                    "name": "spawn",
                    "mappings": []
                }, {
                    "id": "AC78ECF9-A70A-4BA8-A63B-EBC92BCD3694",
                    "name": "die",
                    "mappings": []
                }],
                "transitions": [{
                    "id": "38752B01-0FAF-4819-8FD4-76F49B0C8153",
                    "name": "growSpawnTransition",
                    "fromState": "B7E8331F-8652-4BAF-B0D9-CA74A10889B7",
                    "toState": "AC78ECF9-A70A-4BA8-A63B-EBC92BCD3694"
                }, {
                    "id": "62959EEB-F601-4310-83D6-C92676DB639E",
                    "name": "reflectTransition",
                    "fromState": "default",
                    "toState": "reflect"
                }, {
                    "id": "877268D8-94B4-4241-A981-C652EAE97968",
                    "name": "defaultDelayTransition",
                    "fromState": "default",
                    "toState": "B2DD7015-CC0B-4D10-BC88-5EBB8ED83A9E"
                }, {
                    "id": "A8AA4592-9FDA-46D1-9BD1-2AFD5CE64741",
                    "name": "reflectEndTransition",
                    "fromState": "reflect",
                    "toState": "default"
                }, {
                    "id": "EAEAD888-9BD3-44B3-B942-D4B3EC2EFFD9",
                    "name": "growEndTransition",
                    "fromState": "grow",
                    "toState": "delay"
                }, {
                    "id": "7EA1E1DF-D2E0-48B0-B0FB-70E901C10D45",
                    "name": "intervalTransition",
                    "fromState": "delay",
                    "toState": "grow"
                }, {
                    "id": "E76DBA6B-66E1-4E7D-9B40-9A0F82FDD094",
                    "name": "startSpawnTransition",
                    "fromState": "grow",
                    "toState": "spawn"
                }]
            }
        };
        var chartViews = {};
        //chartView.initializeBehavior(testData.data);



        // if user is running mozilla then use it's built-in WebSocket


        window.WebSocket = window.WebSocket || window.MozWebSocket;
        var HOST = 'ws://localhost:5000';
        //var HOST = 'ws://pure-beach-75578.herokuapp.com/';
        var connection = new WebSocket(HOST, "authoring");



        connection.onopen = function() {
            console.log('connection opened');
            connection.send(JSON.stringify({
                name: 'authoring'
            }));
        };

        connection.onerror = function(error) {
            console.log('connection error', error);

            // an error occurred when sending/receiving data
        };

        connection.onmessage = function(message) {
            // try to decode json (I assume that each message from server is json)
            try {
                var data = JSON.parse(message.data);
                console.log("data.type", data.type);

                if (data.type == "behavior_data") {
                    var chartView = new ChartView(data.data.id);
                    chartViews[data.data.id] = chartView;
                    chartView.initializeBehavior(data.data);

                } else if (data.type == "behavior_change") {
                    if(chartViews[data.behavior_id]){
                        console.log("behavior found for ",data.brush_name);
                        chartViews[data.behavior_id].behaviorChange(data.event,data.data);
                    }
                }
            } catch (error) {
                console.log("error:", error,message.data);
            }
        };

    });



/*var canvas = document.getElementById('canvas');

function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
}

resizeCanvas();
paper.install(window);
paper.setup(canvas);*/

/* var testData = [{
     time: 3.43573,
     pressure: 0,
     angle: 0,
     penDown: true,
     speed: 0,
     position: {
         x: 635,
         y: 779.5
     }
 }, {
     time: 3.4621,
     pressure: 0.694499,
     angle: 0.394383,
     penDown: true,
     speed: 958.418,
     position: {
         x: 612,
         y: 776.5
     }
 }, {
     time: 3.46552,
     pressure: 0.714583,
     angle: 0.393666,
     penDown: true,
     speed: 498.768,
     position: {
         x: 609,
         y: 776
     }
 }];

let distanceGraph = new Graph(450, 200, 10, 1000, "red", "stroke_graphs", "distance");
 let strokeGraph = new Graph(450, 200, 10, 15, "blue", "stroke_graphs", "stroke count");

 let xGraph = new Graph(450, 200, 2, 1000, "green", "stroke_graphs", "x position");
 let yGraph = new Graph(450, 200, 2, 900, "orange", "stroke_graphs", "y position");

 let pressure = new Graph(450, 200, 2, 6, "orange", "stylus_graphs", "pressure");
 let stylusXGraph = new Graph(450, 200, 2, 1000, "green", "stylus_graphs", "x position");
 let stylusYGraph = new Graph(450, 200, 2, 1000, "orange", "stylus_graphs", "y position");
 let speedGraph = new Graph(450, 200, 15, 25, "orange", "stylus_graphs", "speed");

 var positionSeries = new PositionSeries();
 var angleSeries = new AngleSeries();
 var pressureChart = new AreaChart();
 var speedChart = new AreaChart();


 //var json = $.getJSON("app/sample_stylus_data.json", stylusDataLoaded);


 positionSeries.setWidth(1000).setHeight(170);
 angleSeries.setWidth(1000).setHeight(70);
 pressureChart.setWidth(1000).setHeight(70);
 speedChart.setWidth(1000).setHeight(70).setYDomain([0,1500]);


 var toScroll = [positionSeries, angleSeries,pressureChart,speedChart];
 document.onkeydown = checkKey;


 function checkKey(e) {
     var start, end;
     e = e || window.event;

     for (var i = 0; i < toScroll.length; i++) {
         var self = toScroll[i];
         if (e.keyCode == '38') {
             // up arrow
         } else if (e.keyCode == '40') {
             // down arrow
         } else if (e.keyCode == '37') {
             start = self.xDomain[0] - 1; //; < 0 ? 0 : self.xDomain[0] - 10;
             end = self.xDomain[1] - 1;
             self.setXDomain([start, end]);
         } else if (e.keyCode == '39') {
             start = self.xDomain[0] + 1;
             end = self.xDomain[1] + 1; //<0?0:self.xDomain[0]-10;
             self.setXDomain([start, end]);
         }
     }
     for (i = 0; i < toScroll.length; i++) {
         toScroll[i].render();
     }
 }

 // if user is running mozilla then use it's built-in WebSocket


 window.WebSocket = window.WebSocket || window.MozWebSocket;

 //var connection = new WebSocket('ws://10.8.0.205:8080/', "desktop_client");



 connection.onopen = function() {
     console.log('connection opened');
     connection.send('desktop');
 };

 connection.onerror = function(error) {
     console.log('connection error', error);

     // an error occurred when sending/receiving data
 };

 connection.onmessage = function(message) {
     // try to decode json (I assume that each message from server is json)
     //try {
     var data = JSON.parse(message.data);
     console.log("data.type", data.type);

     if (data.type == "stroke_data") {
         graphStroke(data);
     } else if (data.type == "stylus_data") {
         graphStylus(data);
     }
 };

 function loadData(file) {

 }

 function stylusDataLoaded(json) {
     console.log("total datapoints", json.drawings.length);
     var positionData = json.drawings.map(function(d, rank) {
         var position = [d.position];
         var stop = rank - 1 - 200 > 0 ? rank - 1 - 200 : 0;
         for (var i = rank - 1; i > stop; i -= 4) {
             if (i >= 0) {
                 position.unshift(json.drawings[i].position);
             }
         }
         //console.log(position)
         return {
             time: {
                 x: d.time,
                 y: 0
             },
             position: position
         };

     });

     var angleData = json.drawings.map(function(d, rank) {
         var angle = d.angle * 180 / Math.PI;
         return {
             time: {
                 x: d.time,
                 y: 0
             },
             angle: [{
                 x: angle,
                 y: 0
             }]
         };

     });

     var pressureData = json.drawings.map(function(d, rank) {
         return {x:d.time,y:d.pressure};
     });
       var speedData = json.drawings.map(function(d, rank) {
         return {x:d.time,y:d.speed};
     });

     positionSeries.addChild(positionData).generate();
     positionSeries.render();
     angleSeries.addChild(angleData).generate();
     angleSeries.render();
     speedChart.setData(speedData).generate();
     speedChart.render();
     pressureChart.setData(pressureData).generate();
     pressureChart.render();
     
 }

 function graphStylus(json) {
     var data = json.drawings;
     var pressureData = data.map(function(d, rank) {
         return {
             x: d.time,
             y: d.pressure
         };
     });
     var speedData = data.map(function(d, rank) {
         return {
             x: d.time,
             y: d.speed
         };
     });
     //pressure.setData([pressureData]);
     //speedGraph.setData([speedData]);


 }

 function graphStroke(data) {

     var drawings = data.drawings;
     var strokes = drawings[0].strokes;

     var strokeData = strokes.map(function(stroke, rank) {

         return {
             x: stroke.time,
             y: rank
         };
     });

     var distanceData = strokes.map(function(stroke, rank) {
         return stroke.lengths.map(function(length, rank) {
             return {
                 x: length.time,
                 y: length.length
             };
         });
     });
     distanceData = [].concat.apply([], distanceData);

     var xPositionData = strokes.map(function(stroke, rank) {
         return stroke.segments.map(function(segment, rank) {

             return {

                 x: segment.time,
                 y: segment.point.x,
             };
         });
     });

     var yPositionData = strokes.map(function(stroke, rank) {
         return stroke.segments.map(function(segment, rank) {

             return {
                 x: segment.time,
                 y: segment.point.y

             };
         });
     });*/

//console.log("strokeData", strokeData);
//console.log("distanceData", distanceData);

//distanceGraph.setData([distanceData]);
//xGraph.setData(xPositionData);
//yGraph.setData(yPositionData);
//strokeGraph.setData([strokeData]);



//lengthGraph.setData(lengthData);
//var penState = json.penDown == true? 1:0;
//deltaGraph.tick(penState,json.time);


//} catch (e) {
// console.log('This doesn\'t look like a valid JSON: ', message);
//return;
//}

// handle incoming message