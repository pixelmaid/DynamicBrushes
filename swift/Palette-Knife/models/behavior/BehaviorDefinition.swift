//
//  BehaviorDefinition.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/27/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import SwiftKVC
import SwiftyJSON

class BehaviorDefinition {
    
    var brushInstances = [Brush]();
    var states = [String:(String,Float,Float)]()
    var expressions = [String:([String],String)]();
    var conditions = [(String,Any?,[String]?,Any?,[String]?,String)]()
    // var generators = [String:(String,[Any?])]()
    var methods = [String:[(String,String,String,[Any]?)]]()
    var transitions = [String:(String,Emitter?,Bool,String?,String,String,String?,String)]()
    var behaviorMapper = BehaviorMapper()
    var mappings = [String:(Any?,[String]?,String,String,String,String)]()
    
    var storedExpressions = [String:[String:Expression]]()
    var storedConditions =  [String:[String:Condition]]()
    //var storedGenerators = [String:[String:Signal]]()
    
    var name:String;
    var id: String;
    private var active_status:Bool;
    private var auto_spawn_num = 0;
    
    init(id:String, name:String){
        self.name = name;
        self.id = id;
        self.active_status = true;
    }
    
    
    func setActiveStatus(status:Bool){
        self.active_status = status;
    }
    
    func setAutoSpawnNum(num:Int){
        self.auto_spawn_num = num;
    }
    
    func parseJSON(json:JSON){
        self.setActiveStatus(status:json["active_status"].boolValue);
        self.setAutoSpawnNum(num:json["auto_spawn_num"].intValue);
        let stateJSON = json["states"].arrayValue;
        let transitionJSON = json["transitions"].arrayValue;
        let mappingJSON = json["mappings"].arrayValue;
        let methodJSON = json["methods"].arrayValue;
        let conditionJSON = json["conditions"].arrayValue;
        
        for i in 0..<conditionJSON.count{
            self.parseConditionJSON(data:conditionJSON[i])
        }
        for i in 0..<stateJSON.count{
            self.parseStateJSON(data: stateJSON[i])
        }
        for i in 0..<transitionJSON.count{
            self.parseTransitionJSON(data: transitionJSON[i])
            
            
        }
        for i in 0..<mappingJSON.count{
            self.parseMappingJSON(data: mappingJSON[i])
            
        }
        
        for i in 0..<methodJSON.count{
            _ = self.parseMethodJSON(data:methodJSON[i]);
        }
        
    }
    
    
    
    func parseConditionJSON(data:JSON){
        let name = data["name"].stringValue
        var reference:Any? = nil
        if(data["reference"] != JSON.null){
            let refString = data["reference"].stringValue
            switch(refString){
            case "stylus":
                reference = stylus
                break
            case "parent":
                reference = "parent"
                break
            default:
                break;
            }
        }
        else{
            reference = nil
        }
        
        var referenceNames:[String]? = nil
        if(data["referenceNames"] != JSON.null){
            let referenceNamesJSON = data["referenceNames"].arrayValue;
            referenceNames = [String]()
            for i in 0..<referenceNamesJSON.count{
                referenceNames?.append(referenceNamesJSON[i].stringValue)
                
            }
        }
        
        var relative:Any? = nil
        if(data["relative"] != JSON.null){
            let refString = data["relative"].stringValue
            switch(refString){
            case "stylus":
                relative = stylus
                break
            case "parent":
                relative = "parent"
                break
            default:
                break;
            }
        }
        
        
        var relativeNames:[String]? = nil
        if(data["relativeNames"] != JSON.null){
            let relativeNamesJSON = data["relativeNames"].arrayValue;
            relativeNames = [String]()
            for i in 0..<relativeNamesJSON.count{
                relativeNames?.append(relativeNamesJSON[i].stringValue)
                
            }
        }
        
        let relational = data["relational"].stringValue
        
        self.addCondition(name: name, reference: reference, referenceNames: referenceNames, relative: relative, relativeNames: relativeNames, relational: relational)
    }
    
