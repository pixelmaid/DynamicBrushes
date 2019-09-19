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
        //note this might crash if you step in the middle of a recording, exit step, and continue looping
        stateData["constraints"] = brush.states[brush.currentState]!.getConstrainedPropertyNames(targetBrush:brush);
        stateData["methods"] = brush.transitions[brush.prevTransition]!.getMethodNames();
        
        BrushStorageManager.paramStorage[brush.behaviorId]![brush.id]![brush.params.globalTime] = stateData.rawString();
        
   
    }
    
    static func removeCachedData(behaviorId:String, brushId:String, startGlobalTime:Int, endGlobalTime:Int) {
        //find target storage and remove the ones bt time
//        print("~~~ length of storage before" , BrushStorageManager.paramStorage[behaviorId]![brushId]!.count)
//
        let timeDict = BrushStorageManager.paramStorage[behaviorId]![brushId]!
        for (time, val) in timeDict {
            if time >= startGlobalTime && time <= endGlobalTime {
                BrushStorageManager.paramStorage[behaviorId]![brushId]!.removeValue(forKey: time)
//                print("~~ removed cached data at ", time)
            }
        }
//        print("~~~ length of storage is now" , BrushStorageManager.paramStorage[behaviorId]![brushId]!.count)
    }
    
    static func accessSingleBrushStateAtTime(globalTime:Int,behaviorId:String,behaviorName:String, brushId:String)->JSON?{
        var debugData:JSON = [:]
        var behaviorListJSON = [JSON]();
        var brushesListJSON = [JSON]();
        //TODO: look at brush calling store state when recording view is in effect"
        debugData["groupName"] = JSON("brush");
        let behaviorStorage = BrushStorageManager.paramStorage;
        let targetBehaviorData = behaviorStorage[behaviorId]!;
        //TODO: error called in trying to find correct brush id
        let brushStateData = targetBehaviorData[brushId]
        guard brushStateData != nil else{
            return nil
        }
        let targetBrushData = brushStateData![globalTime];
        
        guard targetBrushData != nil else{
            return nil
        }
        
        brushesListJSON.append(JSON.init(parseJSON:targetBrushData!));
//        print(JSON.init(parseJSON:targetBrushData!)["event"]);
        var behaviorJSON:JSON = [:];
        behaviorJSON["id"] = JSON(behaviorId);
        behaviorJSON["name"] = JSON(behaviorName);
        behaviorJSON["brushes"] = JSON(brushesListJSON);
        behaviorListJSON.append(behaviorJSON);
        debugData["behaviors"] = JSON(behaviorListJSON);
        return debugData;


    }
    
   /*static func accessStateAtTime(globalTime:Int?,behaviorNames:[String:String])->JSON{
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
    }*/
    
    
    
    static func accessState(behaviorId:String,brushId:String,globalTime:Int)->BrushStateStorage?{
        guard let brushList = BrushStorageManager.paramStorage[behaviorId] else {
            return nil;
        }
        guard let brush = brushList[brushId] else{
            return nil;
        }
        guard let stateString = brush[globalTime] else{
            return nil;
        }
        
        let stateJSON = JSON.init(parseJSON: stateString);
        
        let state = BrushStateStorage(json:stateJSON["params"]);
        
        return state;
    }
    
    
}


