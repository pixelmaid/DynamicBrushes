'use strict';
define(["jquery","paper", "app/graph"],
    function($, paper, Graph) {
    
        /*var canvas = document.getElementById('canvas');

        function resizeCanvas() {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
        }

        resizeCanvas();
        paper.install(window);
        paper.setup(canvas);*/

        let pressureGraph = new Graph(700,200);
    // if user is running mozilla then use it's built-in WebSocket
    

    window.WebSocket = window.WebSocket || window.MozWebSocket;

    var connection = new WebSocket('ws://10.8.0.205:8080/',"desktop_client");



    connection.onopen = function () {
        console.log('connection opened');
        connection.send('desktop')
    };

    connection.onerror = function (error) {
                console.log('connection error',error);

        // an error occurred when sending/receiving data
    };

    connection.onmessage = function (message) {
        // try to decode json (I assume that each message from server is json)
          //try {
                var json = JSON.parse(message.data);
                //console.log("message recieved",message, json);

                pressureGraph.tick(json.pressure,json.time);

            //} catch (e) {
               // console.log('This doesn\'t look like a valid JSON: ', message);
               //return;
           //}

        // handle incoming message
    };
});