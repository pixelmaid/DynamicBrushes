//
// LiveManager.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 1/30/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON


protocol SignalCollectionManager{
    var collections:[String:SignalCollection] { get set }
    
    func registerCollection(collectionData:JSON)->(id:String,collection:SignalCollection?);
}
    
class LiveManager{
    
    
}

final class MicManager:LiveManager, SignalCollectionManager{
    var collections: [String : SignalCollection] =  [String : LiveCollection]();

    func registerCollection(collectionData: JSON)->(id:String,collection:SignalCollection?){
        let id = collectionData["id"].stringValue;
        if(collections[id]==nil){
            let signalCollection = MicCollection(data:collectionData);
            collections[id] = signalCollection;
            return(id:id,collection:signalCollection);
        }
        else{
            collections[id]?.initializeSignalInstancesFromJSON(data:collectionData);
            return(id:id,collection:nil);

        }

    }
    

    public func setFrequency(val:Double) {
        for (_,micCollection) in self.collections{
            (micCollection as! MicCollection).setFrequency(val: Float(val));
        }
    }
    public func setAmplitude(val:Double) {
        //        print("@ amp inside manager is ", val)
        
        for (_,micCollection) in self.collections{
            (micCollection as! MicCollection).setAmplitude(val: Float(val));
        }
    }
}

final class UIManager:LiveManager{
    var collections: [String : SignalCollection] =  [String : UICollection]();
    
    func registerCollection(collectionData: JSON)->(id:String,collection:SignalCollection?) {
        let id = collectionData["id"].stringValue;
        if(collections[id]==nil){
            let signalCollection = UICollection(data:collectionData);
            collections[id] = signalCollection;
            return(id:id,collection:signalCollection);

        }
        else{
            collections[id]?.initializeSignalInstancesFromJSON(data:collectionData);
            return(id:id,collection:nil);

        }
        
    }
    
    public func setDiameter(val:Float){
        for (_,uiCollection) in self.collections{
            (uiCollection as! UICollection).setDiameter(val: val);
        }
    }
    
    public func setAlpha(val:Float){
        for (_,uiCollection) in self.collections{
            (uiCollection as! UICollection).setAlpha(val: val);
        }
    }
    
    public func setColor(color:UIColor){
        for (_,uiCollection) in self.collections{
            (uiCollection as! UICollection).setColor(color: color);
        }
        
    }
    
}


//feeds stylus live or pre-recorded data depending on state of system
final class StylusManager:LiveManager{
    
    static let stylusUp = Float(0.0);
    static let stylusMove = Float(1.0);
    static let stylusDown = Float(2.0);
    static var globalTime = Int(0);
    
    public var isLive = true;
    public var isStepping = false;
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
    private var recordingLoopCount:Int = 0;
    //events
    public let eraseEvent = Event<(String,[String:[String]])>();
    
    public let recordEvent = Event<(String,RecordingCollection)>();
    public let keyframeEvent = Event<(Int)>();
    public let layerEvent = Event<(String,String)>();
    public let stylusDataEvent = Event<(String, [Float])>();
    public let visualizationEvent = Event<String>();
    private var playbackMultiplier = 10;
    private var prevHash:Float = 0;
    private var playbackRate:Float = 1;
    private var revertToLiveOnLoopEnd = false;
    private var idStart:String!
    private var idEnd:String!
    private var recordingPresetData:JSON = [:]
    private let recordingLimit = 6;
    private var currIndex = 0
    private var moveCounter = 0;
    private var moveThreshold = 4;
    
    
    var collections: [String : SignalCollection] =  [String : StylusCollection]();
    
    public func registerCollection(collectionData: JSON)->(id:String,collection:SignalCollection?) {
        let id = collectionData["id"].stringValue;
        if(collections[id]==nil){
            let signalCollection = StylusCollection(data:collectionData);
            collections[id] = signalCollection;
            return(id:id,collection:signalCollection);

        }
        else{
            collections[id]?.initializeSignalInstancesFromJSON(data:collectionData);
            return(id:id,collection:nil);

        }
        
    }
    
