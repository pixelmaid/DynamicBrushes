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
    var collections: [String : SignalCollection] = [String : BrushCollection]();
    
    func registerCollection(collectionData: JSON) -> (id: String, collection: SignalCollection?) {
        let id = collectionData["id"].stringValue;
        if(collections[id]==nil){
            let signalCollection = BrushCollection(data:collectionData);
            collections[id] = signalCollection;
            return(id:id,collection:signalCollection);
        }
        else{
            collections[id]?.initializeSignalInstancesFromJSON(data:collectionData);
            return(id:id,collection:nil);
            
        }
    }
    
    
    func brushUpdateHandler(data:(String,String,StateStorage),key:String){
        let behaviorId = data.0;
        let brushId = data.1;
        let deltaStorage = data.2;
        #if DEBUG
        //print("brush update handler called:",behaviorId,brushId,deltaStorage.time);
        #endif
        
        for (_,collection) in self.collections{
            let brushCollection = collection as! BrushCollection
            let protodata = deltaStorage.toJSON();
            brushCollection.addProtoSampleForId(behaviorId:behaviorId, brushId: brushId, data: protodata);
        }
    }
    
    
    
    
    
    
}
