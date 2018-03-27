//
//  MicCollection.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 3/26/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class MicCollection: LiveCollection {
    
    var frequency:Float = 0
    var amplitude:Float = 0
    
    required init(data: JSON) {
        super.init(data: data);
        var protodata:JSON = [:]
        protodata["frequency"] = JSON(0);
        protodata["amplitude"] = JSON(0);
        super.addProtoSample(data: protodata);
    }
    
    
    func setFrequency(val:Float){
        self.frequency = val;
        self.exportData();
    }
    
    func setAmplitude(val:Float){
        self.amplitude = val;
        self.exportData();
    }
    
    
    override func exportData()->JSON{
        //export data
        var data = super.exportData();
        data["frequency"] = JSON(self.frequency);
        data["amplitude"] = JSON(self.amplitude);
        self.addProtoSample(data: data)
        return data;
    }
    

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

