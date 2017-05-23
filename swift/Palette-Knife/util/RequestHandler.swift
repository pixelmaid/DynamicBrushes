//
//  RequestHandler.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 4/13/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON

class RequestHandler{
    
    static let saveManager = SaveManager();
    static let socketManager = SocketManager();
    static var requestQueue = [Request]()
    static var dataQueue = [(String,JSON?)]()
    static var dataEvent = Event<(String,JSON?)>();
    
    static let socketKey = NSUUID().uuidString
    static let storageKey = NSUUID().uuidString
    static let sharedInstance = RequestHandler()
    
    static var activeItem:Request?
    
    static func addRequest(requestData:Request){
        print("adding request",requestData)
        requestQueue.append(requestData);
        if(activeItem == nil){
            print("active item is nil, checking request")
            checkRequest();
        }
    }
    
    
    init(){
        
        _ = RequestHandler.socketManager.dataEvent.addHandler(target:self,handler: RequestHandler.socketDataHandler, key:RequestHandler.socketKey)
        _ = RequestHandler.saveManager.dataEvent.addHandler(target:self,handler: RequestHandler.saveDataHandler, key:RequestHandler.storageKey)
    }
    
    static func checkRequest(){
        print("checking request, activeitem: \(RequestHandler.activeItem == nil), requestQueue: \(requestQueue.count), dataQueue: \(dataQueue.count)")
        if(RequestHandler.activeItem == nil){
            if requestQueue.count>0 {
                sharedInstance.handleRequest();
            }
            else if dataQueue.count>0{
                sharedInstance.handleData();
            }
        }
        
    }
    
    private func handleRequest(){
        if(RequestHandler.requestQueue.count>0){
            let request = RequestHandler.requestQueue.removeFirst()
            RequestHandler.activeItem = request as Request
            print("setting handler to nil active item \(RequestHandler.activeItem?.action)")

            switch(RequestHandler.activeItem!.target){
            case "socket":
                
                _ = RequestHandler.socketManager.requestEvent.addHandler(target:self, handler:RequestHandler.socketRequestHandler,key:RequestHandler.socketKey)
                switch RequestHandler.activeItem!.action{
                case "connect":
                    RequestHandler.socketManager.connect();
                    break;
                case "disconnect":
                    RequestHandler.socketManager.disconnect();
                    break;
                case "send_storage_data":
                    let data = RequestHandler.activeItem!.data!
                    var send_data:JSON = [:]
                    send_data["data"] = data;
                    send_data["type"] = JSON("storage_data")
                    RequestHandler.socketManager.sendData(data: send_data);
                    break;
                case "authoring_response":
                    let data = RequestHandler.activeItem!.data!
                    print("sending authoring response \(data)");
                    RequestHandler.socketManager.sendData(data: data);

                    break;
                case "synchronize":
                    let data = RequestHandler.activeItem!.data!
                    var send_data:JSON = [:]
                    send_data["data"] = data;
                    send_data["type"] = JSON("synchronize")
                    RequestHandler.socketManager.sendData(data: send_data);
                    break
                default:
                    break;
                }
                break;
                
            case "storage":
                _ = RequestHandler.saveManager.requestEvent.addHandler(target:self, handler:RequestHandler.saveRequestHandler,key:RequestHandler.storageKey)
                switch RequestHandler.activeItem!.action{
                    
                case "configure":
                    RequestHandler.saveManager.configure();
                    break;
                    
                case "upload":
                    RequestHandler.saveManager.uploadFile(uploadData:RequestHandler.activeItem!.data!)
                    break;
                    
                case "upload_image":
                    RequestHandler.saveManager.uploadImage(uploadData:RequestHandler.activeItem!.data!)
                    break;
                case "download":
                    RequestHandler.saveManager.downloadFile(downloadData:RequestHandler.activeItem!.data!)
                    break;
                case "download_image":
                    RequestHandler.saveManager.downloadImage(downloadData:RequestHandler.activeItem!.data!)
                    break;
                    
                case "filelist":
                    let targetFolder = RequestHandler.activeItem!.data!["targetFolder"].stringValue
                    let list_type = RequestHandler.activeItem!.data!["list_type"].stringValue
                    RequestHandler.saveManager.accessFileList(targetFolder: targetFolder,list_type:list_type, uploadData: nil)
                    break;
                default:
                    break;
                }
                
                break;
            default:
                break;
            }
        }
        else{
            RequestHandler.checkRequest();
            
        }
        
    }
    
    
    private func handleData(){
        print("handle data \(RequestHandler.dataQueue.count)")
        
        if(RequestHandler.dataQueue.count>0){
            let data = RequestHandler.dataQueue.removeFirst();
            print("handling data \(data)")
            
            RequestHandler.dataEvent.raise(data: data);
        }
        RequestHandler.checkRequest();
        
        
    }
    
    
    private func socketRequestHandler(data:(String,JSON?), key:String) {
        print("socket request handler called \(RequestHandler.activeItem)")
        
        if(RequestHandler.activeItem != nil){
            RequestHandler.socketManager.requestEvent.removeHandler(key: RequestHandler.socketKey)
            
            RequestHandler.activeItem?.requester.processRequest(data:data)
            print("setting handler to nil \(RequestHandler.activeItem?.action)")
            RequestHandler.activeItem = nil;

            RequestHandler.checkRequest();
            
        }
        else {
            print("error, socket request does not exist");
        }
    }
    
    private func saveRequestHandler(data:(String,JSON?), key:String) {
        print("save request handler called \(RequestHandler.activeItem)")
        if(RequestHandler.activeItem != nil){
            let activeItem = RequestHandler.activeItem;
            RequestHandler.saveManager.requestEvent.removeHandler(key: RequestHandler.storageKey)
            activeItem?.requester.processRequest(data:data)
            print("setting handler to nil \(RequestHandler.activeItem?.action)")

            RequestHandler.activeItem = nil;

            RequestHandler.checkRequest();
            
        }
        else {
            print("error, save request does not exist");
        }
    }
    
    private func saveDataHandler(data:(String,JSON?), key:String){
        print("save data handler called \(data.0,data.1?["type"].stringValue,RequestHandler.activeItem == nil )")

        //RequestHandler.dataQueue.append(data);
        RequestHandler.checkRequest();
    }
    
    private func socketDataHandler(data:(String,JSON?), key:String){
        if(data.1 != nil){
            print("socket data handler called \(data.0,data.1?["type"].stringValue,RequestHandler.activeItem == nil )")
        }
        
        RequestHandler.dataQueue.append(data);
        RequestHandler.checkRequest();
    }
    
    
    
    
    
}


struct Request{
    
    let target:String
    let action:String
    let data:JSON?
    let requester:Requester
}

protocol Requester{
    func processRequest(data:(String,JSON?))
    
    func processRequestHandler(data: (String, JSON?), key: String)
    
}
