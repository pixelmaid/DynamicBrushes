//
//  BehaviorManager.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 5/25/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON

enum BehaviorError: Error {
    case duplicateName
    case behaviorDoesNotExist
    case mappingDoesNotExist;
    case transitionDoesNotExist;
    case requestDoesNotExist;
    case collectionDoesNotExist
}

class BehaviorManager{
    static var behaviors = [String:BehaviorDefinition]()
    static var imported = [String:SignalCollection]();
    static var recordings = [String:SignalCollection]();
    static var generators = [String:GeneratorCollection]();
    static var liveInputs = [String:SignalCollection]();
    static var signalCollections = [imported,recordings,generators,liveInputs];

    var canvas:Canvas
    init(canvas:Canvas){
        self.canvas = canvas;
      
    }
    
  
    
    func refreshAllBehaviors(){
        for (_,behavior) in BehaviorManager.behaviors{
            behavior.createBehavior(canvas:canvas)
        }
    }
    
    func loadData(json:JSON){
        //BehaviorManager.loadCollectionsFromJSON(data: json["collections"]);
        self.loadBehaviorsFromJSON(json: json["behaviors"], rewriteAll: true)
    }
    
   
    
    func loadBehaviorsFromJSON(json:JSON,rewriteAll:Bool){
        if(rewriteAll){
            for(_,value) in BehaviorManager.behaviors{
                value.clearBehavior();
            }
            BehaviorManager.behaviors.removeAll();
            
        }
        for(key,value) in json{
            if let val = BehaviorManager.behaviors[key] {
                val.clearBehavior();
                
            }
            let behavior = BehaviorDefinition(id:key,name:value["name"].stringValue);
            behavior.parseJSON(json: value)
            behavior.createBehavior(canvas:canvas);
            BehaviorManager.behaviors[key] = behavior;
            
        }
    }
    
