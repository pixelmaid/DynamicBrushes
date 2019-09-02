//
//  Variable.swift
//  DynamicBrushes
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
    internal var prevV:Float = 0;

    internal let maxVals = 100
    var behaviorId:String! = nil

    static let stylusUp:Float = 0.0;
    static let stylusMove:Float = 1.0;
    static let stylusDown:Float = 2.0;

    var dataSubscribers = [String:Observable<Float>]();
    var id:String


    required init(id:String,fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        self.id = id;
        self.fieldName = fieldName;
        self.collectionId = collectionId
        self.displayName = displayName;
        self.style = style;
        super.init(0)
    }
    
    func reset(){
        self.setIndex(i: 0)
    }
    
    public func paramsToJSON()->JSON{
        return JSON(signalBuffer[self.index]);
    }
    
    func setBehaviorId(id:String){
        self.behaviorId = id;
    }
    
    
    
    func incrementAndChange(v:Float){
        self.incrementIndex();
        self.didChange.raise(data: (self.id, self.prevV, v));
        self.prevV = v;
    }
    
    public func setOrder(i:Int){
        self.order = i;
    }
    
    func cloneRawData(protoData:[Float]){
        self.signalBuffer = protoData;

    }
    
    override func get(id:String?) -> Float {
        let v:Float;
        v = signalBuffer[self.index];

        self.setSilent(newValue: v);
        return super.get(id: id);
        
    }
    
    //placeholder for data access
    func getAtTime(time:Int, id:String?, shouldUpdate:Bool)->Float{
        return self.getSilent();
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
      
    }
    
    func addValueFor(behaviorId:String, brushId:String, v:Float){
        self.addValue(v: v);
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
    
    
    //PLACEHOLDERS FOR GENERATOR
    override func registerBrush(brush:Brush){
        
    }
    
    override func brushIsRegistered(brushId:String)->Bool{
        return false;
    }
    
    override func removeRegisteredBrush(id:String){
        
    }
    
   override func clearAllRegisteredBrushes(){
        
    }

}

class TimeSignal:Signal{
    
}



class LiveSignal:Signal{
    required init(id: String, fieldName: String, displayName: String, collectionId: String, style: String, settings: JSON) {
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings: settings);
        self.setLiveStatus(status: true);
    }
    
    override func addValue(v: Float) {
        if self.signalBuffer.count > self.maxVals {
            self.signalBuffer.removeFirst(1)
        }
        super.addValue(v: v);
        
        self.setIndex(i: self.signalBuffer.count-1);
        self.didChange.raise(data: (self.id, v, v));
    }
    
    
}

class BrushSignal:LiveSignal{
    var signalMatrix = [String:[String:[Float]]]();
    
    override func addValue(v: Float) {
        if self.signalBuffer.count > self.maxVals {
            self.signalBuffer.removeFirst(1)
        }
        super.addValue(v: v);
        self.didChange.raise(data: (self.id, v, v));
    }
    
    override func addValueFor(behaviorId:String,brushId:String,v:Float){
       if(signalMatrix[behaviorId] == nil){
            signalMatrix[behaviorId] = [String:[Float]]();
        }
        if( signalMatrix[behaviorId]![brushId] == nil){
            signalMatrix[behaviorId]![brushId] = [Float]();

        }
        signalMatrix[behaviorId]![brushId]!.append(v);
        if signalMatrix[behaviorId]![brushId]!.count > self.maxVals {
            signalMatrix[behaviorId]![brushId]!.removeFirst(1);
            
        }
        self.didChange.raise(data: (self.id, v, v));
        
    }
    
    override func get(id:String?)->Float{
     
        guard behaviorId != nil else{
            #if DEBUG
                print("===========ERROR ATTEMPTED TO ACCESS BRUSH SIGNAL WHEN NO BEHAVIOR ID SET========")
                #endif
            return 0;
        }
        guard id != nil else{
            #if DEBUG
                print("===========ERROR ATTEMPTED TO ACCESS BRUSH SIGNAL WHEN NO BRUSH ID SET========")
            #endif
            return 0;
        }
        let signal = signalMatrix[behaviorId]!;
        let signalVector = signal[id!]!;
        if(signalVector.count>0){
            let val = signalVector.last!;
            return val;
        }
        else{
            return 0;
        }
    }
    
    
}

class Recording:Signal{

  
    func getTimeOrderedList()->[Float]{
        return self.signalBuffer;
    }
}


class StylusEventRecording:Recording{
   
}

class StylusEvent:LiveSignal{
   
}

class ImportedRecording:ImportedSignal {
    
}


class ImportedSignal:Signal{
    required init(id: String, fieldName: String, displayName: String, collectionId: String, style: String, settings: JSON) {
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings: settings);
    }
    
    override func get(id:String?)-> Float{
      
        let v = super.get(id: id);
        incrementAndChange(v: v);
        return v;
    }
    
    override func incrementAndChange(v: Float) {
        super.incrementAndChange(v: v);
        if self.index >= self.signalBuffer.count{
            self.index = 0;
        }
    }
    
}













