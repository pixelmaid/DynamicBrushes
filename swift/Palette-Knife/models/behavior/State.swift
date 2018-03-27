//
//  State.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/20/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

class State {
    var transitions = [String:StateTransition]()
    var constraint_mappings = [String:Constraint]()
    let name: String
    let id: String
    
    init(id:String,name:String){
        self.id = id;
        self.name = name;
    }
    
    func addConstraintMapping(key:String, reference:Observable<Float>, relativeProperty:Observable<Float>, type:String){
        let mapping = Constraint(id:key,reference: reference, relativeProperty:relativeProperty,type:type)
        constraint_mappings[key] = mapping;
    }
    
    func removeAllConstraintMappings(brush:Brush){
        for (key,_) in constraint_mappings{
           _ = removeConstraintMapping(key:key,brush:brush);
        }
     }
    
    func removeAllTransitions()->[StateTransition]{
        var removed = [StateTransition]();
        for (key,_) in transitions{

            removed.append(removeTransitionMapping(key:key)!);
        }
        return removed;
    }

    
    func removeConstraintMapping(key:String, brush:Brush)->Constraint?{
        
        constraint_mappings[key]!.relativeProperty.constrained = false;
        constraint_mappings[key]!.reference.unsubscribe(id:brush.id);
        constraint_mappings[key]!.reference.didChange.removeHandler(key:key)
        constraint_mappings[key]!.relativeProperty.constraintTarget = nil;
       return constraint_mappings.removeValue(forKey: key)
    }
    
    
     func addStateTransitionMapping(id:String, name:String, condition:Condition,toStateId:String)->StateTransition{
        let mapping = StateTransition(id:id, name:name, condition:condition,toStateId:toStateId)
        transitions[id] = mapping;
        return mapping;
    }
    
     func removeTransitionMapping(key:String)->StateTransition?{
        return transitions.removeValue(forKey: key)
        
    }
 
    func getConstraintMapping(key:String)->Constraint?{
             if let _ = constraint_mappings[key] {
            return  constraint_mappings[key]
        }
        else {

            return nil
        }
    }
    
    func getTransitionMapping(key:String)->StateTransition?{
        if let _ = transitions[key] {
            return  transitions[key]
        }
        else {
            
            return nil
        }
    }

    
    func hasTransitionKey(key:String)->Bool{
        if(transitions[key] != nil){
            return true
        }
        return false
    }
    
    func hasConstraintKey(key:String)->Bool{
        if(constraint_mappings[key] != nil){
            return true
        }
        return false
    }
    
    func toJSON()->String{
        var data = "{\"id\":\""+(self.id)+"\","
        data += "\"name\":\""+self.name+"\","
        data += "\"mappings\":[";
        var count = 0;
        for (_, mapping) in constraint_mappings{
            if(count>0){
                data += ","
            }
            data += mapping.toJSON();
            count += 1;
        }
        data += "]"
        data += "}"
        return data;
    }
  
}

struct Constraint{
    var reference:Observable<Float>
    var relativeProperty:Observable<Float>
    var id:String
    var type:String
    init(id:String, reference:Observable<Float>, relativeProperty:Observable<Float>,type:String){
        self.reference = reference
        self.relativeProperty = relativeProperty
        self.id = id;
        self.type = type; //should be active or passive
    }
    
    func toJSON()->String{
        let data = "{\"id\":\""+(self.id)+"\"}"
        return data;
    }
}

class Method{
    var fieldName: String;
    var id: String;
    var arguments: [Expression]
    init(id:String,fieldName:String,arguments:[Expression]){
        self.fieldName = fieldName;
        self.id = id;
        self.arguments = arguments;
    }
    
    
}

class StateTransition{
    var condition:Condition
    var toStateId: String
    var methods = [Method]()
    let name: String
    let id: String
    let didTrigger = Event<(String)>();
    var disposables = [Disposable]()

    init(id:String, name:String, condition:Condition, toStateId:String){
        self.condition = condition
        self.toStateId = toStateId
        self.name = name
        self.id = id;
        let disposable = condition.didChange.addHandler(target: self, handler: StateTransition.conditionValidatedHandler, key: self.id)
        self.disposables.append(disposable)
    }
    
    func addMethod(id:String, fieldName:String,  arguments:[Expression]){
        methods.append(Method(id:id, fieldName:fieldName, arguments:arguments));
    }
    
    func conditionValidatedHandler(data:(String, Bool, Bool),key:String){
        self.didTrigger.raise(data: (self.id));
    }
    
    func destroy(){
        for d in disposables{
            d.dispose();
        }
    }
    

    

}


