//
//  MathUtil.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 4/23/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation


struct MathUtil{
    
    
    static func map(value:Float, low1:Float, high1:Float, low2:Float, high2:Float)->Float
    {
        return low2 + (high2 - low2) * (value - low1) / (high1 - low1);
    }
    
    static func expMap(value:Float,exp:Float)->Float{
        return pow(value,exp)
    }
    
    static func max(v1:Float,v2:Float)->Float{
        if(v1>v2){
            return v1;
            
        }
        else{
            return v2;
        }
    }
    
    static func polarToCart(r:Float, theta:Float)->(Float,Float){
        let x = cos(theta * (Float.pi / 180.0)) * r;
        let y = sin(theta * (Float.pi / 180.0)) * r;
        return (x,y)
    }
    
    static func cartToPolar(p1:Point, p2:Point)->(Float,Float) {
        
        var r = Float(0.0);
        var theta = Float(0.0);
        let x = p2.x.get(id:nil) - p1.x.get(id:nil)
        let y = p2.y.get(id:nil) - p1.y.get(id:nil)
        r = sqrt((x * x) + (y * y));
        
        var type = 0;
        if (x > 0 && y >= 0) {
            type = 1;
        }
        if (x > 0 && y < 0) {
            type = 2;
        }
        if (x < 0) {
            type = 3;
        }
        if (x == 0 && y > 0) {
            type = 4;
        }
        if (x == 0 && y < 0) {
            type = 5;
        }
        if (x == 0 && y == 0) {
            type = 6;
        }
        
        //Find theta
        switch (type) {
        case (1):
            theta = atan(y / x);
            break;
        case (2):
            theta = atan(y / x) + 2 * Float.pi;
            break;
        case (3):
            theta = atan(y / x) +  Float.pi;
            break;
        case (4):
            theta = Float.pi / 2.0;
            break;
        case (5):
            theta = 3 * Float.pi / 2.0;
            break;
        case (6):
            theta = 0.0;
            break;
        default:
            theta = 0.0;
            break;
        }
        
        return (r,theta)
        
    }
    
}
