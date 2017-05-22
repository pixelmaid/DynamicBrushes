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
    
    
    var id = NSUUID().uuidString;
    let name:String?
    var drawActive = true;
    
    
    init(name:String,frame:CGRect){
        self.name = name
        super.init(frame:frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.name = "noname";
       super.init(coder: aDecoder)
    }
    
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
    
    func exportPNG()->String?{
        let image = self.image
        
        if(image != nil){
        let fileManager = FileManager.default
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\(id).png")
            let imageData = UIImagePNGRepresentation(image!)
            UIImagePNGRepresentation(UIImage())
            fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
            
            return path;
        }
        return nil
        
    }
    
    func loadImage(path:String){
       
        let image = UIImage(contentsOfFile: path)
        print("load image",image,path)

        self.contentMode = .scaleAspectFit
        self.image = image
        
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

            for touch in touches {
                
                let location = touch.location(in: self)
                let x = Float(location.x);
                let y = Float(location.y);
                let force = Float(touch.force);
                let angle = Float(touch.azimuthAngle(in: self))
                let mappedAngle = MathUtil.map(value: angle, low1: 0, high1: 2*Float.pi
                    , low2: 0, high2: 1);
                stylus.onStylusMove(x: x, y:y, force:force, angle:angle);
            }
        }
        else {
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
