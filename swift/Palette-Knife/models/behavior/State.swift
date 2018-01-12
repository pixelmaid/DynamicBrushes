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
    
    
     func addStateTransitionMapping(id:String, name:String, reference:Emitter,toStateId:String)->StateTransition{
        let mapping = StateTransition(id:id, name:name, reference:reference,toStateId:toStateId)
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
    var name: String;
    var id: String;
    var arguments: [Any]?
    var expressionId: String
    init(id:String,name:String,expressionId:String,arguments:[Any]?){
        self.name = name;
        self.id = id;
        self.arguments = arguments;
        self.expressionId = expressionId;
    }
    
    func toJSON()->String{
        var data = "{\"id\":\""+(self.id)+"\","
        data += "\"name\":\""+(self.name)+"\"}"
        return data;
    }
    
}

class StateTransition{
    var reference:Emitter
    var toStateId: String
    var methods = [Method]()
    let name: String
    let id: String
    
    init(id:String, name:String, reference:Emitter, toStateId:String){
        self.reference = reference
        self.toStateId = toStateId
        self.name = name
        self.id = id;
    }
    
    func addMethod(id:String, name:String, expressionId:String, arguments:[Any]?){
        methods.append(Method(id:id, name:name,expressionId:expressionId, arguments:arguments));
    }
    
    func toJSON()->String{
        var data = "{\"id\":\""+(self.id)+"\","
        data += "\"name\":\""+self.name+"\","
        data += "\"methods\":[";
        for i in 0..<methods.count{
            if(i>0){
                data += ","
            }
            data += methods[i].toJSON();
        }
        data += "]"
        data += "}"
        return data;
    }

}


