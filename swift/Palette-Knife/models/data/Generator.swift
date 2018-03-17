//
//  Generator.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 3/16/18.
//

import Foundation
import SwiftyJSON

class Generator:Signal{
   
    func reset(){
        self.setHash(h: 0);
    }
}

class Sine:Generator{
    var freq:Float
    var phase:Float
    var amp:Float
    
    
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, settings:JSON){
        self.freq = settings["freq"].floatValue;
        self.phase = settings["phase"].floatValue;
        self.amp = settings["amp"].floatValue;
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, settings:settings);
    }
    
    
    override func get(id:String?) -> Float {
        let v =  sin(self.hash*freq+phase)*amp/2+amp/2;
        return v;
    }
    
    
}


class Sawtooth:Generator{
    var val = [Float]();
    var index = Observable<Float>(0);
    required init(id:String, fieldName:String, displayName:String, collectionId:String, settings:JSON){
        let start = settings["start"].floatValue
        let stop = settings["stop"].floatValue
        let min = settings["min"].intValue
        let max = settings["max"].intValue

        let increment = (stop-start)/Float(max-min)
        for i in min...max-1{
            val.append(start+increment*Float(i))
        }
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, settings:settings);

    }
    
    override func get(id:String?) -> Float {
        let v = val[Int(index.get(id: nil))]
        return v;
    }
    
}


class Triangle:Signal{
    var freq:Float
    var min:Float
    var max:Float
    
    var index = Observable<Float>(0);
    
 required init(id:String, fieldName:String, displayName:String, collectionId:String, settings:JSON){
        self.freq = settings["freq"].floatValue;
        self.min = settings["min"].floatValue;
        self.max = settings["max"].floatValue;
    super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, settings:settings);

    }
    
    
    override func get(id:String?) -> Float {
        let ti = 2.0 * Float.pi * (880 / 44100);
        let theta = ti * self.index.get(id: nil)
        let _v = 1.0 - abs(Float(theta.truncatingRemainder(dividingBy: 4)-2));
        let v = MathUtil.map(value: _v, low1: -1, high1: 1, low2: min, high2: max)
        return v;
    }
    
    
}

class Square:Signal{
    var freq:Float
    var min:Float
    var max:Float
    var currentVal:Float
    
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, settings:JSON){

        self.freq = settings["freq"].floatValue;
        self.min = settings["min"].floatValue;
        self.max = settings["max"].floatValue;
        self.currentVal = min;
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, settings:settings);

    }
    
    override func get(id:String?) -> Float {
        if(hash == 0.0){
            if(currentVal == min){
                currentVal = max;
            }
            else{
                currentVal = min;
            }
        }
        
        return currentVal;
        
    }
    
    
}

class Alternate:Signal{
    var val = [Float]();
    var index = 0;
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, settings:JSON){
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, settings:settings);
        let jsonval = settings["values"].arrayValue;
        for v in jsonval{
            val.append(v.floatValue)
        }
    }
    
    
    override func get(id:String?) -> Float {
        let v = val[index]
        return v;
    }
    
    
    
}


class Random: Signal{
    let start:Float
    let end:Float
    var val:Float;
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, settings:JSON){
        self.start = settings["start"].floatValue;
        self.end = settings["end"].floatValue;
        val = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)

        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, settings:settings);
        
    }
    
    override func get(id:String?) -> Float {
        val = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)
        return val
    }
}


class Interval:Generator{
    var val = [Float]();
    var infinite = false;
    let inc:Float
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, settings:JSON){
        
        self.inc = settings["inc"].floatValue
        
        if (settings["times"] != JSON.null){
            
            let times = settings["times"].intValue
            for i in 1..<times{
                val.append(Float(i)*self.inc)
            }
        }
            
        else {
            infinite = true;
        }
        
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, settings:settings);
    }
    
    
    
    
    override func get(id:String?) -> Float {
        if(infinite){
            let inf = Float(self.hash)*self.inc
            return inf;
        }
        if(Int(hash) < val.count){
            let v = val[Int(hash)]
            
            return v;
        }
        return -1;
    }
    
    
}

