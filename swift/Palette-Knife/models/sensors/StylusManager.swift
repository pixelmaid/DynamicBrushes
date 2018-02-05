//
//  StylusManager.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 1/30/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON

//feeds stylus live or pre-recorded data depending on state of system
final class StylusManager{
    
    static let stylusUp = Float(0.0);
    static let stylusMove = Float(1.0);
    static let stylusDown = Float(2.0);
    static private var isLive = true;
    static private var currentRecordingPackage:StylusRecordingPackage!
    static private var currentLoopingPackage:StylusRecordingPackage!
    static private var playbackTimer:Timer!
    //todo: get rid of this and use linked list structure
    static private var recordingPackages = [String:StylusRecordingPackage]()
    static var stylusManagerEvent = Event<(String,[String:[String]])>();
    static var layerId:String!
    static private var currentStartDate:Date!
    //producer consumer props
    static private let queue = DispatchQueue(label: "stylus-queue")
    static private var buffer: UInt = 0
    static private var size: UInt = 10000;
    static private var producer = StylusDataProducer()
    static private var consumer = StylusDataConsumer()
    
    
    
    init(){
        
    }
    
    static private func beginRecording(start:Date)->StylusRecordingPackage{
        let rPackage = StylusRecordingPackage(id: NSUUID().uuidString,start:start,layerId:StylusManager.layerId)
        recordingPackages[rPackage.id] = rPackage;
        
        if(currentRecordingPackage != nil){
            currentRecordingPackage.store(next: rPackage);
        }
        
        currentRecordingPackage = rPackage;
        return currentRecordingPackage;
        
    }
    
    static private func endRecording()->StylusRecordingPackage?{
        if(currentRecordingPackage != nil){
            currentRecordingPackage.endRecording();
            return currentRecordingPackage;
        }
        return nil
    }
    
    static func setToLastRecording(){
        setToRecording(idStart: currentRecordingPackage.id, idEnd: "foo")
    }
    
    static func liveStatus()->Bool{
        return self.isLive
    }
    
    static func setToLive(){
        self.isLive = true;
        if playbackTimer != nil {
            playbackTimer.invalidate()
            playbackTimer = nil
        }
        
    }
    
    static func setLayerId(layerId:String){
        StylusManager.layerId = layerId;
    }
    
    static func setToRecording(idStart:String,idEnd:String){
        self.isLive = false;
        currentLoopingPackage = recordingPackages[idStart];
        currentStartDate = Date();
        stylusManagerEvent.raise(data:("ERASE_REQUEST",currentLoopingPackage.resultantStrokes));
        
        playbackTimer = Timer.scheduledTimer(timeInterval: 1.0/1000.0, target: self, selector: #selector(advanceRecording), userInfo: nil, repeats: true)
        
    }
    
    @objc static func advanceRecording(){
        /*if buffer < size {*/
            buffer += 1
            let currentTime = Date();
            let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000))-1;
            
            let sample = producer.produce(hash: elapsedTime, recordingPackage: currentRecordingPackage)
        if(sample != nil){
            
            queue.async {
                self.consumer.consume(sample:sample!)
                self.buffer -= 1
                if(sample!.hash > sample!.lastHash){
                    stylusManagerEvent.raise(data:("ERASE_REQUEST",currentLoopingPackage.resultantStrokes));
                    currentStartDate = Date();
                }
            }
        }
            
            
        /*}*/
    }
    
    
    static func onStylusMove(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            let currentTime = Date();
            let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            
            let xLast = currentRecordingPackage.x.get(id:nil);
            let yLast = currentRecordingPackage.y.get(id:nil);
            let dx = x-xLast;
            let dy = y-yLast;
            
            currentRecordingPackage.addRecord(time:elapsedTime, dx: dx, dy: dy, x: x, y: y, force: force, angle: angle, stylusEvent: StylusManager.stylusMove)
            
            
            stylus.onStylusMove(x: x, y: y, force: force, angle: angle)
        }
    }
    
    static func onStylusUp(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            let currentTime = Date();
            let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            
            currentRecordingPackage.addRecord(time:elapsedTime, dx: 0, dy: 0, x: x, y: y, force: force, angle: angle,stylusEvent: StylusManager.stylusUp)
            _ = self.endRecording();
            stylus.onStylusUp();
            
        }
    }
    
    static func onStylusDown(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            currentStartDate = Date();
            let currentTime = Date();
            let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            let rPackage = beginRecording(start:currentStartDate);
            rPackage.addRecord(time:elapsedTime, dx: 0, dy: 0, x: x, y: y, force: force, angle: angle,stylusEvent: StylusManager.stylusDown)
            stylus.onStylusDown(x: x, y: y, force: force, angle: angle);
        }
    }
    static func addResultantStroke(layerId:String, strokeId:String){
        if(isLive){
            currentRecordingPackage.addResultantStroke(layerId: layerId, strokeId: strokeId);
        }
        else{
            currentLoopingPackage.addResultantStroke(layerId: layerId, strokeId: strokeId);
        }
    }
}


