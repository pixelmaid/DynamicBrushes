//
//  SignalCollection.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 3/6/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import SwiftKVC
import SwiftyJSON
enum SignalError: Error {
    case signalTypeAlreadyRegistered;
    case protoNotFound;
    
   
}

//stores a collection of related signals e.g. a stylus recording, a data table
class SignalCollection: Object{
    //list of hashes for all samples
    internal var samples:Set<Float> = [];
    internal var lastSample:Float = 0;
    //stored instances of available signals
    internal var initializedSignals  = [String:[String:Signal]]();
    internal var protoSignals = [String:Signal]();
    //signal types that can be initialized
    internal var registeredSignals = [String:String]();
    public let id:String
    
    init(){
        self.id = NSUUID().uuidString;
    }
    
    init(data:JSON){
        self.id = data["meta"]["view"]["id"].stringValue;

        do{
            try self.loadDataFromJSON(data: data);
        }
        catch {
            
            
            print("ERRROR ---------SIGNAL ERROR ON INIT-----------")
        }
    }
    
    public func syncSignalsToHash(hash:Float){
        
    }
    
  public  func loadDataFromJSON(data:JSON) throws{
    
        let allSignalData = data["meta"]["view"]["columns"].arrayValue;
        #if DEBUG
            //print("dataset loaded",columns,data)
        #endif
        let rawData = data["data"].arrayValue;
        for i in 0..<allSignalData.count{
            let fieldName = allSignalData[i]["fieldName"].stringValue;
            let displayName = allSignalData[i]["displayName"].stringValue;
            let classType =  allSignalData[i]["classType"].stringValue;
            let settings = allSignalData[i]["settings"]

            
            do{
                try self.registerSignalType(fieldName: fieldName, displayName:displayName, settings:settings, classType: classType);
                guard let  signal = self.protoSignals[fieldName] else {
                   throw SignalError.protoNotFound
                }
                for j in 0..<rawData.count{
                    let row = rawData[j].arrayValue;
                    let v = row[i].floatValue;
                    signal.addValue(h: Float(j), v: v);
                }
            }
            
        }
    
    }
    
    public func registerSignalType(fieldName:String, displayName:String, settings:JSON, classType:String) throws{
        if(self.registeredSignals[fieldName] != nil){
            self.registeredSignals[fieldName] = classType;
            self.initializedSignals[fieldName] = [String:Signal]();
            do {
                try _ = self.initializeSignal(fieldName: fieldName, displayName: displayName, settings: settings, isProto: true)
            }

            
        }
        else{
            throw SignalError.signalTypeAlreadyRegistered;
        }
    }
    
    
    public func initializeSignal(fieldName:String, displayName:String, settings:JSON, isProto:Bool)throws->String{
        let id = NSUUID().uuidString
        let aClass = NSClassFromString(fieldName) as! Signal.Type;
        let signal = aClass.init(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        if(isProto){
            self.protoSignals[fieldName] = signal;
        }
        else{
            guard let protoData = self.protoSignals[fieldName]?.signalBuffer else{
                throw SignalError.protoNotFound;
            }
            signal.cloneRawData(protoData:protoData)
            RequestHandler.registerObservable(observableId: id, observable: signal);
            self.initializedSignals[fieldName]![id] = signal;
        }
        return id;
    }
    
    public func removeSignal(fieldName:String,id:String){
       
        if (initializedSignals[fieldName]![id] != nil){
            let signal = initializedSignals[fieldName]?.removeValue(forKey: id);
            signal?.destroy();
        }
    }
    
    public func addProtoSample(hash:Float,data:JSON){
        self.samples.insert(hash)
        self.lastSample  = hash;
         for (key,value) in data {
            guard let targetProtoSignal = self.protoSignals[key] else {
                print("ERRROR ---------NO PROTO SIGNAL FOUND THAT CORRESPOND WITH FIELD NAME-----------")
                return;
                
            }
          
            targetProtoSignal.addValue(h: hash, v: value.floatValue)
            
        }
    }
    
    public func getProtoSignalValue(fieldName:String)->Float?{
        guard let signal =  self.protoSignals[fieldName] else{
            return nil
        }
        return signal.get(id:nil);
    }
    
   
    
    public func getProtoSample(hash:Float)->JSON?{
        if (samples.contains(hash)){
        
        var sample:JSON = [:]
        for (key,value) in self.protoSignals{
            
                value.setHash(h:hash);
                sample[key] = JSON(value.get(id:nil));
            }
            sample["hash"] = JSON(hash)
            sample["lastHash"] = JSON(self.lastSample)
            sample["isLastInRecording"] = JSON(false);
            sample["isLastInSeries"] = JSON(false);
            sample["sequenceHash"] = JSON(0);
            sample["recordingId"] = JSON(self.id);
            return sample;
        }
        return nil;
    }
    
}

class GeneratorCollection:SignalCollection{
    
