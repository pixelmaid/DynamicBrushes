//
//  StylusManager.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 1/30/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON


class LiveManager{
    internal var liveCollections = [String:LiveCollection]();
    
    public func registerCollection(id:String, collection:LiveCollection){
        self.liveCollections[id] = collection;
    }
}

final class MicManager:LiveManager{
    public func setFrequency(val:Double) {
        for (_,micCollection) in self.liveCollections{
            (micCollection as! MicCollection).setFrequency(val: Float(val));
        }
    }
    public func setAmplitude(val:Double) {
        //        print("@ amp inside manager is ", val)
        
        for (_,micCollection) in self.liveCollections{
            (micCollection as! MicCollection).setAmplitude(val: Float(val));
        }
    }
}

final class UIManager:LiveManager{
    
    public func setDiameter(val:Float){
        for (_,uiCollection) in self.liveCollections{
            (uiCollection as! UICollection).setDiameter(val: val);
        }
    }
    
    public func setAlpha(val:Float){
        for (_,uiCollection) in self.liveCollections{
            (uiCollection as! UICollection).setAlpha(val: val);
        }
    }
    
    public func setColor(color:UIColor){
        for (_,uiCollection) in self.liveCollections{
            (uiCollection as! UICollection).setColor(color: color);
        }
        
    }
    
}


//feeds stylus live or pre-recorded data depending on state of system
final class StylusManager:LiveManager{
    
    static let stylusUp = Float(0.0);
    static let stylusMove = Float(1.0);
    static let stylusDown = Float(2.0);
    
    public var isLive = true;
    private var currentRecordingPackage:RecordingCollection!
    private var currentLoopingPackage:RecordingCollection!
    
    private var playbackTimer:Timer!
    //todo: get rid of this and use linked list structure
    private var recordingPackages = [RecordingCollection]()
    var layerId:String!
    private var currentStartDate:Date!
    //producer consumer props
    private let queue = DispatchQueue(label: "stylus-queue")
    private var producer = StylusDataProducer()
    private var consumer = StylusDataConsumer()
    private var samples = [JSON]();
    private var usedSamples = [JSON]();
    private var firstRecording:String!
    private var lastRecording:String!
    
    //events
    public let eraseEvent = Event<(String,[String:[String]])>();
    
    public let recordEvent = Event<(String,RecordingCollection)>();
    public let keyframeEvent = Event<(Int)>();
    
    public let layerEvent = Event<(String,String)>();
    public let stylusDataEvent = Event<(String, [Float])>();
    public let visualizationEvent = Event<String>();
    private var playbackMultiplier = 10;
    private var startTime:Date!
    private var prevTriggerTime:Date!
    private var prevHash:Float = 0;
    private var playbackRate:Float = 1;
    private var revertToLiveOnLoopEnd = false;
    private var idStart:String!
    private var idEnd:String!
    private var recordingPresetData:JSON = [:]
    
    private var currIndex = 0
    
    
    private func beginRecording(start:Date)->RecordingCollection{
        //TODO: find a way to clone recordingpresetdata instead of reassigning ID
        
        print("preset data",recordingPresetData)
        let rid = NSUUID().uuidString
        recordingPresetData["id"] = JSON(rid)
        let rPackage = RecordingCollection(id: rid,start:start,targetLayer:self.layerId,data:recordingPresetData)
        
        if(firstRecording == nil){
            firstRecording = rPackage.id;
        }
        lastRecording = rPackage.id;
        if (recordingPackages.count > 10) {
            //remove last
            recordingPackages.removeFirst(1)
            //todo i know it's not a layerevent but too lazy
            stylusManager.layerEvent.raise(data:("DELETE_FIRST",""));
            print("% deleting first")

        }
        recordingPackages.append(rPackage);
        print(" % appended to recording packages ", recordingPackages.count)
        
        currentRecordingPackage = rPackage;
        return currentRecordingPackage;
        
    }
    
    private func endRecording()->RecordingCollection?{
        if(currentRecordingPackage != nil){
            recordEvent.raise(data:("END_RECORDING",currentRecordingPackage));
            return currentRecordingPackage;
        }
        return nil
    }
    
    
    
