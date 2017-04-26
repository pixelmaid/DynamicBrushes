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
    var expressions = [String:([String:(Any?,[String]?,[String]?)],String)]();
    var conditions = [(String,Any?,[String]?,Any?,[String]?,String)]()
    var generators = [String:(String,[Any?])]()
    var storedGenerators = [String:Generator]()
    var methods = [String:[(String,String,[Any]?)]]()
    var transitions = [String:(String,Emitter?,Bool,String?,String,String,String?,String)]()
    var behaviorMapper = BehaviorMapper()
    var mappings = [String:(Any?,[String]?,String,String,String,String)]()
    var storedExpressions = [String:TextExpression]()
    var storedConditions = [String:Condition]()
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
        let generatorJSON = json["generators"].arrayValue;
        
        for i in 0..<generatorJSON.count{
            self.parseGeneratorJSON(data:generatorJSON[i])
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
            self.parseMethodJSON(data:methodJSON[i]);
        }
        
    }
    
    func parseMethodJSON(data:JSON)->JSON{
        let targetTransition:String?
        if(data["targetTransition"] != nil){
            targetTransition = data["targetTransition"].stringValue;
        }
        else{
            targetTransition = nil;
        }
        var arguments:[Any]? = nil;
        let dataArguments = data["args"];
        let targetMethod = data["targetMethod"].stringValue
        
        var methodJSON:JSON = [:]
        switch(targetMethod){
        case "spawn":
            let name:String;
            let behavior:String;
            let num:Int;
            
            if(dataArguments != nil){
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
        
        // print("arguments= \(arguments)")
        self.addMethod(targetTransition: targetTransition, methodId: data["methodId"].stringValue, targetMethod: targetMethod, arguments: arguments)
        
        return methodJSON;
    }
    
    func parseGeneratorJSON(data:JSON){
        let type = data["generator_type"].stringValue;
        
        switch(type){
        case "random":
            self.addRandomGenerator(name: data["generatorId"].stringValue, min: data["min"].floatValue, max: data["max"].floatValue)
            break;
        case "alternate":
            let jsonValues =  data["values"].arrayValue;
            var values = [Float]();
            for i in jsonValues{
                values.append(i.floatValue);
            }
            self.addAlternate(name: data["generatorId"].stringValue, values: values)
            break;
            
            
        case "range":
            
            self.addRange(name: data["generatorId"].stringValue, min: data["min"].intValue, max: data["max"].intValue, start: data["start"].floatValue, stop: data["stop"].floatValue)
            break;
            
        case "sine":
            self.addSine(name: data["generatorId"].stringValue, freq: data["freq"].floatValue, amp: data["amp"].floatValue, phase: data["phase"].floatValue);
            
            break;
            // case "random_walk":
            
            //return "success"
            
            
        //  return "success";
        default:
            break;
        }
    }
    
    func parseExpressionJSON(data:JSON){
        let expressionId = data["expressionId"].stringValue;
        
        let expressionPropertyList = data["expressionPropertyList"];
        let expressionText = data["expressionText"].stringValue;
        var emitterOperandList = [String:(Any?,[String]?,[String]?)]();
        
        if(expressionPropertyList != nil){
            // print("expression list present\(expressionPropertyList.dictionaryValue)")
            let dataExpressionDictionary = expressionPropertyList.dictionaryValue;
            for (key,value) in dataExpressionDictionary{
                let dataEmitterValue = (value.arrayValue)[0].stringValue;
                let emitter:Any?
                switch(dataEmitterValue){
                case "stylus":
                    emitter = stylus;
                    break;
                default:
                    emitter = nil;
                    break;
                }
                var propertyList:[String]?;
                
                if ((value.arrayValue)[1] != nil) {
                    let dataPropertyList = (value.arrayValue)[1].arrayValue;
                    propertyList = [String]();
                    
                    for i in 0..<dataPropertyList.count {
                        let property = dataPropertyList[i].stringValue;
                        propertyList!.append(property)
                    }
                }
                
                var displayNameList:[String]?;
                
                if ((value.arrayValue)[2] != nil) {
                    let dataPropertyList = (value.arrayValue)[2].arrayValue;
                    displayNameList = [String]();
                    
                    for i in 0..<dataPropertyList.count {
                        let property = dataPropertyList[i].stringValue;
                        displayNameList!.append(property)
                    }
                }
                
                
                emitterOperandList[key]=(emitter,propertyList,displayNameList);
            }
        }
        
        //  print("emitter operand list \(emitterOperandList,expressionText)")
        self.addExpression(id: expressionId, emitterOperandList: emitterOperandList, expressionText: expressionText)
    }
    
    
    func parseMappingJSON(data:JSON){
        self.parseExpressionJSON(data:data)
        
        let expressionId = data["expressionId"].stringValue;
        
        self.addMapping(id: data["mappingId"].stringValue, referenceProperty:nil, referenceNames: [expressionId], relativePropertyName: data["relativePropertyName"].stringValue, stateId: data["stateId"].stringValue,type: data["constraintType"].stringValue,relativePropertyItemName: data["relativePropertyItemName"].stringValue)
    }
    
    func parseStateJSON(data:JSON){
        print("parsing state JSON \(data)");
        let stateId = data["id"].stringValue
        let stateName = data["name"].stringValue
        let stateX = data["x"].floatValue
        let stateY = data["y"].floatValue
        self.addState(stateId: stateId, stateName: stateName, stateX: stateX, stateY: stateY)
    }
    
    func parseTransitionJSON(data:JSON){
        let event = data["eventName"].stringValue;
        //print("adding transition \(data)")
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
        
        let conditionName:String?
        let condition_list = data["conditions"].arrayValue;
        switch(event){
        case "TIME_INTERVAL":
            conditionName = "condition_" + NSUUID().uuidString
            let interval_name = "interval_" + NSUUID().uuidString
            let interval_value = condition_list[0].floatValue;
            self.addInterval(name: interval_name, inc: interval_value, times: nil)
            
            self.addCondition(name: conditionName!, reference: nil, referenceNames: ["time"], relative: nil, relativeNames: [interval_name], relational: "within")
            break;
        default:
            conditionName = nil;
            break;
            
        }
        
        self.addTransition(transitionId: data["transitionId"].stringValue, name: data["name"].stringValue, eventEmitter: emitter, parentFlag: data["parentFlag"].boolValue, event: data["eventName"].stringValue, fromStateId: data["fromStateId"].stringValue, toStateId: data["toStateId"].stringValue, condition: conditionName,displayName:data["displayName"].stringValue)
        
    }
    
    
    func toJSON()->JSON{
        var json_obj:JSON = [:]
        json_obj["name"] = JSON(self.name);
        json_obj["id"] = JSON(self.id);
        json_obj["active_status"] = JSON(self.active_status);
        json_obj["auto_spawn_num"] = JSON(self.auto_spawn_num);
        
        var generatorArray = [JSON]();
        for (key,data) in generators {
            var generatorJSON:JSON = [:]
            let type = data.0;
            generatorJSON["type"] = JSON(type);
            generatorJSON["generatorId"] = JSON(key)
            switch(type){
            case "random":
                generatorJSON["min"] = JSON(data.1[0])
                generatorJSON["max"] = JSON(data.1[1])
                break;
            case "alternate":
                generatorJSON["values"] = JSON(data.1[0])
                break;
            case "range":
                generatorJSON["min"] = JSON(data.1[0])
                generatorJSON["max"] = JSON(data.1[1])
                generatorJSON["start"] = JSON(data.1[2])
                generatorJSON["stop"] = JSON(data.1[3])
                break;
                
            case "sine":
                generatorJSON["freq"] = JSON(data.1[0])
                generatorJSON["amp"] = JSON(data.1[1])
                generatorJSON["phase"] = JSON(data.1[2])
                break;
                // case "random_walk":
                
                //return "success"
                
                
            //  return "success";
            default:
                break;
                
            }
            generatorArray.append(generatorJSON);
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
            _ = data.6
            let displayName = data.7
            
            transitionJSON["transitionId"] = JSON(key);
            transitionJSON["name"] = JSON(name);
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
                    
                    if let methodArgs = method.2{
                        let targetBehavior = methodArgs[0]
                        let behaviorId: String
                        // print("method args 1=\(methodArgs)");
                        let num = methodArgs[1] as! Int
                        if let def =  targetBehavior as? BehaviorDefinition {
                            behaviorId = def.id;
                            methodJSON["currentArgument"] = JSON(behaviorId);
                            
                        }
                        else if let def =  targetBehavior as? String {
                            print("target behavior",targetBehavior)

                            behaviorId = def;
                            methodJSON["currentArgument"] = JSON(behaviorId);
                            
                        }
                    }
                    break
                case "setOrigin", "newStroke":
                    methodJSON["hasArguments"] = JSON(true)
                    
                    methodJSON["methodArguments"] = JSON(["stylus_position":"stylus_position","parent_position":"parent_position","parent_origin":"parent_origin" ])
                    methodJSON["defaultArgument"] = JSON("stylus_position");
                    
                    if let methodArgs = method.2{
                        let pointString:String;
                        let methodPoint = methodArgs[0]
                        if let def = methodPoint as? Point{
                            if(def == stylus.position){
                                pointString = "stylus_position"
                                methodJSON["currentArgument"]="stylus_position"
                                
                            }
                            else{
                                //TODO: handle arbitrary point values here
                                
                            }
                        }
                        else if let def = methodPoint as? String{
                            pointString = def;
                            methodJSON["currentArgument"] = JSON(pointString);
                            
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
            let relativePropertyItemName = data.5;
            let expressionId = data.1![0]
            let expression = expressions[expressionId];
            let expressionText = expression?.1;
            let expressionPropertyList = expression?.0;
            var expressionPropertyListJSON:JSON = [:]
            for(pId,pData) in expressionPropertyList!{
                let emitter = pData.0;
                let propertyList = pData.1;
                let displayNameList = pData.2;
                
                var propEmitter = [JSON]();
                if (emitter as? Stylus) != nil{
                    propEmitter.append(JSON("stylus"));
                }
                else{
                    propEmitter.append(JSON("null"));
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
            mappingJSON["relativePropertyItemName"] = JSON(relativePropertyItemName);
            mappingsArray.append(mappingJSON);
            
        }
        
        json_obj["states"] = JSON(statesArray);
        json_obj["transitions"] = JSON(transitionsArray);
        json_obj["mappings"] = JSON(mappingsArray);
        json_obj["methods"] = JSON(methodArray);
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
    
    func addInterval(name:String,inc:Float,times:Int?){
        generators[name] = ("interval",[inc,times]);
    }
    
    func addIncrement(name:String,inc:Observable<Float>,start:Observable<Float>){
        generators[name] = ("increment",[inc,start]);
    }
    
    func addRange(name:String,min:Int,max:Int,start:Float,stop:Float){
        generators[name] = ("range",[min,max,start,stop]);
    }
    
    func addSine(name:String,freq:Float,amp:Float,phase:Float){
        generators[name] = ("sine",[freq,amp,phase]);
    }
    
    
    func addRandomGenerator(name:String,min:Float,max:Float){
        generators[name] = ("random",[min,max]);
    }
    
    func addLogiGrowthGenerator(name:String,a:Float,b:Float,k:Float){
        
        generators[name] = ("logigrowth",[a,b,k]);
    }
    
    
    func addAlternate(name:String,values:[Float]){
        generators[name] = ("alternate",[values]);
    }
    
    func addState(stateId:String, stateName:String, stateX:Float, stateY:Float){
        //print("adding state\(stateId,stateName,stateX,stateY)");
        states[stateId] = (stateName,stateX,stateY);
    }
    
    func removeState(stateId:String){
        removeTransitionsForState(stateId: stateId);
        removeMappingsForState(stateId: stateId);
        if(states[stateId] != nil){
            states.removeValue(forKey: stateId);
            
        }
    }
    
    func addMethod(targetTransition:String?, methodId: String, targetMethod:String, arguments:[Any]?){
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
        for i in 0..<methods[tt]!.count {
            if methods[tt]?[i].0 == methodId{
                    methods[tt]?.remove(at: i)
            }
        }
        methods[tt]!.append((methodId,targetMethod,arguments))
    }
    
    func checkDependency(behaviorId:String)->Bool{
        for (_, methodlist) in methods{
            for method in methodlist{
                let targetMethod = method.1
                if(targetMethod == "spawn"){
                    let args = method.2;
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
        print("method with id \(methodId) not found");
    }
    
    func removeMethodsForTransition(transitionId:String){
        if(methods[transitionId] != nil){
            
            methods.removeValue(forKey: transitionId);
            return;
        }
        
        print("no methods for transition \(transitionId)")
        
    }
    
    func addTransition(transitionId:String, name:String, eventEmitter:Emitter?,parentFlag:Bool, event:String?, fromStateId:String,toStateId:String, condition:String?, displayName:String){
        transitions[transitionId]=((name,eventEmitter, parentFlag, event, fromStateId,toStateId,condition, displayName));
        // print("current transitions \(transitions.count)");
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
        print("removing transition \(transitions,id)")
        
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
    
    
    func addMapping(id:String, referenceProperty:Any?, referenceNames:[String]?, relativePropertyName:String,stateId:String, type:String,relativePropertyItemName:String){
        mappings[id] = ((referenceProperty,referenceNames,relativePropertyName,stateId,type,relativePropertyItemName))
        
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
        print("removing mappings \(mappings,id)")
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
        print("removing mapping reference \(mappings,id)")
        if(mappings[id] != nil){
            mappings[id]!.0 = nil;
            mappings[id]!.1 = nil;
            return;
        }
        throw BehaviorError.mappingDoesNotExist;
        
    }
    
    func addExpression(id:String, emitterOperandList:[String:(Any?,[String]?,[String]?)], expressionText:String){
        expressions[id]=(emitterOperandList,expressionText);
        print("adding expression\(expressions)");
    }
    
    
    
    //TODO: add in cases for other generators
    func generateGenerator(name:String, data:(String,[Any?])){
        switch(data.0){
        case "interval":
            let interval = Interval(inc:data.1[0] as! Float,times:data.1[1] as? Int)
            storedGenerators[name] = interval;
            break;
        case "range":
            let range = Range(min:data.1[0] as! Int, max:data.1[1] as! Int, start: data.1[2] as! Float, stop:data.1[3] as! Float)
            storedGenerators[name] = range;
        case "sine":
            let sine = Sine(freq: data.1[0] as! Float, amp: data.1[1] as! Float, phase: data.1[2] as! Float);
            storedGenerators[name] = sine;
        case "random":
            let random = RandomGenerator(start:data.1[0] as! Float, end:data.1[1] as! Float)
            storedGenerators[name] = random;
        case "logigrowth":
            let logigrowth = LogiGrowthGenerator(a: data.1[0] as! Float, b:  data.1[1] as! Float, k:  data.1[2] as! Float)
            storedGenerators[name] = logigrowth;
            
            break;
        case "alternate":
            let alternate = Alternate(values:data.1[0] as! [Float])
            storedGenerators[name] = alternate;
        case "increment":
            let increment = Increment(inc:data.1[0] as! Observable<Float>, start:data.1[1] as! Observable<Float>)
            storedGenerators[name] = increment;
            
        default:
            break;
        }
    }
    
    func generateSingleOperand(targetBrush:Brush, emitter:Any?,propList:[String]?)->Observable<Float>{
        print("stored generators: \(storedGenerators)");
        var targetEmitter:Any;
        var operand:Observable<Float>
        if(emitter == nil){
            targetEmitter = targetBrush;
        }
        else{
            targetEmitter = emitter!;
        }
        if(propList != nil){
            if(storedGenerators[propList![0]]) != nil{
                operand = storedGenerators[propList![0]]!;
            }
            else if(storedExpressions[propList![0]] != nil){
                operand = storedExpressions[propList![0]]!;
                
            }
            else if(storedConditions[propList![0]] != nil){
                operand = storedConditions[propList![0]]!;
                
            }
            else{
                operand = (emitter as! Object)[propList![0]]! as! Observable<Float>
            }
            
            if(propList!.count > 1){
                
                for var i in 1..<propList!.count{
                    operand = operand[propList![i]] as! Observable<Float>
                }
            }
        }
        else{
            operand = emitter as! Observable<Float>
        }
        return operand;
    }
    
    func generateOperands(targetBrush:Brush,data:(Any?,[String]?,Any?,[String]?,String))->(Observable<Float>,Observable<Float>){
        var emitter1:Any
        var emitter2:Any
        
        var operand1:Observable<Float>
        var operand2: Observable<Float>
        
        if(data.0 == nil){
            emitter1 = targetBrush;
        }
        else{
            emitter1 = data.0!
        }
        
        if(data.2 == nil){
            emitter2 = targetBrush
        }
        else{
            emitter2 = data.2!
        }
        
        if(data.1 != nil){
            var refPropList = data.1!
            if(storedGenerators[refPropList[0]]) != nil{
                operand1 = storedGenerators[refPropList[0]]!;
            }
            else if(storedExpressions[refPropList[0]] != nil){
                operand1 = storedExpressions[refPropList[0]]!;
                
            }
            else if(storedConditions[refPropList[0]] != nil){
                operand1 = storedConditions[refPropList[0]]!;
                
            }
            else{
                operand1 = (emitter1 as! Object)[refPropList[0]]! as! Observable<Float>
            }
            
            if(refPropList.count > 1){
                
                for i in 1..<refPropList.count{
                    operand1 = operand1[refPropList[i]] as! Observable<Float>
                }
            }
        }
        else{
            operand1 = emitter1 as! Observable<Float>
        }
        
        if(data.3  != nil){
            var refPropList = data.3!
            if(storedGenerators[refPropList[0]]) != nil{
                operand2 = storedGenerators[refPropList[0]]!;
            }
            else if(storedExpressions[refPropList[0]] != nil){
                operand2 = storedExpressions[refPropList[0]]!;
                
            }
            else if(storedConditions[refPropList[0]] != nil){
                operand2 = storedConditions[refPropList[0]]!;
                
            }
            else{
                operand2 = (emitter2 as! Object)[refPropList[0]] as! Observable<Float>
            }
            
            if(refPropList.count > 1){
                
                for i in 1..<refPropList.count{
                    operand2 = operand2[refPropList[i]] as! Observable<Float>
                    
                }
            }
        }
        else{
            operand2 = emitter2 as! Observable<Float>
        }
        
        return(operand1,operand2)
        
        
    }
    
    func generateCondition(targetBrush:Brush, data:(String, Any?,[String]?,Any?,[String]?,String)){
        let name = data.0;
        //TODO: THIS IS GARBAGE CODE. Find a better solution
        let operands = generateOperands(targetBrush: targetBrush, data:(data.1,data.2,data.3,data.4,data.5))
        let operand1 = operands.0;
        let operand2 = operands.1;
        
        let condition = Condition(a: operand1, b: operand2, relational: data.5)
        storedConditions[name] = condition;
        
    }
    
    func generateExpression(targetBrush:Brush, name:String, data:([String:(Any?,[String]?,[String]?)],String)){
        var operands = [String:Observable<Float>]();
        print("expression operand data\(data.0)");
        for (key,value) in data.0 {
            let emitter = value.0;
            let propList = value.1;
            let operand = self.generateSingleOperand(targetBrush: targetBrush, emitter: emitter, propList: propList)
            operands[key] = operand;
        }
        print("expression operands=\(operands)");
        let expression = TextExpression(id:name,operandList: operands, text: data.1);
        self.storedExpressions[name] = expression;
    }
    
    func generateMapping(targetBrush:Brush, id:String, data:(Any?,[String]?,String,String,String,String)){
        
        var mappingRelativeList = [String]();
        mappingRelativeList.append(data.2);
        let operands = generateOperands(targetBrush: targetBrush, data:(data.0,data.1,targetBrush,mappingRelativeList,""))
        let referenceOperand = operands.0;
        let relativeOperand = operands.1;
        
        behaviorMapper.createMapping(id: id, reference: referenceOperand, relative: targetBrush, relativeProperty: relativeOperand, stateId: data.3,type:data.4)
    }
    
    func addBrush(targetBrush:Brush){
        self.brushInstances.append(targetBrush);
    }
    
    func clearBehavior(){
        self.storedExpressions.removeAll();
        self.storedConditions.removeAll();
        self.storedGenerators.removeAll();
        for i in 0..<self.brushInstances.count{
            let targetBrush = self.brushInstances[i];
            targetBrush.clearBehavior();
            targetBrush.destroyChildren();
            targetBrush.destroy();

        }
        self.brushInstances.removeAll();
        
    }
    
    func createBehavior(canvas:Canvas){
        clearBehavior();
        
        if(self.active_status){
            for i in 0..<self.auto_spawn_num{
                print("create new brush",i);
                let targetBrush = Brush(name: "brush_" + String(i) + "_" + self.id, behaviorDef: self, parent: nil, canvas: canvas)
                self.initBrushBehavior(targetBrush:targetBrush);
            }
        }
        
        
    }
    
    func initBrushBehavior(targetBrush:Brush){
        targetBrush.createGlobals();
        
        for (key, generator_data) in generators{
            self.generateGenerator(name: key,data:generator_data)
        }
        
        for i in 0..<conditions.count{
            self.generateCondition(targetBrush: targetBrush,data:conditions[i])
        }
        
        for (key,expression_data) in expressions{
            self.generateExpression(targetBrush: targetBrush,name:key,data:expression_data)
            
            
            
        }
        print("expressions after created \(self.storedExpressions)");
        
        for (id,state) in states{
            behaviorMapper.createState(target: targetBrush,stateId:id, stateName:state.0)
            
        }
        print("transitions:\(transitions)")
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
                    condition = storedConditions[transition.6!]
                }
                else{
                    condition = nil
                }
                
                
                print("generating transition \(key) because event is: \(transition.3)");
                
                behaviorMapper.createStateTransition(id: key,name: transition.0,reference:reference as! Emitter, relative: targetBrush, eventName: transition.3!, fromStateId:transition.4,toStateId:transition.5, condition: condition)
            }
                
                
            else{
                print("could not generate transition \(key) because event is empty")
                
            }
            
        }
        
        for (key,method_list) in methods{
            for method in method_list {
                print("generating method:\(targetBrush,transitionName:key,methodId:method.0,methodName:method.1,arguments:method.2)");
                behaviorMapper.addMethod(relative: targetBrush,transitionName:key,methodId:method.0,methodName:method.1,arguments:method.2);
            }
        }
        
        //referenceProperty!,referenceName!,relativePropertyName,stateId
        for (id, mapping_data) in mappings{
            if(mapping_data.0 != nil || mapping_data.1 != nil ){
                print("generating mapping \(id) because reference is not nil")
                
                self.generateMapping(targetBrush: targetBrush,id:id, data:mapping_data);
            }
            else{
                print("could not generate mapping \(id) because reference is nil")
            }
            targetBrush.setupTransition();
            
        }
    }
    
}
