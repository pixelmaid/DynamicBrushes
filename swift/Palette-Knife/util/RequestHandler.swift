 //
//  RequestHandler.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 4/13/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON

final class RequestHandler: Requester{
    
    static let saveManager = SaveManager();
    static let socketManager = SocketManager();
    static var requestQueue = [Request]()
    static var dataQueue = [(String,JSON?)]()
    static var dataEvent = Event<(String,JSON?)>();
    
    static let socketKey = NSUUID().uuidString
    static let storageKey = NSUUID().uuidString

    static let sharedInstance = RequestHandler()
    static var activeItem:Request?
    static var inspectorObservables = [String:ObservableChangeLog]();
    static var inspectorEventDisposables = [String:Disposable]();
    static var inspectorTimer:Timer!
    
    static func addRequest(requestData:Request){
        requestQueue.append(requestData);
        if(activeItem == nil){
            checkRequest();
        }
    }
    
    
    
    init(){
        
        _ = RequestHandler.socketManager.dataEvent.addHandler(target:self,handler: RequestHandler.socketDataHandler, key:RequestHandler.socketKey)
        _ = RequestHandler.saveManager.dataEvent.addHandler(target:self,handler: RequestHandler.saveDataHandler, key:RequestHandler.storageKey)
    }
    
    static func checkRequest(){
        #if DEBUG
            
            //print("checking request, activeitem: \(RequestHandler.activeItem == nil), requestQueue: \(requestQueue.count), dataQueue: \(dataQueue.count)")
            //for val in requestQueue {
              //  print("request: \(val.action,val.requester, val.data)")
            //}
        #endif

        if(RequestHandler.activeItem == nil){
            if requestQueue.count>0 {
                sharedInstance.handleRequest();
            }
            else if dataQueue.count>0{
                sharedInstance.handleData();
            }
        }
        
    }
    
    static func emptyQueue(){
        RequestHandler.activeItem = nil
        requestQueue.removeAll();
        RequestHandler.socketManager.requestEvent.removeAllHandlers();
        RequestHandler.saveManager.requestEvent.removeAllHandlers();
        
    }
    
    func processRequest(data: (String,JSON?)){
        
    }
    
    func processRequestHandler(data:(String, JSON?), key: String){
    
    }
    