    func parseExpressionJSON(data:JSON){
        
        let expressionId = data["expressionId"].stringValue;
        
        let expressionPropertyList = data["expressionPropertyList"].arrayValue;
        let expressionText = data["expressionText"].stringValue;
        var operandList = [String]();
        for i in 0..<expressionPropertyList.count{
            operandList.append(expressionPropertyList[i].stringValue);
        }
        #if DEBUG
            print("expression prop list",expressionPropertyList);
        #endif
        
        
        self.addExpression(id: expressionId, emitterOperandList: operandList, expressionText: expressionText)
    }
    
    
    func parseMappingJSON(data:JSON){
        self.parseExpressionJSON(data:data)
        
        let expressionId = data["expressionId"].stringValue;
        
        self.addMapping(id: data["mappingId"].stringValue, referenceProperty:nil, referenceNames: [expressionId], relativePropertyName: data["relativePropertyName"].stringValue, stateId: data["stateId"].stringValue,type: data["constraintType"].stringValue,relativePropertyFieldName: data["relativePropertyFieldName"].stringValue)
    }
    
    func parseMethodJSON(data:JSON)->JSON{
        self.parseExpressionJSON(data:data)
        let expressionId = data["expressionId"].stringValue;
        
        let targetTransition:String?
        if(data["targetTransition"] != JSON.null){
            targetTransition = data["targetTransition"].stringValue;
        }
        else{
            targetTransition = nil;
        }
        var arguments:[Any]? = nil;
        let dataArguments = data["currentArguments"];
        let targetMethod = data["targetMethod"].stringValue
        var methodJSON:JSON = [:]
        switch(targetMethod){
        case "spawn":
            let behavior:String;
            let num:Int;
            
            if(dataArguments != JSON.null){
                let spawnBehaviorId = (dataArguments.arrayValue)[0].stringValue;
                if(spawnBehaviorId == "self"){
                    behavior = self.id;
                }
                else{
                    behavior = spawnBehaviorId;
                }
                num = (dataArguments.arrayValue)[1].intValue
                
                arguments = [behavior,num];
            }
            else{
                arguments = ["self",1]
            }
            var behavior_list = [String:String]()
            
            behavior_list["self"] = "self";
            methodJSON["methodArguments"] = JSON(behavior_list);
            methodJSON["defaultArgument"] = JSON("self");
            methodJSON["hasArguments"] = JSON(true)
            
            break;
            
            
            
            
        case "setOrigin", "newStroke":
            if(dataArguments != JSON.null){
                let arg = (dataArguments.arrayValue)[0].stringValue;
                switch(arg){
                case "stylus_position":
                    arguments = [stylus.position];
                    break;
                case "parent_position":
                    arguments = ["parent_position"];
                    break;
                case "parent_origin":
                    arguments = ["parent_origin"];
                    break;
                default:
                    //TODO: handle arbitrary point values here
                    break;
                }
            }
            else{
                arguments = [stylus.position];
            }
            methodJSON["methodArguments"] = JSON(["stylus_position":"stylus_position","parent_position":"parent_position","parent_origin":"parent_origin" ])
            methodJSON["defaultArgument"] = JSON("stylus_position");
            methodJSON["hasArguments"] = JSON(true)
            
            break;
        case "startTimer":
            methodJSON["hasArguments"] = JSON(false)
            
            arguments = [];
            break;
        case "stopTimer":
            methodJSON["hasArguments"] = JSON(false)
            
            arguments = [];
            
            break;
        default:
            arguments = nil;
            break;
        }
        
        self.addMethod(targetTransition: targetTransition, methodId: data["methodId"].stringValue, targetMethod: targetMethod, expressionId:expressionId, arguments: arguments)
        
        return methodJSON;
    }
    
    
    func parseStateJSON(data:JSON){
        let stateId = data["id"].stringValue
        let stateName = data["name"].stringValue
        let stateX = data["x"].floatValue
        let stateY = data["y"].floatValue
        self.addState(stateId: stateId, stateName: stateName, stateX: stateX, stateY: stateY)
    }
    