    public func setRecordingPresetData(data:JSON){
        self.recordingPresetData = data;
    }
    
    
    public func liveStatus()->Bool{
        return self.isLive
    }
    
    public func setToLive(){
        revertToLiveOnLoopEnd = true;
    }
    
    
    
    public func setPlaybackRate(v:Float){
        playbackRate = v;
        
    }
    
    
    func getIndexandCurrentPackage(idStart:String) -> (index:Int, currPackage:RecordingCollection) {
        var currPackage:RecordingCollection = recordingPackages[0]
        var index:Int = 0
        for i in 0 ..< recordingPackages.count {
            let package = recordingPackages[i]
            print("%% looping thru i ", i , " package ", package)
            if package.id == idStart {
                print("%% setting internal to ", i , " recording packages has ", recordingPackages.count)
                index = i
                currPackage = package
                return (index, currPackage)
            }
        }
        return (index, currPackage)
    }
    
    
    
    public func setToRecording(idStart:String,idEnd:String){
        self.isLive = false;
        self.idStart = idStart;
        self.idEnd = idEnd;
        revertToLiveOnLoopEnd = false;
        currentStartDate = Date();
        let indexandpackage = getIndexandCurrentPackage(idStart: idStart)
        currIndex = indexandpackage.0
        currentLoopingPackage = indexandpackage.1
        //        currentLoopingPackage = recordingPackages.first(){$0.id == idStart} //set counter from here
        print("% starting in settorecording with i = ", currIndex , " start end ids are " , idStart, idEnd)
        prevHash = 0;
        do{
            let signalLength = try currentLoopingPackage.getSignalLength();
            
            queue.sync {
                var hashAdd:Float = 0;
                while (true){
                    // print("====advance recording start====",currentLoopingPackage.id,currentLoopingPackage.signals["dx"]!.signalBuffer.count);
                    
                    for i in 0..<signalLength{
                        var sample = producer.produce(index:i, recordingPackage: currentLoopingPackage);
                        if sample != nil{
                            sample!["sequenceHash"] = JSON(sample!["hash"].floatValue+hashAdd);
                            samples.append(sample!);
                            print("advance recording", i,samples.count);
                            
                        }
                    }
                    print("====advance recording break====");
                    //prevTime = elapsedTime;
                    if(currentLoopingPackage.id == self.idEnd){
                        print("% stopping in settorecording with i = ", currIndex)
                        
                        samples[samples.count-1]["isLastinRecording"] = JSON(true);
                        currIndex = 0
                        break;
                        
                    }
                    else{
                        samples[samples.count-1]["isLastInSeries"] = JSON(true);
                        hashAdd = samples[samples.count-1]["sequenceHash"].floatValue;
                        currIndex += 1
                        currentLoopingPackage = recordingPackages[currIndex]; //go to next index
                        print(" % going to next index in settorecording with i = ", currIndex)
                        
                    }
                }
                print("samples",samples);
            }
        }
        catch{
            return;
        }
        
        
        delayTimerReinit();
        
    }
    
    
    
