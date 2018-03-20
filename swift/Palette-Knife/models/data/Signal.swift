//
//  Variable.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/28/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON


class Signal:Observable<Float>{
    internal var hash:Float = -1;
    internal var signalBuffer = [Float:Float]();
    
    internal var position:Int = 0;
    internal let fieldName:String!
    internal let displayName:String!
    internal let collectionId:String!;
    
    
    var dataSubscribers = [String:Observable<Float>]();
    var id:String
    //    var param = Observable<Float>(1.0);
    required init(id:String,fieldName:String, displayName:String, collectionId:String, settings:JSON){
        self.id = id;
        self.fieldName = fieldName;
        self.collectionId = collectionId
        self.displayName = displayName;
        super.init(0)
        RequestHandler.registerObservable(observableId: id, observable: self)
    }
    
 
    func cloneRawData(protoData:[Float:Float]){
        self.signalBuffer = protoData
    }
    
    override func get(id:String?) -> Float {
        
        let v:Float;
        
        v = signalBuffer[hash]!;
        
        self.setSilent(newValue: v);
        return super.get(id: id);
        
    }
    
    
    override func getSilent()->Float{
        return signalBuffer[hash]!
    }
    
    
    
    func setHash(h:Float){
        self.hash = h;
    }
    
    func setSignal(s:[Float]){
        self.signalBuffer.removeAll();
        for i in 0..<s.count{
            signalBuffer[Float(i)] = s[i];
        }
    }
    
    
    func addValue(h:Float,v:Float){
        signalBuffer[h] = v;
        self.setHash(h:h);
    }
    
    func incrementIndex(){
        hash = hash+1.0;
    }
    
    func clearSignal(){
        signalBuffer.removeAll();
    }
    
    public func getCollectionName()->String?{
        return BehaviorManager.getCollectionName(id:self.collectionId);
    }
    
}


class LiveSignal:Signal{
    
}


class Recording:Signal{
    private var next:Recording?
    private var prev:Recording?
    private var lastSample:Float = 0;
    
    
    func getNext()->Recording?{
        if(next != nil){
            return next!;
        }
        return nil;
    }
    
    func getPrev()->Recording?{
        if(prev != nil){
            return prev!;
        }
        return nil;
    }
    
    func setNext(r:Recording){
        next = r;
    }
    
    func setPrev(r:Recording){
        prev = r;
    }
    
    override func addValue(h:Float,v:Float){
        super.addValue(h: h, v: v);
        self.lastSample = h;
    }
    
    func getTimeOrderedList()->[Float]{
        var orderedList = [Float]();
        var hashValue = Float(0);
        while(hashValue <= self.lastSample){
            if(self.signalBuffer[hashValue] != nil){
                orderedList.append(signalBuffer[hashValue]!);
            }
            hashValue+=1.0;
        }
        
        return orderedList;
    }
}


class StylusEventRecording:StylusEvent{
    
}

class StylusEvent:LiveSignal{
    let stylusUp = 0.0;
    let stylusMove = 1.0;
    let stylusDown = 2.0;
}











