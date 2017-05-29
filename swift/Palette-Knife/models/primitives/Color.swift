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
       uiColor = UIColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(lightness), alpha: CGFloat(alpha))
        let cgColor = uiColor.cgColor;
        
       let components = cgColor.components
            
            red = Float(components![0]);
            green = Float(components![1]);
            blue = Float(components![2]);
        
        
    }
    
    init(r:Float,g:Float,b:Float,a:Float){
       
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
    }
    
    func toCGColor()->CGColor{
        return self.uiColor.cgColor;
    }
    
    func toUIColor()->UIColor{
        return UIColor(red: CGFloat(self.red), green: CGFloat(self.green), blue: CGFloat(self.blue), alpha: CGFloat(self.alpha))
    }
    
}
