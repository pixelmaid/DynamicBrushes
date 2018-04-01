//
//  Generator.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 3/16/18.
//

import Foundation
import SwiftyJSON

class Generator:Signal{

    required init(id: String, fieldName: String, displayName: String, collectionId: String, style: String, settings: JSON) {
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
        self.index = 0;

    }
    
   

   override func incrementIndex(){
        self.setIndex(i: self.index+1);
    }
    
}

class Sine:Generator{
    var freq:Float
    var phase:Float
    var amp:Float
    
    
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        self.freq = settings["freq"].floatValue;
        self.phase = settings["phase"].floatValue;
        self.amp = settings["amp"].floatValue;
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
    }
    
    
    override func get(id:String?) -> Float {
        let v =  sin(Float(self.index)*freq+phase)*amp/2+amp/2;
        incrementAndChange(v: v);
        return v;
    }
    
    override func getSettingsJSON()->JSON{
        var json = super.getSettingsJSON();
        json["freq"] = JSON(self.freq);
        json["phase"] = JSON(self.phase);
        json["amp"] = JSON(self.amp);
        return json;
    }
    
    
}


class Sawtooth:Generator{
    var val = [Float]();
    var start:Float;
    var stop:Float;
    var min:Int;
    var max:Int;
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
         start = settings["start"].floatValue
         stop = settings["stop"].floatValue
         min = settings["min"].intValue
         max = settings["max"].intValue

        let increment = (stop-start)/Float(max-min)
        for i in min...max-1{
            val.append(start+increment*Float(i))
        }
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
        print("index =",self.index);

    }
    
    override func get(id:String?) -> Float {
        let v = val[Int(index)]
        incrementAndChange(v: v);
        if(index>=val.count){
            self.index = 0;
        }
        return v;
    }
    
    override func getSettingsJSON()->JSON{
        var json = super.getSettingsJSON();
        json["start"] = JSON(self.start);
        json["stop"] = JSON(self.stop);
        json["min"] = JSON(self.min);
        json["max"] = JSON(self.max);
        return json;
    }
    
}


class Triangle:Generator{
    var freq:Float
    var min:Float
    var max:Float
    
 required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        self.freq = settings["freq"].floatValue;
        self.min = settings["min"].floatValue;
        self.max = settings["max"].floatValue;
    super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style,  settings:settings);

    }
    
    
    override func get(id:String?) -> Float {
        let ti = 2.0 * Float.pi * (880 / 44100);
        let theta = ti * Float(self.index);
        let _v = 1.0 - abs(Float(theta.truncatingRemainder(dividingBy: 4)-2));
        let v = MathUtil.map(value: _v, low1: -1, high1: 1, low2: min, high2: max)
        incrementAndChange(v: v);

        return v;
    }
    
    override func getSettingsJSON()->JSON{
        var json = super.getSettingsJSON();
       
        json["freq"] = JSON(self.freq);
        json["min"] = JSON(self.min);
        json["max"] = JSON(self.max);
        return json;
    }
    
    
}

class Square:Generator{
    var freq:Float
    var min:Float
    var max:Float
    var currentVal:Float
    
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){

        self.freq = settings["freq"].floatValue;
        self.min = settings["min"].floatValue;
        self.max = settings["max"].floatValue;
        self.currentVal = min;
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);

    }
    
    override func get(id:String?) -> Float {
        //TODO: This won't work correctly with new hash system
        if(self.index == 0){
            if(currentVal == min){
                currentVal = max;
            }
            else{
                currentVal = min;
            }
        }
        incrementAndChange(v: currentVal);

        
        return currentVal;
        
    }
    
    override func getSettingsJSON()->JSON{
        var json = super.getSettingsJSON();
        
        json["freq"] = JSON(self.freq);
        json["min"] = JSON(self.min);
        json["max"] = JSON(self.max);
        return json;
    }
    
    
    
}

class Alternate:Generator{
    var val = [Float]();
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
        let jsonval = settings["val"].arrayValue;
        for v in jsonval{
            val.append(v.floatValue)
        }
    }
    
    
    override func get(id:String?) -> Float {
        //TODO: This won't work correctly with new hash system

        let v = val[Int(self.index)]
        incrementAndChange(v: v);
        if(index>=val.count){
            self.index = 0;
        }
        return v;
    }
    
    
    override func getSettingsJSON()->JSON{
        var json = super.getSettingsJSON();
        
        json["val"] = JSON(self.val);
        return json;
    }
    
    
    
}


class Random: Generator{
    let start:Float
    let end:Float
    var val:Float;
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        self.start = settings["start"].floatValue;
        self.end = settings["end"].floatValue;
        val = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)

        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
        
    }
    
    override func get(id:String?) -> Float {
        //TODO: This won't work correctly with new hash system

        val = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)
        incrementAndChange(v: val);

        return val
    }
    override func getSettingsJSON()->JSON{
        var json = super.getSettingsJSON();
        
        json["start"] = JSON(self.start);
        json["end"] = JSON(self.end);
        return json;
    }
    
    
}


class Interval:Generator{
    var val = [Float]();
    var infinite = false;
    let inc:Float
    let times:Int?
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        
        self.inc = settings["inc"].floatValue
        
        if (settings["times"] != JSON.null){
            
            self.times = settings["times"].intValue
            
            for i in 1..<settings["times"].intValue{
                val.append(Float(i)*self.inc)
            }
        }
            
        else {
            infinite = true;
           self.times = nil;
        }
        
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
    }
    
    
    
    
    override func get(id:String?) -> Float {
        if(infinite){
            let inf = Float(self.index)*self.inc
            return inf;
        }
        if(self.index < val.count){
            let v = val[self.index]
            incrementAndChange(v: v);

            return v;
        }
        return -1;
    }
    
    override func getSettingsJSON()->JSON{
        var json = super.getSettingsJSON();
        
        json["inc"] = JSON(self.inc);
        if(times != nil){
            json["times"] = JSON(self.times!)
        }
        else{
            json["times"] = JSON.null;
        }
        return json;
    }
    
    
    
}

