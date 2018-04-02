//
//  BrushSignalManager.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 1/30/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import SwiftyJSON


class BrushSignalManager:SignalCollectionManager{
    
    func brushUpdateHandler(data:(String,String,DeltaStorage),key:String){
        let behaviorId = data.0;
        let brushId = data.1;
        let deltaStorage = data.2;
        #if DEBUG
       // print("brush update handler called:",behaviorId,brushId,deltaStorage);
        #endif
        
        for (_,collection) in self.collections{
            let brushCollection = collection as! BrushCollection
            var protodata:JSON = [:]
            protodata["time"] = JSON(deltaStorage.time);
            protodata["x"] = JSON(deltaStorage.pX);
            protodata["y"] = JSON(deltaStorage.pY);
            protodata["dx"] = JSON(deltaStorage.dX);
            protodata["dy"] = JSON(deltaStorage.dY);
            protodata["diameter"] = JSON(deltaStorage.d);
            protodata["rotation"] = JSON(deltaStorage.r);
            protodata["sx"] = JSON(deltaStorage.sX);
            protodata["sy"] = JSON(deltaStorage.sY);
            protodata["hue"] = JSON(deltaStorage.h);
            protodata["saturation"] = JSON(deltaStorage.s);
            protodata["lightness"] = JSON(deltaStorage.l);
            protodata["alpha"] = JSON(deltaStorage.a);
            protodata["index"] = JSON(deltaStorage.i);
            protodata["siblingcount"] = JSON(deltaStorage.sC);
            protodata["level"] = JSON(deltaStorage.lV);
            brushCollection.addProtoSampleForId(behaviorId:behaviorId, brushId: brushId, data: protodata);
        }
    }
    
    
    
    
    
    
}
