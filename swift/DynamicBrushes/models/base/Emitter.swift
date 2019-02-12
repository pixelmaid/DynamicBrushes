//
//  Emitter.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/25/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//



import Foundation

class Emitter: Observable<Float>, Equatable  {
    
    var kvcDictionary = [String:Observable<Float>]();
    var events =  [String]()
    var keyStorage=[String:[(String,Condition?,Brush)]]()
    var id:String = NSUUID().uuidString;
    
    init(){
        super.init(0);
        self.name = "default"
    }
    
    func createKeyStorage(){
        for e in events{
            self.keyStorage[e] = [(String,Condition?,Brush)]();
        }
        
    }
    
    @objc dynamic func propertyInvalidated(notification: NSNotification){
        self.invalidated = true;
        
        for key in keyStorage["INVALIDATED"]!  {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.2.id, "event":"INVALIDATED"])
            
        }
        
    }
    
    func assignKey(eventType:String,key:String,condition:Condition!,brush:Brush){
        keyStorage[eventType]?.append((key,condition,brush))
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

