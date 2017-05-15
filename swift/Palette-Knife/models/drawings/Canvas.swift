//
//  Canvas.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 6/24/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import UIKit
//Canvas
//stores multiple drawings

class Canvas: WebTransmitter, Hashable{
    var id = NSUUID().uuidString;
    var name:String;
    var drawings = [Drawing]()
    var currentDrawing:Drawing?
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()
    
    var geometryModified = Event<(Geometry,String,String)>()
    
    let drawKey = NSUUID().uuidString;
    let  dataKey = NSUUID().uuidString;
    
    
    //MARK: - Hashable
    var hashValue : Int {
        get {
            return "\(self.id)".hashValue
        }
    }
    
    
    required init(){
        name = "default_"+id;
    }
    
    func drawSegment(context:CGContext){
        for i in 0..<drawings.count{
            if(drawings[i].dirty){
                drawings[i].drawSegment(context:context);
            }
        }
    }
    
    func initDrawing(){
        currentDrawing = Drawing();
        drawings.append(currentDrawing!)
        currentDrawing!.transmitEvent.addHandler(target: self,handler: Canvas.drawingDataGenerated, key:drawKey);
        currentDrawing!.geometryModified.addHandler(target: self,handler: Canvas.drawHandler, key:dataKey);
        
        var string = "{\"canvas_id\":\""+self.id+"\","
        string += "\"drawing_id\":\""+currentDrawing!.id+"\","
        string += "\"type\":\"new_drawing\"}"
        self.transmitEvent.raise(data:(string));
        
    }
    
    func hitTest(point:Point, threshold:Float)->Stroke?{
        let hit = currentDrawing!.hitTest(point: point,threshold:threshold)
        if(hit != nil){
            print("found stroke \(hit)");
            return hit;
        }
        print("found no stroke");
        
        return nil;
    }
    
    func drawingDataGenerated(data:(String), key:String){
        var string = "{\"canvas_id\":\""+self.id+"\","
        string += data;
        string += "}"
        self.transmitEvent.raise(data:(string));
    }
    
    
    
    
    //Event handlers
    //chains communication between brushes and view controller
    func drawHandler(data:(Geometry,String,String), key:String){
        self.geometryModified.raise(data:data)
    }
    
    
    
}


// MARK: Equatable
func ==(lhs:Canvas, rhs:Canvas) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}


