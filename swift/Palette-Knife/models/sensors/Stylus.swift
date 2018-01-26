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
    var prevForce = Observable<Float>(0)
    var angle = Observable<Float>(0)
    var speed = MovingAverage(id:"stylus_speed");
    var prevAngle = Observable<Float>(0)
    var deltaAngle = Observable<Float>(0)
    var position = LinkedPoint(x:0,y:0)
    var origin = Point(x:0,y:0);
    var delta = LinkedPoint(x:0,y:0);
    var deltaChangeBuffer = [Point]();
    var x:Observable<Float>
    var y:Observable<Float>
    var dx:Observable<Float>
    var dy:Observable<Float>
    var xDistance:Observable<Float>
    var yDistance:Observable<Float>
    var distance:Observable<Float>
    var prevTime = Float(0);
    var penDown = Observable<Float>(0);
    var forceSub = Float(1);
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()
    var moveCounter  = 0;
    var constraintTransmitComplete = true;
    
    //var moveDist = Float(0);
    
    // var testCount = 4;
    init(x:Float,y:Float,angle:Float,force:Float){
        prevPosition = Point(x:0, y:0)
        self.force.set(newValue: force);
        self.prevForce.set(newValue: force)
        self.angle.set(newValue: angle)
        self.prevAngle.set(newValue: angle)
        self.x = position.x;
        self.y = position.y
        self.x.printname = "stylus_position_x"
        self.y.printname = "stylus_position_y"
        self.speed.set(newValue: 0)
        self.dx = delta.x;
        self.dy = delta.y;
        self.dx.printname = "stylus_delta_x"
        self.dy.printname = "stylus_delta_y"
        self.distance = Observable<Float>(0);
        self.xDistance = Observable<Float>(0);
        self.yDistance = Observable<Float>(0);
        RequestHandler.registerObservable(observableId: "stylus_x", observable: self.x)
        RequestHandler.registerObservable(observableId: "stylus_y", observable: self.y)
        RequestHandler.registerObservable(observableId: "stylus_dx", observable: self.dx)
        RequestHandler.registerObservable(observableId: "stylus_dy", observable: self.dy)
        RequestHandler.registerObservable(observableId: "stylus_force", observable: self.force)
        RequestHandler.registerObservable(observableId: "stylus_angle", observable: self.angle)
        super.init()
        self.id = "stylus";
        self.name = "stylus"
        self.position.name = "stylus_position"
        position.set(x: x, y:y)
        self.events =  ["STYLUS_UP","STYLUS_DOWN","STYLUS_MOVE_BY","STYLUS_X_MOVE_BY","STYLUS_Y_MOVE_BY"]
        self.createKeyStorage();
        
        self.x.setActiveStatus(status: true)
        self.y.setActiveStatus(status: true)
        self.dx.setActiveStatus(status: true)
        self.dy.setActiveStatus(status: true)
        self.force.setActiveStatus(status: true)
        self.angle.setActiveStatus(status: true)
        
        self.startInterval();
        
    }
    
    
    
    @objc override func timerIntervalCallback()
    {
        //self.transmitData();
    }
    
    func transmitData(){
        var string = "{\"type\":\"stylus_data\",\"canvas_id\":\""+self.id;
        string += "\",\"stylusData\":{"
        string+="\"time\":"+String(self.getTimeElapsed())+","
        string+="\"pressure\":"+String(describing: self.force)+","
        string+="\"angle\":"+String(describing: self.angle)+","
        string+="\"penDown\":"+String(describing: self.penDown)+","
        string+="\"speed\":"+String(self.speed.get(id:nil))+","
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
        self.distance.set(newValue: 0);
        self.xDistance.set(newValue: 0);
        self.yDistance.set(newValue: 0)
        
        for key in keyStorage["STYLUS_MOVE_BY"]!{
            if(key.1 != nil){
                let eventCondition = key.1;
                eventCondition!.reset();
            }

        }
        
        
        for key in keyStorage["STYLUS_X_MOVE_BY"]!{
            if(key.1 != nil){
                let eventCondition = key.1;
                eventCondition!.reset();
            }
            
        }
        
        for key in keyStorage["STYLUS_Y_MOVE_BY"]!{
            if(key.1 != nil){
                let eventCondition = key.1;
                eventCondition!.reset();
            }
            
        }
    }
    
    
    func onStylusUp(){
        for key in keyStorage["STYLUS_UP"]!  {
            key.2.undergoing_transition = true;
        }
        for key in keyStorage["STYLUS_UP"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
            }
            else{
                  NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"STYLUS_UP"])
                
            }
            key.2.undergoing_transition = false;

        }
        //self.delta.set(x: 0,y:0)
        self.penDown.set(newValue: 0);
        self.speed.hardReset(val: 0);
        self.speed.set(newValue: 0);
        self.resetDistance();
        //self.transmitData();
        
    }
    
    func onStylusDown(x:Float,y:Float,force:Float,angle:Float){
        moveCounter = 0;
        //TODO: silent set, need to make more robust/ readable
        self.origin.set(x: x, y: y)
        self.position.x.setSilent(newValue: x)
        self.position.y.setSilent(newValue: y)
        for key in self.keyStorage["STYLUS_DOWN"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
                _ = eventCondition?.evaluate()
            }
            else{
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"STYLUS_DOWN"])
            }
            
        }
        self.delta.set(x: 0,y:0)
        self.penDown.set(newValue: 1);
        self.prevTime = self.getTimeElapsed();
        self.speed.set(newValue: 0);
        //self.transmitData();
        
    }
    
    func onStylusMove(x:Float,y:Float,force:Float,angle:Float){
        if(moveCounter == 0){
        for key in keyStorage["STYLUS_MOVE_BY"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
                if(eventCondition?.evaluate())!{
                     NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"STYLUS_MOVE_BY"])
                    
                }
                else{
                    #if DEBUG
                    //print("EVALUATION FOR CONDITION FAILED")
                    #endif
                }
                
            }
            else{
                NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"STYLUS_MOVE_BY"])
                
            }
        }
        for key in keyStorage["STYLUS_X_MOVE_BY"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
                if(eventCondition?.evaluate())!{
                    NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"STYLUS_X_MOVE_BY"])
                    
                }
                else{
                    #if DEBUG
                        //print("EVALUATION FOR CONDITION FAILED")
                    #endif
                }
                
            }
            else{
                NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"STYLUS_X_MOVE"])
                
            }
        }
        for key in keyStorage["STYLUS_Y_MOVE_BY"]!  {
            if(key.1 != nil){
                let eventCondition = key.1;
                if(eventCondition?.evaluate())!{
                    NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"STYLUS_Y_MOVE_BY"])
                    
                }
                else{
                    #if DEBUG
                        //print("EVALUATION FOR CONDITION FAILED")
                    #endif
                }
                
            }
            else{
                NotificationCenter.default.post(name:NSNotification.Name(key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"STYLUS_Y_MOVE_BY"])
                
            }
        }


        self.prevPosition.set(val:position);
        let newP = Point(x:x,y:y);
        self.position.set(val:newP)
       
    
        let d = self.position.sub(point: self.prevPosition)
      
        self.delta.set(val:d)
        var _deltaAngle =  MathUtil.cartToPolar(p1: self.origin, p2: self.position).1
        _deltaAngle = MathUtil.map(value: _deltaAngle, low1:0.0, high1: 2*Float.pi, low2: 0.0, high2: 100.0)
        self.deltaAngle.set(newValue: _deltaAngle)
        //self.delta.set(x: 0,y:0)

       //deltaChangeBuffer.append(self.position.sub(point: self.prevPosition));
        
         self.distance.set(newValue: self.distance.getSilent() + sqrt(pow( d.x.getSilent(),2)+pow( d.y.getSilent(),2)));
        self.xDistance.set(newValue: self.xDistance.getSilent() + abs(d.x.getSilent()));
        self.yDistance.set(newValue: self.yDistance.getSilent() + abs(d.y.getSilent()));

        self.prevForce.set(newValue:self.force.get(id:nil))
        self.force.set(newValue: force*20)
        self.prevAngle.set(newValue:self.angle.get(id:nil));
        self.angle.set(newValue:angle)
        let currentTime = self.getTimeElapsed();
        var _speed = prevPosition.dist(point: position)/(currentTime-prevTime)
        if(_speed > 5000){
            _speed = 5000
        }
         _speed = MathUtil.map(value: _speed, low1:0, high1: 5000, low2: 0, high2: 100)
        self.speed.set(newValue:_speed)
        self.prevTime = currentTime;
        #if DEBUG
           // print("stylus speed =",self.speed.get(id: nil));
            print("stylus delta angle =",self.deltaAngle.get(id: nil));

        #endif
        }
       // moveCounter += 1
        if(moveCounter > 10){
            moveCounter = 0;
        }
        
    }
    
    
    func shiftDeltaBuffer(){
        self.delta.set(val:self.position.sub(point: self.prevPosition))

    }
    
    
    
    
}