    func parseTransitionJSON(data:JSON){
        let event = data["eventName"].stringValue;
        let emitter:Emitter?
        if(data["emitter"] != JSON.null){
            switch(data["emitter"].stringValue){
            case "stylus":
                emitter = stylus;
                break;
            default:
                emitter = nil;
                break;
            }
        }
        else{
            switch(event){
            case "STYLUS_UP","STYLUS_DOWN","STYLUS_MOVE_BY","STYLUS_X_MOVE_BY","STYLUS_Y_MOVE_BY":
                emitter = stylus
                break;
            default:
                emitter = nil
                break;
            }
        }
        
        var conditionName:String?
        
        if(data["conditionName"] != JSON.null){
            conditionName = data["conditionName"].stringValue;
        }
        else{
            
            let condition_list = data["conditions"].arrayValue;
            conditionName = "condition_" + NSUUID().uuidString
            //TODO: CLEAN THIS UP TO REMOVE CONDITIONAL on event check
            if(event != "STATE_COMPLETE"){
                
                var settings:JSON = [:]
                settings["inc"] = condition_list[0];
                let interval_id =  BehaviorManager.generators["default"]!.initializeSignal(fieldName:"interval",displayName:"interval",settings:settings,classType: "Interval",isProto:false);
                
                
                switch(event){
                case "TIME_INTERVAL":
                    self.addCondition(name: conditionName!, reference: nil, referenceNames: ["time"], relative: nil, relativeNames: [interval_id], relational: "within")
                    break;
                case "DISTANCE_INTERVAL":
                    self.addCondition(name: conditionName!, reference: nil, referenceNames: ["distance"], relative: nil, relativeNames: [interval_id], relational: "within")
                    break;
                case "INTERSECTION":
                    self.addCondition(name: conditionName!, reference: nil, referenceNames: ["intersections"], relative: nil, relativeNames: [interval_id], relational: "within")
                    break;
                case "STYLUS_MOVE_BY","STYLUS_X_MOVE_BY","STYLUS_Y_MOVE_BY":
                    let referenceName:String
                    if(event == "STYLUS_MOVE_BY"){
                        referenceName = "distance"
                    }
                    else if(event == "STYLUS_X_MOVE_BY"){
                        referenceName = "xDistance"
                    }
                    else{
                        referenceName = "yDistance"
                    }
                    self.addCondition(name: conditionName!, reference: stylus, referenceNames: [referenceName], relative: nil, relativeNames: [interval_id], relational: "within")
                    break;
                    
                    
                default:
                    conditionName = nil

                    break;
                    
                }
                
            }
            else{
                conditionName = nil

            }
        }
        
        
        self.addTransition(transitionId: data["transitionId"].stringValue, name: data["name"].stringValue, eventEmitter: emitter, parentFlag: data["parentFlag"].boolValue, event: data["eventName"].stringValue, fromStateId: data["fromStateId"].stringValue, toStateId: data["toStateId"].stringValue, condition: conditionName,displayName:data["displayName"].stringValue)
        
        
    }
    
    
    func toJSON()->JSON{
        var json_obj:JSON = [:]
        json_obj["name"] = JSON(self.name);
        json_obj["id"] = JSON(self.id);
        json_obj["active_status"] = JSON(self.active_status);
        json_obj["auto_spawn_num"] = JSON(self.auto_spawn_num);
        
        var conditionArray = [JSON]();
        for i in 0..<conditions.count {
            let data = conditions[i];
            var conditionJSON:JSON = [:]
            let name = data.0;
            if(data.1 != nil){
                if((data.1 as? Stylus) == stylus){
                    conditionJSON["reference"] = JSON("stylus")
                }
                else if((data.1 as? String) == "parent"){
                    conditionJSON["reference"] = JSON("parent")
                }
            }
            if(data.2 != nil){
                conditionJSON["referenceNames"] = JSON(data.2!)
            }
            if(data.3 != nil){
                if((data.3 as? Stylus) == stylus){
                    conditionJSON["relative"] = JSON("stylus")
                }
                else if((data.3 as? String) == "parent"){
                    conditionJSON["relative"] = JSON("parent")
                }
            }
            if(data.4 != nil){
                conditionJSON["relativeNames"] = JSON(data.4!)
            }
            
            let relational = data.5
            conditionJSON["name"] = JSON(name);
            conditionJSON["relational"] = JSON(relational)
            conditionArray.append(conditionJSON);
        }
        
        
        var statesArray = [JSON]();
        for (key,data) in states {
            var stateJSON:JSON = [:]
            stateJSON["id"] = JSON(key);
            stateJSON["name"] = JSON(data.0);
            stateJSON["x"] = JSON(data.1);
            stateJSON["y"] = JSON(data.2);
            statesArray.append(stateJSON);
        }
        var transitionsArray = [JSON]();
        
        for (key,data) in transitions {
            var transitionJSON:JSON = [:]
            //(name,eventEmitter, parentFlag, event, fromStateId,toStateId,condition)
            let name = data.0
            let emitter = data.1
            let parentFlag = data.2
            let event = data.3
            let fromStateId = data.4
            let toStateId = data.5
            let conditionName = data.6
            let displayName = data.7
            
            transitionJSON["transitionId"] = JSON(key);
            transitionJSON["name"] = JSON(name);
            if(conditionName != nil){
                transitionJSON["conditionName"] = JSON(conditionName!);
            }
            transitionJSON["fromStateId"] = JSON(fromStateId);
            transitionJSON["toStateId"] = JSON(toStateId);
            
            if(emitter != nil){
                
                if(emitter == stylus){
                    transitionJSON["emitter"] = JSON("stylus");
                }
            }
            
            transitionJSON["eventName"] = JSON(event!);
            transitionJSON["parentFlag"] = JSON(parentFlag)
            transitionJSON["displayName"] = JSON(displayName);
            transitionsArray.append(transitionJSON);
        }
        
        var methodArray = [JSON]();
        
        for (key,data) in methods {
            for method in data {
                var methodJSON:JSON = [:]
                //targetTransition:String?, methodId: String, targetMethod:String, arguments:[Any]?
                let methodId = method.0
                let targetMethod = method.1
                
                switch(targetMethod){
                case "spawn":
                    methodJSON["hasArguments"] = JSON(true)
                    
                    var behavior_list = [String:String]()
                    for (key,value) in BehaviorManager.behaviors{
                        if key != self.id {
                            behavior_list[key] = value.name;
                        }
                    }
                    behavior_list["self"] = "self";
                    methodJSON["methodArguments"] = JSON(behavior_list);
                    methodJSON["defaultArgument"] = JSON("self");
                    
                    if let methodArgs = method.3{
                        let targetBehavior = methodArgs[0]
                        let behaviorId: String
                        let num = methodArgs[1] as! Int
                        if let def =  targetBehavior as? BehaviorDefinition {
                            behaviorId = def.id;
                            methodJSON["currentArguments"] = JSON([behaviorId,num]);
                            
                        }
                        else if let def =  targetBehavior as? String {
                            
                            behaviorId = def;
                            methodJSON["currentArguments"] = JSON([behaviorId,num]);
                            
                        }
                    }
                    break
                case "setOrigin", "newStroke":
                    methodJSON["hasArguments"] = JSON(true)
                    
                    methodJSON["methodArguments"] = JSON(["stylus_position":"stylus_position","parent_position":"parent_position","parent_origin":"parent_origin" ])
                    methodJSON["defaultArgument"] = JSON("stylus_position");
                    
                    if let methodArgs = method.3{
                        let pointString:String;
                        let methodPoint = methodArgs[0]
                        if let def = methodPoint as? Point{
                            if(def == stylus.position){
                                pointString = "stylus_position"
                                methodJSON["currentArguments"]=JSON(["stylus_position"])
                                
                            }
                            else{
                                //TODO: handle arbitrary point values here
                                
                            }
                        }
                        else if let def = methodPoint as? String{
                            pointString = def;
                            methodJSON["currentArguments"] = JSON([pointString]);
                            
                        }
                        
                    }
                    break;
                default:
                    methodJSON["hasArguments"] = JSON(false)
                    
                    break
                }
                
                methodJSON["methodId"] = JSON(methodId);
                methodJSON["targetMethod"] = JSON(targetMethod);
                methodJSON["targetTransition"] = JSON(key);
                
                
                
                
                methodArray.append(methodJSON);
            }
        }
        
        var mappingsArray = [JSON]();
        
        for(key, data) in mappings{
            var mappingJSON:JSON = [:]
            
            let mappingId = key;
            let relativePropertyFieldName = data.5;
            let expressionId = data.1![0]
            let expression = expressions[expressionId];
            let expressionText = expression?.1;
            let expressionPropertyList = expression?.0;
            var expressionPropertyListJSON:JSON = [:]
            
            for pId in expressionPropertyList! {
                
                let signal = BehaviorManager.getSignal(id: pId);
                
                var propEmitter = [JSON]();
                let emitter = signal?.getCollectionName();
                let propertyList = signal?.fieldName;
                let displayNameList = signal?.displayName;
                
                if(emitter != nil){
                    propEmitter.append(JSON(emitter!));
                }
                else{
                    propEmitter.append(JSON("NULL"));
                }
                propEmitter.append(JSON(propertyList!));
                propEmitter.append(JSON(displayNameList!));
                expressionPropertyListJSON[pId] = JSON(propEmitter);
                
            }
            let relativePropertyName = data.2
            let stateId = data.3
            let type = data.4
            mappingJSON["mappingId"] = JSON(mappingId);
            mappingJSON["relativePropertyName"] = JSON(relativePropertyName);
            mappingJSON["stateId"] = JSON(stateId);
            mappingJSON["expressionId"] = JSON(expressionId);
            mappingJSON["expressionText"] = JSON(expressionText!);
            mappingJSON["expressionPropertyList"] = expressionPropertyListJSON
            mappingJSON["constraintType"] = JSON(type)
            mappingJSON["relativePropertyFieldName"] = JSON(relativePropertyFieldName);
            mappingsArray.append(mappingJSON);
            
        }
        
        json_obj["states"] = JSON(statesArray);
        json_obj["transitions"] = JSON(transitionsArray);
        json_obj["mappings"] = JSON(mappingsArray);
        json_obj["methods"] = JSON(methodArray);
        json_obj["conditions"] = JSON(conditionArray);
        
        return json_obj;
    }
    
    
    
