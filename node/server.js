'use strict';
var WebSocketServer = require('websocket').server;
var http = require('http');
var ipad_connection, javascript_connection;

// list of currently connected clients
var ipad_client;
var desktop_client;
var clients = [];
var server = http.createServer(function(request, response) {
    // process HTTP request. Since we're writing just WebSockets server
    // we don't have to implement anything.
});
server.listen(8080, function() { });

// create the server
var wsServer = new WebSocketServer({
    httpServer: server
});

// WebSocket server

wsServer.on('request', function(request) {
    console.log("request made",request.requestedProtocols);
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
                if(clientName == 'ipad'){
                    ipad_client = connection;
                }
                else if(clientName == 'desktop'){
                    desktop_client = connection;
                }
                // get random color and send it back to the user
               
                console.log((new Date()) + 'client '+clientName + ' is connected');

            } else { // log and broadcast the message
              var data = message.utf8Data;
              console.log('message',data);
            if(clientName == 'ipad'){
                if(desktop_client){
                    desktop_client.sendUTF(String(data));
                }
            }
        }
    }
    });

    connection.on('close', function(connection) {
         if(clientName == "ipad"){
            ipad_client = null;
        }
        else if(clientName == "desktop"){
            desktop_client = null;
        }
        clients.splice(index, 1);
        console.log((new Date()) + protocol + " disconnected.");

         
    });
});
 
  