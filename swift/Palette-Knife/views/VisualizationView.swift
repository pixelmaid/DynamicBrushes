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
    let eraseEventKey = NSUUID().uuidString
    let stylusDataEvent = Event<(String, [Float])>();
    let stylusEraseEvent = Event<String>();

    override init(name:String,frame:CGRect) {
        super.init(name:name, frame:frame)
        _ = StylusManager.stylusDataEvent.addHandler(target: self, handler: VisualizationView.drawingEventHandler, key: drawingEventKey)
        _ = StylusManager.stylusEraseEvent.addHandler(target: self, handler: VisualizationView.eraseEventHandler, key: eraseEventKey)

        print ("@@ init")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func eraseEventHandler(data:String, key:String){
        self.removeAllStrokes();
        print("@@ erase called, active strokes", self.activeStrokes);
        self.undoById(strokeIds: ["vstroke", "vstrokeU", "vstrokeD"])
        print("@@ erase again active strokes ", self.activeStrokes);

    }
    
    func drawingEventHandler(data:(String,[Float]),key:String){
        let coords = data.1
        let x:Double = Double(coords[0]) + 5
        let y:Double = Double(coords[1]) + 5
        let point = CGPoint(x:x, y:y)
        
        switch(data.0){
        case "STYLUS_UP":
            //self.beginStroke(id:"vstrokeU")
            self.renderStrokeById(currentStrokeId:"vstroke", toPoint:point, toWidth:5.0, toColor:UIColor.red)
            let point2 = CGPoint(x:x+1, y:y+1)
            self.renderStrokeById(currentStrokeId:"vstroke", toPoint:point2, toWidth:5.0, toColor:UIColor.red)
            break
        case "STYLUS_DOWN":
            //self.undoById(strokeIds: ["vstrokeStart", "vStrokeEnd"]) //undo start/end of older stroke

            self.beginStroke(id:"vstroke")
            self.renderStrokeById(currentStrokeId:"vstroke", toPoint:point, toWidth:5.0, toColor:UIColor.green)
            let point2 = CGPoint(x:x+1, y:y+1)
            self.renderStrokeById(currentStrokeId:"vstroke", toPoint:point2, toWidth:5.0, toColor:UIColor.green)
            
//            self.beginStroke(id:"vstroke")
            break
        case "STYLUS_MOVE":
            self.renderStrokeById(currentStrokeId:"vstroke", toPoint:point, toWidth:1.0, toColor:UIColor.cyan)
            break
        default:
            break
        }
        
    }
    
}
