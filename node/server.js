'use strict';
var WebSocketServer = require('websocket').server;
var http = require('http');

// list of currently connected clients
var ipad_client;
var desktop_client;
var clients = [];
var jsonfile = require('jsonfile');

var server = http.createServer(function(request, response) {
    // process HTTP request. Since we're writing just WebSockets server
    // we don't have to implement anything.
});
server.listen(8080, function() {
    var host = server.address().address;
    var port = server.address.port;
    console.log("running at ", host, ":", port);

});

// create the server
var wsServer = new WebSocketServer({
    httpServer: server
});

// WebSocket server

wsServer.on('request', function(request) {
    //console.log("request made", request.requestedProtocols);
    var protocol = request.requestedProtocols[0];
    var connection = request.accept(protocol, request.origin);
    var index = clients.push(connection) - 1;
    var clientName = false;

    // This is the most important callback for us, we'll handle
    // all messages from users here.
    connection.on('message', function(message) {
        if (message.type === 'utf8') {

            if (clientName === false) { // first message sent by user is their name
                // remember user name
                clientName = (message.utf8Data);
                if (clientName == 'ipad') {
                    ipad_client = connection;
                } else if (clientName == 'desktop') {
                    desktop_client = connection;
                }
                // get random color and send it back to the user

                console.log((new Date()) + 'client ' + clientName + ' is connected');

            } else { // log and broadcast the message
                var data = message.utf8Data;
                console.log('message', data);


               if (clientName == 'ipad') {
                    let json_data = JSON.parse(data);
                    console.log("message type", json_data.type);

                    if(json_data.type == "behavior_data"){
                         if (desktop_client) {
                            var behavior_data = JSON.stringify(json_data);
                            desktop_client.sendUTF(behavior_data);
                        }

                        
                    }
                    else{

                    var file = 'drawing_data/' + json_data.canvas_id + '.json';

                    if (json_data.type == "new_canvas") {
                        var obj = {
                            id: json_data.canvas_id,
                            name: json_data.canvas_name,
                            drawings: []
                        };

                        jsonfile.writeFile(file, obj, function(err) {
                            if (err) {
                                console.error("write file error=", err);
                            } else {
                                connection.sendUTF("message recieved");

                            }
                        });
                    } else {
                        console.log('type', json_data.type);

                        jsonfile.readFile(file, function(err, obj) {
                            if (err) {
                                console.error('file read error', err, file);
                                return;
                            }
                            var drawing_obj;
                            switch (json_data.type) {

                                case "new_drawing":
                                    drawing_obj = {
                                        id: json_data.drawing_id,
                                        strokes: [],
                                        intersections: []
                                    };
                                    obj.drawings.push(drawing_obj);
                                    //console.log("drawing obj",drawing_obj);
                                    break;
                                case "new_stroke":
                                case "stroke_data":
                                    //console.log("drawing obj",obj.drawings,json_data.drawing_id);

                                    drawing_obj = obj.drawings.find(function(o) {
                                        return o.id == json_data.drawing_id;
                                    });
                                    if (drawing_obj) {
                                        var stroke_obj;
                                        if (json_data.type == "new_stroke") {
                                            stroke_obj = {
                                                id: json_data.stroke_id,
                                                time: json_data.time
                                            };
                                            drawing_obj.strokes.push(stroke_obj);
                                        } else if (json_data.type == "stroke_data") {


                                            stroke_obj = drawing_obj.strokes.find(function(o) {
                                                return o.id == json_data.stroke_id;
                                            });
                                            //console.log("stroke object",stroke_obj, json_data.stroke_id);

                                            if (stroke_obj) {
                                                var stroke_data = json_data.strokeData;
                                                //console.log(stroke_data.lengths);
                                                for (var p in stroke_data) {
                                                    if (stroke_data.hasOwnProperty(p)) {
                                                        //console.log('stroke data property', p);

                                                        if (!stroke_obj[p]) {
                                                            stroke_obj[p] = [];
                                                        }
                                                        stroke_obj[p].push(
                                                            stroke_data[p]
                                                        );
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    break;
                                case "stylus_data":
                                    drawing_obj = obj.drawings;
                                    var stylus_data = json_data.stylusData;
                                    drawing_obj.push(stylus_data);
                                    break;


                            }
                            jsonfile.writeFile(file, obj, function(err) {
                                if (err) {
                                    console.error("write file error=", err);
                                } else {
                                    console.log('wrote file to', obj.name, obj, file);
                                    connection.sendUTF("message recieved");
                                    if (desktop_client) {
                                        obj.type = json_data.type;
                                        var graph_data = JSON.stringify(obj);
                                        desktop_client.sendUTF(graph_data);
                                    }


                                }
                            });

                        });
                        }


                    }
                }
            }
        }
    });

    connection.on('close', function(connection) {
        if (clientName == "ipad") {
            ipad_client = null;
        } else if (clientName == "desktop") {
            desktop_client = null;
        }
        clients.splice(index, 1);
        console.log((new Date()) + protocol + " disconnected.");


    });
});