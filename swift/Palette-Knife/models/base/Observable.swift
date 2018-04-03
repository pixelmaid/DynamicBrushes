//
//  Observable.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 8/18/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import SwiftKVC

class Observable<T>:Object, DisposableObservable {
    
    var name = "observable"
    var printname = "observable"
    private var live = false;
    var invalidated = false;
    var constrained = false;
    var constraintTarget: Observable<T>?
    let didChange = Event<(String,T, T)>()
    var observables = [DisposableObservable]();
    private var value: T
    
    init(_ initialValue: T) {
        value = initialValue
    }
     func isSignalAccessor()->Bool{
        return false;
    }
    func set(newValue: T) {
        let oldValue = value
        value = newValue
        self.invalidate(oldValue: oldValue, newValue: newValue);
    }
    
    func isLive()->Bool{
        return live;
    }
    
    func setLiveStatus(status:Bool){
        self.live = status;
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
    
    //used for passive Constraints
    
    func passiveConstrain(target:Observable<T>){
        self.constraintTarget = target;
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
    
   
    
    func destroy(){
        for observable in observables {
            observable.destroy();
        }
        self.didChange.removeAllHandlers();
        self.constraintTarget = nil;
        self.clearAllRegisteredBrushes();
        
    }
    
    //TODO: PLACEHOLDERS FOR GENERATOR
    
     func registerBrush(id:String){
        
    }
    
     func removeRegisteredBrush(id:String){
       
    }
    
    func clearAllRegisteredBrushes(){
        
    }


}

protocol DisposableObservable {
    
    func destroy()
    
}
