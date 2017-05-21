//
//  UIInput.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/20/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation


class UIInput: TimeSeries, WebTransmitter {
   
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()
    var id = NSUUID().uuidString;
    
    func transmitData(){
        //TODO: implement transmit data
    }
    
    override init(){
        super.init();
        self.name = "uiinput"
        self.events = []
        self.createKeyStorage();
    }
    
}
