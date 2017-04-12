//
//  Numerical.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 5/26/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

class Numerical{
    
    static let TRIGONOMETRIC_EPSILON = Float(1e-7)
    static let EPSILON = Float(1e-12)
    static let MACHINE_EPSILON = Float(1.12e-16)

    static func isZero (val:Float)->Bool {
        return val >= -EPSILON && val <= EPSILON;
    }
    
    static func map (value:Float, istart:Float, istop:Float, ostart:Float, ostop:Float)->Float {
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
    }
}