    private func beginRecording(start:Date)->RecordingCollection{
        //TODO: find a way to clone recordingpresetdata instead of reassigning ID
        
        let rid = NSUUID().uuidString
        recordingPresetData["id"] = JSON(rid)
        let rPackage = RecordingCollection(id: rid,start:start,targetLayer:self.layerId,data:recordingPresetData)
        
        if(firstRecording == nil){
            firstRecording = rPackage.id;
        }
        lastRecording = rPackage.id;
        if (recordingPackages.count >= self.recordingLimit) {
            //remove last
            recordingPackages.removeFirst(1)
            //todo i know it's not a layerevent but too lazy
            stylusManager.layerEvent.raise(data:("DELETE_FIRST",""));

        }
        recordingPackages.append(rPackage);
        
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
    
   
    
    
    public func setPlaybackRate(v:Float){
        playbackRate = v;
        
    }
    
    
    func getIndexandCurrentPackage(idStart:String) -> (index:Int, currPackage:RecordingCollection) {
        var currPackage:RecordingCollection = recordingPackages[0]
        var index:Int = 0
        for i in 0 ..< recordingPackages.count {
            let package = recordingPackages[i]
            if package.id == idStart {
                index = i
                currPackage = package
                return (index, currPackage)
            }
        }
        return (index, currPackage)
    }
    
    
    public func initializeStepping(){
        if(self.recordingPackages.count>0){
            self.prepareDataToLoop(idStart: self.recordingPackages.last!.id, idEnd: self.recordingPackages.last!.id, startTimer: false);
            self.isStepping = true;
        }
    }
    
    public func deinitializeStepping(){
        self.isStepping = false;
        self.resumeLiveMode();
    }
    
    public func prepareDataToLoop(idStart:String,idEnd:String, startTimer:Bool){
        Debugger.setupResetInspectionRequest();
        self.isLive = false;
        self.idStart = idStart;
        self.idEnd = idEnd;
        revertToLiveOnLoopEnd = false;
        Debugger.resetDebugStatus();
        self.recordingLoopCount = 0;
        currentStartDate = Date();
        let indexandpackage = getIndexandCurrentPackage(idStart: idStart)
        currIndex = indexandpackage.0
        currentLoopingPackage = indexandpackage.1
        //        currentLoopingPackage = recordingPackages.first(){$0.id == idStart} //set counter from here
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
                           
                            
                        }
                    }
                  
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
                        
                    }
                }
                print("samples",samples);
            }
        }
        catch{
            return;
        }
        
        prepStepData();
        if(startTimer){
            startLoopTimer();
        }
    }
    
    public func restartLoop(){
        if(!self.isLive){
            self.stopLoopTimer();
            self.clearCachedData()
            samples.removeAll();
            currentLoopingPackage = nil;
            self.prepareDataToLoop(idStart: self.idStart, idEnd: self.idEnd, startTimer: true);
            self.startLoopTimer();
        }

    }
    
    
    
    private func resumeLiveMode(){
        self.isLive = true;
        self.idStart = nil;
        self.idEnd = nil;
        samples.removeAll();
        usedSamples.removeAll();
        currentLoopingPackage = nil;
        self.visualizationEvent.raise(data:"ERASE_REQUEST")
        Debugger.resetDebugStatus();
        Debugger.setupResetInspectionRequest();
        
    }
    
    
    
    public func terminateLoopAndResumeLive(){
      
        revertToLiveOnLoopEnd = true;
        
        
    }
    
    private func clearCachedData(){
        usedSamples.removeAll();
        prevHash = 0;
    }
    
    private func stopLoopTimer(){
        if(playbackTimer != nil){
            playbackTimer.invalidate()
            playbackTimer = nil
        }
    }
    
    private func startLoopTimer(){
        self.stopLoopTimer();
        
      
        playbackTimer = Timer.scheduledTimer(timeInterval: TimeInterval(0.005/playbackRate), target: self, selector: #selector(advanceRecording), userInfo: nil, repeats: false)

        
    }
    
    
    @objc private func advanceRecording(){
        
        
        queue.sync {
        
            stepSample();
        }
    }

  
    
    
    func prepStepData(){
        self.recordingLoopCount+=1;
        print("recording Loop count",self.recordingLoopCount);
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
    }
    
    
    func stepSample(){
        if(samples.count>0){
            
            let currentSample = samples.remove(at: 0);
            if(currentSample["hash"].floatValue == Float(0)){
                currentLoopingPackage = recordingPackages.first(){$0.id == currentSample["recordingId"].stringValue};
            }
            self.consumer.consume(liveManager:self, sample:currentSample);
            
            usedSamples.append(currentSample);
            if(currentSample["isLastinRecording"].boolValue){
                if(self.revertToLiveOnLoopEnd){
                    
                    self.clearCachedData()
                    self.stopLoopTimer();
                    self.resumeLiveMode();
                }
                else{
                    samples.append(contentsOf:usedSamples);
                    usedSamples.removeAll();
                    prevHash = 0;
                    prepStepData();
                }
                
            }
                
             if(self.isLive == false && self.isStepping == false){
                self.startLoopTimer();
            }
        }
        
        
    }
    
  
  
    
    
    
    //TOOD: NEED TO MAKE THESE SYMMETRICAL TO STYLUSCOLLECTION EVENTS TO CALCULATE ACCURATE DATA
    public func onStylusMove(x:Float,y:Float,force:Float,angle:Float){
        guard self.collections["stylus"] != nil else{
            return
        }
        if(isLive){
            if(self.moveCounter >= self.moveThreshold){
            //let currentTime = Date();
            //let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            
            
            
                
        
                let sample = (self.collections["stylus"]! as! StylusCollection).onStylusMove(x: x, y: y, force: force*20, angle: angle);
            currentRecordingPackage.addProtoSample(data:sample);
                self.moveCounter = 0;
                
                StylusManager.globalTime = sample["time"].intValue;

            }
            self.moveCounter+=1;
        }
    }
    
    public func onStylusUp(x:Float,y:Float,force:Float,angle:Float){
        guard self.collections["stylus"] != nil else{
            return
        }
        if(isLive){
            //let currentTime = Date();
            //let elapsedTime = Float(Int(currentTime.timeIntervalSince(currentStartDate!)*1000));
            
            for (_,stylusCollection) in self.collections{
                (stylusCollection as! StylusCollection).onStylusUp(x: x, y:y);
            }
            let sample = (self.collections["stylus"]! as! StylusCollection).exportData();
            currentRecordingPackage.addProtoSample(data:sample);
            StylusManager.globalTime = sample["time"].intValue;
            _ = self.endRecording();


            
        }
    }
    
    public func onStylusDown(x:Float,y:Float,force:Float,angle:Float){
        guard self.collections["stylus"] != nil else{
            return
        }
        if(isLive){
            currentStartDate = Date();
          
            _ = beginRecording(start:currentStartDate);
            
            
            for (_,stylusCollection) in self.collections{
                (stylusCollection as! StylusCollection).onStylusDown(x: x, y: y, force: force*20, angle: angle);
            }
          
                
            let sample = (self.collections["stylus"]! as! StylusCollection).exportData();
            currentRecordingPackage.addProtoSample(data:sample);
            StylusManager.globalTime = sample["time"].intValue;

            
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
        self.recordingPresetData["id"] = JSON(compiledId);
        let compiledRecordingCollection = ImportedRecordingCollection(data:self.recordingPresetData)
        let targetRecording = self.recordingPackages.first(){$0.id == startId}
        for (key,value) in (targetRecording?.protoSignals)!{
            compiledRecordingCollection.protoSignals[key]?.signalBuffer = value.signalBuffer;
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
            for (_,stylusCollection) in stylusManager.collections{
                (stylusCollection as! StylusCollection).onStylusUp(x: sample["x"].floatValue, y: sample["y"].floatValue);
            }
            stylusManager.stylusDataEvent.raise(data:("STYLUS_UP", [sample["x"].floatValue, sample["y"].floatValue]))
            break;
        case StylusManager.stylusDown:
            stylusManager.stylusDataEvent.raise(data:("STYLUS_DOWN", [sample["x"].floatValue, sample["y"].floatValue]))
            stylusManager.layerEvent.raise(data:("REQUEST_CORRECT_LAYER",sample["targetLayer"].stringValue));
            
            for (_,stylusCollection) in stylusManager.collections{
                (stylusCollection as! StylusCollection).onStylusDown(x: sample["x"].floatValue, y: sample["y"].floatValue, force: sample["force"].floatValue, angle: sample["angle"].floatValue);
            }
            
            break;
        case StylusManager.stylusMove:
            stylusManager.stylusDataEvent.raise(data:("STYLUS_MOVE", [sample["x"].floatValue, sample["y"].floatValue]))
            for (_,stylusCollection) in stylusManager.collections{
                (stylusCollection as! StylusCollection).onStylusMove(x: sample["x"].floatValue, y: sample["y"].floatValue, force: sample["force"].floatValue, angle: sample["angle"].floatValue);
            }
            break;
        default:
            break
        }
        
    }
}





