//
//  Behavior.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/22/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

class Condition:Observable<Float> {
    var referenceA:Observable<Float>
    var referenceB:Observable<Float>
    var relational:String
    
    
    init(a:Observable<Float>,b:Observable<Float>, relational:String){
        self.referenceA = a
        self.referenceB = b
        self.relational  = relational;
        super.init(0);
    }
    
    func reset(){
        if(relational == "within"){
            let interval = self.referenceB as! Interval
            interval.reset();
 
        }
    }
    
    func evaluate()->Bool{
        switch (relational){
        case "<":
            let a = referenceA.get(id: nil)
            let b = referenceB.get(id: nil)
            return a < b;
            
        case ">":
            return referenceA.get(id: nil) > referenceB.get(id: nil);
            
        case "==":
            let a = referenceA.get(id: nil)
            let b = referenceB.get(id: nil)
            return a == b;
        case "!=":
            let a = referenceA.get(id: nil)
            let b = referenceB.get(id: nil)
            return a != b;
        case "within":
            let interval = self.referenceB as! Interval
            let value = interval.get(id: nil);
           
            if(value > 0){
                if(referenceA.get(id: nil)>value){
                    interval.incrementIndex();
                    return true;
                }
            }
            return false;
          case "&&":
            let a = (referenceA as! Condition).evaluate();
            let b = (referenceB as! Condition).evaluate();
            if(a && b){
                return true;
            }
            return false;
        default:
            return false;
        }
        
    }
}
