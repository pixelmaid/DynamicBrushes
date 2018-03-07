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
    static var layerId:String!
    static private var currentStartDate:Date!
    //producer consumer props
    static private let queue = DispatchQueue(label: "stylus-queue")
    static private var producer = StylusDataProducer()
    static private var consumer = StylusDataConsumer()
    static private var samples = [Sample]();
    static private var usedSamples = [Sample]();
    static private var firstRecording:String!
    static private var lastRecording:String!

    //events
    static public let eraseEvent = Event<(String,[String:[String]])>();
    static public let recordEvent = Event<(String,StylusRecordingPackage)>();
    static public let layerEvent = Event<(String,String)>();
    static public let stylusDataEvent = Event<(String, [Float])>();
    static public let visualizationEvent = Event<String>();
    static private var playbackMultiplier = 10;
    static private var startTime:Date!
    static private var prevTriggerTime:Date!
    static private var prevHash:Float = 0;
    static private var playbackRate:Float = 1;
    static private var revertToLiveOnLoopEnd = false;
    static private var idStart:String!
    static private var idEnd:String!

    
    init(){
        
    }
    
    
    
    static private func beginRecording(start:Date)->StylusRecordingPackage{
        
        let rPackage = StylusRecordingPackage(id: NSUUID().uuidString,start:start,targetLayer:StylusManager.layerId)
        if(firstRecording == nil){
            firstRecording = rPackage.id;
        }
        lastRecording = rPackage.id;
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
            recordEvent.raise(data:("END_RECORDING",currentRecordingPackage));
            return currentRecordingPackage;
        }
        return nil
    }
    

    
    static public func liveStatus()->Bool{
        return self.isLive
    }
    
    static public func setToLive(){
        revertToLiveOnLoopEnd = true;
    }
    
   
    
    static public func setPlaybackRate(v:Float){
        playbackRate = v;
        
    }
    

    static public func eraseStrokesForLooping(idStart:String,idEnd:String) {
        //jl - TODO write code that only erases the strokes between idStart and idEnd
        //jl - i changed the args to be an idStart and idEnd, same as setToRecording, since we would only ever temporarily erase the strokes we are concerned with in the looping
        
    }


    
    static public func setToRecording(idStart:String,idEnd:String){
        self.isLive = false;
        self.idStart = idStart;
        self.idEnd = idEnd;
        revertToLiveOnLoopEnd = false;
        currentStartDate = Date();
        currentLoopingPackage = recordingPackages[self.idStart];
        prevHash = 0;
        queue.sync {
            var hashAdd:Float = 0;
            while (true){
                print("====advance recording start====",currentLoopingPackage.id,currentLoopingPackage.dx.signalBuffer.count);
            for i in 0..<Int(currentLoopingPackage.lastSample+1){
                let hash = i;
                var sample = producer.produce(hash: Float(hash), recordingPackage: currentLoopingPackage);
                if sample != nil{
                    sample!.sequenceHash = sample!.hash+hashAdd;
                    samples.append(sample!);
                    print("advance recording", hash,samples.count);
                    
                }
            }
            print("====advance recording break====");
            //prevTime = elapsedTime;
                if(currentLoopingPackage.id == self.idEnd){
                    samples[samples.count-1].isLastinRecording = true;
                    break;

                }
                else{
                    samples[samples.count-1].isLastInSeries = true;
                    hashAdd = samples[samples.count-1].sequenceHash;
                    currentLoopingPackage = currentLoopingPackage.next;
                }
            }
        }
      
        //jl - TODO - delete bottom line? (eraseStrokesForLooping called now in recording controller)

        delayTimerReinit();
        
    }
    
    
   
    static private func killLiveMode(){
        self.isLive = true;
        self.idStart = nil;
        self.idEnd = nil;
        killLoopTimer(delayRestart: false);
        samples.removeAll();
        usedSamples.removeAll();
        currentLoopingPackage = nil;
    }
    
    
    static private func killLoopTimer(delayRestart:Bool){
        if playbackTimer != nil {
            playbackTimer.invalidate()
            playbackTimer = nil
        }
        if(delayRestart){
            playbackTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(delayTimerReinit), userInfo: nil, repeats: false)
        }
        else{
            StylusManager.visualizationEvent.raise(data:"ERASE_REQUEST")

        }
    }
    
    @objc static private func delayTimerReinit(){
        if(playbackTimer != nil){
            playbackTimer.invalidate()
            playbackTimer = nil
        }
        startTime = Date();
        prevTriggerTime = startTime;
        var strokesToErase = [String:[String]]();
        currentLoopingPackage = recordingPackages[self.idStart];
        while (true){
            for (key,list) in currentLoopingPackage.resultantStrokes{
                if(strokesToErase[key] == nil){
                    strokesToErase[key] = [String]();
                }
                strokesToErase[key]?.append(contentsOf: list);
            }
                currentLoopingPackage.removeResultantStrokes();
                if(currentLoopingPackage.id == self.idEnd){
                    break;
                }
                else{
                    currentLoopingPackage = currentLoopingPackage.next;
                }
            }
        
        eraseEvent.raise(data:("ERASE_REQUEST",strokesToErase));
        StylusManager.visualizationEvent.raise(data:"ERASE_REQUEST")

        playbackTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(advanceRecording), userInfo: nil, repeats: true)

    }
    
    @objc static private func advanceRecording(){
      
        
        queue.sync {
        print("total num samples",samples.count)
        let currentTime = Date();
        let elapsedTime = currentTime.timeIntervalSince(prevTriggerTime);
     
        var timeDifferenceCounter = Float(0);
        let timeDifferenceMS:Float;
        
        if(playbackRate >= 10.0){
            timeDifferenceMS = Float(samples.count);
            killLoopTimer(delayRestart: false);

        }
            
        else{
            timeDifferenceMS = Float(elapsedTime)*1000*playbackRate;

        }
        
        while timeDifferenceCounter<timeDifferenceMS{
                
                if(samples.count>0){
                    
                    if(samples[0].sequenceHash == timeDifferenceCounter+prevHash){
                       
                        let currentSample = samples.remove(at: 0);
                        if(currentSample.hash == Float(0)){
                            currentLoopingPackage = recordingPackages[currentSample.recordingId];
                        }
                        print("sample hash",currentSample.hash);
                        self.consumer.consume(sample:currentSample);
                        
                        print(currentSample.stylusEvent,"sample hash, last hash",currentSample.hash,currentSample.lastHash)
                        usedSamples.append(currentSample);
                            if(currentSample.isLastinRecording){
                                samples.append(contentsOf:usedSamples);
                                usedSamples.removeAll();
                                prevHash = 0;

                                if(revertToLiveOnLoopEnd == true){
                                    killLiveMode();
                                }
                                else if(playbackRate<10.0){
                                    killLoopTimer(delayRestart:true);

                                }
                                
                                break;
                                
                            }
                    }
                    timeDifferenceCounter += 1;

                }
            }
            
        }
    }
    
   
    
    static public func onStylusMove(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            let currentTime = Date();
            let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            
            let xLast = currentRecordingPackage.x.get(id:nil);
            let yLast = currentRecordingPackage.y.get(id:nil);
            let dx = x-xLast;
            let dy = y-yLast;
            
            currentRecordingPackage.addSample(time:elapsedTime, dx: dx, dy: dy, x: x, y: y, force: force, angle: angle, stylusEvent: StylusManager.stylusMove)
            
            
            stylus.onStylusMove(x: x, y: y, force: force, angle: angle)
        }
    }
    
    static public func onStylusUp(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            let currentTime = Date();
            let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            
            currentRecordingPackage.addSample(time:elapsedTime, dx: 0, dy: 0, x: x, y: y, force: force, angle: angle,stylusEvent: StylusManager.stylusUp)
            _ = self.endRecording();
            stylus.onStylusUp();
            
        }
    }
    
    static public func onStylusDown(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            currentStartDate = Date();
            let currentTime = Date();
            let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            let rPackage = beginRecording(start:currentStartDate);
            rPackage.addSample(time:elapsedTime, dx: 0, dy: 0, x: x, y: y, force: force, angle: angle,stylusEvent: StylusManager.stylusDown)
            stylus.onStylusDown(x: x, y: y, force: force, angle: angle);
        }
    }
    static public func addResultantStroke(layerId:String, strokeId:String){
        if(isLive){
            currentRecordingPackage.addResultantStroke(layerId: layerId, strokeId: strokeId);
        }
        else{
            currentLoopingPackage.addResultantStroke(layerId: layerId, strokeId: strokeId);
        }
    }
    
    static public func setLayerId(layerId:String){
        StylusManager.layerId = layerId;
    }
    
    static public func  handleDeletedLayer(deletedId: String){
        if(firstRecording != nil){
            var targetRecordingPackage = recordingPackages[firstRecording]
            while(true){
                if(targetRecordingPackage!.targetLayer == layerId ){
                    recordingPackages.removeValue(forKey:targetRecordingPackage!.id);

                    
                    if(targetRecordingPackage!.prev != nil){
                        targetRecordingPackage!.prev!.next = targetRecordingPackage!.next;
                    }
                    if(targetRecordingPackage!.next != nil){
                        targetRecordingPackage!.next!.prev = targetRecordingPackage!.prev;
                        targetRecordingPackage = targetRecordingPackage!.next
                    }
                    else{
                        break;
                    }
                    
                }
            }
            
        }
    }
   
}


