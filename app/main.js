'use strict';
define(["jquery", "paper", "app/ChartView", "app/graph", "app/PositionSeries", "app/AngleSeries", "app/AreaChart"],
    function($, paper, ChartView, Graph, PositionSeries, AngleSeries, AreaChart) {

        var testData ={
    "type": "behavior_data",
    "data": {
        "states": [{
            "id": "244DBDBB-55D3-49BF-A54F-B223E2818884",
            "name": "spawn",
            "mappings": []
        }, {
            "id": "388A5C7C-20C0-44C8-9CB3-BB1B5CE3C45E",
            "name": "die",
            "mappings": []
        }, {
            "id": "796A74F1-9940-4F92-B751-605E12A40265",
            "name": "delay",
            "mappings": []
        }, {
            "id": "1DA1F98C-0A1D-4EAC-A5F7-F678F09CE92F",
            "name": "grow",
            "mappings": [{
                "id": "EEEC3BCA-90B7-4448-8EAA-A9EE17CFB8CC",
                "reference": "parent.yBuffer",
                "relative": "dy",
                "state": "grow"
            }, {
                "id": "96388600-6CC9-429B-99C6-3CC1699C5AEF",
                "reference": "angleIncrememt",
                "relative": "angle",
                "state": "grow"
            }, {
                "id": "70A32FA0-C502-4C58-AEC0-2CB78B84A5C1",
                "reference": "parent.xBuffer",
                "relative": "dx",
                "state": "grow"
            }]
        }, {
            "id": "B2A806B3-00B3-44AD-9C85-201F0A168019",
            "name": "reflect",
            "mappings": []
        } ],
        "transitions": []
    }
};



        var chartView = new ChartView();
    chartView.initializeBehavior(testData.data);



        // if user is running mozilla then use it's built-in WebSocket


        window.WebSocket = window.WebSocket || window.MozWebSocket;

        var connection = new WebSocket('ws://10.8.0.205:8080/', "desktop_client");



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
            console.log("data.type", data.type, data);

            if (data.type == "behavior_data") {
                chartView.initializeBehavior(data);

            } else if (data.type == "behavior_progression") {

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