//
//  Debugger.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 2/15/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON
import Macaw

final class Debugger {
    static public let debugInterval:Int = 1;
    static public var debugTimer:Timer! = nil
    static public let debuggerEvent = Event<(String)>();
    static public var debugDataQueue = [JSON]();
    static public var debuggingTimerActive = false;
    static var propSort = ["ox","oy","sx","sy","rotation","dx","dy","x","y","radius","theta","diameter","hue","lightness","saturation","alpha"]

    
    static public func orderProps(propList:[JSON])->[JSON]{
        var _propList = propList;
        var sortedMappings = [JSON]();

        propSort.forEach { key in
        var found = false;
        _propList = _propList.filter { (mapping) -> Bool in
            
            if( !found && mapping["relativePropertyName"].stringValue == key){
                sortedMappings.append(mapping);
                found = true;
                return false;
            } else{
                return true;
            }
        }
        }
        return sortedMappings;
    }
    
    static public func startDebugTimer(interval:Int){
        Debugger.endDebugTimer();
        Debugger.debuggingTimerActive = true;
        Debugger.debugTimer = Timer(timeInterval: TimeInterval(interval), target: self, selector: #selector(Debugger.fireDebugUpdate), userInfo: nil, repeats: true)
        RunLoop.current.add(debugTimer, forMode: RunLoop.Mode.common)
    }
    
    
   static public func endDebugTimer(){
        if(Debugger.debugTimer != nil){
            Debugger.debugTimer.invalidate();
        }
        Debugger.debugTimer = nil;
        Debugger.debuggingTimerActive = false;

    }
    
    
    static func jumpToState(stroke:Stroke,segment:Segment){
        self.endDebugTimer();
        let brushId = stroke.brushId;
        let behaviorId = stroke.behaviorId;
        
        let localTime = segment.time;
        let brushState = BrushStorageManager.accessState(behaviorId: behaviorId, brushId: brushId, time: localTime);
        let globalTime = brushState!.globalTime;
        
        let debugData = JSON([Debugger.generateDebugData(behaviorId: behaviorId, brushId: brushId, brushState: brushState, globalTime: globalTime, localTime: localTime)]);
        
        let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugData, requester: RequestHandler.sharedInstance)
        RequestHandler.addRequest(requestData: socketRequest)
        
        
        print(debugData);
        //   debugData["type"] = "jump";
        
    }
    

    static func generateOutputDebugData(globalTime:Int?,brushState:BrushStateStorage?)->JSON{
        var debugData:JSON = [:]
        debugData["groupName"] = JSON("output");
        if(globalTime == nil){
            debugData["behaviors"] = BehaviorManager.drawing.activeStrokesToJSON();
        }
        else{
            debugData["behaviors"] = BehaviorManager.drawing.strokesAtGlobalTimeToJSON(globalTime:globalTime!, brushState: brushState!);
        }
        return debugData;
    }
    
    
    static func generateInputDebugData(behaviorId:String?, brushId:String?, globalTime:Int?, localTime:Int?)->JSON{
       
        var debugData:JSON = [:]
        let generatorCollectionsJSON = Debugger.generateGeneratorDebugData(behaviorId: behaviorId,brushId: brushId,localTime: localTime);
        let inputGlobalJSON = Debugger.generateGlobalInputDebugData(globalTime:globalTime);
        debugData["generator"] = generatorCollectionsJSON;
        debugData["inputGlobal"] = inputGlobalJSON;

        return debugData;
    }
    
