//
//  ModifiedCanvasView.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 4/29/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

let pi = CGFloat(M_PI)

class ModifiedCanvasView: UIImageView {
    
    
    let id = NSUUID().uuidString;
    var drawActive = true;
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(drawActive){
        if let touch = touches.first  {
            let point = touch.location(in: self)
            let x = Float(point.x)
            let y = Float(point.y)
            let force = Float(touch.force);
            let angle = Float(touch.azimuthAngle(in: self))
            stylus.onStylusDown(x: x, y:y, force:force, angle:angle)
        }
        }
    }
    
    func exportPNG()->Data?{
        let data = UIImagePNGRepresentation(self.image!)
        return data
    }
    
    func pushContext()->CGContext{
        //print("push context");
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
        self.image?.draw(in: self.bounds)
        let context = UIGraphicsGetCurrentContext()
        return context!;
    }
    
    func popContext(){
        // print("pop context");
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var touches = [UITouch]()
        
        if let coalescedTouches = event?.coalescedTouches(for: touch) {
            touches = coalescedTouches
        } else {
            touches.append(touch)
        }
        //if touch.type == .stylus {
        if(drawActive){
            print("draw active is true")
            
            for touch in touches {
                
                let location = touch.location(in: self)
                let x = Float(location.x);
                let y = Float(location.y);
                let force = Float(touch.force);
                let angle = Float(touch.azimuthAngle(in: self))
                stylus.onStylusMove(x: x, y:y, force:force, angle:angle)
            }
        }
        else {
            print("draw active is false")
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
            self.image?.draw(in: self.bounds)
            let context = UIGraphicsGetCurrentContext()

            for touch in touches {
                let location = touch.location(in: self)
                let previousLocation = touch.previousLocation(in: self)
                let force = touch.force
                eraseCanvas(context:context!, start:previousLocation,end:location,force:force);
            }
            self.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        // }
        
        
        
    }
    
    func eraseCanvas(context:CGContext, start:CGPoint,end:CGPoint,force:CGFloat){
 
        
        
        context.setStrokeColor(UIColor.red.cgColor)
        //TODO: will need to fine tune this
        context.setLineWidth(CGFloat(10))
        context.setLineCap(.round)
        context.setAlpha(CGFloat(1));
        context.setBlendMode(CGBlendMode.clear)

        context.move(to: start)
        
        context.addLine(to:end)
        context.strokePath()
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // image = drawingImage
        stylus.onStylusUp()
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //image = drawingImage
    }
    
    func eraseAll() {
        self.image = nil
        
    }
}
