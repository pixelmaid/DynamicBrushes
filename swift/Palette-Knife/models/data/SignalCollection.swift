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
//stores a collection of related signals e.g. a stylus recording, a data table
class SignalCollection: Object{
    //list of hashes for all samples
    internal var samples:Set<Float> = [];
    internal var lastSample:Float = 0;
    internal var signals  = [String:Signal]();
    public var id:String
    
    init(){
        self.id = NSUUID().uuidString;
    }
    
  /*  public  func loadDataFromJSON(data:JSON){
        
        let columns = data["meta"]["view"]["columns"].arrayValue;
        #if DEBUG
            //print("dataset loaded",columns,data)
        #endif
        let rawData = data["data"].arrayValue;
        
        for i in 0..<columns.count{
            var columnData = [Float]();
            for j in 0..< self.data!.count{
                let row = self.data![j].arrayValue;
                let v = row[i+metadataRowOffset].floatValue;
                columnData.append(v);
            }
            self.columnizedData.append(columnData);
            
            let fieldName = columns[i]["fieldName"].stringValue;
            let position = columns[i]["position"].intValue;
            let dataTypeName = columns[i]["dataTypeName"].stringValue;
            let description = columns[i]["description"].stringValue;
            //let largest = columns[i]["cachedContents"]["largest"].stringValue;
            // let smallest = columns[i]["cachedContents"]["smallest"].stringValue;
            // let width = columns[i]["width"].intValue;
            let id = columns[i]["id"].stringValue;
            let c:Column?
            if(dataTypeName == "meta_data"){
                metadataRowOffset+=1;
            }
            if(dataTypeName == "number"){
                
                let average = Float(columns[i]["cachedContents"]["average"].stringValue)
                c = NumberColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, data:columnData)
            }
                
            else if(dataTypeName == "date"){
                c = GeoColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, data:columnData)
            }
            else{
                c = TextColumn(table:self,id:id, fieldName: fieldName, position: position, dataTypeName: dataTypeName, data:columnData)
                
            }
            #if DEBUG
                //print("dataset fieldname",fieldName);
            #endif
            self.columns[fieldName] = c;
            
        }
        
        for i in 0..<columns.count{
            
        }
        
        #if DEBUG
            print("metadata offset",metadataRowOffset);
        #endif
    }*/
    
    
    public func addSignal(name:String,signal:Signal){
        signals[name] = signal;
        self[name] = signal;
    }
    
    public func removeSignal(name:String){
        if(self[name] != nil){
            self[name] = nil;
        }
        if (signals[name] != nil){
            signals.removeValue(forKey: name);
        }
    }
    
    public func addSample(hash:Float,data:JSON){
        self.samples.insert(hash)
        self.lastSample  = hash;
         for (key,value) in data {
           self.signals[key]?.pushValue(h: hash, v: value.floatValue)
        }
    }
    
    public func getSignalValue(key:String)->Float{
        let signal = self.signals[key];
        return signal!.get(id:nil);
    }
    
    public func getSample(hash:Float)->JSON?{
      
        if(self.samples.contains(hash)){
        
            var sample:JSON = [:]
            for (key,value) in signals{
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


class StylusRecordingCollection:SignalCollection{
   
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
        
        let dx = Recording(id: "dx_"+id);
        let dy = Recording(id: "dy_"+id);
        let x = Recording(id: "x_"+id);
        let y = Recording(id: "y_"+id);
        let force = Recording(id: "force_"+id);
        let angle = Recording(id: "angle_"+id);
        let stylusEvent = EventRecording(id: "events_"+id);
        self.addSignal(name:"dx",signal:dx);
        self.addSignal(name:"dy",signal:dy);
        self.addSignal(name:"x",signal:x);
        self.addSignal(name:"y",signal:y);
        self.addSignal(name:"force",signal:force);
        self.addSignal(name:"angle",signal:angle);
        self.addSignal(name:"stylusEvent",signal:stylusEvent);
    }
   
    override func getSample(hash: Float) -> JSON? {
        var sample = super.getSample(hash: hash);
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
                signals["stylusEvent"]!.setHash(h: hashValue);
                let sE =  signals["stylusEvent"]!.get(id:nil);
                
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
