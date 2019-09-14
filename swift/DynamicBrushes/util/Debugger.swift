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
    static public var programViewDebugTimer:Timer! = nil

    static public let debuggerEvent = Event<(String, String)>();
    static public let collisionEvent = Event<(Float, Float)>();
    
    static private var debuggingActive = false;
    static public var programDebugDataQueue = [JSON]();
    static public var drawingDebugDataQueue = [JSON]();
    
    static public var debuggingTimerActive = false;
    
    //toggle variables
    static public var inputGfx = true
    static public var inputLabel = true
    static public var brushGfx = true
    static public var brushLabel = true
    static public var outputGfx = true
    static public var outputLabel = true
    
    static public var inputLabelTurnedOff = false
    static public var brushLabelTurnedOff = false
    static public var outputLabelTurnedOff = false

    //showing brush up/down variables
    static public var lastState = -1
    static public var lastPointX = 0.0
    static public var lastPointY = 0.0
    static public var toDrawPenDown = false
    
    static var propSort = ["ox","oy","sx","sy","rotation","dx","dy","weight","hue","lightness","saturation","alpha"]
    static var brushGraphicsView:BrushGraphicsView!
    
    static public func activate(){
        Debugger.debuggingActive = true;
        Debugger.debuggerEvent.raise(data: ("INIT", ""));
    }
    
    static public func deactivate(){
        debuggingActive = false;
    }
    
    
    static public func orderProps(propList:[JSON])->[JSON]{
        var _propList = propList;
        var sortedMappings = [JSON]();
        
        propSort.forEach { key in
            var found = false;
            _propList = _propList.filter { (mapping) -> Bool in
                let name = mapping["relativePropertyName"].stringValue;
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
       Debugger.programViewDebugTimer = Timer(timeInterval: TimeInterval(interval), target: self, selector: #selector(Debugger.fireDebugUpdate), userInfo: nil, repeats: true)
        RunLoop.current.add(programViewDebugTimer, forMode: RunLoop.Mode.common)

    }
    
    
    static public func endDebugTimer(){
        if(Debugger.programViewDebugTimer != nil){
            Debugger.programViewDebugTimer.invalidate();

        }
        Debugger.programViewDebugTimer = nil;
        Debugger.debuggingTimerActive = false;
        
    }
    
    static func testMacawCollision(x:Float, y:Float) {
        Debugger.collisionEvent.raise(data: (x, y));
    }
    
    static func checkForCollisions(view:BrushGraphicsView, x:Float, y:Float) {
        view.scene!.checkCollisions(x:x, y:y)
    }
    
    
    static func jumpToState(stroke:Stroke,segment:Segment){
        self.resetDebugStatus();
        self.endDebugTimer();
        
        let brushId = stroke.brushId;
        let behaviorId = stroke.behaviorId;
        
        let localTime = segment.time;
        let brushState = BrushStorageManager.accessState(behaviorId: behaviorId, brushId: brushId, time: localTime);
        let globalTime = brushState!.globalTime;
        
        let debugData = JSON(Debugger.generateDebugData(behaviorId: behaviorId, brushId: brushId, brushState: brushState, globalTime: globalTime, localTime: localTime));
        //print("debug data",debugData)
        Debugger.drawingDebugDataQueue.append(debugData);

        let socketRequest = Request(target: "socket", action: "send_inspector_data", data: [debugData], requester: RequestHandler.sharedInstance)
        RequestHandler.addRequest(requestData: socketRequest)
        
        self.drawCurrentBrushState(view: Debugger.brushGraphicsView!, targetBehaviorId: behaviorId,jump:true,time:localTime)
        
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
            print("~~~ collection ", liveCollection)
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
        debugData["constraints"] = brush.states[brush.currentState]!.getConstrainedPropertyNames(targetBrush: brush);
        debugData["methods"] = brush.transitions[brush.prevTransition]!.getMethodNames();
        return debugData;
    }
    
    static func generateBrushDebugData(brushState:BrushStateStorage?)->JSON{
        let behaviorNames = BehaviorManager.getBehaviorNames();
        
        guard brushState != nil else{
            return BrushStorageManager.accessStateAtTime(globalTime: nil, behaviorNames: behaviorNames)
        }
        return BrushStorageManager.accessStateAtTime(globalTime: brushState?.globalTime, behaviorNames: behaviorNames)
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
        if(Debugger.programDebugDataQueue.count>0){
            let debugJSON = JSON(Debugger.programDebugDataQueue);
            let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugJSON, requester: RequestHandler.sharedInstance)
            RequestHandler.addRequest(requestData: socketRequest)
            Debugger.programDebugDataQueue.removeAll();
        }
    }
    
    @objc static func cacheDebugData(){
        let debugData = Debugger.generateDebugData(behaviorId: nil, brushId: nil, brushState: nil ,globalTime: nil,localTime: nil);
        
        Debugger.programDebugDataQueue.append(debugData);
      //  print("debug data",debugData)

        Debugger.drawingDebugDataQueue.append(debugData);
        
    }
    
    static public func resetDebugStatus(){
        Debugger.programDebugDataQueue.removeAll();
        Debugger.drawingDebugDataQueue.removeAll();
        Debugger.startDebugTimer(interval: Debugger.debugInterval);
        
    }
    
    static public func getGeneratorValue(brushId:String,debugData:JSON) -> [(Double,Int,String,Float)] {
        var val = -1.0
        var time = -1
        var type = "none"
        var freq:Float = -1.0
        var returnVals:[(val:Double,time:Int,type:String,freq:Float)] = []
        
        let params:JSON = debugData["params"]
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
                    returnVals.append((val:val, time:time, type:type, freq:freq))
                    
                    
                }
            }
            
        }
        return returnVals
    }
    
    static public func getStylusInputValue(debugData:JSON) -> (Double, Double, Double, Int) {
        var x = 0.0
        var y = 0.0
        var force = 0.0
        var state = -1
        
        let items:JSON = debugData["items"]
        for (_, subJsonArr):(String, JSON) in items {
            if subJsonArr["id"] == "stylus" {
                let params:JSON = subJsonArr["params"]
                x = params["x"].double ?? 0.0
                y = params["y"].double ?? 0.0
                force = params["force"].double ?? 0.0
                state = params["stylusEvent"].int ?? -1 //0 is down, 2 is up
                
            }
        }
        
        return (x, y, force, state)
    }
    
    static public func toggleVisualizations(view:BrushGraphicsView, item:String, isOn:Bool) {
        switch(item) {
        case "input":
            self.inputGfx = isOn
            break
        case "brush":
            self.brushGfx = isOn
            break
        case "output":
            self.outputGfx = isOn
            break
        default:
            break
        }
        view.scene?.toggleViz(type:item)
    }
    
    static public func toggleLabels(view:BrushGraphicsView, item:String, isOn:Bool) {
        switch(item) {
        case "input":
            self.inputLabel = isOn
            break
        case "brush":
            self.brushLabel = isOn
            break
        case "output":
            self.outputLabel = isOn
            break
        default:
            break
        }
        view.scene?.toggleLabel(type:item)
    }
    
    static public func refreshVisualizations(view:BrushGraphicsView) {
        view.scene?.toggleViz(type:"input")
        view.scene?.toggleViz(type:"output")
        view.scene?.toggleViz(type:"brush")
        view.scene?.toggleLabel(type:"input")
        view.scene?.toggleLabel(type:"output")
        view.scene?.toggleLabel(type:"brush")
    }
    
    static public func highlightVisualizations(view:BrushGraphicsView, param:String, on:Bool) {
        view.scene!.highlightViz(name: param, on:on)
    }
    
    
    static public func drawCurrentBrushState(view:BrushGraphicsView,targetBehaviorId:String,jump:Bool, time:Int?){
        //let behaviors = BehaviorManager.getAllBrushInstances();
        //check to see which brushes are "unrendered"
        // pass them the UI view and draw into it
        var i = 0
        if(Debugger.drawingDebugDataQueue.count>0){

            var brushIds = Set<String>()
            let targetIndex = BehaviorManager.activeInstance;
            let targetBehavior =  BehaviorManager.behaviors[targetBehaviorId]!;
            let targetBrush = targetBehavior.brushInstances[targetIndex];
            if(targetBrush.unrendered || jump == true){
            
            for currentData in Debugger.drawingDebugDataQueue {
                //double check view values since they arent persistent
                refreshVisualizations(view: view)
                let debugInputGlobal = currentData["input"]["inputGlobal"]
                let debugBrush:BrushStateStorage;
                if(time != nil){
                    debugBrush = BrushStorageManager.accessState(behaviorId: targetBehaviorId, brushId: targetBrush.id, time: time!)!
                }
                else{
                    debugBrush = targetBrush.params;
                }
                
                let debugGenerator = currentData["input"]["generator"]
                print("~~ debug gen is", debugGenerator)
                let valArray = Debugger.getGeneratorValue(brushId: targetBrush.id,debugData: currentData["input"]["generator"]);
                let inputInfo = Debugger.getStylusInputValue(debugData: currentData["input"]["inputGlobal"]);
              //  print("~~~ about to draw into context in debugger with stylus x y ", inputInfo.0, inputInfo.1)
                print("~~~valArray is" , valArray)
                targetBrush.drawIntoContext(context:view,brushInfo:debugBrush, stylusInfo:inputInfo)
                view.scene!.drawGenerator(valArray: valArray)
                
                brushIds.insert(targetBrush.id)
                
                //remove brush if not in this list
                let brushesIdsOnCanvas = Set(view.scene!.activeBrushIds.keys)
                
                let keysToRemove = Array(brushesIdsOnCanvas.symmetricDifference(brushIds))
                //        print("##keys to remove is ", keysToRemove)
                for id in keysToRemove {
                    view.scene!.removeActiveId(id:id)
                    view.updateNode()
                    
                    //
                }
            }
            Debugger.drawingDebugDataQueue.removeAll();
        }
        }
        
    }
        