    //TODO: remove eventually- this is bad
    func getStateByName(name:String)->String?{
        for(id,state) in self.states{
            if(state.0 == name){
                return id;
            }
        }
        return nil
    }
    
    
    
    func addCondition(name:String, reference:Any?, referenceNames:[String]?, relative:Any?, relativeNames:[String]?, relational:String){
        
        conditions.append((name,reference,referenceNames,relative,relativeNames,relational))
        
    }
    
    func addState(stateId:String, stateName:String, stateX:Float, stateY:Float){
        states[stateId] = (stateName,stateX,stateY);
    }
    
    func setStatePosition(stateId:String,x:Float,y:Float){
        let stateName = states[stateId]!.0
        states[stateId] = (stateName,x,y);
    }
    
    func removeState(stateId:String){
        removeTransitionsForState(stateId: stateId);
        removeMappingsForState(stateId: stateId);
        if(states[stateId] != nil){
            states.removeValue(forKey: stateId);
            
        }
    }
    
    func addMethod(targetTransition:String?, methodId: String, targetMethod:String, expressionId:String, arguments:[Any]?){
        var tt:String;
        if(targetTransition != nil){
            tt = targetTransition!
        }
        else{
            tt = "globalTransition"
        }
        if(methods[tt] == nil){
            methods [tt] = [];
        }
        //TODO: fix
        methods[tt]? = (methods[tt]?.filter({ $0.0 != methodId }))!
        methods[tt]!.append((methodId,targetMethod,expressionId,arguments))
    }
    
