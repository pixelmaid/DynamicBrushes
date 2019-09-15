//
//  BehaviorDefinition.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 7/27/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON

class BehaviorDefinition {

    var brushInstances = [Brush]();
    var states = [String:(String,Float,Float)]()
    var expressions = [String:(expressionPropertyList:[String],expressionText:String)]();
    internal var conditions = [String:(conditionId:String,referenceAId:String,referenceBId:String,relational:String)]();
    var methods = [String:(transitionId:String,methodId:String,fieldName:String,displayName:String,arguments:[ArgumentData])]()
    var transitions = [String:(transitionId:String,transitionDisplayName: String, conditionId:String, fromStateId:String, toStateId:String)]()
    var mappings = [String:(Emitter?,[String]?,String,String,String,String)]()
    
    var storedExpressions = [String:[String:Expression]]()
    var storedConditions =  [String:[String:Condition]]()
    
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
        let expressionJSON = json["expressions"].arrayValue;

        for i in 0..<expressionJSON.count{
            self.parseExpressionJSON(data: expressionJSON[i]);
        }
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
    
    
    //TODO: fix condition to avoid static references ie stylus
    func parseConditionJSON(data:JSON){
        let conditionId = data["conditionId"].stringValue;
        let referenceAId = data["referenceAId"].stringValue;
        let referenceBId = data["referenceBId"].stringValue;
        let relational = data["relational"].stringValue;
        
        self.addCondition(conditionId: conditionId, referenceAId: referenceAId, referenceBId: referenceBId, relational: relational)
    }
    
    func parseExpressionJSON(data:JSON){
        
        let expressionId = data["expressionId"].stringValue;
        
        let expressionPropertyList = data["expressionPropertyList"].arrayValue;
        let expressionText = data["expressionText"].stringValue;
        var operandList = [String]();
        for i in 0..<expressionPropertyList.count{
            operandList.append(expressionPropertyList[i]["id"].stringValue);
        }
        #if DEBUG
           // print("expression prop list",expressionPropertyList,operandList);
        #endif
        
        
        self.addExpression(id: expressionId, expressionPropertyList: operandList, expressionText: expressionText)
    }
    
    
    func parseMappingJSON(data:JSON){
        
        let expressionId = data["expressionId"].stringValue;
        
        self.addMapping(id: data["mappingId"].stringValue, referenceProperty:nil, referenceNames: [expressionId], relativePropertyName: data["relativePropertyName"].stringValue, stateId: data["stateId"].stringValue,type: data["constraintType"].stringValue,relativePropertyFieldName: data["relativePropertyFieldName"].stringValue)
    }
    
    func parseMethodJSON(data:JSON)->JSON{

        let transitionId = data["transitionId"].stringValue;
        let fieldName = data["fieldName"].stringValue;
        let displayName = data["displayName"].stringValue;
        let methodId:String = data["methodId"].stringValue;
        var arguments:[ArgumentData] = [];
        let argumentList = data["argumentList"].arrayValue
        for i in 0..<argumentList.count{
            let argumentJSON = argumentList[i];
            let isExpression = argumentJSON["isExpression"].boolValue;
            let isDropdown = argumentJSON["isDropdown"].boolValue;
            let defaultVal = argumentJSON["defaultVal"].stringValue;
            let argDisplayName = argumentJSON["displayName"].stringValue;
            let argFieldName = argumentJSON["fieldName"].stringValue;

            let expressionId:String?
            let argumentData:ArgumentData;
            
            if(isExpression){
                if(argumentJSON["expressionId"]==JSON.null){
                    expressionId = NSUUID().uuidString;
                    self.addExpression(id: expressionId!, expressionPropertyList: [], expressionText: defaultVal)
                }
                else{
                    expressionId = argumentJSON["expressionId"].stringValue;
                }
                argumentData = ExpressionArgument(expressionId: expressionId!, fieldName:argFieldName, displayName: argDisplayName, defaultVal: defaultVal);
            }
            else{
                let dropDownArguments:[[String:String]];
                if(fieldName == "spawn"){
                    dropDownArguments = BehaviorManager.getBehaviorsAsArgumentList();
                }
                //TODO: setup dropdown args for other types beside spawn
                else{
                    dropDownArguments = [[String:String]]()
                }
                argumentData = DropdownArgument(fieldName:argFieldName, displayName: argDisplayName, defaultVal: defaultVal,options:dropDownArguments)
            }
            arguments.append(argumentData);
        }
        
        self.addMethod(transitionId: transitionId, methodId: methodId, fieldName: fieldName, displayName: displayName, arguments: arguments);
        return self.methodToJSON(methodId: methodId)!;
    }
    
    
    func parseStateJSON(data:JSON){
        let stateId = data["stateId"].stringValue
        let stateName = data["stateName"].stringValue
        let stateX = data["x"].floatValue
        let stateY = data["y"].floatValue
        self.addState(stateId: stateId, stateName: stateName, stateX: stateX, stateY: stateY)
    }
    
