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
    static public let debugInterval:Int = 1
    static public var debugTimer:Timer! = nil
    static public let debuggerEvent = Event<(String)>();

    
    static private var debuggingActive = false;
    static var propSort = ["ox","oy","sx","sy","rotation","dx","dy","x","y","radius","theta","diameter","hue","lightness","saturation","alpha"]

    static public func activate(){
        Debugger.debuggingActive = true;
        Debugger.debuggerEvent.raise(data: ("INIT"));
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
        self.endDebugTimer();
        Debugger.debugTimer = Timer(timeInterval: TimeInterval(interval), target: self, selector: #selector(Debugger.fireDebugUpdate), userInfo: nil, repeats: true)
        RunLoop.current.add(debugTimer, forMode: RunLoop.Mode.common)
    }
    
    
   static public func endDebugTimer(){
        if(Debugger.debugTimer != nil){
            Debugger.debugTimer.invalidate();
        }
        Debugger.debugTimer = nil;
    }
    
    
    
  static func generateInputDebugData()->JSON{
       
        var debugData:JSON = [:]
        let generatorCollectionsJSON = Debugger.generateGeneratorDebugData();
        
        let liveCollections = BehaviorManager.signalCollections[3];
        var liveCollectionsJSON:JSON = [:]
        liveCollectionsJSON["groupName"] = JSON("inputGlobal");
        var globalItems = [JSON]();
    
        for(key,value) in liveCollections{
            var liveData:JSON = [:]
            liveData["params"] = value.paramsToJSON();
            liveData["name"] = JSON(key);
            liveData["id"] = JSON(key);
            globalItems.append(liveData);
        }
    
        liveCollectionsJSON["items"] = JSON(globalItems);
        debugData["generator"] = generatorCollectionsJSON;
    
        debugData["inputGlobal"] = liveCollectionsJSON;

        return debugData;
    }
    
    static func generateGeneratorDebugData()->JSON{
        
        let generatorCollections = BehaviorManager.signalCollections[2];
        var generatorCollectionsJSON:JSON = [:]
        generatorCollectionsJSON["groupName"] = JSON("generator");
        
        for(key,value) in generatorCollections{
            var generatorData:JSON = [:]
            generatorData["params"] = value.paramsToJSON();
            generatorData["name"] = JSON(key);
            generatorData["id"] = JSON(key);
            generatorCollectionsJSON[key] = generatorData;
        }
        
        
       return generatorCollectionsJSON;
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
    
    static func generateBrushDebugData()->JSON{
        var debugData:JSON = [:]
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
            
        debugData["behaviors"] = JSON(behaviorListJSON);
        }

        return debugData;
    }
    
    
    static public func  generateDebugData()->JSON{
        let inputData = Debugger.generateInputDebugData();
        let brushData = Debugger.generateBrushDebugData();
        var debugData:JSON = [:];
        debugData["brush"] = brushData;
        debugData["input"] = inputData;
            
        return debugData;
    }
    
    @objc static func fireDebugUpdate(){
        let debugData = Debugger.generateDebugData();
        let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugData, requester: RequestHandler.sharedInstance)
        RequestHandler.addRequest(requestData: socketRequest)
    }
    
    static public func drawUnrendererdBrushes(view:BrushGraphicsView){
        let behaviors = BehaviorManager.getAllBrushInstances();
        //check to see which brushes are "unrendered"
       // pass them the UI view and draw into it
        var brushIds = Set<String>()
        for (behaviorId,brushTuple) in behaviors {
            let brushes = brushTuple.1;
            for brush in brushes {
                if brush.unrendered {
                    print("about to draw into context in debugger")
                    brush.drawIntoContext(context:view)
                }
                brushIds.insert(brush.id)
            }
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
    
}
