//
//  FabricatorView.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 10/17/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class FabricatorView:  UIView {
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
    var inactiveMarker: UIImageView;
    var activeMarker: UIImageView;
    
    override init(frame: CGRect) {
        let inactiveImage = UIImage(named: "shopbot_position_inactive.png")
       inactiveMarker = UIImageView(frame: CGRect(x: 100, y: 100, width: 42, height: 41))
        inactiveMarker.image = inactiveImage;
        
        let activeImage = UIImage(named: "shopbot_position_active.png")
        activeMarker = UIImageView(frame: CGRect(x: 100, y: 100, width: 42, height: 41))
        activeMarker.image = activeImage;


        super.init(frame:frame);
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
  
    override func draw(_ rect: CGRect) {
        self.addSubview(inactiveMarker)

        self.addSubview(activeMarker)

           }
    
    func clear(){
       // self.image = nil
    }
    
    func drawFabricatorPosition(x:Float,y:Float,z:Float) {
        
        let _x = Numerical.map(value: x, istart:0, istop: GCodeGenerator.inX, ostart: 0, ostop: GCodeGenerator.pX)+GCodeGenerator.pXOffset
        
        let _y = Numerical.map(value: y, istart:0, istop:GCodeGenerator.inY, ostart:  GCodeGenerator.pY, ostop: 0 )+GCodeGenerator.pYOffset
        
        self.inactiveMarker.frame = CGRect(x:CGFloat(_x-20), y:CGFloat(_y-20), width:42, height:41)
        self.activeMarker.frame = CGRect(x:CGFloat(_x-20),y:CGFloat(_y-20), width:42, height:41)
       /* self.clear();
        
        
        UIGraphicsBeginImageContext(self.frame.size)
        
        
        let context = UIGraphicsGetCurrentContext()!
        
        
        self.image?.drawInRect(CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        
        let color = Color(r:0,g:255,b:0)
        
         
        let fromPoint = CGPoint(x:CGFloat(_x),y:CGFloat(_y));
        let toPoint = CGPoint(x:CGFloat(_x),y:CGFloat(_y));

        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, CGFloat(10))
        CGContextSetStrokeColorWithColor(context, color.toCGColor())
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        CGContextMoveToPoint(context, fromPoint.x,fromPoint.y)
        CGContextAddLineToPoint(context,  toPoint.x,toPoint.y)
        CGContextStrokePath(context)
        
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        self.alpha = 1
        
       
        UIGraphicsEndImageContext()*/
        
        
    }
}