    func handleAuthoringRequest(authoring_data:JSON) throws->JSON{

        let data = authoring_data["data"] as JSON;
        let type = data["type"].stringValue;
        var resultJSON:JSON = [:]
        resultJSON["type"] = JSON("authoring_response");
        resultJSON["authoring_type"] = JSON(type);
        switch(type){
        case "set_behavior_active":
            let behaviorId = data["behaviorId"].stringValue;
            let behavior = BehaviorManager.behaviors[behaviorId]!;
            let active_status = data["active_status"].boolValue;
            behavior.setActiveStatus(status:active_status);
            if(active_status){
            behavior.setAutoSpawnNum(num: 1)
            }
            else{
                behavior.setAutoSpawnNum(num: 0)
  
            }
            BehaviorManager.behaviors[behaviorId]!.createBehavior(canvas:canvas)
            resultJSON["result"] = "success";
            return resultJSON;
            
            
        case "refresh_behavior":
            let behaviorId = data["behaviorId"].stringValue;
            BehaviorManager.behaviors[behaviorId]!.createBehavior(canvas:canvas)
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "request_behavior_json":
            let behaviorId = data["behaviorId"].stringValue;
            let behavior = BehaviorManager.behaviors[behaviorId]!;
            let behaviorJSON:JSON = behavior.toJSON();
            resultJSON["result"] = "success";
            resultJSON["data"] = behaviorJSON
            return resultJSON;
            
        case "behavior_added":
            let name = data["name"].stringValue;
            let id = data["id"].stringValue;
            let data = data["data"]
            //let behavior = BehaviorDefinition(id:data["id"].stringValue, name: data["name"].stringValue);
            let behavior = BehaviorDefinition(id:id,name:name);
            behavior.parseJSON(json: data)

            
            if(BehaviorManager.behaviors[id] != nil){
                throw BehaviorError.duplicateName;
            }
            else{
                BehaviorManager.behaviors[id] = behavior;

               behavior.createBehavior(canvas:canvas)

                resultJSON["result"] = "success";
                return resultJSON;
            }
            
            //request to check dependency
        case "delete_behavior_request":
            let behaviorId = data["behaviorId"].stringValue;
            let behavior = BehaviorManager.behaviors[behaviorId]!;
            let dependents = self.checkDependency(behaviorId:behavior.id);
            if(dependents.count == 0){
                resultJSON["result"] = "success";
            }
            else{
                resultJSON["result"] = "check";
                resultJSON["data"] = ["dependents":JSON(dependents)]
            }
            return resultJSON;
            
        //hard delete despite any dependencies
        case "hard_delete_behavior":
            
            let behaviorId = data["behaviorId"].stringValue;
            let behavior = BehaviorManager.behaviors[behaviorId]!;
            BehaviorManager.behaviors.removeValue(forKey: behaviorId)
            behavior.clearBehavior();
            resultJSON["result"] = "success"
            return resultJSON
            
        case "state_added":
           
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.parseStateJSON(data:data);
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas)
            
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "state_moved":
             let behaviorId = data["behaviorId"].stringValue;
              let stateId = data["stateId"].stringValue;
             let x  = data["x"].floatValue
             let y = data["y"].floatValue

             BehaviorManager.behaviors[behaviorId]!.setStatePosition(stateId:stateId,x:x,y:y);
            resultJSON["result"] = "success";
            return resultJSON;
        case "state_removed":
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeState(stateId: data["stateId"].stringValue);
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas)
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "transition_added","transition_event_added", "transition_event_condition_changed":
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.parseTransitionJSON(data:data)
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas)
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "transition_removed":
            do{
                try BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeTransition(id: data["transitionId"].stringValue);
                BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas)
                
                resultJSON["result"] = "success";
                return resultJSON;            }
            catch{
                print("transition id does not exist, cannot remove");
                resultJSON["result"] = "failure";
                return resultJSON;
            }
        case "transition_event_removed" :
            do{
                try BehaviorManager.behaviors[data["behaviorId"].stringValue]!.setTransitionToDefaultEvent(transitionId: data["transitionId"].stringValue)
                BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas);
                resultJSON["result"] = "success";
                return resultJSON;            }
            catch{
                resultJSON["result"] = "failure";
                return resultJSON;            }
            
   
            
        case "method_added","method_argument_changed":
            let behaviorId = data["behaviorId"].stringValue
            let methodJSON = BehaviorManager.behaviors[behaviorId]!.parseMethodJSON(data: data)
            BehaviorManager.behaviors[behaviorId]!.createBehavior(canvas:canvas);
            let targetMethod = data["targetMethod"].stringValue
            if(targetMethod == "spawn"){
            var behavior_list =  methodJSON["argumentList"]
            for (key,value) in BehaviorManager.behaviors{
                if key != behaviorId {
                    behavior_list[key] = JSON(value.name);
                }
            }
            }
            resultJSON["result"] = "success";
            resultJSON["data"] = methodJSON;
            return resultJSON;
         
            
        case "method_removed":
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeMethod(methodId: data["methodId"].stringValue)
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas);
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "mapping_added":
            let behaviorId = data["behaviorId"].stringValue;
            
            BehaviorManager.behaviors[behaviorId]!.parseMappingJSON(data:data)
            BehaviorManager.behaviors[behaviorId]!.createBehavior(canvas:canvas)
            
            resultJSON["result"] = "success";
            return resultJSON;
 
       
        case "signal_initialized":
            do {
                guard let signalData = try self.parseSignalJSON(data:data) else{
                    resultJSON["result"] = "failure";
                    return resultJSON;
                }
                resultJSON["data"] = signalData;
                resultJSON["result"] = "success";

            }
            catch{
                resultJSON["result"] = "failure";
                return resultJSON;
            }
        break;
            
        case "expression_modified":
            let behaviorId = data["behaviorId"].stringValue;
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.parseExpressionJSON(data:data)
            
            BehaviorManager.behaviors[behaviorId]!.createBehavior(canvas:canvas)
            
            resultJSON["result"] = "success";
            return resultJSON;
            
            
        case "mapping_removed":
            
            do{
                try BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeMapping(id: data["mappingId"].stringValue);
                BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas)
                resultJSON["result"] = "success";
                return resultJSON;
            }
            catch{
                resultJSON["result"] = "failure";
                return resultJSON;
            }
            
        case "dataset_loaded":
             #if DEBUG
                //print("dataset loaded",data);
            #endif
           BehaviorManager.parseImported(data:data)
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        default:
            break
        }
        
        
        
        resultJSON["result"] = "failure";
        return resultJSON;
    }
    
    
 private func parseSignalJSON(data:JSON) throws->JSON?{
        let classType = data["classType"].stringValue;
        let collectionId = data["collectionId"].stringValue;
        let fieldName = data["fieldName"].stringValue;
        let displayName = data["displayName"].stringValue;

        let settings  = data["settings"];
        let id:String

    do {
    switch classType{
        case "generator":
            id = BehaviorManager.generators["default"]!.initializeSignal(fieldName:fieldName,displayName:displayName,settings:settings,classType: classType, isProto: false, order:nil);
        break;
        case "imported":
            guard let dataCollection = BehaviorManager.imported[collectionId] else {
                throw BehaviorError.collectionDoesNotExist;
            }
             id = dataCollection.initializeSignal(fieldName:fieldName,displayName:displayName,settings:settings,classType: classType, isProto: false, order:nil);

        break;
        case "live":
            guard let liveCollection = BehaviorManager.liveInputs[collectionId] else {
                throw BehaviorError.collectionDoesNotExist;

            }
             id = liveCollection.initializeSignal(fieldName:fieldName,displayName:displayName,settings:settings,classType: classType, isProto: false, order:nil);

        break;
        case "recording":
            guard let recordingCollection = BehaviorManager.recordings[collectionId] else {
                throw BehaviorError.collectionDoesNotExist;
                
            }
             id = recordingCollection.initializeSignal(fieldName:fieldName,displayName:displayName,settings:settings,classType: classType, isProto: false, order:nil);

        break;
    //TODO: INIT BRUSH SETUP
        //case "brush":
        
        //break;
        //case "drawing":
        
        //break;
        default:
            return nil;
        }
        
        var signalJSON:JSON = [:]
        signalJSON["id"] = JSON(id);
        signalJSON["classType"] = JSON(classType)
        signalJSON["collectionId"] = JSON(collectionId)
        signalJSON["fieldName"] = JSON(fieldName)
        
        return signalJSON;
    }
        catch {
            #if DEBUG
                print("error thrown on init signal")
            #endif
            
        }
        return nil;
    }

  
    
    static func getBehaviorById(id:String)->BehaviorDefinition?{
        if(BehaviorManager.behaviors[id] != nil){
            return BehaviorManager.behaviors[id]
        }
        return nil
    }
    
    
    static func loadCollectionsFromJSON(data:JSON){
        
        let collectionData = data.dictionaryValue;
        for (key,list) in collectionData{
            let collectionList = list.arrayValue;
            print("collection key",key,collectionList,list);
            switch (key){
            case "live":
                print("live data",collectionList)
                for metadata in collectionList{
                    let signalCollection = LiveCollection(data:metadata);
                    BehaviorManager.liveInputs[signalCollection.id] = signalCollection;
                }
                break;
            case "imported":
                for metadata in collectionList{
                    let signalCollection = SignalCollection(data:metadata);
                    BehaviorManager.imported[signalCollection.id] = signalCollection;
                }
                break;
            case "generators":
                for metadata in collectionList{
                    let signalCollection = GeneratorCollection(data:metadata);
                    BehaviorManager.generators[signalCollection.id] = signalCollection;
                }
                break;
            case "recordings":
                print("recording list",collectionList);

                for metadata in collectionList{
                    print("metadata id",metadata["id"].stringValue);

                    if(metadata["id"].stringValue == "recording_preset"){
                        StylusManager.setRecordingPresetData(data: metadata);
                    }
                    else{
                        let signalCollection = RecordingCollection(data:metadata);
                        BehaviorManager.recordings[signalCollection.id] = signalCollection;
                    }
                }
                break;
            case "drawings":
                break;
            case "brush":
                break;
            default:
                break;
            }
        }
    }
    
    
    static func register(collectionId:String,recording:SignalCollection){
        BehaviorManager.recordings[collectionId] = recording;
    }
    
    
   static func parseImported(data:JSON){
    let id = data["id"].stringValue;
    let signalCollection = SignalCollection(data: data);
    BehaviorManager.imported[id] = signalCollection;
    }
    
    
    //checks to see if other behaviors reference the target behavior
    func checkDependency(behaviorId:String)->[String:String]{
        var dependentBehaviors = [String:String]()
        
        for (_,value) in BehaviorManager.behaviors {
            if(value.id != behaviorId){
                let dependent = value.checkDependency(behaviorId: behaviorId);
                if(dependent){
                    dependentBehaviors[value.id] = value.name;
                }
            }
        }
        
        return dependentBehaviors;
        
    }
    
    
    //TODO: eventually move all collection stuff to seperate final collection manager
    static func getAllCollectionJSON()->JSON{
        var collectionJSON = [JSON]();
        for collectionList in BehaviorManager.signalCollections{
            print("collectionList",collectionList)

            for(_,value) in collectionList {
                print("export collection by name",value.name,BehaviorManager.signalCollections.count)
                collectionJSON.append(value.protoToJSON());
            }
            
        }
        
        return JSON(collectionJSON);
    }
    
    func getAllBehaviorJSON()->JSON {
        var behaviorJSON = [JSON]()
        for (_, behavior) in BehaviorManager.behaviors {
            let data:JSON = behavior.toJSON();
            
            behaviorJSON.append(data);
        }
       
        return JSON(behaviorJSON);
        
    }
    
    func getBehaviorJSON(name:String) throws->String{
        if(BehaviorManager.behaviors[name] != nil){
            var behaviorJSON:JSON = BehaviorManager.behaviors[name]!.toJSON();
            return behaviorJSON.stringValue;
        }
        else{
            throw BehaviorError.behaviorDoesNotExist;
        }
        
    }
    
    public static func getSignal(id:String)->Signal? {
        for collectionList in BehaviorManager.signalCollections{
            for(_,collection) in collectionList{
                let signal = collection.getInitializedSignal(id:id);
                if( signal != nil){
                    return signal;
                }
            }
        }
        return nil;
    }
    
    public static func getCollectionName(id:String)->String?{
        for collectionList in BehaviorManager.signalCollections{
            if (collectionList[id] != nil){
                return collectionList[id]?.name;
            }
        }
        return nil;
    }
    
    func defaultSetup(name:String) throws->BehaviorDefinition {
        let b = BehaviorDefinition(id:NSUUID().uuidString,name: name)
        //TODO: add check for if name is a duplicate
        if(BehaviorManager.behaviors[name] != nil){
            throw BehaviorError.duplicateName;
        }
        else{
            
            BehaviorManager.behaviors[name] = b;
            
            b.addState(stateId: NSUUID().uuidString,stateName:"start", stateX: 20.0, stateY:150.0)
            
            b.addState(stateId: NSUUID().uuidString,stateName:"default", stateX: 1000.0, stateY: 150.0)
            
            b.addTransition(transitionId: NSUUID().uuidString, name: "setup", eventEmitter: nil, parentFlag: false, event: "STATE_COMPLETE", fromStateId: "start", toStateId:"default", condition: nil, displayName: "state complete")
            return b;
        }
        
        
    }
    
    
    
    
    
    
    
}

