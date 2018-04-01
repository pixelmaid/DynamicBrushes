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
    case conditionDoesNotExist;
    case expressionDoesNotExist;
    case requestDoesNotExist;
    case collectionDoesNotExist
}

class BehaviorManager{
    static var behaviors = [String:BehaviorDefinition]()
  // static var imported = [String:SignalCollection]();
  //  static var recordings = [String:SignalCollection]();
   // static var generators = [String:GeneratorCollection]();
   // static var liveInputs = [String:LiveCollection]();
    static var signalCollections = [[String:ImportedCollection](), [String:SignalCollection](),[String:GeneratorCollection](),[String:LiveCollection]()];

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
        print("data to load",json);
        BehaviorManager.loadCollectionsFromJSON(data: json["collections"]);
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
    
    
    func handleDataRequest(requestData:JSON) ->JSON{
        let data = requestData["data"] as JSON;
        let type = data["type"].stringValue;
        var resultJSON:JSON = [:]
        resultJSON["type"] = JSON("data_request_response");
        resultJSON["request_type"] = JSON(type);
        switch(type){
        case "request_existing_mappings":
            let behaviorId = data["behaviorId"].stringValue;
            let stateId = data["stateId"].stringValue;
             let behavior = BehaviorManager.behaviors[behaviorId]!;
            var data:JSON = [:]
            data["states"] = behavior.getMappings();
            data["behaviorId"] = JSON(behaviorId);
            resultJSON["data"] = data;
            
            break;
        default:
            break;
            
        }
        
        return resultJSON;
        
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
            
        case "transition_added":
            let behaviorID = data["behaviorId"].stringValue;
            let targetBehavior = BehaviorManager.behaviors[behaviorID]!
            targetBehavior.parseExpressionJSON(data: data["referenceA"]);
            targetBehavior.parseExpressionJSON(data: data["referenceB"]);
            targetBehavior.parseConditionJSON(data: data["condition"]);
            targetBehavior.parseTransitionJSON(data:data)
            targetBehavior.createBehavior(canvas:canvas)
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "transition_removed":
            do{
                try BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeTransition(id: data["transitionId"].stringValue);
                BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas)
                
                resultJSON["result"] = "success";
                return resultJSON;
                
            }
            catch{
                print("transition id does not exist, cannot remove");
                resultJSON["result"] = "failure";
                return resultJSON;
            }
           