    func parseTransitionJSON(data:JSON){
        let transitionId = data["transitionId"].stringValue;
        let transitionDisplayName = data["name"].stringValue;
        let fromStateId = data["fromStateId"].stringValue;
        let toStateId = data["toStateId"].stringValue;
        let conditionId = data["conditionId"].stringValue;
        self.addTransition(transitionId: transitionId, transitionDisplayName: transitionDisplayName, conditionId: conditionId, fromStateId: fromStateId, toStateId: toStateId);
        
    }
    
    
    func toJSON()->JSON{
        var json_obj:JSON = [:]
        json_obj["name"] = JSON(self.name);
        json_obj["id"] = JSON(self.id);
        json_obj["active_status"] = JSON(self.active_status);
        json_obj["auto_spawn_num"] = JSON(self.auto_spawn_num);
        
        var expressionArray = [JSON]();
        for (key,value) in expressions {
            var expressionJSON:JSON = [:]
            expressionJSON["expressionId"] = JSON(key);
            expressionJSON["expressionText"] = JSON(value.expressionText);
            var expressionPropertyList = [JSON]();
            for i in 0..<value.expressionPropertyList.count {
                
                let signal = BehaviorManager.getSignal(id: value.expressionPropertyList[i])!;
                var signalJSON = signal.getMetaJSON();
                signalJSON["id"] = JSON(signal.id);
                expressionPropertyList.append(signalJSON);
            }
            
            expressionJSON["expressionPropertyList"] = JSON(expressionPropertyList);
            expressionArray.append(expressionJSON);
        }
        
        var conditionArray = [JSON]();
        print("conditions",conditions)
        for (_,value) in conditions {
            var conditionJSON:JSON = [:]
            let conditionId = value.conditionId;
            let referenceAId = value.referenceAId;
            let referenceBId = value.referenceBId;
            let relational = value.relational
            
            conditionJSON["conditionId"] = JSON(conditionId);
            conditionJSON["referenceAId"] = JSON(referenceAId);
            conditionJSON["referenceBId"] = JSON(referenceBId);
            conditionJSON["relational"] = JSON(relational);

            conditionArray.append(conditionJSON);
        }
       
        
        
        var statesArray = [JSON]();
        for (key,data) in states {
            var stateJSON:JSON = [:]
            stateJSON["stateId"] = JSON(key);
            stateJSON["stateName"] = JSON(data.0);
            stateJSON["x"] = JSON(data.1);
            stateJSON["y"] = JSON(data.2);
            statesArray.append(stateJSON);
        }
        var transitionsArray = [JSON]();
        
        for (_,data) in transitions {
            var transitionJSON:JSON = [:]
            let transitionId =  data.transitionId
            let transitionDisplayName = data.transitionDisplayName
            let fromStateId = data.fromStateId;
            let toStateId = data.toStateId;
            let conditionId = data.conditionId;
            
            transitionJSON["transitionId"] =  JSON(transitionId);
            transitionJSON["name"] = JSON(transitionDisplayName);
            transitionJSON["conditionId"] =  JSON(conditionId);
            transitionJSON["fromStateId"] = JSON(fromStateId);
            transitionJSON["toStateId"] = JSON(toStateId);
            transitionsArray.append(transitionJSON);
        }
        
        var methodArray = [JSON]();
        
        for (key,_) in methods {
            let methodJSON = methodToJSON(methodId:key);
            methodArray.append(methodJSON!);
        }
        
        var mappingsArray = [JSON]();
        
        for(key, data) in mappings{
            var mappingJSON:JSON = [:]
            
            let mappingId = key;
            let relativePropertyFieldName = data.5;
            let expressionId = data.1![0]
            let relativePropertyName = data.2
            let stateId = data.3
            let type = data.4
            mappingJSON["mappingId"] = JSON(mappingId);
            mappingJSON["relativePropertyName"] = JSON(relativePropertyName);
            mappingJSON["stateId"] = JSON(stateId);
            mappingJSON["expressionId"] = JSON(expressionId);
            mappingJSON["constraintType"] = JSON(type)
            mappingJSON["relativePropertyFieldName"] = JSON(relativePropertyFieldName);
            mappingsArray.append(mappingJSON);
            
        }
        let orderedMappings = Debugger.orderProps(propList: mappingsArray);
   
        print(orderedMappings)

        json_obj["states"] = JSON(statesArray);
        json_obj["transitions"] = JSON(transitionsArray);
        json_obj["mappings"] = JSON(orderedMappings);
        json_obj["methods"] = JSON(methodArray);
        json_obj["conditions"] = JSON(conditionArray);
        json_obj["expressions"] = JSON(expressionArray);

        return json_obj;
    }
    
