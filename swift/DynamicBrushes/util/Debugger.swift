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
    
    static private var debuggingActive = false;
    
    static public func activate(){
        Debugger.debuggingActive = true;
    }
    
    static public func deactivate(){
        debuggingActive = false;
    }
    
    static public func  generateDebugData(brush:Brush, type:String){
        if(debuggingActive){
            var debugData:JSON = [:]
            debugData["type"] = JSON(type);
            debugData["behaviorId"] = JSON(brush.behaviorDef!.id);
            debugData["prevState"] = JSON(brush.prevState);
            debugData["currentState"] = JSON(brush.currentState);
            debugData["transitionId"] = JSON(brush.prevTransition);
            debugData["brushState"] = brush.brushState.toJSON();
            debugData["constraints"] = brush.states[brush.currentState]!.getConstrainedPropertyNames();
            let socketRequest = Request(target: "socket", action: "send_inspector_data", data: debugData, requester: RequestHandler.sharedInstance)
            RequestHandler.addRequest(requestData: socketRequest)
        }
    }
    
}
