//
//  UIInput.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/20/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class UIInput: TimeSeries, WebTransmitter {
   
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()
    var id = NSUUID().uuidString;
    
    
    let hue:Observable<Float>
    let lightness:Observable<Float>
    let saturation:Observable<Float>
    let alpha:Observable<Float>
    let diameter:Observable<Float>

    override init(){
        self.hue = Observable<Float>(0.5)
        self.lightness = Observable<Float>(0.25)
        self.saturation = Observable<Float>(1)
        self.diameter = Observable<Float>(20)
        self.diameter.printname = "ui_diameter"
        self.alpha = Observable<Float>(1.0)
        
        super.init();
        
        self.name = "uiinput"
        self.events = []
        self.createKeyStorage();

    }
    
    func invalidateAllProperties(){
        self.diameter.invalidate(oldValue: self.diameter.get(id: nil), newValue: self.diameter.get(id: nil));
        self.alpha.invalidate(oldValue: self.alpha.get(id: nil), newValue: self.alpha.get(id: nil));
        self.hue.invalidate(oldValue: self.hue.get(id: nil), newValue: self.hue.get(id: nil));
        self.lightness.invalidate(oldValue: self.lightness.get(id: nil), newValue: self.lightness.get(id: nil));
        self.saturation.invalidate(oldValue: self.saturation.get(id: nil), newValue: self.saturation.get(id: nil));
    }
    
    func setColor(color:UIColor){
        var _hue = CGFloat(0)
        var _saturation = CGFloat(100)
        var _brightness = CGFloat(100)
        var _alpha = CGFloat(0)
        let success = color.getHue(&_hue, saturation: &_saturation, brightness: &_brightness, alpha: &_alpha)
        if(success){
            self.hue.set(newValue: MathUtil.map(value:Float(_hue), low1:0, high1:1, low2:0, high2: 100))
            self.lightness.set(newValue: MathUtil.map(value:Float(_brightness), low1:0, high1:1, low2:0, high2: 100))
            self.saturation.set(newValue:MathUtil.map(value:Float(_saturation), low1:0, high1:1, low2:0, high2: 100))
            
        }
    }
    
    
    func setDiameter(val:Float){
        self.diameter.set(newValue: val);
    }
    
    func setAlpha(val:Float){
        self.alpha.set(newValue: val);
    }
    
    func transmitData(){
        //TODO: implement transmit data
    }
    

    
}
