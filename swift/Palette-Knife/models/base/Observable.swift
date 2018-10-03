//
//  Observable.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 8/18/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

class Observable<T>: DisposableObservable {
    
    var name = "observable"
    var printname = "observable"
    var isPassive = false;
    var invalidated = false;
    var constrained = false;
    var subscribers = [String:Int]();
    var constraintTarget: Observable<T>?
    let didChange = Event<(String,T, T)>()
    var observables = [DisposableObservable]();
    private var value: T
    
    init(_ initialValue: T) {
        value = initialValue
    }
    
    func set(newValue: T) {
        let oldValue = value
        value = newValue
        self.invalidate(oldValue: oldValue, newValue: newValue)
       
    }
    
    func constrainedAndActive()->Bool{
        if(self.constraintTarget == nil && self.constrained){
            return true;
        }
        return false;
    }
    
    func constrainedAndPassive()->Bool{
        if(self.constraintTarget != nil && self.constrained){
            return true;
        }
        return false;
    }
    
    
    func invalidate(oldValue: T, newValue: T){
        invalidated = true;
        didChange.raise(data: (name, oldValue, newValue))
    }
    
    //used for passiveConstraints
    
    func passiveConstrain(target:Observable<T>){
        self.constraintTarget = target;
        target.isPassive = true;
    }
    
    //sets without raising change event
    func setSilent(newValue:T){
        value = newValue
    }
    
    func get(id:String?) -> T {
        invalidated = false;
        if(constraintTarget != nil && self.constrained == true){
            let newValue = constraintTarget!.get(id: id);
            return  newValue
        }
        return value
    }
    
    func getSilent() -> T {
        return value
    }
    
    func subscribe(id:String){
        subscribers[id] = 0
    }
    
    func unsubscribe(id:String){
        subscribers.removeValue(forKey: id)
    }
    
    func destroy(){
        for observable in observables {
            observable.destroy();
        }
        self.didChange.removeAllHandlers();
        self.subscribers.removeAll();
        self.constraintTarget = nil;
        
    }

}

protocol DisposableObservable {
    
    func destroy()
    
}