    func checkDependency(behaviorId:String)->Bool{
        for (_, methodlist) in methods{
            for method in methodlist{
                let targetMethod = method.1
                if(targetMethod == "spawn"){
                    let args = method.3;
                    let spawn_id = args?[0] as! String;
                    if(spawn_id == behaviorId){
                        return true;
                    }
                    
                }
            }
        }
        
        return false;
    }
    
    func removeMethod(methodId:String){
        for (key, method_list) in methods{
            for i in 0..<method_list.count{
                if method_list[i].0 == methodId{
                    methods[key]?.remove(at: i)
                    if method_list.count == 0{
                        methods.removeValue(forKey: methodId);
                        
                    }
                    
                    return;
                }
                
            }
        }
    }
    
    func removeMethodsForTransition(transitionId:String){
        if(methods[transitionId] != nil){
            
            methods.removeValue(forKey: transitionId);
            return;
        }
        
        
    }
    
    func addTransition(transitionId:String, name:String, eventEmitter:Emitter?,parentFlag:Bool, event:String?, fromStateId:String,toStateId:String, condition:String?, displayName:String){
        transitions[transitionId]=((name,eventEmitter, parentFlag, event, fromStateId,toStateId,condition, displayName));
    }
    
    func setTransitionToDefaultEvent(transitionId:String) throws{
        if(transitions[transitionId] != nil){
            transitions[transitionId]!.1 = nil;
            transitions[transitionId]!.3 = "STATE_COMPLETE";
            return;
        }
        
        throw BehaviorError.transitionDoesNotExist;
        
    }
    
    
    func removeTransition(id:String) throws{
        
        removeMethodsForTransition(transitionId: id);
        
        if(transitions[id] != nil){
            transitions.removeValue(forKey: id);
            return;
        }
        throw BehaviorError.transitionDoesNotExist;
        
    }
    