class StylusDataProducer{
    
    
    func produce(hash:Float,recordingPackage:StylusRecordingPackage)->Sample?{
     
        let sample = recordingPackage.getSample(hash:hash);
       // print("sample found at time",hash);
        return sample;
    }
    
}


class StylusDataConsumer{
    
    func consume(sample:Sample){
        
        
        switch(sample.stylusEvent){
        case StylusManager.stylusUp:
            stylus.onStylusUp();
            StylusManager.stylusDataEvent.raise(data:("STYLUS_UP", [sample.x, sample.y]))
            break;
        case StylusManager.stylusDown:
            StylusManager.stylusDataEvent.raise(data:("STYLUS_DOWN", [sample.x, sample.y]))
            StylusManager.layerEvent.raise(data:("REQUEST_CORRECT_LAYER",sample.targetLayer));
            stylus.onStylusDown(x: sample.x, y: sample.y, force: sample.force, angle: sample.angle);
            break;
        case StylusManager.stylusMove:
            StylusManager.stylusDataEvent.raise(data:("STYLUS_MOVE", [sample.x, sample.y]))
            stylus.onStylusMove(x: sample.x, y: sample.y, force: sample.force, angle: sample.angle);
            break;
        default:
            break
        }
        
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
        var sequenceHash:Float = 0;
        let targetLayer:String
        var isLastinRecording:Bool = false;
        var isLastInSeries:Bool = false;
        var recordingId:String;
        init(dx:Float,dy:Float,x:Float,y:Float,force:Float,angle:Float,targetLayer:String,stylusEvent:Float, hash:Float, lastHash:Float, recordingId:String){
            self.dx=dx;
            self.dy=dy;
            self.x=x;
            self.y=y;
            self.force=force;
            self.angle=angle;
            self.stylusEvent=stylusEvent;
            self.targetLayer = targetLayer;
            self.hash = hash;
            self.lastHash = lastHash;
            self.recordingId = recordingId;
        }
        
}
