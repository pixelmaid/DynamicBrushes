'use strict';
define(["jquery", "paper", "app/graph"],
    function($, paper, Graph) {

        /*var canvas = document.getElementById('canvas');

        function resizeCanvas() {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
        }

        resizeCanvas();
        paper.install(window);
        paper.setup(canvas);*/

        let distanceGraph = new Graph(450, 200, 10, 1000, "red", "stroke_graphs","distance");
        let strokeGraph = new Graph(450, 200, 10, 15, "blue","stroke_graphs","stroke count");

        let xGraph = new Graph(450, 200, 2, 1000, "green","stroke_graphs","x position");
        let yGraph = new Graph(450, 200, 2, 900, "orange","stroke_graphs","y position");

        let pressure = new Graph(450, 200, 2, 900, "orange","stylus_graphs","pressure");

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
            if (data.type == "stroke_data") {

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
                });

                //console.log("strokeData", strokeData);
                //console.log("distanceData", distanceData);

                distanceGraph.setData([distanceData]);
                xGraph.setData(xPositionData);
                yGraph.setData(yPositionData);
                strokeGraph.setData([strokeData]);



            }


            //lengthGraph.setData(lengthData);
            //var penState = json.penDown == true? 1:0;
            //deltaGraph.tick(penState,json.time);


            //} catch (e) {
            // console.log('This doesn\'t look like a valid JSON: ', message);
            //return;
            //}

            // handle incoming message
        };
    });