    func removeTransitionsForState(stateId:String){
        for (key,transition) in transitions{
            if(transition.5 == stateId || transition.4 == stateId){
                do {
                    try removeTransition(id: key);
                }
                catch{
                    print("no transition by that id for that state");
                }
                
            }
        }
    }
    
    
    func addMapping(id:String, referenceProperty:Any?, referenceNames:[String]?, relativePropertyName:String,stateId:String, type:String,relativePropertyFieldName:String){
        mappings[id] = ((referenceProperty,referenceNames,relativePropertyName,stateId,type,relativePropertyFieldName))
        
    }
    
    func removeMappingsForState(stateId:String){
        for(key,mapping) in mappings{
            if mapping.3 == stateId{
                do{
                    try removeMapping(id: key);
                    
                }
                catch{
                    print("no mapping by that state id")
                }
            }
        }
    }
    
    func removeMapping(id:String) throws{
        if(mappings[id] != nil){
            let mapping = mappings[id];
            if(mapping!.0 == nil){
                if(mapping!.1 != nil){
                    let mappingKey = mapping!.1![0];
                    if(expressions[mappingKey] != nil){
                        expressions.removeValue(forKey: mappingKey);
                    }
                }
            }
            mappings.removeValue(forKey: id);
            return;
        }
        throw BehaviorError.mappingDoesNotExist;
        
    }
    
    func removeMappingReference(id:String) throws{
        if(mappings[id] != nil){
            mappings[id]!.0 = nil;
            mappings[id]!.1 = nil;
            return;
        }
        throw BehaviorError.mappingDoesNotExist;
        
    }
    
    func addExpression(id:String, emitterOperandList:[String], expressionText:String){
        expressions[id]=(emitterOperandList,expressionText);
    }
    
    func generateSignal(id:String)->Signal?{
        guard let signal = BehaviorManager.getSignal(id:id) else{
            return nil
        }
        
        return signal;
    }
    
