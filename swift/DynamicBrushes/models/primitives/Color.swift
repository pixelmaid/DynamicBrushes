//
//  Color.swift
//  Palette-Knife
//
//  Created by JENNIFER MARY JACOBS on 5/5/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

struct Color {
    var red:Float
    var green:Float
    var blue:Float
    var hue:Float
    var saturation:Float
    var lightness:Float
    var alpha:Float
    var uiColor:UIColor
    
    init(h:Float,s:Float,l:Float, a:Float){
        
        hue = h;
        saturation = s;
        lightness = l;
        alpha = a;
        
        let mappedH =   MathUtil.map(value: h, low1: 0.0, high1: 100.0, low2: 0.0, high2: 1.0)
         
         let mappedS = MathUtil.map(value: s, low1: 0.0, high1: 100.0, low2: 0.0, high2: 1.0)
         
         let mappedL = MathUtil.map(value: l, low1: 0.0, high1: 100.0, low2: 0.0, high2: 1.0)
         let mappedA = MathUtil.map(value: pow(1.054,a)*0.54, low1: 0.0, high1: 100.0, low2: 0.0, high2: 1.0)
      
        
        
       uiColor = UIColor(hue: CGFloat(mappedH), saturation: CGFloat(mappedS), brightness: CGFloat(mappedL), alpha: CGFloat(mappedA))
        let cgColor = uiColor.cgColor;
        
       let components = cgColor.components
            
            red = Float(components![0]);
            green = Float(components![1]);
            blue = Float(components![2]);
        
        
    }
    
    /*init(r:Float,g:Float,b:Float,a:Float){
       
        red = r;
        blue = b;
        green = g;
        alpha = a;

        self.uiColor = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(alpha))
        var _hue = CGFloat(0)
        var _saturation = CGFloat(0)
        var _brightness = CGFloat(0)
        var _alpha = CGFloat(0)
        _ = self.uiColor.getHue(&_hue, saturation: &_saturation, brightness: &_brightness, alpha: &_alpha)
        
            self.hue = Float(_hue)
            self.saturation = Float(_saturation)
            self.lightness = Float(_brightness)
    }*/
    
    func toCGColor()->CGColor{
        
        
        return self.uiColor.cgColor;
    }
    
    func toUIColor()->UIColor{
        return  UIColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(lightness), alpha: CGFloat(self.alpha))
        
    }
    
}