    static func generateGlobalInputDebugData(globalTime:Int?)->JSON{
        let liveCollections = BehaviorManager.signalCollections[3];
        var liveCollectionsJSON:JSON = [:]
        liveCollectionsJSON["groupName"] = JSON("inputGlobal");
        var globalItems = [JSON]();
        
        for(key,value) in liveCollections{
            let liveCollection = value as! LiveCollection;
            var liveData:JSON = [:]
            if(globalTime != nil){
                let params = liveCollection.accessSampleDataByGlobalTime(time:globalTime!);
                if (params != nil){
                    liveData["params"] = params!
                }
                    //TODO: placeholder for setting up time params for other live input
                else{
                    liveData["params"] = JSON([:])
                }
            }
            else{
                liveData["params"] = liveCollection.paramsToJSON();
            }
            liveData["name"] = JSON(key);
            liveData["id"] = JSON(key);
            globalItems.append(liveData);
        }
        
        liveCollectionsJSON["items"] = JSON(globalItems);
        return liveCollectionsJSON
    }
    
    static func generateGeneratorDebugData(behaviorId:String?,brushId:String?,localTime:Int?)->JSON{
        guard let generatorCollection = BehaviorManager.signalCollections[2]["default"] else{
            return JSON([:]);
        }
        
        return generatorCollection.accessState(behaviorId: behaviorId, brushId: brushId , time: localTime);
    }
    
    static func generateSingleBrushDebugData(brush:Brush)->JSON{
        var debugData:JSON = [:]
        debugData["behaviorId"] = JSON(brush.behaviorDef!.id);
        debugData["prevState"] = JSON(brush.prevState);
        debugData["currentState"] = JSON(brush.currentState);
        debugData["transitionId"] = JSON(brush.prevTransition);
        debugData["params"] = brush.params.toJSON();
        debugData["id"] = JSON(brush.id);
        debugData["constraints"] = brush.states[brush.currentState]!.getConstrainedPropertyNames();
        debugData["methods"] = brush.transitions[brush.prevTransition]!.getMethodNames();
        return debugData;
    }
    
    static func generateBrushDebugData(brushState:BrushStateStorage?)->JSON{
        let behaviorNames = BehaviorManager.getBehaviorNames();
        
        guard brushState != nil else{
            return BrushStorageManager.accessStateAtTime(globalTime: nil, behaviorNames: behaviorNames)
        }
       return BrushStorageManager.accessStateAtTime(globalTime: brushState?.globalTime, behaviorNames: behaviorNames)
        
        /*var debugData:JSON = [:]
        debugData["groupName"] = JSON("brush");
        var behaviorListJSON = [JSON]();
        var brushesListJSON = [JSON]();
        let behaviors = BehaviorManager.getAllBrushInstances();
        for (behaviorId,brushTuple) in behaviors {
            let behaviorName = brushTuple.0;
            let brushes = brushTuple.1;
            for brush in brushes {
                var brushJSON = generateSingleBrushDebugData(brush: brush);
                brushJSON["name"] = JSON(brush.name);
                brushesListJSON.append(brushJSON);
        }
            var behaviorJSON:JSON = [:];
            behaviorJSON["id"] = JSON(behaviorId);
            behaviorJSON["name"] = JSON(behaviorName);
            behaviorJSON["brushes"] = JSON(brushesListJSON);
            behaviorListJSON.append(behaviorJSON);
            
        }
        debugData["behaviors"] = JSON(behaviorListJSON);

        return debugData;*/
    }
    
    
    static public func generateDebugData(behaviorId:String?,brushId:String?, brushState:BrushStateStorage?,globalTime:Int?,localTime:Int?)->JSON{
        let inputData = Debugger.generateInputDebugData(behaviorId: behaviorId, brushId: brushId, globalTime: globalTime,localTime: localTime);
        let brushData = Debugger.generateBrushDebugData(brushState:brushState);

        
        let outputData = Debugger.generateOutputDebugData(globalTime:globalTime,brushState:brushState);
        var debugData:JSON = [:];
        debugData["brush"] = brushData;
        debugData["input"] = inputData;
        debugData["output"] = outputData;
        debugData["type"] = "state";
        return debugData;
    }
    
