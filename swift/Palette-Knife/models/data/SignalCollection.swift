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
    public let name:String
    public let classType:String;
    
    
    required init(data:JSON){
        self.id = data["id"].stringValue;
        self.name = data["name"].stringValue;
        self.classType = data["classType"].stringValue;
        do{
            try self.loadDataFromJSON(data: data);
        }
        catch {
            
            
            print("ERROR ---------SIGNAL ERROR ON INIT-----------")
        }
    }
    
    
    public  func loadDataFromJSON(data:JSON) throws{
        print("data",data)
        let allSignalData = data["signals"].arrayValue;
       
        let rawData = data["data"].arrayValue;
        for i in 0..<allSignalData.count{
            let fieldName = allSignalData[i]["fieldName"].stringValue;
            let displayName = allSignalData[i]["displayName"].stringValue;
            let classType =  allSignalData[i]["classType"].stringValue;
            let settings = allSignalData[i]["settings"]
            let order = i;
            
            self.registerSignalType(fieldName: fieldName, displayName:displayName, settings:settings, classType: classType, order: order);
            guard let  signal = self.protoSignals[fieldName] else {
                print("ERROR======SIGNAL PROTO NOT FOUND==============",fieldName)
                throw SignalError.protoNotFound
                
            }
            for j in 0..<rawData.count{
                let row = rawData[j].arrayValue;
                let v = row[i].floatValue;
                signal.addValue(h: Float(j), v: v);
            }
            
        }
        
    }
    
    public func protoToJSON()->JSON{
        var json:JSON = [:];
        var signals = [JSON]();
        
        for (_,value) in self.protoSignals{
           let data = value.getMetaJSON();
            signals.append(data);
        }
        
        json["signals"] = JSON(signals);
        json["classType"] = JSON(self.classType);
        json["id"] = JSON(self.id);
        json["name"] = JSON(self.name);
        json["data"] = self.rawDataToJSON();
        return json;
    }
    
    public func rawDataToJSON()->JSON{
        var rawData = [[Float]]();
        let sortedProtos = self.protoSignals.sorted{ $0.1.order < $1.1.order }
        for _ in 0..<sortedProtos[0].value.signalBuffer.count {
            rawData.append([Float]());
        }
        for i in 0..<sortedProtos.count {
            let dB = sortedProtos[i].value.signalBuffer;
            let sortedBuffer = dB.sorted{ $0.key < $1.key }
           for j in 0..<sortedBuffer.count {
            rawData[i].append(sortedBuffer[j].value);
            }
        }
        return JSON(rawData);
    }
    
    
    public func registerSignalType(fieldName:String, displayName:String, settings:JSON, classType:String, order:Int){
        if(self.registeredSignals[fieldName] == nil){
            self.registeredSignals[fieldName] = classType;
            self.initializedSignals[fieldName] = [String:Signal]();
            _ = self.initializeSignal(fieldName: fieldName, displayName: displayName, settings: settings, classType:classType, isProto: true, order:order)
            
        }
        else{
            print("ERROR======SIGNAL ALREADY REGISTERED==============",fieldName)
        }
    }
    
    
    public func initializeSignal(fieldName:String, displayName:String, settings:JSON, classType:String, isProto:Bool, order:Int?)->String{
        let id = NSUUID().uuidString
        let signal = Signal(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        self.storeSignal(fieldName: fieldName, signal: signal, isProto:isProto, order:order)
        return id;
    }
    
    internal func storeSignal(fieldName:String, signal:Signal,isProto:Bool, order:Int?){
        if(isProto){
            guard order != nil else {
                print("ERROR======NO ORDER VALUE FOR PROTO SIGNAL=============",fieldName)
                return;
            }
            self.protoSignals[fieldName] = signal;
            signal.setOrder(i: order!)
        }
        else{
            guard let protoData = self.protoSignals[fieldName]?.signalBuffer else{
                print("ERROR======NO PROTODATA AVAILABLE=============",fieldName)
                return;
            }
            signal.cloneRawData(protoData:protoData)
            RequestHandler.registerObservable(observableId: id, observable: signal);
            self.initializedSignals[fieldName]![id] = signal;
        }
    }
    
    public func getInitializedSignal(id:String)->Signal?{
        for(_,signalList) in self.initializedSignals{
            if signalList[id] != nil{
                return signalList[id];
            }
        }
        return nil;
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
                print("ERROR ---------NO PROTO SIGNAL FOUND THAT CORRESPOND WITH FIELD NAME-----------",key,self.protoSignals)
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
    
    
    required init(data:JSON){
        super.init(data:data);
    }
    
    /*override  init(){
     super.init();
     do{
     try self.registerSignalType(fieldName: "sine", displayName: "sine wave", classType: "Sine");
     try self.registerSignalType(fieldName: "square", displayName: "square wave", classType: "Square");
     try self.registerSignalType(fieldName: "triangle", displayName: "triangle wave",classType: "Triangle");
     try self.registerSignalType(fieldName: "random", displayName: "random", classType: "Random");
     try self.registerSignalType(fieldName: "sawtooth", classType: "Sawtooth");
     try self.registerSignalType(fieldName: "alternate", classType: "Alternate");
     }
     catch SignalError.signalTypeAlreadyRegistered{
     print("ERRROR ---------Signal Type already Registered-----------")
     }
     catch {
     
     }
     }*/
    
    public override func initializeSignal(fieldName:String, displayName:String, settings:JSON, classType:String, isProto:Bool, order:Int?)->String{
        let id = NSUUID().uuidString
        let signal:Signal
        switch(fieldName){
        case "sine":
            signal = Sine(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        break;
        case "sawtooth":
            signal = Sawtooth(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        break;
        case "interval":
            signal = Interval(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
            break;
        case "square":
            signal = Square(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
            break;
        case "triangle":
            signal = Triangle(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
            break;
        case "random":
            signal = Random(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
            break;
        case "alternate":
            signal = Alternate(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
            break;
        default:
            signal = Generator(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
            break;
        }
        self.storeSignal(fieldName: fieldName, signal: signal, isProto:isProto, order:order)
        return id;
    }
}



class BrushCollection:SignalCollection{
    
    required init(data:JSON){
        super.init(data:data);
        
    }
    
    
    
    /* override init(){
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
     }*/
    //TODO: INIT BRUSH PROPERTIES
   override public func initializeSignal(fieldName:String, displayName:String, settings:JSON, classType:String, isProto:Bool, order:Int?)->String{
        let id = NSUUID().uuidString
        let signal = Signal(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
    self.storeSignal(fieldName: fieldName, signal: signal, isProto:isProto, order:order)
        return id;
    }
}


class UICollection:SignalCollection{
    
    required init(data:JSON){
        super.init(data:data);
        
    }
    /*override init(){
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
     self.name = "stylus";
     
     }*/
    
    //TODO: INIT UI PROPERTIES
    override public func initializeSignal(fieldName:String, displayName:String, settings:JSON, classType:String, isProto:Bool, order:Int?)->String{
        let id = NSUUID().uuidString
        let signal = Signal(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        self.storeSignal(fieldName: fieldName, signal: signal, isProto:isProto, order:order)
        return id;
    }
}


class LiveCollection:SignalCollection{
    
    required init(data:JSON){
        super.init(data:data);
        
        
    }
    
    /* override init(){
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
     
     self.name = "stylus";
     }*/
    
    override public func initializeSignal(fieldName:String, displayName:String, settings:JSON, classType:String, isProto:Bool, order:Int?)->String{
        let id = NSUUID().uuidString
        let signal:Signal;
        if(fieldName == "StylusEvent"){
            signal = StylusEvent(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        }
        else{
            signal = LiveSignal(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        }
        self.storeSignal(fieldName: fieldName, signal: signal, isProto:isProto, order:order)
        return id;
    }
}

class RecordingCollection:LiveCollection{
    
    //stylus
    var next:RecordingCollection?
    var prev:RecordingCollection?
    var start:Date;
    var resultantStrokes = [String:[String]]();
    var targetLayer:String
    
    init(id:String,start:Date,targetLayer:String, data:JSON){
        self.start = start;
        self.targetLayer = targetLayer;
        super.init(data:data);
    }
    
    required init(data:JSON){
        self.start = Date();
        self.targetLayer = "nil"
        super.init(data:data);
        
    }
    
    
    override public func initializeSignal(fieldName:String, displayName:String, settings:JSON, classType:String, isProto:Bool, order:Int?)->String{
        let id = NSUUID().uuidString
        let signal:Signal;
        if(fieldName == "StylusEvent"){
            signal = StylusEventRecording(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        }
        else{
            signal = Recording(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, settings:settings);
        }
        self.storeSignal(fieldName: fieldName, signal: signal, isProto:isProto, order:order)
        return id;
    }
    
    override func getProtoSample(hash: Float) -> JSON? {
        var sample = super.getProtoSample(hash: hash);
        if(sample != nil){
            sample!["targetLayer"] = JSON(self.targetLayer);
            return sample;
        }
        return nil;
    }
    
    
    func store(next:RecordingCollection){
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
