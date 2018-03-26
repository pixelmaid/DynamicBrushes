//
//  UIInput.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/20/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class UICollection: LiveCollection {
   
    var hue:Float = 0
    var lightness:Float = 25
     var saturation:Float = 100
    var alpha:Float = 100;
     var diameter:Float = 20

    required init(data: JSON) {
        super.init(data: data);
        var protodata:JSON = [:]
        protodata["hue"] = JSON(0);
        protodata["lightness"] = JSON(0);
        protodata["saturation"] = JSON(0);
        protodata["alpha"] = JSON(0);
        protodata["diameter"] = JSON(0);
        protodata["time"] = JSON(0);
        super.addProtoSample(data: protodata);
    }
    
    func setColor(color:UIColor){
        var _hue = CGFloat(0)
        var _saturation = CGFloat(100)
        var _brightness = CGFloat(100)
        var _alpha = CGFloat(0)
        let success = color.getHue(&_hue, saturation: &_saturation, brightness: &_brightness, alpha: &_alpha)
        if(success){
            self.hue = MathUtil.map(value:Float(_hue), low1:0, high1:1, low2:0, high2: 100);
            self.lightness = MathUtil.map(value:Float(_brightness), low1:0, high1:1, low2:0, high2: 100);
            self.saturation = MathUtil.map(value:Float(_saturation), low1:0, high1:1, low2:0, high2: 100);
            _ = self.exportData();

        }
    }
    
    
    func setDiameter(val:Float){
        self.diameter = val;
         self.exportData();
    }
    
    func setAlpha(val:Float){
        self.alpha = val;
         self.exportData();
    }
    
   
     override func exportData()->JSON{
        //export data
        var data = super.exportData();
        data["hue"] = JSON(self.hue);
        data["lightness"] = JSON(self.lightness);
        data["saturation"] = JSON(self.saturation);
        data["alpha"] = JSON(self.alpha);
        data["diameter"] = JSON(self.diameter);
    
     
        self.addProtoSample(data: data)
        return data;
    }
    
    //TODO: INIT UI PROPERTIES
    override public func initializeSignal(fieldName:String, displayName:String, settings:JSON, classType:String, style:String, isProto:Bool, order:Int?)->String{
        if(classType == "TimeSignal"){
            return super.initializeSignal(fieldName: fieldName, displayName: displayName, settings: settings, classType: classType, style:style, isProto: isProto, order: order);
        }
        
        let id = NSUUID().uuidString
        let signal = LiveSignal(id:id , fieldName: fieldName, displayName: displayName, collectionId: self.id, style:style, settings:settings);
        self.storeSignal(fieldName: fieldName, signal: signal, isProto:isProto, order:order)
        return id;
    }
    
 
}
