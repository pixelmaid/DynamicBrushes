//
//  Behavior.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/22/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

class Condition:Observable<Bool> {
    var referenceA:Expression
    var referenceB:Expression
    var relational:String
    var interval:ConditionalInterval;
    let id:String;
    var disposables = [Disposable]()
    
    init(id:String, a:Expression,b:Expression, relational:String){
        self.id = id;
        self.referenceA = a;
        self.referenceB = b;
        
        self.relational  = relational;
        self.interval = ConditionalInterval();
        super.init(false);
        
        disposables.append(self.referenceA.didChange.addHandler(target: self, handler: Condition.expressionChangeHandler, key: self.id));
        disposables.append(self.referenceB.didChange.addHandler(target: self, handler: Condition.expressionChangeHandler, key: self.id));

    }
    
    func reset(){
        interval.setIndex(val:0);
    }
    
    func changeRelational(relational:String){
        self.relational = relational;
        self.checkIsValid();
    }
    
    func expressionChangeHandler(data:(String, Float, Float),key:String){
        self.checkIsValid();
    }
    
    func checkIsValid(){
        let isValid = self.evaluate();
        if(isValid){
            self.didChange.raise(data: (self.id,isValid,isValid));
        }
    }
    
    func evaluate()->Bool{
        let a = referenceA.get(id: nil)
        let b = referenceB.get(id: nil)
        switch (relational){
        case "<":
            
            return a < b;
            
        case ">":
            return a > b;
            
        case "==":
            return a == b;
        case "!=":
            return a != b;
        case "within":
            let value = interval.get(inc:b);
            if(value > 0){
                if(a>value){
                    interval.incrementIndex();
                    return true;
                }
            }
            return false;
        default:
            return false;
        }
        
    }
    
    override func destroy(){
        for d in disposables{
            d.dispose();
        }
        super.destroy();
    }
}




class ConditionalInterval{
    var val = [Float]();
    var index = 0;
    
    
    
    func get(inc:Float) -> Float {
        let inf = Float(self.index)*inc
        return inf;
    }
    
    func incrementIndex(){
        self.index += 1;
    }
    
    func setIndex(val:Int){
        self.index = val;
    }
    
  
    
    
    
}
