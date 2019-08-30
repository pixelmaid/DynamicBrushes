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
        guard var brushList =  BrushStorageManager.paramStorage[behaviorId] else {
            var brushList = [String:[Int:String]]();
            brushList[brushId] = [Int:String]();
            BrushStorageManager.paramStorage[behaviorId] = brushList;
            return;
        }
        
        brushList[brushId] = [Int:String]();
        
    }
    
   static func destroyBrushRegistry(behaviorId:String,brushId:String){
        guard var brushList = BrushStorageManager.paramStorage[behaviorId] else {
            return;
        }
        guard let _ = brushList[brushId] else {
            return;
        }
        
        brushList.removeValue(forKey: brushId);
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
    
    static func storeState(behaviorId:String,brushId:String,time:Int,state:String){
        guard var brushList = BrushStorageManager.paramStorage[behaviorId] else {
            return;
        }
        guard var brush = brushList[brushId] else{
            return;
        }
        
        BrushStorageManager.paramStorage[behaviorId]![brushId]![time] = state;
        
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
        
        let state = BrushStateStorage(json:stateJSON);
        
        return state;
    }
    
    
}


