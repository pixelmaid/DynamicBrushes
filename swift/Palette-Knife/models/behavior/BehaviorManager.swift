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
}

class BehaviorManager{
    static var behaviors = [String:BehaviorDefinition]()
    var activeBehavior:BehaviorDefinition?;
    var canvas:Canvas
    init(canvas:Canvas){
        self.canvas = canvas;
       
    }
    
  
    
    static func getBehaviorById(id:String)->BehaviorDefinition{
        return BehaviorManager.behaviors[id]!
    }
    
    func loadBehavior(json:JSON){
            print("json =\(json)")
            self.loadBehaviorsFromJSON(json: json, rewriteAll: true)
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
            activeBehavior = behavior
            let brush = Brush(name: "brush_"+key, behaviorDef: behavior, parent: nil, canvas: canvas)
            behavior.createBehavior();
            BehaviorManager.behaviors[key] = behavior;
            
        }
    }
    
    func handleAuthoringRequest(authoring_data:JSON) throws->JSON{
        let data = authoring_data["data"] as JSON;
        let type = data["type"].stringValue;
        print("authoring request \(type)");
        var resultJSON:JSON = [:]
        resultJSON["type"] = JSON("authoring_response");
        resultJSON["authoring_type"] = JSON(type);

        switch(type){
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
            let setupId = data["setupId"].stringValue;
            let endId = data["dieId"].stringValue;
            print("behaviors with name\(name, BehaviorManager.behaviors[name])");
            
            let behavior = BehaviorDefinition(id:data["id"].stringValue, name: data["name"].stringValue);
            if(BehaviorManager.behaviors[id] != nil){
                throw BehaviorError.duplicateName;
            }
            else{
                BehaviorManager.behaviors[id] = behavior;
                activeBehavior = behavior;
                activeBehavior?.addState(stateId: setupId, stateName: "setup", stateX: 20.0, stateY:150.0);
                activeBehavior?.addState(stateId: endId, stateName: "die", stateX: 1000.0, stateY: 150.0);
                
                let brush = Brush(name: "brush_"+data["id"].stringValue, behaviorDef: activeBehavior, parent: nil, canvas: canvas)
                
                resultJSON["result"] = "success";
                return resultJSON;
            }
            

            
        case "state_added":
            print("state added behaviors \(BehaviorManager.behaviors.count,data["behaviorId"].stringValue,BehaviorManager.behaviors)");
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.parseStateJSON(data:data);
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior()
            
            
            resultJSON["result"] = "success";
            return resultJSON;
        case "state_removed":
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeState(stateId: data["stateId"].stringValue);
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior()
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "transition_added","transition_event_added", "transition_event_condition_changed":

          
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.parseTransitionJSON(data:data)
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior()
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "transition_removed":
            do{
                try BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeTransition(id: data["transitionId"].stringValue);
                BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior()
                
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
                BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior();
                resultJSON["result"] = "success";
                return resultJSON;            }
            catch{
                resultJSON["result"] = "failure";
                return resultJSON;            }
            
   
            
        case "method_added","method_argument_changed":
            let behaviorId = data["behaviorId"].stringValue
            let methodJSON = BehaviorManager.behaviors[behaviorId]!.parseMethodJSON(data: data)
            BehaviorManager.behaviors[behaviorId]!.createBehavior();
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
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior();
            print("removed method");
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "mapping_added":
            let behaviorId = data["behaviorId"].stringValue;
            
            BehaviorManager.behaviors[behaviorId]!.parseMappingJSON(data:data)
            BehaviorManager.behaviors[behaviorId]!.createBehavior()
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "mapping_updated":
            let behaviorId = data["behaviorId"].stringValue;
            
            print("behavior update mapping, target state:\(data["stateId"].stringValue)");
            
            BehaviorManager.behaviors[behaviorId]!.parseMappingJSON(data: data)
            BehaviorManager.behaviors[behaviorId]!.createBehavior()
            
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "expression_text_modified":
            let behaviorId = data["behaviorId"].stringValue;
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.parseExpressionJSON(data:data)
            
            BehaviorManager.behaviors[behaviorId]!.createBehavior()
            
            resultJSON["result"] = "success";
            return resultJSON;
            
        case "mapping_relative_removed":
            
            do{
                try BehaviorManager.behaviors[data["behaviorId"].stringValue]!.removeMapping(id: data["mappingId"].stringValue);
                BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior()
                
                resultJSON["result"] = "success";
                return resultJSON;
            }
            catch{
                print("mapping id does not exist, cannot remove");
                resultJSON["result"] = "failure";
                return resultJSON;
            }
            
        case "mapping_reference_removed":
            let behaviorId = data["behaviorId"].stringValue;
            
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.parseExpressionJSON(data:data)
            
            resultJSON["result"] = "success";
            return resultJSON;
            
            
        case "generator_added":
          
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.parseGeneratorJSON(data:data)
            BehaviorManager.behaviors[data["behaviorId"].stringValue]!.createBehavior()
            
            resultJSON["result"] = "success";
            return resultJSON;
            
            
        default:
            break
        }
        
        
        
        resultJSON["result"] = "failure";
        return resultJSON;
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
    
    func initSpawnTemplate(name:String)->BehaviorDefinition?{
        do {
            let b = try defaultSetup(name: name);
            
            
            b.addMethod(targetTransition: "setup", methodId:NSUUID().uuidString, targetMethod: "newStroke", arguments:nil)
            b.addMethod(targetTransition: "setup", methodId:NSUUID().uuidString, targetMethod: "setOrigin", arguments: ["parent"])
            b.addMethod(targetTransition: "setup", methodId: NSUUID().uuidString, targetMethod: "startInterval", arguments: nil);
            return b;
            
        }
        catch {
            return nil;
        }
    }
    
    func initStandardTemplate(name:String) ->BehaviorDefinition?{
        
        do {
            let b = try defaultSetup(name: name);
            
            b.addTransition(transitionId: NSUUID().uuidString, name:"stylusDownTransition", eventEmitter: stylus, parentFlag:false, event: "STYLUS_DOWN", fromStateId: b.getStateByName(name: "default")!, toStateId: b.getStateByName(name: "default")!, condition:nil, displayName: "foo")
            b.addTransition(transitionId: NSUUID().uuidString, name:"stylusUpTransition", eventEmitter: stylus, parentFlag:false, event: "STYLUS_UP", fromStateId: b.getStateByName(name: "default")!, toStateId: b.getStateByName(name: "default")!, condition:nil, displayName: "foo")
            
            b.addMethod(targetTransition: "stylusDownTransition", methodId:NSUUID().uuidString, targetMethod: "setOrigin", arguments: [stylus.position])
            b.addMethod(targetTransition: "stylusDownTransition", methodId:NSUUID().uuidString, targetMethod: "newStroke", arguments: nil)
            b.addMethod(targetTransition: "stylusDownTransition", methodId:NSUUID().uuidString, targetMethod: "startInterval", arguments: nil)
            b.addMethod(targetTransition: "stylusUpTransition", methodId:NSUUID().uuidString, targetMethod: "stopInterval", arguments: nil)
            
            
            b.addMapping(id: NSUUID().uuidString, referenceProperty:stylus, referenceNames: ["dx"], relativePropertyName: "dx", stateId: "default", type:"active",relativePropertyItemName:"foo")
            b.addMapping(id: NSUUID().uuidString, referenceProperty:stylus, referenceNames: ["dy"], relativePropertyName: "dy", stateId: "default", type:"active",relativePropertyItemName:"foo")
            // b.addMapping(NSUUID().UUIDString, referenceProperty:stylus, referenceNames: ["force"], relativePropertyName: "weight", stateId: "default")
            
            return b;
        }
        catch {
            return nil;
        }
        
    }
    
    
    //---------------------------------- HARDCODED BEHAVIORS ---------------------------------- //
    func initBakeBehavior()->BehaviorDefinition?{
        let b1 = initStandardTemplate(name: "b1");
        
        
        b1!.addTransition(transitionId: NSUUID().uuidString, name:"stylusUpT", eventEmitter: stylus, parentFlag:false, event: "STYLUS_UP", fromStateId: b1!.getStateByName(name: "default")!, toStateId: b1!.getStateByName(name: "default")!, condition:nil, displayName: "foo");
        
        
        b1!.addMethod(targetTransition: "stylusUpT", methodId:NSUUID().uuidString, targetMethod: "bake", arguments: nil)
        //b1.addMethod("stylusUpT", methodId:NSUUID().UUIDString, targetMethod: "liftUp", arguments: nil)
        
        b1!.addMethod(targetTransition: "stylusDownTransition",methodId:NSUUID().uuidString,targetMethod: "jogTo", arguments: [stylus.position])
        
        return b1;
    }
    
    func initDripBehavior()->BehaviorDefinition?{
        let dripBehavior = initSpawnTemplate(name: "dripBehavior");
        
        dripBehavior!.addLogiGrowthGenerator(name: "weightGenerator", a:10,b:15,k:0.36);
        //  dripBehavior!.addExpression("weightExpression", emitter1: nil, operand1Names:["weight"], emitter2: nil, operand2Names: ["weightGenerator"], type: "add")
        dripBehavior!.addRandomGenerator(name: "randomTimeGenerator", min:50, max: 100)
        dripBehavior!.addCondition(name: "lengthCondition", reference: nil, referenceNames: ["distance"], relative: nil, relativeNames: ["randomTimeGenerator"], relational: ">")
        dripBehavior!.addState(stateId: NSUUID().uuidString, stateName: "die",stateX:0,stateY:0);
        
        dripBehavior!.addTransition(transitionId: NSUUID().uuidString, name: "tickTransition", eventEmitter: nil, parentFlag: false, event: "TICK", fromStateId: "default", toStateId: "default", condition: nil, displayName: "foo")
        dripBehavior!.addMapping(id: NSUUID().uuidString, referenceProperty: Observable<Float>(2), referenceNames: nil, relativePropertyName: "dy", stateId: "default", type:"active",relativePropertyItemName:"foo")
        
        dripBehavior!.addMapping(id: NSUUID().uuidString, referenceProperty: nil, referenceNames: ["weightExpression"], relativePropertyName: "weight", stateId: "default", type:"active",relativePropertyItemName:"foo")
        
        
        
        dripBehavior!.addTransition(transitionId: NSUUID().uuidString, name: "dieTransition", eventEmitter: nil, parentFlag: false, event: "TICK", fromStateId: dripBehavior!.getStateByName(name: "default")!, toStateId: dripBehavior!.getStateByName(name: "die")!, condition: "lengthCondition", displayName: "foo")
        
        
        let parentBehavior = initStandardTemplate(name: "parentBehavior");
        parentBehavior!.addInterval(name: "lengthInterval", inc: 100, times: nil)
        parentBehavior!.addCondition(name: "lengthCondition", reference: nil, referenceNames: ["distance"], relative: nil, relativeNames: ["lengthInterval"], relational: "within")
        parentBehavior!.addTransition(transitionId: NSUUID().uuidString, name: "lengthTransition", eventEmitter: nil, parentFlag: false, event: "TICK", fromStateId: parentBehavior!.getStateByName(name: "default")!, toStateId: parentBehavior!.getStateByName(name: "default")!, condition: "lengthCondition", displayName: "foo")
        parentBehavior!.addMethod(targetTransition: "lengthTransition", methodId: NSUUID().uuidString, targetMethod: "spawn", arguments: ["dripBehavior",dripBehavior as Any,1]);
        
        return parentBehavior;
        
        
    }
    
    func initRadialBehavior()->BehaviorDefinition?{
        do{
            let radial_spawnBehavior = initSpawnTemplate(name: "radial_spawn_behavior");
            //   radial_spawnBehavior!.addExpression("angle_expression", emitter1: nil, operand1Names: ["index"], emitter2: Observable<Float>(60), operand2Names: nil, type: "mult")
            
            radial_spawnBehavior!.addMapping(id: NSUUID().uuidString, referenceProperty: nil, referenceNames: ["angle_expression"], relativePropertyName: "angle", stateId: "start", type:"active",relativePropertyItemName:"foo")
            
            radial_spawnBehavior!.addMapping(id: NSUUID().uuidString, referenceProperty:stylus, referenceNames: ["dx"], relativePropertyName: "dx", stateId: "default", type:"active",relativePropertyItemName:"foo")
            radial_spawnBehavior!.addMapping(id: NSUUID().uuidString, referenceProperty:stylus, referenceNames: ["dy"], relativePropertyName: "dy", stateId: "default", type:"active",relativePropertyItemName:"foo")
            
            
            radial_spawnBehavior!.addState(stateId: NSUUID().uuidString,stateName:"die",stateX:0,stateY:0)
            
            radial_spawnBehavior!.addTransition(transitionId: NSUUID().uuidString, name: "dieTransition", eventEmitter: stylus, parentFlag: false, event: "STYLUS_UP", fromStateId: radial_spawnBehavior!.getStateByName(name: "default")!, toStateId:  radial_spawnBehavior!.getStateByName(name: "die")!, condition: nil, displayName: "foo")
            
            radial_spawnBehavior!.addMethod(targetTransition: "dieTransition", methodId:NSUUID().uuidString, targetMethod: "jogAndBake", arguments: nil)
            
            
            
            let radial_behavior = try defaultSetup(name: "radial_behavior");
            
            radial_behavior.addTransition(transitionId: NSUUID().uuidString, name:"stylusDownTransition", eventEmitter: stylus, parentFlag:false, event: "STYLUS_DOWN", fromStateId: radial_behavior.getStateByName(name: "default")!, toStateId: radial_behavior.getStateByName(name: "default")!, condition:nil, displayName: "foo")
            radial_behavior.addTransition(transitionId: NSUUID().uuidString, name:"stylusUpTransition", eventEmitter: stylus, parentFlag:false, event: "STYLUS_UP", fromStateId: radial_behavior.getStateByName(name: "default")!, toStateId: radial_behavior.getStateByName(name: "default")!, condition:nil, displayName: "foo")
            
            radial_behavior.addMethod(targetTransition: "stylusDownTransition", methodId:NSUUID().uuidString, targetMethod: "setOrigin", arguments: [stylus.position])
            radial_behavior.addMethod(targetTransition: "stylusDownTransition", methodId:NSUUID().uuidString, targetMethod: "startInterval", arguments: nil)
            radial_behavior.addMethod(targetTransition: "stylusUpTransition", methodId:NSUUID().uuidString, targetMethod: "stopInterval", arguments: nil)
            
            
            
            
            radial_behavior.addMethod(targetTransition: "stylusDownTransition", methodId:NSUUID().uuidString, targetMethod: "spawn", arguments: ["radial_spawn_behavior",radial_spawnBehavior!,6])
            radial_behavior.addMethod(targetTransition: "stylusDownTransition",methodId:NSUUID().uuidString,targetMethod: "jogTo", arguments: [stylus.position])
            return radial_behavior
            
        }
        catch{
            return nil;
        }
        
    }
    
    func initFractalBehavior()->BehaviorDefinition?{
        do{
            let branchBehavior =  try defaultSetup(name: "branch");
            let rootBehavior =  try defaultSetup(name: "root");
            
            branchBehavior.addRandomGenerator(name: "random1", min: 2 , max: 5)
            branchBehavior.addState(stateId: NSUUID().uuidString,stateName:"spawnEnd",stateX:0,stateY:0);
            
            
            branchBehavior.addCondition(name: "spawnCondition", reference: nil, referenceNames: ["ancestors"], relative: Observable<Float>(2), relativeNames: nil, relational: "<")
            branchBehavior.addCondition(name: "noSpawnCondition", reference: nil, referenceNames: ["ancestors"], relative: Observable<Float>(1), relativeNames: nil, relational: ">")
            
            
            branchBehavior.addState(stateId: NSUUID().uuidString,stateName: "die",stateX:0,stateY:0);
            
            branchBehavior.addCondition(name: "timeLimitCondition", reference: nil, referenceNames: ["time"], relative: nil, relativeNames: ["random1"], relational: ">")
            
            branchBehavior.addCondition(name: "offCanvasCondition", reference: nil, referenceNames: ["offCanvas"], relative: Observable<Float>(1), relativeNames: nil, relational: "==")
            
            
            branchBehavior.addTransition(transitionId: NSUUID().uuidString, name: "destroyTransition", eventEmitter: nil, parentFlag: false, event: "TICK", fromStateId: branchBehavior.getStateByName(name: "default")!, toStateId: branchBehavior.getStateByName(name: "die")!, condition: "timeLimitCondition", displayName: "foo")
            
            branchBehavior.addTransition(transitionId: NSUUID().uuidString, name: "offCanvasTransition", eventEmitter: nil, parentFlag: false, event: "STATE_COMPLETE", fromStateId: branchBehavior.getStateByName(name: "default")!, toStateId: branchBehavior.getStateByName(name: "die")!, condition: "offCanvasCondition", displayName: "foo")
            
            branchBehavior.addMethod(targetTransition: "destroyTransition",methodId:NSUUID().uuidString,targetMethod: "jogAndBake", arguments: nil)
            branchBehavior.addMethod(targetTransition: "offCanvasTransition",methodId:NSUUID().uuidString,targetMethod: "jogAndBake", arguments: nil)
            
            
            // branchBehavior.addMethod("destroyTransition", methodId: NSUUID().UUIDString, targetMethod: "destroy", arguments: nil)
            
            // branchBehavior.addMethod("defaultdestroyTransition", methodId: NSUUID().UUIDString, targetMethod: "destroy", arguments: nil)
            
            
            branchBehavior.addTransition(transitionId: NSUUID().uuidString, name:"spawnTransition" , eventEmitter: nil, parentFlag: false, event: "STATE_COMPLETE", fromStateId: branchBehavior.getStateByName(name: "die")!, toStateId: branchBehavior.getStateByName(name: "spawnEnd")!, condition: "spawnCondition", displayName: "foo")
            
            // branchBehavior.addMethod("spawnTransition", methodId: NSUUID().UUIDString, targetMethod: "spawn", arguments: ["branchBehavior",branchBehavior,2])
            
            branchBehavior.addMethod(targetTransition: "setup", methodId:NSUUID().uuidString, targetMethod: "newStroke", arguments:nil)
            branchBehavior.addMethod(targetTransition: "setup", methodId:NSUUID().uuidString, targetMethod: "setOrigin", arguments: ["parent"])
            branchBehavior.addMethod(targetTransition: "setup", methodId:NSUUID().uuidString, targetMethod: "startInterval", arguments:nil)
            branchBehavior.addMethod(targetTransition: "spawnEnd",  methodId:NSUUID().uuidString, targetMethod: "destroy", arguments:nil)
            
            //branchBehavior.addExpression("xDeltaExp", emitter1: nil, operand1Names: ["parent","currentStroke","xBuffer"],emitter2: Observable<Float>(0.65), operand2Names: nil, type: "mult")
            
            
            //branchBehavior.addExpression("yDeltaExp", emitter1: nil, operand1Names: ["parent","currentStroke","yBuffer"], emitter2: /Observable<Float>(0.65), operand2Names: nil, type: "mult")
            
            // branchBehavior.addExpression("weightDeltaExp", emitter1: nil, operand1Names: ["parent","currentStroke","weightBuffer"],  emitter2: Observable<Float>(0.45), operand2Names: nil,type: "mult")
            
            
            branchBehavior.addMapping(id: NSUUID().uuidString, referenceProperty:nil, referenceNames: ["xDeltaExp"], relativePropertyName: "dx", stateId: "default", type:"active",relativePropertyItemName:"foo")
            branchBehavior.addMapping(id: NSUUID().uuidString, referenceProperty:nil, referenceNames: ["yDeltaExp"], relativePropertyName: "dy", stateId: "default", type:"active",relativePropertyItemName:"foo")
            
            branchBehavior.addMapping(id: NSUUID().uuidString, referenceProperty:nil, referenceNames:["weightDeltaExp"], relativePropertyName: "weight", stateId: "default", type:"active",relativePropertyItemName:"foo")
            
            
            branchBehavior.addTransition(transitionId: NSUUID().uuidString, name: "tickTransition", eventEmitter: nil, parentFlag: false, event: "TICK", fromStateId: branchBehavior.getStateByName(name: "default")!, toStateId:branchBehavior.getStateByName(name: "default")!, condition: nil, displayName: "foo")
            
            
            
            
            rootBehavior.addInterval(name: "timeInterval",inc:1,times:nil)
            
            
            rootBehavior.addCondition(name: "stylusDownCondition", reference:stylus, referenceNames: ["penDown"], relative:Observable<Float>(1), relativeNames:nil, relational: "==")
            
            rootBehavior.addCondition(name: "incrementCondition", reference: nil, referenceNames: ["time"], relative:nil, relativeNames: ["timeInterval"], relational: "within")
            
            rootBehavior.addCondition(name: "stylusANDIncrement",reference: nil, referenceNames: ["stylusDownCondition"], relative:nil, relativeNames: ["incrementCondition"], relational: "&&");
            
            rootBehavior.addTransition(transitionId: NSUUID().uuidString, name:"stylusDownT", eventEmitter: stylus, parentFlag:false, event: "STYLUS_DOWN", fromStateId: rootBehavior.getStateByName(name: "default")!, toStateId: rootBehavior.getStateByName(name: "default")!, condition:nil, displayName: "foo")
            
            rootBehavior.addMethod(targetTransition: "stylusDownT", methodId:NSUUID().uuidString, targetMethod: "setOrigin", arguments: [stylus.position])
            rootBehavior.addMethod(targetTransition: "stylusDownT", methodId:NSUUID().uuidString, targetMethod: "newStroke", arguments: nil)
            rootBehavior.addMethod(targetTransition: "stylusDownT", methodId:NSUUID().uuidString, targetMethod: "startInterval", arguments: nil)
            
            rootBehavior.addMapping(id: NSUUID().uuidString, referenceProperty:stylus, referenceNames: ["dx"], relativePropertyName: "dx", stateId: "default", type:"active",relativePropertyItemName:"foo")
            
            rootBehavior.addMapping(id: NSUUID().uuidString, referenceProperty:stylus,  referenceNames: ["dy"], relativePropertyName: "dy", stateId: "default", type:"active",relativePropertyItemName:"foo")
            
            rootBehavior.addMapping(id: NSUUID().uuidString, referenceProperty:stylus,  referenceNames: ["force"], relativePropertyName: "weight", stateId: "default", type:"active",relativePropertyItemName:"foo")
            
            
            rootBehavior.addTransition(transitionId: NSUUID().uuidString, name: "spawnTransition", eventEmitter: nil, parentFlag: false, event: "TICK", fromStateId: rootBehavior.getStateByName(name: "default")!, toStateId: rootBehavior.getStateByName(name: "default")!, condition: "stylusANDIncrement", displayName: "foo")
            
            rootBehavior.addTransition(transitionId: NSUUID().uuidString, name:"stylusUpT", eventEmitter: stylus, parentFlag:false, event: "STYLUS_UP", fromStateId: rootBehavior.getStateByName(name: "default")!, toStateId: rootBehavior.getStateByName(name: "default")!, condition:nil, displayName: "foo")
            
            rootBehavior.addMethod(targetTransition: "spawnTransition", methodId: NSUUID().uuidString, targetMethod: "spawn", arguments: ["branchBehavior",branchBehavior,2])
            
            //rootBehavior.addMethod("stylusUpT", methodId:NSUUID().UUIDString, targetMethod: "bake", arguments: nil)
            rootBehavior.addMethod(targetTransition: "stylusUpT", methodId:NSUUID().uuidString, targetMethod: "jogAndBake", arguments: nil)
            
            //  rootBehavior.addMethod("stylusDownT",methodId:NSUUID().UUIDString,targetMethod: "jogTo", arguments: nil)
            
            
            return rootBehavior;
        }
        catch{
            return nil
        }
        
        
        
    }
    
    //---------------------------------- END HARDCODED BEHAVIORS ---------------------------------- //
    
    
    
}

