//
//  ColorPickerInput.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/20/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class ColorPickerInput: UIInput{
    let hue:Observable<Float>
    let lightness:Observable<Float>
    let saturation:Observable<Float>

    override init(){
        self.hue = Observable<Float>(0.5)
        self.lightness = Observable<Float>(0.25)
        self.saturation = Observable<Float>(1)
    }
    
    func setColor(color:UIColor){
        var _hue = CGFloat(0)
        var _saturation = CGFloat(0)
        var _brightness = CGFloat(0)
        var _alpha = CGFloat(0)
        let success = color.getHue(&_hue, saturation: &_saturation, brightness: &_brightness, alpha: &_alpha)
        if(success){
            self.hue.set(newValue: Float(_hue))
            self.lightness.set(newValue: Float(_brightness))
            self.saturation.set(newValue: Float(_saturation))
            
        }
    }
    
    
}