    func methodToJSON(methodId:String)->JSON?{
        guard let method = methods[methodId] else{
            return nil;
        }
        
        
                    var methodJSON:JSON = [:]
                    methodJSON["transitionId"] = JSON(method.transitionId)
                    methodJSON["methodId"] = JSON(method.methodId);
                    let arguments =  method.arguments
                    var argumentList = [JSON]();
                    for j in 0..<arguments.count{
                        let argJSON = arguments[j].toJSON();
                        argumentList.append(argJSON);
                    }
                    methodJSON["argumentList"] = JSON(argumentList);
        methodJSON["displayName"] = JSON(method.displayName);
                    methodJSON["fieldName"] = JSON(method.fieldName);
                    return methodJSON;
    
    }
    
    
    //TODO: remove eventually- bad design
    func getStateByName(name:String)->String?{
        for(id,state) in self.states{
            if(state.0 == name){
                return id;
            }
        }
        return nil
    }
    
    
    
    func addCondition(conditionId:String, referenceAId:String, referenceBId:String, relational:String){
        
        conditions[conditionId] = (conditionId:conditionId, referenceAId:referenceAId, referenceBId:referenceBId, relational);
        
    }
    
    func changeConditionRelational(conditionId:String,relational:String) throws{
        if(conditions[conditionId] != nil){
            conditions[conditionId]!.relational = relational;
            return;
        }
        print("===========ERROR ATTEMPTED TO CHANGE RELATIONAL FOR CONDITION THAT DOES NOT EXIST=====================")

        throw BehaviorError.conditionDoesNotExist
    }
    