   override  init(){
        super.init();
        do{
           /* try self.registerSignalType(fieldName: "sine", displayName: "sine wave", classType: "Sine");
            try self.registerSignalType(fieldName: "square", displayName: "square wave", classType: "Square");
            try self.registerSignalType(fieldName: "triangle", displayName: "triangle wave",classType: "Triangle");
            try self.registerSignalType(fieldName: "random", displayName: "random", classType: "Random");
            try self.registerSignalType(fieldName: "sawtooth", classType: "Sawtooth");
            try self.registerSignalType(fieldName: "alternate", classType: "Alternate");*/
        }
        catch SignalError.signalTypeAlreadyRegistered{
            print("ERRROR ---------Signal Type already Registered-----------")
        }
        catch {
            
        }
    }
}



class BrushCollection:SignalCollection{
    
    override init(){
        super.init();
        do{
           /* try self.registerSignalType(fieldName: "spawnIndex", classType: "Index");
            try self.registerSignalType(fieldName: "siblingCount", classType: "SiblingCount");*/
        }
        catch SignalError.signalTypeAlreadyRegistered{
            print("ERRROR ---------Signal Type already Registered-----------")
        }
        catch {
            
        }
    }
}


class UICollection:SignalCollection{
    
    override init(){
        super.init();
        do{
            /*try self.registerSignalType(fieldName: "hue", classType: "Signal");
            try self.registerSignalType(fieldName: "lightness", classType: "Signal");
            try self.registerSignalType(fieldName: "saturation", classType: "Signal");
            try self.registerSignalType(fieldName: "diameter", classType: "Signal");
            try self.registerSignalType(fieldName: "alpha", classType: "Signal");*/

        }
        catch SignalError.signalTypeAlreadyRegistered{
            print("ERRROR ---------Signal Type already Registered-----------")
        }
        catch {
            
        }
    }
}


class StylusCollection:SignalCollection{
   override init(){
       super.init();
        do{
          /*  try self.registerSignalType(fieldName: "dx", classType: "Recording");
            try self.registerSignalType(fieldName: "dy", classType: "Recording");
            try self.registerSignalType(fieldName: "x", classType: "Recording");
            try self.registerSignalType(fieldName: "y", classType: "Recording");
            try self.registerSignalType(fieldName: "force", classType: "Recording");
            try self.registerSignalType(fieldName: "angle", classType: "Recording");
            try self.registerSignalType(fieldName: "stylusEvent", classType: "EventRecording"); */
        }
        catch SignalError.signalTypeAlreadyRegistered{
            print("ERRROR ---------Signal Type already Registered-----------")
        }
        catch {
            
        }
        
        
    }
}

class StylusRecordingCollection:StylusCollection{
   
    //stylus
    var next:StylusRecordingCollection?
    var prev:StylusRecordingCollection?
    var start:Date;
    var resultantStrokes = [String:[String]]();
    var targetLayer:String
    
    init(id:String,start:Date,targetLayer:String){
        self.start = start;
        self.targetLayer = targetLayer;
        super.init();

    }
   
    override func getProtoSample(hash: Float) -> JSON? {
        var sample = super.getProtoSample(hash: hash);
        if(sample != nil){
            sample!["targetLayer"] = JSON(self.targetLayer);
            return sample;
        }
        return nil;
    }
    
    
    func store(next:StylusRecordingCollection){
        self.next = next;
        next.prev = self;
    }
    
    func endRecording(){
        var sampleList = [Float:Float]();
        var hashValue:Float  = 0;
        while(hashValue <= self.lastSample){
            if(self.samples.contains(hashValue)){
                protoSignals["stylusEvent"]!.setHash(h: hashValue);
                let sE =  protoSignals["stylusEvent"]!.get(id:nil);
                
                sampleList[hashValue] = sE;
                print(" recording at:",hashValue,sE);
            }
            hashValue+=1.0;
        }
        
    }
    
    //TODO: move these to stylus manager
    func addResultantStroke(layerId:String,strokeId:String){
        if(resultantStrokes[layerId] == nil){
            resultantStrokes[layerId] = [String]();
        }
        resultantStrokes[layerId]!.append(strokeId);
    }
    
    func removeResultantStrokes(){
        resultantStrokes.removeAll();
    }
    
    
}
