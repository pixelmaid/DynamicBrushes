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
    var currentStrokeID:String = "";
    let startShapeLayer = CAShapeLayer();
    let endShapeLayer = CAShapeLayer();
    let strokeColor:UIColor;
    override init(name:String,frame:CGRect) {
        strokeColor = UIColor(red: 0, green: 1.0, blue: 1.0, alpha: 1)

        super.init(name:name, frame:frame)
        _ = StylusManager.stylusDataEvent.addHandler(target: self, handler: VisualizationView.drawingEventHandler, key: drawingEventKey)
        _ = StylusManager.visualizationEvent.addHandler(target: self, handler: VisualizationView.eraseEventHandler, key: eraseEventKey)
   
        let circlePath1 = UIBezierPath(arcCenter: CGPoint(x: -0.25,y: -0.25), radius: CGFloat(10), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let circlePath2 = UIBezierPath(arcCenter: CGPoint(x: -0.25,y: -0.25), radius: CGFloat(10), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        startShapeLayer.path = circlePath1.cgPath
        startShapeLayer.fillColor = UIColor.green.cgColor
        startShapeLayer.strokeColor = UIColor.cyan.cgColor;
        startShapeLayer.lineWidth = 3.0;
        endShapeLayer.path = circlePath2.cgPath
        endShapeLayer.fillColor = UIColor.red.cgColor
        endShapeLayer.strokeColor = UIColor.cyan.cgColor;
        endShapeLayer.lineWidth = 3.0;
        self.layer.addSublayer(startShapeLayer)
        self.layer.addSublayer(endShapeLayer)

        self.jotView.alpha = 0.5;
        print ("@@ init")
    }
    
    required init?(coder aDecoder: NSCoder) {
        strokeColor = UIColor(red: 0, green: 1.0, blue: 1.0, alpha: 1)

        super.init(coder: aDecoder)
    }
    
    
    func eraseEventHandler(data:String, key:String){
        self.eraseAll();
        self.endShapeLayer.isHidden = true;
        self.startShapeLayer.isHidden = true;

    }
    
    func drawingEventHandler(data:(String,[Float]),key:String){
        let coords = data.1
        let x:Double = Double(coords[0]);
        let y:Double = Double(coords[1]);
        let point = CGPoint(x:x, y:y)
        
        switch(data.0){
        case "STYLUS_UP":
            self.renderStrokeById(currentStrokeId:currentStrokeID, toPoint:point, toWidth:2.0, toColor:UIColor.cyan)
            self.endShapeLayer.isHidden = false;
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            endShapeLayer.position = point;
            CATransaction.commit();
            break
        case "STYLUS_DOWN":
            currentStrokeID = "vstrokeB_" + NSUUID().uuidString;
            self.beginStroke(id:currentStrokeID);
            self.startShapeLayer.isHidden = false;
            CATransaction.begin();
           CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            startShapeLayer.position = point;
            CATransaction.commit();

            break
        case "STYLUS_MOVE":
            self.renderStrokeById(currentStrokeId:currentStrokeID, toPoint:point, toWidth:2.0, toColor:UIColor.cyan)
            break
        default:
            break
        }
        
    }
    
}
