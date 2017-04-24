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
}