    func changeMethodDropdownArgument(methodId:String,fieldName:String,val:String) throws{
        if(methods[methodId] != nil){
            let method = methods[methodId]!
            for a in method.arguments{
                if(a.fieldName == fieldName){
                    a.defaultVal = val;
                }
            }
            return;
        }
        print("===========ERROR ATTEMPTED TO CHANGE DROPDOWN FOR METHOD THAT DOES NOT EXIST=====================")
        
        throw BehaviorError.methodDoesNotExist;
    
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
    
    func addMethod(transitionId:String, methodId: String, fieldName:String, displayName:String, arguments:[ArgumentData]){
        methods[methodId] = (transitionId:transitionId,methodId:methodId,fieldName:fieldName,displayName:displayName,arguments:arguments);
    }
    
    func checkDependency(behaviorId:String)->Bool{
        for (_, method) in methods{
                let fieldName = method.fieldName
                if(fieldName == "spawn"){
                    let args = method.arguments;
                    for a in args{
                        if(a.testSelected(id: behaviorId)){
                            return true;
                        }
                    }
                }
        }
        
        return false;
    }
    
    func removeMethod(methodId:String){
        if(methods[methodId] == nil){
            #if DEBUG
            print("===========WARNING ATTEMPTED TO REMOVE METHOD THAT DOES NOT EXIST=====================")
            #endif
            return;
        }
        methods.removeValue(forKey: methodId);
    }
    
    func removeMethodsForTransition(transitionId:String){
        for (_,method) in methods{
            if(method.transitionId == transitionId){
                methods.removeValue(forKey: transitionId);
            }
        }
    }
    
    func addTransition(transitionId:String,transitionDisplayName: String, conditionId:String, fromStateId:String, toStateId:String){
        transitions[transitionId] = (transitionId:transitionId, transitionDisplayName:transitionDisplayName, conditionId:conditionId,fromStateId:fromStateId,toStateId:toStateId);
    }
    
    
    
    func removeTransition(id:String) throws{
        
        removeMethodsForTransition(transitionId: id);
        
        if(transitions[id] != nil){
           let t =  transitions.removeValue(forKey: id)!;
            do{
                try  self.removeCondition(id:t.conditionId);
            }
            catch {
                print("===========ERROR ATTEMPTED TO REMOVE CONDITION IN TRANSITION THAT DOES NOT EXIST=====================")

                throw BehaviorError.conditionDoesNotExist;

            }
            return;
        }
        print("===========ERROR ATTEMPTED TO REMOVE TRANSITION THAT DOES NOT EXIST=====================")

        throw BehaviorError.transitionDoesNotExist;
        
    }
    
    func removeCondition(id:String) throws{
        if(conditions[id] != nil){
            let c =  conditions.removeValue(forKey: id)!;
             do{
                try self.removeExpression(id:c.referenceAId);
                try self.removeExpression(id:c.referenceBId);
            }
             catch {
                print("===========ERROR ATTEMPTED TO REMOVE EXPRESSION IN CONDITION THAT DOES NOT EXIST=====================")

                throw BehaviorError.expressionDoesNotExist;
                
            }
            return;
        }
        throw  BehaviorError.conditionDoesNotExist
    }
    
    func removeExpression(id:String) throws{
        if(expressions[id] != nil){
            expressions.removeValue(forKey: id);
            return
        }
        print("===========ERROR ATTEMPTED TO REMOVE EXPRESSION THAT DOES NOT EXIST=====================")

        throw BehaviorError.expressionDoesNotExist;
    }
    
    func removeTransitionsForState(stateId:String){
        for (key,transition) in transitions{
            if(transition.fromStateId == stateId || transition.toStateId == stateId){
                do {
                    try removeTransition(id: key);
                }
                catch{
                    print("===========ERROR NO TRANSIITONS FOR STATE=====================")
                }
                
            }
        }
    }
    
    
    func addMapping(id:String, referenceProperty:Emitter!, referenceNames:[String]?, relativePropertyName:String,stateId:String, type:String,relativePropertyFieldName:String){
        mappings[id] = ((referenceProperty,referenceNames,relativePropertyName,stateId,type,relativePropertyFieldName))
        
    }
    
    func getMappings()->JSON{
        var stateJSON:JSON = [:]
        for(key,_) in states{
            stateJSON[key] = getMappingsForState(stateId: key);
            
        }
        return stateJSON;
    }
    
   func getMappingsForState(stateId:String)->JSON{
    var mappingJSON:JSON = [:];
        for(key,mapping) in mappings{
            if mapping.3 == stateId{
                var mappingData:JSON = [:]
                mappingData["relativePropertyName"] = JSON(mapping.2);
                mappingData["relativePropertyFieldName"] = JSON(mapping.5);
                mappingJSON[key] = mappingData;
            }
        }
    return mappingJSON;
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
                    do{
                        try self.removeExpression(id: mappingKey);
                    }
                    catch{
                        print("===========ERROR ATTEMPTED TO REMOVE EXPRESSION THAT DOES NOT EXIST=====================")

                        throw BehaviorError.expressionDoesNotExist;

                    }
                }
            }
            mappings.removeValue(forKey: id);
            return;
        }
        print("===========ERROR ATTEMPTED TO REMOVE MAPPING THAT DOES NOT EXIST=====================")

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
    
    func addExpression(id:String, expressionPropertyList:[String], expressionText:String){
        expressions[id]=(expressionPropertyList:expressionPropertyList,expressionText:expressionText);
    }
    
    func generateSignal(brush:Brush, id:String)->Signal?{
        #if DEBUG   
           // print("generate signal",id);
        #endif
        guard let signal = BehaviorManager.getSignal(id:id) else{
            return nil
        }
        signal.registerBrush(brush:brush);
        return signal;
    }
    
    func generateOperand(targetBrush:Brush,targetEmitter:Emitter?, propId:String?)->Observable<Float>{
        let id = targetBrush.id
        var emitter:Emitter
        
        var operand:Observable<Float>
        
        if(targetEmitter == nil){
            emitter = targetBrush;
        }
        else{
            emitter = targetEmitter!
        }
        
        if(propId != nil){
            let signal = generateSignal(brush:targetBrush, id:propId!);
            if(signal != nil){
                operand = signal!;
            }
            else if(storedExpressions[id]![propId!] != nil){
                operand = storedExpressions[id]![propId!]!; 
                
            }
            else{
                //TOOD: Fix bug regarded to adding generators
                operand = (emitter as! Emitter).kvcDictionary[propId!]!
            }
            
        }
        else{
            operand = emitter as! Observable<Float>
        }
        
        return operand;
        
    }
    
    func generateCondition(targetBrush:Brush, conditionId:String, operandA:Expression, operandB:Expression, relational:String){
        
        let id = targetBrush.id;
        let condition = Condition(id:conditionId, a: operandA, b: operandB, relational: relational);
        storedConditions[id]![conditionId] = condition;
        
    }
    
    func generateExpression(targetBrush:Brush, name:String, signalIds:[String], expressionText:String){
        let id = targetBrush.id
        var operands = [String:Observable<Float>]();
        
        for observableId in signalIds {
            #if DEBUG
                print("registering observable target with id:",observableId);
            #endif
            let operand:Observable<Float>;
            operand = self.generateOperand(targetBrush: targetBrush, targetEmitter: nil, propId:observableId);
            
            operands[observableId] = operand;
            RequestHandler.registerObservableTarget(observableId: observableId, behaviorId: self.id)
        }
        let newExpressionData = Expression.parseForSignalAccessors(expressionString: expressionText, observables: operands)

        let expression = Expression(id:name,brushId:id,behaviorId:self.id,operandList: newExpressionData.newObservables, text: newExpressionData.newString);
        self.storedExpressions[id]![name] = expression;
    }
    
    func generateMapping(targetBrush:Brush, id:String, referenceEmitter:Emitter?, referenceProperties:[String]?, relativePropertyName:String, stateId:String){
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
    
    func getBrushById(id:String)->Brush?{
        for i in 0..<brushInstances.count{
            let b = brushInstances[i];
            if (b.id == id) {
                return b;
            }
        }
        return nil;
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
    
    
    func clearBehavior(drawing:Drawing){
        //reset associated signals
        for (_, expressionList) in self.storedExpressions {
            for (_, expression) in expressionList {
                for (_, signal) in expression.observableList {
                    let signal = signal as! Signal
                    signal.reset()
                }
            }
        }
        for (_, conditions) in self.storedConditions {
            for (_, condition) in conditions {
                condition.reset();
            }
        }
        
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
            targetBrush.destroy();
            
        }
        
     
        self.brushInstances.removeAll();
        drawing.destroyBehaviorRegistry(behaviorId: self.id);
        
    }
    
    func createBehavior(drawing:Drawing){
        clearBehavior(drawing: drawing);
        
        if(self.active_status){
            for i in 0..<self.auto_spawn_num{
                let targetBrush = Brush(name: "brush_" + String(i) + "_" + self.id, behaviorDef: self, parent: nil, drawing:drawing)
                targetBrush.index.set(newValue: Float(i));
                self.initBrushBehavior(targetBrush:targetBrush);
            }
        }
        
        
    }
    
    func initBrushBehavior(targetBrush:Brush){
        _ = targetBrush.signalEvent.addHandler(target: brushManager, handler:BrushSignalManager.brushUpdateHandler, key: "brush_update");
        let id = targetBrush.id
        storedConditions[id] = [String:Condition]();
        storedExpressions[id] = [String:Expression]();
        
        for (key,expression_data) in expressions{
            self.generateExpression(targetBrush: targetBrush, name: key, signalIds: expression_data.0, expressionText: expression_data.1);
        }
        print("conditions",conditions);
        for (_,value) in conditions{
            let conditionId = value.conditionId;
            let referenceAId = value.referenceAId;
            let referenceBId = value.referenceBId;
            let relational = value.relational;
          
            let operandA = generateOperand(targetBrush: targetBrush, targetEmitter: nil, propId: referenceAId) as! Expression;
            let operandB = generateOperand(targetBrush: targetBrush, targetEmitter: nil, propId: referenceBId) as! Expression;

            
            self.generateCondition(targetBrush: targetBrush, conditionId: conditionId, operandA: operandA, operandB: operandB, relational: relational);
        }
        
       
        
        for (id,state) in states{
            targetBrush.createState(id: id, name:state.0);
            
        }
        
        for (_,transition) in transitions{
            let condition = self.storedConditions[id]![transition.conditionId];
            guard condition != nil else{
                #if DEBUG
                    print("================ERROR: CONDITION NOT FOUND==================")
                #endif
                break;
            }
            targetBrush.addStateTransition(id: transition.transitionId, name: transition.transitionDisplayName, condition: condition!, fromStateId: transition.fromStateId, toStateId: transition.toStateId)
        }
        
        for (_,method) in methods{
            let arguments = method.arguments
            var initializedArguments = [Expression]();
            for i in 0..<arguments.count{
                let expressionId = arguments[i].getExpressionId();
                let expression:Expression
                if(expressionId != nil){
                    expression = self.storedExpressions[targetBrush.id]![expressionId!]!;
                }
                else{
                    expression = DropdownExpression(id: NSUUID().uuidString, brushId:targetBrush.id, behaviorId:self.id, operandList: [:], text: arguments[i].defaultVal);
                }
                initializedArguments.append(expression);

            }
           
            targetBrush.addMethod(transitionId:method.transitionId,methodId:method.methodId,fieldName:method.fieldName,arguments:initializedArguments)
                
            
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
        targetBrush.storeInitialValues();
        targetBrush.setupTransition();
        
    }
    
}

class ArgumentData{
    var defaultVal:String;
    let fieldName:String;
    let displayName:String;
    init(fieldName:String,displayName:String, defaultVal:String){
        self.defaultVal = defaultVal;
        self.displayName = displayName;
        self.fieldName = fieldName;
    }
    public func testSelected(id:String)->Bool{
        return false;
    }
    
    public func getExpressionId()->String?{
        return nil
    }
    
    
    public func toJSON()->JSON{
        var argumentJSON:JSON = [:]
        argumentJSON["defaultVal"] = JSON(defaultVal);
        argumentJSON["displayName"] = JSON(displayName);
        argumentJSON["fieldName"] = JSON(fieldName);

        return argumentJSON;
        
    }
}

class DropdownArgument:ArgumentData{
    let dropdownOptions = [(id:String,displayName:String)]();
    let options:[[String:String]]
    
    init(fieldName: String, displayName: String, defaultVal: String, options:[[String:String]]) {
        self.options = options;
        super.init(fieldName: fieldName, displayName: displayName, defaultVal: defaultVal)
        
    }
    override public func testSelected(id:String)->Bool{
        if defaultVal != "" {
            if(defaultVal == id){
                return true;
            }
        }
        return false;
    }
    
    override public func toJSON() -> JSON {
        var argumentJSON = super.toJSON();
        argumentJSON["isExpression"] = JSON(false);
        argumentJSON["isDropdown"] = JSON(true);
        argumentJSON["expressionId"] = JSON.null;
        argumentJSON["options"] = JSON(options);
        if defaultVal != ""{
            argumentJSON["default"] = JSON(defaultVal);
        }
        else{
            argumentJSON["default"] = JSON.null;
        }
        return argumentJSON;
    }

}

class ExpressionArgument:ArgumentData{
    let expressionId:String
   
    init(expressionId:String,fieldName:String,displayName:String,defaultVal:String){
        self.expressionId = expressionId;
        super.init(fieldName:fieldName, displayName:displayName, defaultVal:defaultVal);
    }
    override public func toJSON() -> JSON {
        var argumentJSON = super.toJSON();
        argumentJSON["isExpression"] = JSON(true);
        argumentJSON["isDropdown"] = JSON(false);
        argumentJSON["expressionId"] = JSON(expressionId);
        return argumentJSON;
    }
    
    override public func getExpressionId()->String?{
        return self.expressionId;
    }
    
    
}