    private func killLiveMode(){
        self.isLive = true;
        self.idStart = nil;
        self.idEnd = nil;
        killLoopTimer(delayRestart: false);
        samples.removeAll();
        usedSamples.removeAll();
        currentLoopingPackage = nil;
        self.visualizationEvent.raise(data:"RECORD_IMG_ON")
        self.visualizationEvent.raise(data:"DESELECT_LAST")
        
    }
    
    
    private func killLoopTimer(delayRestart:Bool){
        if playbackTimer != nil {
            playbackTimer.invalidate()
            playbackTimer = nil
        }
        if(delayRestart){
            playbackTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(delayTimerReinit), userInfo: nil, repeats: false)
        }
        else{
            self.visualizationEvent.raise(data:"ERASE_REQUEST")
        }
    }
    
    @objc private func delayTimerReinit(){
        if(playbackTimer != nil){
            playbackTimer.invalidate()
            playbackTimer = nil
        }
        startTime = Date();
        prevTriggerTime = startTime;
        var strokesToErase = [String:[String]]();
        currentLoopingPackage = recordingPackages.first(){$0.id == self.idStart}
        while (true){
            for (key,list) in currentLoopingPackage.resultantStrokes{
                if(strokesToErase[key] == nil){
                    strokesToErase[key] = [String]();
                }
                strokesToErase[key]?.append(contentsOf: list);
            }
            currentLoopingPackage.removeResultantStrokes();
            if(currentLoopingPackage.id == self.idEnd){
                currIndex = 0
                break;
            }
            else{
                currIndex += 1
                currentLoopingPackage = recordingPackages[currIndex];
                
            }
        }
        
        eraseEvent.raise(data:("ERASE_REQUEST",strokesToErase));
        self.visualizationEvent.raise(data:"ERASE_REQUEST")
        
        playbackTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(advanceRecording), userInfo: nil, repeats: true)
        
    }
    
    @objc private func advanceRecording(){
        
        
        queue.sync {
//            print("total num samples",samples.count)
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
                    
                    if(samples[0]["sequenceHash"].floatValue == timeDifferenceCounter+prevHash){
                        
                        let currentSample = samples.remove(at: 0);
                        if(currentSample["hash"].floatValue == Float(0)){
                            currentLoopingPackage = recordingPackages.first(){$0.id == currentSample["recordingId"].stringValue};
                        }
//                        print("sample hash",currentSample["hash"].stringValue);
                        self.consumer.consume(liveManager:self, sample:currentSample);
                        
                        // print(currentSample.stylusEvent,"sample hash, last hash",currentSample.hash,currentSample.lastHash)
                        usedSamples.append(currentSample);
                        if(currentSample["isLastinRecording"].boolValue){
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
    
    
    //TOOD: NEED TO MAKE THESE SYMMETRICAL TO STYLUSCOLLECTION EVENTS TO CALCULATE ACCURATE DATA
    public func onStylusMove(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            //let currentTime = Date();
            //let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            
            
            for (_,stylusCollection) in self.liveCollections{
                
                (stylusCollection as! StylusCollection).onStylusMove(x: x, y: y, force: force, angle: angle)
            }
            let sample = self.liveCollections["stylus"]!.exportData();
            currentRecordingPackage.addProtoSample(data:sample);
        }
    }
    
    public func onStylusUp(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            //let currentTime = Date();
            //let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            
            for (_,stylusCollection) in self.liveCollections{
                (stylusCollection as! StylusCollection).onStylusUp(x: x, y:y);
            }
            let sample = self.liveCollections["stylus"]!.exportData();
            currentRecordingPackage.addProtoSample(data:sample);
            _ = self.endRecording();
            
        }
    }
    
    public func onStylusDown(x:Float,y:Float,force:Float,angle:Float){
        if(isLive){
            currentStartDate = Date();
            //let currentTime = Date();
            //let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            _ = beginRecording(start:currentStartDate);
            
            
            for (_,stylusCollection) in self.liveCollections{
                (stylusCollection as! StylusCollection).onStylusDown(x: x, y: y, force: force, angle: angle);
            }
            //TODO: add guard statement here
            let sample = self.liveCollections["stylus"]!.exportData();
            //print("stylus down sample",sample);
            currentRecordingPackage.addProtoSample(data:sample);
            
        }
    }
    public func addResultantStroke(layerId:String, strokeId:String){
        if(isLive){
            if(currentRecordingPackage != nil){
                currentRecordingPackage.addResultantStroke(layerId: layerId, strokeId: strokeId);
            }
            else{
                print("==============WARNING CANNOT ADD RESULTANT STROKE, NO RECORDING PACKAGE INIT=====================");
            }
            
        }
        else{
            currentLoopingPackage.addResultantStroke(layerId: layerId, strokeId: strokeId);
        }
    }
    
    public func setLayerId(layerId:String){
        self.layerId = layerId;
    }
    
    public func  handleDeletedLayer(deletedId: String){
        if(firstRecording != nil){
            let indexandpackage = getIndexandCurrentPackage(idStart: firstRecording)
            var index = indexandpackage.0
            var targetRecordingPackage = indexandpackage.1
            
            //            var targetRecordingPackage = recordingPackages.first(){$0.id == firstRecording}
            while(true){
                if(targetRecordingPackage.targetLayer == layerId ){
                    let filteredPackages = recordingPackages.filter{$0.id == targetRecordingPackage.id}
                    recordingPackages = filteredPackages;
                    index += 1
                    if (index > recordingPackages.count) {
                        targetRecordingPackage = recordingPackages[index]
                    }
                    else{
                        break;
                    }
                    
                    
                    //                    if(targetRecordingPackage.prev != nil){
                    //                        targetRecordingPackage.prev!.next = targetRecordingPackage!.next;
                    //                    }
                    //                    if(targetRecordingPackage.next != nil){
                    //                        targetRecordingPackage.next!.prev = targetRecordingPackage.prev;
                    //                        targetRecordingPackage = targetRecordingPackage!.next
                    //                    }
                    
                }
            }
            
        }
    }
    
    public func exportRecording(startId:String, endId:String)->JSON?{
        let compiledId = NSUUID().uuidString;
        print("id start / startid is % ", idStart, startId)
        let indexandpackage = getIndexandCurrentPackage(idStart: startId)
        var exportIndex = indexandpackage.0
        let startRecordingCollection = indexandpackage.1
        recordingPresetData["id"] = JSON(compiledId)
        print("recordingPresetData is % " , self.recordingPresetData)
        let compiledRecordingCollection = ImportedRecordingCollection(data:self.recordingPresetData)
        
        var targetRecordingCollection = startRecordingCollection;
        while(true){
            compiledRecordingCollection.addDataFrom(signalCollection:targetRecordingCollection);
            
            if(targetRecordingCollection.id == endId || exportIndex == recordingPackages.count){
                break
            }
            else{
                exportIndex += 1
                targetRecordingCollection = recordingPackages[exportIndex]
            }
            
        }
        return compiledRecordingCollection.protoToJSON();
    }
    
    
    
}


class StylusDataProducer{
    
    
    func produce(index:Int,recordingPackage:RecordingCollection)->JSON?{
        
        let sample = recordingPackage.getProtoSample(index:index);
        return sample;
    }
    
}


class StylusDataConsumer{
    
    func consume(liveManager:LiveManager, sample:JSON){
       // print("consume sample",sample["stylusEvent"].floatValue, sample["x"].floatValue,sample["y"].floatValue,sample["force"].floatValue,sample["targetLayer"].stringValue)
        let stylusManager = liveManager as! StylusManager;
        switch(sample["stylusEvent"].floatValue){
        case StylusManager.stylusUp:
            for (_,stylusCollection) in liveManager.liveCollections{
                (stylusCollection as! StylusCollection).onStylusUp(x: sample["x"].floatValue, y: sample["y"].floatValue);
            }
            stylusManager.stylusDataEvent.raise(data:("STYLUS_UP", [sample["x"].floatValue, sample["y"].floatValue]))
            break;
        case StylusManager.stylusDown:
            stylusManager.stylusDataEvent.raise(data:("STYLUS_DOWN", [sample["x"].floatValue, sample["y"].floatValue]))
            stylusManager.layerEvent.raise(data:("REQUEST_CORRECT_LAYER",sample["targetLayer"].stringValue));
            
            for (_,stylusCollection) in stylusManager.liveCollections{
                (stylusCollection as! StylusCollection).onStylusDown(x: sample["x"].floatValue, y: sample["y"].floatValue, force: sample["force"].floatValue, angle: sample["angle"].floatValue);
            }
            
            stylusManager.visualizationEvent.raise(data:"ADVANCE_KEYFRAME")
            break;
        case StylusManager.stylusMove:
            stylusManager.stylusDataEvent.raise(data:("STYLUS_MOVE", [sample["x"].floatValue, sample["y"].floatValue]))
            for (_,stylusCollection) in stylusManager.liveCollections{
                (stylusCollection as! StylusCollection).onStylusMove(x: sample["x"].floatValue, y: sample["y"].floatValue, force: sample["force"].floatValue, angle: sample["angle"].floatValue);
            }
            break;
        default:
            break
        }
        
    }
}





