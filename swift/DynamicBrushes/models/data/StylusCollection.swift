//
//  Stylus.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/25/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON


class BrushCollection:LiveCollection{
    
    override public func initializeSignalWithId(signalId:String, fieldName:String, displayName:String, settings:JSON, classType:String, style:String, isProto:Bool, order:Int?){
        if(classType == "TimeSignal"){
            super.initializeSignalWithId(signalId:signalId, fieldName: fieldName, displayName: displayName, settings: settings, classType: classType, style:style, isProto: isProto, order: order);
            return;
        }
        
        let signal = BrushSignal(id:signalId, fieldName: fieldName, displayName: displayName, collectionId: self.id, style:style, settings:settings);
        
        self.storeSignal(fieldName: fieldName, signal: signal, isProto:isProto, order:order)
        
    }
    

    
    public func addProtoSampleForId(behaviorId:String, brushId:String, data: JSON) {
        for (key,value) in data {
            guard let targetProtoSignal = self.protoSignals[key] else {
                print("ERROR ---------NO PROTO SIGNAL FOUND THAT CORRESPOND WITH FIELD NAME-----------",key,self.protoSignals)
                break;
            }
            targetProtoSignal.addValueFor(behaviorId:behaviorId, brushId:brushId, v: value.floatValue)
            guard let initializedList = self.initializedSignals[key] else{
                print("ERROR ---------NO  SIGNAL LIST THAT CORRESPOND WITH FIELD NAME-----------",key)
                break;
            }
            for (_,signal) in initializedList{
                signal.addValueFor(behaviorId:behaviorId, brushId:brushId, v: value.floatValue)
            }
        }
    }
}


// manages stylus data, notifies behaviors of stylus events
class StylusCollection:LiveCollection {
    
    var x:Float=0;
    var y:Float=0;
    var oX:Float = 0;
    var oY:Float = 0;
    var dx:Float = 0;
    var dy:Float = 0;
    var pX:Float=0;
    var pY:Float=0;
    var force:Float=0;
    var angle:Float=0;
    var deltaAngle:Float = 0;
    var xDistance:Float = 0;
    var yDistance:Float = 0;
    var euclidDistance:Float = 0;
    var speed:Float = 0;
    var stylusEvent:Float = 0;
    
    
    
    required init(data: JSON) {
        super.init(data: data);
        var protodata:JSON = [:]
        protodata["x"] = JSON(0);
        protodata["y"] = JSON(0);
        protodata["ox"] = JSON(0);
        protodata["oy"] = JSON(0);
        protodata["dx"] = JSON(0);
        protodata["dy"] = JSON(0);
        protodata["force"] = JSON(0);
        protodata["angle"] = JSON(0);
        protodata["deltaAngle"] = JSON(0);
        protodata["xDistance"] = JSON(0);
        protodata["yDistance"] = JSON(0);
        protodata["euclidDistance"] = JSON(0);
        protodata["xDistance"] = JSON(0);
        protodata["yDistance"] = JSON(0);
        protodata["stylusEvent"] = JSON(0);
        protodata["speed"] = JSON(0);
        protodata["time"] = JSON(0);
        super.addProtoSample(data: protodata);
    }
    
    func onStylusUp(x:Float,y:Float){
        self.angle = 0;
        self.force = 0;
        self.dx = 0;
        self.dy = 0;
        self.x = x;
        self.y = y;
        self.speed = 0;
        self.stylusEvent = Signal.stylusUp;
        self.time = self.getTimeElapsed();

        let data = self.exportData();
        self.addProtoSample(data: data)
    }
    
    func onStylusDown(x:Float,y:Float,force:Float,angle:Float){
        self.oX = x;
        self.oY = y;
        self.x = x;
        self.y = y;
        self.dx = 0;
        self.dy = 0;
        self.force = force;
        self.angle = angle;
        self.stylusEvent = Signal.stylusDown;
        self.speed = 0;
        self.deltaAngle = 0;
        self.time = self.getTimeElapsed();

        let data = self.exportData();
        self.addProtoSample(data: data)

    }
    
    func onStylusMove(x:Float,y:Float,force:Float,angle:Float)->JSON{
      
        //TODO: REFACTOR FOR STYLUS MOVE BY
        self.pX = self.x;
        self.x = x;
        self.pY = self.y;
        self.y = y;
        self.force = force;
        self.angle = angle;
        self.dx = x-pX;
        self.dy = y-pY;
        
        //let rawDeltaAngle = MathUtil.cartToPolar(x1: self.oX, y1: self.oY, x2: self.x, y2: self.y).1;
        self.deltaAngle = 0//MathUtil.map(value: rawDeltaAngle, low1:0.0, high1: 2*Float.pi, low2: 0.0, high2: 100.0)
        self.xDistance = 0//self.xDistance + abs(dx);
        self.yDistance = 0//self.yDistance + abs(dy);
       // let euclidDelta = sqrt(pow(dx,2)+pow(dy,2));
        self.euclidDistance = 0//self.euclidDistance + sqrt(pow(dx,2)+pow(dy,2));
        self.time = self.getTimeElapsed();
       
       /* let currentTime = self.getTimeElapsed();
        var rawSpeed = euclidDelta/Float(currentTime-prevTime)
        if(rawSpeed > 5000){
            rawSpeed = 5000;
        }
        self.speed = MathUtil.map(value: rawSpeed, low1:0, high1: 5000, low2: 0, high2: 100);
        
        self.prevTime = currentTime;*/
        //TODO: setup speed;
        self.speed = 0;

        self.stylusEvent = Signal.stylusMove;
        let data = self.exportData();
        self.addProtoSample(data: data)
        return data;

     
    }
    
    override public func addProtoSample (data: JSON) {
     let sortedProtos = self.protoSignals.sorted{ $0.1.order < $1.1.order }
        for i in 0..<sortedProtos.count {
            let key = sortedProtos[i].key;
            let targetProtoSignal = sortedProtos[i].value
            guard data[key] != JSON.null else {
                print("ERROR ---------NO PROTO SIGNAL FOUND THAT CORRESPOND WITH FIELD NAME-----------",key,self.protoSignals)
                return;
            }
            let value = data[key].floatValue;
            targetProtoSignal.addValue(v: value);
            guard let initializedList = self.initializedSignals[key] else{
                print("ERROR ---------NO  SIGNAL LIST THAT CORRESPOND WITH FIELD NAME-----------",key)
                return;
            }
            for (_,signal) in initializedList{
                signal.addValue(v: value);
            }
        }
    }
    
  
    
    override func exportData()->JSON{
        //export data
        var data = super.exportData();
        data["x"] = JSON(self.x);
        data["y"] = JSON(self.y);
        data["dx"] = JSON(self.dx);
        data["dy"] = JSON(self.dy);
        data["ox"] = JSON(self.oX);
        data["oy"] = JSON(self.oY);
        data["force"] = JSON(self.force);
        data["angle"] = JSON(self.angle);
        data["stylusEvent"] = JSON(self.stylusEvent);
        data["euclidDistance"] = JSON(self.euclidDistance);
        data["xDistance"] = JSON(self.xDistance);
        data["yDistance"] = JSON(self.yDistance);
        data["speed"] = JSON(self.speed);
        data["deltaAngle"] = JSON(self.deltaAngle);
        return data;
    }
  
    
    
    
    
}
