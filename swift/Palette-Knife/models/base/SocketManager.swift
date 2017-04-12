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
     var socket = WebSocket(url: NSURL(string: "ws://pure-beach-75578.herokuapp.com/")! as URL, protocols: ["drawing"])
    //var socket = WebSocket(url: NSURL(string: "ws://localhost:5000")!, protocols: ["ipad_client"])
    var socketEvent = Event<(String,JSON?)>();
    var firstConnection = true;
    var targets = [WebTransmitter](); //objects which can send or recieve data
    var startTime:NSDate?
    var dataQueue = [String]();
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
            socketEvent.raise(data: ("first_connection",nil));
        }
        else{
            socketEvent.raise(data: ("connected",nil));
        }
    }
    
    func websocketDidDisconnect(socket ws: WebSocket, error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
            
        }
        socketEvent.raise(data: ("disconnected",nil));
        
    }
    
    func websocketDidReceiveMessage(socket ws: WebSocket, text: String) {
        //print("text = \(text)");
         if(text == "init_data_received" || text == "message received"){
            objc_sync_enter(dataQueue)

            if(dataQueue.count>0){
                
                 socket.write(string:dataQueue.remove(at: 0));
            }
            else{
                
                transmitComplete = true;
            }
            objc_sync_exit(dataQueue);
        }
        else if(text == "fabricator connected"){
          // self.sendFabricationConfigData();
        }
        else{
            if let dataFromString = text.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                let type = json["type"].stringValue;
                if(type == "fabricator_data"){
                    socketEvent.raise(data: ("fabricator_data",json))
                }
                else if(type == "data_request"){
                    print("data request")
                    socketEvent.raise(data: ("data_request",json))
                }
                else if (type == "authoring_request"){
                    print("authoring request")
                    socketEvent.raise(data: ("authoring_request",json))

                }
                
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
    
    
    func sendFabricationConfigData(){
        var source_string = "[\"VR, .2, .1, .4, 10, .1, .4, .4, 10, 1, .200, 100, .150, 65, 0, 0, .200, .250 \",";
        source_string += "\"SW, 2, , \","
        source_string += "\"FS, C:/Users/ShopBot/Desktop/Debug/\""
        source_string+="]"
        var   data = "{\"type\":\"gcode\","
        data += "\"data\":"+source_string+"}"
         socket.write(string:data)

    }
    
    func sendStylusData() {
        var string = "{\"type\":\"stylus_data\",\"canvas_id\":\""+stylus.id;
        string += "\",\"stylusData\":{"
        string+="\"time\":"+String(stylus.getTimeElapsed())+","
        string+="\"pressure\":"+String(describing: stylus.force)+","
        string+="\"angle\":"+String(describing: stylus.angle)+","
        string+="\"penDown\":"+String(describing: stylus.penDown)+","
        string+="\"speed\":"+String(stylus.speed)+","
        string+="\"position\":{\"x\":"+String(describing: stylus.position.x)+",\"y\":"+String(describing: stylus.position.y)+"}"
        // string+="\"delta\":{\"x\":"+String(delta.x)+",\"y\":"+String(delta.y)+"}"
        string+="}}"
        dataGenerated(data: string,key:"_")
    }
    
    func initAction(target:WebTransmitter, type:String){
        let data = "{\"type\":\""+type+"\",\"id\":\""+target.id+"\",\"name\":\""+target.name+"\"}";
        targets.append(target);
        target.transmitEvent.addHandler(target: self,handler: SocketManager.dataGenerated, key:dataKey);
        
        target.initEvent.addHandler(target: self,handler: SocketManager.initEvent, key:dataKey);
        
        self.dataGenerated(data: data,key:"_");
        
        
    }
    
    func initEvent(data:(WebTransmitter,String), key:String){
        self.initAction(target: data.0, type: data.1)
    }
    
    func dataGenerated(data:(String), key:String){
        if(transmitComplete){
            transmitComplete = false;
              socket.write(string:data)
            
        }
        else{
            objc_sync_enter(dataQueue)
            dataQueue.append(data)
            objc_sync_exit(dataQueue)
        }
    }
    
    
    func sendBehaviorData(data:(String)){
        let string = "{\"type\":\"behavior_data\",\"data\":"+data+"}"
        if(transmitComplete){
            transmitComplete = false;
              socket.write(string:string)
            
        }
        else{
            
            objc_sync_enter(dataQueue)
            dataQueue.append(string)
            objc_sync_exit(dataQueue)

        }
    }
    
    func sendData(data:String){
        
        if(transmitComplete){
            transmitComplete = false;
             socket.write(string:data)
            
        }
        else{
            
            objc_sync_enter(dataQueue)
            dataQueue.append(data)
            objc_sync_exit(dataQueue)
            
        }
    }


    
    
    
    
}
