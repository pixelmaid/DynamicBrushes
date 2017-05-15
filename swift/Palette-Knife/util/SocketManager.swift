//
//  SocketManager.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 6/27/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON
import Starscream

//central manager for all requests to web socket
class SocketManager: WebSocketDelegate{
     var socket = WebSocket(url: NSURL(string: "ws://dynamic-brushes.herokuapp.com/")! as URL, protocols: ["drawing_user1"])
    //var socket = WebSocket(url: NSURL(string: "ws://localhost:5000")!, protocols: ["ipad_client"])
    var dataEvent = Event<(String,JSON?)>();
    var requestEvent = Event<(String,JSON?)>();

    var firstConnection = true;
    var targets = [WebTransmitter](); //objects which can send or recieve data
    var startTime:NSDate?
    var dataQueue = [JSON]();
    var transmitComplete = true;
    var pingInterval:Timer!;
    let dataKey = NSUUID().uuidString;
    
    init(){
             socket.delegate = self;


    }
    
    @objc func pingIntervalCallback(){
        socket.write(string:"{\"name\":\"ping\"}")
    }
    
    func connect(){
        socket.connect()
    }
    
    
    // MARK: Websocket Delegate Methods.
    
    func websocketDidConnect(socket ws: WebSocket) {
        print("websocket is connected")
        //send name of client
        pingInterval = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(SocketManager.pingIntervalCallback), userInfo: nil, repeats: true)
          socket.write(string:"{\"name\":\"drawing\"}")
        if(firstConnection){
            requestEvent.raise(data: ("first_connection",nil));
        }
        else{
            requestEvent.raise(data: ("connected",nil));
        }
    }
    
    func websocketDidDisconnect(socket ws: WebSocket, error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
            
        }
        //TODO: might not be threadsafe?
        requestEvent.raise(data: ("disconnected",nil));
        dataEvent.raise(data: ("disconnected",nil));
        
    }
    
    func websocketDidReceiveMessage(socket ws: WebSocket, text: String) {
        if(text == "message received"){
            requestEvent.raise(data: ("text",nil));

            objc_sync_enter(dataQueue)

            if(dataQueue.count>0){
                
                 socket.write(string:dataQueue.remove(at: 0).rawString()!);
            }
            else{
                
                transmitComplete = true;
            }
            objc_sync_exit(dataQueue);
        }
            
        else if (text == "authoring_client_connected"){
           dataEvent.raise(data: ("authoring_client_connected",JSON([])))
        }
            
        else{
            if let dataFromString = text.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                let type = json["type"].stringValue;
                dataEvent.raise(data: (type,json))
            }
        }
    }
    
    func websocketDidReceiveData(socket ws: WebSocket, data: Data) {
    
    }
    
    
    // MARK: Disconnect Action
    
    func disconnect() {
        if socket.isConnected {
            
            socket.disconnect()
        }
    }
    
    
   /* func sendBehaviorData(data:JSON){
        let json_string = data.rawString();
        let string = "{\"type\":\"behavior_data\",\"data\":"+json_string!+"}"
        if(transmitComplete){
            transmitComplete = false;
              socket.write(string:string)
            
        }
        else{
            
            objc_sync_enter(dataQueue)
            dataQueue.append(string)
            objc_sync_exit(dataQueue)

        }
    }*/
    
    func sendData(data:JSON){
        let dataString = data.rawString();
        if(transmitComplete){
            transmitComplete = false;
             socket.write(string:dataString!)
            
        }
        else{
            
            objc_sync_enter(dataQueue)
            dataQueue.append(data)
            objc_sync_exit(dataQueue)
            
        }
    }


    
    
    
    
}