/*static public func drawUnrendererdBrushes(view:BrushGraphicsView){
 let behaviors = BehaviorManager.getAllBrushInstances();
 //check to see which brushes are "unrendered"
 // pass them the UI view and draw into it
 var brushIds = Set<String>()
 
 for (behaviorId,brushTuple) in behaviors {
 let brushes = brushTuple.1;
 let brush = brushes[BehaviorManager.activeInstance]
 if brush.unrendered {
 //                print("~~~ about to draw into context in debugger with brush ", brush.id)
 //double check view values since they arent persistent
 refreshVisualizations(view: view)
 let valArray = Debugger.getGeneratorValue(brushId: brush.id)
 let inputInfo = Debugger.getStylusInputValue(brushId: brush.id)
 brush.drawIntoContext(context:view, info:inputInfo)
 
 view.scene!.drawGenerator(valArray: valArray)
 
 }
 brushIds.insert(brush.id)
 }
 //remove brush if not in this list
 let brushesIdsOnCanvas = Set(view.scene!.activeBrushIds.keys)
 
 let keysToRemove = Array(brushesIdsOnCanvas.symmetricDifference(brushIds))
 //        print("##keys to remove is ", keysToRemove)
 for id in keysToRemove {
 view.scene!.removeActiveId(id:id)
 view.updateNode()
 
 //
 }
 
 }*/
    
    
    static func highlight(data:JSON){
        //respond to highlight request from programming interface
        let param = data["data"]["name"].string ?? ""
        let isOn = data["data"]["isOn"].bool ?? false
//        print("!!~~~ highlight request received! " , param, isOn, data)
        if isOn {
            Debugger.debuggerEvent.raise(data: ("HIGHLIGHT", param));
        } else {
            Debugger.debuggerEvent.raise(data: ("UNHIGHLIGHT", param));
        }
        
    }
    
    static func setupHighlightRequest(kind:String){
        var on = true
        if kind == "clear" { on = false}
        var debugData:JSON = ["kind":kind, "isOn":on]
        
        //populate highlight data here
        debugData["type"] = "highlight";
        let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugData, requester: RequestHandler.sharedInstance)
        RequestHandler.addRequest(requestData: socketRequest)
        
    }
    
    static func setupResetInspectionRequest(){
        var debugData:JSON = [:]
        debugData["type"] = "resetInspection";
        let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugData, requester: RequestHandler.sharedInstance)
        RequestHandler.addRequest(requestData: socketRequest)
    }
    
    
    
    
}
