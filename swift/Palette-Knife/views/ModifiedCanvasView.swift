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

        if let touch = touches.first  {
            let point = touch.location(in: self)
            let x = Float(point.x)
            let y = Float(point.y)
            let force = Float(touch.force);
            let angle = Float(touch.azimuthAngle(in: self))
            stylus.onStylusDown(x: x, y:y, force:force, angle:angle)
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
        //print("touches count",touches.count)
        for touch in touches {
            if(drawActive){
           // if touch.type == .stylus {
              let location = touch.location(in: self)
                let x = Float(location.x);
                let y = Float(location.y);
                let force = Float(touch.force);
                let angle = Float(touch.azimuthAngle(in: self))
                stylus.onStylusMove(x: x, y:y, force:force, angle:angle)
         //   }
            }
            else {
                UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
                let location = touch.location(in: self)
                let previousLocation = touch.previousLocation(in: self)

               
                eraseCanvas(start:previousLocation,end:location);
                
                image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }

        }
        
       
    }
    
    func eraseCanvas(start:CGPoint,end:CGPoint){
        print("erase canvas",start,end);
        let context = UIGraphicsGetCurrentContext()
        context!.beginTransparencyLayer(auxiliaryInfo: nil)

        image?.draw(in: bounds)
        context?.setBlendMode(CGBlendMode.clear)
        context?.setStrokeColor(UIColor.clear.cgColor)
        context?.setLineWidth(CGFloat(20))
        context?.setLineCap(.round)
        context?.setAlpha(1);
        
        context?.move(to: start)
        
        context?.addLine(to:end);
        
        context?.strokePath()
        context!.endTransparencyLayer();

      
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
