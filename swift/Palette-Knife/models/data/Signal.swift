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
    internal var index:Int = 0;
    internal var signalBuffer = [Float]();
    
    internal var position:Int = 0
    internal let fieldName:String!
    internal let displayName:String!
    internal let collectionId:String!
    internal var order:Int = -1
    internal let style:String!

    static let stylusUp:Float = 0.0;
    static let stylusMove:Float = 1.0;
    static let stylusDown:Float = 2.0;
    
    var dataSubscribers = [String:Observable<Float>]();
    var id:String
    //    var param = Observable<Float>(1.0);
    required init(id:String,fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        self.id = id;
        self.fieldName = fieldName;
        self.collectionId = collectionId
        self.displayName = displayName;
        self.style = style;
        super.init(0)
    }
    
    public func setOrder(i:Int){
        self.order = i;
    }
    
 
    func cloneRawData(protoData:[Float]){
        self.signalBuffer = protoData
    }
    
    override func get(id:String?) -> Float {
        
        let v:Float;
        
        v = signalBuffer[self.index];
        
        self.setSilent(newValue: v);
        return super.get(id: id);
        
    }
    
    
    override func getSilent()->Float{
        return signalBuffer[self.index];
    }
    
    
    
    func setIndex(i:Int){
        self.index = i;
    }
    
    func setSignal(s:[Float]){
        self.signalBuffer.removeAll();
        for i in 0..<s.count{
            signalBuffer[i] = s[i];
        }
    }
    
    
    func addValue(v:Float){
        signalBuffer.append(v);
        let prevV:Float;
        if(signalBuffer.count>1){
            prevV = signalBuffer[signalBuffer.count-1];
        }
        else{
            prevV = v;
        }
        self.didChange.raise(data: (self.id, prevV, v))
      
    }
    
    func incrementIndex(){
        self.setIndex(i: self.index+1);
    }
    
    func clearSignal(){
        signalBuffer.removeAll();
    }
    
    public func getCollectionName()->String?{
        return BehaviorManager.getCollectionName(id:self.collectionId);
    }
    
    
    public func getMetaJSON()->JSON{
        var metaJSON:JSON = [:]
        metaJSON["fieldName"] = JSON(self.fieldName);
        metaJSON["displayName"] = JSON(self.displayName);
        metaJSON["classType"] = JSON(String(describing: type(of: self)));
        metaJSON["settings"] = self.getSettingsJSON();
        metaJSON["order"] = JSON(self.order);
        metaJSON["style"] = JSON(self.style);
        return metaJSON;
    }
    
    //placeholder. needs to be overriden for signals with actual settings
    public func getSettingsJSON()->JSON{
        return JSON([:]);
    }
}

class TimeSignal:Signal{
    
}


class LiveSignal:Signal{
    required init(id: String, fieldName: String, displayName: String, collectionId: String, style: String, settings: JSON) {
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings: settings);
        self.setLiveStatus(status: true);
    }
}


class Recording:LiveSignal{
    private var next:Recording?
    private var prev:Recording?

    

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
    
    
    func getTimeOrderedList()->[Float]{
        return self.signalBuffer;
    }
}


class StylusEventRecording:Recording{
   
}

class StylusEvent:LiveSignal{
   
}











