//
//  DebuggerInterfaceManager.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 9/1/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation


class DebuggerInterfaceManager:TouchTarget{
    
    var drawing:Drawing;
    var targetView:UIView;
    var threshold:Float = 4;
    init(drawing:Drawing,targetView:UIView){
        self.drawing = drawing;
        self.targetView = targetView;

    }
    
    
    func recieveTouch(touch: UITouch, state: UIGestureRecognizer.State, predicted: Bool) {
        
            let location = touch.location(in: targetView)
            let x = Float(location.x);
            let y = Float(location.y);
            let point = Point(x: x, y: y);

            Debugger.testMacawCollision(x:x, y:y)
            
            let seg = drawing.hitTestByPoint(point: point, threshold: self.threshold);
            if(seg != nil){
                Debugger.jumpToState(stroke: seg!.parent!, segment: seg!);
                
            }
            else {
                //if hit test is not succesful for strokes, test for hit with Maccaw elements
                //if hit is successful:
                //Debugger.setupHighlightRequest()
            }
        
        
    }
    
    
    
    
}
