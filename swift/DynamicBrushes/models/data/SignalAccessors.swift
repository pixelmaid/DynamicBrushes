//
//  SignalAccessors.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 4/2/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation


class SignalAccessor:Signal{
    var referenceA:Signal! = nil;
    var referenceB:Signal! = nil;
    
    override func setBehaviorId(id: String) {
        self.behaviorId = id;
    }
  
    func setReferences(a:Signal,b:Signal){
        self.referenceA = a;
        self.referenceB = b;
    }
    
    override func isSignalAccessor()->Bool{
        return true;
    }
    
}


class Within:SignalAccessor{
   
    override func get(id:String?)->Float{
        guard id != nil else{
            #if DEBUG
                print ("=============ERROR ATTEMPTED TO ACCESS WITHIN VALUE WITH NO BRUSH ID==================")
            #endif
            return 0
            
        }
        guard behaviorId != nil else{
            #if DEBUG
                print ("=============ERROR ATTEMPTED TO ACCESS WITHIN VALUE WITH NO BEHAVIOR ID==================")
            #endif
            return 0
            
        }
        guard referenceA != nil && referenceB != nil else{
            #if DEBUG
                print ("=============ERROR ATTEMPTED TO ACCESS WITHIN VALUE WITH NIL REFERENCES==================")
            #endif
            return 0

        }
        referenceA.setBehaviorId(id: self.behaviorId);
        referenceB.setBehaviorId(id: self.behaviorId);
        let index = Int(referenceB.get(id: id));
        let formerIndex = referenceA.index;
        referenceA.setIndex(i: index);
        let val = referenceA.get(id: id);
        referenceA.setIndex(i: formerIndex);
        return val;
    }
}
