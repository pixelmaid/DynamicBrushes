//
//  Debugger.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 2/15/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON

final class Debugger {
    
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
    
  
    
    static public func  generateBrushDebugData(brush:Brush, type:String){
            var debugData:JSON = [:]
            debugData["type"] = JSON();
            debugData["behaviorId"] = JSON(brush.behaviorDef!.id);
            debugData["prevState"] = JSON(brush.prevState);
            debugData["currentState"] = JSON(brush.currentState);
            debugData["transitionId"] = JSON(brush.prevTransition);
            debugData["params"] = brush.params.toJSON();
            debugData["constraints"] = brush.states[brush.currentState]!.getConstrainedPropertyNames();
            debugData["methods"] = brush.transitions[brush.prevTransition]!.getMethodNames();
            
            
            let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugData, requester: RequestHandler.sharedInstance)
            RequestHandler.addRequest(requestData: socketRequest)
       
    }
    
    static public func drawUnrendererdBrushes(view:UIView){
        let brushes = BehaviorManager.getAllBrushInstances();
        //check to see which brushes are "unrendered"
       // pass them the UI view and draw into it
    }
    
}
