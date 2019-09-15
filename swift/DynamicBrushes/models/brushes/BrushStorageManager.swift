//
//  BrushStorageManager.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 8/29/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON

class BrushStorageManager{
    static var paramStorage = [String:[String:[Int:String]]]();
    
    static func registerNewBrush(behaviorId:String,brushId:String){
        guard BrushStorageManager.paramStorage[behaviorId] != nil else {
            var brushList = [String:[Int:String]]();
            brushList[brushId] = [Int:String]();
            BrushStorageManager.paramStorage[behaviorId] = brushList;
            return;
        }
        
        BrushStorageManager.paramStorage[behaviorId]![brushId] = [Int:String]();
        
    }
    
   static func destroyBrushRegistry(behaviorId:String,brushId:String){
        guard var brushList = BrushStorageManager.paramStorage[behaviorId] else {
            return;
        }
        guard let _ = brushList[brushId] else {
            return;
        }
        
        BrushStorageManager.paramStorage[behaviorId]!.removeValue(forKey: brushId);
    }
    
    static func destroyBehaviorRegistry(behaviorId:String){
        guard let brushList = BrushStorageManager.paramStorage[behaviorId] else {
            return;
        }
        for (brushId,_) in  brushList{
            self.destroyBrushRegistry(behaviorId: behaviorId, brushId:  brushId);
        }
      
    BrushStorageManager.paramStorage.removeValue(forKey: behaviorId);
        
    }
    
    static func clearAllStoredData(){
       self.paramStorage = [String:[String:[Int:String]]]()
    }
    
    static func storeState(brush:Brush,event:String){
        if (!StylusManager.isLive) {
            return;
        }
        guard var brushList = BrushStorageManager.paramStorage[brush.behaviorId] else {
            return;
        }
        guard brushList[brush.id] != nil else{
            return;
        }
        
        var stateData:JSON = [:]
        stateData["behaviorId"] = JSON(brush.behaviorId);
        stateData["prevState"] = JSON(brush.prevState);
        stateData["currentState"] = JSON(brush.currentState);
        stateData["transitionId"] = JSON(brush.prevTransition);
        stateData["params"] = brush.params.toJSON();
        stateData["id"] = JSON(brush.id);
        stateData["event"] = JSON(event);
        stateData["constraints"] = brush.states[brush.currentState]!.getConstrainedPropertyNames(targetBrush:brush);
        stateData["methods"] = brush.transitions[brush.prevTransition]!.getMethodNames();
        
        BrushStorageManager.paramStorage[brush.behaviorId]![brush.id]![brush.params.time] = stateData.rawString();
        
    }
    
   static func accessStateAtTime(globalTime:Int?,behaviorNames:[String:String])->JSON{
        var debugData:JSON = [:]
        debugData["groupName"] = JSON("brush");
        let behaviors = BrushStorageManager.paramStorage;
        var behaviorListJSON = [JSON]();

        for (behaviorId,brushes) in behaviors {
            let behaviorName = behaviorNames[behaviorId]!;
            var brushesListJSON = [JSON]();
            for (brushId,paramList) in brushes {
                if(globalTime != nil ){
                    let filteredParam = paramList.first{
                        let bJSON = JSON.init(parseJSON:$0.value);
                        let bJSONParams = bJSON["params"]
                        let bJSONTime = bJSONParams["globalTime"].intValue
                        return bJSONTime == globalTime;
                        
                    }
                    if(filteredParam != nil){
                        var brushJSON = JSON.init(parseJSON:filteredParam!.value);
                        brushesListJSON.append(brushJSON);
                    } 
                    
                }
                else{
                    let sortedParams = paramList.sorted{ $0.0 < $1.0 }
                    if(sortedParams.count > 0){
                        
                        var brushJSON = JSON.init(parseJSON:sortedParams.last!.value);
                        let bJSONParams = brushJSON["params"]
                        let bJSONActive = bJSONParams["active"].boolValue;
                        if bJSONActive == true{
                            brushesListJSON.append(brushJSON);
                        }
                    }
                }
            }
            var behaviorJSON:JSON = [:];
            behaviorJSON["id"] = JSON(behaviorId);
            behaviorJSON["name"] = JSON(behaviorName);
            behaviorJSON["brushes"] = JSON(brushesListJSON);
            behaviorListJSON.append(behaviorJSON);
            
        }
        debugData["behaviors"] = JSON(behaviorListJSON);
        return debugData;
    }
    
    
    
    static func accessState(behaviorId:String,brushId:String,time:Int)->BrushStateStorage?{
        guard let brushList = BrushStorageManager.paramStorage[behaviorId] else {
            return nil;
        }
        guard let brush = brushList[brushId] else{
            return nil;
        }
        guard let stateString = brush[time] else{
            return nil;
        }
        
        let stateJSON = JSON.init(parseJSON: stateString);
        
        let state = BrushStateStorage(json:stateJSON["params"]);
        
        return state;
    }
    
    
}


