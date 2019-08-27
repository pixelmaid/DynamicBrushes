//
//  Generator.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 3/16/18.
//

import Foundation
import SwiftyJSON

class Generator:Signal{
    var registeredBrushes = [String:Brush]();
    var paramList = [String : GeneratorStateStorage]()
    
    static let incrementConst = 1;
    required init(id: String, fieldName: String, displayName: String, collectionId: String, style: String, settings: JSON) {
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
        self.index = 0;

    }

    override func registerBrush(brush:Brush){
        self.registeredBrushes[brush.id] = brush;
        self.paramList[brush.id] = GeneratorStateStorage();
        
        
    }
    
    override func removeRegisteredBrush(id:String){
        guard self.registeredBrushes[id] != nil else{
            print("=============WARNING ATTEMPTED TO REMOVE REGISTERED BRUSH FOR GENERATOR THAT IS NOT REGISTERED===========");
            return;
        }
        self.registeredBrushes.removeValue(forKey: id);
        self.paramList.removeValue(forKey: id);

    }
    
    override func reset(){
        registeredBrushes.removeAll();
        self.paramList.removeAll();
    }
    
    override func clearAllRegisteredBrushes(){
        self.registeredBrushes.removeAll();
        self.paramList.removeAll();

    }

    func update(v: Float, id: String, time: Int) {
        self.didChange.raise(data: (self.id, self.prevV, v));
        self.prevV = v;
        let data:[String:Any] = ["v":v,"time":time];
        self.paramList[id]!.updateAll(data: data);
    }
    
   
   override public func paramsToJSON() -> JSON {
        var data = [JSON]();
        for (key,value) in self.paramList{
            var generatorData = value.toJSON();
            generatorData["generatorType"] = JSON(self.fieldName);
            generatorData["brushId"] = JSON(key);
            generatorData["brushIndex"] = JSON(self.registeredBrushes[key]!.index.getSilent());
            generatorData["behaviorId"] = JSON(self.registeredBrushes[key]!.behavior_id );
            generatorData["behaviorName"] = JSON(self.registeredBrushes[key]!.behaviorDef!.name);
            data.append(generatorData);
        }
       // let sortedData = data.sorted(by: { $0["behaviorId"].stringValue < $1["behaviorId"].stringValue});
        return JSON(data);
    }
    
    func getIndexById(id:String)->Int{
        guard self.registeredBrushes[id] != nil else{
            print("=============WARNING ATTEMPTED TO REMOVE REGISTERED BRUSH FOR GENERATOR THAT IS NOT REGISTERED===========");
            return -1;
        }
        let i =  registeredBrushes[id]!.params.time;
        return i;
    }
    
   override func incrementIndex(){
        self.setIndex(i: self.index+Generator.incrementConst);
    }
    
}

class Sine:Generator{
    var freq:Float
    var phase:Float
    var amp:Float
    
    
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        self.freq = 0.5// settings["freq"].floatValue;
        self.phase =  4.7//settings["phase"].floatValue;
        self.amp = 1.0; //settings["amp"].floatValue;
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
    }
    
    
    override func get(id:String?) -> Float {
        guard id != nil else{
            print("=============ERROR ATTEMPTED TO GET BY INDEX FOR GENERATOR BUT ID IS NIL===========");
            return 0;
        }
    
        let i = self.getIndexById(id: id!);
        let v =  (1+sin(Float(i)*freq*Float.pi+phase))*amp/2;
        self.update(v: v, id: id!,time: i);
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
        start = 0//settings["start"].floatValue
        stop = 100//settings["stop"].floatValue
        min = 0//settings["min"].intValue
        max = 100;//settings["max"].intValue

        let increment = Float(1);//(stop-start)/Float(max-min)
        for i in min...max-1{
            val.append(start+increment*Float(i))
        }
        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);

    }
    
    override func get(id:String?) -> Float {
        guard id != nil else{
            
            print("=============ERROR ATTEMPTED TO GET BY INDEX FOR GENERATOR BUT ID IS NIL===========");
            return 0;
        }
        
        let i = self.getIndexById(id: id!);
        let v = Float(i % (100))/100;
        self.update(v: v, id: id!,time: i);
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
    //TODO: reimplement freq/ min max?
    super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style,  settings:settings);


    }
    
    
    override func get(id:String?) -> Float {
        guard id != nil else{
            
            print("=============ERROR ATTEMPTED TO GET BY INDEX FOR GENERATOR BUT ID IS NIL===========");
            return 0;
        }
        
        let i = self.getIndexById(id: id!);
        
        
        let p = Float(10);
        let r = Float(i)/p;
        let v = 2.0*abs(r - floor(r+0.5));
        self.update(v: v, id: id!,time: i);
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
      
     
        guard id != nil else{
            
            print("=============ERROR ATTEMPTED TO GET BY INDEX FOR GENERATOR BUT ID IS NIL===========");
            return 0;
        }
        
    
    
        let t = self.getIndexById(id: id!);
        let i = Float(t);
    
        let p = Float(0.1);
        let a = floor(p*i);
        let b = floor((2.0*p*i));
        let v = 2.0*a-b+1.0;
        self.update(v: v, id: id!,time: t);
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

class Random: Generator{
    let start:Float
    let end:Float
    
    required init(id:String, fieldName:String, displayName:String, collectionId:String, style:String, settings:JSON){
        self.start = 0.0; //settings["start"].floatValue;
        self.end = 1.0; //settings["end"].floatValue;

        super.init(id: id, fieldName: fieldName, displayName: displayName, collectionId: collectionId, style: style, settings:settings);
        
    }
    
    override func get(id:String?) -> Float {
        
       guard id != nil else{
            print("=============ERROR ATTEMPTED TO GET BY INDEX FOR GENERATOR BUT ID IS NIL===========");
            return 0;
        }
    
    
    
        let i = self.getIndexById(id: id!);

        let v = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)
        
        
        self.update(v: v, id: id!,time: i);

        return v
    }
    override func getSettingsJSON()->JSON{
        var json = super.getSettingsJSON();
        
        json["start"] = JSON(self.start);
        json["end"] = JSON(self.end);
        return json;
    }
    
    
}


/*class Alternate:Generator{
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
    
    
    
}*/

