//
//  Stylus.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 5/25/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation


// manages stylus data, notifies behaviors of stylus events
class Stylus: TimeSeries, WebTransmitter {
    var prevPosition: Point
    var force = Observable<Float>(0)
    var prevForce: Float
    var angle = Observable<Float>(0)
    var speed = Float(0)
    var prevAngle: Float
    var position = Point(x:0,y:0);
    var origin = Point(x:0,y:0);
    var delta = Point(x:0,y:0);
    var deltaChangeBuffer = [Point]();
    var x:Observable<Float>
    var y:Observable<Float>
    var dx:Observable<Float>
    var dy:Observable<Float>
    var prevTime = Float(0);
    var penDown = Observable<Float>(0);
    var distance = Float(0);
    var forceSub = Float(1);
    var id = NSUUID().uuidString;
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()

    var constraintTransmitComplete = true;
    var moveDist = Float(0);
    
    // var testCount = 4;
    init(x:Float,y:Float,angle:Float,force:Float){
        prevPosition = Point(x:0, y:0)
        self.force.set(newValue: force);
        self.prevForce = force
        self.angle.set(newValue: angle)
        self.prevAngle = angle;
        self.x = position.x;
        self.y = position.y
        self.dx = delta.x;
        self.dy = delta.y
        super.init()
        self.name = "stylus"
        
        position.set(x: x, y:y)
        self.events =  ["STYLUS_UP","STYLUS_DOWN","STYLUS_MOVE_BY","STYLUS_X_MOVE_BY","STYLUS_Y_MOVE_BY"]
        self.createKeyStorage();
        
        //self.startInterval();
        
    }
    
    
    
    @objc override func timerIntervalCallback()
    {
        self.transmitData();
    }
    
    func transmitData(){
        var string = "{\"type\":\"stylus_data\",\"canvas_id\":\""+self.id;
        string += "\",\"stylusData\":{"
        string+="\"time\":"+String(self.getTimeElapsed())+","
        string+="\"pressure\":"+String(describing: self.force)+","
        string+="\"angle\":"+String(describing: self.angle)+","
        string+="\"penDown\":"+String(describing: self.penDown)+","
        string+="\"speed\":"+String(self.speed)+","
        string+="\"position\":{\"x\":"+String(describing: self.position.x)+",\"y\":"+String(describing: self.position.y)+"}"
        // string+="\"delta\":{\"x\":"+String(delta.x)+",\"y\":"+String(delta.y)+"}"
        string+="}}"
        
        transmitEvent.raise(data: string)
    }
    
    func get(targetProp:String)->Any?{
        switch targetProp{
        case "force":
            return force
            
        case "angle":
            return self.angle
            
            
        default:
            return nil
            
        }
        
    }
    
    func resetDistance(){
        self.distance=0;
    }
    
    func getDistance()->Float{
        return self.distance
    }
    
    func onStylusUp(){
        
        for key in keyStorage["STYLUS_UP"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
            }
            else{
                  NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STYLUS_UP"])
                
            }
        }
        self.delta.set(x: 0,y:0)
        self.penDown.set(newValue: 0);
        self.speed = 0;
        self.transmitData();
        
    }
    
    func onStylusDown(x:Float,y:Float,force:Float,angle:Float){
        //TODO: silent set, need to make more robust/ readable
        self.position.x.setSilent(newValue: x)
        self.position.y.setSilent(newValue: y)
        print("stylus down listeners\(self.keyStorage["STYLUS_DOWN"])");
        for key in self.keyStorage["STYLUS_DOWN"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
                eventCondition?.evaluate()
            }
            else{
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STYLUS_DOWN"])
            }
            
        }
        self.delta.set(x: 0,y:0)
        self.penDown.set(newValue: 1);
        self.prevTime = self.getTimeElapsed();
        self.speed = 0;
        self.transmitData();
        
    }
    
    func onStylusMove(x:Float,y:Float,force:Float,angle:Float){
        for key in keyStorage["STYLUS_MOVE_BY"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
                if(eventCondition?.evaluate())!{
                     NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STYLUS_MOVE_BY"])
                    
                }
                else{
                    //print("EVALUATION FOR CONDITION FAILED")
                }
                
            }
            else{
                
                    moveDist = 0;
                       NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STYLUS_MOVE_BY"])
                
            }
        }
        for key in keyStorage["STYLUS_X_MOVE_BY"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
                if(eventCondition?.evaluate())!{
                    NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STYLUS_X_MOVE_BY"])
                    
                }
                else{
                    //print("EVALUATION FOR CONDITION FAILED")
                }
                
            }
            else{
                
                moveDist = 0;
                NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STYLUS_X_MOVE"])
                
            }
        }
        for key in keyStorage["STYLUS_Y_MOVE_BY"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
                if(eventCondition?.evaluate())!{
                    NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STYLUS_Y_MOVE_BY"])
                    
                }
                else{
                    //print("EVALUATION FOR CONDITION FAILED")
                }
                
            }
            else{
                
                moveDist = 0;
                NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STYLUS_Y_MOVE_BY"])
                
            }
        }


        self.prevPosition.set(val:position);
        
        self.position.set(x: x,y:y)
        self.delta.set(val:self.position.sub(point: self.prevPosition))
      //  print("stylus pos\(self.delta.x.getSilent(),self.delta.y.getSilent(),self.position.x.getSilent(),self.position.y.getSilent())");

        self.delta.set(x: 0,y:0)

        deltaChangeBuffer.append(self.position.sub(point: self.prevPosition));
        self.distance += prevPosition.dist(point:position)
        moveDist += prevPosition.dist(point:position)
        self.prevForce = self.force.get(id:nil)
        self.force.set(newValue: force*5)
        self.prevAngle = self.angle.get(id:nil);
        self.angle.set(newValue:angle)
        let currentTime = self.getTimeElapsed();
        self.speed = prevPosition.dist(point: position)/(currentTime-prevTime)
        self.prevTime = currentTime;
        
    }
    
    
    func shiftDeltaBuffer(){
        self.delta.set(val:self.position.sub(point: self.prevPosition))

    }
    
    
    
    
}