    func generateOperand(targetBrush:Brush,targetEmitter:Any?, propId:String?)->Observable<Float>{
        let id = targetBrush.id
        var emitter:Any
        
        var operand:Observable<Float>
        
        if(targetEmitter == nil){
            emitter = targetBrush;
        }
        else{
            emitter = targetEmitter!
        }
        
        
        if(propId != nil){
            let signal = generateSignal(id:propId!);
            if(signal != nil){
                operand = signal!;
            }
            else if(storedExpressions[id]![propId!] != nil){
                operand = storedExpressions[id]![propId!]!;
                
            }
            else if(storedConditions[id]![propId!] != nil){
                operand = storedConditions[id]![propId!]!;
                
            }
            else{
                operand = (emitter as! Object)[propId!]! as! Observable<Float>
            }
            
        }
        else{
            operand = emitter as! Observable<Float>
        }
        
        return operand;
        
    }
    
    func generateCondition(targetBrush:Brush, conditionId:String, operand1:Observable<Float>, operand2:Observable<Float>, relational:String){
        
        let id = targetBrush.id;
        // let operands = generateOperands(targetBrush: targetBrush, data:(data.1,data.2,data.3,data.4,data.5))
        //let operand1 = operands.0;
        //let operand2 = operands.1;
        
        let condition = Condition(a: operand1, b: operand2, relational: relational)
        storedConditions[id]![conditionId] = condition;
        
    }
    
    func generateExpression(targetBrush:Brush, name:String, signalIds:[String], expressionText:String){
        let id = targetBrush.id
        var operands = [String:Observable<Float>]();
        
        for observableId in signalIds {
            #if DEBUG
                print("registering observable target with id:",observableId);
            #endif
            let operand = self.generateOperand(targetBrush: targetBrush, targetEmitter: nil, propId:observableId);
            operands[observableId] = operand;
            RequestHandler.registerObservableTarget(observableId: observableId, behaviorId: self.id)
        }
        let expression = Expression(id:name,subscriberId:id,brushIndex:targetBrush.index,operandList: operands, text: expressionText);
        
        self.storedExpressions[id]![name] = expression;
    }
    
    func generateMapping(targetBrush:Brush, id:String, referenceEmitter:Any?, referenceProperties:[String]?, relativePropertyName:String, stateId:String){
        var referenceProp:String? = nil;
        if(referenceProperties != nil){
            referenceProp = referenceProperties?[0];
        }
        
        let referenceOperand = generateOperand(targetBrush: targetBrush, targetEmitter: referenceEmitter, propId: referenceProp)
        let relativeOperand = generateOperand(targetBrush: targetBrush, targetEmitter: targetBrush, propId: relativePropertyName)
        
        targetBrush.addConstraint(id: id, reference:referenceOperand, relative: relativeOperand, stateId: stateId)
        
    }
    
    func addBrush(targetBrush:Brush){
        self.brushInstances.append(targetBrush);
        _ = targetBrush.dieEvent.addHandler(target: self, handler: BehaviorDefinition.brushDeath, key: targetBrush.id)
    }
    
    func brushDeath(data:String,key:String){
        for i in 0..<brushInstances.count{
            let b = brushInstances[i];
            if (b.id == data) {
                brushInstances.remove(at: i)
                self.clearExpressionsForId(id: b.id)
                self.clearConditionsForId(id: b.id)
                return
            }
        }
    }
    
    func clearExpressionsForId(id:String){
        for (_,v) in self.storedExpressions[id]!{
            v.destroy();
        }
        self.storedExpressions[id] = nil;
        
    }
    
    
    
    func clearConditionsForId(id:String){
        for (_,v) in self.storedConditions[id]!{
            v.destroy();
        }
        self.storedConditions[id] = nil;
        
    }
    
    
    func clearBehavior(){
        RequestHandler.clearAllObservableListenersForBehavior(behaviorId: self.id)
        for (_,value) in self.storedExpressions{
            for (_,v) in value{
                v.destroy();
            }
        }
        self.storedExpressions.removeAll();
        
        for (_,value) in self.storedConditions{
            for (_,v) in value{
                v.destroy();
            }
        }
        
        self.storedConditions.removeAll();
        //TODO: AT WHAT POINT DO SIGNALS GET DESTROYED???
        
        for i in 0..<self.brushInstances.count{
            let targetBrush = self.brushInstances[i];
            targetBrush.clearBehavior();
            targetBrush.destroy();
            
        }
        self.brushInstances.removeAll();
        
    }
    
