//
//  Stylus.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 5/25/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON

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
    var speedDate:Date;
    var prevTime:Float = 0;
    var stylusEvent:Float = 0;
    
 
    required init(data: JSON) {
        self.speedDate = Date();
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
        protodata["time"] = JSON(0);

        super.addProtoSample(data: protodata);
    }
    
    func onStylusUp(x:Float,y:Float){
        self.xDistance = 0;
        self.yDistance = 0;
        self.euclidDistance = 0;
        self.angle = 0;
        self.force = 0;
        self.dx = 0;
        self.dy = 0;
        self.x = x;
        self.y = y;
        self.speed = 0;
        self.stylusEvent = Signal.stylusUp;
        
        self.exportData();
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
        self.xDistance = 0;
        self.yDistance = 0;
        self.euclidDistance = 0;
        self.prevTime = self.getTimeElapsed();
        
        self.exportData();

    }
    
    func onStylusMove(x:Float,y:Float,force:Float,angle:Float){
      
        //TODO: REFACTOR FOR STYLUS MOVE BY
        self.pX = self.x;
        self.x = x;
        self.pY = self.y;
        self.y = y;
        self.force = force;
        self.angle = angle;
        self.dx = x-pX;
        self.dy = y-pY;
        
        let rawDeltaAngle = MathUtil.cartToPolar(x1: self.oX, y1: self.oY, x2: self.x, y2: self.y).1;
        self.deltaAngle = MathUtil.map(value: rawDeltaAngle, low1:0.0, high1: 2*Float.pi, low2: 0.0, high2: 100.0)
        self.xDistance = self.xDistance + abs(dx);
        self.yDistance = self.yDistance + abs(dy);
        let euclidDelta = sqrt(pow(dx,2)+pow(dy,2));
        self.euclidDistance = self.euclidDistance + sqrt(pow(dx,2)+pow(dy,2));

       
        let currentTime = self.getTimeElapsed();
        var rawSpeed = euclidDelta/(currentTime-prevTime)
        if(rawSpeed > 5000){
            rawSpeed = 5000;
        }
        self.speed = MathUtil.map(value: rawSpeed, low1:0, high1: 5000, low2: 0, high2: 100);
        
        self.prevTime = currentTime;
        self.stylusEvent = Signal.stylusMove;
        self.exportData();
     
    }
    
    func exportData(){
        //export data
        var data:JSON = [:];
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
        
        //TODO:RESOLVE TIME
        data["time"] = JSON(self.getTimeElapsed());
        
        self.addProtoSample(data: data)
    }
  
    
    func getTimeElapsed()->Float{
        let currentTime = NSDate();
        let t = currentTime.timeIntervalSince(speedDate as Date)
        return Float(t);
    }
    
    
    
}