    private func handleRequest(){
        if(RequestHandler.requestQueue.count>0){
            let request = RequestHandler.requestQueue.removeFirst()
            RequestHandler.activeItem = request as Request

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
                case "send_inspector_data":
                    let data = RequestHandler.activeItem!.data!
                    var send_data:JSON = [:]
                    send_data["data"] = data;
                    send_data["type"] = JSON("inspector_data")
                    send_data["subData"] = "inspector";
                    RequestHandler.socketManager.sendData(data: send_data);
                    break;
                case "send_collection_data":
                    let data = RequestHandler.activeItem!.data!
                    var send_data:JSON = [:]
                    send_data["data"] = data;
                    send_data["type"] = JSON("collection_data")
                    RequestHandler.socketManager.sendData(data: send_data);
                    break;
                case "authoring_response":
                    let data = RequestHandler.activeItem!.data!
                    RequestHandler.socketManager.sendData(data: data);
                    break;
                    
                case "data_request_response":
                    let data = RequestHandler.activeItem!.data!
                    var send_data:JSON = [:]
                    //send_data["type"] = JSON("abcdefg")
                    send_data["type"] = JSON("data_request_response")
                    send_data["subData"] = "mapping_info";
                    send_data["data"] = data;
                    RequestHandler.socketManager.sendData(data: send_data);
                    print(send_data);
                    break;
                    
                case "synchronize":
                    let data = RequestHandler.activeItem!.data!
                    let requester = RequestHandler.activeItem!.requester as! DrawingViewController;
                    let currentBehaviorName = requester.currentBehaviorName;
                    let currentBehaviorFile = requester.currentBehaviorFile;

                    var send_data:JSON = [:]
                    send_data["data"] = data;
                    send_data["currentBehaviorName"] = JSON(currentBehaviorName)
                    send_data["currentFile"] = JSON(currentBehaviorFile)
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
                case "download_project_file":
                    RequestHandler.saveManager.downloadProjectFile(downloadData:RequestHandler.activeItem!.data!)
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
        
        if(RequestHandler.dataQueue.count>0){
            let data = RequestHandler.dataQueue.removeFirst();
            
            RequestHandler.dataEvent.raise(data: data);
        }
        RequestHandler.checkRequest();
        
        
    }
    
    
    private func socketRequestHandler(data:(String,JSON?), key:String) {
        #if DEBUG
        //print("socket request handler called \(String(describing: RequestHandler.activeItem))")
        #endif
        if(RequestHandler.activeItem != nil){
            RequestHandler.socketManager.requestEvent.removeHandler(key: RequestHandler.socketKey)
            
            RequestHandler.activeItem?.requester.processRequest(data:data)
            RequestHandler.activeItem = nil;
            print(data);

            RequestHandler.checkRequest();
            
        }
        else {
            #if DEBUG
            print("error, socket request does not exist");
            #endif
        }
    }
    
    private func saveRequestHandler(data:(String,JSON?), key:String) {
        #if DEBUG
        print("save request handler called \(String(describing: RequestHandler.activeItem),data.0)")
        #endif
        if(RequestHandler.activeItem != nil){
            let activeItem = RequestHandler.activeItem;
            RequestHandler.saveManager.requestEvent.removeHandler(key: RequestHandler.storageKey)
            activeItem?.requester.processRequest(data:data)

            RequestHandler.activeItem = nil;

            RequestHandler.checkRequest();
            
        }
        else {
            #if DEBUG
            print("error, save request does not exist");
            #endif
        }
    }
    
    private func saveDataHandler(data:(String,JSON?), key:String){
         #if DEBUG
        print("save data handler called \(data.0,data.1?["type"].stringValue,RequestHandler.activeItem == nil )")
        #endif
        //RequestHandler.dataQueue.append(data);
        RequestHandler.checkRequest();
    }
    
    private func socketDataHandler(data:(String,JSON?), key:String){
        if(data.1 != nil){
            #if DEBUG
           // print("socket data handler called \(data.0,data.1?["type"].stringValue,RequestHandler.activeItem == nil )")
            #endif
        }
        RequestHandler.dataQueue.append(data);
        RequestHandler.checkRequest();
    }
    
    
    static func registerObservable(observableId:String,observable:Observable<Float>){
        if(RequestHandler.inspectorObservables[observableId]==nil){
            RequestHandler.inspectorObservables[observableId] = ObservableChangeLog(observableId:observableId);
           let disposable = observable.didChange.addHandler(target: sharedInstance, handler: RequestHandler.observableChangeHandler, key: observableId)
            RequestHandler.inspectorEventDisposables[observableId] = disposable
        }
       
    }
    
    static func registerObservableTarget(observableId:String,behaviorId:String){
        RequestHandler.inspectorObservables[observableId]!.registerListener(behaviorId:behaviorId, listenerId: observableId);
    if(inspectorTimer == nil){
            inspectorTimer = Timer.scheduledTimer(timeInterval:1, target: RequestHandler.sharedInstance, selector: #selector(RequestHandler.emitterLogCallback), userInfo: nil, repeats: true)
        }
    }
    
    static func clearAllObservableListenersForBehavior(behaviorId:String){
        for (_,observableChangeLog) in RequestHandler.inspectorObservables{
            observableChangeLog.clearListenersForBehavior(behaviorId:behaviorId)
        }
    }
    
    static func clearAllObservables(){
        for (key,observableChangeLog) in RequestHandler.inspectorObservables{
            RequestHandler.inspectorEventDisposables[key]?.dispose();
            observableChangeLog.destroy()
        }
        RequestHandler.inspectorEventDisposables.removeAll();
        RequestHandler.inspectorObservables.removeAll();
        inspectorTimer = nil;
    }
    
    @objc private func emitterLogCallback(){
        var transmitData:JSON = [:];
        transmitData["type"] = JSON("signal_data");
        var signalData = [String:Any]()
        for (key, observableChangeLog) in RequestHandler.inspectorObservables{
            
            if observableChangeLog.hasNewValues{
                let values = observableChangeLog.getValues();
                let registeredListeners = observableChangeLog.getListeners();
                var valueListenerJSON = [String:Any]();
                valueListenerJSON["values"] = values;
                valueListenerJSON["listeners"] = registeredListeners;
                
                signalData[key] = valueListenerJSON;
                observableChangeLog.clearValues();
            }
        }
        transmitData["signalData"] = JSON(signalData);
        #if DEBUG
            print("transmitData",transmitData);
        #endif
        if(!transmitData.isEmpty){
            let socketRequest = Request(target: "socket", action: "send_inspector_data", data: transmitData, requester: RequestHandler.sharedInstance)
            RequestHandler.addRequest(requestData: socketRequest)
        }
    }
    
     private func observableChangeHandler(data:(String,Float,Float),key:String){
        RequestHandler.inspectorObservables[key]!.addValue(value:data.2);
       
    }
    
    
}

//stores the
class ObservableChangeLog{
    
    let observableId:String
    private var registeredListeners = [String:[String]]();
    private var storedValues = [Float]();
    var hasNewValues = false;
    
    init(observableId:String){
        self.observableId = observableId;
    }
    
    func registerListener(behaviorId:String, listenerId:String){
        if(registeredListeners[behaviorId] == nil){
            registeredListeners[behaviorId] = [String]();
        }
        self.registeredListeners[behaviorId]!.append(listenerId)
    }
    
    func getListeners()->[String:[String]]{
        return self.registeredListeners
    }
    
    func clearListenersForBehavior(behaviorId:String){
        if(self.registeredListeners[behaviorId] != nil){
            self.registeredListeners[behaviorId]!.removeAll()
        }
    }
    
     func addValue(value:Float){
        self.storedValues.append(value);
        self.hasNewValues = true;
    }
    
     func getValues()->[Float]{
        return self.storedValues;
    }
    
     func clearValues(){
        self.storedValues.removeAll();
        hasNewValues = false;
    }
    
    func destroy(){
        self.clearValues();
        self.registeredListeners.removeAll();
        
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
