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
    private var samples:Set<Float> = [];
    private var lastSample:Float = 0;
    private var signals  = [String:Signal]();
    private var id:String
    
    init(){
        self.id = NSUUID().uuidString;
    }
    
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
    
    public func getSample(hash:Float)->JSON?{
      
        if(self.samples.contains(hash)){
        
            var sample:JSON = [:]
            for (key,value) in signals{
                value.setHash(h:hash);
                sample[key] = JSON(value.get(id:nil));
            }
            return sample;
        }
        return nil;
    }
    
}


class StylusRecordingPackage:Signal{
    var dx:Recording;
    var dy:Recording;
    var x:Recording;
    var y:Recording;
    var stylusEvent:EventRecording;
    var force:Recording;
    var angle:Recording;
    var id:String;
    var next:StylusRecordingPackage?
    var prev:StylusRecordingPackage?
    var samples:Set<Float> = [];
    var lastSample:Float = 0;
    var start:Date;
    var resultantStrokes = [String:[String]]();
    var targetLayer:String
    init(id:String,start:Date,targetLayer:String){
        self.id = id;
        dx = Recording(id: "dx_"+id);
        dy = Recording(id: "dy_"+id);
        x = Recording(id: "x_"+id);
        y = Recording(id: "y_"+id);
        force = Recording(id: "force_"+id);
        angle = Recording(id: "angle_"+id);
        stylusEvent = EventRecording(id: "events_"+id);
        self.start = start;
        self.targetLayer = targetLayer;
    }
    
    
    
    func addSample(time:Float, dx:Float,dy:Float,x:Float,y:Float,force:Float,angle:Float,stylusEvent:Float){
        self.dx.pushValue(h: time, v: dx);
        self.dy.pushValue(h: time, v: dy);
        self.x.pushValue(h: time, v: x);
        self.y.pushValue(h: time, v: y);
        self.force.pushValue(h: time, v: force);
        self.angle.pushValue(h: time, v: angle);
        self.stylusEvent.pushValue(h: time, v: stylusEvent)
        self.samples.insert(time);
        lastSample = time;
        
    }
    
    func getSample(hash:Float)->Sample?{
        if(self.samples.contains(hash)){
            dx.setHash(h: hash);
            dy.setHash(h: hash);
            x.setHash(h: hash);
            y.setHash(h: hash);
            force.setHash(h: hash);
            angle.setHash(h: hash);
            stylusEvent.setHash(h: hash);
            
            let sample = Sample(dx: dx.get(id:nil), dy: dy.get(id:nil), x: x.get(id:nil), y: y.get(id:nil), force: force.get(id:nil), angle: angle.get(id:nil), targetLayer:self.targetLayer, stylusEvent: stylusEvent.get(id:nil),hash:hash,lastHash:self.lastSample,recordingId:self.id)
            return sample;
        }
        return nil;
    }
    
    
    
    func store(next:StylusRecordingPackage){
        self.next = next;
        next.prev = self;
        self.dx.setNext(r: next.dx);
        self.dy.setNext(r: next.dy);
        self.x.setNext(r: next.x);
        self.y.setNext(r: next.x);
        self.force.setNext(r: next.force);
        self.angle.setNext(r: next.angle);
        
        next.dx.setPrev(r: self.dx);
        next.dy.setPrev(r: self.dy);
        next.x.setPrev(r: self.x);
        next.y.setPrev(r: self.x);
        next.force.setPrev(r: self.force);
        next.angle.setPrev(r: self.angle);
        
        
    }
    
    func endRecording(){
        var sampleList = [Float:Float]();
        var hashValue:Float  = 0;
        while(hashValue <= self.lastSample){
            if(self.samples.contains(hashValue)){
                stylusEvent.setHash(h: hashValue);
                let sE = stylusEvent.get(id:nil);
                
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