        case "relational_changed":
            let behaviorID = data["behaviorId"].stringValue;
            let targetBehavior = BehaviorManager.behaviors[behaviorID]!
             do {
                try targetBehavior.changeConditionRelational(conditionId:data["conditionId"].stringValue,relational:data["relational"].stringValue);
                BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas)
                resultJSON["result"] = "success";
                return resultJSON;
            }
             catch{
                print("condition id does not exist, cannot change relational");
                resultJSON["result"] = "failure";
                return resultJSON;
            }

            
        case "method_added":
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
         
        //TODO: add case for method argument change
            //case "method_argument_changed":
        
        
        //return
        case "method_removed":
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeMethod(methodId: data["methodId"].stringValue)
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior(canvas:canvas);
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "mapping_added":
            let behaviorId = data["behaviorId"].stringValue;
            BehaviorManager.behaviors[behaviorId]!.parseExpressionJSON(data:data)
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
                return resultJSON;
            }
            catch{
                resultJSON["result"] = "failure";
                return resultJSON;
            }
       
        
        case "signal_destroyed":
            do {
                let signalId = data["signalId"].stringValue
                try self.destroySignalInstance(id:signalId)
              
            }
            catch{
                #if DEBUG
                    print("=================ERROR SIGNAL NOT FOUND TO DESTROY====================")
                #endif
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
          let signalCollection = BehaviorManager.parseImported(data:data["dataset"])
          
            resultJSON["result"] = "success";
            resultJSON["dataset"] = JSON([signalCollection.protoToJSON()]);
            return resultJSON;
            
        default:
            break
        }
        
        
        
        resultJSON["result"] = "failure";
        return resultJSON;
    }
    
    
    private func destroySignalInstance(id:String) throws{
        for collectionList in BehaviorManager.signalCollections{
            for(_,collection) in collectionList{
                var signal = collection.getInitializedSignal(id:id);
                if( signal != nil){
                    collection.removeSignal(fieldName: signal!.fieldName, id: signal!.id)
                    signal = nil
                    return;
                }
            }
        }
        throw SignalError.signalNotFound
    }
    
 private func parseSignalJSON(data:JSON) throws->JSON?{
        let classType = data["classType"].stringValue;
        let collectionId = data["collectionId"].stringValue;
        let fieldName = data["fieldName"].stringValue;
        let displayName = data["displayName"].stringValue;
        let style = data["style"].stringValue;
        let settings  = data["settings"];
        let id:String

    do {
    switch classType{
        case "generator":
            guard let generatorCollection = BehaviorManager.signalCollections[2]["default"] else {
                print("===========ERROR GENERATOR COLLECTION DOES NOT EXIST===================")
                
                throw BehaviorError.collectionDoesNotExist;
            }
            id = generatorCollection.initializeSignal(fieldName:fieldName,displayName:displayName,settings:settings,classType: classType, style:style, isProto: false, order:nil);
            print(generatorCollection.initializedSignals);
        break;
        case "imported":
            guard let dataCollection = BehaviorManager.signalCollections[0][collectionId] else {
                print("===========ERROR DATA COLLECTION DOES NOT EXIST===================")

                throw BehaviorError.collectionDoesNotExist;
            }
             id = dataCollection.initializeSignal(fieldName:fieldName,displayName:displayName,settings:settings,classType: classType, style:style, isProto: false, order:nil);
            print(dataCollection.initializedSignals);


        break;
        case "live":
            guard let liveCollection = BehaviorManager.signalCollections[3][collectionId] else {
                print("===========ERROR LIVE COLLECTION DOES NOT EXIST===================")

                throw BehaviorError.collectionDoesNotExist;

            }
            id = liveCollection.initializeSignal(fieldName:fieldName,displayName:displayName,settings:settings,classType: classType,style:style, isProto: false, order:nil);
            
            print(liveCollection.initializedSignals);

        break;
        case "recording":
            guard let recordingCollection = BehaviorManager.signalCollections[1][collectionId] else {
                print("===========ERROR RECORDING COLLECTION DOES NOT EXIST===================")

                throw BehaviorError.collectionDoesNotExist;
                
            }
             id = recordingCollection.initializeSignal(fieldName:fieldName,displayName:displayName,settings:settings,classType: classType, style:style,isProto: false, order:nil);
            print(recordingCollection.initializedSignals);


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
                print("===========ERROR INITIALIZING SIGNAL===================")
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
        
        let collectionData = data.arrayValue;
        for collection in collectionData{
            let key = collection["classType"].stringValue;
            print("key",key);
            switch (key){
            case "live":
                    let signalCollection:LiveCollection;
                    if collection["name"] == "stylus"{
                        signalCollection = StylusCollection(data:collection);
                        stylusManager.registerCollection(id: signalCollection.id, collection:signalCollection as! StylusCollection);
                    }
                    else if collection["name"] == "ui"{
                        signalCollection = UICollection(data:collection);
                        uiManager.registerCollection(id: signalCollection.id, collection:signalCollection as! UICollection);

                    }
                    else if collection["name"] == "mic" {
                        signalCollection = MicCollection(data:collection);
                        micManager.registerCollection(id: signalCollection.id, collection:signalCollection as! MicCollection);
                    }
                    else{
                        signalCollection = LiveCollection(data:collection);
                    }
                   BehaviorManager.signalCollections[3][signalCollection.id] = signalCollection;

                
                break;
            case "imported":
                
                    let signalCollection = ImportedCollection(data:collection);
                   BehaviorManager.signalCollections[0][signalCollection.id] = signalCollection;
                
                break;
            case "generator":
                    let signalCollection = GeneratorCollection(data:collection);
                    BehaviorManager.signalCollections[2][signalCollection.id] = signalCollection;
                
                break;
            case "recording":
               
                    print("collection id",collection["id"].stringValue);

                    if(collection["id"].stringValue == "recording_preset"){
                        stylusManager.setRecordingPresetData(data: collection);
                    }
                    else{
                        let signalCollection = RecordingCollection(data:collection);
                       BehaviorManager.signalCollections[1][signalCollection.id] = signalCollection;
                    }
                
                break;
            case "drawing":
                break;
            case "brush":
                break;
            default:
                break;
            }
        }
    }
    
    
    static func register(collectionId:String,recording:SignalCollection){
        BehaviorManager.signalCollections[1][collectionId] = recording;
    }
    
    
   static func parseImported(data:JSON)->SignalCollection{
    print("imported data",data);
    let id = data["id"].stringValue;
    let signalCollection = SignalCollection(data: data);
    signalCollections[0][id] = signalCollection;
    print("imported count",signalCollections[0]);
    return signalCollection;
  
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
    
    
   static func getAllBehaviorAndCollectionJSON()->JSON{
        let behavior:JSON = BehaviorManager.getAllBehaviorJSON();
        let collections:JSON = BehaviorManager.getAllCollectionJSON();
        var syncJSON:JSON = [:]
        syncJSON["behaviors"] = behavior;
        syncJSON["collections"] = collections;
        return syncJSON;
    }
    
  static  func getAllBehaviorJSON()->JSON {
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

    
    
    
    
}