class StylusDataProducer{
    
    
    func produce(hash:Float,recordingPackage:StylusRecordingPackage)->Sample?{
        
        let sample = recordingPackage.getRecording(hash:hash);
       // print("sample found at time",hash);
        return sample;
    }
    
}


class StylusDataConsumer{
    
    func consume(sample:Sample){
        
        
        
        switch(sample.stylusEvent){
        case StylusManager.stylusUp:
            stylus.onStylusUp();
            break;
        case StylusManager.stylusDown:
            stylus.onStylusDown(x: sample.x, y: sample.y, force: sample.force, angle: sample.angle);
            break;
        case StylusManager.stylusMove:
            stylus.onStylusMove(x: sample.x, y: sample.y, force: sample.force, angle: sample.angle);
            break;
        default:
            break
        }
        
    }
}
    
    
    class StylusRecordingPackage{
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
        
        init(id:String,start:Date,layerId:String){
            self.id = id;
            dx = Recording(id: "dx_"+id);
            dy = Recording(id: "dy_"+id);
            x = Recording(id: "x_"+id);
            y = Recording(id: "y_"+id);
            force = Recording(id: "force_"+id);
            angle = Recording(id: "angle_"+id);
            stylusEvent = EventRecording(id: "events_"+id);
            self.start = start;
        }
        
        func addResultantStroke(layerId:String,strokeId:String){
            if(resultantStrokes[layerId] == nil){
                resultantStrokes[layerId] = [String]();
            }
            resultantStrokes[layerId]!.append(strokeId);
        }
        
        func removeResultantStrokes(){
            resultantStrokes.removeAll();
        }
        
        func addRecord(time:Float, dx:Float,dy:Float,x:Float,y:Float,force:Float,angle:Float,stylusEvent:Float){
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
        
        func getRecording(hash:Float)->Sample?{
            if(self.samples.contains(hash)){
                dx.setHash(h: hash);
                dy.setHash(h: hash);
                x.setHash(h: hash);
                y.setHash(h: hash);
                force.setHash(h: hash);
                angle.setHash(h: hash);
                stylusEvent.setHash(h: hash);
                
                let sample = Sample(dx: dx.get(id:nil), dy: dy.get(id:nil), x: x.get(id:nil), y: y.get(id:nil), force: force.get(id:nil), angle: angle.get(id:nil), stylusEvent: stylusEvent.get(id:nil),hash:hash,lastHash:self.lastSample)
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
            
        }
        
        
    }
    
    
    struct Sample{
        let dx:Float
        let dy:Float
        let x:Float
        let y:Float
        let stylusEvent:Float
        let force:Float
        let angle:Float
        let hash:Float
        let lastHash:Float
        
        init(dx:Float,dy:Float,x:Float,y:Float,force:Float,angle:Float,stylusEvent:Float, hash:Float, lastHash:Float){
            self.dx=dx;
            self.dy=dy;
            self.x=x;
            self.y=y;
            self.force=force;
            self.angle=angle;
            self.stylusEvent=stylusEvent;
            self.hash = hash;
            self.lastHash = lastHash;
        }
        
}
