//
//  StateStorage.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 5/23/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON


protocol StateStorage {
  
    func toJSON()->JSON;
    
    func updateAll(data:[String:Any]);
    
    func update(key:String,value:Any);
    
    func clear();
    
}


class BaseStateStorage:NSObject, StateStorage{

    
    override init(){
        super.init();
    }
    
    init(json:JSON){
        super.init();
        self.parseJSON(json:json);
    }
    
    func toJSON()->JSON{
        
        var data:JSON = [:];
        let mirror = Mirror(reflecting: self);
        
        for child in mirror.children{
            data[child.label as! String] = JSON(child.value);
            
        }
        return data;
        
    }
    
    func parseJSON(json:JSON){
        
        for (key, subJson) in json {
            self.update(key: key,value: subJson.object);
        }
    }
    
    func update(key:String,value:Any){
        self.setValue(value, forKey: key);
    }
    
    func updateAll(data:[String:Any]){
        let mirror = Mirror(reflecting: self);
        
        for child in mirror.children{
            let label = child.label as! String
            let v = data[label];
            self.setValue(v, forKey: label);
            
        }
        
    }
    
    
    func clear(){
        
    }
}


class BrushStateStorage:BaseStateStorage {
    
    @objc dynamic var dx = Float(0)
    @objc dynamic var dy = Float(0)
    @objc dynamic var pr = Float(0)
    @objc dynamic var pt = Float(0)
    @objc dynamic var ox = Float(0)
    @objc dynamic var oy = Float(0)
    @objc dynamic var rotation = Float(0)
    @objc dynamic var sx = Float(0)
    @objc dynamic var sy = Float(0)
    @objc dynamic var weight = Float(0)
    @objc dynamic var hue = Float(0)
    @objc dynamic var saturation = Float(0)
    @objc dynamic var lightness = Float(0)
    @objc dynamic var alpha = Float(0)
    @objc dynamic var dist = Float(0);
    @objc dynamic var xDist = Float(0);
    @objc dynamic var yDist = Float(0);
    @objc dynamic var x = Float(0);
    @objc dynamic var y = Float(0);
    @objc dynamic var cx = Float(0);
    @objc dynamic var cy = Float(0);
    @objc dynamic var i = Float(0);
    @objc dynamic var sc = Float(0);
    @objc dynamic var lv = Float(0);
    @objc dynamic var parent: String?
    @objc dynamic var active: Bool = true;
    @objc dynamic var time = Int(0);

}


class GeneratorStateStorage:BaseStateStorage {
    @objc dynamic var v = Float(0);
    @objc dynamic var time = Int(0);

    

}
