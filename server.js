'use strict';
const express = require('express');
const SocketServer = require('ws').Server;
const path = require('path');


// list of currently connected clients
var drawing_clients = {};
var authoring_clients = {};
var keys = ["jen","fish","ben"];

const PORT = process.env.PORT || 3000;
const INDEX = path.join(__dirname, 'index.html');

const server = express()
	.use((req, res) => res.sendFile(INDEX))
	.listen(PORT, () => console.log(`Listening on ${ PORT }`));

const wss = new SocketServer({
	server
});

wss.on('connection', (ws) => {
	console.log('Client connected', ws.protocol);
	
	var userkey = ws.protocol.split("_")[1];
	if(keys.find(function(e){return e == userkey;})){
	var protocol = ws.protocol;
	
	var connection = ws;
	var clientName = ws.protocol.split("_")[0];
	if (clientName == 'drawing') {
		drawing_clients[userkey] = connection;

		if (authoring_clients[userkey]) {
			authoring_clients[userkey].send("drawing client connected");
		}


	}  else if (clientName == 'authoring') {
		authoring_clients[userkey] = connection;
		if (drawing_clients[userkey]) {
			console.log("sending authoring connected message");
			drawing_clients[userkey].send("authoring_client_connected");
		}
	} 

	ws.on('message', function incoming(message) {
		console.log('message', clientName, userkey, message);

		var json_data = JSON.parse(message);
		 if (json_data.type == "synchronize" || json_data.type == "behavior_data" || json_data.type == "authoring_response" || json_data.type == "storage_data" ) {
			if (authoring_clients[userkey]) {
				authoring_clients[userkey].send(JSON.stringify(json_data));
			}
		}

		if (json_data.type == "brush_init") {
			ws.send("init_data_received");
		} else {
			ws.send("message received");
		}

		if (json_data.type == "data_request" || json_data.type == "synchronize_request" || json_data.type == "authoring_request" || json_data.type == "storage_request") {
			if(json_data.requester == "authoring" && authoring_clients[userkey] && drawing_clients[userkey]){
				console.log("requesting authoring response from drawing client");
				drawing_clients[userkey].send(JSON.stringify(json_data));
			}
		}


	});


	ws.on('close', function close() {
		console.log(clientName +' '+userkey+ 'client disconnected');
		
		if (clientName == "authoring") {
			delete authoring_clients[userkey];
		}
		if (clientName == "drawing") {
			delete drawing_clients[userkey];
		} 
	});
}	
else{
	console.log("key not recognized");
}
});