    @objc static func fireDebugUpdate(){
        if(Debugger.debugDataQueue.count>0){
            let debugJSON = JSON(Debugger.debugDataQueue);
            let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugJSON, requester: RequestHandler.sharedInstance)
            RequestHandler.addRequest(requestData: socketRequest)
            Debugger.debugDataQueue.removeAll();
        }
    }
    
    static public func cacheDebugData(){
        let debugData = Debugger.generateDebugData(behaviorId: nil, brushId: nil, brushState: nil ,globalTime: nil,localTime: nil);
        
        Debugger.debugDataQueue.append(debugData);

    }
    
    static public func getGeneratorValue(brushId:String) -> [(Double,Int,String)] {
        var val = -1.0
        var time = -1
        var type = "none"
        var freq:Float = -1.0
        var returnVals:[(val:Double,time:Int,type:String)] = []
        let generatorJSON = Debugger.generateGeneratorDebugData(behaviorId: nil, brushId: nil, localTime: nil);
        
        let params:JSON = generatorJSON["params"]
        for (_, subJsonArr):(String, JSON) in params {
            for (_, subJson):(String, JSON) in subJsonArr {
                if (subJson["brushId"].string == brushId) {
                    val = subJson["v"].double ?? -1.0
                    time = subJson["time"].int ?? -1
                    type = subJson["generatorType"].string ?? "none"
                    freq = subJson["settings"]["freq"].float ?? -1.0
                    //                        if subJson["settings"].exists() {
                    //                            print("FREQUENCY OF SINE IS ~~~~~~ ", freq)
                    //
                    //                        }
                    returnVals.append((val:val, time:time, type:type))
                    
                    
                }
            }
            
        }
        return returnVals
    }
    
    static public func getStylusInputValue(brushId:String) -> (Double, Double, Double) {
        var x = 0.0
        var y = 0.0
        var force = 0.0
        let debugData = Debugger.generateInputDebugData(behaviorId: nil, brushId: nil,globalTime: nil,localTime: nil)
        if debugData["inputGlobal"].exists() {
            let items:JSON = debugData["inputGlobal"]["items"]
            for (_, subJsonArr):(String, JSON) in items {
                if subJsonArr["id"] == "stylus" {
                    let params:JSON = subJsonArr["params"]
                    x = params["x"].double ?? 0.0
                    y = params["y"].double ?? 0.0
                    force = params["force"].double ?? 0.0
                    
                }
            }
        }
        return (x, y, force)
    }
    
    static public func drawUnrendererdBrushes(view:BrushGraphicsView){
        let behaviors = BehaviorManager.getAllBrushInstances();
        //check to see which brushes are "unrendered"
       // pass them the UI view and draw into it
        var brushIds = Set<String>()
        var i = 0 //note - this is only until we get active instance
        for (behaviorId,brushTuple) in behaviors {
            let brushes = brushTuple.1;
            let brush = brushes[0]
//            for brush in brushes {
            if brush.unrendered && i < 1 {
//                print("~~~ about to draw into context in debugger with brush ", brush.id)
                let valArray = Debugger.getGeneratorValue(brushId: brush.id)
                let inputInfo = Debugger.getStylusInputValue(brushId: brush.id)
                brush.drawIntoContext(context:view, info:inputInfo)

                view.scene!.drawGenerator(valArray: valArray)
            
                i += 1
            }
            brushIds.insert(brush.id)
//            }
        }
        //remove brush if not in this list
        let brushesIdsOnCanvas = Set(view.scene!.activeBrushIds.keys)
        
        let keysToRemove = Array(brushesIdsOnCanvas.symmetricDifference(brushIds))
//        print("##keys to remove is ", keysToRemove)
        for id in keysToRemove {
            view.scene!.removeActiveId(id:id)
            view.updateNode()
        }
        
    }
    
    
    static func highlight(data:JSON){
        //respond to highlight request from programming interface
    }
    
    static func setupHighlightRequest(){
        
        var debugData:JSON = [:]
        
        //populate highlight data here

        
        debugData["type"] = "highlight";

        let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugData, requester: RequestHandler.sharedInstance)
        RequestHandler.addRequest(requestData: socketRequest)
        
    }
    
    
    
    
}
