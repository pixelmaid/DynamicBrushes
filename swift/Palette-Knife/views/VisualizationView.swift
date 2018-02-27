//
//  VisualizationView.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 2/27/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class VisualizationView: ModifiedCanvasView {
    let drawingEventKey = NSUUID().uuidString
    let stylusDataEvent = Event<(String, [Float])>();


    override init(name:String,frame:CGRect) {
        super.init(name:name, frame:frame)
        _ = StylusManager.stylusDataEvent.addHandler(target: self, handler: VisualizationView.drawingEventHandler, key: drawingEventKey)
        print ("@@ init")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func drawingEventHandler(data:(String,[Float]),key:String){
        let coords = data.1
        let x:Double = Double(coords[0])
        let y:Double = Double(coords[1])
        let point = CGPoint(x:x, y:y)
        
        switch(data.0){
        case "STYLUS_UP":
            print ("@@ stylus up")
            self.renderStrokeById(currentStrokeId:"vstroke", toPoint:point, toWidth:1.0, toColor:UIColor.blue)
            break
        case "STYLUS_DOWN":
            print ("@@ stylus down")
            self.beginStroke(id:"vstroke")
            break
        case "STYLUS_MOVE":
            print ("@@ stylus move")
            self.renderStrokeById(currentStrokeId:"vstroke", toPoint:point, toWidth:1.0, toColor:UIColor.blue)
            break
        default:
            break
        }
        
    }
    
}
