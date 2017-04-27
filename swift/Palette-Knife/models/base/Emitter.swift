//
//  Emitter.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 5/25/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//



import Foundation
//import SwiftKVC

class Emitter: Observable<Float>, Equatable  {
    
    var events =  [String]()
    var keyStorage=[String:[(String,Condition!)]]()

    init(){
        super.init(0);
        self.name = "default"
    }
    
    func createKeyStorage(){
        for e in events{
            self.keyStorage[e] = [(String,Condition!)]();
        }
        
    }
    
    dynamic func propertyInvalidated(notification: NSNotification){
        self.invalidated = true;
        
        for key in keyStorage["INVALIDATED"]!  {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0, "event":"INVALIDATED"])
            
        }
        
    }
    
    func assignKey(eventType:String,key:String,condition:Condition!){
        keyStorage[eventType]?.append((key,condition))
    }
    
    func removeKey(key:String){
        for(eventType,keyList) in keyStorage{
            keyStorage[eventType] = keyList.filter() {$0.0 != key}
            
        }
    }
    
   
    
    override func destroy(){
        NotificationCenter.default.removeObserver(self);
        super.destroy();
        
    }
}

// MARK: Equatable
func ==(lhs:Emitter, rhs:Emitter) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}

