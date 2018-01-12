//
//  BehaviorMapper.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 5/25/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

typealias BehaviorConfig = (target: Brush, action: String, emitter:Emitter, eventType:String, eventCondition:Condition?, expression: String?)


// creates mappings between brushes and behaviors
class BehaviorMapper{
    
      
    //TODO: remove so that behavior mapper class can be removed, also should remove event listener structure and replace with Event Class
    
    func createStateTransition(id:String,name:String,reference:Emitter,relative:Brush, eventName:String, fromStateId:String, toStateId:String, condition:Condition!){
        reference.assignKey(eventType: eventName,key:id,condition: condition,brush:relative)
        let selector = #selector(relative.stateTransitionHandler(notification:))
        NotificationCenter.default.addObserver(relative, selector:selector, name:NSNotification.Name(rawValue: id), object: reference)
        relative.addStateTransition(id: id, name:name,reference: reference, fromStateId:fromStateId, toStateId:toStateId)
        _ = relative.removeTransitionEvent.addHandler(target: relative, handler: Brush.removeStateTransition, key:id)
        
    }
    
   
}