    func createBehavior(canvas:Canvas){
        clearBehavior();
        
        if(self.active_status){
            for i in 0..<self.auto_spawn_num{
                let targetBrush = Brush(name: "brush_" + String(i) + "_" + self.id, behaviorDef: self, parent: nil, canvas: canvas)
                self.initBrushBehavior(targetBrush:targetBrush);
            }
        }
        
        uiInput.invalidateAllProperties();
        
        
    }
    
    func initBrushBehavior(targetBrush:Brush){
        targetBrush.createGlobals();
        let id = targetBrush.id
        storedConditions[id] = [String:Condition]();
        storedExpressions[id] = [String:Expression]();
        
        
        
        for i in 0..<conditions.count{
            let conditionId = conditions[i].0;
            var propId1:String? = nil;
            var propId2:String? = nil;
            
            if conditions[i].2 != nil{
                propId1 = conditions[i].2![0]
            }
            if conditions[i].4 != nil{
                propId2 = conditions[i].4![0]
            }
            let operand1 = generateOperand(targetBrush: targetBrush, targetEmitter: conditions[i].1, propId: propId1);
            let operand2 = generateOperand(targetBrush: targetBrush, targetEmitter: conditions[i].3, propId: propId2);
            
            let relational = conditions[i].5;
            
            self.generateCondition(targetBrush: targetBrush, conditionId: conditionId, operand1: operand1, operand2: operand2, relational: relational);
        }
        
        for (key,expression_data) in expressions{
            self.generateExpression(targetBrush: targetBrush, name: key, signalIds: expression_data.0, expressionText: expression_data.1);
        }
        
        for (id,state) in states{
            targetBrush.createState(id: id, name:state.0);
            
        }
        
        for (key,transition) in transitions{
            if((transition.3?.isEmpty) == false){
                var reference:Any
                if(transition.1 == nil){
                    if(transition.2){
                        reference = targetBrush.parent!
                    }
                    else{
                        reference = targetBrush
                    }
                }
                else{
                    reference = transition.1!;
                }
                let condition:Condition?
                if((transition.6) != nil){
                    condition = storedConditions[id]![transition.6!]
                }
                else{
                    condition = nil
                }
                
                
                
                behaviorMapper.createStateTransition(id: key,name: transition.0,reference:reference as! Emitter, relative: targetBrush, eventName: transition.3!, fromStateId:transition.4,toStateId:transition.5, condition: condition)
            }
                
                
            else{
                print("could not generate transition \(key) because event is empty")
                
            }
            
        }
        
        for (key,method_list) in methods{
            for method in method_list {
                //behaviorMapper.addMethod(relative: targetBrush,transitionName:key,methodId:method.0,methodName:method.1,expressionId:String,arguments:method.3);
                //func addMethod(relative:Brush,transitionName:String,methodId:String,methodName:String, arguments:[Any]?){
                
                
                targetBrush.addMethod(transitionId:key,methodId:method.0,methodName:method.1,expressionId:method.2, arguments:method.3)
                
            }
        }
        
        //referenceProperty!,referenceName!,relativePropertyName,stateId
        for (id, mapping_data) in mappings{
            if(mapping_data.0 != nil || mapping_data.1 != nil ){
                
                self.generateMapping(targetBrush: targetBrush, id: id, referenceEmitter: mapping_data.0, referenceProperties: mapping_data.1, relativePropertyName: mapping_data.2, stateId: mapping_data.3);
            }
            else{
                print("could not generate mapping \(id) because reference is nil")
            }
            
        }
        targetBrush.setupTransition();
        
    }
    
}
